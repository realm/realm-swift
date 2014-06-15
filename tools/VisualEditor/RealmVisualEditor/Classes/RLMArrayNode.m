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

@synthesize referringProperty = _referringProperty;
@synthesize referringIndex = _referringIndex;

- (instancetype)initWithArray:(RLMArray *)array withReferringProperty:(NSString *)property referringIndex:(NSUInteger)index realm:(RLMRealm *)realm
{
    NSString *objectClassName = array.objectClassName;
    RLMSchema *schema = realm.schema;
    RLMObjectSchema *objectSchema = [schema schemaForObject:objectClassName];
    
    if (self = [super initWithSchema:objectSchema
                             inRealm:realm]) {
        _referringProperty = property;
        _referringIndex = index;
        displayedArray = array;
    }

    return self;
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

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return displayedArray[index];
}

- (id)nodeElementForColumnWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            return [NSString stringWithFormat:@"instance[%lu].%@", (unsigned long)self.referringIndex, _referringProperty];
            
        default:
            return nil;
    }
}

@end
