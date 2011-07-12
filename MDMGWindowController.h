#import "DMGWindowController.h"
#import "DiskImageMaker.h"
//#import "DMGProgressWindowController.h"

@interface MDMGWindowController : DMGWindowController
{
    IBOutlet id fileListController;
    IBOutlet id fileTable;
	IBOutlet id fileTableController;
    IBOutlet id splitSubview;
	IBOutlet id splitView;
	NSArray *initialItems;
	CGFloat fileTableMinHeight;
}

#pragma mark actions
- (IBAction)deleteTabelSelection:(id)sender;
- (IBAction)addToFileTable:(id)sender;

- (void)setInitialItems:(NSArray *)files;
- (void)showWindow:(id)sender withFiles:(NSArray *)files;
@end
