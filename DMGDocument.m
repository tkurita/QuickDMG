#import "DMGDocument.h"
#import "DMGWindowController.h"
#import "PipingTask.h"

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
	if (!fileInfo) {
		NSFileManager *file_manager = [NSFileManager defaultManager];
		fileInfo = [[file_manager fileAttributesAtPath:[self fileName] traverseLink:NO] retain];
	}
	return fileInfo;
}

#pragma mark DMGDocument Protocol
- (BOOL)isFolder 
{
	return ([[self fileInfo] objectForKey:NSFileType] == NSFileTypeDirectory);
}

- (BOOL)isPackage
{
	return [[NSWorkspace sharedWorkspace] isFilePackageAtPath:[self fileName]];
}

- (unsigned long long)fileSize
{
	unsigned long long result;
	
	if ([self isFolder]) {
		/*
		NSTask * du =[[NSTask alloc] init];
		[du setLaunchPath:@"/usr/bin/du"];
		[du setArguments:[NSArray arrayWithObjects:@"-sk",[self fileName],nil]];
		
		NSPipe * du_out = [NSPipe pipe];
		[du setStandardOutput:du_out];
		[du launch];
		[du waitUntilExit];
		NSData * du_data = [[du_out fileHandleForReading] availableData];
		result = [[[[NSString alloc] initWithData:du_data encoding: NSUTF8StringEncoding] autorelease] intValue];
		*/
		PipingTask *du = [[PipingTask alloc] init];
		[du setLaunchPath:@"/usr/bin/du"];
		[du setArguments:[NSArray arrayWithObjects:@"-sk",[self fileName],nil]];
		[du launch];
		[du waitUntilExit];
		result = [[du stdoutString] intValue];
		result = (result * 1024 *1.1);
		[du release];
	}
	else {
		result = [[self fileInfo] fileSize];
	}
	return result;
}

#pragma mark accessors
- (NSString *)itemName
{
	return [self displayName];
}

- (void)setIconImg:(NSImage *)anImage
{
	[anImage retain];
	[iconImg release];
	iconImg = anImage;
}

- (NSImage *)iconImg16
{
	if (!iconImg) {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		[self setIconImg:[workspace iconForFile:[self fileName] ]];
	}
	return convertImageSize(iconImg, 16);
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
	[iconImg release];
	[fileInfo release];
	[super dealloc];
}

- (id) init
{
	[super init];
	isMultiSourceMember = NO;
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
