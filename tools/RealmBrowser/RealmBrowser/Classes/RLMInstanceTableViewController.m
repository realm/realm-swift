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

#import "NSTableColumn+Resize.h"
#import "NSColor+ByteSizeFactory.h"

#import "objc/objc-class.h"

@implementation RLMInstanceTableViewController {

    BOOL awake;
    BOOL linkCursorDisplaying;
    NSDateFormatter *dateFormatter;
    NSNumberFormatter *numberFormatter;
    
    NSImage *tempImage;
}

#pragma mark - NSObject overrides

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

    self.realmIsLocked = YES;
    self.schemasLocked = YES;

    awake = YES;
}

#pragma mark - Public methods - Accessors

- (RLMTableView *)realmTableView
{
    return (RLMTableView *)self.tableView;
}

#pragma mark - RLMViewController overrides

- (void)performUpdateUsingState:(RLMNavigationState *)newState oldState:(RLMNavigationState *)oldState
{
    [super performUpdateUsingState:newState oldState:oldState];
    
    if ([newState isMemberOfClass:[RLMNavigationState class]]) {
        self.displayedType = newState.selectedType;
        [self.tableView reloadData];
        [self.realmTableView formatColumnsToFitType:newState.selectedType withSelectionAtRow:newState.selectedInstanceIndex];
        [self setSelectionIndex:newState.selectedInstanceIndex];
    }
    else if ([newState isMemberOfClass:[RLMArrayNavigationState class]]) {
        RLMArrayNavigationState *arrayState = (RLMArrayNavigationState *)newState;
        
        RLMClassNode *referringType = (RLMClassNode *)arrayState.selectedType;
        RLMObject *referingInstance = [referringType instanceAtIndex:arrayState.selectedInstanceIndex];
        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithReferringProperty:arrayState.property
                                                                         onObject:referingInstance
                                                                            realm:self.parentWindowController.modelDocument.presentedRealm.realm];
        self.displayedType = arrayNode;
        [self.tableView reloadData];
        [self.realmTableView formatColumnsToFitType:arrayNode withSelectionAtRow:0];
        [self setSelectionIndex:arrayState.arrayIndex];
    }
    else if ([newState isMemberOfClass:[RLMQueryNavigationState class]]) {
        RLMQueryNavigationState *arrayState = (RLMQueryNavigationState *)newState;

        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithQuery:arrayState.searchText result:arrayState.results andParent:arrayState.selectedType];

        self.displayedType = arrayNode;
        [self.tableView reloadData];
        [self.realmTableView formatColumnsToFitType:arrayNode withSelectionAtRow:0];
        [self setSelectionIndex:0];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView != self.tableView) {
        return 0;
    }
    
    return self.displayedType.instanceCount;
}

#pragma mark - RLMTableViewDelegate implementation

- (void)addRows:(NSIndexSet *)rowIndexes
{
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    RLMTypeNode *displayedType = self.displayedType;
    Class rlmObjectClass = NSClassFromString(displayedType.name);
    NSDictionary *defaultPropertyValues = [rlmObjectClass defaultPropertyValues];
    if (!defaultPropertyValues) {
        defaultPropertyValues = [self defaultPropertyValuesForTypeNode:displayedType];
    }
    
    NSUInteger rowsToAdd = MAX(rowIndexes.count, 1);

    [realm beginWriteTransaction];
    for (int i = 0; i < rowsToAdd; i++) {
        [rlmObjectClass createInRealm:realm withObject:defaultPropertyValues];
    }
    [realm commitWriteTransaction];
    
    [self.tableView reloadData];
}

- (void)deleteRows:(NSIndexSet *)rowIndexes
{
    NSMutableArray *objectsToDelete = [NSMutableArray array];
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        RLMObject *object = [self.displayedType instanceAtIndex:idx];
        [objectsToDelete addObject:object];
    }];
    
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    [realm beginWriteTransaction];
    [realm deleteObjects:objectsToDelete];
    [realm commitWriteTransaction];
    [self.tableView reloadData];
}

-(void)addColumns:(NSIndexSet *)columnIndexes
{
    NSLog(@"IT: addColumns: %@", columnIndexes);
}

-(void)deleteColumns:(NSIndexSet *)columnIndexes
{
    NSLog(@"IT: deleteColumns: %@", columnIndexes);
}

