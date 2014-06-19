//
//  RLMClazzProperty.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMClazzProperty.h"

#import "RLMClazzNode.h"

@implementation RLMClazzProperty

- (instancetype)initWithProperty:(RLMProperty *)property;
{
    if (self = [super init]) {
        _property = property;
    }
    return self;
}

- (NSString *)name
{
    return _property.name;
}

- (RLMPropertyType)type
{
    return _property.type;
}

- (Class)clazz
{
    switch (self.type) {
        case RLMPropertyTypeBool:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            return [NSNumber class];
        case RLMPropertyTypeString:
            return [NSString class];
        case RLMPropertyTypeDate:
            return [NSDate class];
        case RLMPropertyTypeData:
        case RLMPropertyTypeObject:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeAny:
            return [RLMClazzNode class];
        default:
            return nil;
    }
}

@end
