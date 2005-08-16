#import "DiskImageMaker.h"

void setOutputToPipe(NSTask *task)
{
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError:[NSPipe pipe]];
}

void showTaskResult(NSTask *theTask)
{
	NSData * taskResult = [[[theTask standardOutput] fileHandleForReading] availableData];
	NSString * resultString = [[NSString alloc] initWithData:taskResult encoding:NSUTF8StringEncoding];
	//NSLog(resultString);
	[resultString release];
}

id getTaskResult(NSTask *theTask)
{
	NSData * taskResult = [[[theTask standardOutput] fileHandleForReading] availableData];
	NSString * resultString = [[NSString alloc] initWithData:taskResult encoding:NSUTF8StringEncoding];
	id resultProp = [resultString propertyList];
	[resultString autorelease];
	return resultProp;
}

NSString *getTaskError(NSTask *theTask)
{
	NSData *taskResult = [[[theTask standardError] fileHandleForReading] availableData];
	NSString *resultString = [[NSString alloc] initWithData:taskResult encoding:NSUTF8StringEncoding];
	[resultString autorelease];
	return resultString;
}

@implementation DiskImageMaker

#pragma mark init and dealloc
- (id) init
{
	[super init];
	dmgSuffix = @"dmg";
	requireSpaceRatio = 1.0;
	zlibLevel = @"1";
	myNotiCenter = [NSNotificationCenter defaultCenter];
	internetEnableFlag = NO;
	isDmgNameDefined = NO;
	return self;
	expectedCompressRatio = 0.7;
	isAttached = NO;
}

- (id) initWithSourcePath:(NSString *) path
{
	[self init];
	[self setSourcePath:path];
	[self setWorkingLocation:[sourcePath stringByDeletingLastPathComponent]];
	[self setSourceName:[sourcePath lastPathComponent]];
	[self setDiskName:[NSString stringWithString:sourceName]];
	[self setDmgName:[self uniqueName:diskName location:workingLocation]];
	return self;
}

- (void)dealloc
{
	[myNotiCenter removeObserver:self];
	[sourceDmgPath release];
	[dmgFormat release];
	[dmgSuffix release];
	[zlibLevel release];
	[mountPoint release];
	[devEntry release];
	[terminationMessage release];
	[sourcePath release];
	[workingLocation release];
	[sourceName release];
	[diskName release];
	[tmpDir release];
	[super dealloc];
}

#pragma mark othors

