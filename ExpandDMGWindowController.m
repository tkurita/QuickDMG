#import "ExpandDMGWindowController.h"
#import "PathExtra.h"

@implementation ExpandDMGWindowController

@synthesize dmgHandler;
@synthesize dmgPath;

- (void)dealloc
{
	[dmgHandler release];
	[dmgPath release];
	[super dealloc];
}

- (void)processFile:(NSString *)path
{
	self.dmgPath = path;
	DMGHandler *h = [DMGHandler dmgHandlerWithDelegate:self];
	[h attachDiskImage:path];
	self.dmgHandler = h;
}

- (void)diskImageDetached:(DMGHandler *)sender
{
	
}

- (void)dittoFinished:(DMGHandler *)sender
{
	if (sender.terminationStatus != 0) {
		NSLog(@"Failed to ditto");
	}
	[sender detachDiskImage:nil];
}

- (void)diskImageAttached:(DMGHandler *)sender
{
	if (sender.terminationStatus != 0) {
		return;
	}
	NSString *src = sender.mountPoint;
	NSString *dest_dir = [dmgPath stringByDeletingLastPathComponent];
	NSString *uname = [[src lastPathComponent] uniqueNameAtLocation:dest_dir];
	NSString *dest_path = [dest_dir stringByAppendingPathComponent:uname];
	[sender dittoPath:sender.mountPoint toPath:dest_path];
}

@end
