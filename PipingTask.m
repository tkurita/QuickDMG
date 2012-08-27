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
		task  = [[NSTask alloc] init];
    }
	
    return self;
}

- (void)dealloc
{
#if useLog
	NSLog(@"will dealloc PipingTask");
#endif
	[errHandle closeFile];
	[errHandle release];
	[task release];
	[stdoutData release];
	[stderrData release];
	[userInfo release];
	[super dealloc];
}

- (void)setUserInfo:(NSDictionary *)info
{
	[info retain];
	[userInfo autorelease];
	userInfo = info;
}

- (NSDictionary *)userInfo
{
	return userInfo;
}

- (void)waitUntilExit
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[task waitUntilExit];
}

- (void)launch
{
	[stdoutData release];
	stdoutData = [[NSMutableData alloc] init];
	[stderrData release];
	stderrData = [[NSMutableData alloc] init];
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError:[NSPipe pipe]];
	NSNotificationCenter *notification_center = [NSNotificationCenter defaultCenter];
	
	errHandle = [[[task standardError] fileHandleForReading] retain];
    [notification_center
        addObserver : self 
           selector : @selector(readStdErr:) 
               name : NSFileHandleReadCompletionNotification 
             object : errHandle]; 

	[errHandle readInBackgroundAndNotify];

	[notification_center
		addObserver : self 
		   selector : @selector(forwardNotification:)
			   name : nil 
			 object : task];
		
	[task launch];

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
									  object:self userInfo:userInfo]];
}

- (void)readStdOut:(id)arg
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	NSPipe *standardOutput = [task standardOutput];
	
	NSFileHandle *out_h = [standardOutput fileHandleForReading];
	while(1) {
		//NSLog(@"will read");
		NSData *data_out = [out_h availableData];
		
		if ([data_out length]) {
			[stdoutData appendData:data_out];
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
	[stderrData appendData:
		[[notification userInfo] objectForKey:NSFileHandleNotificationDataItem]]; 
		
     
    if (task && [task isRunning]) {
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
	return [[[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding] autorelease];
}

- (NSString *)stderrString
{	
	if (![stderrData length]) {
	  [stderrData appendData:[errHandle availableData]];
	}
	return [[[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding] autorelease];
}

#pragma mark bridges to NSTask

- (void)terminate
{
	[task terminate];
}

- (NSArray *)arguments
{
	return [task arguments];
}

- (int)terminationStatus
{
	return [task terminationStatus];
}

- (NSString *)launchPath
{
	return [task launchPath];
}

- (void)setArguments:(NSArray *)arguments
{
	[task setArguments:arguments];
}

- (void)setLaunchPath:(NSString *)path
{
	[task setLaunchPath:path];
}

- (void)setCurrentDirectoryPath:(NSString*)path
{
	[task setCurrentDirectoryPath:path];
} 

@end
