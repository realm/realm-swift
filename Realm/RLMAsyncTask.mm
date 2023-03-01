////////////////////////////////////////////////////////////////////////////
//
// Copyright 2023 Realm Inc.
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

#import "RLMAsyncTask_Private.h"

#import "RLMError_Private.hpp"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMScheduler.h"
#import "RLMSyncSubscription_Private.h"
#import "RLMUtil.hpp"

#import <realm/exceptions.hpp>
#import <realm/object-store/sync/async_open_task.hpp>
#import <realm/object-store/thread_safe_reference.hpp>

static dispatch_queue_t s_async_open_queue = dispatch_queue_create("io.realm.asyncOpenDispatchQueue",
                                                                   DISPATCH_QUEUE_CONCURRENT);
void RLMSetAsyncOpenQueue(dispatch_queue_t queue) {
    s_async_open_queue = queue;
}

static NSError *s_canceledError = [NSError errorWithDomain:NSPOSIXErrorDomain
                                                      code:ECANCELED userInfo:@{
    NSLocalizedDescriptionKey: @"Operation canceled"
}];

__attribute__((objc_direct_members))
@implementation RLMAsyncOpenTask {
    RLMUnfairMutex _mutex;
    std::shared_ptr<realm::AsyncOpenTask> _task;
    std::vector<RLMProgressNotificationBlock> _progressBlocks;
    bool _cancel;

    RLMRealmConfiguration *_configuration;
    RLMScheduler *_scheduler;
    bool _waitForDownloadCompletion;
    RLMAsyncOpenRealmCallback _completion;

    RLMRealm *_backgroundRealm;
}

- (void)addProgressNotificationOnQueue:(dispatch_queue_t)queue block:(RLMProgressNotificationBlock)block {
    auto wrappedBlock = ^(NSUInteger transferred_bytes, NSUInteger transferrable_bytes) {
        dispatch_async(queue, ^{
            @autoreleasepool {
                block(transferred_bytes, transferrable_bytes);
            }
        });
    };

    std::lock_guard lock(_mutex);
    if (_task) {
        _task->register_download_progress_notifier(wrappedBlock);
    }
    else if (!_cancel) {
        _progressBlocks.push_back(wrappedBlock);
    }
}

- (void)addProgressNotificationBlock:(RLMProgressNotificationBlock)block {
    [self addProgressNotificationOnQueue:dispatch_get_main_queue() block:block];
}

- (void)cancel {
    std::lock_guard lock(_mutex);
    _cancel = true;
    _progressBlocks.clear();
    if (_task) {
        _task->cancel();
    }
    [self reportError:s_canceledError];
}

- (void)setTask:(std::shared_ptr<realm::AsyncOpenTask>)task __attribute__((objc_direct)) {
    std::lock_guard lock(_mutex);
    if (_cancel) {
        task->cancel();
        return;
    }

    _task = task;
    for (auto& block : _progressBlocks) {
        _task->register_download_progress_notifier(block);
    }
    _progressBlocks.clear();
}

- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration
                           confinedTo:(RLMScheduler *)scheduler
                             download:(bool)waitForDownloadCompletion {
    if (!(self = [super init])) {
        return self;
    }

    // Copying the configuration here as the user could potentially modify
    // the config after calling async open
    _configuration = configuration.copy;
    _scheduler = scheduler;
    _waitForDownloadCompletion = waitForDownloadCompletion;

    return self;
}

- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration
                           confinedTo:(RLMScheduler *)confinement
                             download:(bool)waitForDownloadCompletion
                           completion:(RLMAsyncOpenRealmCallback)completion {
    self = [self initWithConfiguration:configuration confinedTo:confinement
                              download:waitForDownloadCompletion];
    [self waitForOpen:completion];
    return self;
}

- (void)waitForOpen:(RLMAsyncOpenRealmCallback)completion {
    {
        std::lock_guard lock(_mutex);
        _completion = completion;
        if (_cancel) {
            return [self reportError:s_canceledError];
        }
    }

    // get_synchronized_realm() synchronously opens the DB and performs file-format
    // upgrades, so we want to dispatch to the background before invoking it.
    dispatch_async(s_async_open_queue, ^{
        @autoreleasepool {
            [self startAsyncOpen];
        }
    });
}

