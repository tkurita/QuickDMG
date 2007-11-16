#import "AppController.h"
#import "MDMGWindowController.h"
#import "DonationReminder/DonationReminder.h"
#import "UtilityFunctions.h"
#import "DMGDocumentController.h"

#define useLog 0


@implementation AppController

- (IBAction)newDiskImage:sender
{
	id mdmg_window = [[MDMGWindowController alloc] initWithWindowNibName:@"MDMGWindow"];
	[mdmg_window showWindow:self];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
#if useLog
	NSLog([NSString stringWithFormat:@"start openFiles for :%@",[filenames description]]);
#endif	
	NSError *error = nil;
	
	if ([filenames count] > 1) {
		id mdmg_window = [[MDMGWindowController alloc] initWithWindowNibName:@"MDMGWindow"];
		[mdmg_window loadWindow];
		[mdmg_window setupFileTable:URLsFromPaths(filenames)];
		[mdmg_window showWindow:self];
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
	
	isFirstOpen = NO;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (void)openFinderSelection
{
	NSArray *docArray = [documentController documents];
	if ([docArray count] != 0) {
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
			[mdmg_window loadWindow];
			[mdmg_window setupFileTable:URLsFromPaths(filenames)];
			[mdmg_window showWindow:self];
			[mdmg_window setIsFirstWindow];
		} else {
			DMGDocument *a_doc = [documentController 
					openDocumentWithContentsOfFile:[filenames lastObject] display:YES];
			[[[a_doc windowControllers] lastObject] setIsFirstWindow];
		}
	}
	else {
		[documentController setIsFirstDocument:YES];
		[documentController openDocument:self];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidFinishLaunching");
#endif
	[self openFinderSelection];
	[DonationReminder remindDonation];		
	[documentController setIsFirstDocument:NO];
}

- (void)awakeFromNib
{
	NSString *defaultsPlistPath = [[NSBundle mainBundle] 
									pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary *defautlsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:defautlsDict];

}

@end
