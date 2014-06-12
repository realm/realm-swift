//
//  RLMObjectNode.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 12/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMObjectNode.h"

@implementation RLMObjectNode

@synthesize realm = _realm;
@synthesize schema = _schema;
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
        NSString *propertyName = property.name;
        RLMPropertyType propertyType = property.type;
        
        RLMClazzProperty *tableColumn = [[RLMClazzProperty alloc] initWithName:propertyName
                                                                          type:propertyType];
        [result addObject:tableColumn];
    }
    
    return result;
}

@end
