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

@class RLMApp;
@class RLMRealm;
@class RLMRealmConfiguration;
@class RLMUser;
@protocol RLMBSON;

NS_ASSUME_NONNULL_BEGIN

/**  Determines file behavior during a client reset.

 - see: https://docs.mongodb.com/realm/sync/error-handling/client-resets/
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
    /// - see: `rlmSync_clientResetBackedUpRealmPath` or `SyncError.clientResetInfo()` for more information on accessing the recovery directory.
    RLMClientResetModeManual,
    /// All unsynchronized local changes are automatically discarded and the local state is
    /// automatically reverted to the most recent state from the server. Unsynchronized changes
    /// can then be recovered in the post-client-reset callback block.
    ///
    /// If RLMClientResetModeDiscardLocal is enabled but the client reset operation is unable to complete
    /// then the client reset process reverts to manual mode. Example) During a destructive schema change this
    /// mode will fail and invoke the manual client reset handler.
    RLMClientResetModeDiscardLocal
};

/**
 A block type used to report before a client reset will occur.
 The `beforeFrozen` is a frozen copy of the local state prior to client reset.
 */
typedef void(^RLMClientResetBeforeBlock)(RLMRealm * _Nonnull beforeFrozen);

/**
 A block type used to report after a client reset occurred.
 The `beforeFrozen` argument is a frozen copy of the local state prior to client reset.
 The `after` argument contains the local database state after the client reset occurred.
 */
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
@property (nonatomic, readonly) id<RLMBSON> partitionValue;

/**
 An enum which determines file recovery behvaior in the event of a client reset.
 - note: Defaults to `RLMClientResetModeManual`

 - see: `RLMClientResetMode`
 - see: https://docs.mongodb.com/realm/sync/error-handling/client-resets/
*/
@property (nonatomic) RLMClientResetMode clientResetMode;

/**
 A callback which notifies prior to  prior to a client reset occurring.
 - see: `RLMClientResetBeforeBlock`
 */
@property (nonatomic, nullable) RLMClientResetBeforeBlock beforeClientReset;

/**
 A callback which notifies after a client reset has occurred.
 -see: `RLMClientResetAfterBlock`
 */
@property (nonatomic, nullable) RLMClientResetAfterBlock afterClientReset;

/**
 Whether nonfatal connection errors should cancel async opens.
 
 By default, if a nonfatal connection error such as a connection timing out occurs, any currently pending asyncOpen operations will ignore the error and continue to retry until it succeeds. If this is set to true, the open will instead fail and report the error.
 
 FIXME: This should probably be true by default in the next major version.
 */
@property (nonatomic) bool cancelAsyncOpenOnNonFatalErrors;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("This type cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("This type cannot be created directly")));

@end

NS_ASSUME_NONNULL_END
