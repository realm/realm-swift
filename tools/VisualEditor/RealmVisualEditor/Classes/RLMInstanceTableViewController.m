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

@implementation RLMInstanceTableViewController

- (void)viewDidLoad
{
    // Perform some extra inititialization on the tableview
    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(userDoubleClicked:)];
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
                return [NSString stringWithFormat:@"-> %@[%lu]", referredObject.objectClassName, (unsigned long)referredObject.count];
            }
                
            case RLMPropertyTypeObject: {
                RLMObject *referredObject = (RLMObject *)propertyValue;
                RLMObjectSchema *objectSchema = referredObject.schema;
                return [NSString stringWithFormat:@"-> %@", objectSchema.className];
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

#pragma mark - NSTableViewDelegate implementation

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    
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
                NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor redColor], NSUnderlineStyleAttributeName: @1};
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
                    RLMObjectSchema *objectSchema = referredObject.schema;
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

#pragma mark - Public methods - NSTableView eventHandling

- (IBAction)userDoubleClicked:(id)sender
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
                RLMObjectSchema *linkedObjectSchema = linkedObject.schema;
                
                for (RLMClazzNode *clazzNode in self.parentWindowController.modelDocument.presentedRealm.topLevelClazzes) {
                    if ([clazzNode.name isEqualToString:linkedObjectSchema.className]) {
                        [self.parentWindowController updateSelectedTypeNode:clazzNode];
                        [self updateTableView];
                        
                        // Right now we just fetches the object index from the proxy object.
                        // However, this must be changed later when the proxy object is made public
                        // and provides some mean to retrieve the underlying RLMObject object.
                        // Note: This selection of the linked object does not take any future row
                        // sorting into account!!!
                        NSNumber *indexNumber = [linkedObject valueForKeyPath:@"objectIndex"];
                        NSUInteger instanceIndex = indexNumber.integerValue;
                        
                        if (instanceIndex != NSNotFound) {
                            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:instanceIndex]
                                                 byExtendingSelection:NO];
                        }
                        else {
                            [self.tableView selectRowIndexes:nil
                                                 byExtendingSelection:NO];
                        }
                        
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
                                         fromProperty:propertyNode.property object:selectedInstance];                
            }
        }
    }
}

- (void)updateTableView
{
    [self.tableView reloadData];
    for (NSTableColumn *column in self.tableView.tableColumns) {
        [column resizeToFitContents];
    }
}

#pragma mark - Private methods - Table view construction

- (void)updateSelectedObjectNode:(RLMObjectNode *)outlineNode
{
    self.parentWindowController.selectedTypeNode = outlineNode;
    
    // How many properties does the clazz contains?
    NSArray *columns = outlineNode.propertyColumns;
    NSUInteger columnCount = columns.count;
    
    // We clear the table view from all old columns
    NSUInteger existingColumnsCount = self.tableView.numberOfColumns;
    for (NSUInteger index = 0; index < existingColumnsCount; index++) {
        NSTableColumn *column = [self.tableView.tableColumns lastObject];
        [self.tableView removeTableColumn:column];
    }
    
    // ... and add new columns matching the structure of the new realm table.
    for (NSUInteger index = 0; index < columnCount; index++) {
        NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"Column #%lu", existingColumnsCount + index]];
        
        [self.tableView addTableColumn:tableColumn];
    }
    
    // Set the column names and cell type / formatting
    for (NSUInteger index = 0; index < columns.count; index++) {
        NSTableColumn *tableColumn = self.tableView.tableColumns[index];
        
        RLMClazzProperty *property = columns[index];
        NSString *columnName = property.name;
        
        switch (property.type) {
            case RLMPropertyTypeBool: {
                [self initializeSwitchButtonTableColumn:tableColumn
                                               withName:columnName
                                              alignment:NSRightTextAlignment
                                               editable:YES
                                                toolTip:@"Boolean"];
                break;
            }
                
            case RLMPropertyTypeInt: {
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSRightTextAlignment
                                   editable:YES
                                    toolTip:@"Integer"];
                break;
                
            }
                
            case RLMPropertyTypeFloat: {
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSRightTextAlignment
                                   editable:YES
                                    toolTip:@"Float"];
                break;
            }
                
            case RLMPropertyTypeDouble: {
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSRightTextAlignment
                                   editable:YES
                                    toolTip:@"Double"];
                break;
            }
                
            case RLMPropertyTypeString: {
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSLeftTextAlignment
                                   editable:YES
                                    toolTip:@"String"];
                break;
            }
                
            case RLMPropertyTypeData: {
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSLeftTextAlignment
                                   editable:NO
                                    toolTip:@"Data"];
                break;
            }
                
            case RLMPropertyTypeAny: {
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSLeftTextAlignment
                                   editable:NO
                                    toolTip:@"Any"];
                break;
            }
                
            case RLMPropertyTypeDate: {
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSLeftTextAlignment
                                   editable:YES
                                    toolTip:@"Date"];
                break;
            }
                
            case RLMPropertyTypeArray: {
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSLeftTextAlignment
                                   editable:NO
                                    toolTip:@"Array"];
                break;
            }
                
            case RLMPropertyTypeObject: {
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSLeftTextAlignment
                                   editable:NO
                                    toolTip:@"Link to object"];
                break;
            }
        }
        
        
    }
    
    [self updateTableView];
}

- (NSCell *)initializeTableColumn:(NSTableColumn *)column withName:(NSString *)name alignment:(NSTextAlignment)alignment editable:(BOOL)editable toolTip:(NSString *)toolTip
{
    NSCell *cell = [[NSCell alloc] initTextCell:@""];
    
    [self initializeTabelColumn:column
                       withCell:cell
                           name:name
                      alignment:alignment
                       editable:editable
                        toolTip:toolTip];
    
    return cell;
}

- (NSCell *)initializeSwitchButtonTableColumn:(NSTableColumn *)column withName:(NSString *)name alignment:(NSTextAlignment)alignment editable:(BOOL)editable toolTip:(NSString *)toolTip
{
    NSButtonCell *cell = [[NSButtonCell alloc] init];
    
    cell.title = nil;
    cell.allowsMixedState = YES;
    cell.buttonType =NSSwitchButton;
    cell.alignment = NSCenterTextAlignment;
    cell.imagePosition = NSImageOnly;
    cell.controlSize = NSSmallControlSize;
    
    [self initializeTabelColumn:column
                       withCell:cell
                           name:name
                      alignment:alignment
                       editable:editable
                        toolTip:toolTip];
    
    return cell;
}

- (void)initializeTabelColumn:(NSTableColumn *)column withCell:(NSCell *)cell name:(NSString *) name alignment:(NSTextAlignment)alignment editable:(BOOL)editable toolTip:(NSString *)toolTip
{
    cell.alignment = alignment;
    cell.editable = editable;
    
    column.dataCell = cell;
    column.headerToolTip = toolTip;
    
    NSTableHeaderCell *headerCell = column.headerCell;
    headerCell.stringValue = name;
}


@end
