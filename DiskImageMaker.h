#import <Cocoa/Cocoa.h>
#import "DMGDocumentProtocol.h"
#import "StringExtra.h"
#import "DMGTask.h"
#import "DMGOptionsProtocol.h"
#import "DMGWindowControllerProtocol.h"
#import "PipingTask.h"

@interface DiskImageMaker : NSObject {
	//related source item
	unsigned long long sourceSize;

	//related disk image file
	float requireSpaceRatio;
	float expectedCompressRatio;
	
	//parameters of setup status
	BOOL willBeConverted;
	
	//parameters of mid-flow
	BOOL isOnlyFolder;
	
	//temporary stocked parameters for internal use
    BOOL aborted;
}


//public use
- (void)setCustomDmgName:(NSString *)theDmgName;
- (NSString *)dmgPath;

#pragma mark initilize
- (id)initWithSourceItem:(NSDocument<DMGDocument> *)anItem;
- (id)initWithSourceItems:(NSArray *)array;

#pragma mark launching tasks
//pubulic
- (BOOL)checkCondition:(NSWindowController<DMGWindowController> *)aWindowController;
- (void)createDiskImageWithCompletaionHandler:(void (^)(BOOL))handler;
- (void)aboartTask;

//private
- (BOOL)checkWorkingLocationPermission;
- (BOOL)checkFreeSpace;
- (void)convertDiskImage;

#pragma mark posting notification
//private
- (void) postStatusNotification:(NSString *) message;

#pragma mark setup methods
@property (nonatomic, strong) id<DMGOptions> dmgOptions;
- (void)setDestination:(NSString *)aPath replacing:(BOOL)aFlag;
- (NSString *)resolveDmgName;

#pragma mark accessor methods
//public
@property(assign) int terminationStatus;

@property(nonatomic, strong) NSString *terminationMessage;
@property(nonatomic, strong) NSURL *workingLocationURL;
@property(nonatomic, strong) NSString *diskName;
@property(copy) void (^terminationHandler)(BOOL);
@property(assign) BOOL isReplacing;

//related source item
@property (nonatomic, strong) NSArray *sourceItems;

#pragma mark private use
@property (nonatomic, strong) NSString *dmgName;
@property(nonatomic, strong) NSString *devEntry;
@property(nonatomic, strong) DMGTask *currentDMGTask;
@property(nonatomic, strong) NSString *mountPoint;
@property(nonatomic, strong) NSString *tmpDir;
//target path to convert dmg file
@property(nonatomic, strong) NSString *sourceDmgPath;

@end
