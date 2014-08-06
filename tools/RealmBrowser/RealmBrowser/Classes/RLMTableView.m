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
    
    int opts = (NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingCursorUpdate);
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                options:opts
                                                  owner:self
                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    mouseOverView = NO;
    currentMouseLocation = RLMTableLocationUndefined;
    previousMouseLocation = RLMTableLocationUndefined;
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
    //       in order to cercumvent a bug in OS X version prior to 10.10 Yosemite not honouring
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

//-(void)mouseUp:(NSEvent *)theEvent {
//    if (theEvent.clickCount > 1) {
//        if (self.delegate && [self.delegate respondsToSelector:@selector(userDoubleClickedatLocation:)]) {
//            [(id<RLMTableViewDelegate>)self.delegate userDoubleClickedatLocation:currentMouseLocation];
//        }
//    }
//    else {
//        if (self.delegate && [self.delegate respondsToSelector:@selector(userClickedAtLocation:)]) {
//            [(id<RLMTableViewDelegate>)self.delegate userClickedAtLocation:currentMouseLocation];
//        }
//    }
//}


#pragma mark - NSView overrides

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    [self removeTrackingArea:trackingArea];
    int opts = (NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                options:opts
                                                  owner:self
                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

#pragma mark - Public methods

- (void)formatColumnsToFitType:(RLMTypeNode *)typeNode withSelectionAtRow:(NSUInteger)selectionIndex
{
    // How many properties does the clazz contains?
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
                NSString *targetTypeName = property.property.objectClassName;
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSLeftTextAlignment
                                   editable:NO
                                    toolTip:[NSString stringWithFormat:@"%@[..]", targetTypeName]];
                break;
            }
                
            case RLMPropertyTypeObject: {
                NSString *targetTypeName = property.property.objectClassName;
                [self initializeTableColumn:tableColumn
                                   withName:columnName
                                  alignment:NSLeftTextAlignment
                                   editable:NO
                                    toolTip:[NSString stringWithFormat:@"%@", targetTypeName]];
                break;
            }
        }
        
        
    }
    
    [self reloadData];
    for (NSTableColumn *column in self.tableColumns) {
        [column resizeToFitContents];
    }
}

#pragma mark - Private methods - Cell geometry 

- (RLMTableLocation)currentLocationAtPoint:(NSPoint)point
{
    NSPoint localPoint = [self convertPoint:point
                                   fromView:nil];
    
    NSInteger row = [self rowAtPoint:localPoint];
    NSInteger column = [self columnAtPoint:localPoint];
    
    return RLMTableLocationMake(row, column);
}

- (CGRect)rectOfLocation:(RLMTableLocation)location
{
    CGRect rowRect = [self rectOfRow:location.row];
    CGRect columnRect = [self rectOfColumn:location.column];
    
    return CGRectIntersection(rowRect, columnRect);
}

#pragma mark - Private methods - Table view configuration

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
