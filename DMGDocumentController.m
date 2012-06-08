#import "DMGDocumentController.h"
#import "DMGDocumentProtocol.h"
#import "MDMGWindowController.h"

#define useLog 0

@implementation DMGDocumentController

- (NSArray *)URLsFromRunningOpenPanel
{
#if useLog
	NSLog(@"start URLsFromRunningOpenPanel");
#endif
	NSArray *urls = [super URLsFromRunningOpenPanel];
	if (! urls) return urls;
	
	if ([urls count] > 1) {
		MDMGWindowController *mdmg_window = [[MDMGWindowController alloc] 
												initWithWindowNibName:@"MDMGWindow"];
		[mdmg_window showWindow:self withFiles:urls];
		urls = nil;

	}
	
	return urls;
}

- (void)removeDocument:(id)document
{
	if (![document isMultiSourceMember]) {
		[super removeDocument:document];
	}
	//[super removeDocument:document];
}

- (NSInteger)runModalOpenPanel:(NSOpenPanel*)openPanel forTypes:(NSArray*)extensions
{
	[openPanel setCanChooseDirectories:YES];
    
    return [super runModalOpenPanel:openPanel forTypes:extensions];
}

@end
