//
//  RLMObjectNode.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 12/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#import "RLMRealmOutlineNode.h"
#import "RLMClazzProperty.h"

@interface RLMObjectNode : NSObject <RLMRealmOutlineNode>

@property (nonatomic, readonly) RLMRealm *realm;
@property (nonatomic, readonly) RLMObjectSchema *schema;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *propertyColumns;
@property (nonatomic, readonly) NSUInteger instanceCount;

- (instancetype)initWithSchema:(RLMObjectSchema *)schema inRealm:(RLMRealm *)realm;

- (RLMObject *)instanceAtIndex:(NSUInteger)index;

- (NSUInteger)indexOfInstance:(RLMObject *)instance;

@end
