#import "PipingTask.h"


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
	[task release];
	[stdoutData release];
	[stderrData release];
	[super dealloc];
}

- (void)waitUntilExit
{
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
	[[NSNotificationCenter defaultCenter]
		addObserver:self selector:@selector(forwardNotification:)
		name:nil object:task];
		
	[task launch];
	[NSThread detachNewThreadSelector:@selector(readStdOut:)
							 toTarget:self withObject:nil];

	[NSThread detachNewThreadSelector:@selector(readStdErr:)
							 toTarget:self withObject:nil];
}

- (void)forwardNotification:(NSNotification *)notification
{
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
}

- (void)readStdErr:(id)arg
{
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
}

- (NSString *)stdoutString
{
	return [[[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding] autorelease];
}

- (NSString *)stderrString
{
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
