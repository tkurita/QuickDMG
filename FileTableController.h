/* FileTableController */

#import <Cocoa/Cocoa.h>

@interface FileTableController : NSObject
{
    IBOutlet id fileListController;
    IBOutlet id fileTableView;
}

- (void)addFileURLs:(NSArray *)files;
- (void)addFileURL:(NSURL *)aFileURL;
- (void)disposeDocuments;

@end