- (BOOL) checkFreeSpace
{
	[self postStatusNotification: NSLocalizedString(@"Checking free space of disks.",
													"")];
	NSFileManager *myFileManager = [NSFileManager defaultManager];
	NSDictionary * fileInfo = [myFileManager fileAttributesAtPath:sourcePath traverseLink:NO];
	isSourceFolder = ([fileInfo fileType] == NSFileTypeDirectory);
	if (isSourceFolder) {
		NSTask * du =[[NSTask alloc] init];
		[du setLaunchPath:@"/usr/bin/du"];
		[du setArguments:[NSArray arrayWithObjects:@"-sk",sourcePath,nil]];
		
		NSPipe * duOutput = [NSPipe pipe];
		[du setStandardOutput:duOutput];
		[du launch];
		[du waitUntilExit];
		NSData * duData = [[duOutput fileHandleForReading] availableData];
		sourceSize = [[[[NSString alloc] initWithData:duData encoding: NSUTF8StringEncoding] autorelease] intValue];
		//sourceSize = sourceSize * 1024 * 1.1;
		sourceSize = (sourceSize * 1024 *1.1)+200000;
		[du release];
	}
	else {
		sourceSize = [fileInfo fileSize] + 200000;
	}
	
	NSDictionary *infoWorkingDisk = [myFileManager fileSystemAttributesAtPath:workingLocation];
	unsigned long long freeSize = [[infoWorkingDisk objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
	
	self->willBeConverted = !([dmgFormat isEqualToString:@"UDRW"]||[dmgFormat isEqualToString:@"UDSP"]);
	
	if (willBeConverted) {
		[self setTmpDir:NSTemporaryDirectory()];
		NSDictionary *infoTmpDisk = [myFileManager fileSystemAttributesAtPath:tmpDir];
		
		if ([[infoTmpDisk objectForKey:NSFileSystemNumber] isEqualToNumber:[infoWorkingDisk objectForKey:NSFileSystemNumber]]) {
			requireSpaceRatio = 1 + expectedCompressRatio;
		}
		else {
			unsigned long long freeSizeTmpDir = [[infoTmpDisk objectForKey:@"NSFileSystemFreeSize"] unsignedLongLongValue];
			
			if (freeSizeTmpDir > sourceSize) {
				if ([dmgFormat isEqualToString:@"UDZO"])
					requireSpaceRatio = expectedCompressRatio;
			}
			else {
				return NO;
			}
		}
	}
	else {
		requireSpaceRatio = 1;
	}
		
	if ( freeSize > requireSpaceRatio*sourceSize)
		return YES;
	else
		return NO;
}

- (NSString *)uniqueName:(NSString *)baseName suffix:(NSString *)theSuffix location:(NSString *)dirPath;
{
	NSString *newName = [baseName stringByAppendingPathExtension:theSuffix];
	NSString *checkPath = [dirPath stringByAppendingPathComponent:newName];
	short i = 1;
	NSFileManager *myFileManager = [NSFileManager defaultManager];
	while ([myFileManager fileExistsAtPath:checkPath]){
		NSNumber *numberSuffix = [NSNumber numberWithShort:i++];
		newName = [[baseName stringByAppendingPathExtension:[numberSuffix stringValue]] stringByAppendingPathExtension:theSuffix];
		checkPath = [dirPath stringByAppendingPathComponent:newName];
	}
	return newName;	
}

- (NSString *)uniqueName:(NSString *)baseName location:(NSString*)dirPath;
{
	NSString * newName = [baseName stringByAppendingPathExtension:dmgSuffix];
	NSString * checkPath = [dirPath stringByAppendingPathComponent:newName];
	NSFileManager *myFileManager = [NSFileManager defaultManager];
	short i = 1;
	while ([myFileManager fileExistsAtPath:checkPath]){
		NSNumber * numberSuffix = [NSNumber numberWithShort:i++];
		newName = [[baseName stringByAppendingPathExtension:[numberSuffix stringValue]] stringByAppendingPathExtension:dmgSuffix];
		checkPath = [workingLocation stringByAppendingPathComponent:newName];
	}
	return newName;
}

- (NSTask *)hdiUtilTask
{
	NSTask *theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:@"/usr/bin/hdiutil"];
	[theTask setCurrentDirectoryPath:workingLocation];
	[theTask setStandardOutput:[NSPipe pipe]];
	[theTask setStandardError:[NSPipe pipe]];
	return [theTask autorelease];
}

- (void) copySourceItem:(NSNotification *) notification
{
	//NSLog(@"start copySourceItem:");
	if (![self checkPreviousTask:notification]) {
		return;
	}
	
	[self postStatusNotification: NSLocalizedString(@"Copying source files.","")];
	NSTask* dmgTask = [notification object];
	//showTaskResult(dmgTask);
	NSDictionary * resultDict = getTaskResult(dmgTask);
	//NSLog([resultDict description]);
	resultDict = [[resultDict objectForKey:@"system-entities"] objectAtIndex:0];
	[self setDevEntry:[resultDict objectForKey:@"dev-entry"]];
	[self setMountPoint:[resultDict objectForKey:@"mount-point"]];
	
	NSTask * dittoTask = [[NSTask alloc] init];
	[dittoTask setLaunchPath:@"/usr/bin/ditto"];
	setOutputToPipe(dittoTask);
	[dittoTask setArguments:[NSArray arrayWithObjects:@"--rsrc",sourcePath,mountPoint,nil]];
	
	if (deleteDSStoreFlag) {
		[myNotiCenter addObserver:self selector:@selector(deleteDSStore:)				name:NSTaskDidTerminateNotification object:dittoTask];		
	}
	else {
		[myNotiCenter addObserver:self selector:@selector(detachDiskImage:) name:NSTaskDidTerminateNotification object:dittoTask];
	}
	
	[self setCurrentTask:[dittoTask autorelease]];
	[dittoTask launch];
	//NSLog(@"end copySourceItem:");
}

- (void)internetEnable:(NSNotification *)notification
{
	if (![self checkPreviousTask:notification]) {
		return;
	}

	[self postStatusNotification:NSLocalizedString(@"Setting internet-enable option.","")];
	NSTask * dmgTask = [self hdiUtilTask];
	[dmgTask setArguments:[NSArray arrayWithObjects:@"internet-enable",@"-yes", dmgName, nil]];
	[myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:) name:NSTaskDidTerminateNotification object:dmgTask];
	[self setCurrentTask:dmgTask];
	[dmgTask launch];
}

