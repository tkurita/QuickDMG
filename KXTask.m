#import "KXTask.h"


@implementation KXTask

- (void)dealloc
{
	[stdoutData release];
	[stderrData release];
	[super dealloc];
}

- (void)launch
{
	[stdoutData release];
	stdoutData = [[NSMutableData alloc] init];
	[stderrData release];
	stderrData = [[NSMutableData alloc] init];
	[super launch];
	[NSThread detachNewThreadSelector:@selector(readStdOut:)
							 toTarget:self withObject:nil];

	[NSThread detachNewThreadSelector:@selector(readStdErr:)
							 toTarget:self withObject:nil];
}

- (void)readStdOut:(id)arg
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	NSPipe *standardOutput = [self standardOutput];
	
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
	NSPipe *standardError = [self standardError];
	
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

@end
