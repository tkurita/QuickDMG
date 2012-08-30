#import <Cocoa/Cocoa.h>
#import "DMGHandler.h"

@interface ExpandDMGWindowController : NSWindowController {
	IBOutlet id progressIndicator;
	IBOutlet id statusLabel;
	DMGHandler *dmgHandler;
	NSString *dmgPath;
}
@property(retain) DMGHandler *dmgHandler; 
@property(retain) NSString *dmgPath;

- (IBAction)cancelTask:(id)sender;

- (void)processFile:(NSString *)filename;

@end
