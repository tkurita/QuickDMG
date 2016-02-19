#import <Cocoa/Cocoa.h>


@interface PipingTask : NSObject {

}

@property(nonatomic, strong) NSMutableData *stdoutData;
@property(nonatomic, strong) NSMutableData *stderrData;
@property(nonatomic, strong) NSTask *task;
@property(nonatomic, strong) NSFileHandle *errHandle;
@property(nonatomic, strong) NSDictionary *userInfo;

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
