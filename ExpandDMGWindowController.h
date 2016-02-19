#import <Cocoa/Cocoa.h>
#import "DMGHandler.h"

@interface ExpandDMGWindowController : NSWindowController {
	IBOutlet id progressIndicator;
	IBOutlet id statusLabel;
}

@property(nonatomic, retain) DMGHandler *dmgHandler;
@property(nonatomic, retain) NSString *dmgPath;
@property(nonatomic, retain) NSEnumerator *dmgEnumerator;

- (IBAction)cancelTask:(id)sender;

- (void)processFiles:(NSArray *)array;
- (void)processFile:(NSString *)filename;

@end