#pragma mark - Mouse movement

-(NSDictionary *)defaultPropertyValuesForTypeNode:(RLMTypeNode *)typeNode
{
    NSMutableDictionary *defaultPropertyValues = [NSMutableDictionary dictionary];
    
    for (RLMProperty *property in typeNode.schema.properties) {
        defaultPropertyValues[property.name] = [self defaultValueForPropertyType:property.type];
    }
    
    return defaultPropertyValues;
}

-(id)defaultValueForPropertyType:(RLMPropertyType)propertyType
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

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.tableView == notification.object) {
        NSInteger selectedIndex = self.tableView.selectedRow;
        
        [self.parentWindowController.currentState updateSelectionToIndex:selectedIndex];
    }
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView != self.tableView) {
        return nil;
    }
    
    NSTableCellView *cellView;

    NSUInteger columnIndex = [tableView.tableColumns indexOfObject:tableColumn];
    RLMTypeNode *displayedType = self.displayedType;
    
    RLMClassProperty *classProperty = displayedType.propertyColumns[columnIndex];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:rowIndex];
    id propertyValue = selectedInstance[classProperty.name];
    RLMPropertyType type = classProperty.type;
    
    if (type == RLMPropertyTypeArray) {
        RLMBadgeTableCellView *badgeCellView = [tableView makeViewWithIdentifier:@"BadgeCell" owner:self];
        
        badgeCellView.badge.hidden = NO;
        badgeCellView.badge.title = [NSString stringWithFormat:@"%lu", (unsigned long)[(RLMArray *)propertyValue count]];
        [badgeCellView.badge.cell setHighlightsBy:0];
        
        NSString *formattedText = [self printablePropertyValue:propertyValue ofType:type];
        badgeCellView.textField.attributedStringValue = [self.class linkStringWithString:formattedText];
        
        [badgeCellView.textField setEditable:NO];
        
        cellView = badgeCellView;
    }
    else if (type == RLMPropertyTypeBool) {
        RLMBoolTableCellView *boolCellView = [tableView makeViewWithIdentifier:@"BoolCell" owner:self];
        
        BOOL boolValue;
        if ([propertyValue isKindOfClass:[NSNumber class]]) {
            boolValue = [(NSNumber *)propertyValue boolValue];
        }
        boolCellView.checkBox.state = boolValue ? NSOnState : NSOffState;
        
        cellView = boolCellView;
    }
    else if (type == RLMPropertyTypeInt || type == RLMPropertyTypeFloat || type == RLMPropertyTypeDouble) {
        RLMNumberTableCellView *numberCellView = [tableView makeViewWithIdentifier:@"NumberCell" owner:self];
        numberCellView.textField.stringValue = [self printablePropertyValue:propertyValue ofType:type];
        
        ((RLMNumberTextField *)numberCellView.textField).number = propertyValue;
        
        cellView = numberCellView;
    }
    else {
        RLMBasicTableCellView *basicCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
        
        NSString *formattedText = [self printablePropertyValue:propertyValue ofType:type];
        
        if (type == RLMPropertyTypeObject) {
            basicCellView.textField.attributedStringValue = [self.class linkStringWithString:formattedText];
            [basicCellView.textField setEditable:NO];
        }
        else {
            basicCellView.textField.stringValue = formattedText;
        }
        
        cellView = basicCellView;
    }
    
    cellView.toolTip = [self tooltipForPropertyValue:propertyValue ofType:type];
    
    return cellView;
}

#pragma mark - Datasource helper methods

+(NSAttributedString *)linkStringWithString:(NSString *)string
{
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor colorWithByteRed:26 green:66 blue:251 alpha:255], NSUnderlineStyleAttributeName: @1};
    return [[NSAttributedString alloc] initWithString:string attributes:attributes];
}

-(NSString *)printablePropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType
{
    return [self printablePropertyValue:propertyValue ofType:propertyType linkFormat:NO];
}

