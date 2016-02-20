#import "DiskImageMaker.h"
#import "DMGDocumentProtocol.h"
#import "PathExtra.h"
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
		NSNumber *numberSuffix = @(i++);
		newName = [[baseName stringByAppendingPathExtension:[numberSuffix stringValue]] stringByAppendingPathExtension:theSuffix];
		checkPath = [dirPath stringByAppendingPathComponent:newName];
	}
	return newName;	
}

- (NSString *)uniqueName:(NSString *)baseName location:(NSString*)dirPath;
{
	NSString * newName = [baseName stringByAppendingPathExtension:[_dmgOptions dmgSuffix]];
	NSString * checkPath = [dirPath stringByAppendingPathComponent:newName];
	NSFileManager *file_manager = [NSFileManager defaultManager];
	short i = 1;
	while ([file_manager fileExistsAtPath:checkPath]){
		NSNumber * numberSuffix = @(i++);
		newName = [[baseName stringByAppendingPathExtension:[numberSuffix stringValue]] 
									stringByAppendingPathExtension:[_dmgOptions dmgSuffix]];
		checkPath = [_workingLocationURL.path stringByAppendingPathComponent:newName];
	}
	return newName;
}

#pragma mark init and dealloc
- (id) init
{
	if ((self = [super init])) {
        requireSpaceRatio = 1.0;
        self.myNotiCenter = [NSNotificationCenter defaultCenter];
        isReplacing = NO;
        expectedCompressRatio = 0.7;
        isAttached = NO;
    }
	return self;
}

- (id)initWithSourceItem:(NSDocument<DMGDocument> *)anItem
{
	if (!(self = [self init])) return nil;
	self.sourceItems = @[anItem];
	NSURL *source_url = [anItem fileURL];
	
	if ([[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] containsObject:source_url.path]) {
		self.workingLocationURL = [NSURL fileURLWithPath:
                                   [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES)
								  lastObject]];
	} else {				
		self.workingLocationURL = [source_url URLByDeletingLastPathComponent];
	}
	
	NSString *source_name = [source_url lastPathComponent];
	if ((![anItem isFolder]) || [anItem isPackage]) {
		self.diskName = [source_name stringByDeletingPathExtension];
	} else {
		self.diskName = source_name;
	}
	return self;
}

- (id)initWithSourceItems:(NSArray *)array
{
	if ((self = [self init])) {
        self.sourceItems = array;
    }
	return self;
}


#pragma mark setup methods
- (void)setDestination:(NSString *)aPath replacing:(BOOL)aFlag;
{
	self.workingLocationURL = [NSURL fileURLWithPath:[aPath stringByDeletingLastPathComponent]];
	self.diskName = [[aPath lastPathComponent] stringByDeletingPathExtension];
	isReplacing = aFlag;
	if (isReplacing) {
		self.dmgName = [aPath lastPathComponent];
	} else {
		self.dmgName = [self uniqueName:_diskName location:_workingLocationURL.path];
	}
}

- (NSString *)resolveDmgName
{
	self.dmgName = [self uniqueName:_diskName location:_workingLocationURL.path];
	return _dmgName;
}

- (void)setCustomDmgName:(NSString *)theDmgName
{
	
	isReplacing = YES;
	self.dmgName = theDmgName;
	self.diskName = [theDmgName stringByDeletingPathExtension];
}

- (NSString *)dmgPath
{
	if (!_dmgName) [self resolveDmgName];
	return [_workingLocationURL.path stringByAppendingPathComponent:_dmgName];
}

