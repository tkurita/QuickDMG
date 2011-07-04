#import "stringExtra.h"

@implementation NSString (stringExtra)
-(BOOL) startWith:(NSString *)beginningText
{
	NSRange begginningRange = NSMakeRange(0,[beginningText length]);
	if ([self compare:beginningText options:0 range:begginningRange] == NSOrderedSame) {
		return YES;
	}
	else{
		return NO;
	}
}

-(BOOL) contain:(NSString *)containedText
{
	NSRange theRange = [self rangeOfString:containedText];
	return (theRange.length != 0);
}

-(BOOL) endsWith:(NSString *)enddingText
{
	NSRange endingRange = NSMakeRange([self length]-[enddingText length],[enddingText length]);
	return ([self compare:enddingText options:0 range:endingRange] == NSOrderedSame);
}

-(NSMutableArray *) splitWithCharacterSet:(NSCharacterSet *)delimiters
{
	NSMutableArray * wordArray = [NSMutableArray array];
	NSScanner *scanner = [NSScanner scannerWithString:self];
	NSString *scannedText;
    while(![scanner isAtEnd]) {
        if([scanner scanUpToCharactersFromSet:delimiters intoString:&scannedText]) {
			[wordArray addObject:scannedText];
        }
        [scanner scanCharactersFromSet:delimiters intoString:nil];
    }
	return wordArray;
}

@end
