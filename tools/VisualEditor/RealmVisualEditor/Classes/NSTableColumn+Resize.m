//
//  NSTableColumn+Resize.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 15/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "NSTableColumn+Resize.h"

@implementation NSTableColumn (Resize)

const NSUInteger kMaxNumberOfRowsToConsider = 100;

- (void)resizeToFitContents
{
    NSTableView *tableView = self.tableView;
    NSRect rect = NSMakeRect(0,0, INFINITY, tableView.rowHeight);
    NSInteger columnIndex = [tableView.tableColumns indexOfObject:self];
    CGFloat maxSize = 0;
    
    for (NSInteger index = 0; index < MIN(kMaxNumberOfRowsToConsider, tableView.numberOfRows); index++) {
        NSCell *cell = [tableView preparedCellAtColumn:columnIndex
                                                   row:index];
        NSSize size = [cell cellSizeForBounds:rect];
        maxSize = MAX(maxSize, size.width);
    }
    
    NSCell *headerCell = self.headerCell;
    NSSize headerSize = [headerCell cellSizeForBounds:rect];
    maxSize = MAX(maxSize, headerSize.width) * 1.25;
    
    self.width = maxSize;
}

@end
