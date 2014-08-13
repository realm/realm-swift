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

#import "NSTableColumn+Resize.h"

@interface RLMTableView()<NSMenuDelegate>

@end

@implementation RLMTableView {
    NSTrackingArea *trackingArea;
    BOOL mouseOverView;
    RLMTableLocation currentMouseLocation;
    RLMTableLocation previousMouseLocation;
    NSMenuItem *removeFromArrayItem;
}

#pragma mark - NSObject Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];

    int options = (NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingCursorUpdate);
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

#pragma mark - Private Methods - NSObject Overrides

-(void)createContextMenu
{
    unichar backspaceKey = NSBackspaceCharacter;

    NSMenu *rightClickMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
    
    NSMenuItem *addRowItem = [rightClickMenu insertItemWithTitle:@"Add row" action:@selector(addRows) keyEquivalent:@"+" atIndex:0];
    addRowItem.tag = 5;
    
    NSMenuItem *deleteRowItem = [rightClickMenu insertItemWithTitle:@"Delete row" action:@selector(deleteRows) keyEquivalent:[NSString stringWithCharacters:&backspaceKey length:1] atIndex:1];
    deleteRowItem.tag = 6;
    
    removeFromArrayItem = [[NSMenuItem alloc] initWithTitle:@"Remove row from array" action:@selector(removeRows) keyEquivalent:[NSString stringWithCharacters:&backspaceKey length:1]];
    removeFromArrayItem.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask;
    removeFromArrayItem.tag = 9;

    self.menu = rightClickMenu;
    self.menu.delegate = self;
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
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(mouseDidEnterView:)]) {
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
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(mouseDidExitCellAtLocation:)]) {
                [(id<RLMTableViewDelegate>)self.delegate mouseDidExitCellAtLocation:previousMouseLocation];
            }

            CGRect cellRect = [self rectOfLocation:previousMouseLocation];
            [self setNeedsDisplayInRect:cellRect];

            previousMouseLocation = currentMouseLocation;

            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(mouseDidEnterCellAtLocation:)]) {
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
    
    [(id<RLMTableViewDelegate>)self.delegate rightClickedLocation:location];
    
    [super rightMouseDown:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    mouseOverView = NO;
    
    CGRect cellRect = [self rectOfLocation:currentMouseLocation];
    [self setNeedsDisplayInRect:cellRect];
    
    currentMouseLocation = RLMTableLocationUndefined;
    previousMouseLocation = RLMTableLocationUndefined;
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(mouseDidExitView:)]) {
        [(id<RLMTableViewDelegate>)self.delegate mouseDidExitView:self];
    }
}

-(void)keyDown:(NSEvent *)theEvent
{
    if (theEvent.modifierFlags & NSCommandKeyMask & !NSAlternateKeyMask & !NSShiftKeyMask) {
        if (theEvent.keyCode == 27) {
            [self addRows];
        }
        else if (theEvent.keyCode == 51) {
            [self deleteRows];
        }
    }
    else if (theEvent.modifierFlags & NSCommandKeyMask & !NSAlternateKeyMask & NSShiftKeyMask) {
        if (theEvent.keyCode == 51) {
            [self removeRows];
        }
    }
    
    [self interpretKeyEvents:@[theEvent]];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL canEditRows = ![(id<RLMTableViewDelegate>)self.delegate realmIsLocked];
    BOOL canDeleteRows = self.selectedRowIndexes.count > 0 && canEditRows;
    BOOL displaysArray = [(id<RLMTableViewDelegate>)self.delegate displaysArray];

    switch (menuItem.tag) {
        case 1: // Tools -> Add row
        case 5: // Context -> Add row
            return canEditRows && !displaysArray;
            
        case 2: // Tools -> Delete row
        case 6: // Context -> Delete row
            return canDeleteRows;

        case 9: // Context -> Remove row from array
            return canDeleteRows && displaysArray;
            
        default:
            return YES;
    }
}

#pragma mark - NSMenu Delegate

