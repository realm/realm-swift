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

#import "RLMServerUtil.h"

NS_ASSUME_NONNULL_BEGIN

@class NSURL;

static NSString *const kRLMServerProviderKey      = @"provider";
static NSString *const kRLMServerDataKey          = @"data";
static NSString *const kRLMServerAppIDKey         = @"app_id";
static NSString *const kRLMServerRealmIDKey       = @"realm_id";
static NSString *const kRLMServerRealmURLKey      = @"realm_url";
static NSString *const kRLMServerPathKey          = @"path";
static NSString *const kRLMServerTokenKey         = @"token";
static NSString *const kRLMServerIdentityKey      = @"identity";
static NSString *const kRLMServerExpiresKey       = @"expires";
static NSString *const kRLMServerRefreshKey       = @"refresh";
static NSString *const kRLMServerPasswordKey      = @"password";
static NSString *const kRLMServerRegisterKey      = @"register";
static NSString *const kRLMServerErrorJSONKey     = @"json";

#ifdef __cplusplus
extern "C" {
#endif

/// Given an Realm Object Server URL, derive the 'default' corresponding auth server URL from it.
NSURL *RLMAuthURLForObjectServerURL(NSURL *serverURL, NSNumber *customPort);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END

/// A macro to parse a string out of a JSON dictionary, or return nil.
#define RLMSERVER_PARSE_STRING_OR_ABORT(json_macro_val, key_macro_val, prop_macro_val) \
{ \
id data = json_macro_val[key_macro_val]; \
if (![data isKindOfClass:[NSString class]]) { return nil; } \
self.prop_macro_val = data; \
} \

/// A macro to parse a double out of a JSON dictionary, or return nil.
#define RLMSERVER_PARSE_DOUBLE_OR_ABORT(json_macro_val, key_macro_val, prop_macro_val) \
{ \
id data = json_macro_val[key_macro_val]; \
if (![data isKindOfClass:[NSNumber class]]) { return nil; } \
self.prop_macro_val = [data doubleValue]; \
} \

/// A macro to build a sub-model out of a JSON dictionary, or return nil.
#define RLMSERVER_PARSE_MODEL_OR_ABORT(json_macro_val, key_macro_val, class_macro_val, prop_macro_val) \
{ \
id raw = json_macro_val[key_macro_val]; \
if (![raw isKindOfClass:[NSDictionary class]]) { return nil; } \
id model = [[class_macro_val alloc] initWithJSON:raw]; \
if (!model) { return nil; } \
self.prop_macro_val = model; \
} \