- (void) detachDiskImage:(NSNotification *)notification
{
	//NSLog(@"start detachDiskImage");
	if (![self checkPreviousTask:notification]) {
		return;
	}
	
	[self postStatusNotification:NSLocalizedString(@"Detaching a disk image file.","")];
	NSTask * dmgTask = [self hdiUtilTask];
	[dmgTask setArguments:[NSArray arrayWithObjects:@"detach",devEntry,nil]];
	
	if (willBeConverted) {
		[myNotiCenter addObserver:self selector:@selector(convertTmpDiskImage:) name:NSTaskDidTerminateNotification object:dmgTask];
	}
	else {
		if (internetEnableFlag) {
			[myNotiCenter addObserver:self selector:@selector(internetEnable:) name:NSTaskDidTerminateNotification object:dmgTask];
		}
		else {
			[myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:) name:NSTaskDidTerminateNotification object:dmgTask];
		}
	}
	[self setCurrentTask:dmgTask];
	[dmgTask launch];
	//showTaskResult(dmgTask);
	//NSLog(@"end detachDiskImage");
}

- (void) attachDiskImage: (NSNotification *) notification
{
	if (![self checkPreviousTask:notification]) {
		return;
	}
	
	[self postStatusNotification: NSLocalizedString(@"Attaching a disk image file.","")];
	//showTaskResult(dmgTask);
	NSTask* dmgTask = [notification object];
	NSArray * resultArray = getTaskResult(dmgTask);
	NSString * dmgPath = [resultArray objectAtIndex:0];
	dmgTask = [self hdiUtilTask];
	
	[dmgTask setArguments:[NSArray arrayWithObjects:@"attach",dmgPath,@"-noverify",@"-nobrowse",@"-plist",nil]];
	
	//[myNotiCenter removeObserver:self];
	[myNotiCenter addObserver:self selector:@selector(copySourceItem:) name:NSTaskDidTerminateNotification object:dmgTask];

	[self setCurrentTask:dmgTask];
	[dmgTask launch];
}

- (void) postStatusNotification: (NSString *) message
{
	NSDictionary* notifyInfo = [NSDictionary dictionaryWithObjectsAndKeys:message, @"statusMessage", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DmgProgressNotification"
														object:self userInfo:notifyInfo];
}

