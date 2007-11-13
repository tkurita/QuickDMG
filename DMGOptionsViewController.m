#import "DMGOptionsViewController.h"
#import "LocalizedStringTransformer.h"

@implementation DMGOptionsViewController
+ (void)initialize
{	
	NSValueTransformer *transformer = [[[LocalizedStringTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"LocalizedStringTransformer"];
}

- (id)initWithNibName:(NSString *)nibName owner:(id)owner
{
	self = [self init];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	internetEnable = [user_defaults boolForKey:@"InternetEnable"];
	isDeleteDSStore = [user_defaults boolForKey:@"deleteDSStore"];
	selectedFormatIndexes = [[NSUnarchiver unarchiveObjectWithData:
						[user_defaults dataForKey:@"SelectedFormatIndexes"]] retain];
	compressionLevel = [user_defaults integerForKey:@"compressionLevel"];
	[NSBundle loadNibNamed:nibName owner:self];
	return self;
}

- (void) dealloc {
	[selectedFormatIndexes release];
	[super dealloc];
}


- (void)awakeFromNib
{
	/*
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	internetEnable = [user_defaults boolForKey:@"InternetEnable"];
	isDeleteDSStore = [user_defaults boolForKey:@"deleteDSStore"];
	*/
}

#pragma mark instance methods
- (void)saveSettings
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setBool:internetEnable forKey:@"InternetEnable"];
	[user_defaults setBool:isDeleteDSStore forKey:@"deleteDSStore"];
	[user_defaults setObject:[NSArchiver archivedDataWithRootObject:selectedFormatIndexes]
					forKey:@"SelectedFormatIndexes"];
	[user_defaults setInteger:compressionLevel forKey:@"compressionLevel"];
}

#pragma mark DMGOptions Protocol
- (NSString *)dmgFormat
{
	NSArray *an_array = [dmgFormatController selectedObjects];
	return [[an_array lastObject] objectForKey:@"formatID"];
}

- (NSString *)dmgSuffix
{
	NSArray *an_array = [dmgFormatController selectedObjects];
	return [[an_array lastObject] objectForKey:@"extension"];
}

- (BOOL)internetEnable
{
	return internetEnable;
}

- (BOOL)isDeleteDSStore
{
	return isDeleteDSStore;
}

- (int)compressionLevel
{
	return compressionLevel;
}

#pragma mark accessors
- (NSTableView *)tableView
{
	return dmgFormatTable;
}

- (NSView *)view
{
	return dmgOptionsView;
}

- (void)setInternetEnable:(BOOL)aFlag
{
	internetEnable = aFlag;
}

- (void)setDeleteDSStore:(BOOL)aFlag
{
	isDeleteDSStore = aFlag;
}

- (NSIndexSet *)selectedFormatIndexes
{
	return selectedFormatIndexes;
}

- (void)setSelectedFormatIndexes:(NSIndexSet *)indexSet
{
	[indexSet retain];
	[selectedFormatIndexes release];
	selectedFormatIndexes = indexSet;
}

- (void)setCompressionLevel:(int)aValue
{
	compressionLevel = aValue;
}

- (id)dmgFormatController
{
	return dmgFormatController;
}

#pragma mark delegate for TableView
/*
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSDictionary *dmgFormatDict = [self dmgFormatDict];
	[targetPathView setStringValue:targetPath];
	[zlibLevelButton setEnabled:[[dmgFormatDict objectForKey:@"formatID"] isEqualToString:@"UDZO"]];
}
*/

@end
