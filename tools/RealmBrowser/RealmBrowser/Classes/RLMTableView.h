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

@import Cocoa;

#import "RLMTypeNode.h"

typedef struct {
    NSInteger row;
    NSInteger column;
} RLMTableLocation;

#define RLMTableLocationMake(r, c) (RLMTableLocation){(r), (c)};
#define RLMTableLocationUndefined RLMTableLocationMake(-1, -1)
#define RLMTableLocationIsUndefined(a) ((a) == RLMTableLocationUndefined)
#define RLMTableLocationRowIsUndefined(a) ((a.row) == (-1))
#define RLMTableLocationColumnIsUndefined(a) ((a.column) == (-1))
#define RLMTableLocationEqual(a, b) ((a).row == (b).row) && ((a).column == (b).column)

@class RLMTableView;

@protocol RLMTableViewDataSource <NSTableViewDataSource>

-(NSString *)headerToolTipForColumn:(RLMClassProperty *)propertyColumn;

@end


@protocol RLMTableViewDelegate <NSTableViewDelegate>

// Asking the delegate about the state
- (BOOL)realmIsLocked;

- (BOOL)displaysArray;

// Asking the delegate about the contents
- (BOOL)containsObjectInRows:(NSIndexSet *)rowIndexes column:(NSInteger)column;

- (BOOL)containsArrayInRows:(NSIndexSet *)rowIndexes column:(NSInteger)column;

// RLMObject operations (when showing class table)
- (void)addNewObjects:(NSIndexSet *)rowIndexes;

- (void)deleteObjects:(NSIndexSet *)rowIndexes;

// RLMArray operations
- (void)removeRows:(NSIndexSet *)rowIndexes;

- (void)deleteRows:(NSIndexSet *)rowIndexes;

- (void)addNewRows:(NSIndexSet *)rowIndexes;

// Operations on links in cells
- (void)removeObjectLinksAtRows:(NSIndexSet *)rowIndexes column:(NSInteger)columnIndex;

- (void)removeArrayLinksAtRows:(NSIndexSet *)rowIndexes column:(NSInteger)columnIndex;

// Opening an array in a new window
- (void)openArrayInNewWindowAtRow:(NSInteger)row column:(NSInteger)columnIndex;

@optional

- (void)mouseDidEnterView:(RLMTableView *)view;

- (void)mouseDidExitView:(RLMTableView *)view;

- (void)mouseDidEnterCellAtLocation:(RLMTableLocation)location;

- (void)mouseDidExitCellAtLocation:(RLMTableLocation)location;

- (void)rightClickedHeaderColumn:(NSUInteger)column;

- (void)rightClickedLocation:(RLMTableLocation)location;

@end


@interface RLMTableView : NSTableView

@property (nonatomic, readonly) id<RLMTableViewDelegate> realmDelegate;
@property (nonatomic, readonly) id<RLMTableViewDataSource> realmDataSource;

- (void)scrollToRow:(NSInteger)rowIndex;

- (void)setupColumnsWithType:(RLMTypeNode *)typeNode;

- (void)makeColumnsFitContents;

@end
