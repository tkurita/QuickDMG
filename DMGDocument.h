#import <Cocoa/Cocoa.h>
#import "DMGWindowController.h"
#import "DiskImageMaker.h"
#import "DMGDocumentProtocol.h"

@interface DMGDocument : NSDocument <DMGDocument>
{
	BOOL isMultiSourceMember;
	
	NSImage *iconImg;
	NSDictionary *fileInfo;
}

- (NSString *)itemName;

@end
