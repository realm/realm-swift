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

#import <Realm/RLMConstants.h>

/// A token originating from the Realm Object Server.
typedef NSString* RLMServerToken;

NS_ASSUME_NONNULL_BEGIN

/// The error domain string for all SDK errors related to synchronization functionality.
extern NSString *const RLMSyncErrorDomain;

/// An error which is related to authentication to a Realm Object Server.
typedef RLM_ERROR_ENUM(NSInteger, RLMSyncAuthError, RLMSyncErrorDomain) {
    /// An error that indicates that the provided credentials are invalid.
    RLMSyncAuthErrorInvalidCredential   = 611,

    /// An error that indicates that the user with provided credentials does not exist.
    RLMSyncAuthErrorUserDoesNotExist    = 612,

    /// An error that indicates that the user cannot be registered as it exists already.
    RLMSyncAuthErrorUserAlreadyExists   = 613,
};

/// An error which is related to synchronization with a Realm Object Server.
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
    RLMSyncErrorClientSessionError      = 4,

    /// An error that indicates a problem with a specific user.
    RLMSyncErrorClientUserError         = 5,

    /// An error that indicates an internal, unrecoverable error with the underlying synchronization engine.
    RLMSyncErrorClientInternalError     = 6,
};

NS_ASSUME_NONNULL_END
