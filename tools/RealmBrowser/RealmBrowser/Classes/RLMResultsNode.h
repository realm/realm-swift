//
//  RLMResultsNode.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 19/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMTypeNode.h"

@interface RLMResultsNode : RLMTypeNode

- (instancetype)initWithQuery:(NSString *)searchText result:(RLMResults *)result andParent:(RLMTypeNode *)classNode;

@end
