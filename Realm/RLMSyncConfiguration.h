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

#import <Realm/RLMSyncManager.h>
#import <Realm/RLMInitialSubscriptionsConfiguration.h>

@class RLMApp;
@class RLMRealm;
@class RLMRealmConfiguration;
@class RLMUser;
@class RLMInitialSubscriptionsConfiguration;
@protocol RLMBSON;

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

/**  Determines file behavior during a client reset.

 @see: https://docs.mongodb.com/realm/sync/error-handling/client-resets/
*/
typedef NS_ENUM(NSUInteger, RLMClientResetMode) {
    /// The local copy of the Realm is copied into a recovery
    /// directory for safekeeping, and then deleted from the original location. The next time
    /// the Realm for that partition value is opened, the Realm will automatically be re-downloaded from
    /// Atlas App Services, and can be used as normal.

    /// Data written to the Realm after the local copy of the Realm diverged from the backup
    /// remote copy will be present in the local recovery copy of the Realm file. The
    /// re-downloaded Realm will initially contain only the data present at the time the Realm
    /// was backed up on the server.
    ///
    /// @see: ``rlmSync_clientResetBackedUpRealmPath`` and ``RLMSyncErrorActionToken`` for more information on accessing the recovery directory and error information.
    ///
    /// The manual client reset mode handler can be set in two places:
    ///  1. As an ErrorReportingBlock argument at ``RLMSyncConfiguration.manualClientResetHandler``.
    ///  2. As an ErrorReportingBlock in the ``RLMSyncManager.errorHandler`` property.
    ///  @see: ``RLMSyncManager.errorHandler``
    ///
    ///  When an ``RLMSyncErrorClientResetError`` is thrown, the following rules determine which block is executed:
    ///  - If an error reporting block is set in ``.manualClientResetHandler`` and the ``RLMSyncManager.errorHandler``, the ``.manualClientResetHandler`` block will be executed.
    ///  - If an error reporting block is set in either the ``.manualClientResetHandler`` or the ``RLMSyncManager``, but not both, the single block will execute.
    ///  - If no block is set in either location, the client reset will not be handled. The application will likely need to be restarted and unsynced local changes may be lost.
    /// @note: The ``RLMSyncManager.errorHandler`` is still invoked under all ``RLMSyncError``s *other than* ``RLMSyncErrorClientResetError``.
    /// @see ``RLMSyncError`` for an exhaustive list.
    RLMClientResetModeManual = 0,
    /// All unsynchronized local changes are automatically discarded and the local state is
    /// automatically reverted to the most recent state from the server. Unsynchronized changes
    /// can then be recovered in the post-client-reset callback block.
    ///
    /// If ``RLMClientResetModeDiscardLocal`` is enabled but the client reset operation is unable to complete
    /// then the client reset process reverts to manual mode. Example) During a destructive schema change this
    /// mode will fail and invoke the manual client reset handler.
    ///
    /// The RLMClientResetModeDiscardLocal mode supports two client reset callbacks -- ``RLMClientResetBeforeBlock``, ``RLMClientResetAfterBlock`` -- which can be passed as arguments when creating the ``RLMSyncConfiguration``.
    /// @see: ``RLMClientResetAfterBlock`` and ``RLMClientResetBeforeBlock``
    RLMClientResetModeDiscardLocal __deprecated_enum_msg("Use RLMClientResetModeDiscardUnsyncedChanges") = 1,
    /// All unsynchronized local changes are automatically discarded and the local state is
    /// automatically reverted to the most recent state from the server. Unsynchronized changes
    /// can then be recovered in the post-client-reset callback block.
    ///
    /// If ``RLMClientResetModeDiscardUnsyncedChanges`` is enabled but the client reset operation is unable to complete
    /// then the client reset process reverts to manual mode. Example) During a destructive schema change this
    /// mode will fail and invoke the manual client reset handler.
    ///
    /// The RLMClientResetModeDiscardUnsyncedChanges mode supports two client reset callbacks -- ``RLMClientResetBeforeBlock``, ``RLMClientResetAfterBlock`` -- which can be passed as arguments when creating the ``RLMSyncConfiguration``.
    /// @see: ``RLMClientResetAfterBlock`` and ``RLMClientResetBeforeBlock``
    RLMClientResetModeDiscardUnsyncedChanges = 1,
    /// The client device will download a realm realm which reflects the latest
    /// state of the server after a client reset. A recovery process is run locally in
    /// an attempt to integrate the server version with any local changes from
    /// before the client reset occurred.
    ///
    /// The changes are integrated with the following rules:
    /// 1. Objects created locally that were not synced before client reset will be integrated.
    /// 2. If an object has been deleted on the server, but was modified on the client, the delete takes precedence and the update is discarded
    /// 3. If an object was deleted on the client, but not the server, then the client delete instruction is applied.
    /// 4. In the case of conflicting updates to the same field, the client update is applied.
    ///
    /// If the recovery integration fails, the client reset process falls back to ``RLMClientResetModeManual``.
    /// The recovery integration will fail if the "Client Recovery" setting is not enabled on the server.
    /// Integration may also fail in the event of an incompatible schema change.
    ///
    /// The RLMClientResetModeRecoverUnsyncedChanges mode supports two client reset callbacks -- ``RLMClientResetBeforeBlock``, ``RLMClientResetAfterBlock`` -- which can be passed as arguments when creating the ``RLMSyncConfiguration``.
    /// @see: ``RLMClientResetAfterBlock`` and ``RLMClientResetBeforeBlock``
    RLMClientResetModeRecoverUnsyncedChanges = 2,
    /// The client device will download a realm with objects reflecting the latest version of the server. A recovery
    /// process is run locally in an attempt to integrate the server version with any local changes from before the
    /// client reset occurred.
    ///
    /// The changes are integrated with the following rules:
    /// 1. Objects created locally that were not synced before client reset will be integrated.
    /// 2. If an object has been deleted on the server, but was modified on the client, the delete takes precedence and the update is discarded
    /// 3. If an object was deleted on the client, but not the server, then the client delete instruction is applied.
    /// 4. In the case of conflicting updates to the same field, the client update is applied.
    ///
    /// If the recovery integration fails, the client reset process falls back to ``RLMClientResetModeDiscardUnsyncedChanges``.
    /// The recovery integration will fail if the "Client Recovery" setting is not enabled on the server.
    /// Integration may also fail in the event of an incompatible schema change.
    ///
    /// The RLMClientResetModeRecoverOrDiscardUnsyncedChanges mode supports two client reset callbacks -- ``RLMClientResetBeforeBlock``, ``RLMClientResetAfterBlock`` -- which can be passed as arguments when creating the ``RLMSyncConfiguration``.
    /// @see: ``RLMClientResetAfterBlock`` and ``RLMClientResetBeforeBlock``
    RLMClientResetModeRecoverOrDiscardUnsyncedChanges = 3
};

