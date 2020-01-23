#import "DiskImageMaker.h"
#import "DMGDocumentProtocol.h"
#import "DMGTask.h"
#import "PathExtra.h"
#include <unistd.h>
#include <sys/param.h>
#include <sys/ucred.h>
#include <sys/mount.h>

#ifndef DEBUG
#define DEBUG 0
#endif

#define useLog DEBUG

#ifndef SANDBOX
#define SANDBOX 0
#endif

@implementation DiskImageMaker

#pragma mark internal use
- (NSString *)uniqueName:(NSString *)baseName suffix:(NSString *)theSuffix location:(NSString *)dirPath;
{
	NSString *newName = [baseName stringByAppendingPathExtension:theSuffix];
	NSString *checkPath = [dirPath stringByAppendingPathComponent:newName];
	short i = 1;
	NSFileManager *file_manager = [NSFileManager defaultManager];
	while ([file_manager fileExistsAtPath:checkPath]){
		NSNumber *numberSuffix = @(i++);
		newName = [[baseName stringByAppendingPathExtension:[numberSuffix stringValue]] stringByAppendingPathExtension:theSuffix];
		checkPath = [dirPath stringByAppendingPathComponent:newName];
	}
	return newName;	
}

- (NSString *)uniqueName:(NSString *)baseName location:(NSString*)dirPath;
{
	NSString * newName = [baseName stringByAppendingPathExtension:[_dmgOptions dmgSuffix]];
	NSString * checkPath = [dirPath stringByAppendingPathComponent:newName];
	NSFileManager *file_manager = [NSFileManager defaultManager];
	short i = 1;
	while ([file_manager fileExistsAtPath:checkPath]){
		NSNumber * numberSuffix = @(i++);
		newName = [[baseName stringByAppendingPathExtension:[numberSuffix stringValue]] 
									stringByAppendingPathExtension:[_dmgOptions dmgSuffix]];
		checkPath = [_workingLocationURL.path stringByAppendingPathComponent:newName];
	}
	return newName;
}

#pragma mark init and dealloc
- (id) init
{
	if ((self = [super init])) {
        requireSpaceRatio = 1.0;
        self.isReplacing = NO;
        expectedCompressRatio = 0.7;
        aborted = NO;
    }
	return self;
}

- (id)initWithSourceItem:(NSDocument<DMGDocument> *)anItem
{
	if (!(self = [self init])) return nil;
	self.sourceItems = @[anItem];
	NSURL *source_url = [anItem fileURL];
	
	if ([[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] containsObject:source_url.path]) {
		self.workingLocationURL = [NSURL fileURLWithPath:
                                   [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES)
								  lastObject]];
	} else {				
		self.workingLocationURL = [source_url URLByDeletingLastPathComponent];
	}
	
	NSString *source_name = [source_url lastPathComponent];
	if ((![anItem isFolder]) || [anItem isPackage]) {
		self.diskName = [source_name stringByDeletingPathExtension];
	} else {
		self.diskName = source_name;
	}
	return self;
}

- (id)initWithSourceItems:(NSArray *)array
{
	if ((self = [self init])) {
        self.sourceItems = array;
    }
	return self;
}


#pragma mark setup methods
- (void)setDestination:(NSString *)aPath replacing:(BOOL)aFlag;
{
	self.workingLocationURL = [NSURL fileURLWithPath:[aPath stringByDeletingLastPathComponent]];
	self.diskName = [[aPath lastPathComponent] stringByDeletingPathExtension];
	self.isReplacing = aFlag;
	if (_isReplacing) {
		self.dmgName = [aPath lastPathComponent];
	} else {
		self.dmgName = [self uniqueName:_diskName location:_workingLocationURL.path];
	}
}

- (NSString *)resolveDmgName
{
	self.dmgName = [self uniqueName:_diskName location:_workingLocationURL.path];
	return _dmgName;
}

- (void)setCustomDmgName:(NSString *)aName
{
	self.isReplacing = YES;
	self.dmgName = aName;
	self.diskName = [aName stringByDeletingPathExtension];
}

