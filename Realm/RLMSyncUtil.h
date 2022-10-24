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

/// A token originating from Atlas App Services.
typedef NSString* RLMServerToken;

NS_ASSUME_NONNULL_BEGIN

/// A user info key for use with `RLMSyncErrorClientResetError`.
extern NSString *const kRLMSyncPathOfRealmBackupCopyKey;

/// A user info key for use with certain error types.
extern NSString *const kRLMSyncErrorActionTokenKey;

/// A user info key present in sync errors which originate from the server, containing the URL of the server-side logs associated with the error.
extern NSString * const RLMServerLogURLKey;

/// A user info key containing a HTTP status code. Some ``RLMAppError`` codes include this, most notably ``RLMAppErrorHttpRequestFailed``.
extern NSString * const RLMHTTPStatusCodeKey;

/**
 The error domain string for all SDK errors related to errors reported
 by the synchronization manager error handler, as well as general sync
 errors that don't fall into any of the other categories.
 */
extern NSString *const RLMSyncErrorDomain;

/**
The error domain string for all SDK errors related to the Atlas App Services
endpoint.
*/
extern NSString *const RLMAppErrorDomain;

/**
 The error domain string for all SDK errors related to flexible sync.
 */
extern NSString *const RLMFlexibleSyncErrorDomain;

/**
 An error related to a problem that might be reported by the synchronization manager
 error handler, or a callback on a sync-related API that performs asynchronous work.
 */
typedef RLM_ERROR_ENUM(NSInteger, RLMSyncError, RLMSyncErrorDomain) {

    /// An error that indicates a problem with the session (a specific Realm opened for sync).
    RLMSyncErrorClientSessionError = 4,

    /// An error that indicates a problem with a specific user.
    RLMSyncErrorClientUserError = 5,

    /**
     An error that indicates an internal, unrecoverable problem
     with the underlying synchronization engine.
     */
    RLMSyncErrorClientInternalError = 6,

    /**
     An error that indicates the Realm needs to be reset.

     A synced Realm may need to be reset because Atlas App Services encountered an
     error and had to be restored from a backup. If the backup copy of the remote Realm
     is of an earlier version than the local copy of the Realm, the server will ask the
     client to reset the Realm.

     The reset process is as follows: the local copy of the Realm is copied into a recovery
     directory for safekeeping, and then deleted from the original location. The next time
     the Realm for that partition value is opened, the Realm will automatically be re-downloaded from
     Atlas App Services, and can be used as normal.

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
     `RLMSyncManager` is accessed.

     The value for the `kRLMSyncPathOfRealmBackupCopyKey` key in the `userInfo` dictionary
     describes the path of the recovered copy of the Realm. This copy will not actually be
     created until the client reset process is initiated.

     @see `-[NSError rlmSync_errorActionToken]`, `-[NSError rlmSync_clientResetBackedUpRealmPath]`
     */
    RLMSyncErrorClientResetError = 7,

    /**
     Not used.
     */
    RLMSyncErrorUnderlyingAuthError = 8,

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
    RLMSyncErrorPermissionDeniedError = 9,

    /**
     An error that indicates that the server has reverted a write made by this
     client. This can happen due to not having write permission, or because an
     object was created in a flexible sync Realm which does not match any
     active subscriptions.

     This error is informational and does not require any explicit handling.
     */
    RLMSyncErrorWriteRejected = 10,
};

/**
 An error which is related to a flexible sync operation.
 */
typedef RLM_ERROR_ENUM(NSInteger, RLMFlexibleSyncError, RLMFlexibleSyncErrorDomain) {
    /// An error describing why the subscription set synchronization failed.
    RLMFlexibleSyncErrorStatusError = 1,

    /// An error while committing a subscription write.
    RLMFlexibleSyncErrorCommitSubscriptionSetError = 2,

    /// An error while refreshing the subscription set state.
    RLMFlexibleSyncErrorRefreshSubscriptionSetError = 3,
};

/// An error which occurred when making a request to Atlas App Services.
typedef RLM_ERROR_ENUM(NSInteger, RLMAppError, RLMAppErrorDomain) {
    /// An unknown error has occured
    RLMAppErrorUnknown = -1,

    /// A HTTP request completed with an error status code. The failing status
    /// code can be found in the ``RLMHTTPStatusCodeKey`` key of the userInfo
    /// dictionary.
    RLMAppErrorHttpRequestFailed = 1,

    /// A user's session is in an invalid state. Logging out and back in may rectify this.
    RLMAppErrorInvalidSession,
    /// A request sent to the server was malformed in some way.
    RLMAppErrorBadRequest,
    /// A request was made using a nonexistent user.
    RLMAppErrorUserNotFound,
    /// A request was made against an App using a User which does not belong to that App.
    RLMAppErrorUserAppDomainMismatch,
    /// The auth provider has limited the domain names which can be used for email addresses, and the given one is not allowed.
    RLMAppErrorDomainNotAllowed,
    /// The request body size exceeded a server-configured limit.
    RLMAppErrorReadSizeLimitExceeded,
    /// A request had an invalid parameter.
    RLMAppErrorInvalidParameter,
    /// A request was missing a required parameter.
    RLMAppErrorMissingParameter,
    /// Executing the requested server function failed with an error.
    RLMAppErrorFunctionExecutionError,
    /// The server encountered an internal error.
    RLMAppErrorInternalServerError,
    /// Authentication failed due to the request auth provider not existing.
    RLMAppErrorAuthProviderNotFound,
    /// The requested value does not exist.
    RLMAppErrorValueNotFound,
    /// The value being created already exists.
    RLMAppErrorValueAlreadyExists,
    /// A value with the same name as the value being created already exists.
    RLMAppErrorValueDuplicateName,
    /// The called server function does not exist.
    RLMAppErrorFunctionNotFound,
    /// The called server function has a syntax error.
    RLMAppErrorFunctionSyntaxError,
    /// The called server function is invalid in some way.
    RLMAppErrorFunctionInvalid,
    /// Registering an API key with the auth provider failed due to it already existing.
    RLMAppErrorAPIKeyAlreadyExists,
    /// The operation failed due to exceeding the server-configured time limit.
    RLMAppErrorExecutionTimeLimitExceeded,
    /// The body of the called function does not define a callable thing.
    RLMAppErrorNotCallable,
    /// Email confirmation failed for a user because the user has already confirmed their email.
    RLMAppErrorUserAlreadyConfirmed,
    /// The user cannot be used because it has been disabled.
    RLMAppErrorUserDisabled,
    /// An auth error occurred which does not have a more specific error code.
    RLMAppErrorAuthError,
    /// Account registration failed due to the user name already being taken.
    RLMAppErrorAccountNameInUse,
    /// A login request failed due to an invalid password.
    RLMAppErrorInvalidPassword,
    /// Operation failed due to server-side maintenance.
    RLMAppErrorMaintenanceInProgress,
    /// Operation failed due to an error reported by MongoDB.
    RLMAppErrorMongoDBError,
};

NS_ASSUME_NONNULL_END
