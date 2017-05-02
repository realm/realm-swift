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

#import "RLMSyncSession_Private.hpp"
#import "RLMRealmUtil.hpp"

#import "sync/sync_session.hpp"

using namespace realm;

@implementation RLMSyncUser (ObjectServerTests)

- (BOOL)waitForUploadToFinish:(NSURL *)url {
    const NSTimeInterval timeout = 20;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    RLMSyncSession *session = [self sessionForURL:url];
    NSAssert(session, @"Cannot call with invalid URL");
    BOOL couldWait = [session waitForUploadCompletionOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                                                    callback:^(NSError *){
                                                        dispatch_semaphore_signal(sema);
                                                    }];
    if (!couldWait) {
        return NO;
    }
    return dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0;
}

- (BOOL)waitForDownloadToFinish:(NSURL *)url {
    const NSTimeInterval timeout = 20;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    RLMSyncSession *session = [self sessionForURL:url];
    NSAssert(session, @"Cannot call with invalid URL");
    BOOL couldWait = [session waitForDownloadCompletionOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                                                      callback:^(NSError *){
                                                          dispatch_semaphore_signal(sema);
                                                      }];
    if (!couldWait) {
        return NO;
    }
    return dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0;
}

- (void)simulateClientResetErrorForSession:(NSURL *)url {
    RLMSyncSession *session = [self sessionForURL:url];
    NSAssert(session, @"Cannot call with invalid URL");

    std::shared_ptr<SyncSession> raw_session = session->_session.lock();
    std::error_code code = std::error_code{
        static_cast<int>(realm::sync::ProtocolError::bad_client_file_ident),
        realm::sync::protocol_error_category()
    };
    SyncSession::OnlyForTesting::handle_error(*raw_session, {code, "Not a real error message", false});
}

@end

bool RLMHasCachedRealmForPath(NSString *path) {
    return RLMGetAnyCachedRealmForPath(path.UTF8String);
}
