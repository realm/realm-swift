//
//  RLMRealmColumn.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RLMTableColumnType) {
    RLMTableColumnTypeInteger,
    RLMTableColumnTypeString,
    RLMTableColumnTypeSubTable
};

@interface RLMRealmColumn : NSObject

@property (nonatomic, readonly) NSString *columnName;
@property (nonatomic, readonly) RLMTableColumnType columnType;
@property (nonatomic, readonly) Class columnClass;

- (instancetype)initWithName:(NSString *)name type:(RLMTableColumnType)type;

@end
