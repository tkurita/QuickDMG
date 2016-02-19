#import <Cocoa/Cocoa.h>
#import "DMGDocumentProtocol.h"
#import "StringExtra.h"
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
	BOOL isReplacing;
	
	//parameters of mid-flow
	BOOL isOnlyFolder;
	
	//temporary stocked parameters for internal use
	BOOL isAttached; // disk image file が attach されている状態のはずなら YES
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
- (void)createDiskImage;
- (void)aboartTask;

//private
- (BOOL)checkWorkingLocationPermission;
- (BOOL)checkFreeSpace;
- (void)convertDiskImage;
- (void)internetEnable:(NSNotification *)notification;
- (void)convertTmpDiskImage:(NSNotification *)notification;

#pragma mark posting notification
//private
- (void) dmgTaskTerminate:(NSNotification *)notification;
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

//related source item
@property (nonatomic, strong) NSArray *sourceItems;

//private
@property (nonatomic, strong) NSString *dmgName;
@property(nonatomic, strong) NSString *devEntry;
@property(nonatomic, strong) PipingTask *currentTask;
@property(nonatomic, strong) NSString *mountPoint;
@property(nonatomic, strong) NSString *tmpDir;
//target path to convert dmg file
@property(nonatomic, strong) NSString *sourceDmgPath;
@property(nonatomic, strong) NSNotificationCenter *myNotiCenter;

#pragma mark private use
//- (NSString *) uniqueName:(NSString *)baseName location:(NSString*)dirPath; //baseName に dmgSuffix を付けて、workingLocation で unique な名前を求める
- (BOOL) checkPreviousTask:(NSNotification *)notification;

@end
