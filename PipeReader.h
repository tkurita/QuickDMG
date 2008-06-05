#import <Cocoa/Cocoa.h>


@interface PipeReader : NSObject {
	NSMutableData *stdoutData;
	NSMutableData *stderrData;
	NSTask *targetTask;
}

+ (PipeReader *)readerWithTask:(NSTask *)aTask;
- (void)setTargetTask:(NSTask *)aTask;
- (NSString *)stdoutString;
- (NSString *)stderrString;

@end
