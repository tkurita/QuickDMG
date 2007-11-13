/* DMGProgressWindowController */

#import <Cocoa/Cocoa.h>
#import "DMGWindowControllerProtocol.h"

@interface DMGProgressWindowController : NSObject
{
    IBOutlet id progressBar;
    IBOutlet id progressText;
	IBOutlet id window;
	
	NSWindowController<DMGWindowController> *owner;
}
- (id)initWithNibName:(NSString *)nibName;
- (IBAction)cancelAction:(id)sender;
- (void) beginSheetWith:(NSWindowController *)aController;

@end
