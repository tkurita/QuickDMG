#import "UtilityFunctions.h"

NSArray *URLsFromPaths(NSArray *filenames)
{
	NSEnumerator *enumerator = [filenames objectEnumerator];
	NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[filenames count]];
	NSString *aFilename;
	while (aFilename = [enumerator nextObject]) {
		[urls addObject:[NSURL fileURLWithPath:aFilename]];
	}
	return urls;
}
