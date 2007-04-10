#import "LocalizedStringTransformer.h"


@implementation LocalizedStringTransformer


+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	return NSLocalizedString(value, @"");
}

@end
