/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet id documentController;
	BOOL isFirstOpen;
}

- (IBAction)makeDonation:(id)sender;
- (IBAction)newDiskImage:(id)sender;

- (BOOL)isFirstOpen;
- (void)setFirstOpen:(BOOL)aFlag;

@end
