@protocol DMGWindowController <NSObject>

- (void)showAlertMessage:(NSString *)messageText 
		withInformativeText:(NSString *)informativeText;

- (id)dmgMaker;

@end