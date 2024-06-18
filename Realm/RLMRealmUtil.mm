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
void advance_to_ready(realm::Realm& realm) {
    if (!realm.auto_refresh()) {
        realm.set_auto_refresh(true);
        realm.notify();
        realm.set_auto_refresh(false);
    }
}

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
            if (!realm || realm.autorefresh) {
                return;
            }

            // If an async refresh has been requested, then do that now instead
            // of notifying of a pending version available. Note that this will
            // recursively call this function and then exit above due to
            // autorefresh being true.
            if (_refreshHandlers.empty()) {
                [realm sendNotifications:RLMRealmRefreshRequiredNotification];
            }
            else {
                advance_to_ready(*realm->_realm);
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

    void will_change(std::vector<ObserverState> const& observed,
                     std::vector<void*> const& invalidated) override {
        @autoreleasepool {
            RLMWillChange(observed, invalidated);
        }
    }

    void did_change(std::vector<ObserverState> const& observed,
                    std::vector<void*> const& invalidated, bool version_changed) override {
        @autoreleasepool {
            __strong auto realm = _realm;
            try {
                RLMDidChange(observed, invalidated);
                if (version_changed) {
                    [realm sendNotifications:RLMRealmDidChangeNotification];
                }
            }
            catch (...) {
                // This can only be called during a write transaction if it was
                // called due to the transaction beginning, so cancel it to ensure
                // exceptions thrown here behave the same as exceptions thrown when
                // actually beginning the write
                if (realm.inWriteTransaction) {
                    [realm cancelWriteTransaction];
                }
                throw;
            }

            if (!realm || !version_changed) {
                return;
            }
            auto new_version = realm->_realm->current_transaction_version();
            if (!new_version) {
                return;
            }

            std::erase_if(_refreshHandlers, [&](auto& handler) {
                auto& [target_version, completion] = handler;
                if (new_version->version >= target_version) {
                    completion(true);
                    return true;
                }
                return false;
            });
        }
    }

    void add_before_notify_block(dispatch_block_t block) {
        _beforeNotify.push_back(block);
    }

    void wait_for_refresh(realm::DB::version_type version, RLMAsyncRefreshCompletion completion) {
        _refreshHandlers.emplace_back(version, completion);
    }

private:
    // This is owned by the realm, so it needs to not retain the realm
    __weak RLMRealm *const _realm;
    std::vector<dispatch_block_t> _beforeNotify;
    std::vector<std::pair<realm::DB::version_type, RLMAsyncRefreshCompletion>> _refreshHandlers;
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
        _configuration = realm.configurationSharingSchema;
    }
    return self;
}

- (void)unpin {
    _pin.reset();
}
@end

RLMAsyncRefreshTask *RLMRealmRefreshAsync(RLMRealm *rlmRealm) {
    auto& realm = *rlmRealm->_realm;
    if (realm.is_frozen() || realm.config().immutable()) {
        return nil;
    }

    // Refresh is a no-op if the Realm isn't currently in a read transaction
    // or is up-to-date
    auto latest = realm.latest_snapshot_version();
    auto current = realm.current_transaction_version();
    if (!latest || !current || current->version == *latest)
        return nil;

    // If autorefresh is disabled, we may have already been notified of a new
    // version and simply not advanced to it.
    advance_to_ready(realm);

    // This may have advanced to the latest version in which case there's
    // nothing left to do
    current = realm.current_transaction_version();
    if (current && current->version >= *latest)
        return [RLMAsyncRefreshTask completedRefresh];
    auto refresh = [[RLMAsyncRefreshTask alloc] init];

    // Register the continuation to be called once the new version is ready
    auto& context = static_cast<RLMNotificationHelper&>(*realm.m_binding_context);
    context.wait_for_refresh(*latest, ^(bool didRefresh) { [refresh complete:didRefresh]; });
    return refresh;
}

void RLMRunAsyncNotifiers(NSString *path) {
    realm::_impl::RealmCoordinator::get_existing_coordinator(path.UTF8String)->on_change();
}