#pragma mark instance methods
- (BOOL)checkCondition:(NSWindowController<DMGWindowController> *)aWindowController
{
	if (![self checkWorkingLocationPermission]) {
		NSString* detailMessage = [NSString stringWithFormat:NSLocalizedString(@"No write permission",""),
			_workingLocationURL.path];
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
	if ([_sourceItems count] == 1) {
		id <DMGDocument>item = [_sourceItems lastObject];
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
	int wirtePermInt = access([_workingLocationURL.path fileSystemRepresentation],02);
	return (wirtePermInt == 0);
}

- (BOOL) checkFreeSpace
{
#if useLog
	NSLog(@"start checkFreeSpace");
#endif
	[self postStatusNotification: 
		NSLocalizedString(@"Checking free space of disks.","")];
		
	NSEnumerator *enumerator = [_sourceItems objectEnumerator];
	sourceSize = 0;
	id <DMGDocument>an_item;
	while (an_item = [enumerator nextObject]) {
		sourceSize += [an_item fileSize];
	}
	//sourceSize += 500000;
	sourceSize += [[NSUserDefaults standardUserDefaults] integerForKey:@"additionalSize"];
		
    NSFileManager *file_manager = [NSFileManager defaultManager];
	
	NSError *err = nil;
    NSDictionary *infoWorkingDisk = [file_manager
                                     attributesOfFileSystemForPath:_workingLocationURL.path
                                     error: &err];
    if (err) {
        [NSApp presentError:err];
        return;
    }
	unsigned long long freeSize = [infoWorkingDisk[NSFileSystemFreeSize] unsignedLongLongValue];
    
	NSString *dmg_format = [_dmgOptions dmgFormat];
	willBeConverted = [_dmgOptions needConversion];
	
	self.tmpDir = NSTemporaryDirectory();
	requireSpaceRatio = 0;
	if ([[_dmgOptions command] isEqualToString:@"makehybrid"]) {
		if (isOnlyFolder) {
			requireSpaceRatio = 1;
		} else {
			willBeConverted = YES;
			expectedCompressRatio = 1;
		}
		
	}
	
	if (!requireSpaceRatio) {
		if (willBeConverted) {
            NSDictionary *infoTmpDisk = [file_manager
                                             attributesOfFileSystemForPath:_tmpDir
                                             error: &err];
            if (err) {
                [NSApp presentError:err];
                return;
            }
			if ([infoTmpDisk[NSFileSystemNumber] isEqualToNumber:infoWorkingDisk[NSFileSystemNumber]]) {
				requireSpaceRatio = 1 + expectedCompressRatio;
			}
			else {
				unsigned long long freeSizeTmpDir = [infoTmpDisk[@"NSFileSystemFreeSize"] unsignedLongLongValue];
				
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
	self.currentTask = aTask;
	[aTask launch];
}

#pragma mark disk image task
- (PipingTask *)hdiUtilTask
{
	PipingTask *task = [[PipingTask alloc] init];
	[task setLaunchPath:@"/usr/bin/hdiutil"];
	[task setCurrentDirectoryPath:_workingLocationURL.path];
	return task;
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
	[dmg_task setArguments:@[@"detach",_devEntry]];

	if (willBeConverted) {
		[_myNotiCenter addObserver:self selector:@selector(convertTmpDiskImage:)
						name:NSTaskDidTerminateNotification object:dmg_task];
	}
	else {
		if ([_dmgOptions internetEnable]) {
			[_myNotiCenter addObserver:self selector:@selector(internetEnable:)
				name:NSTaskDidTerminateNotification object:dmg_task];
		}
		else {
			[_myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:)
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
	PipingTask *task = [[PipingTask alloc] init];
	[task setLaunchPath:@"/usr/bin/find"];
	[task setArguments:@[_mountPoint, @"-name", @".DS_Store", @"-delete"]];
	
	[_myNotiCenter addObserver:self selector:@selector(detachDiskImage:) name:NSTaskDidTerminateNotification object:task];

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
			return @(buf[i].f_mntonname);
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
	//NSEnumerator *source_enumerator = [notification userInfo][@"sourceEnumerator"];
		
	NSDocument<DMGDocument>* source_item = [[notification userInfo][@"sourceEnumerator"] nextObject];
	if (!source_item) {
		SEL selector = NSSelectorFromString([notification userInfo][@"nextSelector"]);
		[self performSelector:selector withObject:notification];		
		return;
	}

	
	PipingTask * task = [[PipingTask alloc] init];
	[task setLaunchPath:@"/usr/bin/ditto"];
	
	NSString *destination = [notification userInfo][@"copyDestination"];
	
	if (!isOnlyFolder && [source_item isFolder]) {
		destination = [destination
                       stringByAppendingPathComponent:[[source_item fileURL] lastPathComponent]];
	}
	
	[task setArguments:@[@"--rsrc",[[source_item fileURL] path],destination]];
	task.userInfo = [notification userInfo];
	[_myNotiCenter addObserver:self selector:@selector(copySourceItems:)
                          name:NSTaskDidTerminateNotification object:task];
	
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
	[dmg_task setArguments:@[@"internet-enable", @"-yes", _dmgName]];

	[_myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:)
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
	task_result = task_result[@"system-entities"][0];
	[self setDevEntry:task_result[@"dev-entry"]];
	[self setMountPoint:task_result[@"mount-point"]];
	
	if ([[_dmgOptions filesystem] isEqualToString:@"HFS"]) {
		CFStringEncoding sysenc = CFStringGetSystemEncoding();
		PipingTask *dt_task = [PipingTask
                               launchedTaskWithLaunchPath:@"/usr/sbin/disktool"
                            arguments:@[@"-s", _devEntry, [NSString stringWithFormat:@"%d",sysenc]]];
		[dt_task waitUntilExit];
		// Fix volume name is not reflected if diskName have multi byte characters, 
		dt_task = [PipingTask
                   launchedTaskWithLaunchPath:@"/usr/sbin/diskutil"
                   arguments:@[@"rename" ,_devEntry, _diskName]];
		[dt_task waitUntilExit];
		if ([dt_task terminationStatus] !=0) {
			NSLog(@"%@", [dt_task stderrString]);
		}
		
		NSString *bufmp = mountPointForDevEntry(_devEntry);
		if (bufmp) {
			[self setMountPoint:bufmp];
		} else {
			//NSLog([NSString stringWithFormat:@"Can't find the mount point for %@", devEntry]);
			self.terminationStatus = 1;
			[self setTerminationMessage:
				[NSString stringWithFormat:@"Can't find the mount point for %@", 
										 _devEntry]];
			[_myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
			return;
		}
	}
	
	NSString *next_selector;
	if ([_dmgOptions isDeleteDSStore]) {
		next_selector = @"deleteDSStore:";
	}
	else {
		next_selector = @"detachDiskImage:";
	}
	
	
	[self copySourceItems:[NSNotification notificationWithName:@"StartCopySources"
									object:nil
					  userInfo:@{@"copyDestination": _mountPoint,
								@"sourceEnumerator": [_sourceItems objectEnumerator],
								@"nextSelector": next_selector}]];
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
	NSString *dmgPath = resultArray[0];
	dmg_task = [self hdiUtilTask];
	
	[dmg_task setArguments:@[@"attach",dmgPath,@"-noverify",
														@"-nobrowse",@"-plist"]];
	
	[_myNotiCenter addObserver:self selector:@selector(afterAttachDiskImage:)
					name:NSTaskDidTerminateNotification object:dmg_task];

	[self launchAsCurrentTask:dmg_task];
#if useLog
	NSLog(@"end attachDiskImage");
#endif
}

- (void) postStatusNotification: (NSString *) message
{
	NSDictionary* notifyInfo = @{@"statusMessage": message};
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DmgProgressNotification"
														object:self userInfo:notifyInfo];
}

- (PipingTask *)makeHybridTask:(NSString *)source destination:(NSString *)destination
{
	PipingTask *task = [self hdiUtilTask];
	[task setArguments:@[@"makehybrid", @"-iso", @"-udf", @"-udf-version", @"1.0.2",
							@"-udf-volume-name",_diskName, @"-o", destination, source]];
	return task;
}

- (void)performCleanTempSources:(NSNotification *)notification
{
	if (![self checkPreviousTask:notification]) {
		return;
	}

	[self postStatusNotification:NSLocalizedString(@"Cleaning temporary files.","")];
	NSError *err = nil;
    [[NSFileManager defaultManager]
                removeItemAtPath:[notification userInfo][@"dmgSource"]
                        error:&err];
    if (err) {
        NSLog(@"%@", err);
    }
	[_myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
}

- (void)performMakeHybrid:(NSNotification *)notification
{
	if (![self checkPreviousTask:notification]) {
		return;
	}
	
	[self postStatusNotification:NSLocalizedString(@"Creating a hybrid disk image.","")];
	
	NSString *source = [notification userInfo][@"dmgSource"];
	NSString *destination = [notification userInfo][@"dmgDestination"];
	PipingTask *task = [self makeHybridTask:source destination:destination];
	[_myNotiCenter addObserver:self selector:@selector(performCleanTempSources:)
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
		imageSize = [@(sourceSize) stringValue];
	
	[self postStatusNotification: NSLocalizedString(@"Preparing.",
													"Status message of checking condition.")];

	NSString* dmg_target = _dmgName;

	if (isReplacing) {
		NSString *target_path = [_workingLocationURL.path stringByAppendingPathComponent:_dmgName];
		NSFileManager *file_manager = [NSFileManager defaultManager];
		if ([file_manager fileExistsAtPath:target_path]) {
			NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
			NSInteger tag;
			if (![workspace performFileOperation:NSWorkspaceRecycleOperation
                                    source:_workingLocationURL.path destination:@""
                                   files:@[_dmgName] tag:&tag]) {
#if useLog
				NSLog(@"can not delete");
#endif
				[self setTerminationMessage:[NSString stringWithFormat:
											 NSLocalizedString(@"The file \n %@ could not be removed.", 
															   "can not trash existing file"),
											 target_path]];
				self.terminationStatus = 1;
				[_myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
				return;
			}
		}
	}
	
	PipingTask *task = nil;
	NSString *command = [_dmgOptions command];
	if ([command isEqualToString:@"makehybrid"]) {
		if (isOnlyFolder) {
			NSDocument<DMGDocument>* source_item = [_sourceItems lastObject];
			task = [self makeHybridTask:[[source_item fileURL] path]
                            destination:dmg_target];
			[_myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:)
								 name:NSTaskDidTerminateNotification object:task];
			[self postStatusNotification:NSLocalizedString(@"Creating a hybrid disk image.","")];
		} else {
			NSString *tmp_name = [self uniqueName:_diskName suffix:@"" location:_tmpDir];
			NSString *tmp_path = [_tmpDir stringByAppendingPathComponent:tmp_name];
            if ([[NSFileManager defaultManager]
                                createDirectoryAtURL: [tmp_path fileURL]
                                    withIntermediateDirectories:YES
                                            attributes:nil error:nil]) {
                [self copySourceItems:[NSNotification notificationWithName:@"StartCopySources"
                            object:nil
                          userInfo:@{@"copyDestination": tmp_path,
                                @"sourceEnumerator": [_sourceItems objectEnumerator],
                                @"nextSelector": @"performMakeHybrid:",
                                @"dmgSource": tmp_path,
                                @"dmgDestination": dmg_target}]];
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
			NSString *tmp_name = [self uniqueName:_diskName
                                           suffix:a_suffix location:_tmpDir];
#if useLog
			NSLog(tmp_name);
#endif
			dmg_target = [_tmpDir stringByAppendingPathComponent:tmp_name];
			self.sourceDmgPath = dmg_target;
		}
		
		NSString *dmg_type;

		if ([[_dmgOptions dmgFormat] isEqualToString:@"UDSP"])
			dmg_type = @"SPARSE";
		else
			dmg_type = @"UDIF";
		NSString *fs = [_dmgOptions filesystem];
		[task setArguments:@[@"create",@"-fs", fs,@"-size",imageSize,
                    @"-layout",@"None",@"-type",dmg_type,@"-volname",_diskName,
								dmg_target,@"-plist"]];		
		[_myNotiCenter addObserver:self selector:@selector(attachDiskImage:)
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
	
	[_myNotiCenter removeObserver:self];
	
	if ([dmg_task terminationStatus] != 0) {
#if useLog
		NSLog(@"termination status is not 0");
#endif
		[self setTerminationMessage:[dmg_task stderrString]];
#if useLog
		NSLog(terminationMessage);
#endif
		if ([_terminationMessage hasSuffix:@".Trashes: Permission denied\n"]) {
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
				[detachTask setArguments:@[@"detach",_devEntry]];
				[detachTask launch];
			}
			self.terminationStatus = [dmg_task terminationStatus];
			[_myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
			return NO;
		}
	} else {
		[self setTerminationMessage:nil];
	}
#if useLog	
	NSLog(@"termination status is 0");
#endif
	NSString *firstArg = [dmg_task arguments][0];
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
		[_myNotiCenter addObserver:self selector:@selector(deleteSourceDmg:)
			name:NSTaskDidTerminateNotification object:dmg_task];			
	else
		[_myNotiCenter addObserver:self selector:@selector(dmgTaskTerminate:)
			name:NSTaskDidTerminateNotification object:dmg_task];
	
	NSMutableArray *arguments = @[@"convert", _sourceDmgPath, @"-format",
                               [_dmgOptions dmgFormat], @"-o",_dmgName,@"-plist"].mutableCopy;
	
	if ([[_dmgOptions dmgFormat] isEqualToString:@"UDZO"]) {
		NSString *zlibLevelString = [NSString stringWithFormat:@"zlib-level=%i", [_dmgOptions compressionLevel]+1];
		[arguments addObjectsFromArray:@[@"-imagekey" ,zlibLevelString]];
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
        
    [[NSFileManager defaultManager] removeItemAtPath:_sourceDmgPath error:nil];
	if ([self checkPreviousTask:notification]) {
		if ([_dmgOptions internetEnable])
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
	_terminationStatus = [dmg_task terminationStatus];
	[_myNotiCenter removeObserver:self];
	
	if (_terminationStatus) {
		[self setTerminationMessage:[dmg_task stderrString]];
	} else if ([_dmgOptions putawaySources]) {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSEnumerator *enumerator = [_sourceItems objectEnumerator];
		NSDocument<DMGDocument> *item;
		while (item = [enumerator nextObject]) {
			NSInteger tag;
			NSString *path = [[item fileURL] path];
			NSString *dir = [path stringByDeletingLastPathComponent];
			NSString *itemname = [path lastPathComponent];
			[workspace performFileOperation:NSWorkspaceRecycleOperation
									 source:dir destination:@"" files:@[itemname]
										tag:&tag];
		}
	}
	
	[_myNotiCenter postNotificationName: @"DmgDidTerminationNotification" object:self];
#if useLog
	NSLog(@"end dmgTaskTerminate");
#endif
}

- (void)aboartTask
{
	[_myNotiCenter removeObserver:self];
	[_currentTask terminate];
	if (isAttached) {
		PipingTask *dmg_task = [self hdiUtilTask];
		[dmg_task setArguments:@[@"detach", _devEntry]];
		[self launchAsCurrentTask:dmg_task];
	}
	
	NSString *dmg_path = [_workingLocationURL.path
                          stringByAppendingPathComponent:_dmgName];
	NSFileManager *file_manager = [NSFileManager defaultManager];
	if ([file_manager fileExistsAtPath:dmg_path]) {
		[file_manager removeItemAtPath:dmg_path error:nil];
	}
	
	if ((willBeConverted) && ([file_manager fileExistsAtPath:_sourceDmgPath])) {
		[file_manager removeItemAtPath:_sourceDmgPath error:nil];
	}
	
}

@end

