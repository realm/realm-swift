//
//  RLMClazzNode.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#import "RLMClazzProperty.h"
#import "RLMRealmOutlineNode.h"

@interface RLMClazzNode : NSObject <RLMRealmOutlineNode>

@property (nonatomic, readonly) RLMObjectSchema *schema;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *propertyColumns;
@property (nonatomic, readonly) NSUInteger instanceCount;

- (instancetype)initWithSchema:(RLMObjectSchema *)schema inRealm:(RLMRealm *)realm;

- (BOOL)addInstanceWithValues:(NSArray *)values;

- (RLMObject *)instanceAtIndex:(NSUInteger)index;

- (NSUInteger)indexOfInstance:(RLMObject *)instance;

@end