- (void)startAsyncOpen {
    if ([self checkCancellation]) {
        return;
    }

    if (_waitForDownloadCompletion && _configuration.configRef.sync_config) {
#if REALM_ENABLE_SYNC
        auto task = realm::Realm::get_synchronized_realm(_configuration.config);
        self.task = task;
        task->start([=](realm::ThreadSafeReference ref, std::exception_ptr err) {
            if ([self checkCancellation]) {
                return;
            }
            if (err) {
                return [self reportException:err];
            }

            auto realm = ref.resolve<std::shared_ptr<realm::Realm>>(nullptr);
            // We're now running on the sync worker thread, so hop back
            // to a more appropriate queue for the next stage of init.
            dispatch_async(s_async_open_queue, ^{
                @autoreleasepool {
                    [self downloadCompleted];
                    // Capture the Realm to keep the RealmCoordinator alive
                    // so that we don't have to reopen it.
                    static_cast<void>(realm);
                }
            });
        });
#else
        @throw RLMException(@"Realm was not built with sync enabled");
#endif
    }
    else {
        // We're not downloading first, so just pretend it completed successfully
        [self downloadCompleted];
    }
}

- (void)downloadCompleted {
    if ([self checkCancellation]) {
        return;
    }

    NSError *error;
    // We've now downloaded all data (if applicable) and done the object
    // store initialization, and are back on our background queue. Next we
    // want to do our own initialization while still in the background
    @autoreleasepool {
        // Holding onto the Realm so that opening the final Realm on the target
        // scheduler can hit the fast path
        _backgroundRealm = [RLMRealm realmWithConfiguration:_configuration
                                                 confinedTo:RLMScheduler.currentRunLoop error:&error];
        if (error) {
            return [self reportError:error];
        }
    }

#if REALM_ENABLE_SYNC
    // If we're opening a flexible sync Realm, we now want to wait for the
    // initial subscriptions to be ready
    if (_waitForDownloadCompletion && _backgroundRealm.isFlexibleSync) {
        auto subscriptions = _backgroundRealm.subscriptions;
        if (subscriptions.state == RLMSyncSubscriptionStatePending) {
            // FIXME: need cancellation for waiting for the subscription
            return [subscriptions waitForSynchronizationOnQueue:nil
                                                completionBlock:^(NSError *error) {
                if (error) {
                    return [self reportError:error];
                }
                [self completeAsyncOpen];
            }];
        }
    }
#endif
    [self completeAsyncOpen];
}

- (void)completeAsyncOpen {
    if ([self checkCancellation]) {
        return;
    }

    [_scheduler invoke:^{
        @autoreleasepool {
            NSError *error;
            RLMRealm *localRealm = [RLMRealm realmWithConfiguration:_configuration
                                                         confinedTo:_scheduler
                                                              error:&error];
            auto completion = _completion;
            [self releaseResources];
            completion(localRealm, error);
        }
    }];
}

- (bool)checkCancellation {
    std::lock_guard lock(_mutex);
    return _cancel;
}

- (void)reportException:(std::exception_ptr const&)err {
    try {
        std::rethrow_exception(err);
    }
    catch (realm::Exception const& e) {
        if (e.code() == realm::ErrorCodes::OperationAborted) {
            return [self reportError:s_canceledError];
        }
        [self reportError:makeError(e)];
    }
    catch (...) {
        NSError *error;
        RLMRealmTranslateException(&error);
        [self reportError:error];
    }
}

- (void)reportError:(NSError *)error {
    auto completion = _completion;
    auto scheduler = _scheduler;
    [self releaseResources];
    [scheduler invoke:^{
        completion(nil, error);
    }];
}

- (void)releaseResources {
    _backgroundRealm = nil;
    _configuration = nil;
    _scheduler = nil;
    _completion = nil;
}
@end
