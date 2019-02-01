#import "DMGDocumentController.h"
#import "DMGDocumentProtocol.h"
#import "MDMGWindowController.h"

#define useLog DEBUG

@implementation DMGDocumentController

- (NSArray *)URLsFromRunningOpenPanel //not callled by openDocument:, may deletable.
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

- (void)beginOpenPanelWithCompletionHandler:(void (^)(NSArray<NSURL *> *))completionHandler
{
    [super beginOpenPanelWithCompletionHandler:^(NSArray<NSURL *> *urls) {
        if (urls && (urls.count > 1)) {
            MDMGWindowController *mdmg_window = [[MDMGWindowController alloc]
                                                 initWithWindowNibName:@"MDMGWindow"];
            [mdmg_window showWindow:self withFiles:urls];
            urls = nil;
        }
        completionHandler(urls);
    }];
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
#if useLog
    NSLog(@"start runModalOpenPanel");
#endif
	[openPanel setCanChooseDirectories:YES];
    
    return [super runModalOpenPanel:openPanel forTypes:extensions];
}

@end
