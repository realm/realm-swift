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
#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMScheduler.h"
#import "RLMSyncSubscription_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/exceptions.hpp>
#import <realm/object-store/sync/async_open_task.hpp>
#import <realm/object-store/sync/sync_session.hpp>
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
    void (^_completion)(NSError *);

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
        // Cancelling realm::AsyncOpenTask results in it never calling our callback,
        // so if we're currently in that we have to just send the cancellation
        // error immediately. In all other cases, though, we want to wait until
        // we've actually cancelled and will send the error the next time we
        // check for cancellation
        [self reportError:s_canceledError];
    }
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
    __weak auto weakSelf = self;
    [self waitWithCompletion:^(NSError *error) {
        RLMRealm *realm;
        if (auto self = weakSelf) {
            realm = self->_localRealm;
            self->_localRealm = nil;
        }
        completion(realm, error);
    }];
}

- (void)waitWithCompletion:(void (^)(NSError *))completion {
    std::lock_guard lock(_mutex);
    _completion = completion;
    if (_cancel) {
        return [self reportError:s_canceledError];
    }

    // get_synchronized_realm() synchronously opens the DB and performs file-format
    // upgrades, so we want to dispatch to the background before invoking it.
    dispatch_async(s_async_open_queue, ^{
        @autoreleasepool {
            [self startAsyncOpen];
        }
    });
}

// The full async open flow is:
// 1. Dispatch to a background queue
// 2. Use Realm::get_synchronized_realm() to create the Realm file, run
//    migrations and compactions, and download the latest data from the server.
// 3. Dispatch back to queue
// 4. Initialize a RLMRealm in the background queue to perform the SDK
//    initialization (e.g. creating managed accessor classes).
// 5. Wait for initial flexible sync subscriptions to complete
// 6. Dispatch to the final scheduler
// 7. Open the final RLMRealm, release the previously opened background one,
//    and then invoke the completion callback.
//
// Steps 2 and 5 are skipped for non-sync or non-flexible sync Realms, in which
// case step 4 will handle doing migrations and compactions etc. in the background.
//
// At any point `cancel` can be called from another thread. Cancellation is mostly
// cooperative rather than preemptive: we check at each step if we've been cancelled,
// and if so call the completion with the cancellation error rather than
// proceeding. Downloading the data from the server is the one exception to this.
// Ideally waiting for flexible sync subscriptions would also be preempted.
- (void)startAsyncOpen {
    std::unique_lock lock(_mutex);
    if ([self checkCancellation]) {
        return;
    }

    if (_waitForDownloadCompletion && _configuration.configRef.sync_config) {
#if REALM_ENABLE_SYNC
        _task = realm::Realm::get_synchronized_realm(_configuration.config);
        for (auto& block : _progressBlocks) {
            _task->register_download_progress_notifier(block);
        }
        _progressBlocks.clear();
        _task->start([=](realm::ThreadSafeReference ref, std::exception_ptr err) {
            std::lock_guard lock(_mutex);
            if ([self checkCancellation]) {
                return;
            }
            // Note that cancellation intentionally trumps reporting other kinds
            // of errors
            if (err) {
                return [self reportException:err];
            }

            // Dispatch blocks can only capture copyable types, so we need to
            // resolve the TSR to a shared_ptr<Realm>
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
        // We're not downloading first, so just proceed directly to the next step.
        lock.unlock();
        [self downloadCompleted];
    }
}

- (void)downloadCompleted {
    std::unique_lock lock(_mutex);
    _task.reset();
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
                                                        timeout:0
                                                completionBlock:^(NSError *error) {
                if (error) {
                    std::lock_guard lock(_mutex);
                    return [self reportError:error];
                }
                [self asyncOpenCompleted];
            }];
        }
    }
#endif
    lock.unlock();
    [self asyncOpenCompleted];
}

- (void)asyncOpenCompleted {
    std::lock_guard lock(_mutex);
    if (![self checkCancellation]) {
        [_scheduler invoke:^{
            [self openFinalRealmAndCallCompletion];
        }];
    }
}

- (void)openFinalRealmAndCallCompletion {
    std::unique_lock lock(_mutex);
    @autoreleasepool {
        if ([self checkCancellation]) {
            return;
        }
        if (!_completion) {
            return;
        }
        NSError *error;
        auto completion = _completion;
        // It should not actually be possible for this to fail
        _localRealm = [RLMRealm realmWithConfiguration:_configuration
                                            confinedTo:_scheduler
                                                 error:&error];
        [self releaseResources];

        lock.unlock();
        completion(error);
    }
}

- (bool)checkCancellation {
    if (_cancel && _completion) {
        [self reportError:s_canceledError];
    }
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
    if (!_completion || !_scheduler) {
        return;
    }

    auto completion = _completion;
    auto scheduler = _scheduler;
    [self releaseResources];
    [scheduler invoke:^{
        completion(error);
    }];
}

- (void)releaseResources {
    _backgroundRealm = nil;
    _configuration = nil;
    _scheduler = nil;
    _completion = nil;
}
@end

@implementation RLMAsyncDownloadTask {
    RLMUnfairMutex _mutex;
    std::shared_ptr<realm::SyncSession> _session;
    bool _started;
}

- (instancetype)initWithRealm:(RLMRealm *)realm {
    if (self = [super init]) {
        _session = realm->_realm->sync_session();
    }
    return self;
}

