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

#import "RLMClassNode.h"

#import "RLMObjectNode.h"
#import "RLMArrayNode.h"
#import "RLMResultsNode.h"

#import "RLMSidebarTableCellView.h"
#import "Realm_Private.h"

@interface RLMClassNode ()

@property (nonatomic, readonly) NSMutableArray *displayedItems;

@end


@implementation RLMClassNode {
    NSMutableArray *displayedObjects;
    NSMutableArray *displayedArrays;
    
    BOOL displaysQuery;
}

- (instancetype)initWithSchema:(RLMObjectSchema *)schema inRealm:(RLMRealm *)realm
{
    self = [super initWithSchema:schema inRealm:realm];
    if (self) {
        displayedObjects = [[NSMutableArray alloc] initWithCapacity:10];
        displayedArrays = [[NSMutableArray alloc] initWithCapacity:10];
        displaysQuery = NO;
    }
    
    return self;
}

#pragma mark - RLMObjectNode overrides

- (NSString *)name
{
    return [self.schema.className copy];
}

- (NSUInteger)instanceCount
{
    return self.allObjects.count;
}

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)isExpandable
{
    return self.displayedItems.count > 0;
}

- (NSUInteger)numberOfChildNodes
{
    return self.displayedItems.count;
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return self.displayedItems[index];
}

#pragma mark - RLMTypeNode overrides

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return self.allObjects[index];
}

- (NSUInteger)indexOfInstance:(RLMObject *)instance
{    
    return [self.allObjects indexOfObject:instance];
}

- (NSView *)cellViewForTableView:(NSTableView *)tableView
{
    RLMSidebarTableCellView *result = [tableView makeViewWithIdentifier:@"MainCell" owner:self];

    result.textField.stringValue = self.name;
    result.button.title = [NSString stringWithFormat:@"%lu", (unsigned long)[self instanceCount]];
    [[result.button cell] setHighlightsBy:0];
    result.button.hidden = NO;
    result.imageView.image = nil;
    
    return result;
}

- (RLMResults *)allObjects
{
    if (!_allObjects) {
        _allObjects = [self.realm allObjects:self.schema.className];
    }
    
    return _allObjects;
}

#pragma mark - Public methods

- (RLMObjectNode *)displayChildObject:(RLMObject *)object
{
    displaysQuery = NO;
    
    RLMObjectNode *objectNode = [[RLMObjectNode alloc] initWithObject:object realm:self.realm];
    objectNode.parentNode = self;
    
    if (displayedObjects.count == 0) {
        [displayedObjects addObject:objectNode];
    }
    else {
        [displayedObjects replaceObjectAtIndex:0 withObject:objectNode];
    }

    return objectNode;
}

- (RLMResultsNode *)displayChildResultsFromQuery:(NSString *)searchText result:(RLMResults *)result
{
    displaysQuery = YES;
    
    RLMResultsNode *resultsNode = [[RLMResultsNode alloc] initWithQuery:searchText result:result andParent:self];
    
    if (displayedArrays.count == 0) {
        [displayedArrays addObject:resultsNode];
    }
    else {
        [displayedArrays replaceObjectAtIndex:0 withObject:resultsNode];
    }

    return resultsNode;
}

- (void)removeAllChildNodes
{
    [displayedArrays removeAllObjects];
    [displayedObjects removeAllObjects];
}

- (void)removeDisplayingOfArrayAtIndex:(NSUInteger)index
{

}

- (void)removeDisplayingOfArrayFromObjectAtIndex:(NSUInteger)index
{

}

#pragma mark - Private methods

- (NSMutableArray *)displayedItems
{
    return displaysQuery ? displayedArrays : displayedObjects;
}

@end








