//
//  RLMArrayNode.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 12/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMObjectNode.h"

@interface RLMArrayNode : RLMObjectNode

- (instancetype)initWithArray:(RLMArray *)array withReferringProperty:(RLMProperty *)property onObject:(RLMObject *)object realm:(RLMRealm *)realm;

@end
