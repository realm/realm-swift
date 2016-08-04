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

typedef void(^RLMErrorReportingBlock)(NSError * _Nullable);

@class RLMRealmConfiguration;

typedef NSString* RLMSyncIdentity;
typedef NSString* RLMSyncToken;
typedef NSString* RLMCredentialToken;
typedef NSString* RLMSyncPath;
typedef NSString* RLMSyncAppID;
typedef void(^RLMSyncCompletionBlock)(NSError * _Nullable, NSDictionary * _Nullable);
typedef void(^RLMSyncFetchedRealmCompletionBlock)(NSError * _Nullable, RLMRealmConfiguration * _Nullable, BOOL * _Nonnull);

typedef NS_ENUM(NSInteger, RLMSyncError) {
    /// An error that indicates that the response received from the authentication server was malformed.
    RLMSyncErrorBadResponse             = 1,

    /// An error that indicates that the supplied Realm path was invalid, or could not be resolved by the authentication
    /// server.
    RLMSyncErrorBadRemoteRealmPath      = 2,

    /// An error that indicates that the response received from the authentication server was an HTTP error code. The
    /// `userInfo` dictionary contains the actual error code value.
    RLMSyncErrorHTTPStatusCodeError     = 3,

    /// An error that indicates an issue with the underlying Sync engine.
    RLMSyncInternalError                = 4,
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
