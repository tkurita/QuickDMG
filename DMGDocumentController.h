#import <Cocoa/Cocoa.h>
#import "DMGDocument.h"

@interface DMGDocumentController : NSDocumentController
{
	BOOL isFirstDocument;
}

- (void)setIsFirstDocument:(BOOL)aFlag;

@end
