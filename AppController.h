/* AppController */

@interface AppController : NSObject
{
    IBOutlet id documentController;
}
@property (nonatomic ,strong) id mdmgWindow;
- (IBAction)makeDonation:(id)sender;
- (IBAction)newDiskImage:(id)sender;
- (void)openFinderSelection;

@end
