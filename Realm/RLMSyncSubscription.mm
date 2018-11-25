////////////////////////////////////////////////////////////////////////////
//
// Copyright 2018 Realm Inc.
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

#import "RLMSyncSubscription.h"

#import "RLMRealm_Private.hpp"
#import "RLMResults_Private.hpp"
#import "RLMUtil.hpp"

#import "sync/partial_sync.hpp"

using namespace realm;

@interface RLMSyncSubscription ()
- (instancetype)initWithName:(NSString *)name results:(Results const&)results realm:(RLMRealm *)realm;

@property (nonatomic, readwrite) RLMSyncSubscriptionState state;
@property (nonatomic, readwrite, nullable) NSError *error;
@end

@implementation RLMSyncSubscription {
    partial_sync::SubscriptionNotificationToken _token;
    util::Optional<partial_sync::Subscription> _subscription;
    RLMRealm *_realm;
}

- (instancetype)initWithName:(NSString *)name results:(Results const&)results realm:(RLMRealm *)realm {
    if (!(self = [super init]))
        return nil;

    _name = [name copy];
    _realm = realm;
    _subscription = partial_sync::subscribe(results, name ? util::make_optional<std::string>(name.UTF8String) : util::none);
    self.state = (RLMSyncSubscriptionState)_subscription->state();
    __weak RLMSyncSubscription *weakSelf = self;
    _token = _subscription->add_notification_callback([weakSelf] {
        RLMSyncSubscription *self = weakSelf;
        if (!self)
            return;

        // Retrieve the current error and status. Update our properties only if the values have changed,
        // since clients use KVO to observe these properties.

        if (auto error = self->_subscription->error()) {
            try {
                std::rethrow_exception(error);
            } catch (...) {
                NSError *nsError;
                RLMRealmTranslateException(&nsError);
                if (!self.error || ![self.error isEqual:nsError])
                    self.error = nsError;
            }
        }
        else if (self.error) {
            self.error = nil;
        }

        auto status = (RLMSyncSubscriptionState)self->_subscription->state();
        if (status != self.state)
            self.state = (RLMSyncSubscriptionState)status;
    });

    return self;
}

- (void)unsubscribe {
    partial_sync::unsubscribe(*_subscription);
}
@end

@implementation RLMResults (SyncSubscription)

- (RLMSyncSubscription *)subscribe {
    return [[RLMSyncSubscription alloc] initWithName:nil results:_results realm:self.realm];
}

- (RLMSyncSubscription *)subscribeWithName:(NSString *)subscriptionName {
    return [[RLMSyncSubscription alloc] initWithName:subscriptionName results:_results realm:self.realm];
}

- (RLMSyncSubscription *)subscribeWithName:(NSString *)subscriptionName limit:(NSUInteger)limit {
    return [[RLMSyncSubscription alloc] initWithName:subscriptionName results:_results.limit(limit) realm:self.realm];
}

@end
