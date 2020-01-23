#import "DMGTask.h"
#import "DMGDocumentProtocol.h"

#ifndef DEBUG
#define DEBUG 0
#endif

#define useLog DEBUG

@implementation DMGTask

+ (DMGTask *)dmgTaskAt:(NSString *)workingLocation
{
    DMGTask *task = [self new];
    task.workingLocation = workingLocation;
    return task;
}

- (id)init
{
    self = [super init];
    self->aborted = NO;
    return self;
}

- (PipingTask *)hdiUtilTask
{
    PipingTask *task = [[PipingTask alloc] init];
    [task setLaunchPath:@"/usr/bin/hdiutil"];
    if (_workingLocation) [task setCurrentDirectoryPath:_workingLocation];
    return task;
}

- (BOOL)setInternetEnable:(NSString *)path enable:(BOOL)flag
{
    NSString *command = flag?@"-yes":@"-no";
    PipingTask * task = [self hdiUtilTask];
    self.currentTask = task;
    _currentTask.arguments = @[path, command];
    [_currentTask launch];
    [_currentTask waitUntilExit];
    self.terminationStatus = _currentTask.terminationStatus;
    return (0 == _terminationStatus);
}

- (void)createDiskImage:(NSString *)destination
             volumeName:(NSString *)volname
                   type:(NSString *)type
             filesystem:(NSString *)fs
                   size:(NSString *)size
      completionHandler:(void(^)(BOOL))handler
{
    self.currentTask = [self hdiUtilTask];
    NSArray *args = @[@"create", destination,
                      @"-fs", fs,
                      @"-size",size,
                      @"-layout",@"None",
                      @"-type",type,
                      @"-volname",volname,
                      @"-plist"];
    
    if ([fs isEqualToString:@"HFS+"]) {
        args = [args arrayByAddingObjectsFromArray:@[@"-fsargs", @"-c c=64,a=16,e=16"]];
    }
    _currentTask.arguments = args;
    __unsafe_unretained typeof(self) weak_self = self;
    [_currentTask launchWithCompletionHandler:^(int status) {
        weak_self.terminationStatus = _currentTask.terminationStatus;
        if (0 == _terminationStatus) {
            NSArray *resultArray = weak_self.currentTask.stdoutString.propertyList;
            weak_self.dmgPath = resultArray[0];
        }
        handler(0 == _terminationStatus);
    }];
}

- (void)createDiskImage:(NSString *)destination
              srcfolder:(NSString *)srcfolder
             volumeName:(NSString *)volname
             filesystem:(NSString *)fs
                   size:(NSString *)size
       compressionLevel:(int)compressionLevel
      completionHandler:(void(^)(BOOL))handler
{
    self.currentTask = [self hdiUtilTask];
    NSMutableArray *args = @[@"create", destination,
                            @"-fs", fs,
                            @"-size",size,
                            @"-srcfolder", srcfolder,
                            @"-layout",@"None",
                            @"-volname",volname,
                            @"-fsargs", @"-c c=64,a=16,e=16",
                            @"-plist"].mutableCopy;
    /*
    if ([fs isEqualToString:@"HFS+"]) {
        args = [args arrayByAddingObjectsFromArray:@[@"-fsargs", @"-c c=64,a=16,e=16"]];
    }*/
    
    if (compressionLevel > 1) {
        NSString *zlibLevelString = [NSString stringWithFormat:@"zlib-level=%i", compressionLevel];
        [args addObjectsFromArray:@[@"-imagekey" ,zlibLevelString]];
    }
    
    _currentTask.arguments = args;
    __unsafe_unretained typeof(self) weak_self = self;
    [_currentTask launchWithCompletionHandler:^(int status) {
        weak_self.terminationStatus = _currentTask.terminationStatus;
        if (0 == _terminationStatus) {
            NSArray *resultArray = weak_self.currentTask.stdoutString.propertyList;
            weak_self.dmgPath = resultArray[0];
        }
        handler(0 == _terminationStatus);
    }];
}

