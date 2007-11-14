#import <Cocoa/Cocoa.h>
#import "DMGWindowController.h"
#import "DiskImageMaker.h"
//#import "DMGProgressWindowController.h"

@interface MDMGWindowController : DMGWindowController
{
    IBOutlet id fileListController;
    IBOutlet id fileTable;
	IBOutlet id fileTableController;
    IBOutlet id splitSubview;
}

#pragma mark actions
- (IBAction)deleteTabelSelection:(id)sender;
- (IBAction)addToFileTable:(id)sender;

- (void)setupFileTable:(NSArray *)files;

@end
