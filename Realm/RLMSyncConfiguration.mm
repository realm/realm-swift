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

#import "RLMSyncConfiguration_Private.hpp"

#import "RLMSyncManager_Private.h"
#import "RLMSyncSession_Private.hpp"
#import "RLMSyncUser_Private.hpp"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"

#import "sync/sync_manager.hpp"
#import "sync/sync_config.hpp"

#import <realm/sync/protocol.hpp>

using namespace realm;

namespace {
using ProtocolError = realm::sync::ProtocolError;

RLMSyncSystemErrorKind errorKindForSyncError(SyncError error) {
    if (error.is_client_reset_requested()) {
        return RLMSyncSystemErrorKindClientReset;
    } else if (error.error_code == ProtocolError::bad_authentication) {
        return RLMSyncSystemErrorKindUser;
    } else if (error.is_session_level_protocol_error()) {
        return RLMSyncSystemErrorKindSession;
    } else if (error.is_connection_level_protocol_error()) {
        return RLMSyncSystemErrorKindConnection;
    } else if (error.is_client_error()) {
        return RLMSyncSystemErrorKindClient;
    } else {
        return RLMSyncSystemErrorKindUnknown;
    }
}
}

static BOOL isValidRealmURL(NSURL *url) {
    NSString *scheme = [url scheme];
    if (![scheme isEqualToString:@"realm"] && ![scheme isEqualToString:@"realms"]) {
        return NO;
    }
    return YES;
}

@interface RLMSyncConfiguration () {
    std::unique_ptr<realm::SyncConfig> _config;
}

- (instancetype)initWithUser:(RLMSyncUser *)user
                    realmURL:(NSURL *)url
               customFileURL:(nullable NSURL *)customFileURL
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy
                errorHandler:(std::function<realm::SyncSessionErrorHandler>)errorHandler;
@end

@implementation RLMSyncConfiguration

@dynamic stopPolicy;

- (instancetype)initWithRawConfig:(realm::SyncConfig)config {
    if (self = [super init]) {
        _config = std::make_unique<realm::SyncConfig>(config);
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[RLMSyncConfiguration class]]) {
        return NO;
    }
    RLMSyncConfiguration *that = (RLMSyncConfiguration *)object;
    return [self.realmURL isEqual:that.realmURL]
        && [self.user isEqual:that.user]
        && self.stopPolicy == that.stopPolicy;
}

- (realm::SyncConfig)rawConfiguration {
    return *_config;
}

- (RLMSyncUser *)user {
    return [[RLMSyncUser alloc] initWithSyncUser:_config->user];
}

- (RLMSyncStopPolicy)stopPolicy {
    return translateStopPolicy(_config->stop_policy);
}

- (void)setStopPolicy:(RLMSyncStopPolicy)stopPolicy {
    _config->stop_policy = translateStopPolicy(stopPolicy);
}

- (NSURL *)realmURL {
    NSString *rawStringURL = @(_config->realm_url.c_str());
    return [NSURL URLWithString:rawStringURL];
}

- (instancetype)initWithUser:(RLMSyncUser *)user realmURL:(NSURL *)url {
    return [self initWithUser:user
                     realmURL:url
                customFileURL:nil
                   stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
                 errorHandler:nullptr];
}

- (instancetype)initWithUser:(RLMSyncUser *)user
                    realmURL:(NSURL *)url
               customFileURL:(nullable NSURL *)customFileURL
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy
                errorHandler:(std::function<realm::SyncSessionErrorHandler>)errorHandler {
    if (self = [super init]) {
        if (!isValidRealmURL(url)) {
            @throw RLMException(@"The provided URL (%@) was not a valid Realm URL.", [url absoluteString]);
        }
        auto bindHandler = [=](auto&,
                               const SyncConfig& config,
                               const std::shared_ptr<SyncSession>& session) {
            [user _bindSessionWithConfig:config
                                 session:session
                              completion:[RLMSyncManager sharedManager].sessionCompletionNotifier];
        };
        if (!errorHandler) {
            errorHandler = [=](std::shared_ptr<SyncSession> errored_session,
                               SyncError error) {
                RLMSyncSession *session = [[RLMSyncSession alloc] initWithSyncSession:errored_session];
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:error.user_info.size()];
                for (auto& pair : error.user_info) {
                    userInfo[@(pair.first.c_str())] = @(pair.second.c_str());
                }
                // FIXME: how should the binding respond if the `is_fatal` bool is true?
                [[RLMSyncManager sharedManager] _fireErrorWithCode:error.error_code.value()
                                                           message:@(error.message.c_str())
                                                           isFatal:error.is_fatal
                                                           session:session
                                                          userInfo:userInfo
                                                        errorClass:errorKindForSyncError(error)];
            };
        }

        _config = std::make_unique<SyncConfig>(SyncConfig{
            [user _syncUser],
            [[url absoluteString] UTF8String],
            translateStopPolicy(stopPolicy),
            std::move(bindHandler),
            std::move(errorHandler)
        });
        self.customFileURL = customFileURL;
        return self;
    }
    return nil;
}

@end
