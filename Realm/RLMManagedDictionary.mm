//
//  RLMManagedDictionary.m
//  Realm
//
//  Created by Pavel Yakimenko on 28/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

#include "RLMDictionary.h"
#include "RLMUtil.hpp"

@interface RLMManagedDictionary: RLMDictionary
@end

@implementation RLMManagedDictionary

- (nonnull RLMNotificationToken *)addNotificationBlock:(nonnull void (^)(id<RLMCollection> _Nullable, RLMCollectionChange * _Nullable, NSError * _Nullable))block {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull id)objectAtIndexedSubscript:(NSUInteger)index {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (instancetype)freeze {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

@end
