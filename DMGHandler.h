#import <Cocoa/Cocoa.h>
#import "PipingTask.h"

@interface DMGHandler : NSObject

@property(nonatomic, strong) NSString *statusMessage;
@property(nonatomic, strong) NSString *terminationMessage;
@property(nonatomic, strong) NSString *workingLocation;
@property(nonatomic, strong) NSString *devEntry;
@property(nonatomic, strong) NSString *mountPoint;
@property(nonatomic, strong) PipingTask *currentTask;
@property(nonatomic, assign) int terminationStatus;
@property(nonatomic, unsafe_unretained) id delegate;

- (void)attachDiskImage:(NSString *)path;
- (void)detachDiskImage:(NSString *)dev;
- (void)dittoPath:(NSString *)srcPath toPath:(NSString *)destPath;
- (PipingTask *)detachNow;
- (void)abortTask;

+ (DMGHandler *)dmgHandlerWithDelegate:(id)object;

@end

@protocol DMGHandlerDelegateProtocol

- (void)diskImageAttached:(DMGHandler *)sender;
- (void)diskImageDetached:(DMGHandler *)sender;
- (void)dittoFinished:(DMGHandler *)sender;

@end
