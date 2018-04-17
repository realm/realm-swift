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

#import "RLMSyncUtil_Private.hpp"

#import "RLMJSONModels.h"
#import "RLMObject_Private.hpp"
#import "RLMRealmConfiguration+Sync.h"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncUser_Private.hpp"
#import "RLMUtil.hpp"

#import "shared_realm.hpp"

#import "sync/sync_permission.hpp"
#import "sync/sync_user.hpp"

RLMIdentityProvider const RLMIdentityProviderAccessToken = @"_access_token";

NSString *const RLMSyncErrorDomain = @"io.realm.sync";
NSString *const RLMSyncAuthErrorDomain = @"io.realm.sync.auth";
NSString *const RLMSyncPermissionErrorDomain = @"io.realm.sync.permission";

NSString *const kRLMSyncPathOfRealmBackupCopyKey            = @"recovered_realm_location_path";
NSString *const kRLMSyncErrorActionTokenKey                 = @"error_action_token";

NSString *const kRLMSyncAppIDKey                = @"app_id";
NSString *const kRLMSyncDataKey                 = @"data";
NSString *const kRLMSyncErrorJSONKey            = @"json";
NSString *const kRLMSyncErrorStatusCodeKey      = @"statusCode";
NSString *const kRLMSyncIdentityKey             = @"identity";
NSString *const kRLMSyncIsAdminKey              = @"is_admin";
NSString *const kRLMSyncNewPasswordKey          = @"new_password";
NSString *const kRLMSyncPasswordKey             = @"password";
NSString *const kRLMSyncPathKey                 = @"path";
NSString *const kRLMSyncProviderKey             = @"provider";
NSString *const kRLMSyncProviderIDKey           = @"provider_id";
NSString *const kRLMSyncRegisterKey             = @"register";
NSString *const kRLMSyncTokenKey                = @"token";
NSString *const kRLMSyncUnderlyingErrorKey      = @"underlying_error";
NSString *const kRLMSyncUserIDKey               = @"user_id";

uint8_t RLMGetComputedPermissions(RLMRealm *realm, id _Nullable object) {
    if (!object) {
        return static_cast<unsigned char>(realm->_realm->get_privileges());
    }
    if ([object isKindOfClass:[NSString class]]) {
        return static_cast<unsigned char>(realm->_realm->get_privileges([object UTF8String]));
    }
    if (auto obj = RLMDynamicCast<RLMObjectBase>(object)) {
        RLMVerifyAttached(obj);
        return static_cast<unsigned char>(realm->_realm->get_privileges(obj->_row));
    }
    return 0;
}

#pragma mark - C++ APIs

namespace {

NSError *make_permission_error(NSString *description, util::Optional<NSInteger> code, RLMSyncPermissionError type) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (description) {
        userInfo[NSLocalizedDescriptionKey] = description;
    }
    if (code) {
        userInfo[kRLMSyncErrorStatusCodeKey] = @(*code);
    }
    return [NSError errorWithDomain:RLMSyncPermissionErrorDomain code:type userInfo:userInfo];
}

}

SyncSessionStopPolicy translateStopPolicy(RLMSyncStopPolicy stopPolicy) {
    switch (stopPolicy) {
        case RLMSyncStopPolicyImmediately:              return SyncSessionStopPolicy::Immediately;
        case RLMSyncStopPolicyLiveIndefinitely:         return SyncSessionStopPolicy::LiveIndefinitely;
        case RLMSyncStopPolicyAfterChangesUploaded:     return SyncSessionStopPolicy::AfterChangesUploaded;
    }
    REALM_UNREACHABLE();    // Unrecognized stop policy.
}

RLMSyncStopPolicy translateStopPolicy(SyncSessionStopPolicy stop_policy) {
    switch (stop_policy) {
        case SyncSessionStopPolicy::Immediately:            return RLMSyncStopPolicyImmediately;
        case SyncSessionStopPolicy::LiveIndefinitely:       return RLMSyncStopPolicyLiveIndefinitely;
        case SyncSessionStopPolicy::AfterChangesUploaded:   return RLMSyncStopPolicyAfterChangesUploaded;
    }
    REALM_UNREACHABLE();
}

NSError *translateSyncExceptionPtrToError(std::exception_ptr ptr, RLMPermissionActionType type) {
    NSError *error = nil;
    try {
        std::rethrow_exception(ptr);
    } catch (PermissionActionException const& ex) {
        switch (type) {
            case RLMPermissionActionTypeGet:
                error = make_permission_error_get(@(ex.what()), ex.code);
                break;
            case RLMPermissionActionTypeChange:
                error = make_permission_error_change(@(ex.what()), ex.code);
                break;
            case RLMPermissionActionTypeOffer:
                error = make_permission_error_offer(@(ex.what()), ex.code);
                break;
            case RLMPermissionActionTypeAcceptOffer:
                error = make_permission_error_accept_offer(@(ex.what()), ex.code);
                break;
        }
    }
    catch (const std::exception &exp) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, exp), &error);
    }
    return error;
}

std::shared_ptr<SyncSession> sync_session_for_realm(RLMRealm *realm) {
    Realm::Config realmConfig = realm.configuration.config;
    if (auto config = realmConfig.sync_config) {
        std::shared_ptr<SyncUser> user = config->user;
        if (user && user->state() != SyncUser::State::Error) {
            return user->session_for_on_disk_path(realmConfig.path);
        }
    }
    return nullptr;
}

