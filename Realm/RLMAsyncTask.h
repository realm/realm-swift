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
#import <Realm/RLMSyncSession.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

/**
 A task object which can be used to observe or cancel an async open.

 When a synchronized Realm is opened asynchronously, the latest state of the
 Realm is downloaded from the server before the completion callback is invoked.
 This task object can be used to observe the state of the download or to cancel
 it. This should be used instead of trying to observe the download via the sync
 session as the sync session itself is created asynchronously, and may not exist
 yet when -[RLMRealm asyncOpenWithConfiguration:completion:] returns.
 */
RLM_SWIFT_SENDABLE RLM_FINAL // is internally thread-safe
@interface RLMAsyncOpenTask : NSObject
/**
 Register a progress notification block.

 Each registered progress notification block is called whenever the sync
 subsystem has new progress data to report until the task is either cancelled
 or the completion callback is called. Progress notifications are delivered on
 the main queue.
 */
- (void)addProgressNotificationBlock:(RLMProgressNotificationBlock)block;

/**
 Register a progress notification block which is called on the given queue.

 Each registered progress notification block is called whenever the sync
 subsystem has new progress data to report until the task is either cancelled
 or the completion callback is called. Progress notifications are delivered on
 the supplied queue.
 */
- (void)addProgressNotificationOnQueue:(dispatch_queue_t)queue
                                 block:(RLMProgressNotificationBlock)block;

/**
 Cancel the asynchronous open.

 Any download in progress will be cancelled, and the completion block for this
 async open will never be called. If multiple async opens on the same Realm are
 happening concurrently, all other opens will fail with the error "operation cancelled".
 */
- (void)cancel;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
