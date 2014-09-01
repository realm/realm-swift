////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMInstanceTableViewController.h"

#import "RLMRealmBrowserWindowController.h"
#import "RLMArrayNavigationState.h"
#import "RLMQueryNavigationState.h"
#import "RLMArrayNode.h"
#import "RLMRealmNode.h"

#import "RLMBadgeTableCellView.h"
#import "RLMBasicTableCellView.h"
#import "RLMBoolTableCellView.h"
#import "RLMNumberTableCellView.h"
#import "RLMImageTableCellView.h"

#import "RLMTableColumn.h"

#import "NSColor+ByteSizeFactory.h"
#import "NSFont+Standard.h"

#import "objc/objc-class.h"

const NSUInteger kMaxNumberOfArrayEntriesInToolTip = 5;
const NSUInteger kMaxNumberOfStringCharsInObjectLink = 20;
const NSUInteger kMaxNumberOfStringCharsForTooltip = 300;
const NSUInteger kMaxNumberOfObjectCharsForTable = 200;

@interface RLMObject ()

- (instancetype)initWithRealm:(RLMRealm *)realm
                       schema:(RLMObjectSchema *)schema
                defaultValues:(BOOL)useDefaults;

@end

@implementation RLMInstanceTableViewController {
    BOOL awake;
    BOOL linkCursorDisplaying;
    NSDateFormatter *dateFormatter;
    NSNumberFormatter *numberFormatter;
    NSMutableDictionary *autofittedColumns;
}

#pragma mark - NSObject Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];

    if (awake) {
        return;
    }
    
    [self.tableView setTarget:self];
    [self.tableView setAction:@selector(userClicked:)];
    [self.tableView setDoubleAction:@selector(userDoubleClicked:)];

    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    linkCursorDisplaying = NO;
    
    autofittedColumns = [NSMutableDictionary dictionary];
    
    awake = YES;
}

#pragma mark - Public methods - Accessors

- (RLMTableView *)realmTableView
{
    return (RLMTableView *)self.tableView;
}

#pragma mark - RLMViewController Overrides

- (void)performUpdateUsingState:(RLMNavigationState *)newState oldState:(RLMNavigationState *)oldState
{
    [super performUpdateUsingState:newState oldState:oldState];
    
    [self.tableView setAutosaveTableColumns:NO];
    
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    
    if ([newState isMemberOfClass:[RLMNavigationState class]]) {
        self.displayedType = newState.selectedType;
        [self.tableView reloadData];

        [self.realmTableView setupColumnsWithType:newState.selectedType
                                 withSelectionAtRow:newState.selectedInstanceIndex];
        [self setSelectionIndex:newState.selectedInstanceIndex];
    }
    else if ([newState isMemberOfClass:[RLMArrayNavigationState class]]) {
        RLMArrayNavigationState *arrayState = (RLMArrayNavigationState *)newState;
        
        RLMClassNode *referringType = (RLMClassNode *)arrayState.selectedType;
        RLMObject *referingInstance = [referringType instanceAtIndex:arrayState.selectedInstanceIndex];
        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithReferringProperty:arrayState.property
                                                                         onObject:referingInstance
                                                                            realm:realm];
        self.displayedType = arrayNode;
        [self.tableView reloadData];

        [self.realmTableView setupColumnsWithType:arrayNode withSelectionAtRow:0];
        [self setSelectionIndex:arrayState.arrayIndex];
    }
    else if ([newState isMemberOfClass:[RLMQueryNavigationState class]]) {
        RLMQueryNavigationState *arrayState = (RLMQueryNavigationState *)newState;

        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithQuery:arrayState.searchText
                                                               result:arrayState.results
                                                            andParent:arrayState.selectedType];

        self.displayedType = arrayNode;
        [self.tableView reloadData];

        [self.realmTableView setupColumnsWithType:arrayNode withSelectionAtRow:0];
        [self setSelectionIndex:0];
    }
    
    self.tableView.autosaveName = [NSString stringWithFormat:@"%lu:%@", realm.hash, self.displayedType.name];
    [self.tableView setAutosaveTableColumns:YES];
    
    if (![autofittedColumns[self.tableView.autosaveName] isEqual: @YES]) {
        [self.realmTableView makeColumnsFitContents];
        autofittedColumns[self.tableView.autosaveName] = @YES;
    }

    self.displaysArray = [newState isMemberOfClass:[RLMArrayNavigationState class]];
}

