/* FileTableController */

#import <Cocoa/Cocoa.h>

@interface FileTableController : NSObject
{
    IBOutlet id fileListController;
    IBOutlet id fileTableView;
}

- (void)addFileURLs:(NSArray *)files completionHandler:(void (^)())completionHandler;
- (void)addFileURL:(NSURL *)aFileURL completionHandler:(void (^)())completionHandler;
- (void)disposeDocuments;

@end
