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
typedef NSString* RLMServerToken;
typedef NSString* RLMCredentialToken;
typedef NSString* RLMServerPath;
typedef void(^RLMServerCompletionBlock)(NSError * _Nullable, NSDictionary * _Nullable);

NS_ASSUME_NONNULL_BEGIN

extern NSString *const RLMSyncErrorDomain;

typedef RLM_ERROR_ENUM(NSInteger, RLMSyncError, RLMSyncErrorDomain) {
    /// An error that indicates that the response received from the authentication server was malformed.
    RLMSyncErrorBadResponse             = 1,

    /// An error that indicates that the supplied Realm path was invalid, or could not be resolved by the authentication
    /// server.
    RLMSyncErrorBadRemoteRealmPath      = 2,

    /// An error that indicates that the response received from the authentication server was an HTTP error code. The
    /// `userInfo` dictionary contains the actual error code value.
    RLMSyncErrorHTTPStatusCodeError     = 3,

    /// An error that indicates a problem with the session (a specific Realm opened for sync).
    RLMSyncClientSessionError           = 4,

    /// An error that indicates a problem with a specific user.
    RLMSyncClientUserError              = 5,

    /// An error that indicates an internal error with the underlying synchronization engine. Only for information.
    RLMSyncClientInternalError          = 6,
};

NS_ASSUME_NONNULL_END

#define RLM_SYNC_UNINITIALIZABLE \
- (instancetype)init NS_UNAVAILABLE; \
+ (instancetype)new NS_UNAVAILABLE;
