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

#import <Foundation/Foundation.h>

#import "RLMSyncUtil_Private.hpp"

RLMIdentityProvider const RLMIdentityProviderAccessToken = @"_access_token";

NSString *const RLMSyncErrorDomain = @"io.realm.sync";

NSString *const kRLMSyncAppIDKey                = @"app_id";
NSString *const kRLMSyncDataKey                 = @"data";
NSString *const kRLMSyncErrorJSONKey            = @"json";
NSString *const kRLMSyncIdentityKey             = @"identity";
NSString *const kRLMSyncPasswordKey             = @"password";
NSString *const kRLMSyncPathKey                 = @"path";
NSString *const kRLMSyncProviderKey             = @"provider";
NSString *const kRLMSyncRegisterKey             = @"register";
NSString *const kRLMSyncUnderlyingErrorKey      = @"underlying_error";
NSString *const kRLMSyncActionsKey              = @"actions";

namespace realm {

SyncSessionStopPolicy translateStopPolicy(RLMSyncStopPolicy stopPolicy) {
    switch (stopPolicy) {
        case RLMSyncStopPolicyImmediately:              return SyncSessionStopPolicy::Immediately;
        case RLMSyncStopPolicyLiveIndefinitely:         return SyncSessionStopPolicy::LiveIndefinitely;
        case RLMSyncStopPolicyAfterChangesUploaded:     return SyncSessionStopPolicy::AfterChangesUploaded;
    }
    REALM_UNREACHABLE();    // Unrecognized stop policy.
}

RLMSyncStopPolicy translateStopPolicy(SyncSessionStopPolicy stop_policy)
{
    switch (stop_policy) {
        case SyncSessionStopPolicy::Immediately:            return RLMSyncStopPolicyImmediately;
        case SyncSessionStopPolicy::LiveIndefinitely:       return RLMSyncStopPolicyLiveIndefinitely;
        case SyncSessionStopPolicy::AfterChangesUploaded:   return RLMSyncStopPolicyAfterChangesUploaded;
    }
    REALM_UNREACHABLE();
}

}
