#import "PipingTask.h"

#ifndef DEBUG
#define DEBUG 0
#endif

#define useLog DEBUG

@implementation PipingTask

+ (PipingTask *)launchedTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments
{
	PipingTask *a_task = [[self alloc] init];
	[a_task setLaunchPath:path];
	[a_task setArguments:arguments];
	[a_task launch];
	return a_task;
}

+ (PipingTask *)launchedTaskWithLaunchPath:(NSString *)path
                                 arguments:(NSArray *)arguments
                        terminationHandler:(void(^)(PipingTask *))handler
{
    PipingTask *a_task = [[self alloc] init];
    [a_task setLaunchPath:path];
    [a_task setArguments:arguments];
    __unsafe_unretained typeof(a_task) weak_task = a_task;
    [a_task launchWithCompletionHandler:^(int status) {
        handler(weak_task);
    }];
    return a_task;
}

- (id)init
{
    if (self = [super init]) {
		self.task  = [NSTask new];
    }
	
    return self;
}

- (void)waitUntilExit
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_task waitUntilExit];
}

- (void)launchWithCompletionHandler:(void(^)(int))handler
{
#if useLog
    NSLog(@"start launchWithCompletionHandler");
#endif
    self.stdoutData = nil;
    self.stdoutData = [NSMutableData new];
    self.stderrData = nil;
    self.stderrData = [NSMutableData new];
    _task.standardOutput = [NSPipe pipe];
    _task.standardError = [NSPipe pipe];
    _task.terminationHandler = ^(NSTask *t){
        handler(t.terminationStatus);
    };
    
    [_task launch];
    
    [NSThread detachNewThreadSelector:@selector(readStdOut:)
                             toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(readStdErr:)
                             toTarget:self withObject:nil];
}

- (void)launch
{
	self.stdoutData = nil;
	self.stdoutData = [NSMutableData new];
	self.stderrData = nil;
	self.stderrData = [NSMutableData new];
	[_task setStandardOutput:[NSPipe pipe]];
	[_task setStandardError:[NSPipe pipe]];
    
	NSNotificationCenter *notification_center = [NSNotificationCenter defaultCenter];

	[notification_center
		addObserver : self 
		   selector : @selector(forwardNotification:)
			   name : nil 
			 object : _task];
		
	[_task launch];

	[NSThread detachNewThreadSelector:@selector(readStdOut:)
							 toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(readStdErr:)
                             toTarget:self withObject:nil];

}

- (void)forwardNotification:(NSNotification *)notification
{
#if useLog
	NSLog(@"will forwardNotification PipingTask");
#endif
	NSNotificationCenter *n_center = [NSNotificationCenter defaultCenter];
	[n_center removeObserver:self];
	[n_center postNotification:
		[NSNotification notificationWithName:[notification name]
									  object:self userInfo:_userInfo]];
}

- (void)readStdOut:(id)arg
{
	@autoreleasepool {
		NSPipe *standardOutput = [_task standardOutput];
		
		NSFileHandle *out_h = [standardOutput fileHandleForReading];
		while(1) {
			//NSLog(@"will read");
			NSData *data_out = [out_h availableData];
			
			if ([data_out length]) {
				[_stdoutData appendData:data_out];
			} else {
				break;
			}
		}
		
		[out_h closeFile];
	}
#if useLog
	NSLog(@"end readStdOut PipingTask");
#endif
	[NSThread exit];
}

- (void)readStdErr:(id)arg
{
    @autoreleasepool {
        NSPipe *pipe_stderr = [_task standardError];
        
        NSFileHandle *out_h = [pipe_stderr fileHandleForReading];
        while(1) {
            //NSLog(@"will read");
            NSData *data_out = [out_h availableData];
            
            if ([data_out length]) {
                [_stderrData appendData:data_out];
            } else {
                break;
            }
        }
        
        [out_h closeFile];
    }
#if useLog
    NSLog(@"end readStdError PipingTask");
#endif
    [NSThread exit];
}

- (NSString *)stdoutString
{
	return [[NSString alloc] initWithData:_stdoutData encoding:NSUTF8StringEncoding];
}

- (NSString *)stderrString
{
    return [[NSString alloc] initWithData:_stderrData encoding:NSUTF8StringEncoding];
}

#pragma mark bridges to NSTask

- (void)terminate
{
	[_task terminate];
}

- (NSArray *)arguments
{
	return [_task arguments];
}

- (int)terminationStatus
{
	return _task.terminationStatus;
}

- (NSString *)launchPath
{
	return [_task launchPath];
}

- (void)setArguments:(NSArray *)arguments
{
	[_task setArguments:arguments];
}

- (void)setLaunchPath:(NSString *)path
{
	[_task setLaunchPath:path];
}

- (void)setCurrentDirectoryPath:(NSString*)path
{
	[_task setCurrentDirectoryPath:path];
} 

@end