/**
 A block type used to report before a client reset will occur.
 The `beforeFrozen` is a frozen copy of the local state prior to client reset.
 */
RLM_SWIFT_SENDABLE // invoked on a background thread
typedef void(^RLMClientResetBeforeBlock)(RLMRealm * _Nonnull beforeFrozen);

/**
 A block type used to report after a client reset occurred.
 The `beforeFrozen` argument is a frozen copy of the local state prior to client reset.
 The `after` argument contains the local database state after the client reset occurred.
 */
RLM_SWIFT_SENDABLE // invoked on a backgroun thread
typedef void(^RLMClientResetAfterBlock)(RLMRealm * _Nonnull beforeFrozen, RLMRealm * _Nonnull after);

/**
 A configuration object representing configuration state for a Realm which is intended to sync with a Realm Object
 Server.
 */
@interface RLMSyncConfiguration : NSObject

/// The user to which the remote Realm belongs.
@property (nonatomic, readonly) RLMUser *user;

/**
 The value this Realm is partitioned on. The partition key is a property defined in
 Atlas App Services. All classes with a property with this value will be synchronized to the
 Realm.
 */
@property (nonatomic, readonly, nullable) id<RLMBSON> partitionValue;

/**
 An enum which determines file recovery behavior in the event of a client reset.
 @note: Defaults to `RLMClientResetModeRecoverUnsyncedChanges`

 @see: `RLMClientResetMode`
 @see: https://docs.mongodb.com/realm/sync/error-handling/client-resets/
*/
@property (nonatomic) RLMClientResetMode clientResetMode;

/**
 A callback which notifies prior to  prior to a client reset occurring.
 @see: `RLMClientResetBeforeBlock`
 */
@property (nonatomic, nullable) RLMClientResetBeforeBlock beforeClientReset;

/**
 A callback which notifies after a client reset has occurred.
 @see: `RLMClientResetAfterBlock`
 */
@property (nonatomic, nullable) RLMClientResetAfterBlock afterClientReset;

/**
    A callback that's executed when an `RLMSyncErrorClientResetError` is encountered.
    @See RLMSyncErrorReportingBlock and RLMSyncErrorClientResetError for more
    details on handling a client reset manually.
 */
@property (nonatomic, nullable) RLMSyncErrorReportingBlock manualClientResetHandler;

/**
 A configuration that controls how initial subscriptions are populated when the Realm is opened.
 @see `RLMInitialSubscriptionsConfiguration`
 */
@property (nonatomic, readwrite, nullable) RLMInitialSubscriptionsConfiguration *initialSubscriptions;

/**
 Whether nonfatal connection errors should cancel async opens.
 
 By default, if a nonfatal connection error such as a connection timing out occurs, any currently pending asyncOpen operations will ignore the error and continue to retry until it succeeds. If this is set to true, the open will instead fail and report the error.
 
 NEXT-MAJOR: This should be true by default.
 */
@property (nonatomic) bool cancelAsyncOpenOnNonFatalErrors;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("This type cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("This type cannot be created directly")));

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
