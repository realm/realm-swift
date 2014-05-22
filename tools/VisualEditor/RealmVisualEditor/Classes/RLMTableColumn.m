//
//  RLMTableColumn.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMTableColumn.h"

#import "RLMTableNode.h"

@implementation RLMTableColumn

@synthesize columnName = _columnName;
@synthesize columnType = _columnType;

- (instancetype)initWithName:(NSString *)name type:(RLMType)type
{
    if (self = [super init]) {
        _columnName = [name copy];
        _columnType = type;
    }
    return self;
}

- (Class)columnClass
{
    switch (_columnType) {
        case RLMTypeBool:
        case RLMTypeInt:
        case RLMTypeFloat:
        case RLMTypeDouble:
            return [NSNumber class];
        case RLMTypeString:
            return [NSString class];
        case RLMTypeDate:
            return [NSDate class];
        case RLMTypeBinary:            
        case RLMTypeNone:
        case RLMTypeTable:
        case RLMTypeMixed:
            return [RLMTableNode class];
        default:
            return nil;
    }
}

@end
