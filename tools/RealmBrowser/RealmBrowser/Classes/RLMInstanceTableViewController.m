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
        [(RLMTableView *)self.tableView formatColumnsToFitType:newState.selectedType withSelectionAtRow:newState.selectedInstanceIndex];
        [self setSelectionIndex:newState.selectedInstanceIndex];
    }
    else if ([newState isMemberOfClass:[RLMArrayNavigationState class]]) {
        RLMArrayNavigationState *arrayState = (RLMArrayNavigationState *)newState;
        
        RLMClazzNode *referringType = (RLMClazzNode *)arrayState.selectedType;
        RLMObject *referingInstance = [referringType instanceAtIndex:arrayState.selectedInstanceIndex];
        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithReferringProperty:arrayState.property
                                                                         onObject:referingInstance
                                                                            realm:self.parentWindowController.modelDocument.presentedRealm.realm];
        self.displayedType = arrayNode;
        [self.tableView reloadData];
        [(RLMTableView *)self.tableView formatColumnsToFitType:arrayNode withSelectionAtRow:0];
        [self setSelectionIndex:arrayState.arrayIndex];
    }
    else if ([newState isMemberOfClass:[RLMQueryNavigationState class]]) {
        RLMQueryNavigationState *arrayState = (RLMQueryNavigationState *)newState;

        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithQuery:arrayState.searchText result:arrayState.results andParent:arrayState.selectedType];

        self.displayedType = arrayNode;
        [self.tableView reloadData];
        [(RLMTableView *)self.tableView formatColumnsToFitType:arrayNode withSelectionAtRow:0];
        [self setSelectionIndex:0];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.tableView) {
        RLMTypeNode *displayedType = self.displayedType;
        return displayedType.instanceCount;
    }
    
    return 0;
}

#pragma mark - RLMTableViewDelegate implementation

- (void)menuSelectedDeleteRow:(RLMTableLocation)location
{
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
        
    if (location.row >= self.displayedType.instanceCount || RLMTableLocationRowIsUndefined(location)) {
        return;
    }
    
    RLMObject *selectedObject = [self.displayedType instanceAtIndex:location.row];
    [realm beginWriteTransaction];
    [realm deleteObject:selectedObject];
    [realm commitWriteTransaction];
    [self.tableView reloadData];
}

- (void)menuSelectedAddRow:(RLMTableLocation)location
{
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    RLMTypeNode *displayedType = self.displayedType;
    Class rlmObjectClass = NSClassFromString(displayedType.name);
    NSDictionary *defaultPropertyValues = [rlmObjectClass defaultPropertyValues];
    if (!defaultPropertyValues) {
        defaultPropertyValues = [self defaultPropertyValuesForTypeNode:displayedType];
    }
    
    [realm beginWriteTransaction];
    [rlmObjectClass createInRealm:realm withObject:defaultPropertyValues];
    [realm commitWriteTransaction];
    
    [self.tableView reloadData];
}

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
            return @"===STRING===";
            
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
        
        RLMNavigationState *currentState = self.parentWindowController.currentState;
        NSInteger selectedIndex = self.tableView.selectedRow;
        
        [currentState updateSelectionToIndex:selectedIndex];
    }
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    
    if (tableView == self.tableView) {
        NSUInteger columnIndex = [tableView.tableColumns indexOfObject:tableColumn];
        RLMTypeNode *displayedType = self.displayedType;
        NSLog(@"vftc:%lu, dt.c:%lu tableColumns: %lu", columnIndex, displayedType.propertyColumns.count, tableView.tableColumns.count);

        RLMClazzProperty *clazzProperty = displayedType.propertyColumns[columnIndex];
        RLMObject *selectedInstance = [displayedType instanceAtIndex:rowIndex];
        id propertyValue = selectedInstance[clazzProperty.name];
        RLMPropertyType type = clazzProperty.type;
        
        if (type == RLMPropertyTypeArray) {
            RLMBadgeTableCellView *badgeCellView = [tableView makeViewWithIdentifier:@"BadgeCell" owner:self];
            
            badgeCellView.badge.hidden = NO;
            badgeCellView.badge.title = [NSString stringWithFormat:@"%lu", (unsigned long)[(RLMArray *)propertyValue count]];
            [badgeCellView.badge.cell setHighlightsBy:0];
            
            NSString *formattedText = [self printablePropertyValue:propertyValue ofType:type];
            badgeCellView.textField.attributedStringValue = [self.class linkStringWithString:formattedText];
            
            return badgeCellView;
        }
        else if (type == RLMPropertyTypeBool) {
            RLMBoolTableCellView *boolCellView = [tableView makeViewWithIdentifier:@"BoolCell" owner:self];
            
            BOOL boolValue;
            if ([propertyValue isKindOfClass:[NSNumber class]]) {
                boolValue = [(NSNumber *)propertyValue boolValue];
            }
            boolCellView.checkBox.state = boolValue ? NSOnState : NSOffState;
            
            return boolCellView;
        }
        else if (type == RLMPropertyTypeInt || type == RLMPropertyTypeFloat || type == RLMPropertyTypeDouble) {
            RLMNumberTableCellView *numberCellView = [tableView makeViewWithIdentifier:@"NumberCell" owner:self];
            numberCellView.textField.stringValue = [self printablePropertyValue:propertyValue ofType:type];
            
            ((RLMNumberTextField *)numberCellView.textField).number = propertyValue;
            
            return numberCellView;
        }
//        else if (type == RLMPropertyTypeData) {
//            NSTableCellView *imageCellView = [tableView makeViewWithIdentifier:@"ImageCell" owner:self];
//            
//            imageCellView.textField.stringValue = @"imagecell";
//            
//            if (tempImage) {
//                NSLog(@"== Already had one ==");
//                imageCellView.imageView.image = tempImage;
//                return imageCellView;
//            }
//            
//            NSData *data = propertyValue;
//
//            NSString *content = [self.class contentTypeForImageData:data];
//            imageCellView.textField.stringValue = content;
//            
//            NSLog(@"=====%ld datacontent: %@", (long)rowIndex, content);
//
//            NSImage *image = [[NSImage alloc] initWithData:data];
//            NSImage *thumbnail = RLMThumbnailImageFromImage(image);
//            NSLog(@"======%ld image: %@", (long)rowIndex, thumbnail);
//            
//            tempImage = thumbnail;
//            imageCellView.imageView.image = thumbnail;
//            
//            return imageCellView;
//        }
        else {
            RLMBasicTableCellView *basicCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            
            NSString *formattedText = [self printablePropertyValue:propertyValue ofType:type];
            
            if (type == RLMPropertyTypeObject) {
                basicCellView.textField.attributedStringValue = [self.class linkStringWithString:formattedText];
            }
            else {
                basicCellView.textField.stringValue = formattedText;
            }
            
            return basicCellView;
        }
    }
    
    return nil;
}

