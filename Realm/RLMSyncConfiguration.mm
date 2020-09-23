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

#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMRealmConfiguration+Sync.h"
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncSession_Private.hpp"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/sync/sync_session.hpp>
#import <realm/sync/config.hpp>
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
}

@interface RLMSyncConfiguration () {
    std::unique_ptr<realm::SyncConfig> _config;
}

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
    return [self.partitionValue isEqual:that.partitionValue]
    && [self.user isEqual:that.user]
    && self.stopPolicy == that.stopPolicy;
}

- (realm::SyncConfig&)rawConfiguration {
    return *_config;
}

- (RLMUser *)user {
    RLMApp *app = [RLMApp appWithId:@(_config->user->sync_manager()->app().lock()->config().app_id.data())];
    return [[RLMUser alloc] initWithUser:_config->user app:app];
}

- (RLMSyncStopPolicy)stopPolicy {
    return translateStopPolicy(_config->stop_policy);
}

- (void)setStopPolicy:(RLMSyncStopPolicy)stopPolicy {
    _config->stop_policy = translateStopPolicy(stopPolicy);
}

- (id<RLMBSON>)partitionValue {
    if (!_config->partition_value.empty()) {
        return RLMConvertBsonToRLMBSON(realm::bson::parse(_config->partition_value.c_str()));
    }
    return nil;
}

- (bool)cancelAsyncOpenOnNonFatalErrors {
    return _config->cancel_waits_on_nonfatal_error;
}

- (void)setCancelAsyncOpenOnNonFatalErrors:(bool)cancelAsyncOpenOnNonFatalErrors {
    _config->cancel_waits_on_nonfatal_error = cancelAsyncOpenOnNonFatalErrors;
}

- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(nullable id<RLMBSON>)partitionValue {
    return [self initWithUser:user
               partitionValue:partitionValue
                customFileURL:nil
                   stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
}

- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(nullable id<RLMBSON>)partitionValue
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy{
    auto config = [self initWithUser:user
                      partitionValue:partitionValue
                       customFileURL:nil
                          stopPolicy:stopPolicy];
    return config;
}

- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(id<RLMBSON>)partitionValue
               customFileURL:(nullable NSURL *)customFileURL
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    if (self = [super init]) {
        std::stringstream s;
        s << RLMConvertRLMBSONToBson(partitionValue);
        _config = std::make_unique<SyncConfig>(
            [user _syncUser],
            s.str()
        );
        _config->stop_policy = translateStopPolicy(stopPolicy);
        RLMApp *app = user.app;
        _config->error_handler = [app](std::shared_ptr<SyncSession> errored_session, SyncError error) {
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

            RLMSyncManager *manager = [app syncManager];
            auto errorHandler = manager.errorHandler;
            if (!shouldMakeError || !errorHandler) {
                return;
            }
            NSError *nsError = make_sync_error(errorClass, @(error.message.c_str()), error.error_code.value(), custom);
            RLMSyncSession *session = [[RLMSyncSession alloc] initWithSyncSession:errored_session];
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(nsError, session);
            });
        };
        _config->client_resync_mode = realm::ClientResyncMode::Manual;

        RLMSyncManager *manager = [user.app syncManager];
        if (NSString *authorizationHeaderName = manager.authorizationHeaderName) {
            _config->authorization_header_name.emplace(authorizationHeaderName.UTF8String);
        }
        if (NSDictionary<NSString *, NSString *> *customRequestHeaders = manager.customRequestHeaders) {
            for (NSString *key in customRequestHeaders) {
                _config->custom_http_headers.emplace(key.UTF8String, customRequestHeaders[key].UTF8String);
            }
        }

        self.customFileURL = customFileURL;
        return self;
    }
    return nil;
}

@end