- (NSString *)dmgPath
{
	if (!_dmgName) [self resolveDmgName];
	return [_workingLocationURL.path stringByAppendingPathComponent:_dmgName];
}

#pragma mark instance methods
- (BOOL)checkCondition:(NSWindowController<DMGWindowController> *)aWindowController
{
    if (!SANDBOX && ![self checkWorkingLocationPermission]) {
		NSString* detailMessage = [NSString stringWithFormat:NSLocalizedString(@"No write permission",""),
			_workingLocationURL.path];
		[aWindowController showAlertMessage:NSLocalizedString(@"Insufficient access right.","") 
											withInformativeText:detailMessage];
		return NO;
	}
    
	if (![self checkFreeSpace]) {
		[aWindowController 
			showAlertMessage:NSLocalizedString(@"Can't progress jobs.","")
			withInformativeText:NSLocalizedString(@"Not enough free space for creating a disk image.", "")];
		return NO;
	}
	
	isOnlyFolder = NO;
	if ([_sourceItems count] == 1) {
		id <DMGDocument>item = [_sourceItems lastObject];
		isOnlyFolder = ([item isFolder] && ![item isPackage]);
	}
	
	return YES;
}

- (BOOL)checkWorkingLocationPermission
{
#if useLog
	NSLog(@"start checkWorkingLocationPermission:%@", _workingLocationURL.path);
#endif
	int wirtePermInt = access([_workingLocationURL.path fileSystemRepresentation],02);
	return (wirtePermInt == 0);
}

- (BOOL) checkFreeSpace
{
#if useLog
	NSLog(@"start checkFreeSpace");
#endif
	[self postStatusNotification: 
		NSLocalizedString(@"Checking free space of disks.","")];
		
	sourceSize = 0;
	for (id <DMGDocument>an_item in _sourceItems) {
		sourceSize += [an_item fileSize];
	}
	//sourceSize += 500000;
	sourceSize += [[NSUserDefaults standardUserDefaults] integerForKey:@"additionalSize"];
		
    NSFileManager *file_manager = [NSFileManager defaultManager];
	
	NSError *err = nil;
    NSDictionary *infoWorkingDisk = [file_manager
                                     attributesOfFileSystemForPath:_workingLocationURL.path
                                     error: &err];
    if (err) {
        [NSApp presentError:err];
        return NO;
    }
	unsigned long long freeSize = [infoWorkingDisk[NSFileSystemFreeSize] unsignedLongLongValue];
    
	NSString *dmg_format = [_dmgOptions dmgFormat];
	willBeConverted = [_dmgOptions needConversion];
	
	self.tmpDir = NSTemporaryDirectory();
	requireSpaceRatio = 0;
	if ([[_dmgOptions command] isEqualToString:@"makehybrid"]) {
		if (isOnlyFolder) {
			requireSpaceRatio = 1;
		} else {
			willBeConverted = YES;
			expectedCompressRatio = 1;
		}
    } else if ([dmg_format isEqualToString:@"UDZO"] && ![_dmgOptions isDeleteDSStore]
                                                && ([_sourceItems count] == 1)) {
        willBeConverted = NO;
    }
	
	if (!requireSpaceRatio) {
		if (willBeConverted) {
            NSDictionary *infoTmpDisk = [file_manager
                                             attributesOfFileSystemForPath:_tmpDir
                                             error: &err];
            if (err) {
                [NSApp presentError:err];
                return NO;
            }
			if ([infoTmpDisk[NSFileSystemNumber] isEqualToNumber:infoWorkingDisk[NSFileSystemNumber]]) {
				requireSpaceRatio = 1 + expectedCompressRatio;
			}
			else {
				unsigned long long freeSizeTmpDir = [infoTmpDisk[@"NSFileSystemFreeSize"] unsignedLongLongValue];
				
				if (freeSizeTmpDir > sourceSize) {
					if ([dmg_format isEqualToString:@"UDZO"] || [dmg_format isEqualToString:@"UDBZ"])
						requireSpaceRatio = expectedCompressRatio;
				}
				else {
					return NO;
				}
			}
		}
		else {
			requireSpaceRatio = 1;
		}
	}
		
	if ( freeSize > requireSpaceRatio*sourceSize)
		return YES;
	else
		return NO;
}

