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

#import <Realm/RLMConstants.h>

#ifdef __cplusplus
#include <memory>
namespace realm::util {
class Scheduler;
}
#endif

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

// A serial work queue of some sort which represents a thread-confinement context
// of some sort which blocks can be invoked inside. Realms are confined to a
// scheduler, which can be a thread (actually a run loop), a dispatch queue, or
// an actor. The scheduler ensures that the Realm is only used on one thread at
// a time, and allows us to dispatch work to the thread where we can access the
// Realm safely.
RLM_SWIFT_SENDABLE // is immutable
@interface RLMScheduler : NSObject
+ (RLMScheduler *)mainRunLoop __attribute__((objc_direct));
+ (RLMScheduler *)currentRunLoop __attribute__((objc_direct));
// A scheduler for the given queue if it's non-nil, and currentRunLoop otherwise
+ (RLMScheduler *)dispatchQueue:(nullable dispatch_queue_t)queue;

// Invoke the block on this scheduler. Currently not actually implement for run
// loop schedulers.
- (void)invoke:(dispatch_block_t)block;

// Cache key for this scheduler suitable for use with NSMapTable. Only valid
// when called from the current scheduler.
- (void *)cacheKey;

#ifdef __cplusplus
// The object store Scheduler corresponding to this scheduler
- (std::shared_ptr<realm::util::Scheduler>)osScheduler;
#endif
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
