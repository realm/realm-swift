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
#import "RLMObject+ResolvedClass.h"
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

- (void)updateViewWithState:(RLMNavigationState *)state
{
    [(RLMTableView *)self.tableView formatColumnsToFitType:state.selectedType
                                        withSelectionAtRow:state.selectionIndex];
    [self.tableView reloadData];
    [self.realmTableView setSelectionIndex:state.selectionIndex];
}

#pragma mark - NSTableViewDataSource implementation

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.tableView) {
        return self.parentWindowController.selectedTypeNode.instanceCount;
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.tableView) {
        
        NSUInteger columnIndex = [self.tableView.tableColumns
                                  indexOfObject:tableColumn];
        
        RLMClazzProperty *clazzProperty = self.parentWindowController.selectedTypeNode.propertyColumns[columnIndex];
        NSString *propertyName = clazzProperty.name;
        RLMObject *selectedInstance = [self.parentWindowController.selectedTypeNode instanceAtIndex:rowIndex];
        NSObject *propertyValue = selectedInstance[propertyName];
        
        switch (clazzProperty.type) {
            case RLMPropertyTypeInt:
            case RLMPropertyTypeBool:
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
                return @"<Data>";
                
            case RLMPropertyTypeAny:
                return @"<Any>";
                
            case RLMPropertyTypeDate:
                if ([propertyValue isKindOfClass:[NSDate class]]) {
                    return propertyValue;
                }
                break;
                
            case RLMPropertyTypeArray: {
                RLMArray *referredObject = (RLMArray *)propertyValue;
                return [NSString stringWithFormat:@"List of links to %@", referredObject.objectClassName];
            }
                
            case RLMPropertyTypeObject: {
                RLMObject *referredObject = (RLMObject *)propertyValue;
                RLMObjectSchema *objectSchema = referredObject.RLMObject_schema;
                return [NSString stringWithFormat:@"Link to %@", objectSchema.className];
            }
                
            default:
                break;
        }
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.tableView) {
        NSUInteger columnIndex = [self.tableView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = self.parentWindowController.selectedTypeNode.propertyColumns[columnIndex];
        NSString *propertyName = propertyNode.name;
        
        RLMObject *selectedObject = [self.parentWindowController.selectedTypeNode instanceAtIndex:rowIndex];
        
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

#pragma mark - RLMTableViewDelegate implementation

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self.parentWindowController updateSelectionAtIndex:self.tableView.selectedRow];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.tableView) {
        NSUInteger columnIndex = [self.tableView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = self.parentWindowController.selectedTypeNode.propertyColumns[columnIndex];
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
        NSUInteger columnIndex = [self.tableView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = self.parentWindowController.selectedTypeNode.propertyColumns[columnIndex];
        
        RLMObject *selectedInstance = [self.parentWindowController.selectedTypeNode instanceAtIndex:row];
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
                    RLMObjectSchema *objectSchema = referredObject.RLMObject_schema;
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
        NSUInteger columnIndex = [self.tableView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = self.parentWindowController.selectedTypeNode.propertyColumns[columnIndex];
        
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
            
            RLMObject *selectedObject = [self.parentWindowController.selectedTypeNode instanceAtIndex:row];
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
        if (location.column < self.parentWindowController.selectedTypeNode.propertyColumns.count) {
            RLMClazzProperty *propertyNode = self.parentWindowController.selectedTypeNode.propertyColumns[location.column];
            
            if (propertyNode.type == RLMPropertyTypeObject || propertyNode.type == RLMPropertyTypeArray) {
                if (location.row < self.parentWindowController.selectedTypeNode.instanceCount) {
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
        RLMClazzProperty *propertyNode = self.parentWindowController.selectedTypeNode.propertyColumns[column];
        
        if (propertyNode.type == RLMPropertyTypeObject) {
            RLMObject *selectedInstance = [self.parentWindowController.selectedTypeNode instanceAtIndex:row];
            NSObject *propertyValue = selectedInstance[propertyNode.name];
            
            if ([propertyValue isKindOfClass:[RLMObject class]]) {
                RLMObject *linkedObject = (RLMObject *)propertyValue;
                RLMObjectSchema *linkedObjectSchema = linkedObject.RLMObject_schema;
                
                for (RLMClazzNode *clazzNode in self.parentWindowController.modelDocument.presentedRealm.topLevelClazzes) {
                    if ([clazzNode.name isEqualToString:linkedObjectSchema.className]) {
                        RLMRealm *realm = linkedObject.realm;
                        RLMObjectSchema *objectSchema = linkedObject.RLMObject_schema;
                        NSString *className = objectSchema.className;
                        RLMArray *allInstances = [realm allObjects:className];
                        NSUInteger objctIndex = [allInstances indexOfObject:linkedObject];
                        
                        [self.parentWindowController updateSelectedTypeNode:clazzNode
                                                       withSelectionAtIndex:objctIndex];
                        break;
                    }
                }
            }
        }
        else if (propertyNode.type == RLMPropertyTypeArray) {
            RLMObject *selectedInstance = [self.parentWindowController.selectedTypeNode instanceAtIndex:row];
            NSObject *propertyValue = selectedInstance[propertyNode.name];
            
            if ([propertyValue isKindOfClass:[RLMArray class]]) {
                RLMArray *linkedArray = (RLMArray *)propertyValue;

                [self.parentWindowController addArray:linkedArray
                                         fromProperty:propertyNode.property
                                               object:selectedInstance];
            }
        }
        else {
            if (row != -1) {
                [self.realmTableView setSelectionIndex:row];
            }
            else {
                [self.realmTableView clearSelection];
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