-(void)menuNeedsUpdate:(NSMenu *)menu
{
    BOOL displaysArray = [(id<RLMTableViewDelegate>)self.delegate displaysArray];
    BOOL multipleRows = self.selectedRowIndexes.count > 1;
    
    for (NSMenuItem *menuItem in menu.itemArray) {
        switch (menuItem.tag) {
            case 1: // Tools -> Add row
            case 5: // Context -> Add row
                menuItem.title = multipleRows ? @"Add objects" : @"Add object";
                break;
                
            case 2: // Tools -> Delete row
            case 6: // Context -> Delete row
                menuItem.title = multipleRows ? @"Delete objects" : @"Delete object";
                break;
                
            case 9: // Context -> Delete row
                menuItem.title = multipleRows ? @"Remove objects from array" : @"Remove object from array";
                break;
        }
    }
    
    BOOL containsRemoveFromArrayItem = [menu.itemArray containsObject:removeFromArrayItem];

    if (displaysArray && !containsRemoveFromArrayItem) {
        [self.menu addItem:removeFromArrayItem];
    } else if (!displaysArray && containsRemoveFromArrayItem) {
        [self.menu removeItem:removeFromArrayItem];
    }
}

#pragma mark - First Responder User Actions

- (IBAction)menuAddRow:(id)sender
{
    [self addRows];
}

- (IBAction)menuDeleteRow:(id)sender
{
    [self deleteRows];
}

- (IBAction)menuRemoveRow:(id)sender
{
    [self removeRows];
}

#pragma mark - Private Methods - User Actions

-(void)addRows
{
    if ([self.delegate respondsToSelector:@selector(addRows:)] && ![(id<RLMTableViewDelegate>)self.delegate realmIsLocked]) {
        [(id<RLMTableViewDelegate>)self.delegate addRows:self.selectedRowIndexes];
    }
}

-(void)deleteRows
{
    if ([self.delegate respondsToSelector:@selector(deleteRows:)] && ![(id<RLMTableViewDelegate>)self.delegate realmIsLocked]) {
        [(id<RLMTableViewDelegate>)self.delegate deleteRows:self.selectedRowIndexes];
    }
}

-(void)removeRows
{
    if ([self.delegate respondsToSelector:@selector(removeRows:)] && ![(id<RLMTableViewDelegate>)self.delegate realmIsLocked]) {
        [(id<RLMTableViewDelegate>)self.delegate removeRows:self.selectedRowIndexes];
    }
}

#pragma mark - NSView Overrides

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    [self removeTrackingArea:trackingArea];
    int opts = (NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:opts owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
}

#pragma mark - Public Methods

- (void)formatColumnsToFitType:(RLMTypeNode *)typeNode withSelectionAtRow:(NSUInteger)selectionIndex
{
    // How many properties does the class contains?
    NSArray *columns = typeNode.propertyColumns;
    NSUInteger columnCount = columns.count;
    
    // We clear the table view from all old columns
    NSUInteger existingColumnsCount = self.numberOfColumns;
    for (NSUInteger index = 0; index < existingColumnsCount; index++) {
        NSTableColumn *column = [self.tableColumns lastObject];
        [self removeTableColumn:column];
    }
    
    // ... and add new columns matching the structure of the new realm table.
    for (NSUInteger index = 0; index < columnCount; index++) {
        NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"Column #%lu", existingColumnsCount + index]];
        
        [self addTableColumn:tableColumn];
    }
    
    // Set the column names and cell type / formatting
    for (NSUInteger index = 0; index < columns.count; index++) {
        NSTableColumn *tableColumn = self.tableColumns[index];
        
        RLMClassProperty *property = columns[index];
        [[tableColumn headerCell] setStringValue:property.name];

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
                toolTip = [NSString stringWithFormat:@"%@[..]", property.property.objectClassName];
                break;
                
            case RLMPropertyTypeObject:
                toolTip = [NSString stringWithFormat:@"%@", property.property.objectClassName];
                break;
        }
        
        tableColumn.headerToolTip = toolTip;
    }
    
    [self reloadData];
    for (NSTableColumn *column in self.tableColumns) {
        [column resizeToFitContents];
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





