#import "AppController.h"

@implementation AppController

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//NSLog(@"start applicationDidFinishLaunching");
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
	NSDictionary * errorDict;
	NSAppleScript * getFinderSelection = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errorDict];
	NSAppleEventDescriptor * scriptResult = [getFinderSelection executeAndReturnError:&errorDict];
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
@end
