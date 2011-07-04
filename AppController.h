/* AppController */

@interface AppController : NSObject
{
    IBOutlet id documentController;
}

- (IBAction)makeDonation:(id)sender;
- (IBAction)newDiskImage:(id)sender;
- (void)openFinderSelection;

@end
