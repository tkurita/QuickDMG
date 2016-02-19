#import "PipingTask.h"

#define useLog 0

@implementation PipingTask

+ (PipingTask *)launchedTaskWithLaunchPath:path arguments:arguments
{
	PipingTask *a_task = [[self alloc] init];
	[a_task setLaunchPath:path];
	[a_task setArguments:arguments];
	[a_task launch];
	return [a_task autorelease];
}

- (id)init
{
    if (self = [super init]) {
		self.task  = [[NSTask new] autorelease];
    }
	
    return self;
}

- (void)dealloc
{
#if useLog
	NSLog(@"will dealloc PipingTask");
#endif
	[_errHandle closeFile];
	[_errHandle release];
	[_task release];
	[_stdoutData release];
	[_stderrData release];
	[_userInfo release];
	[super dealloc];
}

- (void)waitUntilExit
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_task waitUntilExit];
}

- (void)launch
{
	self.stdoutData = nil;
	self.stdoutData = [[NSMutableData new] autorelease];
	self.stderrData = nil;
	self.stderrData = [[NSMutableData new] autorelease];
	[_task setStandardOutput:[NSPipe pipe]];
	[_task setStandardError:[NSPipe pipe]];
	NSNotificationCenter *notification_center = [NSNotificationCenter defaultCenter];
	
	self.errHandle = [[[_task standardError] fileHandleForReading] retain];
    [notification_center
        addObserver : self 
           selector : @selector(readStdErr:) 
               name : NSFileHandleReadCompletionNotification 
             object : _errHandle]; 

	[_errHandle readInBackgroundAndNotify];

	[notification_center
		addObserver : self 
		   selector : @selector(forwardNotification:)
			   name : nil 
			 object : _task];
		
	[_task launch];

	[NSThread detachNewThreadSelector:@selector(readStdOut:)
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
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
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
	[pool release];
#if useLog
	NSLog(@"end readStdOut PipingTask");
#endif
	[NSThread exit];
}


- (void)readStdErr:(NSNotification *)notification
{
#if useLog
	NSLog(@"start readStdErr PipingTask");
#endif
	[_stderrData appendData:
		[notification userInfo][NSFileHandleNotificationDataItem]]; 
		
     
    if (_task && [_task isRunning]) {
        [[notification object] readInBackgroundAndNotify]; 
	/*
    } else {
		[[NSNotificationCenter defaultCenter] removeObserver:self 
								name:NSFileHandleReadCompletionNotification 
								object:[notification object]];
	*/
	}
#if useLog
	NSLog(@"end readStdErr PipingTask");
#endif
}

- (NSString *)stdoutString
{
	return [[[NSString alloc] initWithData:_stdoutData encoding:NSUTF8StringEncoding] autorelease];
}

- (NSString *)stderrString
{	
	if (![_stderrData length]) {
	  [_stderrData appendData:[_errHandle availableData]];
	}
	return [[[NSString alloc] initWithData:_stderrData encoding:NSUTF8StringEncoding] autorelease];
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
	return [_task terminationStatus];
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
