//
//  RLMArrayNode.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 12/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMObjectNode.h"

@interface RLMArrayNode : RLMObjectNode

@property (nonatomic, copy) NSString *referringProperty;
@property (nonatomic, assign) NSUInteger referringIndex;

- (instancetype)initWithArray:(RLMArray *)array withReferringProperty:(NSString *)property referringIndex:(NSUInteger)index realm:(RLMRealm *)realm;

@end
