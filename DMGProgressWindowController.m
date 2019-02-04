#import "DMGProgressWindowController.h"
#import "DiskImageMaker.h"
#import "KXTableView.h"

@implementation DMGProgressWindowController

- (id)initWithNibName:(NSString *)nibName
{
	self = [self init];
    NSArray *top_levels;
    [[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:&top_levels];
	return self;
}

- (IBAction)cancelAction:(id)sender
{
	[[NSApplication sharedApplication] endSheet: [sender window] returnCode:DIALOG_ABORT];
	[progressBar stopAnimation:self];
	[[_owner dmgMaker] aboartTask];
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

- (void) beginSheetWith:(NSWindowController<DMGWindowController> *)aController
{
	self.owner = aController;
	[[NSApplication sharedApplication] beginSheet:window
							modalForWindow:[aController window] 
							modalDelegate:self 
							didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
							contextInfo:nil];
	[progressBar startAnimation:self];
}

- (void)showStatusMessage:(NSNotification *)notification
{
	NSString* statusMessage = [notification userInfo][@"statusMessage"];
    NSNumber* max_value = [notification userInfo][@"maxValue"];
    NSNumber* increment = [notification userInfo][@"increment"];
    if (max_value) {
        progressBar.maxValue = max_value.doubleValue;
        progressBar.doubleValue = 0;
    }
    if (increment) {
        [progressBar incrementBy:increment.doubleValue];
    }
    if (statusMessage) {
        [progressText setStringValue: statusMessage];
    }
}

@end
