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

using namespace realm;

namespace {
RLMSyncSessionErrorKind errorKindForSessionError(SyncSessionError error) {
    switch (error) {
        case SyncSessionError::AccessDenied:    return RLMSyncSessionErrorKindAccessDenied;
        case SyncSessionError::Debug:           return RLMSyncSessionErrorKindDebug;
        case SyncSessionError::SessionFatal:    return RLMSyncSessionErrorKindSessionFatal;
        case SyncSessionError::UserFatal:       return RLMSyncSessionErrorKindUserFatal;
    }
    REALM_UNREACHABLE();
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
        auto bindHandler = [=](const std::string& path,
                              const SyncConfig& config,
                              const std::shared_ptr<SyncSession>& session) {
            [user _bindSessionWithPath:path
                                config:config
                               session:session
                            completion:[RLMSyncManager sharedManager].sessionCompletionNotifier
                          isStandalone:NO];
        };
        if (!errorHandler) {
            errorHandler = [=](std::shared_ptr<SyncSession> errored_session,
                               int error_code,
                               std::string message,
                               realm::SyncSessionError error_type) {
                RLMSyncSession *session = [[RLMSyncSession alloc] initWithSyncSession:errored_session];
                [[RLMSyncManager sharedManager] _fireErrorWithCode:error_code
                                                           message:@(message.c_str())
                                                           session:session
                                                        errorClass:errorKindForSessionError(error_type)];
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
