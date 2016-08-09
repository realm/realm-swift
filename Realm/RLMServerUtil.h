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

typedef NSString* RLMIdentity;
typedef NSString* RLMLocalIdentity;
typedef NSString* RLMServerToken;
typedef NSString* RLMCredentialToken;
typedef NSString* RLMServerPath;
typedef void(^RLMServerCompletionBlock)(NSError * _Nullable, NSDictionary * _Nullable);
typedef void(^RLMServerFetchedRealmCompletionBlock)(NSError * _Nullable, RLMRealmConfiguration * _Nullable, BOOL * _Nonnull);

NS_ASSUME_NONNULL_BEGIN

static NSString *const RLMServerErrorDomain = @"io.realm.server";

typedef RLM_ERROR_ENUM(NSInteger, RLMServerError, RLMServerErrorDomain) {
    /// An error that indicates that the response received from the authentication server was malformed.
    RLMServerErrorBadResponse             = 1,

    /// An error that indicates that the supplied Realm path was invalid, or could not be resolved by the authentication
    /// server.
    RLMServerErrorBadRemoteRealmPath      = 2,

    /// An error that indicates that the response received from the authentication server was an HTTP error code. The
    /// `userInfo` dictionary contains the actual error code value.
    RLMServerErrorHTTPStatusCodeError     = 3,

    /// An error that indicates an issue with the underlying Realm Object Server engine.
    RLMServerInternalError                = 4,
};

typedef NSString *RLMIdentityProvider RLM_EXTENSIBLE_STRING_ENUM;

static RLMIdentityProvider const RLMIdentityProviderDebug                  = @"debug";
static RLMIdentityProvider const RLMIdentityProviderRealm                  = @"realm";
static RLMIdentityProvider const RLMIdentityProviderUsernamePassword       = @"password";
static RLMIdentityProvider const RLMIdentityProviderFacebook               = @"facebook";
static RLMIdentityProvider const RLMIdentityProviderTwitter                = @"twitter";
static RLMIdentityProvider const RLMIdentityProviderGoogle                 = @"google";
static RLMIdentityProvider const RLMIdentityProviderICloud                 = @"icloud";
// FIXME: add more providers as necessary...

NS_ASSUME_NONNULL_END
