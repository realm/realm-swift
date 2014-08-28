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

#import "RLMTableView.h"
#import "RLMTableColumn.h"
#import "RLMArrayNode.h"

@interface RLMTableView()<NSMenuDelegate>

@end

@implementation RLMTableView {
    NSTrackingArea *trackingArea;
    BOOL mouseOverView;
    RLMTableLocation currentMouseLocation;
    RLMTableLocation previousMouseLocation;
    NSMenuItem *clickLockItem;
    NSMenuItem *addRowItem;
    NSMenuItem *deleteRowItem;
    NSMenuItem *insertIntoArrayItem;
    NSMenuItem *removeFromArrayItem;
    NSMenuItem *removeLinkToObjectItem;
    NSMenuItem *removeLinkToArrayItem;
}

#pragma mark - NSObject Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];

    int options = NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited
    | NSTrackingMouseMoved | NSTrackingCursorUpdate;
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    mouseOverView = NO;
    currentMouseLocation = RLMTableLocationUndefined;
    previousMouseLocation = RLMTableLocationUndefined;
    
    [self createContextMenu];
}

- (void)dealloc
{
    [self removeTrackingArea:trackingArea];
}

#pragma mark - Public methods - Accessors

-(id<RLMTableViewDelegate>)realmDelegate
{
    return (id<RLMTableViewDelegate>)self.delegate;
}

#pragma mark - Private Methods - NSObject Overrides

-(void)createContextMenu
{
    NSMenu *rightClickMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
    self.menu = rightClickMenu;
    self.menu.delegate = self;

    unichar backspaceKey = NSBackspaceCharacter;
    NSString *backspaceString = [NSString stringWithCharacters:&backspaceKey length:1];

    clickLockItem = [[NSMenuItem alloc] initWithTitle:@"Click lock icon to edit"
                                               action:nil
                                        keyEquivalent:@""];
    clickLockItem.tag = 99;

    addRowItem = [[NSMenuItem alloc] initWithTitle:@"Add row"
                                            action:@selector(selectedAddRow:)
                                     keyEquivalent:@"+"];
    addRowItem.tag = 5;
    
    deleteRowItem = [[NSMenuItem alloc] initWithTitle:@"Delete row"
                                               action:@selector(selectedDeleteRow:)
                                        keyEquivalent:backspaceString];
    deleteRowItem.tag = 6;
    
    insertIntoArrayItem = [[NSMenuItem alloc] initWithTitle:@"Insert row into array"
                                                     action:@selector(selectedInsertRow:)
                                              keyEquivalent:@"+"];
    insertIntoArrayItem.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask;
    insertIntoArrayItem.tag = 9;

    removeFromArrayItem = [[NSMenuItem alloc] initWithTitle:@"Remove row from array"
                                                     action:@selector(selectedRemoveRow:)
                                              keyEquivalent:backspaceString];
    removeFromArrayItem.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask;
    removeFromArrayItem.tag = 10;

    removeLinkToObjectItem= [[NSMenuItem alloc] initWithTitle:@"Remove link to object"
                                                       action:@selector(selectedRemoveObjectLink:)
                                              keyEquivalent:@""];
    removeLinkToObjectItem.tag = 11;

    removeLinkToArrayItem = [[NSMenuItem alloc] initWithTitle:@"Remove link to array"
                                                     action:@selector(selectedRemoveArrayLink:)
                                              keyEquivalent:@""];
    removeLinkToArrayItem.tag = 12;
}

#pragma mark - NSResponder Overrides

- (void)cursorUpdate:(NSEvent *)event
{
    // Note: This method is left empty intentionally. It avoids cursor events to be passed on up
    //       the responder chain where it potentially could reach a displayed tool-tip view, which
    //       will undo any modification to the cursor image dome by the application. This "fix" is
    //       in order to circumvent a bug in OS X version prior to 10.10 Yosemite not honouring
    //       the NSTrackingActiveAlways option even when the cursorRect has been disabled.
    //       IMPORTANT: Must NOT be deleted!!!
}

- (void)mouseEntered:(NSEvent*)event
{
    mouseOverView = YES;
    
    if ([self.delegate respondsToSelector:@selector(mouseDidEnterView:)]) {
        [(id<RLMTableViewDelegate>)self.delegate mouseDidEnterView:self];
    }
}

