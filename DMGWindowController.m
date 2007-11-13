#import "DMGWindowController.h"
#import "DMGDocument.h"
#import "DMGOptionsViewController.h"

#define useLog 0

@implementation DMGWindowController

#pragma mark accessors
- (id)dmgMaker
{
	return dmgMaker;
}

#pragma mark methods for sheet
- (void)alertDidEnd:(NSWindow*)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo //common
{
	[alert release];
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo // not common
{
	if (returnCode == NSOKButton) {
		NSString *resultPath = [sheet filename];
		id document = [self document];
		[document setWorkingLocation:[resultPath stringByDeletingLastPathComponent]];
		[document setCustomDmgName:[resultPath lastPathComponent]];
		[self setTargetPath:[document dmgPath]];
	}
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
	
	[alert beginSheetModalForWindow:window modalDelegate:self 
			didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)chooseTargetPath:(id)sender //not common
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

#pragma mark methods for setup
- (void)setIsFirstWindow
{
	isFirstWindow = YES;
}

- (void)setupProgressWindow //common
{
	if (!progressWindowController) {
		progressWindowController = [[DMGProgressWindowController alloc] initWithNibName:@"DMGProgressWindow"];
	}
	[progressWindowController beginSheetWith:self];
}

/*
- (void)setSourcePath:(NSString *)string
{
    //NSLog(@"setSroucePath");
	if (string) {
        [sourcePathView setStringValue:string];
    }
}
*/

- (void)setTargetPath:(NSString *)string // not common
{
    if (string) {
        [targetPathView setStringValue:string];
    }
}

- (void)setupDMGOptionsView //common
{
	dmgOptionsViewController = [[DMGOptionsViewController alloc]
								initWithNibName:@"DMGOptionsView" owner:self];
	[dmgOptionsBox setContentView:[dmgOptionsViewController view]];
	[okButton bind:@"enabled" toObject:[dmgOptionsViewController dmgFormatController] 
								withKeyPath:@"selectedObjects.@count" options:nil];
}

#pragma mark communicate with DiskImageMaker
- (void)makeDiskImage //common
{
	[self setupProgressWindow];
	if ([dmgMaker checkCondition:self]) {
		NSNotificationCenter* notification_center = [NSNotificationCenter defaultCenter];
		[notification_center addObserver:progressWindowController
							   selector:@selector(showStatusMessage:)
								   name:@"DmgProgressNotification"
								 object:dmgMaker];
		[notification_center addObserver:self
							   selector:@selector(dmgDidTerminate:)
								   name:@"DmgDidTerminationNotification"
								 object:dmgMaker];
		[dmgMaker createDiskImage];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object //not common
				change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"selectedObjects"]) {
		[dmgMaker resolveDmgName];
		[targetPathView setStringValue:[dmgMaker dmgPath]];
    }
}

-(void) dmgDidTerminate:(NSNotification *) notification //common
{
	DiskImageMaker* dmg_maker = [notification object];
	if ([dmg_maker terminationStatus] == 0) {
		[self close];
	}
	else {
#if useLog
		NSLog(@"termination status is not 0");
#endif		
		NSString *a_message = [dmg_maker terminationMessage];
		[self showAlertMessage:NSLocalizedString(@"Error! Can't progress jobs.","") 
								withInformativeText:a_message];
	}
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
}

#pragma mark delegate of NSWindow
- (void)windowWillClose:(NSNotification *)aNotification
{
	NSLog([NSString stringWithFormat:@"windowWillClose %i", [[NSApp windows] count]]);
	[[dmgOptionsViewController dmgFormatController] removeObserver:self 
													forKeyPath:@"selectedObjects"];

	[dmgOptionsViewController saveSettings];
	if (isFirstWindow) {
		int visible_windows = 0;
		NSEnumerator *enumerator = [[NSApp windows] objectEnumerator];
		NSWindow *a_window;
		while (a_window = [enumerator nextObject]) {
			visible_windows += [a_window isVisible];
		}
		
		if (visible_windows == 1) {
			//[NSApp terminate:self];
			[NSApp performSelectorOnMainThread:@selector(terminate:) withObject:self waitUntilDone:NO];
		}
	}
}

#pragma mark action
- (IBAction)cancelAction:(id)sender //common 
{
	[[self window] performClose:self];
}

- (IBAction)okAction:(id)sender //not common
{
	[self makeDiskImage];
}

#pragma mark initialize
- (void)dealloc
{
	//NSLog(@"dealloc DMGWindowController");
	[dmgOptionsViewController release];
	[progressWindowController release];
	[dmgMaker release];
	[super dealloc];
}

- (void)awakeFromNib
{
	//NSLog(@"awakeFromNib in DMGWindowController");
	[self setupDMGOptionsView];
	
	[[dmgOptionsViewController dmgFormatController] addObserver:self
							 forKeyPath:@"selectedObjects"
								 options:(NSKeyValueObservingOptionNew)
									context:NULL];
					
	
	id theDocument = [self document];

	[sourcePathView setStringValue:[theDocument fileName]];
	dmgMaker = [[DiskImageMaker alloc] initWithSourceItem:theDocument];
	[dmgMaker setDMGOptions:dmgOptionsViewController];
	[targetPathView setStringValue:[dmgMaker dmgPath]];
	
	[[self window] center];
	NSLog([NSString stringWithFormat:@"%i", [[NSApp windows] count]]);
}

@end
