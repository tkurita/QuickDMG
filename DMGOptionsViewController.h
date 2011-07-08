/* DMGOptionsViewController */
#import "DMGOptionsProtocol.h"

@interface DMGOptionsViewController : NSObject <DMGOptions>
{
    IBOutlet id dmgFormatController;
    IBOutlet id dmgFormatTable;
	IBOutlet id dmgOptionsView;
    IBOutlet id internetEnableButton;
    IBOutlet id zlibLevelButton;
	
	BOOL internetEnable;
	BOOL isDeleteDSStore;
	NSIndexSet *selectedFormatIndexes;
	int compressionLevel;
	BOOL putawaySources;
}

- (id)initWithNibName:(NSString *)nibName owner:(id)owner;
- (void)saveSettings;

#pragma mark accessors
- (NSIndexSet *)selectedFormatIndexes;
- (void)setSelectedFormatIndexes:(NSIndexSet *)indexSet;
- (id)dmgFormatController;
- (NSTableView *)tableView;
- (void)setCompressionLevel:(int)aValue;
- (void)setDeleteDSStore:(BOOL)aFlag;
- (void)setInternetEnable:(BOOL)aFlag;
- (void)setPutawaySources:(BOOL)flag;

@end
