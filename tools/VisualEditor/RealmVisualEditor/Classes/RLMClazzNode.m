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

#import "RLMClazzNode.h"

@implementation RLMClazzNode {

    NSMutableArray *displayedArrays;
}

- (instancetype)initWithSchema:(RLMObjectSchema *)schema inRealm:(RLMRealm *)realm
{
    if (self = [super initWithSchema:schema
                             inRealm:realm]) {
    
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
    RLMArray *allObjects = [self.realm allObjects:self.schema.className];
    return allObjects.count;
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

- (id)nodeElementForColumnWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            return self.schema.className;
        
        default:
            return nil;
    }
}

#pragma mark - RLMObjectNode overrides

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    RLMArray *allObjects = [self.realm allObjects:self.schema.className];
    return allObjects[index];
}

- (NSUInteger)indexOfInstance:(RLMObject *)instance
{    
// Note: The indexOfObject method of RLMArray is not yet implemented so we have to perform the
//       lookup as a simple linear search;
    
    RLMArray *allObjects = [self.realm allObjects:self.schema.className];
    NSUInteger index = 0;
    for (RLMObject *classInstance in allObjects) {
        if (classInstance == instance) {
            return index;
        }
        index++;
    }
    
    return NSNotFound;
    
/*
    return [allObjects indexOfObject:instance];
*/
}

#pragma mark - Public methods

- (RLMArrayNode *)displayChildArray:(RLMArray *)array fromProperty:(RLMProperty *)property object:(RLMObject *)object
{
    RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithArray:array
                                            withReferringProperty:property
                                                         onObject:object
                                                            realm:self.realm];
    [displayedArrays addObject:arrayNode];
    
    return arrayNode;
}

- (void)removeDisplayingOfArrayAtIndex:(NSUInteger)index
{

}

- (void)removeDisplayingOfArrayFromObjectAtIndex:(NSUInteger)index
{

}


@end








