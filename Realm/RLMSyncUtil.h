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

typedef NSString* RLMSyncAccountID;
typedef NSString* RLMSyncToken;
typedef NSString* RLMSyncCredential;
typedef NSString* RLMSyncRealmPath;
typedef NSString* RLMSyncAppID;
typedef void(^RLMSyncCompletionBlock)(NSError * _Nullable, NSDictionary * _Nullable);

typedef NS_ENUM(NSInteger, RLMSyncError) {
    RLMSyncErrorBadResponse             = 1,
    RLMSyncErrorBadRealmPath            = 2,
    RLMSyncErrorInvalidSession          = 3,
    RLMSyncErrorManagerNotConfigured    = 4,
};

typedef NS_ENUM(NSUInteger, RLMSyncIdentityProvider) {
    RLMRealmSyncIdentityProviderRealm,
    RLMRealmSyncIdentityProviderFacebook,
    RLMRealmSyncIdentityProviderTwitter,
    RLMRealmSyncIdentityProviderGoogle,
    RLMRealmSyncIdentityProviderICloud,
    RLMRealmSyncIdentityProviderDebug,
    // FIXME: add more providers as necessary...
};

NS_ASSUME_NONNULL_BEGIN

static NSString *const RLMSyncErrorDomain = @"io.realm.sync";

static NSString *const kRLMSyncProviderKey      = @"provider";
static NSString *const kRLMSyncDataKey          = @"data";
static NSString *const kRLMSyncAppIDKey         = @"app_id";
static NSString *const kRLMSyncRealmIDKey       = @"realm_id";
static NSString *const kRLMSyncRealmURLKey      = @"realm_url";
static NSString *const kRLMSyncPathKey          = @"path";

#ifdef __cplusplus
extern "C" {
#endif

_Nullable RLMSyncToken RLM_accessTokenForJSON(NSDictionary *json);
_Nullable RLMSyncToken RLM_refreshTokenForJSON(NSDictionary *json);
_Nullable RLMSyncAccountID RLM_accountForJSON(NSDictionary *json);
NSString * _Nullable RLM_realmIDForJSON(NSDictionary *json);
NSString * _Nullable RLM_realmURLForJSON(NSDictionary *json);
NSTimeInterval RLM_accessExpirationForJSON(NSDictionary *json);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END

#define RLMSYNC_CHECK_MANAGER(__error) \
if (![RLMSyncManager sharedManager].configured) { \
  if (__error) { \
    *__error = [NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorManagerNotConfigured userInfo:nil]; \
  } \
  return;\
} \
