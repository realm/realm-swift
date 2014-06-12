//
//  RLMClazzNode.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMClazzNode.h"

#import "RLMArrayNode.h"

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
    for(RLMObject *classInstance in allObjects) {
        if(classInstance == instance) {
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

- (void)displayChildArray:(RLMArray *)array fromObjectWithIndex:(NSUInteger)index
{
    RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithArray:array
                                            withParentObjectIndex:index
                                                            realm:self.realm];
    
    [displayedArrays addObject:arrayNode];
}

- (void)removeDisplayingOfArrayAtIndex:(NSUInteger)index
{

}

- (void)removeDisplayingOfArrayFromObjectAtIndex:(NSUInteger)index
{

}


@end