#pragma mark disk image task

- (void)detachDiskImage
{
    [self postStatusNotification:NSLocalizedString(@"Detaching a disk image.","")
                       increment:1.0];
    self.currentDMGTask = [DMGTask dmgTaskAt:_workingLocationURL.path];
    [_currentDMGTask detachDiskImage:_devEntry
                   completionHandler:^(BOOL result){
                       if (result) {
                           _devEntry = nil;
                       }
                       if (result && willBeConverted && !aborted) {
                           [self convertDiskImage];
                       } else {
                           [self terminatedCurrentDmgTask];
                       }
                   }];
}

- (void)deleteDSStore
{
#if useLog
    NSLog(@"start deleteDSStore in DiskImageMaker");
#endif
    
    [self postStatusNotification:NSLocalizedString(@"Deleting .DS_Store files.","")
                           increment:1.0];

    DMGTask *task = [DMGTask dmgTaskAt:self.workingLocationURL.path];
    [_currentDMGTask deleteDSStore:_mountPoint completionHandler:^(BOOL result) {
        if (result && !aborted) {
            [self detachDiskImage];
        } else {
            if (!aborted) {
                [_currentDMGTask detachNow];
                self.currentDMGTask = task;
            }
            [self terminatedCurrentDmgTask];
        }
    }];
}

NSString *mountPointForDevEntry(NSString *devEntry)
{
	struct statfs *buf;
	int i, count;
	const char *dev = [devEntry UTF8String];
	
	count = getmntinfo(&buf, 0);
	for (i=0; i<count; i++)
	{
		if (strcmp(buf[i].f_mntfromname, dev) == 0)
			return @(buf[i].f_mntonname);
	}
	return nil;
}

- (BOOL)fixedHFSVolume
{
    if (![[_dmgOptions filesystem] isEqualToString:@"HFS"]) return YES;
    
    CFStringEncoding sysenc = CFStringGetSystemEncoding();
    PipingTask *dt_task = [PipingTask
                           launchedTaskWithLaunchPath:@"/usr/sbin/disktool"
                           arguments:@[@"-s", _devEntry, [NSString stringWithFormat:@"%d",sysenc]]];
    [dt_task waitUntilExit];
    // Fix volume name is not reflected if diskName have multi byte characters,
    dt_task = [PipingTask
               launchedTaskWithLaunchPath:@"/usr/sbin/diskutil"
               arguments:@[@"rename" ,_devEntry, _diskName]];
    [dt_task waitUntilExit];
    if ([dt_task terminationStatus] !=0) {
        NSLog(@"%@", [dt_task stderrString]);
    }
    
    NSString *bufmp = mountPointForDevEntry(_devEntry);
    if (bufmp) {
        self.mountPoint = bufmp;
    } else {
        self.terminationStatus = 1;
        self.terminationMessage =
         [NSString stringWithFormat:@"Can't find the mount point for %@", _devEntry];
        self.currentDMGTask = nil;
        return NO;
    }
    return YES;
}


- (void)attachDiskImage
{
#if useLog
    NSLog(@"%@", @"start attachDiskImage");
#endif
    [self postStatusNotification: NSLocalizedString(@"Attaching a disk image.","")
                       increment:1.0];
    NSString *dmg_path = _currentDMGTask.dmgPath;
    self.currentDMGTask = [DMGTask dmgTaskAt:_workingLocationURL.path];
    [_currentDMGTask attachDiskImage:dmg_path
                   completionHandler:^(BOOL result) {
                       if (!result || aborted) {
                           [self terminatedCurrentDmgTask];
                           return;
                       }
                       
                       self.devEntry = _currentDMGTask.devEntry;
                       self.mountPoint = _currentDMGTask.mountPoint;
                       
                       if (![self fixedHFSVolume]) {
                           [self terminatedCurrentDmgTask];
                           return;
                       };
                       self.currentDMGTask = [DMGTask dmgTaskAt:self.workingLocationURL.path];
                       [_currentDMGTask dittoItems:[_sourceItems objectEnumerator]
                                      destination:_mountPoint
                                     isOnlyFolder:isOnlyFolder
                                completionHandler:^(BOOL result) {
                                    if (aborted) {
                                        [self terminatedCurrentDmgTask];
                                    }
                           if (result && [_dmgOptions isDeleteDSStore]) {
                               [self deleteDSStore];
                           }
                           else {
                               [self detachDiskImage];
                           }
                       }];
                   }];
}

