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

namespace realm::sync {
class Subscription;
class SubscriptionSet;
}

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@interface RLMSyncSubscription ()

- (instancetype)initWithSubscription:(realm::sync::Subscription)subscription subscriptionSet:(RLMSyncSubscriptionSet *)subscriptionSet;

@end

@interface RLMSyncSubscriptionSet ()

- (instancetype)initWithSubscriptionSet:(realm::sync::SubscriptionSet)subscriptionSet realm:(RLMRealm *)realm;

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