#pragma mark - NSTableView Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView != self.tableView) {
        return 0;
    }
    
    return self.displayedType.instanceCount;
}

#pragma mark - RLMTableView Data Source

-(NSString *)headerToolTipForColumn:(RLMClassProperty *)propertyColumn
{
    NSString *toolTip;
    
    switch (propertyColumn.property.type) {
        case RLMPropertyTypeBool:
            toolTip = @"Boolean";
            break;
            
        case RLMPropertyTypeInt:
            toolTip = @"Integer";
            break;
            
        case RLMPropertyTypeFloat:
            toolTip = @"Float";
            break;
            
        case RLMPropertyTypeDouble:
            toolTip = @"Double";
            break;
            
        case RLMPropertyTypeString:
            toolTip = @"String";
            break;
            
        case RLMPropertyTypeData:
            toolTip = @"Data";
            break;
            
        case RLMPropertyTypeAny:
            toolTip = @"Any";
            break;
            
        case RLMPropertyTypeDate:
            toolTip = @"Date";
            break;
            
        case RLMPropertyTypeArray:
            toolTip = [NSString stringWithFormat:@"%@[]", propertyColumn.property.objectClassName];
            break;
            
        case RLMPropertyTypeObject:
            toolTip = [NSString stringWithFormat:@"%@", propertyColumn.property.objectClassName];
            break;
    }
    
    return toolTip;
}

#pragma mark - NSTableView Delegate

-(CGFloat)tableView:(NSTableView *)tableView sizeToFitWidthOfColumn:(NSInteger)column
{
    RLMTableColumn *tableColumn = self.realmTableView.tableColumns[column];
    
    return [tableColumn sizeThatFitsWithLimit:NO];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.tableView == notification.object) {
        NSInteger selectedIndex = self.tableView.selectedRow;
        
        [self.parentWindowController.currentState updateSelectionToIndex:selectedIndex];
    }
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    NSLog(@"====== viewForTableColumn:row: %ld (%lu) ======", rowIndex, self.displayedType.instanceCount);

    if (tableView != self.tableView) {
        return nil;
    }
    
    NSUInteger columnIndex = [tableView.tableColumns indexOfObject:tableColumn];
    NSLog(@"displayedType: %@", self.displayedType);

    if ([self.displayedType isMemberOfClass:[RLMArrayNode class]]) {
        columnIndex--;
        NSLog(@"decreasing column index to %lu", columnIndex);
    }
    
    // Array gutter
    if (columnIndex == -1) {
        RLMBasicTableCellView *basicCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
        basicCellView.textField.stringValue = [@(rowIndex) stringValue];
        [basicCellView.textField setEditable:NO];
        
        return basicCellView;
    }

    NSLog(@"accessing column %lu out of %lu", columnIndex, self.displayedType.propertyColumns.count);
    
    RLMClassProperty *classProperty = self.displayedType.propertyColumns[columnIndex];
    RLMObject *selectedInstance = [self.displayedType instanceAtIndex:rowIndex];
    id propertyValue = selectedInstance[classProperty.name];
    RLMPropertyType type = classProperty.type;

    NSTableCellView *cellView;
    
    switch (classProperty.type) {
        case RLMPropertyTypeArray: {
            RLMBadgeTableCellView *badgeCellView = [tableView makeViewWithIdentifier:@"BadgeCell" owner:self];
            
            badgeCellView.badge.hidden = NO;
            badgeCellView.badge.title = [NSString stringWithFormat:@"%lu", [(RLMArray *)propertyValue count]];
            [badgeCellView.badge.cell setHighlightsBy:0];
            
            NSString *formattedText = [self printablePropertyValue:propertyValue ofType:type];
            
            badgeCellView.textField.stringValue = formattedText;
            badgeCellView.textField.font = [NSFont linkFont];
            
            [badgeCellView.textField setEditable:NO];
            
            cellView = badgeCellView;
        }
            break;
            
        case RLMPropertyTypeBool: {
            RLMBoolTableCellView *boolCellView = [tableView makeViewWithIdentifier:@"BoolCell" owner:self];
            
            boolCellView.checkBox.state = [(NSNumber *)propertyValue boolValue] ? NSOnState : NSOffState;
            [boolCellView.checkBox setEnabled:!self.realmIsLocked];
            
            cellView = boolCellView;
        }
            break;
            
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble: {
            RLMNumberTableCellView *numberCellView = [tableView makeViewWithIdentifier:@"NumberCell" owner:self];
            numberCellView.textField.stringValue = [self printablePropertyValue:propertyValue ofType:type];
            
            ((RLMNumberTextField *)numberCellView.textField).number = propertyValue;
            [numberCellView.textField setEditable:!self.realmIsLocked];
            
            cellView = numberCellView;
        }
            break;
            
        case RLMPropertyTypeData: {
            RLMImageTableCellView *imageCellView = [tableView makeViewWithIdentifier:@"ImageCell" owner:self];
            imageCellView.textField.stringValue = [self printablePropertyValue:propertyValue ofType:type];
            
            [imageCellView.textField setEditable:NO];
            
            cellView = imageCellView;
        }
            break;
            
        case RLMPropertyTypeAny:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeObject:
        case RLMPropertyTypeString: {
            RLMBasicTableCellView *basicCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            
            NSString *formattedText = [self printablePropertyValue:propertyValue ofType:type];
            basicCellView.textField.stringValue = formattedText;
            
            if (type == RLMPropertyTypeObject) {
                basicCellView.textField.font = [NSFont linkFont];
                [basicCellView.textField setEditable:NO];
            }
            else {
                basicCellView.textField.font = [NSFont textFont];
                [basicCellView.textField setEditable:!self.realmIsLocked];
            }
            
            cellView = basicCellView;
        }
            break;
    }
    
    cellView.toolTip = [self tooltipForPropertyValue:propertyValue ofType:type];
    
    return cellView;
}

