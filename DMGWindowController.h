#import <Cocoa/Cocoa.h>
#import "DMGWindowControllerProtocol.h"
#import "DMGProgressWindowController.h"
#import "DiskImageMaker.h"

@interface DMGWindowController : NSWindowController <DMGWindowController>
{
    IBOutlet id sourcePathView;
    IBOutlet id targetPathView;
	IBOutlet id dmgOptionsBox;
	IBOutlet id okButton;
    
    BOOL okButtonPushed;
}

@property(nonatomic ,strong) id dmgOptionsViewController;
@property(nonatomic ,strong) DMGProgressWindowController *progressWindowController;
@property(nonatomic ,strong) DiskImageMaker *dmgMaker;

- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;

- (void)makeDiskImage;

#pragma mark common method
- (void)setupProgressWindow;
- (void)setupDMGOptionsView;

//DMGWindowControllery Only
- (void)setTargetPath:(NSString *)string;
- (IBAction)chooseTargetPath:(id)sender;

@end