//+ (NSString *)contentTypeForImageData:(NSData *)data
//{
//    uint8_t c;
//    [data getBytes:&c length:1];
//    
//    switch (c) {
//        case 0xFF:
//            return @"image/jpeg";
//        case 0x89:
//            return @"image/png";
//        case 0x47:
//            return @"image/gif";
//        case 0x49:
//        case 0x4D:
//            return @"image/tiff";
//    }
//    
//    return nil;
//}

//static NSImage *RLMThumbnailImageFromImage(NSImage *image) {
//    NSSize imageSize = [image size];
//    CGFloat imageAspectRatio = imageSize.width/imageSize.height;
//    
//    NSSize thumbnailSize = NSMakeSize(30.0 * imageAspectRatio, 30.0);
//    NSImage *thumbnailImage = [[NSImage alloc] initWithSize:thumbnailSize];
//    [thumbnailImage lockFocus];
//    [image drawInRect:NSMakeRect(0, 0, thumbnailSize.width, thumbnailSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//    [thumbnailImage unlockFocus];
//    
//    return thumbnailImage;
//}


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

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
    if (tableView == self.tableView) {
        RLMTypeNode *displayedType = self.displayedType;
        
        NSUInteger columnIndex = [self.tableView.tableColumns indexOfObject:tableColumn];
        RLMClazzProperty *propertyNode = displayedType.propertyColumns[columnIndex];
        
        RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
        NSObject *propertyValue = selectedInstance[propertyNode.name];
        
        switch (propertyNode.type) {
            case RLMPropertyTypeDate: {
                if ([propertyValue isKindOfClass:[NSDate class]]) {
                    return [dateFormatter stringFromDate:(NSDate *)propertyValue];
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

#pragma mark - Mouse movement

- (void)mouseDidEnterCellAtLocation:(RLMTableLocation)location
{
    if (!(RLMTableLocationColumnIsUndefined(location) || RLMTableLocationRowIsUndefined(location))) {
        RLMTypeNode *displayedType = self.displayedType;
        
        if (location.column < displayedType.propertyColumns.count && location.row < displayedType.instanceCount) {
            RLMClazzProperty *propertyNode = displayedType.propertyColumns[location.column];
            
            if (propertyNode.type == RLMPropertyTypeObject) {
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
    RLMClazzProperty *propertyNode = displayedType.propertyColumns[column];
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
    RLMClazzProperty *propertyNode = displayedType.propertyColumns[column];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:row];

    NSNumber *result = @((BOOL)(sender.state == NSOnState));

    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    [realm beginWriteTransaction];
    selectedInstance[propertyNode.name] = result;
    [realm commitWriteTransaction];
}

- (void)userClicked:(NSTableView *)sender
{
    NSInteger column = self.tableView.clickedColumn;
    NSInteger row = self.tableView.clickedRow;
    
    if (column != -1 && row != -1) {
        RLMTypeNode *displayedType = self.displayedType;
        RLMClazzProperty *propertyNode = displayedType.propertyColumns[column];
        
        if (propertyNode.type == RLMPropertyTypeObject) {
            RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
            id propertyValue = selectedInstance[propertyNode.name];
            
            if ([propertyValue isKindOfClass:[RLMObject class]]) {
                RLMObject *linkedObject = (RLMObject *)propertyValue;
                RLMObjectSchema *linkedObjectSchema = linkedObject.objectSchema;
                
                for (RLMClazzNode *clazzNode in self.parentWindowController.modelDocument.presentedRealm.topLevelClazzes) {
                    if ([clazzNode.name isEqualToString:linkedObjectSchema.className]) {
                        RLMArray *allInstances = [linkedObject.realm allObjects:linkedObjectSchema.className];
                        NSUInteger objectIndex = [allInstances indexOfObject:linkedObject];
                        
                        RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:clazzNode index:objectIndex];
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
}

- (void)userDoubleClicked:(NSTableView *)sender {
    NSInteger column = self.tableView.clickedColumn;
    NSInteger row = self.tableView.clickedRow;
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClazzProperty *propertyNode = displayedType.propertyColumns[column];
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
