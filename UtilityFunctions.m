#import "UtilityFunctions.h"

NSArray *URLsFromPaths(NSArray *filenames)
{
	NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[filenames count]];
	for (NSString *aFilename in filenames) {
		[urls addObject:[NSURL fileURLWithPath:aFilename]];
	}
	return urls;
}
