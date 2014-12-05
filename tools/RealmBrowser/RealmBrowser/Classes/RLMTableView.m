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
#import "RLMTableHeaderCell.h"
#import "RLMDescriptions.h"

const NSInteger NOT_A_COLUMN = -1;

@interface RLMTableView()<NSMenuDelegate>

@end

@implementation RLMTableView {
    NSTrackingArea *trackingArea;
    RLMTableLocation currentMouseLocation;
    RLMTableLocation previousMouseLocation;

    NSMenuItem *clickLockItem;

    NSMenuItem *deleteObjectItem;

    NSMenuItem *removeFromArrayItem;
    NSMenuItem *deleteRowItem;
    NSMenuItem *insertIntoArrayItem;
    
    NSMenuItem *removeLinkToObjectItem;
    NSMenuItem *removeLinkToArrayItem;
    
    NSMenuItem *openArrayInNewWindowItem;
}

#pragma mark - NSObject Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    int options = NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited
    | NSTrackingMouseMoved | NSTrackingCursorUpdate;
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    currentMouseLocation = RLMTableLocationUndefined;
    previousMouseLocation = RLMTableLocationUndefined;
    
    [self createContextMenuItems];
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

-(id<RLMTableViewDataSource>)realmDataSource
{
    return (id<RLMTableViewDataSource>)self.dataSource;
}

#pragma mark - Private Methods - NSObject Overrides

-(void)createContextMenuItems
{
    NSMenu *rightClickMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
    self.menu = rightClickMenu;
    self.menu.delegate = self;
    
    // This single menu item alerts the user that the realm is locked for editing
    clickLockItem = [[NSMenuItem alloc] initWithTitle:@"Click lock icon to edit"
                                               action:nil
                                        keyEquivalent:@""];
    clickLockItem.tag = 99;
    
    // Operations on objects in class tables
    deleteObjectItem = [[NSMenuItem alloc] initWithTitle:@"Delete objects"
                                                  action:@selector(deleteObjectsAction:)
                                           keyEquivalent:@""];
    deleteObjectItem.tag = 200;

    // Operations on objects in arrays
    removeFromArrayItem = [[NSMenuItem alloc] initWithTitle:@"Remove objects from array"
                                                     action:@selector(removeRowsFromArrayAction:)
                                              keyEquivalent:@""];
    removeFromArrayItem.tag = 210;
    
    deleteRowItem = [[NSMenuItem alloc] initWithTitle:@"Remove objects from array and delete"
                                               action:@selector(deleteRowsFromArrayAction:)
                                        keyEquivalent:@""];
    deleteRowItem.tag = 211;
    
    insertIntoArrayItem = [[NSMenuItem alloc] initWithTitle:@"Add new objects to array"
                                                     action:@selector(addRowsToArrayAction:)
                                              keyEquivalent:@""];
    insertIntoArrayItem.tag = 212;
    
    // Operations on links in cells
    removeLinkToObjectItem= [[NSMenuItem alloc] initWithTitle:@"Remove link to object"
                                                       action:@selector(removeObjectLinksAction:)
                                                keyEquivalent:@""];
    removeLinkToObjectItem.tag = 220;
    
    removeLinkToArrayItem = [[NSMenuItem alloc] initWithTitle:@"Make array empty"
                                                       action:@selector(removeArrayLinksAction:)
                                                keyEquivalent:@""];
    removeLinkToArrayItem.tag = 221;
    
    // Open array in new window
    openArrayInNewWindowItem = [[NSMenuItem alloc] initWithTitle:@"Open array in new window"
                                                          action:@selector(openArrayInNewWindowAction:)
                                                   keyEquivalent:@""];
    openArrayInNewWindowItem.tag = 230;
}

#pragma mark - NSMenu Delegate

// Called on the context menu before displaying
-(void)menuNeedsUpdate:(NSMenu *)menu
{
    [self.menu removeAllItems];
    
    BOOL actualColumn = self.clickedColumn != NOT_A_COLUMN;
    
    // Menu items that are independent on the realm lock
    if (actualColumn && [self.realmDelegate containsArrayInRows:self.selectedRowIndexes column:self.clickedColumn]) {
        [self.menu addItem:openArrayInNewWindowItem];
    }
    
    // If it is locked, show the unlock hint menu item and return
    if (self.realmDelegate.realmIsLocked) {
        [self.menu addItem:clickLockItem];
        return;
    }
    
    // Below, only menu items that do require editing
    
    if (self.realmDelegate.displaysArray) {
        [self.menu addItem:insertIntoArrayItem];
    }
    
    if (self.selectedRowIndexes.count == 0) {
        return;
    }
    
    // Below, only menu items that make sense with a row selected
    
    if (self.realmDelegate.displaysArray) {
        [self.menu addItem:removeFromArrayItem];
        [self.menu addItem:deleteRowItem];
    }
    else {
        [self.menu addItem:deleteObjectItem];
    }
    
    if (!actualColumn) {
        return;
    }
    
    // Below, only menu items that make sense when clicking in a column
    
    if ([self.realmDelegate containsObjectInRows:self.selectedRowIndexes column:self.clickedColumn]) {
        [self.menu addItem:removeLinkToObjectItem];
    }
    else if ([self.realmDelegate containsArrayInRows:self.selectedRowIndexes column:self.clickedColumn]) {
        [self.menu addItem:removeLinkToArrayItem];
    }
}

