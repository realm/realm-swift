//
//  RLMTableNode.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RLMTableColumn.h"
#import "RLMRealmOutlineNode.h"
#import "Realm.h"

@interface RLMTableNode : NSObject <RLMRealmOutlineNode>

@property (nonatomic, readonly) NSString *tableName;
@property (nonatomic, readonly) NSArray *tableColumns;
@property (nonatomic, readonly) NSUInteger rowCount;

- (instancetype)initWithName:(NSString *)name realmTable:(RLMTable *)table;

- (BOOL)addRowWithValues:(NSArray *)values;

- (NSArray *)rowAtIndex:(NSUInteger)index;

@end
