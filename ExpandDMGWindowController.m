#import "ExpandDMGWindowController.h"
#import "PathExtra.h"
#import "StringExtra.h"

@implementation ExpandDMGWindowController

- (void)dealloc
{
	[_dmgHandler release];
	[_dmgPath release];
	[_dmgEnumerator release];
	[super dealloc];
}

- (BOOL)processNextItem
{
	if (! _dmgEnumerator) return NO;
	if (! (self.dmgPath = [_dmgEnumerator nextObject])) return NO;
	
	[self.window setRepresentedFilename:_dmgPath];
	NSString *title = [NSString stringWithLocalizedFormat:@"Expanding %@", 
					   [_dmgPath lastPathComponent]];
	[self.window setTitle:title];
	[self.dmgHandler attachDiskImage:_dmgPath];
	return YES;
}

- (void)processFiles:(NSArray *)array
{
	self.dmgHandler = [DMGHandler dmgHandlerWithDelegate:self];
	self.dmgEnumerator = [array objectEnumerator];
	[self showWindow:self];
	[progressIndicator startAnimation:self];
	if (! [self processNextItem]) {
		[self close];
	}
}

- (void)processFile:(NSString *)path
{
	self.dmgPath = path;
	DMGHandler *h = [DMGHandler dmgHandlerWithDelegate:self];
	[self showWindow:self];
	//[self.window setTitleWithRepresentedFilename:path];
	[self.window setRepresentedFilename:path];
	NSString *title = [NSString stringWithLocalizedFormat:@"Expanding %@", 
						[path lastPathComponent]];
	[self.window setTitle:title];
	[progressIndicator startAnimation:self];
	[h attachDiskImage:path];
	self.dmgHandler = h;
}

- (void)diskImageDetached:(DMGHandler *)sender
{
	if (sender.terminationStatus != 0) {
		_dmgHandler.statusMessage = [NSString stringWithLocalizedFormat:@"Failed detaching with error : %@",
															sender.terminationMessage];
		[progressIndicator stopAnimation:self];
		return;
	}
	
	if (![self processNextItem]) {
		[progressIndicator stopAnimation:self];
		[self close];
	}
}

- (void)dittoFinished:(DMGHandler *)sender
{
	if (sender.terminationStatus != 0) {
		_dmgHandler.statusMessage = [NSString stringWithLocalizedFormat:@"Failed copy with error : %@",
															sender.terminationMessage];
		[sender detachNow];
		[progressIndicator stopAnimation:self];
		return;
	}
	[sender detachDiskImage:nil];
}

- (void)diskImageAttached:(DMGHandler *)sender
{
	if (sender.terminationStatus != 0) {
		_dmgHandler.statusMessage = [NSString stringWithLocalizedFormat:@"Failed attaching with error : %@",
										sender.terminationMessage];
		[progressIndicator stopAnimation:self];
		return;
	}
	NSString *src = sender.mountPoint;
	NSString *dest_dir = [_dmgPath stringByDeletingLastPathComponent];
	NSString *uname = [[src lastPathComponent] uniqueNameAtLocation:dest_dir];
	NSString *dest_path = [dest_dir stringByAppendingPathComponent:uname];
	[sender dittoPath:sender.mountPoint toPath:dest_path];
}

- (IBAction)cancelTask:(id)sender
{
	[_dmgHandler abortTask];
	[progressIndicator stopAnimation:self];
	[self close];
}

- (void)windowWillClose:(NSNotification*)notification {
	[self autorelease];
}

@end
