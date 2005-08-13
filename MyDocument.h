#import <Cocoa/Cocoa.h>
#import "MyWindowController.h"
#import "DiskImageMaker.h"

@interface MyDocument : NSDocument
{
	MyWindowController *targetWindowController;
	DiskImageMaker *dmgMaker;
	BOOL isFirstDocument;
}

- (void)makeDmg;
- (void)dmgDidTerminate:(NSNotification *)notification;
- (void)setIsFirstDocument;
- (BOOL)isFirstDocument;
- (NSString *)updateTargetPathByFormatDict:(NSDictionary *)dictionary;
- (void)setDmgMaker:(DiskImageMaker *)theObject;
- (DiskImageMaker *)dmgMaker;

//for setting properties of DiskImageMaker
- (void)setFormatDict:(NSDictionary *)dictionary;

@end
