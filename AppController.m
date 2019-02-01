#import <Cocoa/Cocoa.h>
#import "AppController.h"
#import "MDMGWindowController.h"
#import "DonationReminder/DonationReminder.h"
#import "UtilityFunctions.h"
#import "DMGDocumentController.h"
#import "ExpandDMGWindowController.h"

#define useLog 0

#ifdef SANDBOX
#else
#define SANDBOX 0
#endif

@implementation AppController

static BOOL AUTO_QUIT = YES;

- (IBAction)newDiskImage:(id)sender
{
	id mdmg_window = [[MDMGWindowController alloc] initWithWindowNibName:@"MDMGWindow"];
	[mdmg_window showWindow:self];
}

- (void)processFiles:(NSArray *)filenames
{
	if ([filenames count] > 1) {
		id mdmg_window = [[MDMGWindowController alloc] initWithWindowNibName:@"MDMGWindow"];
		[mdmg_window showWindow:self withFiles:URLsFromPaths(filenames)];
	}
	else {
        
        [documentController
            openDocumentWithContentsOfURL:[URLsFromPaths(filenames) lastObject]
            display:YES
            completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                                 if (document) {
                                     if (![[document windowControllers] count]) {
                                         [document makeWindowControllers];
                                     }
                                     [document showWindows];
                                     
                                 } else {
                                     NSLog(@"%@",[error localizedDescription]);
                                 }
                             }];
	}
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
#if useLog
	NSLog(@"start openFiles for :%@",[filenames description]);
#endif		
	[self processFiles:filenames];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return YES;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication
{
#if useLog
	NSLog(@"applicationOpenUntitledFile");
#endif	
	[self openFinderSelection];
	return YES;
}

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (void)expandDmgFromPasteboard:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
	NSArray *types = [pboard types];
	NSArray *filenames;
	if (![types containsObject:NSFilenamesPboardType] 
		|| !(filenames = [pboard propertyListForType:NSFilenamesPboardType])) {
        *error = NSLocalizedString(@"Error: Pasteboard doesn't contain file paths.",
								   @"Pasteboard couldn't give string.");
        return;
    }

	ExpandDMGWindowController *edmgw_controller = [[ExpandDMGWindowController alloc]
												  initWithWindowNibName:@"ExpandDMGWindow"];
	[edmgw_controller processFiles:filenames];
}

- (void)createDmgFromPasteboard:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
#if useLog
	NSLog(@"start createDmgFromPasteboard");
#endif
	NSArray *types = [pboard types];
	NSArray *filenames;
	if (![types containsObject:NSFilenamesPboardType] 
			|| !(filenames = [pboard propertyListForType:NSFilenamesPboardType])) {
        *error = NSLocalizedString(@"Error: Pasteboard doesn't contain file paths.",
								   @"Pasteboard couldn't give string.");
        return;
    }
	
	[self processFiles:filenames];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)openFinderSelection
{
	NSArray *docArray = [documentController documents];
	if ([docArray count] != 0) {
#if useLog
		NSLog(@"Already window is opened. Dont't obtain Finder's selection.");
#endif
		return;
	}
	NSDictionary * errorDict = nil;
    NSAppleEventDescriptor * scriptResult = nil;
    if (!SANDBOX) {
        NSBundle * bundle = [NSBundle mainBundle];
        NSString * scriptPath = [bundle pathForResource:@"GetFinderSelection" ofType:@"scpt"];
        NSURL * scriptURL = [NSURL fileURLWithPath:scriptPath];
        NSAppleScript * getFinderSelection = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errorDict];
        scriptResult = [getFinderSelection executeAndReturnError:&errorDict];
    }
	if (errorDict != nil) {
#if useLog
		NSLog(@"%@", [errorDict description]);
#endif
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:
			[NSString stringWithFormat:@"AppleScript Error : %@",errorDict[NSAppleScriptErrorNumber]]
			];
		[alert setInformativeText:errorDict[NSAppleScriptErrorMessage]];
		[alert setAlertStyle:NSWarningAlertStyle];
		if ([alert runModal] == NSAlertFirstButtonReturn) {
		} 
		return;
	}
	
	
	if ((!SANDBOX) && ([scriptResult descriptorType] == typeAEList)) {
		NSMutableArray *filenames = [NSMutableArray array];
		for (unsigned int i=1; i <= [scriptResult numberOfItems]; i++) {
			NSString *a_selection = [[scriptResult descriptorAtIndex:i] stringValue];
			[filenames addObject:a_selection];
		}
		if ([filenames count] > 1) {
            [[[MDMGWindowController alloc]
                initWithWindowNibName:@"MDMGWindow"]
                        showWindow:self withFiles:URLsFromPaths(filenames)];

		} else {
            [documentController openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[filenames lastObject]]
                                                      display:YES
                                            completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {}];
		}
	}
	else {
		[documentController openDocument:self];
	}
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	[NSApp setServicesProvider:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidFinishLaunching");
#endif
	
	NSAppleEventDescriptor *ev = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
#if useLog
	NSLog(@"%@", [ev description]);
#endif
	AEEventID evid = [ev eventID];
	BOOL should_process = NO;
	NSAppleEventDescriptor *propData;
	switch (evid) {
		case kAEOpenDocuments:
#if useLog			
			NSLog(@"kAEOpenDocuments");
#endif
			break;
		case kAEOpenApplication:
#if useLog			
			NSLog(@"kAEOpenApplication");
#endif
			propData = [ev paramDescriptorForKeyword: keyAEPropData];
			DescType type = propData ? [propData descriptorType] : typeNull;
			OSType value = 0;
			if(type == typeType) {
				value = [propData typeCodeValue];
				switch (value) {
					case keyAELaunchedAsLogInItem:
						AUTO_QUIT = NO;
						break;
					case keyAELaunchedAsServiceItem:
						break;
				}
			} else {
				should_process = YES;
			}
			break;
	}
	
    if (!SANDBOX)
        [DonationReminder remindDonation];
    
#if useLog
	NSLog(@"end applicationDidFinishLaunching");
#endif
}

- (void)awakeFromNib
{
	NSString *defaultsPlistPath = [[NSBundle mainBundle] 
									pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary *defautlsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:defautlsDict];
    /* Disable restoring documents.
       Adding "NSQuitAlwaysKeepsWindows" entry in UserDefaults.plist does not work. */
    [userDefaults setBool:NO forKey:@"NSQuitAlwaysKeepsWindows"];

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return AUTO_QUIT;
}

@end
