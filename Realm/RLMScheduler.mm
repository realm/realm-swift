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

#import "RLMScheduler.h"

#import "RLMUtil.hpp"

#include <realm/object-store/util/scheduler.hpp>

@interface RLMMainRunLoopScheduler : RLMScheduler
@end

RLM_HIDDEN
@implementation RLMMainRunLoopScheduler
- (std::shared_ptr<realm::util::Scheduler>)osScheduler {
    return realm::util::Scheduler::make_runloop(CFRunLoopGetMain());
}

- (void *)cacheKey {
    // The main thread and main queue share a cache key of `std::numeric_limits<uintptr_t>::max()`
    // so that they give the same instance. Other Realms are keyed on either the thread or the queue.
    // Note that despite being a void* the cache key is not actually a pointer;
    // this is just an artifact of NSMapTable's strange API.
    return reinterpret_cast<void *>(std::numeric_limits<uintptr_t>::max());
}

// We can't access MainActor.shared directly from obj-c and need to set it from
// Swift. The locking here is _almost_ unnecessary as this is set from a static
// initializer before the value can ever be read, but mixed use of the obj-c and
// Swift APIs could potentially race on the read.
static auto& g_mainActorLock = *new RLMUnfairMutex;
static id g_mainActor;
void RLMSetMainActor(id actor) {
    std::lock_guard lock(g_mainActorLock);
    g_mainActor = actor;
}
- (id)actor {
    std::lock_guard lock(g_mainActorLock);
    return g_mainActor;
}

- (void)invoke:(dispatch_block_t)block {
    dispatch_async(dispatch_get_main_queue(), block);
}
@end

@interface RLMDispatchQueueScheduler : RLMScheduler
@end

RLM_HIDDEN
@implementation RLMDispatchQueueScheduler {
    dispatch_queue_t _queue;
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    if (self = [super init]) {
        _queue = queue;
    }
    return self;
}

- (void)invoke:(dispatch_block_t)block {
    dispatch_async(_queue, block);
}

- (std::shared_ptr<realm::util::Scheduler>)osScheduler {
    if (_queue == dispatch_get_main_queue()) {
        return RLMScheduler.mainRunLoop.osScheduler;
    }
    return realm::util::Scheduler::make_dispatch((__bridge void *)_queue);
}

- (void *)cacheKey {
    if (_queue == dispatch_get_main_queue()) {
        return RLMScheduler.mainRunLoop.cacheKey;
    }
    return (__bridge void *)_queue;
}
@end

namespace {
class ActorScheduler final : public realm::util::Scheduler {
public:
    ActorScheduler(void (^invoke)(dispatch_block_t), dispatch_block_t verify)
    : _invoke(invoke) , _verify(verify) {}

    void invoke(realm::util::UniqueFunction<void()>&& fn) override {
        auto ptr = fn.release();
        _invoke(^{
            realm::util::UniqueFunction<void()> fn(ptr);
            fn();
        });
    }

    // This currently isn't actually implementable, but fortunately is only used
    // to report errors when we aren't on the thread, so triggering the actor
    // data race detection is good enough.
    bool is_on_thread() const noexcept override {
        _verify();
        return true;
    }

    // This is used for OS Realm caching, which we don't use (as we have our own cache)
    bool is_same_as(const Scheduler *) const noexcept override {
        REALM_UNREACHABLE();
    }

    // Actor isolated Realms can always invoke blocks
    bool can_invoke() const noexcept override {
        return true;
    }

private:
    void (^_invoke)(dispatch_block_t);
    dispatch_block_t _verify;
};
}

@interface RLMActorScheduler : RLMScheduler
@end

RLM_HIDDEN
@implementation RLMActorScheduler {
    id _actor;
    void (^_invoke)(dispatch_block_t);
    void (^_verify)();
}

- (instancetype)initWithActor:(id)actor invoke:(void (^)(dispatch_block_t))invoke verify:(void (^)())verify {
    if (self = [super init]) {
        _actor = actor;
        _invoke = invoke;
        _verify = verify;
    }
    return self;
}

- (void)invoke:(dispatch_block_t)block {
    _invoke(block);
}

- (std::shared_ptr<realm::util::Scheduler>)osScheduler {
    return std::make_shared<ActorScheduler>(_invoke, _verify);
}

- (void *)cacheKey {
    return (__bridge void *)_actor;
}

- (id)actor {
    return _actor;
}
@end

@implementation RLMScheduler
+ (RLMScheduler *)currentRunLoop {
    if (pthread_main_np()) {
        return RLMScheduler.mainRunLoop;
    }

    static RLMScheduler *currentRunLoopScheduler = [[RLMScheduler alloc] init];
    return currentRunLoopScheduler;
}

+ (RLMScheduler *)mainRunLoop {
    static RLMScheduler *mainRunLoopScheduler = [[RLMMainRunLoopScheduler alloc] init];
    return mainRunLoopScheduler;
}

+ (RLMScheduler *)dispatchQueue:(dispatch_queue_t)queue {
    if (queue) {
        return [[RLMDispatchQueueScheduler alloc] initWithQueue:queue];
    }
    return RLMScheduler.currentRunLoop;
}

+ (RLMScheduler *)actor:(id)actor invoke:(void (^)(dispatch_block_t))invoke verify:(void (^)())verify {
    auto mainRunLoopScheduler = RLMScheduler.mainRunLoop;
    if (actor == mainRunLoopScheduler.actor) {
        return mainRunLoopScheduler;
    }
    return [[RLMActorScheduler alloc] initWithActor:actor invoke:invoke verify:verify];
}

- (void)invoke:(dispatch_block_t)block {
    // Currently not used or needed for run loops
    REALM_UNREACHABLE();
}

- (std::shared_ptr<realm::util::Scheduler>)osScheduler {
    // For normal thread-confined Realms we let object store create the scheduler
    return nullptr;
}

- (void *)cacheKey {
    return pthread_self();
}

- (id)actor {
    return nil;
}
@end
