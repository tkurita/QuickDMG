#import "MyWindowController.h"
#import "MyDocument.h"
#import "DmgDataSource.h"

static const int DIALOG_OK		= 128;
static const int DIALOG_ABORT	= 129;

@implementation MyWindowController

- (IBAction)zlibLevelButton:(id)sender
{
	
}

- (IBAction)abortAction:(id)sender
{
	[[NSApplication sharedApplication] endSheet: [sender window] returnCode:DIALOG_ABORT];
	[progressBar stopAnimation:self];
}

- (IBAction)cancelAction:(id)sender
{
	[[self document] close];
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSString *resultPath = [sheet filename];
		//NSLog(resultPath);
		id document = [self document];
		[document setWorkingLocation:[resultPath stringByDeletingLastPathComponent]];
		[document setCustomDmgName:[resultPath lastPathComponent]];
		[self setTargetPath:[document dmgPath]];
	}
}

- (IBAction)chooseTargetPath:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	id document = [self document];
	[savePanel setRequiredFileType:[document dmgSuffix]];
	[savePanel setCanSelectHiddenExtension:YES];
	//[savePanel setExtensionHidden:YES];
	[savePanel beginSheetForDirectory:[document workingLocation] file:[document dmgName]
				   modalForWindow:[self window]
					modalDelegate:self
				   didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
					  contextInfo:nil];
}

- (IBAction)internetEnableButton:(id)sender
{
	
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    [sheet orderOut:self];
    
    // Check return code
    if(returnCode == DIALOG_ABORT) {
        // Cancel button was pushed
        //NSLog(@"Sheet is canceled");
        return;
    }
    else if(returnCode == DIALOG_OK) {
        // OK button was pushed
        //NSLog(@"Sheet is accepted");
    }
}

- (IBAction)okAction:(id)sender
{	
	[[NSApplication sharedApplication] beginSheet:progressSheet 
								modalForWindow:[self window] 
								modalDelegate:self 
								didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
								contextInfo:nil];
	[progressBar startAnimation:self];
	
	id theDocument = [self document];
	BOOL internetEnableFlag = ([internetEnableButton state] == NSOnState);
	[theDocument setInternetEnable:internetEnableFlag];
	NSString *zlibLevel = [zlibLevelButton titleOfSelectedItem];
	[theDocument setCompressionLevel:zlibLevel];
	BOOL deleteDSStoreFlag = ([deleteDSStoreButton state] == NSOnState);
	[theDocument setDeleteDSStore:deleteDSStoreFlag];
	
	[theDocument makeDmg];
}

- (void)setTargetFormatFromIndex:(int)formatIndex
{
	[dmgFormatTable selectRow:formatIndex byExtendingSelection:NO];
}

- (NSDictionary *)dmgFormatDict
{
	//NSLog(@"start dmgFormartDict");
	int selectedIndex = [dmgFormatTable selectedRow];
	DmgDataSource *dataSource = [dmgFormatTable dataSource];
	NSString *formatID = [dataSource formatIDFromIndex:selectedIndex];	
	NSString *formatSuffix = [dataSource formatSuffixFromIndex:selectedIndex];
	NSNumber *canInternetEnable = [dataSource canInternetEnableFromIndex:selectedIndex];
	return [NSDictionary dictionaryWithObjectsAndKeys:formatID,@"formatID",
			formatSuffix,@"formatSuffix",
			canInternetEnable,@"canInternetEnable",nil];
}

- (void)setSourcePath:(NSString *)string
{
    //NSLog(@"setSroucePath");
	if (string) {
        [sourcePathView setStringValue:string];
    }
}

- (void)setTargetPath:(NSString *)string
{
    if (string) {
        [targetPathView setStringValue:string];
    }
}

//delegate for window
- (void)windowWillClose:(NSNotification *)aNotification
{
	//NSLog(@"start windowWillClose");
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	int selectedIndex = [dmgFormatTable selectedRow];
	[userDefaults setInteger:selectedIndex forKey:@"formatIndex"];
	
	BOOL internetEnableFlag = ([internetEnableButton state] == NSOnState);
	[userDefaults setBool:internetEnableFlag forKey:@"InternetEnable"];
	
	BOOL deleteDSStoreFlag = ([deleteDSStoreButton state] == NSOnState);
	[userDefaults setBool:deleteDSStoreFlag forKey:@"deleteDSStore"];	
	
	[userDefaults setInteger:[zlibLevelButton indexOfSelectedItem] forKey:@"compressionLevel"];
}

- (void)awakeFromNib
{
	//NSLog(@"awakeFromNib in MyWindowController");
	
	NSString *defaultsPlistPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary *defautlsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath];

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	//format and suffix
	[userDefaults registerDefaults:defautlsDict];
	int formatIndex = [userDefaults integerForKey:@"formatIndex"];
	[dmgFormatTable selectRowIndexes:[NSIndexSet indexSetWithIndex:formatIndex] byExtendingSelection:NO];
	NSDictionary *formatDict = [self dmgFormatDict];
	
	id theDocument = [self document];
	[theDocument setFormatDict:formatDict];

	[sourcePathView setStringValue:[theDocument fileName]];
	[targetPathView setStringValue:[theDocument dmgPath]];
	
	//internet-enable
	if ([userDefaults boolForKey:@"InternetEnable"])
		[internetEnableButton setState:NSOnState];
	else
		[internetEnableButton setState:NSOffState];
	
	[internetEnableButton setEnabled:[[formatDict objectForKey:@"canInternetEnable"] charValue]];
	
	//compression level
	[zlibLevelButton selectItemAtIndex:[userDefaults integerForKey:@"compressionLevel"]];
	[zlibLevelButton setEnabled:[[formatDict objectForKey:@"formatID"] isEqualToString:@"UDZO"]];
	
	//delete .DS_Store
	if ([userDefaults boolForKey:@"deleteDSStore"])
		[deleteDSStoreButton setState:NSOnState];
	else
		[deleteDSStoreButton setState:NSOffState];
	
	//window position
	[[self window] center];
}

- (void)showStatusMessage:(NSNotification *)notification
{
	//NSLog(@"showStatusMessage in MyWindowController");
	NSString* statusMessage = [[notification userInfo] objectForKey:@"statusMessage"];
	[progressText setStringValue: statusMessage];
}

- (void)showAlertMessage:(NSString *)theMessageText withInformativeText:(NSString *)infoText
{
	NSWindow *window = [self window];
	
	NSWindow *sheet = [window attachedSheet];
	if (sheet != nil) {
		[[NSApplication sharedApplication] endSheet:sheet returnCode:DIALOG_ABORT];
	}

	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:theMessageText];
	[alert setInformativeText:infoText];
	
	[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)alertDidEnd:(NSWindow*)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[alert release];
}

//delegate for table view
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([[self window] isVisible]) {
		MyDocument *document = [self document];
		NSDictionary *dmgFormatDict = [self dmgFormatDict];
		NSString *targetPath = [document updateTargetPathByFormatDict:dmgFormatDict];
		[targetPathView setStringValue:targetPath];
		[internetEnableButton setEnabled:[[dmgFormatDict objectForKey:@"canInternetEnable"] charValue]];
		[zlibLevelButton setEnabled:[[dmgFormatDict objectForKey:@"formatID"] isEqualToString:@"UDZO"]];
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end
