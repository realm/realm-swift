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

#import "RLMObjectSchema_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMUtil.hpp"

#import <Realm/RLMConstants.h>
#import <Realm/RLMSchema.h>

#import "binding_context.hpp"
#import "shared_realm.hpp"

#import <map>
#import <mutex>

// Global realm state
static auto& s_realmCacheMutex = *new std::mutex();
static auto& s_realmsPerPath = *new std::map<std::string, NSMapTable *>();
static auto& s_frozenRealms = *new std::map<std::string, NSMapTable *>();

void RLMCacheRealm(std::string const& path, void *key, __unsafe_unretained RLMRealm *const realm) {
    std::lock_guard<std::mutex> lock(s_realmCacheMutex);
    NSMapTable *realms = s_realmsPerPath[path];
    if (!realms) {
        s_realmsPerPath[path] = realms = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality|NSPointerFunctionsOpaqueMemory
                                                               valueOptions:NSPointerFunctionsWeakMemory];
    }
    [realms setObject:realm forKey:(__bridge id)key];
}

RLMRealm *RLMGetAnyCachedRealmForPath(std::string const& path) {
    std::lock_guard<std::mutex> lock(s_realmCacheMutex);
    return [s_realmsPerPath[path] objectEnumerator].nextObject;
}

RLMRealm *RLMGetThreadLocalCachedRealmForPath(std::string const& path, void *key) {
    std::lock_guard<std::mutex> lock(s_realmCacheMutex);
    return [s_realmsPerPath[path] objectForKey:(__bridge id)key];
}

void RLMClearRealmCache() {
    std::lock_guard<std::mutex> lock(s_realmCacheMutex);
    s_realmsPerPath.clear();
    s_frozenRealms.clear();
}

RLMRealm *RLMGetFrozenRealmForSourceRealm(__unsafe_unretained RLMRealm *const sourceRealm) {
    std::lock_guard<std::mutex> lock(s_realmCacheMutex);
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

private:
    // This is owned by the realm, so it needs to not retain the realm
    __weak RLMRealm *const _realm;
};
} // anonymous namespace


std::unique_ptr<realm::BindingContext> RLMCreateBindingContext(__unsafe_unretained RLMRealm *const realm) {
    return std::unique_ptr<realm::BindingContext>(new RLMNotificationHelper(realm));
}
