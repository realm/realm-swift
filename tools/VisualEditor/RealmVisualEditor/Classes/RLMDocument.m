//
//  RLMDocument.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 13/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMDocument.h"

#import "RLMRealmNode.h"
#import "RLMTableNode.h"
#import "RLMTableColumn.h"
#import "RLMRealmOutlineNode.h"

@interface RLMDocument ()

@property (nonatomic, strong) IBOutlet NSOutlineView *realmTableOutlineView;
@property (nonatomic, strong) IBOutlet NSTableView *realmTableColumnsView;

@end

@implementation RLMDocument {
    NSArray *testRealms;
    RLMTableNode *selectedTable;
    NSUInteger selectedRowIndex;
}

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    if (self = [super init]) {
        if ([[typeName lowercaseString] isEqualToString:@"documenttype"]) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:absoluteURL.path]) {
                NSString *lastComponent = [absoluteURL lastPathComponent];
                NSString *extension = [absoluteURL pathExtension];

                if ([[extension lowercaseString] isEqualToString:@"realm"]) {
                    NSArray *fileNameComponents = [lastComponent componentsSeparatedByString:@"."];
                    NSString *realmName = [fileNameComponents firstObject];
                    
                    RLMRealmNode *realm = [[RLMRealmNode alloc] initWithName:realmName
                                                                         url:absoluteURL.path];
                    testRealms = @[realm];
                    
                }
            }
            else {
                
            }
        }
        else {
            
        }
    }
    
    return self;
}

- (id)initForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return nil;
}


- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"RLMDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}

#pragma mark - NSOutlineViewDataSource implementation

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return testRealms[index];
    }
    else if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
        id<RLMRealmOutlineNode> outlineItem = item;
        return [outlineItem childNodeAtIndex:index];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (item == nil) {
        return testRealms.count != 0;
    }
    else if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
        id<RLMRealmOutlineNode> outlineItem = item;
        return outlineItem.isExpandable;
    }
    
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return testRealms.count;
    }
    else if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
        id<RLMRealmOutlineNode> outlineItem = item;
        return outlineItem.numberOfChildNodes;
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSUInteger columnIndex = [_realmTableOutlineView.tableColumns indexOfObject:tableColumn];
    if (columnIndex != NSNotFound) {
        if (item == nil && columnIndex == 0) {
            return @"Realms";
        }
        else if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
            id<RLMRealmOutlineNode> outlineItem = item;
            return [outlineItem nodeElementForColumnWithIndex:columnIndex];
        }
    }
    
    return nil;
}

#pragma mark - NSOutlineViewDelegate implementation

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{

    NSOutlineView *outlineView = notification.object;
    if (outlineView == self.realmTableOutlineView) {
        id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
        if ([selectedItem isKindOfClass:[RLMTableNode class]]) {
        [self updateSelectedTable:selectedItem];
            return;
        }
    }
    
    [self updateSelectedTable:nil];
}

