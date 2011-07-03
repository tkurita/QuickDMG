#import "DiskImageMaker.h"
#include <unistd.h>
#include <sys/param.h>
#include <sys/ucred.h>
#include <sys/mount.h>
	 
#define useLog 0

id getTaskResult(PipingTask *aTask)
{
#if useLog
	NSLog(@"start getTaskResult");
#endif
	NSString *result = [aTask stdoutString];
#if useLog
	NSLog(result);
#endif
	id resultProp = [result propertyList];
	return resultProp;
}

@implementation DiskImageMaker

#pragma mark internal use
- (NSString *)uniqueName:(NSString *)baseName suffix:(NSString *)theSuffix location:(NSString *)dirPath;
{
	NSString *newName = [baseName stringByAppendingPathExtension:theSuffix];
	NSString *checkPath = [dirPath stringByAppendingPathComponent:newName];
	short i = 1;
	NSFileManager *file_manager = [NSFileManager defaultManager];
	while ([file_manager fileExistsAtPath:checkPath]){
		NSNumber *numberSuffix = [NSNumber numberWithShort:i++];
		newName = [[baseName stringByAppendingPathExtension:[numberSuffix stringValue]] stringByAppendingPathExtension:theSuffix];
		checkPath = [dirPath stringByAppendingPathComponent:newName];
	}
	return newName;	
}

- (NSString *)uniqueName:(NSString *)baseName location:(NSString*)dirPath;
{
	NSString * newName = [baseName stringByAppendingPathExtension:[dmgOptions dmgSuffix]];
	NSString * checkPath = [dirPath stringByAppendingPathComponent:newName];
	NSFileManager *file_manager = [NSFileManager defaultManager];
	short i = 1;
	while ([file_manager fileExistsAtPath:checkPath]){
		NSNumber * numberSuffix = [NSNumber numberWithShort:i++];
		newName = [[baseName stringByAppendingPathExtension:[numberSuffix stringValue]] 
									stringByAppendingPathExtension:[dmgOptions dmgSuffix]];
		checkPath = [workingLocation stringByAppendingPathComponent:newName];
	}
	return newName;
}

- (void)setSourceEnumerator:(NSEnumerator *)enumerator
{
	[enumerator retain];
	[sourceEnumerator release];
	sourceEnumerator = enumerator;
}

#pragma mark init and dealloc
- (id) init
{
	[super init];
	requireSpaceRatio = 1.0;
	myNotiCenter = [NSNotificationCenter defaultCenter];
	isReplacing = NO;
	expectedCompressRatio = 0.7;
	isAttached = NO;
	return self;
}

- (id)initWithSourceItem:(NSDocument<DMGDocument> *)anItem
{
	[self init];
	sourceItems = [[NSArray arrayWithObject:anItem] retain];
	NSString *source_path = [anItem fileName];
	
	if ([[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] containsObject:source_path]) {
		[self setWorkingLocation:[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject]];
	} else {				
		[self setWorkingLocation:[source_path stringByDeletingLastPathComponent]];
	}
	
	NSString *source_name = [source_path lastPathComponent];
	if ((![anItem isFolder]) || [anItem isPackage]) {
		[self setDiskName:[source_name stringByDeletingPathExtension]];
	} else {
		[self setDiskName:source_name];
	}
	return self;
}

- (id)initWithSourceItems:(NSArray *)array
{
	[self init];
	sourceItems = [array retain];
	return self;
}

- (void)dealloc
{
	[sourceDmgPath release];
	[mountPoint release];
	[devEntry release];
	[terminationMessage release];
	[workingLocation release];
	[diskName release];
	[tmpDir release];
	[sourceItems release];
	[super dealloc];
}

#pragma mark setup methods
- (void)setDMGOptions:(id<DMGOptions>)anObject
{
	[anObject retain];
	[dmgOptions release];
	dmgOptions = anObject;
}

- (void)setDestination:(NSString *)aPath replacing:(BOOL)aFlag;
{
	[self setWorkingLocation:[aPath stringByDeletingLastPathComponent]];
	[self setDiskName:[[aPath lastPathComponent] stringByDeletingPathExtension]];
	isReplacing = aFlag;
	if (isReplacing) {
		[self setDmgName:[aPath lastPathComponent]];
	} else {
		[self setDmgName:[self uniqueName:diskName location:workingLocation]];
	}
}