#pragma mark - NSResponder Overrides

- (void)cursorUpdate:(NSEvent *)event
{
    [self mouseMoved: event];
    
    // Note: This method is left mostly empty on purpose. It avoids cursor events to be passed on up
    //       the responder chain where it potentially could reach a displayed tool-tip view, which
    //       will undo any modification to the cursor image dome by the application. This "fix" is
    //       in order to circumvent a bug in OS X version prior to 10.10 Yosemite not honouring
    //       the NSTrackingActiveAlways option even when the cursorRect has been disabled.
    //       IMPORTANT: Must NOT be deleted!!!
}

- (void)mouseMoved:(NSEvent *)event
{
    if (!self.delegate) {
        return; // No delegate, no need to track the mouse.
    }
        
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
    CGRect cellRect = [self rectOfLocation:currentMouseLocation];
    [self setNeedsDisplayInRect:cellRect];
    
    currentMouseLocation = RLMTableLocationUndefined;
    previousMouseLocation = RLMTableLocationUndefined;
    
    if ([self.delegate respondsToSelector:@selector(mouseDidExitView:)]) {
        [(id<RLMTableViewDelegate>)self.delegate mouseDidExitView:self];
    }
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL nonemptySelection = self.selectedRowIndexes.count > 0;
    BOOL multipleSelection = self.selectedRowIndexes.count > 1;
    BOOL unlocked = !self.realmDelegate.realmIsLocked;
    BOOL displaysArray = self.realmDelegate.displaysArray;

    NSString *numberModifier = multipleSelection ? @"s" : @"";
    
    switch (menuItem.tag) {
        case 99: // Context -> Click lock icon to edit
            return NO;

        case 100: // Edit -> Delete object
        case 200: // Context -> Delete object
            menuItem.title = [NSString stringWithFormat:@"Delete object%@", numberModifier];
            return nonemptySelection && unlocked && !displaysArray;

        case 101: // Edit -> Add object
//        case 201: // Context -> Add object
            menuItem.title = [NSString stringWithFormat:@"Add new object%@", numberModifier];
            return unlocked && !displaysArray;
            
        case 110: // Edit -> Remove object from array
        case 210: // Context -> Remove object from array
            menuItem.title = [NSString stringWithFormat:@"Remove object%@ from array", numberModifier];
            return unlocked && nonemptySelection && displaysArray;

        case 111: // Edit -> Remove object from array and delete
        case 211: // Context -> Remove object from array and delete
            menuItem.title = [NSString stringWithFormat:@"Remove object%@ from array and delete", numberModifier];
            return unlocked && nonemptySelection && displaysArray;

        case 112: // Edit -> Insert object into array
        case 212: // Context -> Insert object into array
            menuItem.title = [NSString stringWithFormat:@"Add new object%@ to array", numberModifier];
            return unlocked && displaysArray;
            
        case 220: // Context -> Remove links to object
            menuItem.title = [NSString stringWithFormat:@"Remove link%@ to object%@", numberModifier, numberModifier];
            return unlocked && nonemptySelection;

        case 221: // Context -> Remove links to array
            menuItem.title = [NSString stringWithFormat:@"Make array%@ empty", numberModifier];
            return unlocked && nonemptySelection;

        case 230: // Context -> Open array in new window
            menuItem.title = @"Open array in new window";
            return YES;

        default:
            return YES;
    }
}

#pragma mark - First Responder User Actions

// Delete selected objects
- (IBAction)deleteObjectsAction:(id)sender
{
    if (!self.realmDelegate.displaysArray && !self.realmDelegate.realmIsLocked) {
        [self.realmDelegate deleteObjects:self.selectedRowIndexes];
    }
}