- (void)postStatusNotificationWithDict:(NSDictionary *)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
                        postNotificationName: @"DmgProgressNotification"
                                    object:self userInfo:userInfo];
    });
}

- (void)postStatusNotification:(NSString *)message
{
	NSDictionary* user_info = @{@"statusMessage": message};
    [self postStatusNotificationWithDict:user_info];
}

- (void)postStatusNotification:(NSString *)message maxValue:(double)maxValue
{
    NSDictionary* user_info = @{@"statusMessage": message,
                                @"maxValue": [NSNumber numberWithDouble:maxValue]};
    [self postStatusNotificationWithDict:user_info];
}

- (void)postStatusNotification:(NSString *)message increment:(double)increment
{
    NSDictionary* user_info = @{@"statusMessage": message,
                                @"increment": [NSNumber numberWithDouble:increment]};
    [self postStatusNotificationWithDict:user_info];
}

- (void)postStatusNotification:(NSString *)message maxValue:(double)maxValue increment:(double)increment
{
    NSDictionary* user_info = @{@"statusMessage": message,
                                @"maxValue": [NSNumber numberWithDouble:maxValue],
                                @"increment": [NSNumber numberWithDouble:increment]};
    [self postStatusNotificationWithDict:user_info];
}


- (void)makeHybridDiskImageTo:(NSString *)destination
            completionHandler:(void (^)(BOOL))handler
{
    if (isOnlyFolder) {
        NSDocument<DMGDocument>* source_item = [_sourceItems lastObject];
        self.currentDMGTask = [DMGTask dmgTaskAt:_workingLocationURL.path];
        [_currentDMGTask makeHibridFromSource:[[source_item fileURL] path]
                                  destination:destination
                                   volumeName:_diskName
                             completionHadler:^(BOOL result) {
                                 handler(result);
                             }];
        [self postStatusNotification:NSLocalizedString(@"Creating a hybrid disk image.","")
                            maxValue:2.0];
        return;
        
    } else {
        NSString *tmp_name = [self uniqueName:_diskName suffix:@"" location:_tmpDir];
        NSString *tmp_path = [_tmpDir stringByAppendingPathComponent:tmp_name];
        if ([[NSFileManager defaultManager]
             createDirectoryAtURL: [tmp_path fileURL]
             withIntermediateDirectories:YES
             attributes:nil error:nil]) {
            
            void (^after_copy)(BOOL) = ^(BOOL result){
                if (!result || aborted) {
                    [self terminatedCurrentDmgTask];
                    return;
                }
                [self postStatusNotification:NSLocalizedString(@"Creating a hybrid disk image.","")
                                   increment:1.0];
                self.currentDMGTask = [DMGTask dmgTaskAt:_workingLocationURL.path];
                [_currentDMGTask makeHibridFromSource:tmp_path
                                          destination:destination
                                           volumeName:_diskName
                                     completionHadler:^(BOOL result) {
                                         NSError *err;
                                         [[NSFileManager defaultManager] removeItemAtPath:tmp_path
                                                                                    error:&err];
                                         if (err) NSLog(@"%@", err);
                                         handler(result);
                                     }];
            };
            self.currentDMGTask = [DMGTask dmgTaskAt:self.workingLocationURL.path];
            [_currentDMGTask cpItems:[_sourceItems objectEnumerator]
                           destination:tmp_path
                     completionHandler:after_copy];
            [self postStatusNotification: NSLocalizedString(@"Copying source files.","")
                                maxValue:3.0 increment:1.0];
            return;
        } else {
            NSLog(@"Failed to make directory");
            return;
        }
    }
}

