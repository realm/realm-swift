//
//  RLMClazzNode.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMClazzNode.h"

@implementation RLMClazzNode {

    RLMRealm *sourceRealm;
}

@synthesize schema = _schema;
@dynamic name;
@dynamic instanceCount;

@synthesize propertyColumns = _propertyColumns;

- (instancetype)initWithSchema:(RLMObjectSchema *)schema inRealm:(RLMRealm *)realm
{
    if (self = [super init]) {
        sourceRealm = realm;
        _schema = schema;
        _propertyColumns = [self constructColumnObjectsForScheme:schema];
    }
    return self;
}

#pragma mark - Public methods - Accessors

- (NSString *)name
{
    return [_schema.className copy];
}

- (NSUInteger)instanceCount
{
    RLMArray *allObjects = [sourceRealm allObjects:_schema.className];
    return allObjects.count;
}

#pragma mark - Public methods

- (BOOL)addInstanceWithValues:(NSArray *)values
{
    return NO;
}

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    RLMArray *allObjects = [sourceRealm allObjects:_schema.className];
    return allObjects[index];
}

- (NSUInteger)indexOfInstance:(RLMObject *)instance
{    
// Note: The indexOfObject method of RLMArray is not yet implemented so we have to perform the
//       lookup as a simple linear search;
    
    RLMArray *allObjects = [sourceRealm allObjects:_schema.className];
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

#pragma mark - RLMRealmOutlineNode implementation

- (BOOL)isRootNode
{
    return NO;
}

- (BOOL)isExpandable
{
    return NO;
}

- (NSUInteger)numberOfChildNodes
{
    return 0;
}

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index
{
    return nil;
}

- (id)nodeElementForColumnWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            return _schema.className;
            
        default:
            return nil;
    }
}

#pragma mark - Public methods - Accessors

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








