#import "AppController.h"

#import "DonationReminder/DonationReminder.h"

#define useLog 0

@implementation AppController

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (void)openFinderSelection
{
	NSArray *docArray = [documentController documents];
	if ([docArray count] != 0) {
		NSEnumerator *docEnumerator = [docArray objectEnumerator];
		id firstDoc;
		while (firstDoc = [docEnumerator nextObject]){
			[firstDoc setIsFirstDocument];
		}
		return;
	}
	
	NSBundle * bundle = [NSBundle mainBundle];
	NSString * scriptPath = [bundle pathForResource:@"GetFinderSelection" ofType:@"scpt" inDirectory:@"Scripts"
		];
	//NSLog(scriptPath);
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
		for (unsigned int i=1; i <= [scriptResult numberOfItems]; i++) {
			unsigned int nItem = [scriptResult numberOfItems];
			NSString *resultString = [[scriptResult descriptorAtIndex:i] stringValue];
			MyDocument *theDocument = [documentController openDocumentWithContentsOfFile:resultString display:YES];
			[theDocument setIsFirstDocument];
			//[theDocument makeDmg];
		}
		
	}
	else {
		//document = [documentController openUntitledDocumentOfType:@"anything" display:YES];
		[documentController setIsFirstDocument];
		[documentController openDocument:self];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidFinishLaunching");
#endif
	NSString *defaultsPlistPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary *defautlsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath];

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	//format and suffix
	[userDefaults registerDefaults:defautlsDict];

	[self openFinderSelection];
	[DonationReminder remindDonation];
		
}

@end
