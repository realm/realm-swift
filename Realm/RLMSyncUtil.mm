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

#import "RLMUser_Private.hpp"

NSString *const kRLMSyncPathOfRealmBackupCopyKey            = @"recovered_realm_location_path";
NSString *const kRLMSyncErrorActionTokenKey                 = @"error_action_token";

#pragma mark - C++ APIs

using namespace realm;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static_assert((int)RLMClientResetModeDiscardLocal == (int)realm::ClientResyncMode::DiscardLocal);
#pragma clang diagnostic pop
static_assert((int)RLMClientResetModeDiscardUnsyncedChanges == (int)realm::ClientResyncMode::DiscardLocal);
static_assert((int)RLMClientResetModeRecoverUnsyncedChanges == (int)realm::ClientResyncMode::Recover);
static_assert((int)RLMClientResetModeRecoverOrDiscardUnsyncedChanges == (int)realm::ClientResyncMode::RecoverOrDiscard);
static_assert((int)RLMClientResetModeManual == (int)realm::ClientResyncMode::Manual);

static_assert(int(RLMSyncStopPolicyImmediately) == int(SyncSessionStopPolicy::Immediately));
static_assert(int(RLMSyncStopPolicyLiveIndefinitely) == int(SyncSessionStopPolicy::LiveIndefinitely));
static_assert(int(RLMSyncStopPolicyAfterChangesUploaded) == int(SyncSessionStopPolicy::AfterChangesUploaded));

SyncSessionStopPolicy translateStopPolicy(RLMSyncStopPolicy stopPolicy) {
    return static_cast<SyncSessionStopPolicy>(stopPolicy);
}

RLMSyncStopPolicy translateStopPolicy(SyncSessionStopPolicy stopPolicy) {
    return static_cast<RLMSyncStopPolicy>(stopPolicy);
}
