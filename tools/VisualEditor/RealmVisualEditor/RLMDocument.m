//
//  RLMDocument.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 13/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMDocument.h"

@interface RLMDocument ()

@property (nonatomic, strong) IBOutlet NSTableView *realmTables;
@property (nonatomic, strong) IBOutlet NSTableView *tableColumns;

@end

@implementation RLMDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
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

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.realmTables) {
        return [self tables].count;
    }
    else if (tableView == self.tableColumns) {
        NSArray *columns = [self columnsForTableAtIndex:self.realmTables.selectedRow];
        return columns.count;
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.realmTables) {
        NSArray *tables = [self tables];
        return tables[rowIndex];
    }
    else if (tableView == self.tableColumns) {
        NSUInteger tableIndex = self.realmTables.selectedRow;
        NSUInteger columnIndex = [self tableView:tableView
                              indexOfTableColumn:tableColumn];
        
        NSArray *rows = [self rowsForTableAtIndex:tableIndex];
        NSArray *items = rows[rowIndex];
        
        if (columnIndex < items.count) {
            return items[columnIndex];
        }
        
        return @"";
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{

}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (notification.object == self.realmTables) {
        // How many columns does the table contains?
        NSUInteger selectedTabelIndex = self.realmTables.selectedRow;
        NSArray *columns = [self columnsForTableAtIndex:selectedTabelIndex];
        NSUInteger columnCount = columns.count;
        
        // If we have more columns than needed we hide those in excess
        NSUInteger displayColumnsCount = self.tableColumns.numberOfColumns;
        if (columnCount <= displayColumnsCount) {
        
        }
        else {
        
        }
        
        [self.tableColumns reloadData];
    }
}

#pragma mark - Private methods

- (NSUInteger)tableView:(NSTableView *)tableView indexOfTableColumn:(NSTableColumn *)tableColumn
{
    return [tableView.tableColumns indexOfObject:tableColumn];
}

- (NSArray *)tables
{
    return @[@"Table 0", @"Table 1", @"Table 2"];
}

- (NSArray *)columnsForTableAtIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
            return @[@"Column 0,0", @"Colum 0,1"];
            break;

        case 1:
            return @[@"Column 1,0", @"Colum 1,1", @"Colum 1,2"];
            break;

        case 2:
            return @[@"Column 2,0"];
            break;
            
        default:
            return @[];
            break;
    }
}

- (NSArray *)rowsForTableAtIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
            return @[@[@"Item 0,0,0", @"Item 0,1,0"], @[@"Item 0,0,1", @"Item 0,1,1"]];
            break;
            
        case 1:
            return @[@[@"Item 1,0,0", @"Item 1,1,0"], @[@"Item 1,0,1", @"Item 1,1,1"],  @[@"Item 1,0,2", @"Item 1,1,2"]];
            break;
            
        case 2:
            return @[@[@"item 2,0,0"]];
            break;
            
        default:
            return @[];
            break;
    }
}

@end