- (void)createDiskImageTo:(NSString *)destination //non-sandbox
{
    NSString * image_size = (sourceSize < 550000 ) ? @"550000" : [@(sourceSize) stringValue];
    
    NSString *dmg_type = [_dmgOptions dmgFormat];
    if ([dmg_type isEqualToString:@"UDSP"]) {
        dmg_type = @"SPARSE";
    } else if ([dmg_type isEqualToString:@"UDZO"]) {
        if ([_dmgOptions isDeleteDSStore] || ([_sourceItems count] != 1)) {
            dmg_type = @"UDIF";
        }
    } else {
        dmg_type = @"UDIF";
    }
    
    NSString *fs = [_dmgOptions filesystem];
    
    self.currentDMGTask = [DMGTask dmgTaskAt:_workingLocationURL.path];
    if ([dmg_type isEqualToString:@"UDZO"])
    {
        NSDocument<DMGDocument> *doc = [_sourceItems lastObject];
        [_currentDMGTask createDiskImage:destination
                               srcfolder:doc.fileURL.path
                              volumeName:_diskName
                              filesystem:fs
                                    size:image_size
                        compressionLevel:[_dmgOptions compressionLevel]+1
                       completionHandler:^(BOOL result) {
                           if (result && willBeConverted && !aborted) {
                               [self convertDiskImage];
                           } else {
                               [self terminatedCurrentDmgTask];
                           }
                       }];
    } else {
        [_currentDMGTask createDiskImage:destination
                              volumeName:_diskName
                                    type:dmg_type
                              filesystem:fs
                                    size:image_size
                       completionHandler:^(BOOL result) {
                           if (result && !aborted) {
                               [self attachDiskImage];
                           } else {
                               [self terminatedCurrentDmgTask];
                           }
                       }];
    }
}

- (void)createDiskImageWithCompletaionHandler:(void (^)(BOOL))handler
{
#if useLog
    NSLog(@"%@", @"start createDiskImageWithCompletaionHandler");
#endif
    self.terminationHandler = handler;
    
    [self postStatusNotification: NSLocalizedString(@"Preparing.",
                                                    "Status message of checking condition.")];
    
    if (_isReplacing) {
        NSString *target_path = self.dmgPath;
        NSFileManager *file_manager = [NSFileManager defaultManager];
        if ([file_manager fileExistsAtPath:target_path]) {
            NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
            NSInteger tag;
            if (![workspace performFileOperation:NSWorkspaceRecycleOperation
                                          source:_workingLocationURL.path destination:@""
                                           files:@[_dmgName] tag:&tag]) {
#if useLog
                NSLog(@"can not delete");
#endif
                [self setTerminationMessage:[NSString stringWithFormat:
                                             NSLocalizedString(@"The file \n %@ could not be removed.",
                                                               "can not trash existing file"),
                                             target_path]];
                _terminationStatus = 1;
                handler(NO);
                return;
            }
        }
    }
    
    NSString *command = [_dmgOptions command];
    if ([command isEqualToString:@"makehybrid"]) {
        [self makeHybridDiskImageTo:self.dmgPath
                  completionHandler:^(BOOL result){
                      [self terminatedCurrentDmgTask];
                  }];
        return;
        
    } else {
        if (SANDBOX) {
            willBeConverted = YES;
        }
        double stepnum = 1;
        if (willBeConverted) stepnum += 1;
        if (!isOnlyFolder) {
            stepnum +=1; //copy file
            if (!SANDBOX) {
                stepnum +=2; //attach and detach
            }
        }
        if ([_dmgOptions isDeleteDSStore]) stepnum +=1;
        
        [self postStatusNotification:NSLocalizedString(@"Creating a disk image.",
                                                       "Status message of creating a disk image.")
                            maxValue:stepnum
                           increment:1.0];

        NSString* dmg_target = self.dmgPath;
        if (willBeConverted) {
            NSString *a_suffix = SANDBOX ? @"iso" : @"dmg";
            NSString *tmp_name = [self uniqueName:_diskName
                                           suffix:a_suffix location:_tmpDir];
#if useLog
            NSLog(@"%@", tmp_name);
#endif
            dmg_target = [_tmpDir stringByAppendingPathComponent:tmp_name];
            self.sourceDmgPath = dmg_target;
        }
        
        if (SANDBOX) {
            [self makeHybridDiskImageTo:dmg_target
                      completionHandler:^(BOOL result){
                          if (result)
                              [self convertDiskImage];
                          else
                              [self terminatedCurrentDmgTask];
                      }];
        } else {
            [self createDiskImageTo:dmg_target];
        }
    }
}


