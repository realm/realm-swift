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

#import "RLMSyncSessionHandle.hpp"

#import "sync_session.hpp"

using namespace realm;

@interface RLMSyncWeakSessionHandle : RLMSyncSessionHandle {
@public
    std::weak_ptr<SyncSession> _ptr;
}
@end

@interface RLMSyncStrongSessionHandle : RLMSyncSessionHandle {
@public
    std::shared_ptr<SyncSession> _ptr;
}
@end

#pragma mark - Weak session handle

@implementation RLMSyncWeakSessionHandle

- (BOOL)sessionIsInErrorState {
    if (auto pointer = _ptr.lock()) {
        return !(pointer->is_valid());
    }
    return NO;
}

- (BOOL)sessionStillExists {
    return bool(_ptr.lock()) == true;
}

- (BOOL)refreshAccessToken:(NSString *)accessToken serverURL:(NSURL *)serverURL {
    if (auto pointer = _ptr.lock()) {
        pointer->refresh_access_token(accessToken.UTF8String,
                                      serverURL ? util::make_optional<std::string>(serverURL.absoluteString.UTF8String)
                                                : util::none);
        return YES;
    }
    return NO;
}

- (void)logOut {
    if (auto pointer = _ptr.lock()) {
        pointer->log_out();
    }
}

- (void)revive {
    if (auto pointer = _ptr.lock()) {
        pointer->revive_if_needed();
    }
}

- (BOOL)waitForUploadCompletionOnQueue:(dispatch_queue_t)queue
                              callback:(void(^)(void))callback {
    if (auto pointer = _ptr.lock()) {
        queue = queue ?: dispatch_get_main_queue();
        pointer->wait_for_upload_completion([=](){
            dispatch_async(queue, ^{
                callback();
            });
        });
        return YES;
    }
    return NO;
}

- (BOOL)waitForDownloadCompletionOnQueue:(dispatch_queue_t)queue
                                callback:(void(^)(void))callback {
    if (auto pointer = _ptr.lock()) {
        queue = queue ?: dispatch_get_main_queue();
        pointer->wait_for_download_completion([=](){
            dispatch_async(queue, ^{
                callback();
            });
        });
        return YES;
    }
    return NO;
}

@end

#pragma mark - Strong session handle

@implementation RLMSyncStrongSessionHandle

- (BOOL)sessionIsInErrorState {
    return !(_ptr->is_valid());
}

- (BOOL)sessionStillExists {
    return YES;
}

- (BOOL)refreshAccessToken:(NSString *)accessToken serverURL:(NSURL *)serverURL {
    _ptr->refresh_access_token(accessToken.UTF8String,
                               serverURL ? util::make_optional<std::string>(serverURL.absoluteString.UTF8String)
                                         : util::none);
    return YES;
}

- (void)logOut {
    _ptr->log_out();
}

- (void)revive {
    _ptr->revive_if_needed();
}

- (BOOL)waitForUploadCompletionOnQueue:(dispatch_queue_t)queue
                              callback:(void(^)(void))callback {
    queue = queue ?: dispatch_get_main_queue();
    _ptr->wait_for_upload_completion([=](){
        dispatch_async(queue, ^{
            callback();
        });
    });
    return YES;
}

- (BOOL)waitForDownloadCompletionOnQueue:(dispatch_queue_t)queue
                                callback:(void(^)(void))callback {
    queue = queue ?: dispatch_get_main_queue();
    _ptr->wait_for_download_completion([=](){
        dispatch_async(queue, ^{
            callback();
        });
    });
    return YES;
}

@end

#pragma mark - Abstract base class

@implementation RLMSyncSessionHandle

+ (instancetype)syncSessionHandleForWeakPointer:(std::shared_ptr<SyncSession>)session {
    RLMSyncWeakSessionHandle *h = [[RLMSyncWeakSessionHandle alloc] init];
    h->_ptr = std::move(session);
    return h;
}

+ (instancetype)syncSessionHandleForPointer:(std::shared_ptr<SyncSession>)session {
    RLMSyncStrongSessionHandle *h = [[RLMSyncStrongSessionHandle alloc] init];
    h->_ptr = std::move(session);
    return h;
}

- (void)logOut {
    NSAssert(NO, @"Subclasses must override...");
}

- (BOOL)sessionIsInErrorState {
    NSAssert(NO, @"Subclasses must override...");
    return NO;
}

- (BOOL)sessionStillExists {
    NSAssert(NO, @"Subclasses must override...");
    return NO;
}

- (BOOL)refreshAccessToken:(__unused NSString *)accessToken serverURL:(__unused NSURL *)serverURL {
    NSAssert(NO, @"Subclasses must override...");
    return NO;
}

- (void)revive {
    NSAssert(NO, @"Subclasses must override...");
}

- (BOOL)waitForUploadCompletionOnQueue:(__unused dispatch_queue_t)queue
                              callback:(__unused void(^)(void))callback {
    NSAssert(NO, @"Subclasses must override...");
    return NO;
}

- (BOOL)waitForDownloadCompletionOnQueue:(__unused dispatch_queue_t)queue
                                callback:(__unused void(^)(void))callback {
    NSAssert(NO, @"Subclasses must override...");
    return NO;
}

@end
