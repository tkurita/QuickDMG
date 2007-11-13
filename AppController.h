/* AppController */

#import <Cocoa/Cocoa.h>
#import "DMGDocument.h"

@interface AppController : NSObject
{
    IBOutlet id documentController;
	
	BOOL isFirstOpen;
}

- (IBAction)makeDonation:(id)sender;

@end
