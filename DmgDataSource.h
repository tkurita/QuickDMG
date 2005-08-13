/* DmgDataSource */

#import <Cocoa/Cocoa.h>

@interface DmgDataSource : NSObject
{
	NSMutableDictionary * dataDict;
}

- (void)loadDmgFormatsPlist;

- (NSString *)formatIDFromIndex:(int) theIndex;
- (NSString *)formatSuffixFromIndex:(int)theIndex;
- (NSNumber *)canInternetEnableFromIndex:(int)theIndex;

@end

