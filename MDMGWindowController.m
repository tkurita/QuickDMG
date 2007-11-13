#import "MDMGWindowController.h"
#import "DMGOptionsViewController.h"
#import "DMGDocument.h"
#import "KXTableView.h"
#import "FileTableController.h"
#import "RBSplitView/RBSplitView.h"
#import "RBSplitView/RBSplitSubview.h"

#define useLog 0

@implementation MDMGWindowController

- (void) dealloc {
	[super dealloc];
}

#pragma mark actions
- (IBAction)okAction:(id)sender
{
	NSSavePanel *save_panel = [NSSavePanel savePanel];
	[save_panel setRequiredFileType:[dmgOptionsViewController dmgSuffix]];
	[save_panel setCanSelectHiddenExtension:YES];
	[save_panel beginSheetForDirectory:nil file:nil
				   modalForWindow:[self window]
					modalDelegate:self
				   didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
					  contextInfo:nil];

}
#pragma mark delegate sheet
- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSString *result_path = [sheet filename];
		NSLog(result_path);
		if (!dmgMaker) {
			[dmgMaker release];
		}
		dmgMaker = [[DiskImageMaker alloc] initWithSourceItems:[fileListController arrangedObjects]];
		[dmgMaker setDMGOptions:dmgOptionsViewController];
		[dmgMaker setDestination:result_path];
		[sheet orderOut:self];
		[self makeDiskImage];
	}
}

#pragma mark setup contents

- (void)setupFileTable:(NSArray *)files
{
#if useLog	
	NSLog(@"setupFileTable in MDMGWindowController");
#endif
	[fileTableController addFileURLs:files];
	
	float row_height = [fileTable rowHeight];
	int nrows = [fileTable numberOfRows];
	NSSize spacing = [fileTable intercellSpacing];
	NSRect hframe =	[[fileTable headerView] frame];
	float table_height = hframe.size.height + ((row_height + spacing.height)*(nrows)) +5;

	float current_dimension = [splitSubview dimension];
	if (table_height > current_dimension) table_height = current_dimension;
	[splitSubview setDimension:table_height ];
}

#pragma mark delegate of KXTabelView

- (void)deleteTabelSelection:(id)sender
{
	NSArray *selected_items = [fileListController selectedObjects];
	//[fileListController remove:self];
	[fileListController removeObjects:selected_items];
	NSEnumerator *enumerator = [selected_items objectEnumerator];
	DMGDocument *a_source;
	while (a_source = [enumerator nextObject]) {
		[a_source setIsMultiSourceMember:NO];
		[a_source dispose:self];
	}
}

- (void)openTableSelection:(id)sender
{
	NSArray *selected_items = [fileListController selectedObjects];	
	NSEnumerator *enumerator = [selected_items objectEnumerator];
	DMGDocument *a_source;
	while (a_source = [enumerator nextObject]) {
		if (![[a_source windowControllers] count]) {
			[a_source makeWindowControllers];
		}
		[a_source showWindows];
	}
}

#pragma mark override NSWindowController
- (void)windowDidLoad
{
	#if useLog
	NSLog(@"windowDidLoad in MDMGWindowController");
	#endif
}

NSValue *lefttop_of_frame(NSRect aRect)
{
	return [NSValue valueWithPoint:NSMakePoint(NSMinX(aRect), NSMaxY(aRect))];
}

- (void)awakeFromNib
{
	#if useLog
	NSLog(@"awakeFromNib in MDMGWindowController");
	#endif
	[self setupDMGOptionsView];
	[fileTable setDeleteAction:@selector(deleteTabelSelection:)];
	[fileTable setDoubleAction:@selector(openTableSelection:)];
	isFirstWindow = NO;
	[[self window] center];
	NSValue *current_lt = lefttop_of_frame([[self window] frame]);
	
	NSMutableArray *left_tops = [NSMutableArray array];
	NSEnumerator *enumerator = [[NSApp windows] objectEnumerator];
	NSWindow *a_window;
	NSRect a_frame;
	while(a_window = [enumerator nextObject]) {
		if ([a_window isVisible]) {
			a_frame = [a_window frame];
			[left_tops addObject:lefttop_of_frame(a_frame)];
		}	
	}
	
	if ([left_tops count]) {
		while(1) {		
			if ([left_tops containsObject:current_lt]) {
				current_lt = [NSValue valueWithPoint:
								[[self window] cascadeTopLeftFromPoint:[current_lt pointValue]]];
			} else {
				break;
			}
		}
		[[self window] setFrameTopLeftPoint:[current_lt pointValue]];
	}
	
}

#pragma mark delegate of NSWindow
- (void)windowWillClose:(NSNotification *)aNotification
{
	[fileTableController disposeDocuments];
	/*
	[dmgOptionsViewController saveSettings];
	if (isFirstWindow) {
		if ([[[NSDocumentController sharedDocumentController] documents] count] == 0) {
			//[NSApp terminate:self];
			[NSApp performSelectorOnMainThread:@selector(terminate:) withObject:self waitUntilDone:NO];
		}
	}*/
	[super windowWillClose:aNotification];
}

@end
