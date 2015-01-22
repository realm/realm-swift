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

#import "RLMRealmCache.h"

#import "RLMRealm_Private.hpp"

// Global realm state
static NSMutableDictionary *s_realmsPerPath = [NSMutableDictionary new];
static NSMutableDictionary *s_notifiersPerPath = [NSMutableDictionary new];

void RLMCacheRealm(RLMRealm *realm) {
    @synchronized(s_realmsPerPath) {
        if (!s_realmsPerPath[realm.path]) {
            s_realmsPerPath[realm.path] = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPersonality
                                                                valueOptions:NSPointerFunctionsWeakMemory];
        }
        [s_realmsPerPath[realm.path] setObject:realm forKey:@(realm->_threadID)];
    }
}

RLMRealm *RLMGetAnyCachedRealmForPath(NSString *path) {
    @synchronized(s_realmsPerPath) {
        return [s_realmsPerPath[path] objectEnumerator].nextObject;
    }
}

RLMRealm *RLMGetCurrentThreadCachedRealmForPath(NSString *path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    @synchronized(s_realmsPerPath) {
        return [s_realmsPerPath[path] objectForKey:@(threadID)];
    }
}

void RLMClearRealmCache() {
    @synchronized(s_realmsPerPath) {
        for (NSMapTable *map in s_realmsPerPath.allValues) {
            [map removeAllObjects];
        }
        [s_realmsPerPath removeAllObjects];
    }
    @synchronized (s_notifiersPerPath) {
        [s_notifiersPerPath removeAllObjects];
    }
}

// A weak holder for an RLMRealm to allow calling performSelector:onThread:
// without a strong reference to the realm
@interface RLMWeakNotifier : NSObject
@property (nonatomic, weak) RLMRealm *realm;

- (instancetype)initWithRealm:(RLMRealm *)realm;
- (void)notifyOnTargetThread;
@end

void RLMStartListeningForChanges(RLMRealm *realm) {
    @synchronized (s_notifiersPerPath) {
        NSMutableArray *notifiers = s_notifiersPerPath[realm.path];
        if (!notifiers) {
            notifiers = [NSMutableArray new];
            s_notifiersPerPath[realm.path] = notifiers;
        }
        [notifiers addObject:[[RLMWeakNotifier alloc] initWithRealm:realm]];
    }
}

void RLMStopListeningForChanges(RLMRealm *realm) {
    @synchronized (s_notifiersPerPath) {
        NSMutableArray *notifiers = s_notifiersPerPath[realm.path];
        if (!notifiers) {
            return;
        }

        // we're called from `dealloc`, so the weak pointer is already nil
        [notifiers filterUsingPredicate:[NSPredicate predicateWithFormat:@"realm != nil"]];
        if (notifiers.count == 0) {
            [s_notifiersPerPath removeObjectForKey:realm.path];
        }
    }
}

void RLMNotifyOtherRealms(RLMRealm *notifyingRealm) {
    @synchronized (s_notifiersPerPath) {
        for (RLMWeakNotifier *notifier in s_notifiersPerPath[notifyingRealm.path]) {
            if (notifier.realm != notifyingRealm) {
                [notifier notifyOnTargetThread];
            }
        }
    }
}

@implementation RLMWeakNotifier {
    NSThread *_thread;
    // flag used to avoid queuing up redundant notifications
    std::atomic_flag _hasPendingNotification;
}

- (instancetype)initWithRealm:(RLMRealm *)realm {
    self = [super init];
    if (self) {
        _realm = realm;
        _thread = [NSThread currentThread];
        _hasPendingNotification.clear();
    }
    return self;
}

- (void)notify {
    _hasPendingNotification.clear();
    [_realm handleExternalCommit];
}

- (void)notifyOnTargetThread {
    if (!_hasPendingNotification.test_and_set()) {
        [self performSelector:@selector(notify)
                     onThread:_thread withObject:nil waitUntilDone:NO];
    }
}
@end
