#import "DMGDocument.h"
#import "DMGWindowController.h"
#import "PipingTask.h"
#import "PathExtra.h"

#define useLog 0

NSImage *convertImageSize(NSImage *iconImage, int imgSize)
{
	NSArray * repArray = [iconImage representations];
	NSEnumerator *repEnum = [repArray objectEnumerator];
	NSImageRep *imageRep;
	NSSize targetSize = NSMakeSize(imgSize, imgSize);
	NSImage *new_image;
	BOOL hasTargetSize = NO;
	while (imageRep = [repEnum nextObject]) {
		if (NSEqualSizes([imageRep size],targetSize)) {
			hasTargetSize = YES;
			break;
		}
	}
	
	if (hasTargetSize) {
		[iconImage setScalesWhenResized:NO];
		new_image = [iconImage copy];
		[new_image setSize:targetSize];
#if useLog
		NSLog(@"have target size %i", imgSize);
#endif
	}
	else {
		[iconImage setScalesWhenResized:YES];
		new_image = [iconImage copy];
		[new_image setSize:targetSize];
#if useLog
		NSLog(@"not have target size %i", imgSize);
#endif
	}
	
	return [new_image autorelease];
	//return new_image;
}

@implementation DMGDocument

#pragma mark internal use
- (NSDictionary *)fileInfo
{
	if (!_fileInfo) {
		NSError *err = nil;
        self.fileInfo = [self.fileURL
                         resourceValuesForKeys:@[NSURLIsPackageKey, NSURLIsDirectoryKey,NSURLFileSizeKey]
                         error:&err];
	}
	return _fileInfo;
}

#pragma mark DMGDocument Protocol
- (BOOL)isFolder 
{
    return _fileInfo[NSURLIsDirectoryKey];
}

- (BOOL)isPackage
{
   return _fileInfo[NSURLIsPackageKey];
}

- (unsigned long long)fileSize
{
#if useLog
	NSLog(@"start fileSize");
#endif
	unsigned long long result;
	
	if ([self isFolder]) {
		PipingTask *du = [[PipingTask alloc] init];
		[du setLaunchPath:@"/usr/bin/du"];
		[du setArguments:[NSArray arrayWithObjects:@"-sk",self.fileURL.path,nil]];
		[du launch];
		[du waitUntilExit];
		result = [[du stdoutString] intValue];
		result = (result * 1024 *1.1);
		[du release];
	}
	else {
		result = _fileInfo[NSURLFileSizeKey];
	}
#if useLog
	NSLog(@"end fileSize");
#endif
	return result;
}

#pragma mark accessors
- (NSString *)itemName
{
	return [self displayName];
}

- (NSImage *)iconImg16
{
	if (!_iconImg) {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		self.iconImg = [workspace iconForFile:self.fileURL.path];
	}
	return convertImageSize(_iconImg, 16);
}

- (BOOL)isMultiSourceMember
{
	return isMultiSourceMember;
}

- (void)setIsMultiSourceMember:(BOOL)aBool
{
	isMultiSourceMember = aBool;
}

#pragma mark init and dealloc
- (void)dealloc
{
#if useLog
	NSLog(@"dealloc DMGDocument");
#endif
	[_iconImg release];
	[_fileInfo release];
	[super dealloc];
}

- (id) init
{
	if ((self = [super init])) {
        isMultiSourceMember = NO;
    }
	return self;
}

- (void)dispose:(id)sender
{
	if (!isMultiSourceMember) {
		switch ([[self windowControllers] count]) {
		case 0:
			[[NSDocumentController sharedDocumentController] removeDocument:self];
			break;
		case 1:
			if ([[self windowControllers] containsObject:sender])
				[[NSDocumentController sharedDocumentController] removeDocument:self];
			break;
		default:
			break;
		}
	}
}

#pragma mark overriding NSDocument
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    return nil;
}

- (BOOL)readFromFile:(NSString *)filePath ofType:(NSString *)type
{
#if useLog
	NSLog(@"start readFromFile");
#endif
    return YES;
}

- (void)makeWindowControllers
{
#if useLog
	NSLog(@"start makeWindowControlls");
#endif	
	DMGWindowController *a_controller = [[DMGWindowController alloc] initWithWindowNibName:@"DMGDocument"];
    [self addWindowController:[a_controller autorelease]];
}

@end