#pragma mark - Private Methods - NSTableView Delegate

-(NSString *)printablePropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType
{
    return [self printablePropertyValue:propertyValue ofType:propertyType linkFormat:NO];
}

-(NSString *)printablePropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType linkFormat:(BOOL)linkFormat
{
    if (!propertyValue) {
        return @"";
    }
    
    switch (propertyType) {
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            numberFormatter.maximumFractionDigits = 3;
            numberFormatter.allowsFloats = propertyType != RLMPropertyTypeInt;
            
            return [numberFormatter stringFromNumber:(NSNumber *)propertyValue];
            
        case RLMPropertyTypeString: {
            NSString *stringValue = propertyValue;
            
            if (linkFormat && stringValue.length > kMaxNumberOfStringCharsInObjectLink) {
                stringValue = [stringValue substringToIndex:kMaxNumberOfStringCharsInObjectLink - 3];
                stringValue = [stringValue stringByAppendingString:@"..."];
            }
            
            return stringValue;
        }
            
        case RLMPropertyTypeBool:
                return [(NSNumber *)propertyValue boolValue] ? @"TRUE" : @"FALSE";
            
        case RLMPropertyTypeArray: {
            RLMArray *referredArray = (RLMArray *)propertyValue;
            if (linkFormat) {
                return [NSString stringWithFormat:@"%@[%lu]", referredArray.objectClassName, referredArray.count];
            }
            
            return [NSString stringWithFormat:@"%@[]", referredArray.objectClassName];
        }
            
        case RLMPropertyTypeDate:
            return [dateFormatter stringFromDate:(NSDate *)propertyValue];
            
        case RLMPropertyTypeData:
            return @"<Data>";
            
        case RLMPropertyTypeAny:
            return @"<Any>";
            
        case RLMPropertyTypeObject: {
            RLMObject *referredObject = (RLMObject *)propertyValue;
            if (referredObject == nil) {
                return @"";
            }
            
            if (linkFormat) {
                return [NSString stringWithFormat:@"%@()", referredObject.objectSchema.className];
            }
            
            NSString *returnString = [NSString stringWithFormat:@"%@(", referredObject.objectSchema.className];
            
            for (RLMProperty *property in referredObject.objectSchema.properties) {
                id propertyValue = referredObject[property.name];
                NSString *propertyDescription = [self printablePropertyValue:propertyValue ofType:property.type linkFormat:YES];
                
                if (returnString.length > kMaxNumberOfObjectCharsForTable - 4) {
                    returnString = [returnString stringByAppendingFormat:@"..."];
                    break;
                }
                
                returnString = [returnString stringByAppendingFormat:@"%@, ", propertyDescription];
            }
            
            if ([returnString hasSuffix:@", "]) {
                returnString = [returnString substringToIndex:returnString.length - 2];
            }
            
            return [returnString stringByAppendingString:@")"];
        }
    }
}

