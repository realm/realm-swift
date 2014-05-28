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

@synthesize name = _name;
@synthesize type = _type;

- (instancetype)initWithName:(NSString *)name type:(RLMPropertyType)type;
{
    if (self = [super init]) {
        _name = [name copy];
        _type = type;
    }
    return self;
}

- (Class)clazz
{
    switch (_type) {
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
