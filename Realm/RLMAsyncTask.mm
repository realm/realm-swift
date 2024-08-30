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
#import "RLMUtil.hpp"

#import <realm/exceptions.hpp>
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
    bool _cancel;

    RLMRealmConfiguration *_configuration;
    RLMScheduler *_scheduler;
    void (^_completion)(NSError *);

    RLMRealm *_backgroundRealm;
}

- (void)cancel {
    std::lock_guard lock(_mutex);
    _cancel = true;
}

- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration
                           confinedTo:(RLMScheduler *)scheduler {
    if (!(self = [super init])) {
        return self;
    }

    // Copying the configuration here as the user could potentially modify
    // the config after calling async open
    _configuration = configuration.copy;
    _scheduler = scheduler;

    return self;
}

- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration
                           confinedTo:(RLMScheduler *)confinement
                           completion:(RLMAsyncOpenRealmCallback)completion {
    self = [self initWithConfiguration:configuration confinedTo:confinement];
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

    dispatch_async(s_async_open_queue, ^{
        @autoreleasepool {
            [self startAsyncOpen];
        }
    });
}

- (void)startAsyncOpen {
    std::unique_lock lock(_mutex);
    if ([self checkCancellation]) {
        return;
    }

    NSError *error;
    @autoreleasepool {
        // Holding onto the Realm so that opening the final Realm on the target
        // scheduler can hit the fast path
        _backgroundRealm = [RLMRealm realmWithConfiguration:_configuration
                                                 confinedTo:RLMScheduler.currentRunLoop error:&error];
        if (error) {
            return [self reportError:error];
        }
    }
    if ([self checkCancellation]) {
        return;
    }

    [_scheduler invoke:^{
        [self openFinalRealmAndCallCompletion];
    }];
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