-(NSString *)tooltipForPropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType
{
    if (!propertyValue) {
        return nil;
    }

    switch (propertyType) {
        case RLMPropertyTypeString: {
            NSUInteger chars = MIN(kMaxNumberOfStringCharsForTooltip, [(NSString *)propertyValue length]);
            return [(NSString *)propertyValue substringToIndex:chars];
        }
            
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
                numberFormatter.maximumFractionDigits = UINT16_MAX;
                return [numberFormatter stringFromNumber:propertyValue];
            
        case RLMPropertyTypeObject: {
            return nil;

            RLMObject *referredObject = (RLMObject *)propertyValue;
            RLMObjectSchema *objectSchema = referredObject.objectSchema;
            NSArray *properties = objectSchema.properties;
            
            NSString *toolTipString = @"";
            for (RLMProperty *property in properties) {
                toolTipString = [toolTipString stringByAppendingFormat:@" %@:%@\n", property.name, referredObject[property.name]];
            }
            return toolTipString;
        }
            
        case RLMPropertyTypeArray: {
            return nil;
            RLMArray *referredArray = (RLMArray *)propertyValue;
            
            if (referredArray.count <= kMaxNumberOfArrayEntriesInToolTip) {
                return referredArray.description;
            }
            else {
                NSString *result = @"";
                for (NSUInteger index = 0; index < kMaxNumberOfArrayEntriesInToolTip; index++) {
                    RLMObject *arrayItem = referredArray[index];
                    NSString *description = [arrayItem.description stringByReplacingOccurrencesOfString:@"\n"
                                                                                             withString:@"\n\t"];
                    description = [NSString stringWithFormat:@"\t[%lu] %@", index, description];
                    if (index < kMaxNumberOfArrayEntriesInToolTip - 1) {
                        description = [description stringByAppendingString:@","];
                    }
                    result = [[result stringByAppendingString:description] stringByAppendingString:@"\n"];
                }
                result = [@"RLMArray (\n" stringByAppendingString:[result stringByAppendingString:@"\t...\n)"]];
                return result;
            }
        }
            
        case RLMPropertyTypeAny:
        case RLMPropertyTypeBool:
        case RLMPropertyTypeData:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeInt:
            return nil;
    }
}

#pragma mark - RLMTableView Delegate

- (void)addRows:(NSIndexSet *)rowIndexes
{
    if (self.realmIsLocked) {
        return;
    }
    
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    RLMObjectSchema *objectSchema = [realm.schema schemaForClassName:self.displayedType.name];
    
    [realm beginWriteTransaction];
    
    NSUInteger rowsToAdd = MAX(rowIndexes.count, 1);
    
    for (int i = 0; i < rowsToAdd; i++) {
        RLMObject *object = [[RLMObject alloc] initWithRealm:nil schema:objectSchema defaultValues:NO];

        [realm addObject:object];
        for (RLMProperty *property in objectSchema.properties) {
            object[property.name] = [self defaultValueForPropertyType:property.type];
        }
    }
    
    [realm commitWriteTransaction];
    [self.parentWindowController reloadAllWindows];
}

- (void)deleteRows:(NSIndexSet *)rowIndexes
{
    if (self.realmIsLocked) {
        return;
    }

    NSMutableArray *objectsToDelete = [NSMutableArray array];
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        RLMObject *object = [self.displayedType instanceAtIndex:idx];
        [objectsToDelete addObject:object];
    }];
    
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    [realm beginWriteTransaction];
    [realm deleteObjects:objectsToDelete];
    [realm commitWriteTransaction];
    
    [self.parentWindowController reloadAllWindows];
}

- (void)insertRows:(NSIndexSet *)rowIndexes
{
    if (self.realmIsLocked || !self.displaysArray) {
        return;
    }

    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    RLMTypeNode *displayedType = self.displayedType;
    RLMObjectSchema *objectSchema = displayedType.schema;
    
    NSUInteger rowsToInsert = MAX(rowIndexes.count, 1);
    NSUInteger rowToInsertAt = rowIndexes.firstIndex;
    
    if (rowToInsertAt == -1) {
        rowToInsertAt = 0;
    }
    
    [realm beginWriteTransaction];
    
    for (int i = 0; i < rowsToInsert; i++) {
        RLMObject *object = [[RLMObject alloc] initWithRealm:realm schema:objectSchema defaultValues:NO];
        
        for (RLMProperty *property in objectSchema.properties) {
            object[property.name] = [self defaultValueForPropertyType:property.type];
        }
        [(RLMArrayNode *)self.displayedType insertInstance:object atIndex:rowToInsertAt];
    }

    [realm commitWriteTransaction];
    
    [self.parentWindowController reloadAllWindows];
}

