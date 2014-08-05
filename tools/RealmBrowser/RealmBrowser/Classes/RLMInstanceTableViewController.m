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

#import "NSTableColumn+Resize.h"
#import "NSColor+ByteSizeFactory.h"

#import "objc/objc-class.h"

@implementation RLMInstanceTableViewController {

    BOOL linkCursorDisplaying;
}

#pragma mark - NSObject overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Perform some extra inititialization on the tableview
    [self.tableView setTarget:self];
    [self.tableView setAction:@selector(userClicked:)];
    
    linkCursorDisplaying = NO;
}

#pragma mark - RLMViewController overrides

- (void)performUpdateUsingState:(RLMNavigationState *)newState oldState:(RLMNavigationState *)oldState
{
    [super performUpdateUsingState:newState
                          oldState:oldState];
    
    if ([newState isMemberOfClass:[RLMNavigationState class]]) {
        [self setDisplayedType:newState.selectedType];
        [(RLMTableView *)self.tableView formatColumnsToFitType:newState.selectedType
                                            withSelectionAtRow:newState.selectedInstanceIndex];
        [self.tableView reloadData];
        [self setSelectionIndex:newState.selectedInstanceIndex];
    }
    else if ([newState isMemberOfClass:[RLMArrayNavigationState class]]) {
        RLMArrayNavigationState *arrayState = (RLMArrayNavigationState *)newState;
        
        RLMClazzNode *referringType = (RLMClazzNode *)arrayState.selectedType;
        RLMObject *referingInstance = [referringType instanceAtIndex:arrayState.selectedInstanceIndex];
        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithReferringProperty:arrayState.property
                                                                         onObject:referingInstance
                                                                            realm:self.parentWindowController.modelDocument.presentedRealm.realm];
        [self setDisplayedType:arrayNode];
        [(RLMTableView *)self.tableView formatColumnsToFitType:arrayNode
                                            withSelectionAtRow:0];
        [self.tableView reloadData];
        [self setSelectionIndex:arrayState.arrayIndex];
    }
    else if ([newState isMemberOfClass:[RLMQueryNavigationState class]]) {
        RLMQueryNavigationState *arrayState = (RLMQueryNavigationState *)newState;

        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithQuery:arrayState.searchText result:arrayState.results andParent:arrayState.selectedType];

        [self setDisplayedType:arrayNode];
        [(RLMTableView *)self.tableView formatColumnsToFitType:arrayNode
                                            withSelectionAtRow:0];
        [self.tableView reloadData];
        [self setSelectionIndex:0];
    }
}

#pragma mark - NSTableViewDataSource implementation

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.tableView) {
        RLMTypeNode *displayedType = [self displayedType];
        NSUInteger count = displayedType.instanceCount;
        
        return count;
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.tableView) {
        NSUInteger columnIndex = [self.tableView.tableColumns indexOfObject:tableColumn];
        
        RLMTypeNode *displayedType = [self displayedType];
        RLMClazzProperty *clazzProperty = displayedType.propertyColumns[columnIndex];
        
        NSString *propertyName = clazzProperty.name;
        RLMObject *selectedInstance = [displayedType instanceAtIndex:rowIndex];
        
        NSObject *propertyValue = selectedInstance[propertyName];

        return [self.class printablePropertyValue:propertyValue ofType:clazzProperty.type];
    }
    
    return nil;
}

+(id)printablePropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType
{
    return [self printablePropertyValue:propertyValue ofType:propertyType linkFormat:NO];
}

