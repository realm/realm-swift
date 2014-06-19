//
//  RLMArrayNode.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 12/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMArrayNode.h"

@implementation RLMArrayNode {

    RLMProperty *referringProperty;
    RLMObject *referringObject;
    RLMArray *displayedArray;
}

- (instancetype)initWithArray:(RLMArray *)array withReferringProperty:(RLMProperty *)property onObject:(RLMObject *)object realm:(RLMRealm *)realm
{
    NSString *elementTypeName = property.objectClassName;
    RLMSchema *realmSchema = realm.schema;
    RLMObjectSchema *elementSchema = [realmSchema schemaForObject:elementTypeName];
    
    if (self = [super initWithSchema:elementSchema
                             inRealm:realm]) {
        referringProperty = property;
        referringObject = object;
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
            return [NSString stringWithFormat:@"%@<%@>", referringProperty.name, referringProperty.objectClassName];
            
        default:
            return nil;
    }
}

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)hasToolTip
{
    return YES;
}

- (NSString *)toolTipString
{
    return referringObject.description;
}

@end