- (void)convertDiskImage:(NSString *)source
                  format:(NSString *)format
             destination:(NSString *)destination
         compressionLevel:(int)compressionLevel
       completionHandler:(void(^)(BOOL))handler
{
    NSMutableArray *args = @[@"convert", source,
                                  @"-format", format,
                                  @"-o",destination ,
                                  @"-plist"].mutableCopy;
    
    if ([format isEqualToString:@"UDZO"]) {
        NSString *zlibLevelString = [NSString stringWithFormat:@"zlib-level=%i", compressionLevel];
        [args addObjectsFromArray:@[@"-imagekey" ,zlibLevelString]];
    }
    self.currentTask = [self hdiUtilTask];
    _currentTask.arguments = args;
    __unsafe_unretained typeof(self) weak_self = self;
    [_currentTask launchWithCompletionHandler:^(int status) {
        weak_self.terminationStatus = _currentTask.terminationStatus;
        handler(0 == _terminationStatus);
    }];
}

- (void)makeHibridFromSource:(NSString *)source
                 destination:(NSString *)destination
                    volumeName:(NSString *)diskName
            completionHadler:(void (^)(BOOL))handler
{
    self.currentTask = [self hdiUtilTask];
    _currentTask.arguments = @[@"makehybrid", @"-iso", @"-udf",
                                 @"-udf-version", @"1.0.2",
                                 @"-udf-volume-name",diskName,
                                 @"-o", destination, source];
    
    __unsafe_unretained typeof(self) weak_self = self;
    [_currentTask launchWithCompletionHandler:^(int status) {
        weak_self.terminationStatus = _currentTask.terminationStatus;
        handler(0 == _terminationStatus);
    }];
}

- (void)attachDiskImage:(NSString *)dmgPath
      completionHandler:(void (^)(BOOL))handler
{
    self.currentTask = [self hdiUtilTask];
    _currentTask.arguments = @[@"attach",dmgPath,@"-noverify",
                               @"-nobrowse",@"-plist"];
    __unsafe_unretained typeof(self) weak_self = self;
    [_currentTask launchWithCompletionHandler:^(int status) {
        weak_self.terminationStatus = _currentTask.terminationStatus;
        if (0 == _terminationStatus) {
            NSDictionary *task_result = [[_currentTask stdoutString] propertyList];
            NSArray *entities = task_result[@"system-entities"];
            NSString *mount_point = nil;
            for (NSDictionary *dict in entities) {
                mount_point = dict[@"mount-point"];
                if (mount_point) {
                    self.devEntry = dict[@"dev-entry"];
                    self.mountPoint = mount_point;
                    break;
                }
            }
        }
        handler(0 == _terminationStatus);
    }];
}

- (void)detachDiskImage:(NSString *)dev
      completionHandler:(void (^)(BOOL))handler
{
    self.currentTask = [self hdiUtilTask];
    [_currentTask setArguments:@[@"detach", dev]];
    __unsafe_unretained typeof(self) weak_self = self;
    [_currentTask launchWithCompletionHandler:^(int status) {
        weak_self.terminationStatus = _currentTask.terminationStatus;
        handler(0 == _terminationStatus);
    }];
}

- (PipingTask *)detachNow
{
    if (!_devEntry) {
        return nil;
    }
    
    PipingTask *detach_task = [self detachNow:_devEntry];
    self.devEntry = nil;
    self.mountPoint = nil;
    return detach_task;
}

- (PipingTask *)detachNow:(NSString *)devEntry
{
    PipingTask *detach_task = [self hdiUtilTask];
    [detach_task setArguments:@[@"detach", devEntry]];
    [detach_task launch];
    return detach_task;
}

- (void)cpItems:(NSEnumerator *)enumerator
      destination:(NSString *)destination
