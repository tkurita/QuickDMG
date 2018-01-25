#import "FileTableController.h"
#import "DMGDocument.h"
#import "KXTableView.h"
#import "UtilityFunctions.h"

#define useLog 0

@implementation FileTableController

static NSString *MovedRowsType = @"MOVED_ROWS_TYPE";


- (void)disposeDocuments
{
	for (DMGDocument *a_source in [fileListController arrangedObjects]) {
		[a_source setIsMultiSourceMember:NO];
		[a_source dispose:self];
	}
}

- (void)addFileURL:(NSURL *)aFileURL
{
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:aFileURL
                                                                            display:NO
                                                                  completionHandler:
     ^(NSDocument *document, BOOL documentWasAleadyOpen, NSError *error) {
         if (document) {
             if (![[fileListController arrangedObjects] containsObject:document]) {
                 [fileListController addObject:document];
             }
         }
     }];
     
    /*
    NSDocument *a_doc = [[NSDocumentController sharedDocumentController]
							openDocumentWithContentsOfURL:aFileURL display:NO error:nil];
	if (a_doc) {
		if (![[fileListController arrangedObjects] containsObject:a_doc]) {
			[fileListController addObject:a_doc];
		}
	}
     */
}

- (void)addFileURLs:(NSArray *)files
{
	for (NSURL *file_url in files) {
		[self addFileURL:file_url];
	}
}


- (void)awakeFromNib
{
#if useLog
	NSLog(@"start awakeFromNib in FileTableController");
#endif	
	[fileTableView registerForDraggedTypes: 
		@[MovedRowsType, NSFilenamesPboardType]];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard 
{
#if useLog
	NSLog(@"start writeRowsWithIndexes");
#endif
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pboard declareTypes:@[MovedRowsType] owner:self];
	[pboard setData:data forType:MovedRowsType];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op 
{
#if useLog
    NSLog(@"validate Drop: %i",op);
#endif
	NSDragOperation result = NSDragOperationEvery;
	switch(op) {
		case NSTableViewDropOn:
			result = NSDragOperationNone;
			break;
		case NSTableViewDropAbove:
			result = NSDragOperationEvery;
			break;
		default:
			break;
	}
	
	return result;
}

-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet
										toIndex:(NSInteger)insertIndex
{
	NSUInteger index = [indexSet lastIndex];
	
    NSUInteger	aboveInsertIndexCount = 0;
    id object;
    NSUInteger	removeIndex;
	NSMutableArray *objects = [[fileListController arrangedObjects] mutableCopy];
	NSMutableArray *selectedObj = [NSMutableArray arrayWithCapacity:[indexSet count]];
	while (NSNotFound != index) {
		if (index >= insertIndex) {
			removeIndex = index + aboveInsertIndexCount;
			aboveInsertIndexCount += 1;
		}
		else {
			removeIndex = index;
			insertIndex -= 1;
		}
		
		object = objects[removeIndex];
		[objects removeObjectAtIndex:removeIndex];
		[objects insertObject:object atIndex:insertIndex];
		[selectedObj addObject:object];
		index = [indexSet indexLessThanIndex:index];
    }
	//[fileListController setSortDescriptors:nil];
	[fileListController removeObjects:objects];
	[fileListController addObjects:objects];
	[fileListController setSelectedObjects:selectedObj];
}

- (void)insertFromPathes:(NSArray *)pathes row:(NSInteger)row
{
	NSMutableArray *doc_list = [NSMutableArray arrayWithCapacity:[pathes count]];
	NSArray *current_docs = [fileListController arrangedObjects];
	for (NSURL *aFileURL in URLsFromPaths(pathes)) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[NSDocumentController sharedDocumentController]
         openDocumentWithContentsOfURL:aFileURL
         display:NO
         completionHandler:^(NSDocument *document, BOOL wasAlreayOpen, NSError *error){
             if (![current_docs containsObject:document]) {
                 [doc_list addObject:document];
             }
            dispatch_semaphore_signal(semaphore);
         }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
		/*
        a_doc = [[NSDocumentController sharedDocumentController]
                        openDocumentWithContentsOfURL:aFileURL display:NO error:nil];
		if (![current_docs containsObject:a_doc]) {
			[doc_list addObject:a_doc];
		}
         */
	}
	NSIndexSet *insertIdxes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row,[doc_list count])];
	[fileListController insertObjects:doc_list atArrangedObjectIndexes:insertIdxes];
}


- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info 
			  row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    BOOL success = NO;
	if ([info draggingSource] == fileTableView) { //move in same table
		
		NSData* rowData = [pboard dataForType:MovedRowsType];
		NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
		[self moveObjectsInArrangedObjectsFromIndexes:rowIndexes toIndex:row];
		
		success = YES;
    } 
	else {
		NSString *error = nil;
		NSPropertyListFormat format;
		NSData* rowData = [pboard dataForType:NSFilenamesPboardType];
		id plist = [NSPropertyListSerialization propertyListFromData:rowData
													mutabilityOption:NSPropertyListImmutable
															  format:&format
													errorDescription:&error];		
		[self insertFromPathes:plist row:row];
		success = YES;
	}
	
	return success;
}
@end
