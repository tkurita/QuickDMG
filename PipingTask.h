#import <Cocoa/Cocoa.h>


@interface PipingTask : NSTask {
	NSMutableData *stdoutData;
	NSMutableData *stderrData;
}

- (NSString *)stdoutString;
- (NSString *)stderrString;

@end