- (void)mouseMoved:(NSEvent *)event
{
    id myDelegate = [self delegate];
    
    if (!myDelegate) {
        return; // No delegate, no need to track the mouse.
    }

    if (mouseOverView) {
        currentMouseLocation = [self currentLocationAtPoint:[event locationInWindow]];
		
        if (RLMTableLocationEqual(previousMouseLocation, currentMouseLocation)) {
            return;
        }
        else {
            if ([self.delegate respondsToSelector:@selector(mouseDidExitCellAtLocation:)]) {
                [(id<RLMTableViewDelegate>)self.delegate mouseDidExitCellAtLocation:previousMouseLocation];
            }

            CGRect cellRect = [self rectOfLocation:previousMouseLocation];
            [self setNeedsDisplayInRect:cellRect];

            previousMouseLocation = currentMouseLocation;

            if ([self.delegate respondsToSelector:@selector(mouseDidEnterCellAtLocation:)]) {
                [(id<RLMTableViewDelegate>)self.delegate mouseDidEnterCellAtLocation:currentMouseLocation];
            }
        }

        CGRect cellRect = [self rectOfLocation:currentMouseLocation];
        [self setNeedsDisplayInRect:cellRect];
    }
}

-(void)rightMouseDown:(NSEvent *)theEvent
{
    RLMTableLocation location = [self currentLocationAtPoint:[theEvent locationInWindow]];
    
    if ([self.delegate respondsToSelector:@selector(rightClickedLocation:)]) {
        [(id<RLMTableViewDelegate>)self.delegate rightClickedLocation:location];
    }
    [super rightMouseDown:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    mouseOverView = NO;
    
    CGRect cellRect = [self rectOfLocation:currentMouseLocation];
    [self setNeedsDisplayInRect:cellRect];
    
    currentMouseLocation = RLMTableLocationUndefined;
    previousMouseLocation = RLMTableLocationUndefined;
    
    if ([self.delegate respondsToSelector:@selector(mouseDidExitView:)]) {
        [(id<RLMTableViewDelegate>)self.delegate mouseDidExitView:self];
    }
}

-(void)keyDown:(NSEvent *)theEvent
{
    if (theEvent.modifierFlags & NSCommandKeyMask & !NSAlternateKeyMask & !NSShiftKeyMask) {
        if (theEvent.keyCode == 27) {
            [self selectedAddRow:theEvent];
        }
        else if (theEvent.keyCode == 51) {
            [self selectedDeleteRow:theEvent];
        }
    }
    else if (theEvent.modifierFlags & NSCommandKeyMask & !NSAlternateKeyMask & NSShiftKeyMask) {
        if (theEvent.keyCode == 27) {
            [self selectedInsertRow:theEvent];
        }
        else if (theEvent.keyCode == 51) {
            [self selectedRemoveRow:theEvent];
        }
    }
    
    [self interpretKeyEvents:@[theEvent]];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL multipleRows = self.selectedRowIndexes.count > 1;
    BOOL canEditRows = !self.realmDelegate.realmIsLocked;
    BOOL canDeleteRows = self.selectedRowIndexes.count > 0 && canEditRows;
    BOOL displaysArray = self.realmDelegate.displaysArray;

    switch (menuItem.tag) {
        case 1: // Tools -> Add row
        case 5: // Context -> Add row
            menuItem.title = multipleRows ? @"Add objects" : @"Add object";
            return canEditRows && !displaysArray;
            
        case 2: // Tools -> Delete row
        case 6: // Context -> Delete row
            menuItem.title = multipleRows ? @"Delete objects" : @"Delete object";
            return canDeleteRows;

        case 9: // Context -> Insert row into array
            menuItem.title = multipleRows ? @"Insert objects into array" : @"Insert object into array";
            return canEditRows && displaysArray;

        case 10: // Context -> Remove row from array
            menuItem.title = multipleRows ? @"Remove objects from array" : @"Remove object from array";
            return canDeleteRows && displaysArray;

        case 11: // Context -> Remove row from array
            menuItem.title = multipleRows ? @"Remove links to objects" : @"Remove link to object";
            return YES;

        case 12: // Context -> Remove row from array
            menuItem.title = multipleRows ? @"Remove links to arrays" : @"Remove link to array";
            return YES;

        case 99: // Context -> Click lock icon to edit
            return NO;

        default:
            return YES;
    }
}

#pragma mark - NSMenu Delegate

-(void)menuNeedsUpdate:(NSMenu *)menu
{
    [self.menu removeAllItems];
    
    if (self.realmDelegate.realmIsLocked) {
        [self.menu addItem:clickLockItem];
        return;
    }
    
    if (self.selectedRowIndexes.count == 0) {
        return;
    }
    
    [self.menu addItem:deleteRowItem];

    if (self.realmDelegate.displaysArray) {
        [self.menu addItem:removeFromArrayItem];
    }

    if (self.clickedColumn == -1) {
        return;
    }
    
    if ([self.realmDelegate containsObjectInRows:self.selectedRowIndexes column:self.clickedColumn]) {
        [self.menu addItem:removeLinkToObjectItem];
    }
    else if ([self.realmDelegate containsArrayInRows:self.selectedRowIndexes column:self.clickedColumn]) {
        [self.menu addItem:removeLinkToArrayItem];
    }
}

#pragma mark - First Responder User Actions

- (IBAction)selectedAddRow:(id)sender
{
    if (!self.realmDelegate.realmIsLocked) {
        [self.realmDelegate addRows:self.selectedRowIndexes];
    }
}

- (IBAction)selectedDeleteRow:(id)sender
{
    if (!self.realmDelegate.realmIsLocked) {
        [self.realmDelegate deleteRows:self.selectedRowIndexes];
    }
}

- (IBAction)selectedRemoveRow:(id)sender
{
    if (self.realmDelegate.displaysArray && !self.realmDelegate.realmIsLocked) {
        [self.realmDelegate removeRows:self.selectedRowIndexes];
    }
}

- (IBAction)selectedInsertRow:(id)sender
{
    if (self.realmDelegate.displaysArray && !self.realmDelegate.realmIsLocked) {
        [self.realmDelegate insertRows:self.selectedRowIndexes];
    }
}

- (IBAction)selectedRemoveObjectLink:(id)sender
{
    if (!self.realmDelegate.realmIsLocked) {
        [self.realmDelegate removeArrayLinks:self.selectedRowIndexes inColumn:self.clickedColumn];
    }
}

- (IBAction)selectedRemoveArrayLink:(id)sender
{
    if (!self.realmDelegate.realmIsLocked) {
        [self.realmDelegate removeObjectLinks:self.selectedRowIndexes inColumn:self.clickedColumn];
    }
}

#pragma mark - NSView Overrides

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    [self removeTrackingArea:trackingArea];
    int opts = NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved;
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:opts owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
}

