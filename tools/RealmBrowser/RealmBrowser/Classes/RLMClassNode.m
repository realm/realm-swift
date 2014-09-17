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

#import "RLMSidebarTableCellView.h"

// private redeclaration
@interface RLMRealm ()
- (RLMArray *)allObjects:(NSString *)className;
@end


@interface RLMClassNode ()

@property (nonatomic) RLMArray *allObjects;

@end


@implementation RLMClassNode {

    NSMutableArray *displayedArrays;
}

- (instancetype)initWithSchema:(RLMObjectSchema *)schema inRealm:(RLMRealm *)realm
{
    self = [super initWithSchema:schema inRealm:realm];
    if (self) {
        displayedArrays = [[NSMutableArray alloc] initWithCapacity:10];
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
    return displayedArrays.count > 0;
}

- (NSUInteger)numberOfChildNodes
{
    return displayedArrays.count;
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return displayedArrays[index];
}

#pragma mark - RLMObjectNode overrides

- (id)minimumOfPropertyNamed:(NSString *)propertyName
{
    return [self.allObjects minOfProperty:propertyName];
}

- (NSNumber *)averageOfPropertyNamed:(NSString *)propertyName
{
    return [self.allObjects averageOfProperty:propertyName];
}

- (id)maximumOfPropertyNamed:(NSString *)propertyName
{
    return [self.allObjects maxOfProperty:propertyName];
}

- (NSNumber *)sumOfPropertyNamed:(NSString *)propertyName
{
    return [self.allObjects sumOfProperty:propertyName];
}

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return self.allObjects[index];
}

- (NSUInteger)indexOfInstance:(RLMObject *)instance
{    
// Note: The indexOfObject method of RLMArray is not yet implemented so we have to perform the
//       lookup as a simple linear search;
    
    NSUInteger index = 0;
    for (RLMObject *classInstance in self.allObjects) {
        if (classInstance == instance) {
            return index;
        }
        index++;
    }
    
    return NSNotFound;
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

#pragma mark - Public methods

- (RLMArrayNode *)displayChildArrayFromProperty:(RLMProperty *)property object:(RLMObject *)object
{
    RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithReferringProperty:property
                                                                     onObject:object
                                                                        realm:self.realm];
    
    if (displayedArrays.count == 0) {
        [displayedArrays addObject:arrayNode];
    }
    else {
        [displayedArrays replaceObjectAtIndex:0
                                   withObject:arrayNode];
    }

    return arrayNode;
}

- (RLMArrayNode *)displayChildArrayFromQuery:(NSString *)searchText result:(RLMArray *)result
{
    RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithQuery:searchText result:result andParent:self];

    if (displayedArrays.count == 0) {
        [displayedArrays addObject:arrayNode];
    }
    else {
        [displayedArrays replaceObjectAtIndex:0 withObject:arrayNode];
    }

    return arrayNode;
}

- (void)removeAllChildNodes
{
    [displayedArrays removeAllObjects];
}

- (void)removeDisplayingOfArrayAtIndex:(NSUInteger)index
{

}

- (void)removeDisplayingOfArrayFromObjectAtIndex:(NSUInteger)index
{

}

#pragma mark - Private methods

- (RLMArray *)allObjects
{
    if (!_allObjects) {
        _allObjects = [self.realm allObjects:self.schema.className];
    }
    
    return _allObjects;
}

@end








