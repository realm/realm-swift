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

#import "RLMTypeNode.h"

@implementation RLMTypeNode

@dynamic name;
@dynamic instanceCount;

@synthesize propertyColumns = _propertyColumns;

- (instancetype)initWithSchema:(RLMObjectSchema *)schema inRealm:(RLMRealm *)realm
{
    if (self = [super init]) {
        _realm = realm;
        _schema = schema;
        _propertyColumns = [self constructColumnObjectsForScheme:schema];
    }
    return self;
}

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)isRootNode
{
    return NO; // Default implementation - should be overridden by subclasses.
}

- (BOOL)isExpandable
{
    return NO; // Default implementation - should be overridden by subclasses.
}

- (NSUInteger)numberOfChildNodes
{
    return 0; // Default implementation - should be overridden by subclasses.
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return nil; // Default implementation - should be overridden by subclasses.
}

- (id)nodeElementForColumnWithIndex:(NSInteger)index
{
    return nil; // Default implementation - should be overridden by subclasses.
}

- (NSView *)cellViewForTableView:(NSTableView *)tableView
{
    return nil; // Default implementation - should be overridden by subclasses.    
}


#pragma mark - Public methods - Accessors

- (NSString *)name
{
    return @"";
}

- (NSUInteger)instanceCount
{
    return 0;
}

#pragma mark - Public methods

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return nil; // Default implementation - should be overridden by subclasses.
}

- (NSUInteger)indexOfInstance:(RLMObject *)instance
{
    return 0; // Default implementation - should be overridden by subclasses.
}

#pragma mark - Private methods

- (NSArray *)constructColumnObjectsForScheme:(RLMObjectSchema *)schema;
{
    NSArray *properties = schema.properties;
    NSUInteger propertyCount = properties.count;
    
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:propertyCount];
    for (NSUInteger index = 0; index < propertyCount; index++) {
        RLMProperty *property = properties[index];        
        RLMClassProperty *tableColumn = [[RLMClassProperty alloc] initWithProperty:property];
        [result addObject:tableColumn];
    }
    
    return result;
}

@end
