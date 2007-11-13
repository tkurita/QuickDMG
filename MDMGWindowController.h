/* MDMGWindowController */

#import <Cocoa/Cocoa.h>
#import "DMGWindowController.h"
#import "DiskImageMaker.h"
//#import "DMGProgressWindowController.h"

//@interface MDMGWindowController : NSWindowController <DMGWindowController>
@interface MDMGWindowController : DMGWindowController
{
    //IBOutlet id dmgOptionsBox;
    IBOutlet id fileListController;
    IBOutlet id fileTable;
	IBOutlet id fileTableController;
    //IBOutlet id okButton;
    IBOutlet id splitSubview;
	
	//id dmgOptionsViewController;
	//NSMutableArray *documentArray;
	//DMGProgressWindowController *progressWindowController;
	//DiskImageMaker *dmgMaker;
}

#pragma mark actions
//- (IBAction)cancelAction:(id)sender;
//- (IBAction)okAction:(id)sender;

- (void)setupFileTable:(NSArray *)files;
@end