- (NSString *)resolveDmgName
{
	[self setDmgName:[self uniqueName:diskName location:workingLocation]];
	return dmgName;
}

- (void)setCustomDmgName:(NSString *)theDmgName
{
	
	isReplacing = YES;
	[self setDmgName:theDmgName];
	[self setDiskName:[theDmgName stringByDeletingPathExtension]];
}

- (NSString *)dmgPath
{
	if (!dmgName) [self resolveDmgName];
	return [workingLocation stringByAppendingPathComponent:dmgName];
}

#pragma mark instance methods
- (BOOL)checkCondition:(NSWindowController<DMGWindowController> *)aWindowController
{
	if (![self checkWorkingLocationPermission]) {
		NSString* detailMessage = [NSString stringWithFormat:NSLocalizedString(@"No write permission",""),
			[self workingLocation]];
		[aWindowController showAlertMessage:NSLocalizedString(@"Insufficient access right.","") 
											withInformativeText:detailMessage];
		return NO;
	}
	
	if (![self checkFreeSpace]) {
		[aWindowController 
			showAlertMessage:NSLocalizedString(@"Can't progress jobs.","")
			withInformativeText:NSLocalizedString(@"Not enough free space for creating a disk image.", "")];
		return NO;
	}
	
	isOnlyFolder = NO;
	if ([sourceItems count] == 1) {
		id <DMGDocument>item = [sourceItems lastObject];
		isOnlyFolder = ([item isFolder] && ![item isPackage]);
	}
	
	return YES;
}

- (BOOL)checkWorkingLocationPermission
{
#if useLog
	NSLog(@"start checkWorkingLocationPermission");
	NSLog(workingLocation);
#endif
	int wirtePermInt = access([workingLocation fileSystemRepresentation],02);
	return (wirtePermInt == 0);
}