#pragma mark - Public Methods

- (void)formatColumnsWithType:(RLMTypeNode *)typeNode withSelectionAtRow:(NSUInteger)selectionIndex
{
    // We clear the table view from all old columns
    NSUInteger existingColumnsCount = self.numberOfColumns;
    for (NSUInteger index = 0; index < existingColumnsCount; index++) {
        NSTableColumn *column = [self.tableColumns lastObject];
        [self removeTableColumn:column];
    }
    
    // If array, add extra first column with numbers
    if ([typeNode isMemberOfClass:[RLMArrayNode class]]) {
        RLMTableColumn *tableColumn = [[RLMTableColumn alloc] initWithIdentifier:@"#"];
        tableColumn.headerToolTip = @"Position of object within array";
        tableColumn.propertyType = RLMPropertyTypeInt;
        [self addTableColumn:tableColumn];
        [tableColumn.headerCell setStringValue:@"#"];
    }
    
    // ... and add new columns matching the structure of the new realm table.
    NSArray *columns = typeNode.propertyColumns;

    for (NSUInteger index = 0; index < columns.count; index++) {
        RLMClassProperty *property = columns[index];
        RLMTableColumn *tableColumn = [[RLMTableColumn alloc] initWithIdentifier:property.name];
        tableColumn.propertyType = property.type;
        [self addTableColumn:tableColumn];

        [tableColumn.headerCell setStringValue:property.name];

        NSString *toolTip;
        switch (property.type) {
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
                toolTip = [NSString stringWithFormat:@"%@[]", property.property.objectClassName];
                break;
                
            case RLMPropertyTypeObject:
                toolTip = [NSString stringWithFormat:@"%@", property.property.objectClassName];
                break;
        }
        
        tableColumn.headerToolTip = toolTip;
    }
    
    [self reloadData];
}

#pragma mark - Private Methods - Column widths

-(void)makeColumnsFitContents
{
    for (RLMTableColumn *column in self.tableColumns) {
        column.width = [column sizeThatFitsWithLimit:YES];
    }
}

#pragma mark - Private Methods - Cell geometry

- (RLMTableLocation)currentLocationAtPoint:(NSPoint)point
{
    NSPoint localPointInTable = [self convertPoint:point fromView:nil];
    
    NSInteger row = [self rowAtPoint:localPointInTable];
    NSInteger column = [self columnAtPoint:localPointInTable];
    
    NSPoint localPointInHeader = [self.headerView convertPoint:point fromView:nil];
    if (NSPointInRect(localPointInHeader, self.headerView.bounds)) {
        row = -2;
        column = [self columnAtPoint:localPointInHeader];
    }
    
    return RLMTableLocationMake(row, column);
}

- (CGRect)rectOfLocation:(RLMTableLocation)location
{
    CGRect rowRect = [self rectOfRow:location.row];
    CGRect columnRect = [self rectOfColumn:location.column];
    
    return CGRectIntersection(rowRect, columnRect);
}

@end