+(id)printablePropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType linkFormat:(BOOL)linkFormat
{
    switch (propertyType) {
        case RLMPropertyTypeBool:
            if ([propertyValue isKindOfClass:[NSNumber class]]) {
                if (linkFormat) {
                    return (BOOL)propertyValue ? @"TRUE" : @"FALSE";
                }
                return propertyValue;
            }
            break;

        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            if ([propertyValue isKindOfClass:[NSNumber class]]) {
                return propertyValue;
            }
            break;
            
        case RLMPropertyTypeString:
            if ([propertyValue isKindOfClass:[NSString class]]) {
                return propertyValue;
            }
            break;
        
        case RLMPropertyTypeData:
            if (linkFormat) {
                return @"<Data>";
            }
            
            // Will eventually return an image if present
            return @"<Data>";
            
        case RLMPropertyTypeAny:
            return @"<Any>";
            
        case RLMPropertyTypeDate:
            if ([propertyValue isKindOfClass:[NSDate class]]) {
                if (linkFormat) {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.dateStyle = NSDateFormatterMediumStyle;
                    formatter.timeStyle = NSDateFormatterShortStyle;
                
                    return [formatter stringFromDate:(NSDate *)propertyValue];
                }
                
                return propertyValue;
            }
            
        case RLMPropertyTypeArray: {
            RLMArray *referredArray = (RLMArray *)propertyValue;
            
            if (linkFormat) {
                return [NSString stringWithFormat:@"%@[%lu]", referredArray.objectClassName, (unsigned long)referredArray.count];
            }
            
            // Will show count as a badge instead
            return [NSString stringWithFormat:@"List of %@", referredArray.objectClassName];
        }
            
        case RLMPropertyTypeObject: {
            RLMObject *referredObject = (RLMObject *)propertyValue;
            if (referredObject == nil) {
                return @"";
            }
            
            if (linkFormat) {
                return referredObject.objectSchema.className;
            }
            
            NSString *returnString = [NSString stringWithFormat:@"%@(", referredObject.objectSchema.className];
            
            for (RLMProperty *property in referredObject.objectSchema.properties) {
                id propertyValue = referredObject[property.name];
                id propertyDescription = [self printablePropertyValue:propertyValue ofType:property.type linkFormat:YES];
                
                returnString = [returnString stringByAppendingFormat:@"%@, ", propertyDescription];
            }
            
            returnString = [returnString substringToIndex:returnString.length - 2];
            
            return [returnString stringByAppendingString:@")"];
        }
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    RLMTypeNode *displayedType = [self displayedType];
    
    if (tableView == self.tableView) {
        NSUInteger columnIndex = [self.tableView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = displayedType.propertyColumns[columnIndex];
        NSString *propertyName = propertyNode.name;
        
        RLMObject *selectedObject = [displayedType instanceAtIndex:rowIndex];
        
        RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
        
        [realm beginWriteTransaction];
        
        switch (propertyNode.type) {
            case RLMPropertyTypeBool:
                if ([object isKindOfClass:[NSNumber class]]) {
                    selectedObject[propertyName] = @(((NSNumber *)object).boolValue);
                }
                break;
                
            case RLMPropertyTypeInt:
                if ([object isKindOfClass:[NSNumber class]]) {
                    selectedObject[propertyName] = @(((NSNumber *)object).integerValue);
                }
                break;
                
            case RLMPropertyTypeFloat:
                if ([object isKindOfClass:[NSNumber class]]) {
                    selectedObject[propertyName] = @(((NSNumber *)object).floatValue);
                }
                break;
                
            case RLMPropertyTypeDouble:
                if ([object isKindOfClass:[NSNumber class]]) {
                    selectedObject[propertyName] = @(((NSNumber *)object).doubleValue);
                }
                break;
                
            case RLMPropertyTypeString:
                if ([object isKindOfClass:[NSString class]]) {
                    selectedObject[propertyName] = object;
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
        
        [realm commitWriteTransaction];
    }
}

#pragma mark - NSTableViewDelegate implementation

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.tableView == notification.object) {
        RLMNavigationState *currentState = self.parentWindowController.currentState;
        NSInteger selectedIndex = self.tableView.selectedRow;
        
        [currentState updateSelectionToIndex:selectedIndex];
    }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.tableView) {
        RLMTypeNode *displayedType = [self displayedType];
        
        NSUInteger columnIndex = [self.tableView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = displayedType.propertyColumns[columnIndex];
        NSCell *displayingCell = (NSCell *)cell;
        
        switch (propertyNode.type) {
            case RLMPropertyTypeBool:
            case RLMPropertyTypeInt: {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.allowsFloats = NO;
                displayingCell.formatter = formatter;
                break;
            }
                
            case RLMPropertyTypeFloat:
            case RLMPropertyTypeDouble: {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.allowsFloats = YES;
                formatter.numberStyle = NSNumberFormatterDecimalStyle;
                displayingCell.formatter = formatter;
                break;
            }
                
            case RLMPropertyTypeDate: {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateStyle = NSDateFormatterMediumStyle;
                formatter.timeStyle = NSDateFormatterShortStyle;
                displayingCell.formatter = formatter;
                break;
            }
                
            case RLMPropertyTypeData: {
                break;
            }
                
            case RLMPropertyTypeString:
                break;
                
            case RLMPropertyTypeObject:
            case RLMPropertyTypeArray: {
                NSString *rawText = displayingCell.stringValue;
                NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor colorWithByteRed:26 green:66 blue:251 alpha:255], NSUnderlineStyleAttributeName: @1};
                NSAttributedString *formattedText = [[NSAttributedString alloc] initWithString:rawText
                                                                                attributes:attributes];
                displayingCell.attributedStringValue = formattedText;
                break;
            }
            default:
                break;
        }
    }
}

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
    if (tableView == self.tableView) {
        RLMTypeNode *displayedType = [self displayedType];
        
        NSUInteger columnIndex = [self.tableView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = displayedType.propertyColumns[columnIndex];
        
        RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
        NSObject *propertyValue = selectedInstance[propertyNode.name];
        
        switch (propertyNode.type) {
            case RLMPropertyTypeDate: {
                if ([propertyValue isKindOfClass:[NSDate class]]) {
                    NSDate *dateValue = (NSDate *)propertyValue;
                    
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.dateStyle = NSDateFormatterFullStyle;
                    formatter.timeStyle = NSDateFormatterFullStyle;
                    
                    return [formatter stringFromDate:dateValue];
                }
                break;
            }
                
            case RLMPropertyTypeObject: {
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
            }
                
            case RLMPropertyTypeArray: {
                if ([propertyValue isKindOfClass:[RLMArray class]]) {
                    RLMArray *referredArray = (RLMArray *)propertyValue;
                    
                    // In order to avoid that we procedure very long tooltips for arrays we have
                    // an upper limit on how many entries we will display. If the total item count
                    // of the array is within the limit we simply use the default description of
                    // the array, otherwise we construct the tooltip explicitly by concatenating the
                    // descriptions of the all the first array items within the limit + an ellipis.
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
            }
                
            default:
                
                break;
        }
    }
    
    return nil;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.tableView) {
        RLMTypeNode *displayedType = [self displayedType];
        
        NSUInteger columnIndex = [self.tableView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = displayedType.propertyColumns[columnIndex];
        
        if (propertyNode.type == RLMPropertyTypeDate) {
            // Create a frame which covers the cell to be edited
            NSRect frame = [tableView frameOfCellAtColumn:[[tableView tableColumns] indexOfObject:tableColumn]
                                                      row:row];
            
            frame.origin.x -= [tableView intercellSpacing].width * 0.5;
            frame.origin.y -= [tableView intercellSpacing].height * 0.5;
            frame.size.width += [tableView intercellSpacing].width * 0.5;
            frame.size.height = 23;
            
            // Set up a date picker with no border or background
            NSDatePicker *datepicker = [[NSDatePicker alloc] initWithFrame:frame];
            datepicker.bordered = NO;
            datepicker.drawsBackground = NO;
            datepicker.datePickerStyle = NSTextFieldAndStepperDatePickerStyle;
            datepicker.datePickerElements = NSHourMinuteSecondDatePickerElementFlag | NSYearMonthDayDatePickerElementFlag | NSTimeZoneDatePickerElementFlag;
            
            RLMObject *selectedObject = [displayedType instanceAtIndex:row];
            NSString *propertyName = propertyNode.name;
            
            datepicker.dateValue = selectedObject[propertyName];
            
            // Create a menu with a single menu item, and set the date picker as the menu item's view
            NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@""
                                                          action:NULL
                                                   keyEquivalent:@""];
            item.view = datepicker;
            [menu addItem:item];
            
            // Display the menu, and if the user pressed enter rather than clicking away or hitting escape then process our new timestamp
            BOOL userAcceptedEdit = [menu popUpMenuPositioningItem:nil
                                                        atLocation:frame.origin
                                                            inView:tableView];
            if (userAcceptedEdit) {
                RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
                
                [realm beginWriteTransaction];
                selectedObject[propertyName] = datepicker.dateValue;
                [realm commitWriteTransaction];
            }
        }
        else {
            return YES;
        }
    }
    
    return NO;
}

