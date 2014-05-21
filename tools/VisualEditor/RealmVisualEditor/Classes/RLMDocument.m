//
//  RLMDocument.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 13/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMDocument.h"

#import "RLMRealm.h"
#import "RLMRealmTable.h"
#import "RLMRealmColumn.h"
#import "RLMRealmOutlineNode.h"

@interface RLMDocument ()

@property (nonatomic, strong) IBOutlet NSOutlineView *realmTableOutlineView;
@property (nonatomic, strong) IBOutlet NSTableView *realmTableColumnsView;

@end

@implementation RLMDocument {
    NSArray *testRealms;
    RLMRealmTable *selectedTable;
    NSUInteger selectedRowIndex;
}

- (instancetype)init
{
    if (self = [super init]) {
        selectedTable = nil;
        selectedRowIndex = 0;
        [self initializeTestRealm];
    }
    return self;
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
    if(columnIndex != NSNotFound) {
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
    if(outlineView == self.realmTableOutlineView) {
        id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
        if([selectedItem isKindOfClass:[RLMRealmTable class]]) {
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
        if([object isKindOfClass:[RLMRealmTable class]]) {
            return @"<Sub table>";
        }
        return object;
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{

}

#pragma mark - NSTableViewDelegate implementation

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
}

#pragma mark - Private methods

- (void)updateSelectedTable:(RLMRealmTable *)table
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
            [self.realmTableColumnsView addTableColumn:tableColumn];
        }
    }
    
    // Set the column names
    for (NSUInteger index = 0; index < columns.count; index++) {
        NSTableColumn *tableColumn = self.realmTableColumnsView.tableColumns[index];
        NSTableHeaderCell *headerCell = tableColumn.headerCell;
        RLMRealmColumn *column = columns[index];
        headerCell.stringValue = column.columnName;
    }
    
    [self.realmTableColumnsView reloadData];
}

- (void)initializeTestRealm
{
    RLMRealm *testRealm1 = [[RLMRealm alloc] initWithName:@"Realm 1" url:@"~/zuschlag/Documents/default.realm"];
    RLMRealm *testRealm2 = [[RLMRealm alloc] initWithName:@"Realm 2" url:@"~/zuschlag/temp/old/customers.realm"];
    
    RLMRealmTable *table1 = [[RLMRealmTable alloc] initWithName:@"Table 1"
                                                    columnNames:@[@"Int column 1", @"String col 1", @"Subtable col 1"]
                                                    columnTypes:@[@(RLMTableColumnTypeInteger), @(RLMTableColumnTypeString), @(RLMTableColumnTypeSubTable)]];

    RLMRealmTable *table2 = [[RLMRealmTable alloc] initWithName:@"Table 2"
                                                    columnNames:@[@"Int col 2", @"String col 2"]
                                                    columnTypes:@[@(RLMTableColumnTypeInteger), @(RLMTableColumnTypeString)]];

    RLMRealmTable *table3 = [[RLMRealmTable alloc] initWithName:@"Table 3"
                                                    columnNames:@[@"Int col 4", @"String col 3"]
                                                    columnTypes:@[@(RLMTableColumnTypeInteger), @(RLMTableColumnTypeString)]];
    
    
    RLMRealmTable *subtable1 = [[RLMRealmTable alloc] initWithName:@"Sub table 1"
                                                       columnNames:@[@"Int subcol 1",]
                                                       columnTypes:@[@(RLMTableColumnTypeInteger)]];
    
    RLMRealmTable *subtable2 = [[RLMRealmTable alloc] initWithName:@"Subtable 2"
                                                       columnNames:@[@"String subcol 2",]
                                                       columnTypes:@[@(RLMTableColumnTypeString)]];
    
    [table1 addRowWithValues:@[@(1234), @"Denmark", subtable1]];
    [table1 addRowWithValues:@[@(4321), @"USA", subtable2]];
    
    [table2 addRowWithValues:@[@(8642), @"Green"]];
    [table2 addRowWithValues:@[@(12),   @"Blue"]];
    [table2 addRowWithValues:@[@(-789), @"Yellow"]];
    [table2 addRowWithValues:@[@(1000), @"Black"]];
    [table2 addRowWithValues:@[@(8),    @"Red"]];
    
    [table3 addRowWithValues:@[@(1200), @"New York"]];
    [table3 addRowWithValues:@[@(800),  @"Paris"]];
    [table3 addRowWithValues:@[@(1500), @"Rome"]];
    
    [subtable1 addRowWithValues:@[@(2342)]];
    [subtable1 addRowWithValues:@[@(4522)]];
    [subtable1 addRowWithValues:@[@(999)]];
    [subtable1 addRowWithValues:@[@(111)]];
    [subtable1 addRowWithValues:@[@(222)]];

    [subtable2 addRowWithValues:@[@"Luke Skywalker"]];
    [subtable2 addRowWithValues:@[@"Yoda"]];
    [subtable2 addRowWithValues:@[@"Anakin Skywalker"]];
    [subtable2 addRowWithValues:@[@"R2D2"]];
    [subtable2 addRowWithValues:@[@"Han Solo"]];
    
    [testRealm1 addTable:table1];
    [testRealm1 addTable:table2];
    
    [testRealm2 addTable:table3];
    
    testRealms = @[testRealm1, testRealm2];
}

@end
