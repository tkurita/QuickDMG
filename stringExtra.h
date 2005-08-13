#import <Cocoa/Cocoa.h>


@interface NSString (stringExtra) 

- (BOOL)startWith:(NSString *)beginningText;
- (BOOL)contain:(NSString *)containedText;
- (BOOL)endsWith:(NSString *)enddingText;

- (NSMutableArray *)splitWithCharacterSet:(NSCharacterSet *)delimiters;

@end
