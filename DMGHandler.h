#import <Cocoa/Cocoa.h>
#import "PipingTask.h"

@interface DMGHandler : NSObject

@property(nonatomic, retain) NSString *statusMessage;
@property(nonatomic, retain) NSString *terminationMessage;
@property(nonatomic, retain) NSString *workingLocation;
@property(nonatomic, retain) NSString *devEntry;
@property(nonatomic, retain) NSString *mountPoint;
@property(nonatomic, retain) PipingTask *currentTask;
@property(nonatomic, assign) int terminationStatus;
@property(nonatomic, assign) id delegate;

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