- (void) createDiskImage
{
	NSDictionary * resultDict;
	NSString * imageSize;
	
	/*** make disk image file ***/
	if (sourceSize < 550000 ) 
		imageSize = @"550000";
	else 
		imageSize = [[NSNumber numberWithUnsignedLongLong:sourceSize] stringValue];
	
	[self postStatusNotification: NSLocalizedString(@"Creating a disk image file.",
											"Status message of creating a disk image.")];
	
	NSTask * dmgTask = [self hdiUtilTask];
	NSString* dmgTarget;
	
	
	NSString *dmgType;
	if ([dmgFormat isEqualToString:@"UDSP"]) 
		dmgType = @"SPARSE";
	else
		dmgType = @"UDIF";

	if (willBeConverted) {
		//NSString *theSuffix = @"sparseimage";
		NSString *theSuffix = @"dmg";
		NSString *tmpName = [self uniqueName:diskName suffix:theSuffix location:tmpDir];
		//NSLog(tmpName);
		dmgTarget = [tmpDir stringByAppendingPathComponent:tmpName];
		sourceDmgPath = [dmgTarget retain];
	}
	else {
		dmgTarget = dmgName;
	}
	
	if (isDmgNameDefined) {
		NSString *targetPath = [workingLocation stringByAppendingPathComponent:dmgName];
		NSFileManager *myFileManager = [NSFileManager defaultManager];
		if ([myFileManager fileExistsAtPath:targetPath]) {
			NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
			int tag;
			if (![workspace performFileOperation:NSWorkspaceRecycleOperation
										 source:workingLocation destination:@""
										   files:[NSArray arrayWithObject:dmgName] tag:&tag]) {
				//NSLog(@"can not delete");
				[self setTerminationMessage:[NSString stringWithFormat:
					NSLocalizedString(@"The file \n %@ could not be removed.", 
									  "can not trash existing file"),
					targetPath]];
				self->terminationStatus = 1;
				[myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
				return;
			}
		}
	}
	
//	if (isSourceFolder) {
//		[dmgTask setArguments:[NSArray arrayWithObjects:@"create",@"-fs",@"HFS+",@" -srcfolder",sourcePath,@"-layout",@"None",@"-type",dmgType,@"-volname",diskName,dmgTarget,@"-plist",nil]];
//	}
//	else {
//		[dmgTask setArguments:[NSArray arrayWithObjects:@"create",@"-fs",@"HFS+",@"-size",imageSize,@"-layout",@"None",@"-type",dmgType,@"-volname",diskName,dmgTarget,@"-plist",nil]];
//	}
	
	[dmgTask setArguments:[NSArray arrayWithObjects:@"create",@"-fs",@"HFS+",@"-size",imageSize,@"-layout",@"None",@"-type",dmgType,@"-volname",diskName,dmgTarget,@"-plist",nil]];

	
	[myNotiCenter addObserver:self selector:@selector(attachDiskImage:) name:NSTaskDidTerminateNotification object:dmgTask];
	[self setCurrentTask:dmgTask];
	[dmgTask launch];
}

-(BOOL) checkPreviousTask:(NSNotification *)notification
{
	//NSLog(@"start checkPreviousTask");
	
	NSTask *dmgTask = [notification object];
	//NSLog(sourcePath);
	
	if ([dmgTask terminationStatus] != 0) {
		//NSLog(@"termination status is not 0");
		[self setTerminationMessage:getTaskError(dmgTask)];
		if ([terminationMessage endsWith:@".Trashes: Permission denied\n"]) {
			//NSLog(@"success to delete .DS_Store");
			return YES;
		}
		else {
			//NSLog(@"error occur");
			if (isAttached) {
				NSTask *detachTask = [self hdiUtilTask];
				[detachTask setArguments:[NSArray arrayWithObjects:@"detach",devEntry,nil]];
				[detachTask launch];
			}
			[self dmgTaskTerminate: notification];
			return NO;
		}
	}
	
	//NSLog(@"termination status is 0");
	NSString *firstArg = [[dmgTask arguments] objectAtIndex:0];
	if ([firstArg isEqualToString:@"attach"]) {
		self->isAttached = YES;
	}
	else if ([firstArg isEqualToString:@"detach"]){
		self->isAttached = NO;
	}
	
	//NSLog(@"end checkPreviousTask");
	return YES;
}

-(void) convertTmpDiskImage:(NSNotification *)notification
{
	if (![self checkPreviousTask:notification]) {
		return;
	}
	[self convertDiskImage];
}

-(void) convertDiskImage
{
	[self postStatusNotification: NSLocalizedString(@"Converting a disk image file.","")];
	
	NSTask * dmgTask = [self hdiUtilTask];
	if (willBeConverted) 
		[myNotiCenter addObserver:self selector:@selector(deleteSourceDmg:) name:NSTaskDidTerminateNotification object:dmgTask];			
	else
		[myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:) name:NSTaskDidTerminateNotification object:dmgTask];
	
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"convert",
		sourceDmgPath,
		@"-format",dmgFormat,@"-o",dmgName,@"-plist",nil];
	
	if ([dmgFormat isEqualToString:@"UDZO"]) {
		NSString *zlibLevelTitle = @"zlib-level=";
		NSString *zlibLevelString = [zlibLevelTitle stringByAppendingString:zlibLevel];
		[arguments addObjectsFromArray:[NSArray arrayWithObjects:@"-imagekey" ,zlibLevelString ,nil]];
	}
	[dmgTask setArguments:arguments];
	[self setCurrentTask:dmgTask];
	[dmgTask launch];
}

-(void) deleteSourceDmg:(NSNotification *) notification
{
	NSFileManager *myFileManager = [NSFileManager defaultManager];
	[myFileManager removeFileAtPath:sourceDmgPath handler:nil];
	if (internetEnableFlag) 
		[self internetEnable:notification];
	else
		[self dmgTaskTerminate: notification];
}

