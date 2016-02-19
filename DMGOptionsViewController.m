#import "DMGOptionsViewController.h"
#import "LocalizedStringTransformer.h"

#define useLog 0

@implementation DMGOptionsViewController
+ (void)initialize
{	
	NSValueTransformer *transformer = [[[LocalizedStringTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"LocalizedStringTransformer"];
}

- (id)initWithNibName:(NSString *)nibName owner:(id)owner
{
#if useLog
	NSLog(@"start [DMGOptionsViewController initWithNibName:owner:]");
#endif	
	self = [self init];
	[NSBundle loadNibNamed:nibName owner:self];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[self setInternetEnable:[user_defaults boolForKey:@"InternetEnable"]];
	[self setDeleteDSStore:[user_defaults boolForKey:@"deleteDSStore"]];
	self.selectedFormatIndexes = [NSIndexSet indexSetWithIndex:
									[user_defaults integerForKey:@"formatIndex"]];
	[self setCompressionLevel:[user_defaults integerForKey:@"compressionLevel"]];
	[self setPutawaySources:[user_defaults boolForKey:@"putawaySources"]];
	return self;
}

- (void) dealloc {
	[_selectedFormatIndexes release];
	[super dealloc];
}

#pragma mark instance methods
- (void)saveSettings
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setBool:internetEnable forKey:@"InternetEnable"];
	[user_defaults setBool:isDeleteDSStore forKey:@"deleteDSStore"];
	[user_defaults setObject:@([_selectedFormatIndexes firstIndex])
					forKey:@"formatIndex"];
	[user_defaults setInteger:compressionLevel forKey:@"compressionLevel"];
	[user_defaults setBool:putawaySources forKey:@"putawaySources"];
}

#pragma mark DMGOptions Protocol
- (NSString *)dmgFormat
{
	NSArray *an_array = [dmgFormatController selectedObjects];
	return [an_array lastObject][@"formatID"];
}

- (NSString *)dmgSuffix
{
	NSArray *an_array = [dmgFormatController selectedObjects];
	return [an_array lastObject][@"extension"];
}

- (NSString *)filesystem
{
	NSArray *an_array = [dmgFormatController selectedObjects];
	return [an_array lastObject][@"filesystem"];
}

- (BOOL)internetEnable
{
	return [[[dmgFormatController selectedObjects] lastObject][@"canInternetEnable"] boolValue]
			&& internetEnable;
}

- (BOOL)needConversion
{
	NSArray *array = [dmgFormatController selectedObjects];
	return [[array lastObject][@"needConversion"] boolValue];
}

- (NSString *)command
{
	NSArray *array = [dmgFormatController selectedObjects];
	return [array lastObject][@"command"];
}

- (BOOL)isDeleteDSStore
{
	return isDeleteDSStore;
}

- (int)compressionLevel
{
	return compressionLevel;
}

- (BOOL)putawaySources
{
	return putawaySources;
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

- (void)setCompressionLevel:(int)aValue
{
	compressionLevel = aValue;
}

- (id)dmgFormatController
{
	return dmgFormatController;
}

-(void)setPutawaySources:(BOOL)flag
{
	putawaySources = flag;
}


@end