- (void)waitWithCompletion:(void (^)(NSError *_Nullable))completion {
    std::unique_lock lock(_mutex);
    if (!_session) {
        lock.unlock();
        return completion(nil);
    }

    _started = true;
    _session->revive_if_needed();
    _session->wait_for_download_completion([=](realm::Status status) {
        completion(makeError(status));
    });
}

- (void)cancel {
    std::unique_lock lock(_mutex);
    if (_started) {
        _session->force_close();
    }
    _session = nullptr;
}
@end

__attribute__((objc_direct_members))
@implementation RLMAsyncRefreshTask {
    RLMUnfairMutex _mutex;
    void (^_completion)(bool);
    bool _complete;
    bool _didRefresh;
}

- (void)complete:(bool)didRefresh {
    void (^completion)(bool);
    {
        std::lock_guard lock(_mutex);
        std::swap(completion, _completion);
        _complete = true;
        // If we're both cancelled and did complete a refresh then continue
        // to report true
        _didRefresh = _didRefresh || didRefresh;
    }
    if (completion) {
        completion(didRefresh);
    }
}

- (void)wait:(void (^)(bool))completion {
    bool didRefresh;
    {
        std::lock_guard lock(_mutex);
        if (!_complete) {
            _completion = completion;
            return;
        }
        didRefresh = _didRefresh;
    }
    completion(didRefresh);
}

+ (RLMAsyncRefreshTask *)completedRefresh {
    static RLMAsyncRefreshTask *shared = [] {
        auto refresh = [[RLMAsyncRefreshTask alloc] init];
        refresh->_complete = true;
        refresh->_didRefresh = true;
        return refresh;
    }();
    return shared;
}
@end

@implementation RLMAsyncWriteTask {
    // Mutex guards _realm and _completion
    RLMUnfairMutex _mutex;

    // _realm is non-nil only while waiting for an async write to begin. It is
    // set to `nil` when it either completes or is cancelled.
    RLMRealm *_realm;
    dispatch_block_t _completion;

    RLMAsyncTransactionId _id;
}

// No locking needed for these two as they have to be called before the
// cancellation handler is set up
- (instancetype)initWithRealm:(RLMRealm *)realm {
    if (self = [super init]) {
        _realm = realm;
    }
    return self;
}
- (void)setTransactionId:(RLMAsyncTransactionId)transactionID {
    _id = transactionID;
}

- (void)complete:(bool)cancel {
    // The swap-under-lock pattern is used to avoid invoking the callback with
    // a lock held
    dispatch_block_t completion;
    {
        std::lock_guard lock(_mutex);
        std::swap(completion, _completion);
        if (cancel) {
            // This is a no-op if cancellation is coming after the wait completed
            [_realm cancelAsyncTransaction:_id];
        }
        _realm = nil;
    }
    if (completion) {
        completion();
    }
}

- (void)wait:(void (^)())completion {
    {
        std::lock_guard lock(_mutex);
        // `_realm` being non-nil means it's neither completed nor been cancelled
        if (_realm) {
            _completion = completion;
            return;
        }
    }

    // It has either been completed or cancelled, so call the callback immediately
    completion();
}
@end

@implementation RLMAsyncSubscriptionTask {
    RLMUnfairMutex _mutex;

    RLMSyncSubscriptionSet *_subscriptionSet;
    dispatch_queue_t _queue;
    NSTimeInterval _timeout;
    void (^_completion)(NSError *);

    dispatch_block_t _worker;
}

- (instancetype)initWithSubscriptionSet:(RLMSyncSubscriptionSet *)subscriptionSet
                                  queue:(nullable dispatch_queue_t)queue
                                timeout:(NSTimeInterval)timeout
                             completion:(void(^)(NSError *))completion {
    if (!(self = [super init])) {
        return self;
    }

    _subscriptionSet = subscriptionSet;
    _queue = queue;
    _timeout = timeout;
    _completion = completion;

    return self;
}

- (void)waitForSubscription {
    std::lock_guard lock(_mutex);

    if (_timeout != 0) {
        // Setup timer
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_timeout * NSEC_PER_SEC));
        // If the call below doesn't return after `time` seconds, the internal completion is called with an error.
        _worker = dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
            NSString* errorMessage = [NSString stringWithFormat:@"Waiting for update timed out after %.01f seconds.", _timeout];
            NSError* error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ETIMEDOUT userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
            [self invokeCompletionWithError:error];
        });

        dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), _worker);
    }

    [self waitForSync];
}

-(void)waitForSync {
    if (_completion) {
        _subscriptionSet->_subscriptionSet->get_state_change_notification(realm::sync::SubscriptionSet::State::Complete)
            .get_async([self](realm::StatusWith<realm::sync::SubscriptionSet::State> state) noexcept {
                NSError *error = makeError(state);
                [self invokeCompletionWithError:error];
            });
    }
}

-(void)invokeCompletionWithError:(NSError * _Nullable)error {
    void (^completion)(NSError *);
    {
        std::lock_guard lock(_mutex);
        std::swap(completion, _completion);
    }

    if (_worker) {
        dispatch_block_cancel(_worker);
        _worker = nil;
    }

    if (completion) {
        if (_queue) {
            dispatch_async(_queue, ^{
                completion(error);
            });
            return;
        }

        completion(error);
    }
}
@end
