//
//  RLMArrayNode.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 12/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMArrayNode.h"

@implementation RLMArrayNode {

    RLMArray *displayedArray;
}

@synthesize parentObjectIndex = _parentObjectIndex;

- (instancetype)initWithArray:(RLMArray *)array withParentObjectIndex:(NSUInteger)index realm:(RLMRealm *)realm
{
    NSString *objectClassName = array.objectClassName;
    RLMSchema *schema = realm.schema;
    RLMObjectSchema *objectSchema = [schema schemaForObject:objectClassName];
    
    if (self = [super initWithSchema:objectSchema
                             inRealm:realm]) {
        _parentObjectIndex = index;
        displayedArray = array;
    }

    return self;
}

#pragma mark - RLMObjectNode overrides

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return displayedArray[index];
}

#pragma mark - RLMObjectNode overrides

- (NSString *)name
{
    return @"Array";
}

- (NSUInteger)instanceCount
{
    return displayedArray.count;
}


@end
