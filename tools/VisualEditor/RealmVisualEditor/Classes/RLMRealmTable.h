//
//  RLMRealmTable.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RLMRealmColumn.h"

#import "RLMRealmOutlineNode.h"

@interface RLMRealmTable : NSObject <RLMRealmOutlineNode>

@property (nonatomic, readonly) NSString *tableName;
@property (nonatomic, readonly) NSArray *tableColumns;
@property (nonatomic, readonly) NSUInteger rowCount;

- (instancetype)initWithName:(NSString *)name columns:(NSArray *)columns;

- (instancetype)initWithName:(NSString *)name columnNames:(NSArray *)columnNames columnTypes:(NSArray *)columnTypes;

- (BOOL)addRowWithValues:(NSArray *)values;

- (NSArray *)rowAtIndex:(NSUInteger)index;

@end
