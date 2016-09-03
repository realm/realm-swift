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

@end

@implementation RLMSyncStrongSessionHandle

- (BOOL)sessionIsInErrorState {
    return !(_ptr->is_valid());
}

- (BOOL)sessionStillExists {
    return YES;
}

- (BOOL)refreshAccessToken:(NSString *)accessToken serverURL:(NSURL *)serverURL {
    _ptr->refresh_access_token(accessToken.UTF8String,
                               serverURL ? util::none
                               : util::make_optional<std::string>(serverURL.absoluteString.UTF8String));
    return YES;
}

- (void)logOut {
    _ptr->log_out();
}

@end

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

@end
