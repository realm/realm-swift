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

#import "RLMSyncSession_Private.hpp"

#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncUser_Private.hpp"
#import "sync/sync_session.hpp"

using namespace realm;

@interface RLMSyncSession () {
    std::weak_ptr<SyncSession> _session;
}

@end

@implementation RLMSyncSession

- (instancetype)initWithSyncSession:(std::shared_ptr<SyncSession>)session {
    if (self = [super init]) {
        _session = session;
        return self;
    }
    return nil;
}

- (RLMSyncConfiguration *)configuration {
    if (auto session = _session.lock()) {
        if (session->state() != SyncSession::PublicState::Error) {
            return [[RLMSyncConfiguration alloc] initWithRawConfig:session->config()];
        }
    }
    return nil;
}

- (NSURL *)realmURL {
    if (auto session = _session.lock()) {
        if (auto url = session->full_realm_url()) {
            return [NSURL URLWithString:@(url->c_str())];
        }
    }
    return nil;
}

- (RLMSyncUser *)parentUser {
    if (auto session = _session.lock()) {
        if (session->state() != SyncSession::PublicState::Error) {
            return [[RLMSyncUser alloc] initWithSyncUser:session->user()];
        }
    }
    return nil;
}

- (RLMSyncSessionState)state {
    if (auto session = _session.lock()) {
        if (session->state() == SyncSession::PublicState::Inactive) {
            return RLMSyncSessionStateInactive;
        }
        if (session->state() != SyncSession::PublicState::Error) {
            return RLMSyncSessionStateActive;
        }
    }
    return RLMSyncSessionStateInvalid;
}

- (BOOL)waitForUploadCompletionOnQueue:(dispatch_queue_t)queue callback:(void(^)(void))callback {
    if (auto session = _session.lock()) {
        if (session->state() == SyncSession::PublicState::Error) {
            return NO;
        }
        queue = queue ?: dispatch_get_main_queue();
        session->wait_for_upload_completion([=](std::error_code) { // FIXME: report error to user
            dispatch_async(queue, callback);
        });
        return YES;
    }
    return NO;
}

- (BOOL)waitForDownloadCompletionOnQueue:(dispatch_queue_t)queue callback:(void(^)(void))callback {
    if (auto session = _session.lock()) {
        if (session->state() == SyncSession::PublicState::Error) {
            return NO;
        }
        queue = queue ?: dispatch_get_main_queue();
        session->wait_for_download_completion([=](std::error_code) { // FIXME: report error to user
            dispatch_async(queue, callback);
        });
        return YES;
    }
    return NO;
}

@end
