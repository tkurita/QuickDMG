/* DMGOptionsViewController */
#import "DMGOptionsProtocol.h"

@interface DMGOptionsViewController : NSObject <DMGOptions>
{
    IBOutlet id dmgFormatController;
    IBOutlet id dmgFormatTable;
	IBOutlet id dmgOptionsView;
    IBOutlet id internetEnableButton;
    IBOutlet id zlibLevelButton;
}

- (id)initWithNibName:(NSString *)nibName owner:(id)owner;
- (void)saveSettings;

#pragma mark accessors
- (NSIndexSet *)selectedFormatIndexes;
- (void)setSelectedFormatIndexes:(NSIndexSet *)indexSet;
- (id)dmgFormatController;
- (NSTableView *)tableView;

@property (nonatomic, strong) NSIndexSet *selectedFormatIndexes;
@property (nonatomic) NSInteger compressionLevel;
@property (nonatomic) BOOL isDeleteDSStore;
@property (nonatomic) BOOL internetEnable;
@property (nonatomic) BOOL putawaySources;

@end
