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

#import "RLMRealmUtil.h"

#import "RLMRealm_Private.hpp"

#import <tightdb/group_shared.hpp>
#import <tightdb/commit_log.hpp>
#import <tightdb/lang_bind_helper.hpp>

// A weak holder for an RLMRealm to allow calling performSelector:onThread:
// without a strong reference to the realm
@interface RLMWeakNotifier : NSObject
@property (nonatomic, weak) RLMRealm *realm;
@property (nonatomic, strong) void (^stop)();

- (instancetype)initWithRealm:(RLMRealm *)realm;
- (void)notifyOnTargetThread;
@end

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
        [s_realmsPerPath removeAllObjects];
    }
    NSMutableArray *stopBlocks;
    @synchronized (s_notifiersPerPath) {
        if (s_notifiersPerPath.count == 0) {
            return;
        }

        stopBlocks = [NSMutableArray arrayWithCapacity:s_notifiersPerPath.count];
        for (NSMutableSet *set in s_notifiersPerPath.objectEnumerator) {
            if (id stop = [(RLMWeakNotifier *)set.anyObject stop])
                [stopBlocks addObject:stop];
            for (RLMWeakNotifier *notifier in set) {
                notifier.stop = nil;
            }
        }

        [s_notifiersPerPath removeAllObjects];
    }

    // have to call stop() with s_notifiersPerPath unlocked as it waits for
    // something that wants to lock s_notifiersPerPath
    for (void (^stop)() in stopBlocks) {
        stop();
    }
}

void RLMStartListeningForChanges(RLMRealm *realm) {
    @synchronized (s_notifiersPerPath) {
        NSMutableSet *notifiers = s_notifiersPerPath[realm.path];
        if (!notifiers) {
            notifiers = [NSMutableSet new];
            s_notifiersPerPath[realm.path] = notifiers;
        }

        RLMWeakNotifier *notifier = [[RLMWeakNotifier alloc] initWithRealm:realm];
        realm.notifier = notifier;
        // If there's already a realm listening for changes to this path, no need
        // to spawn another listener thread
        if (RLMWeakNotifier *existing = notifiers.anyObject) {
            notifier.stop = existing.stop;
            [notifiers addObject:notifier];
            return;
        }
        [notifiers addObject:notifier];

        dispatch_queue_t queue = dispatch_queue_create(realm.path.UTF8String, 0);
        __block bool cancel = false;
        __block SharedGroup *group = nil;
        notifier.stop = ^{
            cancel = true;
            @synchronized (queue) {
                if (group) {
                    group->wait_for_change_release();
                }
            }

            // wait for the thread to wake up and tear down the SharedGroup to
            // ensure that it doesn't continue to care about the files on disk after
            // the last RLMRealm instance for them is deallocated
            dispatch_sync(queue, ^{});
        };

        NSString *path = realm.path;
        SharedGroup::DurabilityLevel durability = realm->_inMemory ? SharedGroup::durability_MemOnly
                                                                   : SharedGroup::durability_Full;

        dispatch_async(queue, ^{
            std::unique_ptr<Replication> replication(tightdb::makeWriteLogCollector(path.UTF8String));
            SharedGroup sg(*replication, durability);
            @synchronized(queue) {
                group = &sg;
            }
            sg.begin_read();

            while (!cancel && sg.wait_for_change() && !cancel) {
                // we don't have any accessors, so just start a new read transaction
                // rather than using advance_read() as that does far more work
                sg.end_read();
                sg.begin_read();

                @synchronized (s_notifiersPerPath) {
                    for (RLMWeakNotifier *notifier in notifiers) {
                        [notifier notifyOnTargetThread];
                    }
                }
            }

            @synchronized (queue) {
                group = nil;
            }
        });
    }
}

void RLMStopListeningForChanges(RLMRealm *realm) {
    if (!realm.notifier) {
        return;
    }

    dispatch_block_t stop = nil;

    @synchronized (s_notifiersPerPath) {
        NSMutableSet *notifiers = s_notifiersPerPath[realm.path];
        [notifiers removeObject:realm.notifier];

        if (notifiers && notifiers.count == 0) {
            stop = realm.notifier.stop;
            [s_notifiersPerPath removeObjectForKey:realm.path];
        }
    }

    // Needs to be called with s_notifiersPerPath unlocked
    if (stop) {
        stop();
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
