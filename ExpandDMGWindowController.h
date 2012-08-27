#import <Cocoa/Cocoa.h>
#import "DMGHandler.h"

@interface ExpandDMGWindowController : NSWindowController {
	DMGHandler *dmgHandler;
	NSString *dmgPath;
}
@property(retain) DMGHandler *dmgHandler; 
@property(retain) NSString *dmgPath;

- (void)processFile:(NSString *)filename;

@end
