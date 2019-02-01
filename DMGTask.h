#import <Foundation/Foundation.h>
#import "PipingTask.h"

@interface DMGTask : NSObject {
    BOOL aborted;
}

@property(nonatomic, strong) NSString *statusMessage;
@property(nonatomic, strong) NSString *terminationMessage;
@property(nonatomic, strong) NSString *workingLocation;
@property(nonatomic, strong) NSString *devEntry;
@property(nonatomic, strong) NSString *mountPoint;
@property(nonatomic, strong) NSString *dmgPath;
@property(nonatomic, strong) PipingTask *currentTask;
@property(nonatomic, assign) int terminationStatus;
@property(readonly)BOOL isSuccess;
/*
- (void)attachDiskImage:(NSString *)path;
- (void)detachDiskImage:(NSString *)dev;
- (void)dittoPath:(NSString *)srcPath toPath:(NSString *)destPath;
- (PipingTask *)detachNow;
- (void)abortTask;
*/

+ (DMGTask *)dmgTaskAt:(NSString *)workingLocation;

- (BOOL)setInternetEnable:(NSString *)path enable:(BOOL)flag;

- (void)createDiskImage:(NSString *)destination
             volumeName:(NSString *)volname
                   type:(NSString *)type
             filesystem:(NSString *)fs
                   size:(NSString *)size
      completionHandler:(void(^)(BOOL))handler;

- (void)createDiskImage:(NSString *)destination
              srcfolder:(NSString *)srcfolder
             volumeName:(NSString *)volname
             filesystem:(NSString *)fs
                   size:(NSString *)size
       compressionLevel:(int)compressionLevel
      completionHandler:(void(^)(BOOL))handler;

- (void)convertDiskImage:(NSString *)source
                  format:(NSString *)format
             destination:(NSString *)destination
         compressionLevel:(int)compressionLevel
       completionHandler:(void(^)(BOOL))handler;

- (void)makeHibridFromSource:(NSString *)source
                 destination:(NSString *)destination
                    volumeName:(NSString *)disName
            completionHadler:(void (^)(BOOL))handler;

- (void)attachDiskImage:(NSString *)dmgPath
      completionHandler:(void (^)(BOOL))handler;

- (void)detachDiskImage:(NSString *)dev
      completionHandler:(void (^)(BOOL))handler;

- (PipingTask *)detachNow;
- (PipingTask *)detachNow:(NSString *)devEntry;

- (void)cpItems:(NSEnumerator *)enumerator
      destination:(NSString *)destination
completionHandler:(void (^)(BOOL))handler;

- (void)dittoItems:(NSEnumerator *)enumerator
      destination:(NSString *)destination
     isOnlyFolder:(BOOL)isOnlyFolder
completionHandler:(void (^)(BOOL))handler;

- (void)deleteDSStore:(NSString *)path
    completionHandler:(void (^)(BOOL))handler;

- (void)abortTask;

@end
