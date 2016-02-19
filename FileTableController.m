#import "FileTableController.h"
#import "DMGDocument.h"
#import "KXTableView.h"
#import "UtilityFunctions.h"

#define useLog 0

@implementation FileTableController

static NSString *MovedRowsType = @"MOVED_ROWS_TYPE";

- (void) dealloc {
	[super dealloc];
}

- (void)disposeDocuments
{
	NSEnumerator *enumerator = [[fileListController arrangedObjects] objectEnumerator];
	DMGDocument *a_source;
	while (a_source = [enumerator nextObject]) {
		[a_source setIsMultiSourceMember:NO];
		[a_source dispose:self];
	}
}

- (void)addFileURL:(NSURL *)aFileURL
{
	NSDocument *a_doc = [[NSDocumentController sharedDocumentController]
							openDocumentWithContentsOfURL:aFileURL display:NO error:nil];
	if (a_doc) {
		if (![[fileListController arrangedObjects] containsObject:a_doc]) {
			[fileListController addObject:a_doc];
		}
	}
}

- (void)addFileURLs:(NSArray *)files
{
	NSEnumerator *enumerator = [files objectEnumerator];
	NSURL *file_url;
	while (file_url = [enumerator nextObject]) {
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
										toIndex:(unsigned int)insertIndex
{
	NSUInteger index = [indexSet lastIndex];
	
    unsigned int	aboveInsertIndexCount = 0;
    id object;
    unsigned int	removeIndex;
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
	[fileListController setSortDescriptors:nil];
	[fileListController removeObjects:objects];
	[fileListController addObjects:objects];
	[fileListController setSelectedObjects:selectedObj];
}

- (void)insertFromPathes:(NSArray *)pathes row:(int)row
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSMutableArray *doc_list = [NSMutableArray arrayWithCapacity:[pathes count]];
	NSEnumerator *enumerator = [URLsFromPaths(pathes) objectEnumerator];
	
	NSURL *aFileURL;
	NSDocument *a_doc;
	NSArray *current_docs = [fileListController arrangedObjects];
	while (aFileURL = [enumerator nextObject]) {
		a_doc = [[NSDocumentController sharedDocumentController]
							openDocumentWithContentsOfURL:aFileURL display:NO error:nil];
		if (![current_docs containsObject:a_doc]) {
			[doc_list addObject:a_doc];
		}
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
