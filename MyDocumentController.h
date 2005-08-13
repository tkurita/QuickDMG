/* MyDocumentController */

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"

@interface MyDocumentController : NSDocumentController
{
	BOOL isFirstDocument;
}

- (void)setIsFirstDocument;

@end
