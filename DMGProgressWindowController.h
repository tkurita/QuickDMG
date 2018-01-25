/* DMGProgressWindowController */

#import <Cocoa/Cocoa.h>
#import "DMGWindowControllerProtocol.h"

@interface DMGProgressWindowController : NSObject
{
    IBOutlet id progressBar;
    IBOutlet id progressText;
	IBOutlet id window;
}

- (id)initWithNibName:(NSString *)nibName;
- (IBAction)cancelAction:(id)sender;
- (void) beginSheetWith:(NSWindowController<DMGWindowController> *)aController;
- (void)showStatusMessage:(NSNotification *)notification;

@property(nonatomic, unsafe_unretained) NSWindowController<DMGWindowController> *owner;

@end
