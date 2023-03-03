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

#include <realm/object-store/util/scheduler.hpp>

@interface RLMMainRunLoopScheduler : RLMScheduler
@end

__attribute__((visibility("hidden")))
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
@end

@interface RLMDispatchQueueScheduler : RLMScheduler
@end

__attribute__((visibility("hidden")))
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

@implementation RLMScheduler
+ (RLMScheduler *)currentRunLoop {
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

- (void)invoke:(dispatch_block_t)block {
    // Currently not used or needed for run loops
    REALM_UNREACHABLE();
}

- (std::shared_ptr<realm::util::Scheduler>)osScheduler {
    // For normal thread-confined Realms we let object store create the scheduler
    return nullptr;
}

- (void *)cacheKey {
    if (pthread_main_np()) {
        return RLMScheduler.mainRunLoop.cacheKey;
    }
    return pthread_self();
}
@end
