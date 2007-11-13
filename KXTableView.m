#import "KXTableView.h"

#define useLog 0

@implementation KXTableView

- (void)delete:sender
{
	[NSApp sendAction:deleteSelector to:nil from:self];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	if (aSelector == @selector(delete:)) {
		if (deleteSelector)
				return YES;
	}
	
	//return [[self class] instancesRespondToSelector:aSelector];
	return [super respondsToSelector:aSelector];
}


- (void)setDeleteAction:(SEL)aSelector
{
	deleteSelector = aSelector;
}	

@end
