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

/// A user info key for use with `RLMSyncErrorClientResetError`.
extern NSString *const kRLMSyncPathOfRealmBackupCopyKey;

/// A user info key for use with certain error types.
extern NSString *const kRLMSyncErrorActionTokenKey;

/**
 The error domain string for all SDK errors related to errors reported
 by the synchronization manager error handler, as well as general sync
 errors that don't fall into any of the other categories.
 */
extern NSString *const RLMSyncErrorDomain;

/**
 The error domain string for all SDK errors related to the authentication
 endpoint.
 */
extern NSString *const RLMSyncAuthErrorDomain;

/**
 The error domain string for all SDK errors related to the permissions
 system and APIs.
 */
extern NSString *const RLMSyncPermissionErrorDomain;

/**
 An error related to a problem that might be reported by the synchronization manager
 error handler, or a callback on a sync-related API that performs asynchronous work.
 */
typedef RLM_ERROR_ENUM(NSInteger, RLMSyncError, RLMSyncErrorDomain) {

    /// An error that indicates a problem with the session (a specific Realm opened for sync).
    RLMSyncErrorClientSessionError      = 4,

    /// An error that indicates a problem with a specific user.
    RLMSyncErrorClientUserError         = 5,

    /**
     An error that indicates an internal, unrecoverable problem
     with the underlying synchronization engine.
     */
    RLMSyncErrorClientInternalError     = 6,

    /**
     An error that indicates the Realm needs to be reset.

     A synced Realm may need to be reset because the Realm Object Server encountered an
     error and had to be restored from a backup. If the backup copy of the remote Realm
     is of an earlier version than the local copy of the Realm, the server will ask the
     client to reset the Realm.

     The reset process is as follows: the local copy of the Realm is copied into a recovery
     directory for safekeeping, and then deleted from the original location. The next time
     the Realm for that URL is opened, the Realm will automatically be re-downloaded from the
     Realm Object Server, and can be used as normal.

     Data written to the Realm after the local copy of the Realm diverged from the backup
     remote copy will be present in the local recovery copy of the Realm file. The
     re-downloaded Realm will initially contain only the data present at the time the Realm
     was backed up on the server.

     The client reset process can be initiated in one of two ways.
     
     The `userInfo` dictionary contains an opaque token object under the key
     `kRLMSyncErrorActionTokenKey`. This token can be passed into
     `+[RLMSyncSession immediatelyHandleError:]` in order to immediately perform the client
     reset process. This should only be done after your app closes and invalidates every
     instance of the offending Realm on all threads (note that autorelease pools may make this
     difficult to guarantee).

     If `+[RLMSyncSession immediatelyHandleError:]` is not called, the client reset process
     will be automatically carried out the next time the app is launched and the
     `RLMSyncManager` singleton is accessed.

     The value for the `kRLMSyncPathOfRealmBackupCopyKey` key in the `userInfo` dictionary
     describes the path of the recovered copy of the Realm. This copy will not actually be
     created until the client reset process is initiated.

     @see `-[NSError rlmSync_errorActionToken]`, `-[NSError rlmSync_clientResetBackedUpRealmPath]`
     */
    RLMSyncErrorClientResetError        = 7,

    /**
     An error that indicates an authentication error occurred.

     The `kRLMSyncUnderlyingErrorKey` key in the user info dictionary will contain the
     underlying error, which is guaranteed to be under the `RLMSyncAuthErrorDomain`
     error domain.
     */
    RLMSyncErrorUnderlyingAuthError     = 8,

    /**
     An error that indicates the user does not have permission to perform an operation
     upon a synced Realm. For example, a user may receive this error if they attempt to
     open a Realm they do not have at least read access to, or write to a Realm they only
     have read access to.
     
     This error may also occur if a user incorrectly opens a Realm they have read-only
     permissions to without using the `asyncOpen()` APIs.

     A Realm that suffers a permission denied error is, by default, flagged so that its
     local copy will be deleted the next time the application starts.
     
     The `userInfo` dictionary contains an opaque token object under the key
     `kRLMSyncErrorActionTokenKey`. This token can be passed into
     `+[RLMSyncSession immediatelyHandleError:]` in order to immediately delete the local
     copy. This should only be done after your app closes and invalidates every instance
     of the offending Realm on all threads (note that autorelease pools may make this
     difficult to guarantee).

     @warning It is strongly recommended that, if a Realm has encountered a permission denied
              error, its files be deleted before attempting to re-open it.
     
     @see `-[NSError rlmSync_errorActionToken]`
     */
    RLMSyncErrorPermissionDeniedError   = 9,
};

/// An error which is related to authentication to a Realm Object Server.
typedef RLM_ERROR_ENUM(NSInteger, RLMSyncAuthError, RLMSyncAuthErrorDomain) {
    /// An error that indicates that the response received from the authentication server was malformed.
    RLMSyncAuthErrorBadResponse                     = 1,

    /// An error that indicates that the supplied Realm path was invalid, or could not be resolved by the authentication
    /// server.
    RLMSyncAuthErrorBadRemoteRealmPath              = 2,

    /// An error that indicates that the response received from the authentication server was an HTTP error code. The
    /// `userInfo` dictionary contains the actual error code value.
    RLMSyncAuthErrorHTTPStatusCodeError             = 3,

    /// An error that indicates a problem with the session (a specific Realm opened for sync).
    RLMSyncAuthErrorClientSessionError              = 4,

    /// An error that indicates that the provided credentials are invalid.
    RLMSyncAuthErrorInvalidCredential               = 611,

    /// An error that indicates that the user with provided credentials does not exist.
    RLMSyncAuthErrorUserDoesNotExist                = 612,

    /// An error that indicates that the user cannot be registered as it exists already.
    RLMSyncAuthErrorUserAlreadyExists               = 613,

    /// An error that indicates the path is invalid or the user doesn't have access to that Realm.
    RLMSyncAuthErrorAccessDeniedOrInvalidPath       = 614,

    /// An error that indicates the refresh token was invalid.
    RLMSyncAuthErrorInvalidAccessToken              = 615,

    /// An error that indicates the permission offer is expired.
    RLMSyncAuthErrorExpiredPermissionOffer          = 701,

    /// An error that indicates the permission offer is ambiguous.
    RLMSyncAuthErrorAmbiguousPermissionOffer        = 702,

    /// An error that indicates the file at the given path can't be shared.
    RLMSyncAuthErrorFileCannotBeShared              = 703,
};

/**
 An error related to the permissions subsystem.
 */
typedef RLM_ERROR_ENUM(NSInteger, RLMSyncPermissionError, RLMSyncPermissionErrorDomain) {
    /**
     An error that indicates a permission change operation failed. The `userInfo`
     dictionary contains the underlying error code and a message (if any).
     */
    RLMSyncPermissionErrorChangeFailed          = 1,

    /**
     An error that indicates that attempting to retrieve permissions failed.
     */
    RLMSyncPermissionErrorGetFailed             = 2,

    /**
     An error that indicates that trying to create a permission offer failed.
     */
    RLMSyncPermissionErrorOfferFailed           = 3,

    /**
     An error that indicates that trying to accept a permission offer failed.
     */
    RLMSyncPermissionErrorAcceptOfferFailed     = 4,

    /**
     An error that indicates that an internal error occurred.
     */
    RLMSyncPermissionErrorInternal              = 5,
};

NS_ASSUME_NONNULL_END
