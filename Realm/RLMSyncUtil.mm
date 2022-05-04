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

#import "RLMObject_Private.hpp"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/shared_realm.hpp>
#import <realm/object-store/sync/sync_user.hpp>
#import <realm/sync/config.hpp>

NSString *const RLMSyncErrorDomain = @"io.realm.sync";
NSString *const RLMSyncAuthErrorDomain = @"io.realm.sync.auth";
NSString *const RLMAppErrorDomain = @"io.realm.app";

NSString *const RLMFlexibleSyncErrorDomain = @"io.realm.sync.flx";

NSString *const kRLMSyncPathOfRealmBackupCopyKey            = @"recovered_realm_location_path";
NSString *const kRLMSyncErrorActionTokenKey                 = @"error_action_token";

NSString *const kRLMSyncErrorStatusCodeKey      = @"statusCode";
NSString *const kRLMSyncUnderlyingErrorKey      = @"underlying_error";

#pragma mark - C++ APIs

using namespace realm;

static_assert((int)RLMClientResetModeManual == (int)realm::ClientResyncMode::Manual);
static_assert((int)RLMClientResetModeDiscardLocal == (int)realm::ClientResyncMode::DiscardLocal);

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

CocoaSyncUserContext& context_for(const std::shared_ptr<realm::SyncUser>& user)
{
    return *std::static_pointer_cast<CocoaSyncUserContext>(user->binding_context());
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
