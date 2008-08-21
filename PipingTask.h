#import <Cocoa/Cocoa.h>


@interface PipingTask : NSObject {
	NSMutableData *stdoutData;
	NSMutableData *stderrData;
	NSTask *task;
	NSFileHandle *errHandle;
}

+ (PipingTask *)launchedTaskWithLaunchPath:path arguments:arguments;

- (NSString *)stdoutString;
- (NSString *)stderrString;

- (void)waitUntilExit;
- (void)launch;

#pragma mark bridges to NSTask
- (void)terminate;
- (NSArray *)arguments;
- (int)terminationStatus;
- (NSString *)launchPath;
- (void)setArguments:(NSArray *)arguments;
- (void)setLaunchPath:(NSString *)path;
- (void)setCurrentDirectoryPath:(NSString*)path;

@end
