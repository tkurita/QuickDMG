/* AppController */

@interface AppController : NSObject
{
    IBOutlet id documentController;
    IBOutlet NSMenuItem *checkForUpdatesMenuItem;
    IBOutlet NSMenuItem *donationMenuItem;
}

@property (nonatomic ,strong) id mdmgWindow;
- (IBAction)makeDonation:(id)sender;
- (IBAction)newDiskImage:(id)sender;
- (void)openFinderSelection;

#if !SANDBOX
@property (nonatomic ,strong) id updater;
#endif

@end
