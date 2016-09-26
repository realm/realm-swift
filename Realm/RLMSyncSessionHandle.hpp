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

#import <Foundation/Foundation.h>
#import <memory>

namespace realm {
struct SyncSession;
}

NS_ASSUME_NONNULL_BEGIN

@interface RLMSyncSessionHandle : NSObject

+ (instancetype)syncSessionHandleForWeakPointer:(std::shared_ptr<realm::SyncSession>)pointer;
+ (instancetype)syncSessionHandleForPointer:(std::shared_ptr<realm::SyncSession>)pointer;

/// Whether the underlying session is in an unrecoverable error state.
- (BOOL)sessionIsInErrorState;

/// Whether the underlying session still exists, if the session reference is weak.
- (BOOL)sessionStillExists;

/// Inform the session that the user that owns it has logged out.
- (void)logOut;

/// Refresh the access token for the session.
- (BOOL)refreshAccessToken:(NSString *)accessToken serverURL:(nullable NSURL *)serverURL;

/// Revive the session.
- (void)revive;

/// Wait for pending uploads to complete or the session to expire, and dispatch the callback onto the specified queue.
- (BOOL)waitForUploadCompletionOnQueue:(nullable dispatch_queue_t)queue callback:(void(^)(void))callback;

/// Wait for pending downloads to complete or the session to expire, and dispatch the callback onto the specified queue.
- (BOOL)waitForDownloadCompletionOnQueue:(nullable dispatch_queue_t)queue callback:(void(^)(void))callback;

@end

NS_ASSUME_NONNULL_END
