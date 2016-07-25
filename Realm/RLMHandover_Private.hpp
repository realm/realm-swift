//
//  RLMHandover.h
//  Realm
//
//  Created by Realm on 7/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "RLMHandover.h"
#import "handover.hpp"

@class RLMRealm;

NS_ASSUME_NONNULL_BEGIN

@protocol RLMThreadConfined_Private

@property (readonly) realm::AnyThreadConfined rlm_handoverData;
@property (readonly) id rlm_handoverMetadata;
+ (instancetype)rlm_objectWithHandoverData:(realm::AnyThreadConfined&)data
                                  metadata:(nullable id)metadata inRealm:(RLMRealm *)realm;

@end

@interface RLMHandoverPackage ()

- (instancetype)initWithRealm:(RLMRealm *)realm objects:(NSArray<id<RLMThreadConfined>> *)handoffObjects;

@end

NS_ASSUME_NONNULL_END
