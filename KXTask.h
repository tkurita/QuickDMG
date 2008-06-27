#import <Cocoa/Cocoa.h>


@interface KXTask : NSTask {
	NSMutableData *stdoutData;
	NSMutableData *stderrData;
}

- (NSString *)stdoutString;
- (NSString *)stderrString;

@end