- (void)removeRows:(NSIndexSet *)rowIndexes
{
    if (self.realmIsLocked || !self.displaysArray) {
        return;
    }

    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    [realm beginWriteTransaction];
    [rowIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        [(RLMArrayNode *)self.displayedType removeInstanceAtIndex:idx];
    }];
    [realm commitWriteTransaction];
    [self.parentWindowController reloadAllWindows];
}

- (BOOL)containsObjectInRows:(NSIndexSet *)rowIndexes column:(NSInteger)column;
{
    if (column == -1) {
        return NO;
    }

    if ([self propertyTypeForColumn:column] != RLMPropertyTypeObject) {
        return NO;
    }
    
    return [self cellsAreNonEmptyInRows:rowIndexes column:column];
}

- (void)removeObjectLinksAtRows:(NSIndexSet *)rowIndexes column:(NSInteger)columnIndex
{
    [self removeContentsAtRows:rowIndexes column:columnIndex];
}

- (BOOL)containsArrayInRows:(NSIndexSet *)rowIndexes column:(NSInteger)column;
{
    if (column == -1) {
        return NO;
    }
    
    if ([self propertyTypeForColumn:column] != RLMPropertyTypeArray) {
        return NO;
    }

    return [self cellsAreNonEmptyInRows:rowIndexes column:column];
}

- (void)removeArrayLinksAtRows:(NSIndexSet *)rowIndexes column:(NSInteger)columnIndex
{
    [self removeContentsAtRows:rowIndexes column:columnIndex];
}

- (void)openArrayInNewWindowAtRow:(NSInteger)row column:(NSInteger)columnIndex
{
    if (self.displaysArray) {
        columnIndex--;
    }
    
    RLMClassProperty *propertyNode = self.displayedType.propertyColumns[columnIndex];
    RLMArrayNavigationState *state = [[RLMArrayNavigationState alloc] initWithSelectedType:self.displayedType
                                                                                 typeIndex:row
                                                                                  property:propertyNode.property
                                                                                arrayIndex:0];
    [self.parentWindowController newWindowWithNavigationState:state];
}

#pragma mark - Private Methods - RLMTableView Delegate

- (NSDictionary *)defaultValuesForProperties:(NSArray *)properties
{
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    
    for (RLMProperty *property in properties) {
        defaultValues[property.name] = [self defaultValueForPropertyType:property.type];
    }
    
    return defaultValues;
}

- (id)defaultValueForPropertyType:(RLMPropertyType)propertyType
{
    switch (propertyType) {
        case RLMPropertyTypeInt:
            return @0;
        
        case RLMPropertyTypeFloat:
            return @(0.0f);

        case RLMPropertyTypeDouble:
            return @0.0;
            
        case RLMPropertyTypeString:
            return @"";
            
        case RLMPropertyTypeBool:
            return @NO;
            
        case RLMPropertyTypeArray:
            return @[];
            
        case RLMPropertyTypeDate:
            return [NSDate date];
            
        case RLMPropertyTypeData:
            return @"<Data>";
            
        case RLMPropertyTypeAny:
            return @"<Any>";
            
        case RLMPropertyTypeObject: {
            return [NSNull null];
        }
    }
}

- (RLMPropertyType)propertyTypeForColumn:(NSInteger)column
{
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    RLMObjectSchema *objectSchema = [realm.schema schemaForClassName:self.displayedType.name];
    
    if (self.displaysArray) {
        column--;
    }
    
    RLMProperty *property = objectSchema.properties[column];
    
    return property.type;;
}

- (BOOL)cellsAreNonEmptyInRows:(NSIndexSet *)rowIndexes column:(NSInteger)column
{
    if (self.displaysArray) {
        column--;
    }
    
    RLMClassProperty *classProperty = self.displayedType.propertyColumns[column];
    
    __block BOOL returnValue = NO;
    
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger rowIndex, BOOL *stop) {
        RLMObject *selectedInstance = [self.displayedType instanceAtIndex:rowIndex];
        id propertyValue = selectedInstance[classProperty.name];
        if (propertyValue) {
            returnValue = YES;
            *stop = YES;
        }
    }];
    
    return returnValue;
}

