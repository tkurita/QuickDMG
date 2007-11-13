@protocol DMGDocument
- (unsigned long long)fileSize;
- (BOOL)isFolder;
- (BOOL)isPackage;
- (BOOL)isMultiSourceMember;
- (void)setIsMultiSourceMember:(BOOL)aBool;
- (void)dispose:(id)sender;

@end