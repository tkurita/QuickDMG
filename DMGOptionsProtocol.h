@protocol DMGOptions <NSObject>
- (BOOL)internetEnable;
- (BOOL)isDeleteDSStore;
- (int)compressionLevel;
- (NSString *)dmgFormat;
- (NSString *)dmgSuffix;
@end