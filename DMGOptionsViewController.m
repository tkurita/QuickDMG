#import "DMGOptionsViewController.h"
#import "LocalizedStringTransformer.h"

#define useLog 0

#ifndef SANDBOX
#define SANDBOX 0
#endif

@implementation DMGOptionsViewController
+ (void)initialize
{	
	NSValueTransformer *transformer = [[LocalizedStringTransformer alloc] init];
	[NSValueTransformer setValueTransformer:transformer forName:@"LocalizedStringTransformer"];
}

- (id)initWithNibName:(NSString *)nibName owner:(id)owner
{
#if useLog
	NSLog(@"start [DMGOptionsViewController initWithNibName:owner:]");
#endif	
	self = [self init];
    NSArray *top_levels;
    [[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:&top_levels];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	
	self.isDeleteDSStore = [user_defaults boolForKey:@"deleteDSStore"];
	self.selectedFormatIndexes = [NSIndexSet indexSetWithIndex:
									[user_defaults integerForKey:@"formatIndex"]];
	self.compressionLevel = [user_defaults integerForKey:@"compressionLevel"];
    
#if SANDBOX
    [internetEnableButton removeFromSuperview];
    [deleteDSStoreButton removeFromSuperview];
#else
	[self setInternetEnable:[user_defaults boolForKey:@"InternetEnable"]];
    [self setPutawaySources:[user_defaults boolForKey:@"putawaySources"]];
#endif
	return self;
}


#pragma mark instance methods
- (void)saveSettings
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setBool:_internetEnable forKey:@"InternetEnable"];
	[user_defaults setBool:_isDeleteDSStore forKey:@"deleteDSStore"];
	[user_defaults setObject:@([_selectedFormatIndexes firstIndex])
					forKey:@"formatIndex"];
	[user_defaults setInteger:_compressionLevel forKey:@"compressionLevel"];
	[user_defaults setBool:_putawaySources forKey:@"putawaySources"];
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
			&& _internetEnable;
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

#pragma mark accessors
- (NSTableView *)tableView
{
	return dmgFormatTable;
}

- (NSView *)view
{
	return dmgOptionsView;
}

- (id)dmgFormatController
{
	return dmgFormatController;
}



@end
