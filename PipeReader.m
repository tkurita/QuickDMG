#import "PipeReader.h"

@implementation PipeReader
- (id)init
{
	[super init];
	stdoutData = [[NSMutableData alloc] init];
	stderrData = [[NSMutableData alloc] init];
	return self;
}

- (void)dealloc
{
	[stdoutData release];
	[stderrData release];
	[targetTask release];
	[super dealloc];
}

- (id)initWithTask:(NSTask *)aTask
{
	[self init];
	[self setTargetTask:aTask];
	[NSThread detachNewThreadSelector:@selector(readStdOut:)
							 toTarget:self withObject:aTask];

	[NSThread detachNewThreadSelector:@selector(readStdErr:)
							 toTarget:self withObject:aTask];
	
	return self;
}

+ (PipeReader *)readerWithTask:(NSTask *)aTask
{
	return [[[self alloc] initWithTask:aTask] autorelease];
}

- (NSString *)stdoutString
{
	return [[[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding] autorelease];
}

- (NSString *)stderrString
{
	return [[[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding] autorelease];
}

- (void)readStdErr:(NSTask *)aTask
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	NSPipe *standardError = [[[aTask standardError] retain] autorelease];
	
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

- (void)readStdOut:(NSTask *)aTask
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	NSPipe *standardOutput = [[[aTask standardOutput] retain] autorelease];
	
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

- (void)setTargetTask:(NSTask *)aTask
{
	[aTask retain];
	[targetTask release];
	targetTask = aTask;
}

@end