// Add objects of the current type, according to number of selected rows
- (IBAction)addObjectsAction:(id)sender
{
    if (!self.realmDelegate.displaysArray && !self.realmDelegate.realmIsLocked) {
        [self.realmDelegate addNewObjects:self.selectedRowIndexes];
    }
}

// Remove selected objects from array, keeping the objects
- (IBAction)removeRowsFromArrayAction:(id)sender
{
    if (self.realmDelegate.displaysArray && !self.realmDelegate.realmIsLocked) {
        [self.realmDelegate removeRows:self.selectedRowIndexes];
    }
}

// Remove selected objects from array and delete the objects
- (IBAction)deleteRowsFromArrayAction:(id)sender
{
    if (self.realmDelegate.displaysArray && !self.realmDelegate.realmIsLocked) {
        [self.realmDelegate deleteRows:self.selectedRowIndexes];
    }
}

// Create and insert objects at the selected rows
- (IBAction)addRowsToArrayAction:(id)sender
{
    if (self.realmDelegate.displaysArray && !self.realmDelegate.realmIsLocked) {
        [self.realmDelegate addNewRows:self.selectedRowIndexes];
    }
}

// Set object links in the clicked column to [NSNull null] at the selected rows
- (IBAction)removeObjectLinksAction:(id)sender
{
    if (!self.realmDelegate.realmIsLocked) {
        [self.realmDelegate removeObjectLinksAtRows:self.selectedRowIndexes column:self.clickedColumn];
    }
}

// Make array links in the clicked column, at selected rows, empty
- (IBAction)removeArrayLinksAction:(id)sender
{
    if (!self.realmDelegate.realmIsLocked) {
        [self.realmDelegate removeArrayLinksAtRows:self.selectedRowIndexes column:self.clickedColumn];
    }
}

// Opens the array in the current cell in a new window
- (IBAction)openArrayInNewWindowAction:(id)sender
{
    [self.realmDelegate openArrayInNewWindowAtRow:self.clickedRow column:self.clickedColumn];
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

- (void)scrollToRow:(NSInteger)rowIndex
{
    NSRect rowRect = [self rectOfRow:rowIndex];
    NSPoint scrollOrigin = rowRect.origin;
    NSClipView *clipView = (NSClipView *)[self superview];
    scrollOrigin.y += MAX(0, round((NSHeight(rowRect) - NSHeight(clipView.frame))*0.5f));
    NSScrollView *scrollView = (NSScrollView *)[clipView superview];
    if ([scrollView respondsToSelector:@selector(flashScrollers)]){
        [scrollView flashScrollers];
    }
    [[clipView animator] setBoundsOrigin:scrollOrigin];
}

- (void)setupColumnsWithType:(RLMTypeNode *)typeNode
{
    while (self.numberOfColumns > 0) {
        [self removeTableColumn:[self.tableColumns lastObject]];
    }
    
    [self reloadData];

    NSRect frame = self.headerView.frame;
    frame.size.height = 36;
    self.headerView.frame = frame;
    
    [self beginUpdates];
    // If array, add extra first column with numbers
    if ([typeNode isMemberOfClass:[RLMArrayNode class]]) {
        RLMTableColumn *tableColumn = [[RLMTableColumn alloc] initWithIdentifier:@"#"];
        tableColumn.propertyType = RLMPropertyTypeInt;
        
        RLMTableHeaderCell *headerCell = [[RLMTableHeaderCell alloc] init];
        headerCell.wraps = YES;
        headerCell.firstLine = @"";
        headerCell.secondLine = @"#";

        tableColumn.headerCell = headerCell;
        tableColumn.headerToolTip = @"Order of object within array";
        
        [self addTableColumn:tableColumn];
    }
    
    // ... and add new columns matching the structure of the new realm table.
    NSArray *propertyColumns = typeNode.propertyColumns;

    for (NSUInteger index = 0; index < propertyColumns.count; index++) {
        RLMClassProperty *propertyColumn = propertyColumns[index];
        RLMTableColumn *tableColumn = [[RLMTableColumn alloc] initWithIdentifier:propertyColumn.name];
        
        tableColumn.propertyType = propertyColumn.type;
        
        RLMTableHeaderCell *headerCell = [[RLMTableHeaderCell alloc] init];
        headerCell.wraps = YES;
        headerCell.firstLine = propertyColumn.name;
        headerCell.secondLine = [RLMDescriptions typeNameOfProperty:propertyColumn.property];
        tableColumn.headerCell = headerCell;
        
        tableColumn.headerToolTip = [self.realmDataSource headerToolTipForColumn:propertyColumn];
        [self addTableColumn:tableColumn];
    }
    
    [self endUpdates];
}

#pragma mark - Private Methods - Table Columns

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