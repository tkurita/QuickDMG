#import <Cocoa/Cocoa.h>
#import "DMGWindowController.h"
#import "DiskImageMaker.h"
#import "DMGDocumentProtocol.h"

@interface DMGDocument : NSDocument <DMGDocument>
{
	BOOL isMultiSourceMember;
}

@property (nonatomic, strong) NSImage *iconImg;
@property (nonatomic, strong) NSDictionary *fileInfo;

- (NSString *)itemName;

@end
