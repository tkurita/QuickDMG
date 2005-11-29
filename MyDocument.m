#import "MyDocument.h"
#import "MyWindowController.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    }
    return self;
}

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

- (void)makeWindowControllers
{
    //NSLog(@"start makeWindowControlls");
	targetWindowController = [[MyWindowController alloc] initWithWindowNibName:@"MyDocument"];
    [self addWindowController:targetWindowController];
}

- (void)setFormatDict:(NSDictionary *)dictionary
{
	[dmgMaker setDmgFormat:[dictionary objectForKey:@"formatID"]];
	[dmgMaker setDmgSuffix:[dictionary objectForKey:@"formatSuffix"]];	
}

- (DiskImageMaker *)dmgMaker
{
	return self->dmgMaker;
}

- (void)setDmgMaker:(DiskImageMaker *)theObject
{
	[theObject retain];
	[dmgMaker release];
	dmgMaker = theObject;
}

- (BOOL)readFromFile:(NSString *)filePath ofType:(NSString *)type
{
	//NSLog(@"start readFromFile");
	DiskImageMaker *dmgObj = [[DiskImageMaker alloc] initWithSourcePath:filePath];
	[self setDmgMaker:[dmgObj autorelease]];
	//NSLog(filePath);
	
    return YES;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[targetWindowController release];
	[super dealloc];
}

- (void)setIsFirstDocument
{
	self->isFirstDocument = TRUE;
}

- (BOOL)isFirstDocument
{
	return self->isFirstDocument;
}

-(void) dmgDidTerminate:(NSNotification *) notification
{
	//NSLog(@"start dmgDidTerminate in MyDocument");
	DiskImageMaker* dmgObj = [notification object];
	if ([dmgObj terminationStatus] == 0) {
		[self close];
	}
	else {
		//NSLog(@"termination status is not 0");
		NSString *theMessage = [dmgObj terminationMessage];
		//NSLog(theMessage);
		[targetWindowController showAlertMessage:NSLocalizedString(@"Error! Can't progress jobs.","") withInformativeText:theMessage];
	}
}

- (NSString *)updateTargetPathByFormatDict:(NSDictionary *)dictionary
{
	[dmgMaker setDmgFormat:[dictionary objectForKey:@"formatID"]];
	[dmgMaker setDmgSuffix:[dictionary objectForKey:@"formatSuffix"]];
	
	return [dmgMaker dmgPath];
}

- (void)makeDmg
{
	if (![dmgMaker checkWorkingLocationPermission]) {
		NSString* detailMessage = [NSString stringWithFormat:NSLocalizedString(@"No write permission",""),
			[dmgMaker workingLocation]];
		[targetWindowController showAlertMessage:NSLocalizedString(@"Access right is insufficiency.","") withInformativeText:detailMessage];
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
			withInformativeText:NSLocalizedString(@"No enough free space to create a disk image.", "")];
	}
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
