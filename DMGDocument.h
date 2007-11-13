#import <Cocoa/Cocoa.h>
#import "DMGWindowController.h"
#import "DiskImageMaker.h"
#import "DMGDocumentProtocol.h"

@interface DMGDocument : NSDocument <DMGDocument>
{
	BOOL isMultiSourceMember;
	//BOOL isFirstDocument;
	
	NSImage *iconImg;
	NSDictionary *fileInfo;
}

//- (void)setIsFirstDocument;
//- (BOOL)isFirstDocument;
- (NSString *)itemName;

@end
