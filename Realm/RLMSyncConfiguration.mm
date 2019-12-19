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
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy;
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

- (BOOL)isPartial {
    return (BOOL)_config->is_partial;
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

- (void)setFullSynchronization:(BOOL)fullSynchronization {
    _config->is_partial = !(bool)fullSynchronization;
}

- (BOOL)fullSynchronization {
    return !(BOOL)_config->is_partial;
}

- (realm::SyncConfig&)rawConfiguration {
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

- (bool)cancelAsyncOpenOnNonFatalErrors {
    return _config->cancel_waits_on_nonfatal_error;
}

- (void)setCancelAsyncOpenOnNonFatalErrors:(bool)cancelAsyncOpenOnNonFatalErrors {
    _config->cancel_waits_on_nonfatal_error = cancelAsyncOpenOnNonFatalErrors;
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
                   stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
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
                          stopPolicy:stopPolicy];
    config.urlPrefix = urlPrefix;
    config.enableSSLValidation = enableSSLValidation;
    config.pinnedCertificateURL = certificatePath;
    return config;
}

static void bindHandler(std::string const&, SyncConfig const& config, std::shared_ptr<SyncSession> session) {
    const std::shared_ptr<SyncUser>& user = config.user;
    NSURL *realmURL = [NSURL URLWithString:@(config.realm_url().c_str())];
    NSString *path = [realmURL path];
    REALM_ASSERT(realmURL && path);
    auto handle = [[RLMSyncSessionRefreshHandle alloc] initWithRealmURL:realmURL
                                                                   user:user
                                                                session:std::move(session)
                                                        completionBlock:RLMSyncManager.sharedManager.sessionCompletionNotifier];
    context_for(user).register_refresh_handle([path UTF8String], handle);
}

static void errorHandler(std::shared_ptr<SyncSession> errored_session, SyncError error) {
    NSString *recoveryPath;
    RLMSyncErrorActionToken *token;
    for (auto& pair : error.user_info) {
        if (pair.first == realm::SyncError::c_original_file_path_key) {
            token = [[RLMSyncErrorActionToken alloc] initWithOriginalPath:pair.second];
        }
        else if (pair.first == realm::SyncError::c_recovery_file_path_key) {
            recoveryPath = @(pair.second.c_str());
        }
    }

    BOOL shouldMakeError = YES;
    NSDictionary *custom = nil;
    // Note that certain types of errors are 'interactive'; users have several options
    // as to how to proceed after the error is reported.
    auto errorClass = errorKindForSyncError(error);
    switch (errorClass) {
        case RLMSyncSystemErrorKindClientReset: {
            custom = @{kRLMSyncPathOfRealmBackupCopyKey: recoveryPath, kRLMSyncErrorActionTokenKey: token};
            break;
        }
        case RLMSyncSystemErrorKindPermissionDenied: {
            custom = @{kRLMSyncErrorActionTokenKey: token};
            break;
        }
        case RLMSyncSystemErrorKindUser:
        case RLMSyncSystemErrorKindSession:
            break;
        case RLMSyncSystemErrorKindConnection:
        case RLMSyncSystemErrorKindClient:
        case RLMSyncSystemErrorKindUnknown:
            // Report the error. There's nothing the user can do about it, though.
            shouldMakeError = error.is_fatal;
            break;
    }
    auto errorHandler = RLMSyncManager.sharedManager.errorHandler;
    if (!shouldMakeError || !errorHandler) {
        return;
    }
    NSError *nsError = make_sync_error(errorClass, @(error.message.c_str()), error.error_code.value(), custom);
    RLMSyncSession *session = [[RLMSyncSession alloc] initWithSyncSession:errored_session];
    dispatch_async(dispatch_get_main_queue(), ^{
        errorHandler(nsError, session);
    });
};

- (instancetype)initWithUser:(RLMSyncUser *)user
                    realmURL:(NSURL *)url
               customFileURL:(nullable NSURL *)customFileURL
                   isPartial:(BOOL)isPartial
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    if (self = [super init]) {
        if (!isValidRealmURL(url)) {
            @throw RLMException(@"The provided URL (%@) was not a valid Realm URL.", [url absoluteString]);
        }

        _config = std::make_unique<SyncConfig>(SyncConfig{
            [user _syncUser],
            [[url absoluteString] UTF8String]
        });
        _config->stop_policy = translateStopPolicy(stopPolicy);
        _config->bind_session_handler = bindHandler;
        _config->error_handler = errorHandler;
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
                                                                       stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    config.syncConfiguration = syncConfig;
    return config;
}

@end
