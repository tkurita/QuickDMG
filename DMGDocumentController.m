#import "DMGDocumentController.h"
#import "DMGDocumentProtocol.h"
#import "MDMGWindowController.h"

#define useLog 0

@implementation DMGDocumentController

- (id) init
{
	[super init];
	isFirstDocument = NO;
	return self;
}

- (NSArray *)URLsFromRunningOpenPanel
{
	NSLog(@"start URLsFromRunningOpenPanel");
	NSArray *urls = [super URLsFromRunningOpenPanel];
	if (! urls) return urls;
	
	if ([urls count] > 1) {
		MDMGWindowController *mdmg_window = [[MDMGWindowController alloc] 
												initWithWindowNibName:@"MDMGWindow"];
		[mdmg_window loadWindow];
		[mdmg_window setupFileTable:urls];
		[mdmg_window showWindow:self];
		if (isFirstDocument) {
			[mdmg_window setIsFirstWindow];
			isFirstDocument = NO;
		}
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

- (void)setIsFirstDocument:(BOOL)aFlag
{
	isFirstDocument = aFlag;
}

- (void)addDocument:(id)document
{
	if (isFirstDocument) {
		[[[document windowControllers] lastObject] setIsFirstWindow];
		isFirstDocument = NO;
	}
	[super addDocument:document];
#if useLog
	NSLog([NSString stringWithFormat:@"in DMGDocumentController %i", [[NSApp windows] count]]);
#endif
}

- (int)runModalOpenPanel:(NSOpenPanel*)openPanel forTypes:(NSArray*)extensions
{
	[openPanel setCanChooseDirectories:YES];
    
    return [super runModalOpenPanel:openPanel forTypes:extensions];
}

@end
