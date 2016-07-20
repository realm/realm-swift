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
#import "RLMConstants.h"

@class RLMSyncSession;

typedef NSString* RLMSyncIdentity;
typedef NSString* RLMSyncToken;
typedef NSString* RLMSyncCredential;
typedef NSString* RLMSyncRealmPath;
typedef NSString* RLMSyncAppID;
typedef void(^RLMSyncLoginCompletionBlock)(NSError * _Nullable, RLMSyncSession * _Nullable);
typedef void(^RLMSyncCompletionBlock)(NSError * _Nullable, NSDictionary * _Nullable);

typedef NS_ENUM(NSInteger, RLMSyncError) {
    RLMSyncErrorBadResponse             = 1,
    RLMSyncErrorBadRemoteRealmPath      = 2,
    RLMSyncErrorBadLocalRealmPath       = 3,
    RLMSyncErrorInvalidSession          = 4,
    RLMSyncErrorManagerNotConfigured    = 5,
    RLMSyncErrorHTTPStatusCodeError     = 6,
};

NS_ASSUME_NONNULL_BEGIN

typedef NSString *RLMSyncIdentityProvider RLM_EXTENSIBLE_STRING_ENUM;

static RLMSyncIdentityProvider const RLMSyncIdentityProviderDebug                  = @"debug";
static RLMSyncIdentityProvider const RLMSyncIdentityProviderRealm                  = @"realm";
static RLMSyncIdentityProvider const RLMSyncIdentityProviderUsernamePassword       = @"password";
static RLMSyncIdentityProvider const RLMSyncIdentityProviderFacebook               = @"facebook";
static RLMSyncIdentityProvider const RLMSyncIdentityProviderTwitter                = @"twitter";
static RLMSyncIdentityProvider const RLMSyncIdentityProviderGoogle                 = @"google";
static RLMSyncIdentityProvider const RLMSyncIdentityProviderICloud                 = @"icloud";
// FIXME: add more providers as necessary...

static NSString *const RLMSyncErrorDomain = @"io.realm.sync";

NS_ASSUME_NONNULL_END
