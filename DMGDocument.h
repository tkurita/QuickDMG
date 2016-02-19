#import <Cocoa/Cocoa.h>
#import "DMGWindowController.h"
#import "DiskImageMaker.h"
#import "DMGDocumentProtocol.h"

@interface DMGDocument : NSDocument <DMGDocument>
{
	BOOL isMultiSourceMember;
}

@property (nonatomic, retain) NSImage *iconImg;
@property (nonatomic, retain) NSDictionary *fileInfo;

- (NSString *)itemName;

@end
