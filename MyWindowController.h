/* MyWindowController */

#import <Cocoa/Cocoa.h>

@interface MyWindowController : NSWindowController
{
    IBOutlet id dmgFormatTable;
    IBOutlet id internetEnableButton;
    IBOutlet id progressBar;
    IBOutlet id progressSheet;
    IBOutlet id progressText;
    IBOutlet id sourcePathView;
    IBOutlet id targetPathView;
	IBOutlet id zlibLevelButton;
	IBOutlet id deleteDSStoreButton;
}

- (IBAction)abortAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)chooseTargetPath:(id)sender;
- (IBAction)internetEnableButton:(id)sender; //not required
- (IBAction)okAction:(id)sender;
- (IBAction)zlibLevelButton:(id)sender; //not required

- (void)setSourcePath:(NSString *)string;
- (void)setTargetPath:(NSString *)string;
- (void)showStatusMessage:(NSNotification *) notification;
- (void)setTargetFormatFromIndex:(int)formatIndex;
- (NSDictionary *)dmgFormatDict;
- (void)showAlertMessage:(NSString *)theMessageText withInformativeText:(NSString *)theInformativeText;

@end
