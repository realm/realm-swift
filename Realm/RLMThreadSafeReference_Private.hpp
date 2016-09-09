//
//  RLMThreadSafeReference.h
//  Realm
//
//  Created by Realm on 9/7/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "RLMThreadSafeReference.h"
#include "shared_realm.hpp"
#include "thread_safe_reference.hpp"

NS_ASSUME_NONNULL_BEGIN

@protocol RLMThreadConfined_Private <NSObject>

// Constructs a new `ThreadSafeReference`
- (std::unique_ptr<realm::ThreadSafeReferenceBase>)rlm_newThreadSafeReference;

// The extra information needed to construct an instance of this type from the Object Store type
@property (nonatomic, readonly, nullable) id rlm_objectiveCMetadata;

// Constructs an new instance of this type
+ (instancetype)rlm_objectWithThreadSafeReference:(std::unique_ptr<realm::ThreadSafeReferenceBase>)reference
                                         metadata:(nullable id)metadata
                                            realm:(RLMRealm *)realm;
@end

@interface RLMThreadSafeReference ()

- (id<RLMThreadConfined>)resolveReferenceInRealm:(RLMRealm *)realm;

@end

NS_ASSUME_NONNULL_END