- (void)removeContentsAtRows:(NSIndexSet *)rowIndexes column:(NSInteger)column
{
    if (self.displaysArray) {
        column--;
    }
    
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    RLMClassProperty *classProperty = self.displayedType.propertyColumns[column];
    
    id newValue = [NSNull null];
    if (classProperty.property.type == RLMPropertyTypeArray) {
        newValue = @[];
    }
    
    [realm beginWriteTransaction];
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger rowIndex, BOOL *stop) {
        RLMObject *selectedInstance = [self.displayedType instanceAtIndex:rowIndex];
        selectedInstance[classProperty.name] = newValue;
    }];
    [realm commitWriteTransaction];
    
    [self.parentWindowController reloadAllWindows];
}

#pragma mark - Mouse Handling

- (void)mouseDidEnterCellAtLocation:(RLMTableLocation)location
{
    if (!(RLMTableLocationColumnIsUndefined(location) || RLMTableLocationRowIsUndefined(location))) {
        RLMTypeNode *displayedType = self.displayedType;
        
        if (location.column < displayedType.propertyColumns.count && location.row < displayedType.instanceCount) {
            RLMClassProperty *propertyNode = displayedType.propertyColumns[location.column];
            
            if (propertyNode.type == RLMPropertyTypeObject) {
                if (!linkCursorDisplaying) {
                    RLMClassProperty *propertyNode = displayedType.propertyColumns[location.column];
                    RLMObject *selectedInstance = [displayedType instanceAtIndex:location.row];
                    NSObject *propertyValue = selectedInstance[propertyNode.name];
                    
                    if (propertyValue != nil) {
                        [self enableLinkCursor];
                    }
                }
                
                return;
            }
            else if (propertyNode.type == RLMPropertyTypeArray) {
                [self enableLinkCursor];
                return;
            }
        }
    }
    
    [self disableLinkCursor];
}

- (void)mouseDidExitCellAtLocation:(RLMTableLocation)location
{
    [self disableLinkCursor];
}

- (void)mouseDidExitView:(RLMTableView *)view
{
    [self disableLinkCursor];
}

#pragma mark - Public Methods - NSTableView Event Handling

- (IBAction)editedTextField:(NSTextField *)sender {
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[column];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
    
    id result = nil;
    
    switch (propertyNode.type) {
        case RLMPropertyTypeInt:
            numberFormatter.allowsFloats = NO;
            result = [numberFormatter numberFromString:sender.stringValue];
            break;
            
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            numberFormatter.allowsFloats = YES;
            numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            result = [numberFormatter numberFromString:sender.stringValue];
            break;
            
        case RLMPropertyTypeString:
            result = sender.stringValue;
            break;

        case RLMPropertyTypeDate:
            result = [dateFormatter dateFromString:sender.stringValue];
            break;
            
        case RLMPropertyTypeAny:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeBool:
        case RLMPropertyTypeData:
        case RLMPropertyTypeObject:
            break;
    }
    
    if (result) {
        RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
        [realm beginWriteTransaction];
        selectedInstance[propertyNode.name] = result;
        [realm commitWriteTransaction];
    }
    
    [self.tableView reloadData];
}

- (IBAction)editedCheckBox:(NSButton *)sender
{
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[column];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:row];

    NSNumber *result = @((BOOL)(sender.state == NSOnState));

    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    [realm beginWriteTransaction];
    selectedInstance[propertyNode.name] = result;
    [realm commitWriteTransaction];
}

- (void)rightClickedLocation:(RLMTableLocation)location
{
    NSUInteger row = location.row;

    if (row >= self.displayedType.instanceCount || RLMTableLocationRowIsUndefined(location)) {
        [self clearSelection];
        return;
    }
    
    if ([self.tableView.selectedRowIndexes containsIndex:row]) {
        return;
    }
    
    [self setSelectionIndex:row];
}

