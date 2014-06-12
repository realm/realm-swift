//
//  RLMArrayNode.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 12/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMObjectNode.h"

@interface RLMArrayNode : RLMObjectNode

@property (nonatomic, assign) NSUInteger parentObjectIndex;

- (instancetype)initWithArray:(RLMArray *)array withParentObjectIndex:(NSUInteger)index realm:(RLMRealm *)realm;

@end