-(NSString *)printablePropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType linkFormat:(BOOL)linkFormat
{
    switch (propertyType) {
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            if ([propertyValue isKindOfClass:[NSNumber class]]) {
                numberFormatter.maximumFractionDigits = 3;
                if (propertyType == RLMPropertyTypeInt) {
                    numberFormatter.allowsFloats = NO;
                } else {
                    numberFormatter.allowsFloats = YES;
                }
                
                return [numberFormatter stringFromNumber:(NSNumber *)propertyValue];
            }
            break;
            
        case RLMPropertyTypeString:
            if ([propertyValue isKindOfClass:[NSString class]]) {
                return propertyValue;
            }
            break;
            
        case RLMPropertyTypeBool:
            if ([propertyValue isKindOfClass:[NSNumber class]]) {
                return [(NSNumber *)propertyValue boolValue] ? @"TRUE" : @"FALSE";
            }
            break;

        case RLMPropertyTypeArray: {
            RLMArray *referredArray = (RLMArray *)propertyValue;
            if (linkFormat) {
                return [NSString stringWithFormat:@"%@[%lu]", referredArray.objectClassName, (unsigned long)referredArray.count];
            }

            return [NSString stringWithFormat:@"%@[]", referredArray.objectClassName];
        }
            
        case RLMPropertyTypeDate:
            if ([propertyValue isKindOfClass:[NSDate class]]) {
                return [dateFormatter stringFromDate:(NSDate *)propertyValue];
            }
            break;
            
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
                
                returnString = [returnString stringByAppendingFormat:@"%@, ", propertyDescription];
            }
            returnString = [returnString substringToIndex:returnString.length - 2];
            
            return [returnString stringByAppendingString:@")"];
        }
    }
    
    return nil;
}

-(NSString *)tooltipForPropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType
{
    switch (propertyType) {
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            if ([propertyValue isKindOfClass:[NSNumber class]]) {
                numberFormatter.maximumFractionDigits = UINT16_MAX;
                
                return [numberFormatter stringFromNumber:propertyValue];
            }
            break;
            
        case RLMPropertyTypeObject:
            if ([propertyValue isKindOfClass:[RLMObject class]]) {
                RLMObject *referredObject = (RLMObject *)propertyValue;
                RLMObjectSchema *objectSchema = referredObject.objectSchema;
                NSArray *properties = objectSchema.properties;
                
                NSString *toolTipString = @"";
                for (RLMProperty *property in properties) {
                    toolTipString = [toolTipString stringByAppendingFormat:@" %@:%@", property.name, referredObject[property.name]];
                }
                
                return toolTipString;
            }
            break;
            
        case RLMPropertyTypeArray:
            if ([propertyValue isKindOfClass:[RLMArray class]]) {
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
            
            break;
            
        default:
            break;
    }
    
    return nil;
}

#pragma mark - Mouse movement

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

#pragma mark - Public methods - NSTableView event handling

- (IBAction)editedTextField:(NSTextField *)sender {
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[column];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
    
    id result = nil;
    
    if (propertyNode.type == RLMPropertyTypeString) {
        result = sender.stringValue;
    }
    else if (propertyNode.type == RLMPropertyTypeInt) {
        numberFormatter.allowsFloats = NO;
        result = [numberFormatter numberFromString:sender.stringValue];
    }
    else if (propertyNode.type == RLMPropertyTypeFloat || propertyNode.type == RLMPropertyTypeDouble) {
        numberFormatter.allowsFloats = YES;
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        result = [numberFormatter numberFromString:sender.stringValue];
    }
    else if (propertyNode.type == RLMPropertyTypeDate) {
        result = [dateFormatter dateFromString:sender.stringValue];
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

- (void)rightClickedHeaderColumn:(NSUInteger)column
{
    if ([self.tableView.selectedColumnIndexes containsIndex:column]) {
        return;
    }
    
    [self.tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex:column] byExtendingSelection:NO];
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
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[column];
    
    if (propertyNode.type == RLMPropertyTypeObject) {
        RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
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
        RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
        NSObject *propertyValue = selectedInstance[propertyNode.name];
        
        if ([propertyValue isKindOfClass:[RLMArray class]]) {
            RLMArrayNavigationState *state = [[RLMArrayNavigationState alloc] initWithSelectedType:displayedType typeIndex:row property:propertyNode.property arrayIndex:0];
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
        datepicker.datePickerElements = NSHourMinuteSecondDatePickerElementFlag | NSYearMonthDayDatePickerElementFlag | NSTimeZoneDatePickerElementFlag;
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

#pragma mark - Public methods - Table view construction

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

@end



