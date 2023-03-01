////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import "RLMRealmUtil.hpp"

#import "RLMAsyncTask_Private.h"
#import "RLMObservation.hpp"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMScheduler.h"
#import "RLMUtil.hpp"

#import <realm/object-store/binding_context.hpp>
#import <realm/object-store/impl/realm_coordinator.hpp>
#import <realm/object-store/shared_realm.hpp>
#import <realm/object-store/util/scheduler.hpp>

#import <map>

// Global realm state
static auto& s_realmCacheMutex = *new RLMUnfairMutex;
static auto& s_realmsPerPath = *new std::map<std::string, NSMapTable *>();
static auto& s_frozenRealms = *new std::map<std::string, NSMapTable *>();

void RLMCacheRealm(__unsafe_unretained RLMRealmConfiguration *const configuration,
                   RLMScheduler *scheduler,
                   __unsafe_unretained RLMRealm *const realm) {
    auto& path = configuration.path;
    auto key = scheduler.cacheKey;
    std::lock_guard lock(s_realmCacheMutex);
    NSMapTable *realms = s_realmsPerPath[path];
    if (!realms) {
        s_realmsPerPath[path] = realms = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality|NSPointerFunctionsOpaqueMemory
                                                               valueOptions:NSPointerFunctionsWeakMemory];
    }
    [realms setObject:realm forKey:(__bridge id)key];
}

RLMRealm *RLMGetCachedRealm(__unsafe_unretained RLMRealmConfiguration *const configuration,
                            RLMScheduler *scheduler) {
    auto key = scheduler.cacheKey;
    auto& path = configuration.path;
    std::lock_guard lock(s_realmCacheMutex);
    RLMRealm *realm = [s_realmsPerPath[path] objectForKey:(__bridge id)key];
    if (realm && !realm->_realm->scheduler()->is_on_thread()) {
        // We can get here in two cases: if the user is trying to open a
        // queue-bound Realm from the wrong queue, or if we have a stale cached
        // Realm which is bound to a thread that no longer exists. In the first
        // case we'll throw an error later on; in the second we'll just create
        // a new RLMRealm and replace the cache entry with one bound to the
        // thread that now exists.
        realm = nil;
    }
    return realm;
}

RLMRealm *RLMGetAnyCachedRealm(__unsafe_unretained RLMRealmConfiguration *const configuration) {
    return RLMGetAnyCachedRealmForPath(configuration.path);
}

RLMRealm *RLMGetAnyCachedRealmForPath(std::string const& path) {
    std::lock_guard lock(s_realmCacheMutex);
    return [s_realmsPerPath[path] objectEnumerator].nextObject;
}

void RLMClearRealmCache() {
    std::lock_guard lock(s_realmCacheMutex);
    s_realmsPerPath.clear();
    s_frozenRealms.clear();
}

RLMRealm *RLMGetFrozenRealmForSourceRealm(__unsafe_unretained RLMRealm *const sourceRealm) {
    std::lock_guard lock(s_realmCacheMutex);
    auto& r = *sourceRealm->_realm;
    auto& path = r.config().path;
    NSMapTable *realms = s_realmsPerPath[path];
    if (!realms) {
        s_realmsPerPath[path] = realms = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsIntegerPersonality|NSPointerFunctionsOpaqueMemory
                                                               valueOptions:NSPointerFunctionsWeakMemory];
    }
    r.read_group();
    auto version = reinterpret_cast<void *>(r.read_transaction_version().version);
    RLMRealm *realm = [realms objectForKey:(__bridge id)version];
    if (!realm) {
        realm = [sourceRealm frozenCopy];
        [realms setObject:realm forKey:(__bridge id)version];
    }
    return realm;
}

namespace {
class RLMNotificationHelper : public realm::BindingContext {
public:
    RLMNotificationHelper(RLMRealm *realm) : _realm(realm) { }

    void before_notify() override {
        @autoreleasepool {
            auto blocks = std::move(_beforeNotify);
            _beforeNotify.clear();
            for (auto block : blocks) {
                block();
            }
        }
    }

    void changes_available() override {
        @autoreleasepool {
            auto realm = _realm;
            if (realm && !realm.autorefresh) {
                [realm sendNotifications:RLMRealmRefreshRequiredNotification];
            }
        }
    }

    std::vector<ObserverState> get_observed_rows() override {
        @autoreleasepool {
            if (auto realm = _realm) {
                [realm detachAllEnumerators];
                return RLMGetObservedRows(realm->_info);
            }
            return {};
        }
    }

    void will_change(std::vector<ObserverState> const& observed, std::vector<void*> const& invalidated) override {
        @autoreleasepool {
            RLMWillChange(observed, invalidated);
        }
    }

    void did_change(std::vector<ObserverState> const& observed, std::vector<void*> const& invalidated, bool version_changed) override {
        try {
            @autoreleasepool {
                RLMDidChange(observed, invalidated);
                if (version_changed) {
                    [_realm sendNotifications:RLMRealmDidChangeNotification];
                }
            }
        }
        catch (...) {
            // This can only be called during a write transaction if it was
            // called due to the transaction beginning, so cancel it to ensure
            // exceptions thrown here behave the same as exceptions thrown when
            // actually beginning the write
            if (_realm.inWriteTransaction) {
                [_realm cancelWriteTransaction];
            }
            throw;
        }
    }

    void add_before_notify_block(dispatch_block_t block) {
        _beforeNotify.push_back(block);
    }

private:
    // This is owned by the realm, so it needs to not retain the realm
    __weak RLMRealm *const _realm;
    std::vector<dispatch_block_t> _beforeNotify;
};
} // anonymous namespace

std::unique_ptr<realm::BindingContext> RLMCreateBindingContext(__unsafe_unretained RLMRealm *const realm) {
    return std::unique_ptr<realm::BindingContext>(new RLMNotificationHelper(realm));
}

void RLMAddBeforeNotifyBlock(RLMRealm *realm, dispatch_block_t block) {
    static_cast<RLMNotificationHelper *>(realm->_realm->m_binding_context.get())->add_before_notify_block(block);
}

@implementation RLMPinnedRealm {
    realm::TransactionRef _pin;
}

- (instancetype)initWithRealm:(RLMRealm *)realm {
    if (self = [super init]) {
        _pin = realm->_realm->duplicate();
        _configuration = realm.configuration;
    }
    return self;
}

- (void)unpin {
    _pin.reset();
}
@end
