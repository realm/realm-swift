//
//  RLMBNode.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBNode.h"

// PRIVATE
@interface RLMRealm ()
- (RLMResults *)allObjects:(NSString *)className;
@end


@implementation RLMBNode

-(RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return nil;
}

@end


@interface RLMBRootNode ()
@property (nonatomic) RLMResults *allObjects;
@end

@implementation RLMBRootNode

- (RLMResults *)allObjects
{
    if (!_allObjects) {
        _allObjects = [self.realm allObjects:self.objectSchema.className];
    }
    
    return _allObjects;
}

-(NSUInteger)instanceCount
{
    return self.allObjects.count;
}

-(RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return self.allObjects[index];
}

@end


@interface RLMBArrayNode ()
@property (nonatomic) RLMArray *array;
@end

@implementation RLMBArrayNode

-(NSUInteger)instanceCount
{
    return self.array.count;
}

-(RLMObject *)objectAtIndex:(NSUInteger)index
{
    return self.array[index];
}

@end


@interface RLMBResultsNode ()
@property (nonatomic) RLMResults *allObjects;
@end

@implementation RLMBResultsNode

-(NSUInteger)instanceCount
{
    return self.allObjects.count;
}

-(RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return self.allObjects[index];
}

@end


@interface RLMBObjectNode ()
@property (nonatomic) RLMObject *object;
@end

@implementation RLMBObjectNode

-(NSUInteger)instanceCount
{
    return self.object ? 1 : 0;
}

-(RLMObject *)objectAtIndex:(NSUInteger)index
{
    return self.object;
}

@end
