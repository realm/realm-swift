//
//  RLMDocument.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 13/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMDocument.h"

#import "RLMRealmNode.h"
#import "RLMClazzNode.h"
#import "RLMClazzProperty.h"
#import "RLMRealmOutlineNode.h"

@interface RLMDocument ()

@property (nonatomic, strong) IBOutlet NSOutlineView *realmTableOutlineView;
@property (nonatomic, strong) IBOutlet NSTableView *realmTableColumnsView;

@end

@implementation RLMDocument {
    RLMRealmNode *presentedRealm;
    RLMClazzNode *selectedClazz;
    NSUInteger selectedInstanceIndex;
}

- (instancetype)init
{
    if (self = [super init]) {

    }
    return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
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
                    presentedRealm = realm;
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

    [self.tableOutlineView expandItem:nil
                       expandChildren:YES];
    
    id firstItem = presentedRealm.topLevelClazzes.firstObject;
    if (firstItem != nil) {
        NSInteger index = [self.tableOutlineView rowForItem:firstItem];
        [self.tableOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                           byExtendingSelection:NO];
    }
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

#pragma mnark - Public methods - NSDocument overrides

- (NSString *)displayName {
    if (presentedRealm.name != nil)
        return presentedRealm.name;
    
    return [super displayName];
}

#pragma mark - NSOutlineViewDataSource implementation

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return presentedRealm;
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
        return presentedRealm == nil;
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
        return 1;
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

- (NSString *)outlineView:(NSOutlineView *)outlineView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation
{
    if ([item respondsToSelector:@selector(hasToolTip)]) {
        if ([item respondsToSelector:@selector(toolTipString)]) {
            return [item toolTipString];
        }
    }
    
    return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSOutlineView *outlineView = notification.object;
    if (outlineView == self.realmTableOutlineView) {
        id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
        if ([selectedItem isKindOfClass:[RLMClazzNode class]]) {
            [self updateSelectedClazz:selectedItem];
            return;
        }
    }
    
    [self updateSelectedClazz:nil];
}

#pragma mark - NSTableViewDataSource implementation

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.realmTableColumnsView) {
        return selectedClazz.instanceCount;
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.realmTableColumnsView) {
        
        NSUInteger columnIndex = [self.realmTableColumnsView.tableColumns
                                  indexOfObject:tableColumn];
        
        RLMClazzProperty *clazzProperty = selectedClazz.propertyColumns[columnIndex];
        NSString *propertyName = clazzProperty.name;
        RLMObject *selectedInstance = [selectedClazz instanceAtIndex:rowIndex];
        NSObject *propertyValue = selectedInstance[propertyName];
        
        switch (clazzProperty.type) {
            case RLMPropertyTypeInt:
            case RLMPropertyTypeBool:
            case RLMPropertyTypeFloat:
            case RLMPropertyTypeDouble:
                if([propertyValue isKindOfClass:[NSNumber class]]) {
                    return propertyValue;
                }
                break;


            case RLMPropertyTypeString:
                if([propertyValue isKindOfClass:[NSString class]]) {
                    return propertyValue;
                }
                break;

            case RLMPropertyTypeData:
                return @"<Data>";

            case RLMPropertyTypeAny:
                return @"<Any>";

            case RLMPropertyTypeDate:
                if([propertyValue isKindOfClass:[NSDate class]]) {
                    return propertyValue;
                }
                break;

            case RLMPropertyTypeArray:
                return @"<Array>";

            case RLMPropertyTypeObject:
                return @"<Object>";

            default:
                break;
        }
    }
    
    return nil;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return NO;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.realmTableColumnsView) {
        NSUInteger columnIndex = [self.realmTableColumnsView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = selectedClazz.propertyColumns[columnIndex];
        NSString *propertyName = propertyNode.name;
        
        RLMObject *selectedObject = [selectedClazz instanceAtIndex:selectedInstanceIndex];

        RLMRealm *realm = presentedRealm.realm;
        
        switch (propertyNode.type) {
            case RLMPropertyTypeBool:
                if ([object isKindOfClass:[NSNumber class]]) {
                    [realm beginWriteTransaction];
                    
                    selectedObject[propertyName] = @(((NSNumber *)object).boolValue);
                    
                    [realm commitWriteTransaction];
                }
                break;

            case RLMPropertyTypeInt:
                if ([object isKindOfClass:[NSNumber class]]) {
                    [realm beginWriteTransaction];
                    
                    selectedObject[propertyName] = @(((NSNumber *)object).integerValue);
                    
                    [realm commitWriteTransaction];
                }
                break;

            case RLMPropertyTypeFloat:
                if ([object isKindOfClass:[NSNumber class]]) {
                    [realm beginWriteTransaction];
                    
                    selectedObject[propertyName] = @(((NSNumber *)object).floatValue);
                    
                    [realm commitWriteTransaction];
                }
                break;

            case RLMPropertyTypeDouble:
                if ([object isKindOfClass:[NSNumber class]]) {
                    [realm beginWriteTransaction];
                    
                    selectedObject[propertyName] = @(((NSNumber *)object).doubleValue);
                    
                    [realm commitWriteTransaction];
                }
                break;
                
            case RLMPropertyTypeString:
                if ([object isKindOfClass:[NSNumber class]]) {
                    [realm beginWriteTransaction];
                    
                    selectedObject[propertyName] = @(((NSNumber *)object).doubleValue);
                    
                    [realm commitWriteTransaction];
                }
                break;
                
            case RLMPropertyTypeDate:
            case RLMPropertyTypeData:
            case RLMPropertyTypeObject:
            case RLMPropertyTypeArray:
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
        RLMClazzProperty *propertyNode = selectedClazz.propertyColumns[columnIndex];
        
        switch (propertyNode.type) {
            case RLMPropertyTypeBool:
            case RLMPropertyTypeInt: {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.allowsFloats = NO;
                ((NSCell *)cell).formatter = formatter;
                break;
            }
            case RLMPropertyTypeFloat:
            case RLMPropertyTypeDouble: {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.allowsFloats = YES;
                formatter.numberStyle = NSNumberFormatterDecimalStyle;
                ((NSCell *)cell).formatter = formatter;
                break;
            }
            case RLMPropertyTypeDate: {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateStyle = NSDateFormatterMediumStyle;
                formatter.timeStyle = NSDateFormatterShortStyle;
                ((NSCell *)cell).formatter = formatter;
                break;
            }
            case RLMPropertyTypeString:
            case RLMPropertyTypeData:
            case RLMPropertyTypeObject:
            case RLMPropertyTypeArray:
                break;
                
            default:
                break;
        }
    }
}

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
    if (tableView == self.realmTableColumnsView) {
        NSUInteger columnIndex = [self.realmTableColumnsView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = selectedClazz.propertyColumns[columnIndex];

        if (propertyNode.type == RLMPropertyTypeDate) {
            RLMObject *selectedInstance = [selectedClazz instanceAtIndex:row];
            NSObject *propertyValue = selectedInstance[propertyNode.name];
            
            if([propertyValue isKindOfClass:[NSDate class]]) {
                NSDate *dateValue = (NSDate *)propertyValue;
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateStyle = NSDateFormatterFullStyle;
                formatter.timeStyle = NSDateFormatterFullStyle;
                
                return [formatter stringFromDate:dateValue];
            }
        }
    }
    
    return nil;
}

#pragma mark - Private methods

- (void)updateSelectedClazz:(RLMClazzNode *)clazz
{
    selectedClazz = clazz;

    // How many properties does the clazz contains?
    NSArray *columns = selectedClazz.propertyColumns;
    NSUInteger columnCount = columns.count;

    // We clear the table view from all old columns
    NSUInteger existingColumnsCount = self.realmTableColumnsView.numberOfColumns;
    for (NSUInteger index = 0; index < existingColumnsCount; index++) {
        NSTableColumn *column = [self.realmTableColumnsView.tableColumns lastObject];
        [self.realmTableColumnsView removeTableColumn:column];
    }

    // ... and add new columns matching the structure of the new realm table.
    for (NSUInteger index = 0; index < columnCount; index++) {
        NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"Column #%lu", existingColumnsCount + index]];
        
        // RLMClazzProperty *column = columns[index];
        
        [self.realmTableColumnsView addTableColumn:tableColumn];
    }
    
    // Set the column names and cell type / formatting
    for (NSUInteger index = 0; index < columns.count; index++) {
        NSTableColumn *tableColumn = self.realmTableColumnsView.tableColumns[index];
        RLMClazzProperty *rlmTableColumn = columns[index];
        
        NSCell *cell;
        switch (rlmTableColumn.type) {
            case RLMPropertyTypeBool: {
                NSButtonCell *buttonCell = [[NSButtonCell alloc] init];
                [buttonCell setTitle:nil];
                [buttonCell setAllowsMixedState:YES];
                [buttonCell setButtonType:NSSwitchButton];
                [buttonCell setAlignment:NSCenterTextAlignment];
                [buttonCell setImagePosition:NSImageOnly];
                [buttonCell setControlSize:NSSmallControlSize];
                
                cell = buttonCell;
                break;
            }
            case RLMPropertyTypeInt:
            case RLMPropertyTypeFloat:
            case RLMPropertyTypeDouble: {
                cell = [[NSCell alloc] initTextCell:@""];
                [cell setAlignment:NSRightTextAlignment];
                
                break;
            }
            case RLMPropertyTypeString:
            case RLMPropertyTypeData:
            case RLMPropertyTypeAny:
            case RLMPropertyTypeDate:
            case RLMPropertyTypeArray:
            case RLMPropertyTypeObject: {
                cell = [[NSCell alloc] initTextCell:@""];
                [cell setAlignment:NSLeftTextAlignment];
            
                break;
            }
        }

        cell.editable = NO;
        tableColumn.dataCell = cell;
        
        NSTableHeaderCell *headerCell = tableColumn.headerCell;
        RLMClazzProperty *column = columns[index];
        headerCell.stringValue = column.name;
    }
    
    [self.realmTableColumnsView reloadData];
}

@end
