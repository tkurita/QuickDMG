#import "MyDocumentController.h"

@implementation MyDocumentController

- (id) init
{
	[super init];
	isFirstDocument = NO;
	return self;
}

- (void)removeDocument:(id)document
{
	if ([document isFirstDocument]) {
		if ([[self documents] count] == 1) {;
			[[NSApplication sharedApplication] terminate:self];
			return;
		}
	}
	
	[super removeDocument:document];
}

- (void)setIsFirstDocument
{
	self->isFirstDocument = YES;
}

- (void)addDocument:(id)document
{
	if (isFirstDocument) {
		[document setIsFirstDocument];
		self->isFirstDocument = NO;
	}
	[super addDocument:document];
}

- (int)runModalOpenPanel:(NSOpenPanel*)openPanel forTypes:(NSArray*)extensions
{
	[openPanel setCanChooseDirectories:YES];
    
    return [super runModalOpenPanel:openPanel forTypes:extensions];
}

@end
