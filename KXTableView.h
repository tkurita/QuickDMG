/* KXTableView */

#import <Cocoa/Cocoa.h>

@interface KXTableView : NSTableView
{
	SEL deleteSelector;
}

- (void)setDeleteAction:(SEL)selector;
@end
