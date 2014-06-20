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

#import "RLMDocument.h"

#import "RLMRealmNode.h"
#import "RLMClazzNode.h"
#import "RLMArrayNode.h"
#import "RLMClazzProperty.h"
#import "RLMRealmOutlineNode.h"
#import "RLMRealmBrowserWindowController.h"
#import "RLMObject+ResolvedClass.h"
#import "NSTableColumn+Resize.h"

const NSUInteger kMaxNumberOfArrayEntriesInToolTip = 5;

@interface RLMDocument ()

@property (nonatomic, strong) IBOutlet NSOutlineView *realmTableOutlineView;
@property (nonatomic, strong) IBOutlet NSTableView *realmTableColumnsView;

@end

@implementation RLMDocument {
    RLMRealmNode *presentedRealm;
    RLMObjectNode *selectedObjectNode;
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
                    
                    NSError *error;
                    
                    RLMRealmNode *realm = [[RLMRealmNode alloc] initWithName:realmName
                                                                         url:absoluteURL.path];
                    presentedRealm = realm;
                    
                    if ([realm connect:&error]) {
                        NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
                        [documentController noteNewRecentDocumentURL:absoluteURL];                    
                    }
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

#pragma mark - Public methods - NSDocument overrides - Creating and Managing Window Controllers

- (void)makeWindowControllers
{
    RLMRealmBrowserWindowController *windowController = [[RLMRealmBrowserWindowController alloc] initWithWindowNibName:self.windowNibName
                                                                                                                 owner:self];
    [self addWindowController:windowController];
}

- (NSString *)windowNibName
{
    return @"RLMDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    // Perform some extra inititialization on the tableview
    
    [self.instancesTableView setDelegate:self];
    [self.instancesTableView setDoubleAction:@selector(userDoubleClicked:)];
    
    // We want the class outline to be expandedas default
    [self.classesOutlineView expandItem:nil
                       expandChildren:YES];
    
    // ... and the first class to be selected so something is displayed in the property pane.
    id firstItem = presentedRealm.topLevelClazzes.firstObject;
    if (firstItem != nil) {
        NSInteger index = [self.classesOutlineView rowForItem:firstItem];
        [self.classesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                           byExtendingSelection:NO];
    }
}

#pragma mark - Public methods - NSDocument overrides - Loading Document Data

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // As we do not use the usual file handling mechanism we just returns nil (but it is necessary
    // to override this method as the default implementation throws an exception.
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // As we do not use the usual file handling mechanism we just returns YES (but it is necessary
    // to override this method as the default implementation throws an exception.
    return YES;
}

#pragma mark - Public methods - NSDocument overrides - Managing Document Windows

- (NSString *)displayName {
    if (presentedRealm.name != nil) {
        return presentedRealm.name;
    }
    
    return [super displayName];
}

#pragma mark - NSOutlineViewDataSource implementation

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return presentedRealm;
    }
    // ... and second level nodes are all classes.
    else if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
        id<RLMRealmOutlineNode> outlineItem = item;
        return [outlineItem childNodeAtIndex:index];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    // The root node is expandable if we are presenting a realm
    if (item == nil) {
        return presentedRealm == nil;
    }
    // ... otherwise the exandability check is re-delegated to the node in question.
    else if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
        id<RLMRealmOutlineNode> outlineItem = item;
        return outlineItem.isExpandable;
    }
    
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    // There is always only one root node
    if (item == nil) {
        return 1;
    }
    // ... otherwise the number of child nodes are defined by the node in question.
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

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
{
    // The top level node should not be collapsed.
    return item != presentedRealm;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
    // The top level node should not display the toggle triangle.
    return item != presentedRealm;
}

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
            RLMClazzNode *classNode = (RLMClazzNode *)selectedItem;
            [self updateSelectedObjectNode:classNode];
            return;
        }
        else if ([selectedItem isKindOfClass:[RLMArrayNode class]]) {
            RLMArrayNode *arrayNode = (RLMArrayNode *)selectedItem;
            [self updateSelectedObjectNode:arrayNode];
            return;
        }
    }
    
    [self updateSelectedObjectNode:nil];
}