- (void)convertDiskImage
{
#if useLog
	NSLog(@"start convertDiskImage");
#endif
	[self postStatusNotification: NSLocalizedString(@"Converting a disk image.","")
                       increment:1.0];
	
    self.currentDMGTask = [DMGTask dmgTaskAt:_workingLocationURL.path];
    [_currentDMGTask convertDiskImage:_sourceDmgPath
                               format:[_dmgOptions dmgFormat]
                          destination:self.dmgPath //_dmgName
                     compressionLevel:[_dmgOptions compressionLevel]+1
                    completionHandler:^(BOOL result) {
                        if (willBeConverted) {
                           [[NSFileManager defaultManager] removeItemAtPath:_sourceDmgPath error:nil];
                        }
                        
                        [self terminatedCurrentDmgTask];
                     }];
    
#if useLog
	NSLog(@"end convertDiskImage");
#endif
}


- (void)terminatedCurrentDmgTask
{
#if useLog
    NSLog(@"start terminatedCurrentDmgTask");
#endif
    if (_currentDMGTask && !aborted) {
        NSLog(@"%@", _currentDMGTask.currentTask.launchPath);
        self.terminationStatus = _currentDMGTask.terminationStatus;
        if (_currentDMGTask.isSuccess) {
            if ([_dmgOptions internetEnable]) {
                [self postStatusNotification:NSLocalizedString(@"Setting internet-enable option.","")];
                DMGTask *task = [DMGTask dmgTaskAt:_workingLocationURL.path];
                if (![task setInternetEnable:_dmgName enable:YES]) {
                    self.terminationMessage = _currentDMGTask.terminationMessage;
                    goto bail;
                }
            }
            
            if ([_dmgOptions putawaySources]) {
                NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
                for (NSDocument<DMGDocument> *item in _sourceItems) {
                    NSInteger tag;
                    NSString *path = [[item fileURL] path];
                    NSString *dir = [path stringByDeletingLastPathComponent];
                    NSString *itemname = [path lastPathComponent];
                    [workspace performFileOperation:NSWorkspaceRecycleOperation
                                             source:dir
                                        destination:@""
                                              files:@[itemname]
                                                tag:&tag];
                }
            }
        } else {
            self.terminationMessage = _currentDMGTask.terminationMessage;
        }
    }
bail:
#if useLog
    NSLog(@"before terminationHadler");
#endif
    dispatch_async(dispatch_get_main_queue(), ^{
        self.terminationHandler(0 == _terminationStatus);
    });
#if useLog
    NSLog(@"end terminatedCurrentDmgTask");
#endif
}

- (void)aboartTask
{
    [self postStatusNotification:NSLocalizedString(@"Canceling task.","")];
	[_currentDMGTask abortTask];
	if (_devEntry) {
        [[DMGTask new] detachNow:_devEntry];
	}
    aborted = YES;
	NSString *dmg_path = [_workingLocationURL.path
                          stringByAppendingPathComponent:_dmgName];
	NSFileManager *file_manager = [NSFileManager defaultManager];
	if ([file_manager fileExistsAtPath:dmg_path]) {
		[file_manager removeItemAtPath:dmg_path error:nil];
	}
	
	if ((willBeConverted) && ([file_manager fileExistsAtPath:_sourceDmgPath])) {
		[file_manager removeItemAtPath:_sourceDmgPath error:nil];
	}
	
}

@end

