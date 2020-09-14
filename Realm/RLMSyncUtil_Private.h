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

#import <Realm/RLMSyncUtil.h>

#import <Realm/RLMProperty.h>
#import <Realm/RLMRealmConfiguration.h>
#import <Realm/RLMCredentials.h>

typedef NS_ENUM(NSUInteger, RLMSyncSystemErrorKind) {
    // Specific
    RLMSyncSystemErrorKindClientReset,
    RLMSyncSystemErrorKindPermissionDenied,
    // General
    RLMSyncSystemErrorKindClient,
    RLMSyncSystemErrorKindConnection,
    RLMSyncSystemErrorKindSession,
    RLMSyncSystemErrorKindUser,
    RLMSyncSystemErrorKindUnknown,
};

@class RLMUser;

typedef void(^RLMSyncCompletionBlock)(NSError * _Nullable, NSDictionary * _Nullable);
typedef void(^RLMSyncBasicErrorReportingBlock)(NSError * _Nullable);

typedef NSString* RLMServerPath;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kRLMSyncErrorStatusCodeKey;
extern NSString *const kRLMSyncUnderlyingErrorKey;

#define RLM_SYNC_UNINITIALIZABLE \
- (instancetype)init __attribute__((unavailable("This type cannot be created directly"))); \
+ (instancetype)new __attribute__((unavailable("This type cannot be created directly")));

NS_ASSUME_NONNULL_END
