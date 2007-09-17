#import "MyDocument.h"
#import "MyWindowController.h"

#define useLog 0

@implementation MyDocument

#pragma mark dmg tasks
- (void)setFormatDict:(NSDictionary *)dictionary
{
	[dmgMaker setDmgFormat:[dictionary objectForKey:@"formatID"]];
	[dmgMaker setDmgSuffix:[dictionary objectForKey:@"extension"]];	
}

-(void) dmgDidTerminate:(NSNotification *) notification
{
#if useLog
	NSLog(@"start dmgDidTerminate in MyDocument");
#endif	
	DiskImageMaker* dmgObj = [notification object];
	if ([dmgObj terminationStatus] == 0) {
		[self close];
	}
	else {
#if useLog
		NSLog(@"termination status is not 0");
#endif		
		NSString *theMessage = [dmgObj terminationMessage];
		[targetWindowController showAlertMessage:NSLocalizedString(@"Error! Can't progress jobs.","") withInformativeText:theMessage];
	}
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
	[notificationCenter removeObserver:targetWindowController];
}

- (void)makeDmg
{
	if (![dmgMaker checkWorkingLocationPermission]) {
		NSString* detailMessage = [NSString stringWithFormat:NSLocalizedString(@"No write permission",""),
			[dmgMaker workingLocation]];
		[targetWindowController showAlertMessage:NSLocalizedString(@"Insufficient access right.","") withInformativeText:detailMessage];
		return;
	}
	
	if ([dmgMaker checkFreeSpace]) {
		NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:targetWindowController
							   selector:@selector(showStatusMessage:)
								   name:@"DmgProgressNotification"
								 object:dmgMaker];
		[notificationCenter addObserver:self
							   selector:@selector(dmgDidTerminate:)
								   name:@"DmgDidTerminationNotification"
								 object:dmgMaker];
		
		[dmgMaker createDiskImage];
	}
	else {
		[targetWindowController 
			showAlertMessage:NSLocalizedString(@"Can't progress jobs.","")
			withInformativeText:NSLocalizedString(@"Not enough free space for creating a disk image.", "")];
	}
}

#pragma mark accessors
- (DiskImageMaker *)dmgMaker
{
	return dmgMaker;
}

- (void)setDmgMaker:(DiskImageMaker *)theObject
{
	[theObject retain];
	[dmgMaker release];
	dmgMaker = theObject;
}

- (void)setIsFirstDocument
{
	isFirstDocument = TRUE;
}

- (BOOL)isFirstDocument
{
	return isFirstDocument;
}

#pragma mark init and dealloc
- (void)dealloc
{
	[targetWindowController release];
	[super dealloc];
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
	DiskImageMaker *dmgObj = [[DiskImageMaker alloc] initWithSourcePath:filePath];
	[self setDmgMaker:[dmgObj autorelease]];
    return YES;
}

- (void)makeWindowControllers
{
#if useLog
	NSLog(@"start makeWindowControlls");
#endif	
	targetWindowController = [[MyWindowController alloc] initWithWindowNibName:@"MyDocument"];
    [self addWindowController:targetWindowController];
}

#pragma mark others

- (NSString *)updateTargetPathByFormatDict:(NSDictionary *)dictionary
{
	[dmgMaker setDmgFormat:[dictionary objectForKey:@"formatID"]];
	[dmgMaker setDmgSuffix:[dictionary objectForKey:@"extension"]];
	
	return [dmgMaker dmgPath];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ( [super respondsToSelector:aSelector] )
        return YES;
    else 
		return [dmgMaker respondsToSelector:aSelector];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature*  signature;
    
    signature = [dmgMaker methodSignatureForSelector:selector];
    if (signature) {
        return signature;
    }
    
    return [[self class] instanceMethodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];
	if ([dmgMaker respondsToSelector:aSelector])
        [invocation invokeWithTarget:dmgMaker];
    else
        [self doesNotRecognizeSelector:aSelector];
}

@end