completionHandler:(void(^)(BOOL)) handler
{
#if useLog
    NSLog(@"start cpItems in DMGTask");
#endif
    // abort した時どうなるか要確認。
    NSDocument<DMGDocument>* source_item = [enumerator nextObject];
    if (!source_item) {
        self.terminationStatus = _currentTask.terminationStatus;
        handler(0 == _terminationStatus);
        return;
    }
    
    self.currentTask = [PipingTask new];
    _currentTask.launchPath = @"/bin/cp";
    
    _currentTask.arguments = @[source_item.fileURL.path, destination];
#if useLog
    NSLog(@"arguments: %@", _currentTask.arguments);
#endif
    __unsafe_unretained typeof(self) weak_self = self;
    [_currentTask launchWithCompletionHandler:^(int result) {
        weak_self.terminationStatus = _currentTask.terminationStatus;
        if ((0 == result) && (! aborted)) {
            [weak_self cpItems:enumerator
                      destination:destination
                completionHandler:handler];
        } else {
            handler(NO);
        }
    }];
}

- (void)dittoItems:(NSEnumerator *)enumerator
      destination:(NSString *)destination
     isOnlyFolder:(BOOL)isOnlyFolder
        completionHandler:(void(^)(BOOL)) handler
{
#if useLog
    NSLog(@"start dittoItems in DMGTask");
#endif
    // abort した時どうなるか要確認。
    NSDocument<DMGDocument>* source_item = [enumerator nextObject];
    if (!source_item) {
        self.terminationStatus = _currentTask.terminationStatus;
        handler(0 == _terminationStatus);
        return;
    }
    
    self.currentTask = [PipingTask new];
    _currentTask.launchPath = @"/usr/bin/ditto";
    
    
    NSString *dest = destination;
    if (!isOnlyFolder && [source_item isFolder]) {
        dest = [destination stringByAppendingPathComponent:
                [[source_item fileURL] lastPathComponent]];
    }
    
    _currentTask.arguments = @[@"--rsrc",[[source_item fileURL] path],
                         dest];
#if useLog
    NSLog(@"arguments: %@", _currentTask.arguments);
#endif
    __unsafe_unretained typeof(self) weak_self = self;
    [_currentTask launchWithCompletionHandler:^(int result) {
        weak_self.terminationStatus = _currentTask.terminationStatus;
        if ((0 == result) && (! aborted)) {
            [weak_self dittoItems:enumerator
                     destination:destination
                    isOnlyFolder:isOnlyFolder
               completionHandler:handler];
        } else {
            handler(NO);
        }
    }];
}

- (void)deleteDSStore:(NSString *)path
    completionHandler:(void (^)(BOOL))handler
{
#if useLog
    NSLog(@"start deleteDSStore:completionHandler:");
#endif
    self.currentTask = [[PipingTask alloc] init];
    [_currentTask setLaunchPath:@"/usr/bin/find"];
    [_currentTask setArguments:@[path, @"-name", @".DS_Store",
                                 @"-delete"]];
    __unsafe_unretained typeof(self) weak_self = self;
    [_currentTask launchWithCompletionHandler:^(int result) {
        #if useLog
            NSLog(@"start completionHandler in deleteDSStore:completionHandler:");
        #endif
        weak_self.terminationStatus = _currentTask.terminationStatus;
        if (0 == result) {
            handler(YES);
            return;
        }
        if ([_currentTask.stderrString hasSuffix:@".Trashes: Permission denied\n"]) {
            handler(YES);
            return;
        }
        handler(NO);
    }];
}

- (NSString *)terminationMessage
{
    if (_terminationMessage) {
        return _terminationMessage;
    } else {
        return [_currentTask stderrString];
    }
}

- (BOOL)isSuccess
{
    return (0 == _terminationStatus);
}

- (void)abortTask
{
#if useLog
    NSLog(@"%@", @"aborted in DMGTask");
#endif
    [_currentTask terminate];
    [self detachNow];
    aborted = YES;
}

@end
