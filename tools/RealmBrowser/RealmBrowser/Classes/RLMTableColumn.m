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

#import "RLMTableColumn.h"
#import "RLMTableCellView.h"

@implementation RLMTableColumn

const NSUInteger kMaxNumberOfRowsToConsider = 50;
const CGFloat kMaxColumnWidth = 200.0;

- (CGFloat)sizeThatFitsWithLimit:(BOOL)limited
{
    int rowsToConsider;
    
    switch (self.propertyType) {
        case RLMPropertyTypeBool:
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
            rowsToConsider = 1;
            break;
            
        case RLMPropertyTypeArray:
        case RLMPropertyTypeObject:
        case RLMPropertyTypeDate:
            rowsToConsider = 3;
            break;

        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeString:
            rowsToConsider = kMaxNumberOfRowsToConsider;
            break;
    }

    NSInteger columnIndex = [self.tableView.tableColumns indexOfObject:self];

    CGFloat maxWidth = 0.0;

    for (NSInteger rowIndex = 0; rowIndex < MIN(rowsToConsider, self.tableView.numberOfRows); rowIndex++) {
        RLMTableCellView *tableCellView = [self.tableView viewAtColumn:columnIndex row:rowIndex makeIfNecessary:YES];
        maxWidth = MAX(maxWidth, tableCellView.sizeThatFits.width);
    }
    
    NSCell *headerCell = self.headerCell;
    NSRect rect = NSMakeRect(0,0, INFINITY, self.tableView.rowHeight);
    NSSize headerSize = [headerCell cellSizeForBounds:rect];

    maxWidth = MAX(maxWidth + 10.0f, headerSize.width*1.1);
    
    if (limited) {
        maxWidth = MIN(maxWidth, kMaxColumnWidth);
    }
    
    return maxWidth;
}

@end
