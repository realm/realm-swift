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

@class RLMSyncSession;

typedef NSString* RLMSyncAccountID;
typedef NSString* RLMSyncToken;
typedef NSString* RLMSyncCredential;
typedef NSString* RLMSyncRealmPath;
typedef NSString* RLMSyncAppID;
typedef void(^RLMSyncLoginCompletionBlock)(NSError * _Nullable, NSDictionary * _Nullable, RLMSyncSession * _Nullable);
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
static NSString *const kRLMSyncTokenKey         = @"token";
static NSString *const kRLMSyncExpiresKey       = @"expires";

#ifdef __cplusplus
extern "C" {
#endif

    // Free helper functions go here.

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

/// A macro to parse a string out of a JSON dictionary, or return nil.
#define RLMSYNC_PARSE_STRING_OR_ABORT(__json, __key, __prop) \
{ \
  id data = __json[__key]; \
  if (![data isKindOfClass:[NSString class]]) { return nil; } \
  self.__prop = data; \
} \

/// A macro to parse a double out of a JSON dictionary, or return nil.
#define RLMSYNC_PARSE_DOUBLE_OR_ABORT(__json, __key, __prop) \
{ \
  id data = __json[__key]; \
  if (![data isKindOfClass:[NSNumber class]]) { return nil; } \
  self.__prop = [data doubleValue]; \
} \

/// A macro to build a sub-model out of a JSON dictionary, or return nil.
#define RLMSYNC_PARSE_MODEL_OR_ABORT(__json, __key, __class, __prop) \
{ \
  id raw = __json[__key]; \
  if (![raw isKindOfClass:[NSDictionary class]]) { return nil; } \
  id model = [[__class alloc] initWithJSON:raw]; \
  if (!model) { return nil; } \
  self.__prop = model; \
} \
