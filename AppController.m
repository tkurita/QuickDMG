#import "AppController.h"
#import "MDMGWindowController.h"
#import "DonationReminder/DonationReminder.h"
#import "UtilityFunctions.h"
#import "DMGDocumentController.h"

#define useLog 0


@implementation AppController

- (BOOL)isFirstOpen
{
	return isFirstOpen;
}

- (void)setFirstOpen:(BOOL)aFlag
{
	isFirstOpen = aFlag;
}

- (IBAction)newDiskImage:(id)sender
{
	id mdmg_window = [[MDMGWindowController alloc] initWithWindowNibName:@"MDMGWindow"];
	[mdmg_window showWindow:self];
}

- (void)processFiles:(NSArray *)filenames
{
	NSError *error = nil;
	
	if ([filenames count] > 1) {
		id mdmg_window = [[MDMGWindowController alloc] initWithWindowNibName:@"MDMGWindow"];
		[mdmg_window showWindow:self withFiles:URLsFromPaths(filenames)];
	}
	else {
		NSDocument *a_doc = [documentController
						openDocumentWithContentsOfURL:[URLsFromPaths(filenames) lastObject] 
							display:YES error:&error];
		if (a_doc) {
			if (![[a_doc windowControllers] count]) {
				[a_doc makeWindowControllers];
			}
			[a_doc showWindows];

		} else {
			NSLog([error localizedDescription]);
		}
	}
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
#if useLog
	NSLog([NSString stringWithFormat:@"start openFiles for :%@",[filenames description]]);
#endif		
	[self processFiles:filenames];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
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
	
	NSBundle * bundle = [NSBundle mainBundle];
	NSString * scriptPath = [bundle pathForResource:@"GetFinderSelection" ofType:@"scpt" inDirectory:@"Scripts"
		];
	NSURL * scriptURL = [NSURL fileURLWithPath:scriptPath];
	NSDictionary * errorDict = nil;
	NSAppleScript * getFinderSelection = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errorDict];
	NSAppleEventDescriptor * scriptResult = [getFinderSelection executeAndReturnError:&errorDict];
	if (errorDict != nil) {
#if useLog
		NSLog([errorDict description]);
#endif
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:
			[NSString stringWithFormat:@"AppleScript Error : %@",[errorDict objectForKey:NSAppleScriptErrorNumber]]
			];
		[alert setInformativeText:[errorDict objectForKey:NSAppleScriptErrorMessage]];
		[alert setAlertStyle:NSWarningAlertStyle];
		if ([alert runModal] == NSAlertFirstButtonReturn) {
		} 
		[alert release];
		return;
	}
	
	[getFinderSelection release];
	
	if ([scriptResult descriptorType] == typeAEList) {
		NSMutableArray *filenames = [NSMutableArray array];
		for (unsigned int i=1; i <= [scriptResult numberOfItems]; i++) {
			NSString *a_selection = [[scriptResult descriptorAtIndex:i] stringValue];
			[filenames addObject:a_selection];
		}
		if ([filenames count] > 1) {
			MDMGWindowController* mdmg_window = [[MDMGWindowController alloc] 
												initWithWindowNibName:@"MDMGWindow"];
			[mdmg_window showWindow:self withFiles:URLsFromPaths(filenames)];
		} else {
			DMGDocument *a_doc = [documentController 
					openDocumentWithContentsOfFile:[filenames lastObject] display:YES];
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

- (void)delayedOpenFinderSelection
{
#if useLog
	NSLog(@"delayedOpenFinderSelection");
#endif	
	[self openFinderSelection];
	isFirstOpen = NO;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidFinishLaunching");
#endif
	
	[DonationReminder remindDonation];
	// try to obtain Finder's selection after system serviece call.
	[self performSelector:@selector(delayedOpenFinderSelection)
											withObject:nil afterDelay:0.1];
#if useLog
	NSLog(@"end applicationDidFinishLaunching");
#endif
}

- (void)awakeFromNib
{
	isFirstOpen = YES;
	NSString *defaultsPlistPath = [[NSBundle mainBundle] 
									pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary *defautlsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:defautlsDict];

}

@end
