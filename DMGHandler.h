#import <Cocoa/Cocoa.h>
#import "PipingTask.h"

@interface DMGHandler : NSObject {
	NSString *statusMessage;
	NSString *terminationMessage;
	NSString *workingLocation;
	NSString *devEntry;
	NSString *mountPoint;
	PipingTask *currentTask;
	int terminationStatus;	
	id delegate;
}

@property(retain) NSString *statusMessage;
@property(retain) NSString *terminationMessage;
@property(retain) NSString *workingLocation;
@property(retain) NSString *devEntry;
@property(retain) NSString *mountPoint;
@property(retain) PipingTask *currentTask;
@property(assign) int terminationStatus;
@property(assign) id delegate;

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
