//
//  RLMHandoverable.h
//  Realm
//
//  Created by Realm on 7/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLMHandoverable.h"
#import "handover.hpp"

NS_ASSUME_NONNULL_BEGIN

@protocol RLMHandoverable_Private

@property (readonly) realm::AnyHandoverable rlm_handoverable;
@property (readonly) id rlm_handoverMetadata;
+ (instancetype)rlm_objectWithHandoverable:(realm::AnyHandoverable&)handoverable metadata:(nullable id)metadata inRealm:(RLMRealm *)realm;

@end

NS_ASSUME_NONNULL_END
