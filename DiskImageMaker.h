#import <Cocoa/Cocoa.h>
#import "stringExtra.h"

@interface DiskImageMaker : NSObject {
	//related source item
	NSString *sourcePath;
	NSString *sourceName;
	unsigned long long sourceSize;
	
	//related disk image file
	NSString *workingLocation;
	NSString *diskName;
	float requireSpaceRatio;
	float expectedCompressRatio;
	NSString *sourceDmgPath; //target path to convert dmg file
	NSString *dmgSuffix; 
	NSString *dmgName;
	NSString *dmgFormat;
	
	//parameters of setup status
	BOOL isDmgNameDefined;
	BOOL willBeConverted;
	BOOL internetEnableFlag;
	NSString *zlibLevel;
	BOOL deleteDSStoreFlag;
	
	//parameters of mid-flow
	NSString *devEntry;
	NSString *mountPoint;
	int terminationStatus;
	NSString *tmpDir;
	
	//show dask results
	NSString *terminationMessage;

	//temporary stocked parameters for internal use
	NSNotificationCenter *myNotiCenter;
	BOOL isAttached; // disk image file が attach されている状態のはずなら YES
	NSTask *currentTask;
}

//public use
- (void)setCustomDmgName:(NSString *)theDmgName;
- (NSString *)dmgPath;

#pragma mark initilize
- (id)initWithSourcePath:(NSString *) sourcePath;

#pragma mark launching tasks
//pubulic
- (BOOL)checkFreeSpace;
- (void)createDiskImage;

//private
- (void)convertDiskImage;
- (void)internetEnable:(NSNotification *)notification;
- (void)convertTmpDiskImage:(NSNotification *)notification;

#pragma mark posting notification
//private
- (void) dmgTaskTerminate:(NSNotification *)notification;
- (void) postStatusNotification:(NSString *) message;

#pragma mark private use
- (NSString *) uniqueName:(NSString *)baseName location:(NSString*)dirPath; //baseName に dmgSuffix を付けて、workingLocation で unique な名前を求める
- (BOOL) checkPreviousTask:(NSNotification *)notification;

#pragma mark accessor methods
//public
- (int)terminationStatus;

- (NSString *)terminationMessage;
- (void)setTerminationMessage:(NSString *)theString;

- (void)setDmgFormat:(NSString *)formatID;

- (NSString *)dmgSuffix;
- (void)setDmgSuffix:(NSString *)formatSuffix;

- (void)setInternetEnable:(BOOL)yesOrNo;
- (void)setCompressionLevel:(NSString *)zlibLevel;

- (NSString *)workingLocation;
- (void)setWorkingLocation:(NSString *)theWorkingLocation;

- (void)setDeleteDSStore:(BOOL)yesOrNo;

//private
- (void)setSourceName:(NSString *)theSourceName;
- (void)setTmpDir:(NSString *)path;
- (void)setDiskName:(NSString *)theDiskName;

- (NSString *)dmgName;
- (void)setDmgName:(NSString *)theDmgName;

- (NSString *)sourcePath;
- (void)setSourcePath:(NSString *)theSourcePath;

- (void)setDevEntry:(NSString *)theDevEntry;
- (void)setCurrentTask:(NSTask *)aTask;
- (void)setMountPoint:(NSString *)theMountPoint;
@end