#pragma mark - NSTableViewDataSource implementation

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.realmTableColumnsView) {
        return selectedTable.rowCount;
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.realmTableColumnsView) {
        NSArray *row = [selectedTable rowAtIndex:rowIndex];
        
        NSUInteger columnIndex = [self.realmTableColumnsView.tableColumns indexOfObject:tableColumn];
        id object = row[columnIndex];
        if ([object isKindOfClass:[RLMTableNode class]] || [object isKindOfClass:[RLMTable class]]) {
            return @"<Sub table>";
        }
        
        return object;
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.realmTableColumnsView) {
        NSUInteger columnIndex = [self.realmTableColumnsView.tableColumns indexOfObject:tableColumn];
        RLMTableColumn *columnNode = selectedTable.tableColumns[columnIndex];

        RLMRealmNode *realmNode = testRealms[0];
        RLMRealm *realm = realmNode.realm;
        
        switch (columnNode.columnType) {
            case RLMTypeBool: {
                if ([object isKindOfClass:[NSNumber class]]) {
                    [realm writeUsingBlock:^(RLMRealm *realm) {
                        RLMTable *table = [realm tableWithName:selectedTable.tableName];
                        table[rowIndex][columnIndex] = @(((NSNumber *)object).boolValue);
                    }];
                }
                break;
            }
            case RLMTypeInt: {
                if ([object isKindOfClass:[NSNumber class]]) {
                    [realm writeUsingBlock:^(RLMRealm *realm) {
                        RLMTable *table = [realm tableWithName:selectedTable.tableName];
                        table[rowIndex][columnIndex] = @(((NSNumber *)object).intValue);
                    }];
                }
                break;
            }
            case RLMTypeFloat: {
                if ([object isKindOfClass:[NSNumber class]]) {
                    [realm writeUsingBlock:^(RLMRealm *realm) {
                        RLMTable *table = [realm tableWithName:selectedTable.tableName];
                        table[rowIndex][columnIndex] = @(((NSNumber *)object).floatValue);
                    }];
                }
                break;
            }
            case RLMTypeDouble: {
                if ([object isKindOfClass:[NSNumber class]]) {
                    [realm writeUsingBlock:^(RLMRealm *realm) {
                        RLMTable *table = [realm tableWithName:selectedTable.tableName];
                        table[rowIndex][columnIndex] = @(((NSNumber *)object).doubleValue);
                    }];
                }
                break;
            }
            case RLMTypeString: {
                if ([object isKindOfClass:[NSString class]]) {
                    [realm writeUsingBlock:^(RLMRealm *realm) {
                        RLMTable *table = [realm tableWithName:selectedTable.tableName];
                        table[rowIndex][columnIndex] = object;
                    }];
                }
                break;
            }
            case RLMTypeNone:
            case RLMTypeBinary:
            case RLMTypeDate:
            case RLMTypeTable:
            case RLMTypeMixed:
                break;
                
            default:
                break;
        }
    }
//    NSArray *row = [selectedTable rowAtIndex:rowIndex];
}

#pragma mark - NSTableViewDelegate implementation

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.realmTableColumnsView) {
        NSUInteger columnIndex = [self.realmTableColumnsView.tableColumns indexOfObject:tableColumn];
        RLMTableColumn *columnNode = selectedTable.tableColumns[columnIndex];
        
        switch (columnNode.columnType) {
            case RLMTypeBool:
            case RLMTypeInt: {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.allowsFloats = NO;
                ((NSCell *)cell).formatter = formatter;
                break;
            }
            case RLMTypeFloat:
            case RLMTypeDouble: {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                ((NSCell *)cell).formatter = formatter;
                break;
            }
            case RLMTypeNone:
            case RLMTypeString:
            case RLMTypeBinary:
            case RLMTypeDate:
            case RLMTypeTable:
            case RLMTypeMixed:
                break;
                
            default:
                break;
        }
    }
}

#pragma mark - Private methods

- (void)updateSelectedTable:(RLMTableNode *)table
{
    selectedTable = table;

    // How many columns does the table contains?
    NSArray *columns = selectedTable.tableColumns;
    NSUInteger requiredColumnCount = columns.count;
    
    // If we have more columns than needed we remove the ones in excess
    NSUInteger existingColumnsCount = self.realmTableColumnsView.numberOfColumns;
    if (requiredColumnCount <= existingColumnsCount) {
        NSUInteger excessColumnCount = existingColumnsCount - requiredColumnCount;
        for (NSUInteger index = 0; index < excessColumnCount; index++) {
            NSTableColumn *column = [self.realmTableColumnsView.tableColumns lastObject];
            [self.realmTableColumnsView removeTableColumn:column];
        }
    }
    // Otherwise we need to add new columns to display all columns
    else {
        for (NSUInteger index = 0; index < requiredColumnCount - existingColumnsCount; index++) {
            NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"Column #%lu", existingColumnsCount + index]];
            
            RLMTableColumn *column = columns[index];
            
            if (column.columnType == RLMTypeBool ||
                column.columnType == RLMTypeInt ||
                column.columnType == RLMTypeFloat ||
                column.columnType == RLMTypeDouble ||
                column.columnType == RLMTypeString) {
                tableColumn.editable = YES;
            
            }
            else {
                tableColumn.editable = NO;
            }
            
            [self.realmTableColumnsView addTableColumn:tableColumn];
        }
    }
    
    // Set the column names
    for (NSUInteger index = 0; index < columns.count; index++) {
        NSTableColumn *tableColumn = self.realmTableColumnsView.tableColumns[index];
        NSTableHeaderCell *headerCell = tableColumn.headerCell;
        RLMTableColumn *column = columns[index];
        headerCell.stringValue = column.columnName;
    }
    
    [self.realmTableColumnsView reloadData];
}

@end
