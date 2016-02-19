#import <Cocoa/Cocoa.h>
#import "DMGHandler.h"

@interface ExpandDMGWindowController : NSWindowController {
	IBOutlet id progressIndicator;
	IBOutlet id statusLabel;
}

@property(nonatomic, strong) DMGHandler *dmgHandler;
@property(nonatomic, strong) NSString *dmgPath;
@property(nonatomic, strong) NSEnumerator *dmgEnumerator;

- (IBAction)cancelTask:(id)sender;

- (void)processFiles:(NSArray *)array;
- (void)processFile:(NSString *)filename;

@end