- (BOOL) checkFreeSpace
{
#if useLog
	NSLog(@"start checkFreeSpace");
#endif
	[self postStatusNotification: 
		NSLocalizedString(@"Checking free space of disks.","")];
		
	NSEnumerator *enumerator = [sourceItems objectEnumerator];
	sourceSize = 0;
	id <DMGDocument>an_item;
	while (an_item = [enumerator nextObject]) {
		sourceSize += [an_item fileSize];
	}
	//sourceSize += 500000;
	sourceSize += [[NSUserDefaults standardUserDefaults] integerForKey:@"additionalSize"];
	
	NSFileManager *file_manager = [NSFileManager defaultManager];
	
	NSDictionary *infoWorkingDisk = [file_manager fileSystemAttributesAtPath:workingLocation];
	unsigned long long freeSize = [[infoWorkingDisk objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
	NSString *dmg_format = [dmgOptions dmgFormat];
	//self->willBeConverted = !([dmg_format isEqualToString:@"UDRW"]||[dmg_format isEqualToString:@"UDSP"]);
	willBeConverted = [dmgOptions needConversion];
	
	[self setTmpDir:NSTemporaryDirectory()];
	requireSpaceRatio = 0;
	if ([[dmgOptions command] isEqualToString:@"makehybrid"]) {
		if (isOnlyFolder) {
			requireSpaceRatio = 1;
		} else {
			willBeConverted = YES;
			expectedCompressRatio = 1;
		}
		
	}
	
	if (!requireSpaceRatio) {
		if (willBeConverted) {
			NSDictionary *infoTmpDisk = [file_manager fileSystemAttributesAtPath:tmpDir];
			
			if ([[infoTmpDisk objectForKey:NSFileSystemNumber] isEqualToNumber:[infoWorkingDisk objectForKey:NSFileSystemNumber]]) {
				requireSpaceRatio = 1 + expectedCompressRatio;
			}
			else {
				unsigned long long freeSizeTmpDir = [[infoTmpDisk objectForKey:@"NSFileSystemFreeSize"] unsignedLongLongValue];
				
				if (freeSizeTmpDir > sourceSize) {
					if ([dmg_format isEqualToString:@"UDZO"] || [dmg_format isEqualToString:@"UDBZ"])
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
	}
		
	if ( freeSize > requireSpaceRatio*sourceSize)
		return YES;
	else
		return NO;
}

-(void) launchAsCurrentTask:(PipingTask *)aTask
{
	[self setCurrentTask:aTask];
	[aTask launch];
}

#pragma mark disk image task
- (PipingTask *)hdiUtilTask
{
	PipingTask *task = [[PipingTask alloc] init];
	[task setLaunchPath:@"/usr/bin/hdiutil"];
	[task setCurrentDirectoryPath:workingLocation];
	return [task autorelease];
}

- (void) detachDiskImage:(NSNotification *)notification
{
#if useLog
	NSLog(@"start detachDiskImage");
#endif
	if (![self checkPreviousTask:notification]) {
		return;
	}
	
	[self postStatusNotification:NSLocalizedString(@"Detaching a disk image.","")];
	PipingTask * dmg_task = [self hdiUtilTask];
	[dmg_task setArguments:[NSArray arrayWithObjects:@"detach",devEntry,nil]];

	if (willBeConverted) {
		[myNotiCenter addObserver:self selector:@selector(convertTmpDiskImage:) 
						name:NSTaskDidTerminateNotification object:dmg_task];
	}
	else {
		if ([dmgOptions internetEnable]) {
			[myNotiCenter addObserver:self selector:@selector(internetEnable:)
				name:NSTaskDidTerminateNotification object:dmg_task];
		}
		else {
			[myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:)
				name:NSTaskDidTerminateNotification object:dmg_task];
		}
	}
	[self launchAsCurrentTask:dmg_task];
#if useLog
	NSLog(@"end detachDiskImage");
#endif
}

- (void)deleteDSStore:(NSNotification *)notification
{
#if useLog
	NSLog(@"start deleteDSStore");
#endif
	if (![self checkPreviousTask:notification]) {
		return;
	}
	
	[self postStatusNotification:NSLocalizedString(@"Deleting .DS_Store files.","")];
	PipingTask *task = [[[PipingTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/bin/find"];
	[task setArguments:[NSArray arrayWithObjects:mountPoint, @"-name", @".DS_Store", @"-delete", nil]];
	
	[myNotiCenter addObserver:self selector:@selector(detachDiskImage:) name:NSTaskDidTerminateNotification object:task];

	[self launchAsCurrentTask:task];
}

NSString *mountPointForDevEntry(NSString *devEntry)
{
	struct statfs *buf;
	int i, count;
	const char *dev = [devEntry UTF8String];
	
	count = getmntinfo(&buf, 0);
	for (i=0; i<count; i++)
	{
		if (strcmp(buf[i].f_mntfromname, dev) == 0)
			return [NSString stringWithUTF8String:buf[i].f_mntonname];
	}
	return nil;
}



- (void) copySourceItems:(NSNotification *) notification
{
#if useLog
	NSLog(@"start copySourceItems:");
#endif
	if (![[notification name] isEqualToString:@"StartCopySources"]) {
		if (![self checkPreviousTask:notification]) return;
	}
	
	[self postStatusNotification: NSLocalizedString(@"Copying source files.","")];
	NSEnumerator *source_enumerator = [[notification userInfo] objectForKey:@"sourceEnumerator"];
	
//	PipingTask *previous_task = [notification object];
//	
//	if ([[previous_task launchPath] isEqualToString:@"/usr/bin/hdiutil"]) {
//		NSDictionary *task_result = [[previous_task stdoutString] propertyList];
//#if useLog
//		NSLog([task_result description]);
//#endif
//		task_result = [[task_result objectForKey:@"system-entities"] objectAtIndex:0];
//		[self setDevEntry:[task_result objectForKey:@"dev-entry"]];
//		[self setMountPoint:[task_result objectForKey:@"mount-point"]];
//		[self setSourceEnumerator:[sourceItems objectEnumerator]];
//	}
	
	NSDocument<DMGDocument>* source_item = [source_enumerator nextObject];
	if (!source_item) {
		SEL selector = NSSelectorFromString([[notification userInfo] objectForKey:@"nextSelector"]);
		[self performSelector:selector withObject:notification];
//		if ([dmgOptions isDeleteDSStore]) {
//			[self deleteDSStore:notification];
//		}
//		else {
//			[self detachDiskImage:notification];
//		}
		
		return;
	}

//	if ([[dmgOptions filesystem] isEqualToString:@"HFS"]) {
//		CFStringEncoding sysenc = CFStringGetSystemEncoding();
//		PipingTask *dt_task = [PipingTask launchedTaskWithLaunchPath:@"/usr/sbin/disktool"
//					arguments:[NSArray arrayWithObjects:@"-s", devEntry, [NSString stringWithFormat:@"%d",sysenc],  nil]];
//		[dt_task waitUntilExit];
//		// Fix volume name is not reflected if diskName have multi byte characters, 
//		dt_task = [PipingTask launchedTaskWithLaunchPath:@"/usr/sbin/diskutil"
//					arguments:[NSArray arrayWithObjects:@"rename" ,devEntry, diskName, nil]];
//		[dt_task waitUntilExit];
//		if ([dt_task terminationStatus] !=0) {
//			NSLog([dt_task stderrString]);
//		}
//		
//		NSString *bufmp = mountPointForDevEntry(devEntry);
//		if (bufmp) {
//			[self setMountPoint:bufmp];
//		} else {
//			//NSLog([NSString stringWithFormat:@"Can't find the mount point for %@", devEntry]);
//			terminationStatus = 1;
//			[self setTerminationMessage:[NSString stringWithFormat:@"Can't find the mount point for %@", devEntry]];		
//			[myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
//			return;
//		}
//	}
	
	PipingTask * task = [[[PipingTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/bin/ditto"];
	
	NSString *destination = [[notification userInfo] objectForKey:@"copyDestination"];
	
	if (!isOnlyFolder && [source_item isFolder]) {
		destination = [destination stringByAppendingPathComponent:[[source_item fileName] lastPathComponent]];
	}
	
	[task setArguments:[NSArray arrayWithObjects:@"--rsrc",[source_item fileName],destination,nil]];
	[task setUserInfo:[notification userInfo]];
	[myNotiCenter addObserver:self selector:@selector(copySourceItems:) name:NSTaskDidTerminateNotification object:task];		
	
	[self launchAsCurrentTask:task];
#if useLog
	NSLog(@"end copySourceItems:");
#endif
}

- (void)internetEnable:(NSNotification *)notification
{
#if useLog
	NSLog(@"start internetEnable");
#endif	
	if (![self checkPreviousTask:notification]) {
		return;
	}

	[self postStatusNotification:NSLocalizedString(@"Setting internet-enable option.","")];
	PipingTask * dmg_task = [self hdiUtilTask];
	[dmg_task setArguments:[NSArray arrayWithObjects:@"internet-enable",@"-yes", dmgName, nil]];

	[myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:) 
					name:NSTaskDidTerminateNotification object:dmg_task];
	[self launchAsCurrentTask:dmg_task];
#if useLog
	NSLog(@"end internetEnable");
#endif	
}

- (void) afterAttachDiskImage: (NSNotification *) notification
{
	if (![self checkPreviousTask:notification]) {
		return;
	}
	PipingTask *previous_task = [notification object];
	NSDictionary *task_result = [[previous_task stdoutString] propertyList];
#if useLog
	NSLog([task_result description]);
#endif
	task_result = [[task_result objectForKey:@"system-entities"] objectAtIndex:0];
	[self setDevEntry:[task_result objectForKey:@"dev-entry"]];
	[self setMountPoint:[task_result objectForKey:@"mount-point"]];
	
	if ([[dmgOptions filesystem] isEqualToString:@"HFS"]) {
		CFStringEncoding sysenc = CFStringGetSystemEncoding();
		PipingTask *dt_task = [PipingTask launchedTaskWithLaunchPath:@"/usr/sbin/disktool"
														   arguments:[NSArray arrayWithObjects:@"-s", devEntry, [NSString stringWithFormat:@"%d",sysenc],  nil]];
		[dt_task waitUntilExit];
		// Fix volume name is not reflected if diskName have multi byte characters, 
		dt_task = [PipingTask launchedTaskWithLaunchPath:@"/usr/sbin/diskutil"
											   arguments:[NSArray arrayWithObjects:@"rename" ,devEntry, diskName, nil]];
		[dt_task waitUntilExit];
		if ([dt_task terminationStatus] !=0) {
			NSLog([dt_task stderrString]);
		}
		
		NSString *bufmp = mountPointForDevEntry(devEntry);
		if (bufmp) {
			[self setMountPoint:bufmp];
		} else {
			//NSLog([NSString stringWithFormat:@"Can't find the mount point for %@", devEntry]);
			terminationStatus = 1;
			[self setTerminationMessage:[NSString stringWithFormat:@"Can't find the mount point for %@", devEntry]];		
			[myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
			return;
		}
	}
	
	NSString *next_selector;
	if ([dmgOptions isDeleteDSStore]) {
		next_selector = @"deleteDSStore:";
	}
	else {
		next_selector = @"detachDiskImage:";
	}
	
	
	[self copySourceItems:[NSNotification notificationWithName:@"StartCopySources"
														object:nil
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:mountPoint, @"copyDestination",
																[sourceItems objectEnumerator], @"sourceEnumerator", 
																next_selector, @"nextSelector", nil]]];
}

- (void) attachDiskImage: (NSNotification *) notification
{
#if useLog
	NSLog(@"start attachDiskImage");
#endif
	if (![self checkPreviousTask:notification]) {
		return;
	}
	
	[self postStatusNotification: NSLocalizedString(@"Attaching a disk image.","")];
	PipingTask *dmg_task = [notification object];
	
	NSArray *resultArray = [[dmg_task stdoutString] propertyList];
	NSString *dmgPath = [resultArray objectAtIndex:0];
	dmg_task = [self hdiUtilTask];
	
	[dmg_task setArguments:[NSArray arrayWithObjects:@"attach",dmgPath,@"-noverify",@"-nobrowse",@"-plist",nil]];
	
	//[myNotiCenter addObserver:self selector:@selector(copySourceItems:) 
	//				name:NSTaskDidTerminateNotification object:dmg_task];

	[myNotiCenter addObserver:self selector:@selector(afterAttachDiskImage:) 
					name:NSTaskDidTerminateNotification object:dmg_task];

	[self launchAsCurrentTask:dmg_task];
#if useLog
	NSLog(@"end attachDiskImage");
#endif
}

- (void) postStatusNotification: (NSString *) message
{
	NSDictionary* notifyInfo = [NSDictionary dictionaryWithObjectsAndKeys:message, @"statusMessage", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DmgProgressNotification"
														object:self userInfo:notifyInfo];
}

- (PipingTask *)makeHybridTask:(NSString *)source destination:(NSString *)destination
{
	PipingTask *task = [self hdiUtilTask];
	[task setArguments:[NSArray arrayWithObjects:@"makehybrid", @"-iso", @"-udf", @"-udf-version", @"1.0.2",
							@"-udf-volume-name",diskName, @"-o", destination, source, nil]];
	return task;
}

- (void)performCleanTempSources:(NSNotification *)notification
{
	if (![self checkPreviousTask:notification]) {
		return;
	}

	[self postStatusNotification:NSLocalizedString(@"Cleaning Temporary files.","")];
	[[NSFileManager defaultManager] removeFileAtPath:[[notification userInfo] objectForKey:@"dmgSource"]
											 handler:nil];
	
	[myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
}

- (void)performMakeHybrid:(NSNotification *)notification
{
	if (![self checkPreviousTask:notification]) {
		return;
	}
	
	[self postStatusNotification:NSLocalizedString(@"Creating a hybrid disk image.","")];
	
	NSString *source = [[notification userInfo] objectForKey:@"dmgSource"];
	NSString *destination = [[notification userInfo] objectForKey:@"dmgDestination"];
	PipingTask *task = [self makeHybridTask:source destination:destination];
	[myNotiCenter addObserver:self selector:@selector(performCleanTempSources:)
						 name:NSTaskDidTerminateNotification object:task];
	[self launchAsCurrentTask:task];
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
	
	[self postStatusNotification: NSLocalizedString(@"Preparing.",
													"Status message of checking condition.")];

	NSString* dmg_target = dmgName;

	if (isReplacing) {
		NSString *target_path = [workingLocation stringByAppendingPathComponent:dmgName];
		NSFileManager *file_manager = [NSFileManager defaultManager];
		if ([file_manager fileExistsAtPath:target_path]) {
			NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
			int tag;
			if (![workspace performFileOperation:NSWorkspaceRecycleOperation
										  source:workingLocation destination:@""
										   files:[NSArray arrayWithObject:dmgName] tag:&tag]) {
#if useLog
				NSLog(@"can not delete");
#endif
				[self setTerminationMessage:[NSString stringWithFormat:
											 NSLocalizedString(@"The file \n %@ could not be removed.", 
															   "can not trash existing file"),
											 target_path]];
				self->terminationStatus = 1;
				[myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
				return;
			}
		}
	}
	
	PipingTask *task = nil;
	NSString *command = [dmgOptions command];
	if ([command isEqualToString:@"makehybrid"]) {
		if (isOnlyFolder) {
			NSDocument<DMGDocument>* source_item = [sourceItems lastObject];
			task = [self makeHybridTask:[[source_item fileURL] path] destination:dmg_target];
			[myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:)
								 name:NSTaskDidTerminateNotification object:task];
			[self postStatusNotification:NSLocalizedString(@"Creating a hybrid disk image.","")];
		} else {
			NSString *tmp_name = [self uniqueName:diskName suffix:@"" location:tmpDir];
			NSString *tmp_path = [tmpDir stringByAppendingPathComponent:tmp_name];
			if ([[NSFileManager defaultManager] createDirectoryAtPath:tmp_path attributes:nil]) {
				[self copySourceItems:[NSNotification notificationWithName:@"StartCopySources"
																	object:nil
												  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																	tmp_path, @"copyDestination",
																	[sourceItems objectEnumerator], @"sourceEnumerator", 
																	@"performMakeHybrid:", @"nextSelector",
																	tmp_path,@"dmgSource", 
																	dmg_target, @"dmgDestination", nil]]];
				return;
			} else {
				NSLog(@"Failed to make directory");
				return;
			}
		}
		
	} else {
		[self postStatusNotification: NSLocalizedString(@"Creating a disk image.",
														"Status message of creating a disk image.")];
		task = [self hdiUtilTask];
		if (willBeConverted) {
			NSString *a_suffix = @"dmg";
			NSString *tmp_name = [self uniqueName:diskName suffix:a_suffix location:tmpDir];
#if useLog
			NSLog(tmp_name);
#endif
			dmg_target = [tmpDir stringByAppendingPathComponent:tmp_name];
			sourceDmgPath = [dmg_target retain];
		}
		
		NSString *dmg_type;

		if ([[dmgOptions dmgFormat] isEqualToString:@"UDSP"]) 
			dmg_type = @"SPARSE";
		else
			dmg_type = @"UDIF";
		NSString *fs = [dmgOptions filesystem];
		[task setArguments:[NSArray arrayWithObjects:@"create",@"-fs", fs,@"-size",imageSize,
								@"-layout",@"None",@"-type",dmg_type,@"-volname",diskName,
								dmg_target,@"-plist",nil]];		
		[myNotiCenter addObserver:self selector:@selector(attachDiskImage:) 
							 name:NSTaskDidTerminateNotification object:task];
	}
	
	[self launchAsCurrentTask:task];
}

-(BOOL) checkPreviousTask:(NSNotification *)notification
{
#if useLog
	NSLog(@"start checkPreviousTask");
#endif

	PipingTask *dmg_task = [notification object];
	
	[myNotiCenter removeObserver:self];
	
	if ([dmg_task terminationStatus] != 0) {
#if useLog
		NSLog(@"termination status is not 0");
#endif
		[self setTerminationMessage:[dmg_task stderrString]];
#if useLog
		NSLog(terminationMessage);
#endif
		if ([terminationMessage endsWith:@".Trashes: Permission denied\n"]) {
#if useLog
			NSLog(@"success to delete .DS_Store");
#endif
			return YES;
		}
		else {
#if useLog
			NSLog(@"error occur");
#endif
			if (isAttached) {
				PipingTask *detachTask = [self hdiUtilTask];
				[detachTask setArguments:[NSArray arrayWithObjects:@"detach",devEntry,nil]];
				[detachTask launch];
			}
			terminationStatus = [dmg_task terminationStatus];
			[myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
			return NO;
		}
	} else {
		[self setTerminationMessage:nil];
	}
#if useLog	
	NSLog(@"termination status is 0");
#endif
	NSString *firstArg = [[dmg_task arguments] objectAtIndex:0];
	if ([firstArg isEqualToString:@"attach"]) {
		self->isAttached = YES;
	}
	else if ([firstArg isEqualToString:@"detach"]){
		self->isAttached = NO;
	}
#if useLog	
	NSLog(@"end checkPreviousTask");
#endif
	return YES;
}

-(void) convertTmpDiskImage:(NSNotification *)notification
{
#if useLog
	NSLog(@"start convertTmpDiskImage");
#endif
	if (![self checkPreviousTask:notification]) {
		return;
	}
	[self convertDiskImage];
}

-(void) convertDiskImage
{
#if useLog
	NSLog(@"start convertDiskImage");
#endif
	[self postStatusNotification: NSLocalizedString(@"Converting a disk image.","")];
	
	PipingTask *dmg_task = [self hdiUtilTask];
	if (willBeConverted) 
		[myNotiCenter addObserver:self selector:@selector(deleteSourceDmg:)
			name:NSTaskDidTerminateNotification object:dmg_task];			
	else
		[myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:)
			name:NSTaskDidTerminateNotification object:dmg_task];
	
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"convert",
		sourceDmgPath, @"-format", [dmgOptions dmgFormat], @"-o",dmgName,@"-plist",nil];
	
	if ([[dmgOptions dmgFormat] isEqualToString:@"UDZO"]) {
		NSString *zlibLevelString = [NSString stringWithFormat:@"zlib-level=%i", [dmgOptions compressionLevel]+1];
		[arguments addObjectsFromArray:[NSArray arrayWithObjects:@"-imagekey" ,zlibLevelString ,nil]];
	}
	[dmg_task setArguments:arguments];
	[self launchAsCurrentTask:dmg_task];
#if useLog
	NSLog(@"end convertDiskImage");
#endif
}

-(void) deleteSourceDmg:(NSNotification *) notification
{
#if useLog
	NSLog(@"start deleteSourceDmg");
#endif
	NSFileManager *file_manager = [NSFileManager defaultManager];
	[file_manager removeFileAtPath:sourceDmgPath handler:nil];

	if ([self checkPreviousTask:notification]) {
		if ([dmgOptions internetEnable]) 
			[self internetEnable:notification];
		else
			[self dmgTaskTerminate:notification];
	}

#if useLog
	NSLog(@"end deleteSourceDmg");
#endif
}

- (void) dmgTaskTerminate:(NSNotification *)notification
{
#if useLog
	NSLog(@"start dmgTaskTerminate");
#endif
	PipingTask *dmg_task = [notification object];
	terminationStatus = [dmg_task terminationStatus];
	if (terminationStatus) {
		[self setTerminationMessage:[dmg_task stderrString]];
	}
	[myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
#if useLog
	NSLog(@"end dmgTaskTerminate");
#endif
}

- (void)aboartTask
{
	[myNotiCenter removeObserver:self];
	[currentTask terminate];
	if (isAttached) {
		PipingTask *dmg_task = [self hdiUtilTask];
		[dmg_task setArguments:[NSArray arrayWithObjects:@"detach",devEntry,nil]];
		[self launchAsCurrentTask:dmg_task];
	}
	
	NSString *dmg_path = [workingLocation stringByAppendingPathComponent:dmgName];
	NSFileManager *file_manager = [NSFileManager defaultManager];
	if ([file_manager fileExistsAtPath:dmg_path]) {
		[file_manager removeFileAtPath:dmg_path handler:nil];
	}
	
	if ((willBeConverted) && ([file_manager fileExistsAtPath:sourceDmgPath])) {
		[file_manager removeFileAtPath:sourceDmgPath handler:nil];
	}
	
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

- (void)setCurrentTask:(PipingTask *)aTask
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

- (void)setReplacing:(BOOL)aFlag
{
	isReplacing = aFlag;
}
@end

