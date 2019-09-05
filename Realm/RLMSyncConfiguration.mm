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

#import "RLMRealmConfiguration+Sync.h"
#import "RLMSyncManager_Private.h"
#import "RLMSyncSession_Private.hpp"
#import "RLMSyncSessionRefreshHandle.hpp"
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
    } else if (error.error_code == ProtocolError::permission_denied) {
        return RLMSyncSystemErrorKindPermissionDenied;
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

BOOL isValidRealmURL(NSURL *url) {
    NSString *scheme = [url scheme];
    return [scheme isEqualToString:@"realm"] || [scheme isEqualToString:@"realms"];
}
}

@interface RLMSyncConfiguration () {
    std::unique_ptr<realm::SyncConfig> _config;
}

- (instancetype)initWithUser:(RLMSyncUser *)user
                    realmURL:(NSURL *)url
               customFileURL:(nullable NSURL *)customFileURL
                   isPartial:(BOOL)isPartial
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy
                errorHandler:(std::function<realm::SyncSessionErrorHandler>)errorHandler;
@end

@implementation RLMSyncConfiguration

@dynamic stopPolicy;

- (instancetype)initWithRawConfig:(realm::SyncConfig)config {
    if (self = [super init]) {
        _config = std::make_unique<realm::SyncConfig>(std::move(config));
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
        && self.stopPolicy == that.stopPolicy
        && self.fullSynchronization == that.fullSynchronization;
}

- (void)setEnableSSLValidation:(BOOL)enableSSLValidation {
    _config->client_validate_ssl = (bool)enableSSLValidation;
}

- (BOOL)enableSSLValidation {
    return (BOOL)_config->client_validate_ssl;
}

- (void)setIsPartial:(BOOL)isPartial {
    _config->is_partial = (bool)isPartial;
}

- (NSURL *)pinnedCertificateURL {
    if (auto& path = _config->ssl_trust_certificate_path) {
        return [NSURL fileURLWithPath:RLMStringDataToNSString(*path)];
    }
    return nil;
}

- (void)setPinnedCertificateURL:(NSURL *)pinnedCertificateURL {
    if (pinnedCertificateURL) {
        if ([pinnedCertificateURL respondsToSelector:@selector(UTF8String)]) {
            _config->ssl_trust_certificate_path = std::string([(id)pinnedCertificateURL UTF8String]);
        }
        else {
            _config->ssl_trust_certificate_path = std::string(pinnedCertificateURL.path.UTF8String);
        }
    }
    else {
        _config->ssl_trust_certificate_path = util::none;
    }
}


- (BOOL)isPartial {
    return (BOOL)_config->is_partial;
}

- (void)setFullSynchronization:(BOOL)fullSynchronization {
    _config->is_partial = !(bool)fullSynchronization;
}

- (BOOL)fullSynchronization {
    return !(BOOL)_config->is_partial;
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

- (NSString *)urlPrefix {
    if (_config->url_prefix) {
        return @(_config->url_prefix->c_str());
    }
    return nil;
}

- (void)setUrlPrefix:(NSString *)urlPrefix {
    if (urlPrefix) {
        _config->url_prefix.emplace(urlPrefix.UTF8String);
    } else {
        _config->url_prefix = none;
    }
}

- (NSURL *)realmURL {
    NSString *rawStringURL = @(_config->reference_realm_url.c_str());
    return [NSURL URLWithString:rawStringURL];
}

- (instancetype)initWithUser:(RLMSyncUser *)user realmURL:(NSURL *)url {
    return [self initWithUser:user
                     realmURL:url
                customFileURL:nil
                    isPartial:NO
                   stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
                 errorHandler:nullptr];
}

- (instancetype)initWithUser:(RLMSyncUser *)user
                    realmURL:(NSURL *)url
                   isPartial:(BOOL)isPartial
                   urlPrefix:(NSString *)urlPrefix
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy
         enableSSLValidation:(BOOL)enableSSLValidation
             certificatePath:(nullable NSURL *)certificatePath {
    auto config = [self initWithUser:user
                            realmURL:url
                       customFileURL:nil
                           isPartial:isPartial
                          stopPolicy:stopPolicy
                        errorHandler:nullptr];
    config.urlPrefix = urlPrefix;
    config.enableSSLValidation = enableSSLValidation;
    config.pinnedCertificateURL = certificatePath;
    return config;
}

- (instancetype)initWithUser:(RLMSyncUser *)user
                    realmURL:(NSURL *)url
               customFileURL:(nullable NSURL *)customFileURL
                   isPartial:(BOOL)isPartial
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy
                errorHandler:(std::function<realm::SyncSessionErrorHandler>)errorHandler {
    if (self = [super init]) {
        if (!isValidRealmURL(url)) {
            @throw RLMException(@"The provided URL (%@) was not a valid Realm URL.", [url absoluteString]);
        }
        auto bindHandler = [=](auto&,
                               const SyncConfig& config,
                               const std::shared_ptr<SyncSession>& session) {
            const std::shared_ptr<SyncUser>& user = config.user;
            NSURL *realmURL = [NSURL URLWithString:@(config.realm_url().c_str())];
            NSString *path = [realmURL path];
            REALM_ASSERT(realmURL && path);
            RLMSyncSessionRefreshHandle *handle = [[RLMSyncSessionRefreshHandle alloc] initWithRealmURL:realmURL
                                                                                                   user:user
                                                                                                session:std::move(session)
                                                                                        completionBlock:[RLMSyncManager sharedManager].sessionCompletionNotifier];
            context_for(user).register_refresh_handle([path UTF8String], handle);
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
            [[url absoluteString] UTF8String]
        });
        _config->stop_policy = translateStopPolicy(stopPolicy);
        _config->bind_session_handler = std::move(bindHandler);
        _config->error_handler = std::move(errorHandler);
        _config->is_partial = isPartial;
        _config->client_resync_mode = realm::ClientResyncMode::Manual;

        if (NSString *authorizationHeaderName = [RLMSyncManager sharedManager].authorizationHeaderName) {
            _config->authorization_header_name.emplace(authorizationHeaderName.UTF8String);
        }
        if (NSDictionary<NSString *, NSString *> *customRequestHeaders = [RLMSyncManager sharedManager].customRequestHeaders) {
            for (NSString *key in customRequestHeaders) {
                _config->custom_http_headers.emplace(key.UTF8String, customRequestHeaders[key].UTF8String);
            }
        }

        self.customFileURL = customFileURL;
        return self;
    }
    return nil;
}

+ (RLMRealmConfiguration *)automaticConfiguration {
    if (RLMSyncUser.allUsers.count != 1)
        @throw RLMException(@"The automatic configuration requires there be exactly one logged-in sync user.");

    return [RLMSyncConfiguration automaticConfigurationForUser:RLMSyncUser.currentUser];
}

+ (RLMRealmConfiguration *)automaticConfigurationForUser:(RLMSyncUser *)user {
    RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:user
                                                                         realmURL:user.defaultRealmURL
                                                                    customFileURL:nil
                                                                        isPartial:YES
                                                                       stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
                                                                     errorHandler:nullptr];
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    config.syncConfiguration = syncConfig;
    return config;
}

@end
