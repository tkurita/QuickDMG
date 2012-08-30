#import <Cocoa/Cocoa.h>
#import "DMGHandler.h"

@interface ExpandDMGWindowController : NSWindowController {
	IBOutlet id progressIndicator;
	IBOutlet id statusLabel;
	DMGHandler *dmgHandler;
	NSString *dmgPath;
	NSEnumerator *dmgEnumerator;
}
@property(retain) DMGHandler *dmgHandler; 
@property(retain) NSString *dmgPath;
@property(retain) NSEnumerator *dmgEnumerator;

- (IBAction)cancelTask:(id)sender;

- (void)processFiles:(NSArray *)array;
- (void)processFile:(NSString *)filename;

@end