- (void)mouseDidEnterCellAtLocation:(RLMTableLocation)location
{
    if (!(RLMTableLocationColumnIsUndefined(location) || RLMTableLocationRowIsUndefined(location))) {
        RLMTypeNode *displayedType = [self displayedType];
        
        if (location.column < displayedType.propertyColumns.count) {
            RLMClazzProperty *propertyNode = displayedType.propertyColumns[location.column];
            
            if (propertyNode.type == RLMPropertyTypeObject) {
                if (location.row < displayedType.instanceCount) {
                    if (!linkCursorDisplaying) {
                        RLMClazzProperty *propertyNode = displayedType.propertyColumns[location.column];
                        RLMObject *selectedInstance = [displayedType instanceAtIndex:location.row];
                        NSObject *propertyValue = selectedInstance[propertyNode.name];
                        
                        if (propertyValue != nil) {
                            [self enableLinkCursor];
                        }
                    }
                    
                    return;
                }
            }
            else if (propertyNode.type == RLMPropertyTypeArray) {
                if (location.row < displayedType.instanceCount) {
                    if (!linkCursorDisplaying) {
                        [self enableLinkCursor];
                    }
                    
                    return;
                }
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

#pragma mark - Public methods - Accessors

- (RLMTableView *)realmTableView
{
    return (RLMTableView *)self.tableView;
}

#pragma mark - Public methods - NSTableView eventHandling

- (IBAction)userClicked:(id)sender
{
    NSInteger column = self.tableView.clickedColumn;
    NSInteger row = self.tableView.clickedRow;
    
    if (column != -1 && row != -1) {
        RLMTypeNode *displayedType = [self displayedType];
        
        RLMClazzProperty *propertyNode = displayedType.propertyColumns[column];
        
        if (propertyNode.type == RLMPropertyTypeObject) {
            RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
            NSObject *propertyValue = selectedInstance[propertyNode.name];
            
            if ([propertyValue isKindOfClass:[RLMObject class]]) {
                RLMObject *linkedObject = (RLMObject *)propertyValue;
                RLMObjectSchema *linkedObjectSchema = linkedObject.objectSchema;
                
                for (RLMClazzNode *clazzNode in self.parentWindowController.modelDocument.presentedRealm.topLevelClazzes) {
                    if ([clazzNode.name isEqualToString:linkedObjectSchema.className]) {
                        RLMArray *allInstances = [linkedObject.realm allObjects:linkedObjectSchema.className];
                        NSUInteger objectIndex = [allInstances indexOfObject:linkedObject];
                        
                        RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:clazzNode
                                                                                               index:objectIndex];
                        [self.parentWindowController addNavigationState:state
                                                     fromViewController:self];
                        
                        break;
                    }
                }
            }
        }
        else if (propertyNode.type == RLMPropertyTypeArray) {
            RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
            NSObject *propertyValue = selectedInstance[propertyNode.name];
            
            if ([propertyValue isKindOfClass:[RLMArray class]]) {
                RLMArrayNavigationState *state = [[RLMArrayNavigationState alloc] initWithSelectedType:displayedType
                                                                                             typeIndex:row
                                                                                              property:propertyNode.property
                                                                                            arrayIndex:0];
                [self.parentWindowController addNavigationState:state
                                             fromViewController:self];
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
}

#pragma mark - Public methods - Table view construction

- (void)enableLinkCursor
{
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
