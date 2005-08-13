#import "DmgDataSource.h"

@implementation DmgDataSource

- (NSString *)formatIDFromIndex:(int) theIndex
{
	NSArray *formatIDList = [dataDict objectForKey:@"formatIDs"];
	return [formatIDList objectAtIndex:theIndex];
}

- (NSNumber *)canInternetEnableFromIndex:(int)theIndex
{
	NSArray *canInternetEnableList = [dataDict objectForKey:@"canInternetEnable"];
	return [canInternetEnableList objectAtIndex:theIndex];
}

- (NSString *)formatSuffixFromIndex:(int)theIndex
{
	NSArray *formatSuffixList = [dataDict objectForKey:@"extensions"];
	return [formatSuffixList objectAtIndex:theIndex];
}

- (void)loadDmgFormatsPlist
{
	NSBundle *thisBundle = [NSBundle mainBundle];
	NSString *dmgPlistPath = [thisBundle pathForResource:@"DmgFormats" ofType:@"plist"];
	dataDict = [[NSDictionary dictionaryWithContentsOfFile:dmgPlistPath] retain];
	//NSLog([dataDict description]);
}

- (id)init
{
    self = [super init];
    if (self) {
		[self loadDmgFormatsPlist];
    }
    
    return self;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[dataDict objectForKey:@"descriptions"] count];
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
    id	identifier;
    NSArray * columnArray;

    identifier = [tableColumn identifier];
	if ([identifier isEqualToString:@"descriptions"]) {
		if (columnArray = [dataDict objectForKey:identifier]) {
			return NSLocalizedString([columnArray objectAtIndex:row],"");
		}
		else {
			return nil;
		}		
		
	}
	else {
		if (columnArray = [dataDict objectForKey:identifier]) {
			return [columnArray objectAtIndex:row];
		}
		else {
			return nil;
		}
	}
}

@end