- (void)userClicked:(NSTableView *)sender
{
    if (self.tableView.selectedRowIndexes.count > 1) {
        return;
    }
    
    NSInteger row = self.tableView.clickedRow;
    NSInteger column = self.tableView.clickedColumn;
    
    if (row == -1 || column == -1) {
        return;
    }
    
    RLMClassProperty *propertyNode = self.displayedType.propertyColumns[column];
    
    if (propertyNode.type == RLMPropertyTypeObject) {
        RLMObject *selectedInstance = [self.displayedType instanceAtIndex:row];
        id propertyValue = selectedInstance[propertyNode.name];
        
        if ([propertyValue isKindOfClass:[RLMObject class]]) {
            RLMObject *linkedObject = (RLMObject *)propertyValue;
            RLMObjectSchema *linkedObjectSchema = linkedObject.objectSchema;
            
            for (RLMClassNode *classNode in self.parentWindowController.modelDocument.presentedRealm.topLevelClasses) {
                if ([classNode.name isEqualToString:linkedObjectSchema.className]) {
                    RLMArray *allInstances = [linkedObject.realm allObjects:linkedObjectSchema.className];
                    NSUInteger objectIndex = [allInstances indexOfObject:linkedObject];
                    
                    RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:classNode index:objectIndex];
                    [self.parentWindowController addNavigationState:state fromViewController:self];
                    
                    break;
                }
            }
        }
    }
    else if (propertyNode.type == RLMPropertyTypeArray) {
        RLMObject *selectedInstance = [self.displayedType instanceAtIndex:row];
        NSObject *propertyValue = selectedInstance[propertyNode.name];
        
        if ([propertyValue isKindOfClass:[RLMArray class]]) {
            RLMArrayNavigationState *state = [[RLMArrayNavigationState alloc] initWithSelectedType:self.displayedType
                                                                                         typeIndex:row
                                                                                          property:propertyNode.property
                                                                                        arrayIndex:0];
            [self.parentWindowController addNavigationState:state fromViewController:self];
        }
    }
    else {
        if (row != -1) {
            [self setSelectionIndex:row];
        }
        else {
            [self clearSelection];
        }
    }
}

- (void)userDoubleClicked:(NSTableView *)sender {
    NSInteger row = self.tableView.clickedRow;
    NSInteger column = self.tableView.clickedColumn;
    
    if (row == -1 || column == -1) {
        return;
    }
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[column];
    RLMObject *selectedObject = [displayedType instanceAtIndex:row];
    id propertyValue = selectedObject[propertyNode.name];
    
    if (propertyNode.type == RLMPropertyTypeDate) {
        // Create a menu with a single menu item, and later populate it with the propertyValue
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
        
        NSRect frame = [self.tableView frameOfCellAtColumn:column row:row];
        frame.origin.x -= [self.tableView intercellSpacing].width*0.5;
        frame.origin.y -= [self.tableView intercellSpacing].height*0.5;
        frame.size.width += [self.tableView intercellSpacing].width;
        frame.size.height += [self.tableView intercellSpacing].height;
        
        frame.size.height = MAX(23.0, frame.size.height);
        
        // Set up a date picker with no border or background
        NSDatePicker *datepicker = [[NSDatePicker alloc] initWithFrame:frame];
        datepicker.bordered = NO;
        datepicker.drawsBackground = NO;
        datepicker.datePickerStyle = NSTextFieldAndStepperDatePickerStyle;
        datepicker.datePickerElements = NSHourMinuteSecondDatePickerElementFlag
        | NSYearMonthDayDatePickerElementFlag
        | NSTimeZoneDatePickerElementFlag;
        datepicker.dateValue = propertyValue;
        
        item.view = datepicker;
        [menu addItem:item];
        
        if ([menu popUpMenuPositioningItem:nil atLocation:frame.origin inView:self.tableView]) {
            RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
            [realm beginWriteTransaction];
            selectedObject[propertyNode.name] = datepicker.dateValue;
            [realm commitWriteTransaction];
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Public Methods - Table View Construction

- (void)enableLinkCursor
{
    if (linkCursorDisplaying) {
        return;
    }
    NSCursor *currentCursor = [NSCursor currentCursor];
    [currentCursor push];
    
    NSCursor *newCursor = [NSCursor pointingHandCursor];
    [newCursor set];
    
    linkCursorDisplaying = YES;
}

- (void)disableLinkCursor
{
    if (linkCursorDisplaying) {
        [NSCursor pop];
        
        linkCursorDisplaying = NO;
    }
}

#pragma mark - Private Methods - Setters/Getters

- (void)setRealmIsLocked:(BOOL)realmIsLocked
{
    _realmIsLocked = realmIsLocked;
    [self.tableView reloadData];
}

@end