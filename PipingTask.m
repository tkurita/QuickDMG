#import "PipingTask.h"

#define useLog 0

@implementation PipingTask

+ (PipingTask *)launchedTaskWithLaunchPath:path arguments:arguments
{
	PipingTask *a_task = [[self alloc] init];
	[a_task setLaunchPath:path];
	[a_task setArguments:arguments];
	[a_task launch];
	return a_task;
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
	[super dealloc];
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
	[notification_center
		addObserver : self 
		   selector : @selector(forwardNotification:)
			   name : nil 
			 object : task];
	
	errHandle = [[[task standardError] fileHandleForReading] retain];
    [notification_center
        addObserver : self 
           selector : @selector(readStdErr:) 
               name : NSFileHandleReadCompletionNotification 
             object : errHandle]; 

	[errHandle readInBackgroundAndNotify];
		
	[task launch];

	[NSThread detachNewThreadSelector:@selector(readStdOut:)
							 toTarget:self withObject:nil];

/*
	[NSThread detachNewThreadSelector:@selector(readStdErr:)
							 toTarget:self withObject:nil];
*/
}

- (void)forwardNotification:(NSNotification *)notification
{
#if useLog
	NSLog(@"will forwardNotification PipingTask");
#endif
	/*
	if (![task isRunning]) {
		[errHandle closeFile];
		[errHandle release];
	}*/
	NSNotificationCenter *n_center = [NSNotificationCenter defaultCenter];
	[n_center removeObserver:self];
	[n_center postNotification:
		[NSNotification notificationWithName:[notification name]
						object:self]];
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
    } 

#if useLog
	NSLog(@"end readStdErr PipingTask");
#endif
}


/*
- (void)readStdErr:(id)arg
{
#if useLog
	NSLog(@"start readStdErr PipingTask");
#endif
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	NSPipe *standardError = [task standardError];
	
	NSFileHandle *err_h = [standardError fileHandleForReading];
	while(1) {
		NSData *data_err = [err_h availableData];

		if (data_err) {
			[stderrData appendData:data_err];
		} else {
			break;
		}
		
	}
	
	[err_h closeFile];
	[pool release];
#if useLog
	NSLog(@"end readStdErr PipingTask");
#endif
	[NSThread exit];
}
*/
- (NSString *)stdoutString
{
	return [[[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding] autorelease];
}

- (NSString *)stderrString
{	
	if (!stderrData) {
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
