//
//  RLMRealmColumn.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMRealmColumn.h"

#import "RLMRealmTable.h"

@implementation RLMRealmColumn

@synthesize columnName = _columnName;
@synthesize columnType = _columnType;

- (instancetype)initWithName:(NSString *)name type:(RLMTableColumnType)type
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
        case RLMTableColumnTypeInteger:
            return [NSNumber class];

        case RLMTableColumnTypeString:
            return [NSString class];
            
        case RLMTableColumnTypeSubTable:
            return [RLMRealmTable class];

        default:
            return nil;
    }
}

@end
