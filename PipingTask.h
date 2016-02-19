#import <Cocoa/Cocoa.h>


@interface PipingTask : NSObject {

}

@property(nonatomic, retain) NSMutableData *stdoutData;
@property(nonatomic, retain) NSMutableData *stderrData;
@property(nonatomic, retain) NSTask *task;
@property(nonatomic, retain) NSFileHandle *errHandle;
@property(nonatomic, retain) NSDictionary *userInfo;

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