#pragma mark - NSTableViewDataSource implementation

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.realmTableColumnsView) {
        return selectedObjectNode.instanceCount;
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView == self.realmTableColumnsView) {
        
        NSUInteger columnIndex = [self.realmTableColumnsView.tableColumns
                                  indexOfObject:tableColumn];
        
        RLMClazzProperty *clazzProperty = selectedObjectNode.propertyColumns[columnIndex];
        NSString *propertyName = clazzProperty.name;
        RLMObject *selectedInstance = [selectedObjectNode instanceAtIndex:rowIndex];
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
    if (tableView == self.realmTableColumnsView) {
        NSUInteger columnIndex = [self.realmTableColumnsView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = selectedObjectNode.propertyColumns[columnIndex];
        NSString *propertyName = propertyNode.name;
        
        RLMObject *selectedObject = [selectedObjectNode instanceAtIndex:rowIndex];

        RLMRealm *realm = presentedRealm.realm;

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
    if (tableView == self.realmTableColumnsView) {
        NSUInteger columnIndex = [self.realmTableColumnsView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = selectedObjectNode.propertyColumns[columnIndex];
        
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
                
            case RLMPropertyTypeData: {
                break;
            }

            case RLMPropertyTypeString:
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
        RLMClazzProperty *propertyNode = selectedObjectNode.propertyColumns[columnIndex];

        RLMObject *selectedInstance = [selectedObjectNode instanceAtIndex:row];
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
    if (tableView == self.realmTableColumnsView) {
        NSUInteger columnIndex = [self.realmTableColumnsView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = selectedObjectNode.propertyColumns[columnIndex];
        
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
            
            RLMObject *selectedObject = [selectedObjectNode instanceAtIndex:row];
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
                RLMRealm *realm = presentedRealm.realm;
                
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

- (void)userDoubleClicked:(id)sender
{
    NSInteger column = self.instancesTableView.clickedColumn;
    NSInteger row = self.instancesTableView.clickedRow;
    
    if (column != -1 && row != -1) {
        RLMClazzProperty *propertyNode = selectedObjectNode.propertyColumns[column];
        
        if (propertyNode.type == RLMPropertyTypeObject) {
            RLMObject *selectedInstance = [selectedObjectNode instanceAtIndex:row];
            NSObject *propertyValue = selectedInstance[propertyNode.name];

            if ([propertyValue isKindOfClass:[RLMObject class]]) {
                RLMObject *linkedObject = (RLMObject *)propertyValue;
                RLMObjectSchema *linkedObjectSchema = linkedObject.schema;
                
                for (RLMClazzNode *clazzNode in presentedRealm.topLevelClazzes) {
                    if ([clazzNode.name isEqualToString:linkedObjectSchema.className]) {
                        NSInteger index = [self.classesOutlineView rowForItem:clazzNode];
                        
                        [self.classesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                                             byExtendingSelection:NO];
                        
                        [self updateTableView];
                        
                        // Right now we just fetches the object index from the proxy object.
                        // However, this must be changed later when the proxy object is made public
                        // and provides some mean to retrieve the underlying RLMObject object.
                        // Note: This selection of the linked object does not take any future row
                        // sorting into account!!!
                        NSNumber *indexNumber = [linkedObject valueForKeyPath:@"objectIndex"];
                        NSUInteger instanceIndex = indexNumber.integerValue;

                        if (instanceIndex != NSNotFound) {
                            [self.instancesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:instanceIndex]
                                                 byExtendingSelection:NO];
                        }
                        else {
                            [self.instancesTableView selectRowIndexes:nil
                                                 byExtendingSelection:NO];
                        }
                        
                        break;
                    }
                }
            }
        }
        else if (propertyNode.type == RLMPropertyTypeArray) {
            RLMObject *selectedInstance = [selectedObjectNode instanceAtIndex:row];
            NSObject *propertyValue = selectedInstance[propertyNode.name];
            
            if ([propertyValue isKindOfClass:[RLMArray class]]) {
                RLMArray *linkedArray = (RLMArray *)propertyValue;
        
                RLMClazzNode *selectedClassNode = (RLMClazzNode *)selectedObjectNode;
                
                RLMArrayNode *arrayNode = [selectedClassNode displayChildArray:linkedArray
                                                                  fromProperty:propertyNode.property
                                                                        object:selectedInstance];
                
                [self.classesOutlineView reloadData];
                
                [self.classesOutlineView expandItem:selectedClassNode];
                NSInteger index = [self.classesOutlineView rowForItem:arrayNode];
                if (index != NSNotFound) {
                    [self.classesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                                         byExtendingSelection:NO];
                }

            }
        }
    }
}

#pragma mark - Private methods - Table view construction

- (void)updateSelectedObjectNode:(RLMObjectNode *)outlineNode
{
    selectedObjectNode = outlineNode;

    // How many properties does the clazz contains?
    NSArray *columns = outlineNode.propertyColumns;
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
        
        [self.realmTableColumnsView addTableColumn:tableColumn];
    }
    
    // Set the column names and cell type / formatting
    for (NSUInteger index = 0; index < columns.count; index++) {
        NSTableColumn *tableColumn = self.realmTableColumnsView.tableColumns[index];
    
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

- (void)updateTableView
{
    [self.instancesTableView reloadData];
    for(NSTableColumn *column in self.instancesTableView.tableColumns) {
        [column resizeToFitContents];
    }
}

@end
