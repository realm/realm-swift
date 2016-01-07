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

#import "RLMObservation.hpp"
#import "RLMRealm_Private.h"
#import "RLMUtil.hpp"

#import <Realm/RLMConstants.h>
#import <Realm/RLMSchema.h>

#import "binding_context.hpp"

#import <map>
#import <mutex>
#import <sys/event.h>
#import <sys/stat.h>
#import <sys/time.h>
#import <unistd.h>

// Global realm state
static std::mutex s_realmCacheMutex;
static std::map<std::string, NSMapTable *> s_realmsPerPath;

void RLMCacheRealm(std::string const& path, RLMRealm *realm) {
    std::lock_guard<std::mutex> lock(s_realmCacheMutex);
    NSMapTable *realms = s_realmsPerPath[path];
    if (!realms) {
        s_realmsPerPath[path] = realms = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPersonality
                                                               valueOptions:NSPointerFunctionsWeakMemory];
    }
    [realms setObject:realm forKey:@(pthread_mach_thread_np(pthread_self()))];
}

RLMRealm *RLMGetAnyCachedRealmForPath(std::string const& path) {
    std::lock_guard<std::mutex> lock(s_realmCacheMutex);
    return [s_realmsPerPath[path] objectEnumerator].nextObject;
}

RLMRealm *RLMGetThreadLocalCachedRealmForPath(std::string const& path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    std::lock_guard<std::mutex> lock(s_realmCacheMutex);
    return [s_realmsPerPath[path] objectForKey:@(threadID)];
}

void RLMClearRealmCache() {
    std::lock_guard<std::mutex> lock(s_realmCacheMutex);
    s_realmsPerPath.clear();
}

void RLMInstallUncaughtExceptionHandler() {
    static auto previousHandler = NSGetUncaughtExceptionHandler();

    NSSetUncaughtExceptionHandler([](NSException *exception) {
        NSNumber *threadID = @(pthread_mach_thread_np(pthread_self()));
        {
            std::lock_guard<std::mutex> lock(s_realmCacheMutex);
            for (auto const& realmsPerThread : s_realmsPerPath) {
                if (RLMRealm *realm = [realmsPerThread.second objectForKey:threadID]) {
                    if (realm.inWriteTransaction) {
                        [realm cancelWriteTransaction];
                    }
                }
            }
        }
        if (previousHandler) {
            previousHandler(exception);
        }
    });
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
            auto realm = _realm;
            [realm detachAllEnumerators];
            return RLMGetObservedRows(realm.schema.objectSchema);
        }
    }

    void will_change(std::vector<ObserverState> const& observed, std::vector<void*> const& invalidated) override {
        @autoreleasepool {
            RLMWillChange(observed, invalidated);
        }
    }

    void did_change(std::vector<ObserverState> const& observed, std::vector<void*> const& invalidated) override {
        @autoreleasepool {
            RLMDidChange(observed, invalidated);
            [_realm sendNotifications:RLMRealmDidChangeNotification];
        }
    }

private:
    // This is owned by the realm, so it needs to not retain the realm
    __weak RLMRealm *const _realm;
};
} // anonymous namespace


std::unique_ptr<realm::BindingContext> RLMCreateBindingContext(RLMRealm *realm) {
    return std::unique_ptr<realm::BindingContext>(new RLMNotificationHelper(realm));
}
