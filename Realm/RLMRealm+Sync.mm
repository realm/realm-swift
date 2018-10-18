////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMRealm+Sync.h"

#import "RLMObjectBase.h"
#import "RLMQueryUtil.hpp"
#import "RLMObjectSchema.h"
#import "RLMRealm_Private.hpp"
#import "RLMResults_Private.hpp"
#import "RLMSchema.h"
#import "RLMSyncSession.h"

#import "results.hpp"
#import "shared_realm.hpp"
#import "sync/partial_sync.hpp"
#import "sync/subscription_state.hpp"

using namespace realm;

@implementation RLMRealm (Sync)

- (void)subscribeToObjects:(Class)type where:(NSString *)query callback:(RLMPartialSyncFetchCallback)callback {
    [self verifyThread];

    RLMClassInfo& info = _info[[type className]];
    Query q = RLMPredicateToQuery([NSPredicate predicateWithFormat:query],
                                  info.rlmObjectSchema, self.schema, self.group);
    struct Holder {
        partial_sync::Subscription subscription;
        partial_sync::SubscriptionNotificationToken token;

        Holder(partial_sync::Subscription&& s) : subscription(std::move(s)) { }
    };
    auto state = std::make_shared<Holder>(partial_sync::subscribe(Results(_realm, std::move(q)), util::none));
    state->token = state->subscription.add_notification_callback([=]() mutable {
        if (!callback) {
            return;
        }
        switch (state->subscription.state()) {
            case partial_sync::SubscriptionState::Invalidated:
            case partial_sync::SubscriptionState::Pending:
            case partial_sync::SubscriptionState::Creating:
                return;

            case partial_sync::SubscriptionState::Error:
                try {
                    rethrow_exception(state->subscription.error());
                }
                catch (...) {
                    NSError *error = nil;
                    RLMRealmTranslateException(&error);
                    callback(nil, error);
                }
                break;

            case partial_sync::SubscriptionState::Complete:
                callback([RLMResults emptyDetachedResults], nil);
                break;
        }

        callback = nil;
        state->token = {};
    });
}

- (RLMSyncSession *)syncSession {
    return [RLMSyncSession sessionForRealm:self];
}

@end
