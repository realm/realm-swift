////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMSyncSubscription_Private.h"

#import <memory>

namespace realm::sync {
class Subscription;
class SubscriptionSet;
}
namespace realm {
class Query;
}

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@interface RLMSyncSubscription ()
- (instancetype)initWithSubscription:(realm::sync::Subscription)subscription subscriptionSet:(RLMSyncSubscriptionSet *)subscriptionSet;
@end

@interface RLMSyncSubscriptionSet () {
@public 
    std::unique_ptr<realm::sync::SubscriptionSet> _subscriptionSet;
}

- (instancetype)initWithSubscriptionSet:(realm::sync::SubscriptionSet)subscriptionSet realm:(RLMRealm *)realm;

- (void)update:(__attribute__((noescape)) void(^)(void))block
         queue:(nullable dispatch_queue_t)queue
       timeout:(NSTimeInterval)timeout
    onComplete:(void(^)(NSError *))completionBlock;

- (RLMObjectId *)addSubscriptionWithClassName:(NSString *)objectClassName
                             subscriptionName:(nullable NSString *)name
                                        query:(realm::Query)query
                               updateExisting:(BOOL)updateExisting;

- (nullable RLMSyncSubscription *)subscriptionWithQuery:(realm::Query)query;

// Return subscription that matches name *and* query
- (nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name
                                                 query:(realm::Query)query;

- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                                  query:(realm::Query)query;

- (void)removeSubscriptionWithId:(RLMObjectId *)objectId;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