- (void)deleteDSStore:(NSNotification *)notification
{
	if (![self checkPreviousTask:notification]) {
		return;
	}
	
	[self postStatusNotification:NSLocalizedString(@"Deleting .DS_Store files.","")];
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/bin/find"];
	//[task setCurrentDirectoryPath:mountPoint];
	setOutputToPipe(task);
	[task setArguments:[NSArray arrayWithObjects:mountPoint, @"-name", @".DS_Store", @"-delete", nil]];
	
	[myNotiCenter addObserver:self selector:@selector(detachDiskImage:) name:NSTaskDidTerminateNotification object:task];
	[self setCurrentTask:task];
	[task launch];
}

- (void) dmgTaskTerminate:(NSNotification *)notification
{
	//NSLog(@"start dmgTaskTerminate");
	NSTask *dmgTask = [notification object];
	self->terminationStatus = [dmgTask terminationStatus];
	[myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
	//NSLog(@"end dmgTaskTerminate");
}

- (void)setCustomDmgName:(NSString *)theDmgName
{
	
	isDmgNameDefined = YES;
	[self setDmgName:theDmgName];
	[self setDiskName:[theDmgName stringByDeletingPathExtension]];
}

- (NSString *)dmgPath
{
	return [workingLocation stringByAppendingPathComponent:dmgName];
}

#pragma mark accessor methods
- (void)setMountPoint:(NSString *)theMountPoint
{
	[theMountPoint retain];
	[mountPoint release];
	mountPoint = theMountPoint;
}

- (void)setDevEntry:(NSString *)theDevEntry
{
	[theDevEntry retain];
	[devEntry release];
	devEntry = theDevEntry;
}
- (void)setCurrentTask:(NSTask *)aTask
{
	[aTask retain];
	[currentTask release];
	currentTask = aTask;
}

- (void)setTmpDir:(NSString *)path
{
	[path retain];
	[tmpDir release];
	tmpDir = path;
}

- (void)setSourceName:(NSString *)theSourceName
{
	[theSourceName retain];
	[sourceName release];
	sourceName = theSourceName;	
}

- (void)setSourcePath:(NSString *)theSourcePath
{
	[theSourcePath retain];
	[sourcePath release];
	sourcePath = theSourcePath;
}


- (NSString *)sourcePath
{
	return self->sourcePath;
}

- (void)setDiskName:(NSString *)theDiskName
{
	[theDiskName retain];
	[diskName release];
	diskName = theDiskName;
}

- (void)setDmgName:(NSString *) theDmgName
{
	[theDmgName retain];
	[dmgName release];
	dmgName = theDmgName;
}

- (NSString *)dmgName
{
	return self->dmgName;
}

- (void)setTerminationMessage:(NSString *)theString
{
	[theString retain];
	[terminationMessage release];
	terminationMessage = theString;
}

- (NSString *)terminationMessage
{
	return self->terminationMessage;
}

- (int)terminationStatus
{
	return self->terminationStatus;
}

- (void)setDmgFormat:(NSString *)formatID
{
	[formatID retain];
	[dmgFormat release];
	dmgFormat = formatID;
}

- (void)setDmgSuffix:(NSString *)formatSuffix
{
	[formatSuffix retain];
	[dmgSuffix release];
	dmgSuffix = [formatSuffix retain];
	
	[self setDmgName:[self uniqueName:diskName location:workingLocation]];
}

- (NSString *)dmgSuffix
{
	return self->dmgSuffix;
}

- (void)setDeleteDSStore:(BOOL)yesOrNo
{
	self->deleteDSStoreFlag = yesOrNo;
}

- (void)setInternetEnable:(BOOL)yesOrNo
{
	self->internetEnableFlag = yesOrNo;
}

- (void)setCompressionLevel:(NSString *)theZlibLevel
{
	[theZlibLevel retain];
	[zlibLevel release];
	self->zlibLevel = theZlibLevel;
}

- (void)setWorkingLocation:(NSString *)theWorkingLocation
{
	[theWorkingLocation retain];
	[workingLocation release];
	workingLocation = theWorkingLocation;
}

- (NSString *)workingLocation
{
	return self->workingLocation;
}


@end

