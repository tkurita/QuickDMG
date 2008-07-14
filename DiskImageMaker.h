#import <Cocoa/Cocoa.h>
#import "DMGDocumentProtocol.h"
#import "stringExtra.h"
#import "DMGOptionsProtocol.h"
#import "DMGWindowControllerProtocol.h"
#import "PipingTask.h"

@interface DiskImageMaker : NSObject {
	//related source item
	NSArray *sourceItems;
	unsigned long long sourceSize;
	NSEnumerator *sourceEnumerator;
	
	//related disk image file
	NSString *workingLocation;
	NSString *diskName;
	float requireSpaceRatio;
	float expectedCompressRatio;
	NSString *sourceDmgPath; //target path to convert dmg file
	NSString *dmgName;
	id<DMGOptions> dmgOptions;
	
	//parameters of setup status
	BOOL willBeConverted;
	BOOL isReplacing;
	
	//parameters of mid-flow
	NSString *devEntry;
	NSString *mountPoint;
	int terminationStatus;
	NSString *tmpDir;
	BOOL isOnlyFolder;
	
	//show dask results
	NSString *terminationMessage;

	//temporary stocked parameters for internal use
	NSNotificationCenter *myNotiCenter;
	BOOL isAttached; // disk image file が attach されている状態のはずなら YES
	PipingTask *currentTask;
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
- (void)setDMGOptions:(id<DMGOptions>)anObject;
- (void)setDestination:(NSString *)aPath replacing:(BOOL)aFlag;
- (NSString *)resolveDmgName;

#pragma mark accessor methods
//public
- (int)terminationStatus;

- (NSString *)terminationMessage;
- (void)setTerminationMessage:(NSString *)theString;
- (NSString *)workingLocation;
- (void)setWorkingLocation:(NSString *)theWorkingLocation;
- (void)setReplacing:(BOOL)aFlag;

//private
- (void)setTmpDir:(NSString *)path;
- (void)setDiskName:(NSString *)theDiskName;

- (NSString *)dmgName;
- (void)setDmgName:(NSString *)theDmgName;

- (void)setDevEntry:(NSString *)theDevEntry;
- (void)setCurrentTask:(PipingTask *)aTask;
- (void)setMountPoint:(NSString *)theMountPoint;

#pragma mark private use
//- (NSString *) uniqueName:(NSString *)baseName location:(NSString*)dirPath; //baseName に dmgSuffix を付けて、workingLocation で unique な名前を求める
- (BOOL) checkPreviousTask:(NSNotification *)notification;

@end
