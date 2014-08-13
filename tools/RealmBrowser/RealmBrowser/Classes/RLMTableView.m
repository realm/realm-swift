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



@interface RLMTableHeaderView : NSTableHeaderView

@end


@implementation RLMTableHeaderView

-(void)rightMouseDown:(NSEvent *)theEvent
{
    [self.tableView rightMouseDown:theEvent];
    [super rightMouseDown:theEvent];
}

@end


@implementation RLMTableView {
    NSTrackingArea *trackingArea;
    BOOL mouseOverView;
    RLMTableLocation currentMouseLocation;
    RLMTableLocation previousMouseLocation;
}

#pragma mark - NSObject overrides

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

-(void)createContextMenu
{
    unichar backspaceKey = NSBackspaceCharacter;

    NSMenu *rightClickMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];

    NSMenuItem *addColumnItem = [rightClickMenu insertItemWithTitle:@"Add column" action:@selector(addColumns) keyEquivalent:@"+" atIndex:0];
    addColumnItem.tag = 7;
    addColumnItem.keyEquivalentModifierMask = NSCommandKeyMask | NSAlternateKeyMask;
    addColumnItem.target = self;
    
    NSMenuItem *deleteColumnItem = [rightClickMenu insertItemWithTitle:@"Delete column" action:@selector(deleteColumns) keyEquivalent:[NSString stringWithCharacters:&backspaceKey length:1] atIndex:1];
    deleteColumnItem.tag = 8;
    deleteColumnItem.keyEquivalentModifierMask = NSCommandKeyMask | NSAlternateKeyMask;
    deleteColumnItem.target = self;
    
    self.headerView.menu = [rightClickMenu copy];
    
    NSMenuItem *addRowItem = [rightClickMenu insertItemWithTitle:@"Add row" action:@selector(addRows) keyEquivalent:@"+" atIndex:2];
    addRowItem.tag = 5;
    
    NSMenuItem *deleteRowItem = [rightClickMenu insertItemWithTitle:@"Delete row" action:@selector(deleteRows) keyEquivalent:[NSString stringWithCharacters:&backspaceKey length:1] atIndex:3];
    deleteRowItem.tag = 6;
    
    [self setMenu:rightClickMenu];
}

- (void)dealloc
{
    [self removeTrackingArea:trackingArea];
}

#pragma mark - NSResponder overrides

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
    
    if (location.row == -2 && location.column >= 0 && location.column < self.tableColumns.count) {
        [(id<RLMTableViewDelegate>)self.delegate rightClickedHeaderColumn:location.column];
        return;
    }
    
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
    if (theEvent.modifierFlags & NSCommandKeyMask & !NSAlternateKeyMask) {
        if (theEvent.keyCode == 27) {
            [self addRows];
        }
        else if (theEvent.keyCode == 51) {
            [self deleteRows];
        }
    }
    
    [self interpretKeyEvents:@[theEvent]];
}

#pragma mark - Menu handling

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL canDeleteRows = self.selectedRowIndexes.count > 0;
    BOOL multipleRows = self.selectedRowIndexes.count > 1;
    BOOL canDeleteColumns = self.selectedColumnIndexes.count > 0;
    BOOL multipleColumns = self.selectedColumnIndexes.count > 1;
    
    switch (menuItem.tag) {
        case 1: // Tools -> Add row
        case 5: // Context -> Add row
            menuItem.title = multipleRows ? @"Add rows" : @"Add row";
            return YES;
            
        case 2: // Tools -> Delete row
        case 6: // Context -> Delete row
            menuItem.title = multipleRows ? @"Delete rows" : @"Delete row";
            return canDeleteRows;

        case 3: // Tools -> Add column
        case 7: // Context -> Add column
            return YES;
        
        case 4: // Tools -> Delete column
        case 8: // Context -> Delete column
            menuItem.title = multipleColumns ? @"Delete columns" : @"Delete column";
            return canDeleteColumns;
            
        default:
            return YES;
    }
}

- (IBAction)menuAddRow:(id)sender
{
    [self addRows];
}

- (IBAction)menuDeleteRow:(id)sender
{
    [self deleteRows];
}

- (IBAction)menuAddColumn:(id)sender
{
    [self addColumns];
}

- (IBAction)menuDeleteColumn:(id)sender
{
    [self deleteColumns];
}

#pragma mark - Helper methods

-(void)addRows
{
    if ([self.delegate respondsToSelector:@selector(addRows:)]) {
        [(id<RLMTableViewDelegate>)self.delegate addRows:self.selectedRowIndexes];
    }
}

-(void)deleteRows
{
    if ([self.delegate respondsToSelector:@selector(deleteRows:)]) {
        [(id<RLMTableViewDelegate>)self.delegate deleteRows:self.selectedRowIndexes];
    }
}

-(void)addColumns
{
    if ([self.delegate respondsToSelector:@selector(addColumns:)]) {
        [(id<RLMTableViewDelegate>)self.delegate addColumns:self.selectedColumnIndexes];
    }
}

-(void)deleteColumns
{
    if ([self.delegate respondsToSelector:@selector(deleteColumns:)]) {
        [(id<RLMTableViewDelegate>)self.delegate deleteColumns:self.selectedColumnIndexes];
    }
}

#pragma mark - NSView overrides

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    [self removeTrackingArea:trackingArea];
    int opts = (NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:opts owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
}

#pragma mark - Public methods

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

#pragma mark - Private methods - Cell geometry 

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





