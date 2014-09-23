//
//  RLMObjectNode.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 23/09/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMTypeNode.h"

@class RLMArrayNode;
@interface RLMObjectNode : RLMTypeNode

@property (nonatomic) id<RLMRealmOutlineNode> childNode;
@property (nonatomic) id<RLMRealmOutlineNode> parentNode;

- (instancetype)initWithObject:(RLMObject *)object realm:(RLMRealm *)realm;

- (RLMArrayNode *)displayChildArrayFromProperty:(RLMProperty *)property object:(RLMObject *)object;

@end