CocoaSyncUserContext& context_for(const std::shared_ptr<realm::SyncUser>& user)
{
    return *std::static_pointer_cast<CocoaSyncUserContext>(user->binding_context());
}

AccessLevel accessLevelForObjCAccessLevel(RLMSyncAccessLevel level) {
    switch (level) {
        case RLMSyncAccessLevelNone:
            return AccessLevel::None;
        case RLMSyncAccessLevelRead:
            return AccessLevel::Read;
        case RLMSyncAccessLevelWrite:
            return AccessLevel::Write;
        case RLMSyncAccessLevelAdmin:
            return AccessLevel::Admin;
    }
    REALM_UNREACHABLE();
}

RLMSyncAccessLevel objCAccessLevelForAccessLevel(AccessLevel level) {
    switch (level) {
        case AccessLevel::None:
            return RLMSyncAccessLevelNone;
        case AccessLevel::Read:
            return RLMSyncAccessLevelRead;
        case AccessLevel::Write:
            return RLMSyncAccessLevelWrite;
        case AccessLevel::Admin:
            return RLMSyncAccessLevelAdmin;
    }
    REALM_UNREACHABLE();
}

NSError *make_auth_error_bad_response(NSDictionary *json) {
    return [NSError errorWithDomain:RLMSyncAuthErrorDomain
                               code:RLMSyncAuthErrorBadResponse
                           userInfo:json ? @{kRLMSyncErrorJSONKey: json} : nil];
}

NSError *make_auth_error_http_status(NSInteger status) {
    return [NSError errorWithDomain:RLMSyncAuthErrorDomain
                               code:RLMSyncAuthErrorHTTPStatusCodeError
                           userInfo:@{kRLMSyncErrorStatusCodeKey: @(status)}];
}

NSError *make_auth_error_client_issue() {
    return [NSError errorWithDomain:RLMSyncAuthErrorDomain
                               code:RLMSyncAuthErrorClientSessionError
                           userInfo:nil];
}

NSError *make_auth_error(RLMSyncErrorResponseModel *model) {
    NSMutableDictionary<NSString *, NSString *> *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    if (NSString *description = model.title) {
        [userInfo setObject:description forKey:NSLocalizedDescriptionKey];
    }
    if (NSString *hint = model.hint) {
        [userInfo setObject:hint forKey:NSLocalizedRecoverySuggestionErrorKey];
    }
    return [NSError errorWithDomain:RLMSyncAuthErrorDomain code:model.code userInfo:userInfo];
}

NSError *make_permission_error_get(NSString *description, util::Optional<NSInteger> code) {
    return make_permission_error(description, std::move(code), RLMSyncPermissionErrorGetFailed);
}

NSError *make_permission_error_change(NSString *description, util::Optional<NSInteger> code) {
    return make_permission_error(description, std::move(code), RLMSyncPermissionErrorChangeFailed);
}

NSError *make_permission_error_offer(NSString *description, util::Optional<NSInteger> code) {
    return make_permission_error(description, std::move(code), RLMSyncPermissionErrorOfferFailed);
}

NSError *make_permission_error_accept_offer(NSString *description, util::Optional<NSInteger> code) {
    return make_permission_error(description, std::move(code), RLMSyncPermissionErrorAcceptOfferFailed);
}

NSError *make_sync_error(RLMSyncSystemErrorKind kind, NSString *description, NSInteger code, NSDictionary *custom) {
    NSMutableDictionary *buffer = [custom ?: @{} mutableCopy];
    buffer[NSLocalizedDescriptionKey] = description;
    if (code != NSNotFound) {
        buffer[kRLMSyncErrorStatusCodeKey] = @(code);
    }

    RLMSyncError errorCode;
    switch (kind) {
        case RLMSyncSystemErrorKindClientReset:
            errorCode = RLMSyncErrorClientResetError;
            break;
        case RLMSyncSystemErrorKindPermissionDenied:
            errorCode = RLMSyncErrorPermissionDeniedError;
            break;
        case RLMSyncSystemErrorKindUser:
            errorCode = RLMSyncErrorClientUserError;
            break;
        case RLMSyncSystemErrorKindSession:
            errorCode = RLMSyncErrorClientSessionError;
            break;
        case RLMSyncSystemErrorKindConnection:
        case RLMSyncSystemErrorKindClient:
        case RLMSyncSystemErrorKindUnknown:
            errorCode = RLMSyncErrorClientInternalError;
            break;
    }
    return [NSError errorWithDomain:RLMSyncErrorDomain
                               code:errorCode
                           userInfo:[buffer copy]];
}

NSError *make_sync_error(NSError *wrapped_auth_error) {
    return [NSError errorWithDomain:RLMSyncErrorDomain
                               code:RLMSyncErrorUnderlyingAuthError
                           userInfo:@{kRLMSyncUnderlyingErrorKey: wrapped_auth_error}];
}

NSError *make_sync_error(std::error_code sync_error, RLMSyncSystemErrorKind kind) {
    return [NSError errorWithDomain:RLMSyncErrorDomain
                               code:kind
                           userInfo:@{
                                      NSLocalizedDescriptionKey: @(sync_error.message().c_str()),
                                      kRLMSyncErrorStatusCodeKey: @(sync_error.value())
                                      }];
}
