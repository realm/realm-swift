////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMSyncUser+ObjectServerTests.h"

#import "RLMSyncSession_Private.h"
#import "RLMSyncSessionHandle.hpp"

@interface RLMSyncSession ()
- (RLMSyncSessionHandle *)sessionHandle;
@end

@implementation RLMSyncUser (ObjectServerTests)

- (void)waitForUploadToFinish:(NSURL *)url {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    RLMSyncSession *session = [self sessionForURL:url];
    NSAssert(session, @"Cannot call with invalid URL");
    [[session sessionHandle] waitForUploadCompletionOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                                                   callback:^{
                                                       dispatch_semaphore_signal(sema);
                                                   }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

- (void)waitForDownloadToFinish:(NSURL *)url {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    RLMSyncSession *session = [self sessionForURL:url];
    NSAssert(session, @"Cannot call with invalid URL");
    [[session sessionHandle] waitForDownloadCompletionOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                                                     callback:^{
                                                         dispatch_semaphore_signal(sema);
                                                     }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

@end
