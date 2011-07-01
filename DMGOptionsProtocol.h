@protocol DMGOptions <NSObject>
- (BOOL)internetEnable;
- (BOOL)isDeleteDSStore;
- (int)compressionLevel;
- (NSString *)dmgFormat;
- (NSString *)dmgSuffix;
- (NSString *)filesystem;
- (BOOL)needConversion;
- (NSString *)command;
@end