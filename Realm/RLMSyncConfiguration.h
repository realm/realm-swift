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

@class RLMRealm;
@class RLMRealmConfiguration;
@class RLMUser;
@class RLMApp;
@protocol RLMBSON;

NS_ASSUME_NONNULL_BEGIN

/**  Determines file behavior during a client reset.

 - see: https://docs.mongodb.com/realm/sync/error-handling/client-resets/
*/
typedef NS_ENUM(NSUInteger, RLMClientResetMode) {
    /// The SDK will create a back up of unsynced data.The client reset error handler may be manually overwritten to
    /// transfer data from the backup copy to a new destination. Otherwise no effort to transfer the data from the backup is carried out.
    RLMClientResetModeManual,
    /// The SDK will overwrite the client database with the server database. Object accessors remain bound so Realm notifications are not disrupted.
    RLMClientResetModeDiscardLocal
};

/**
 A block type used to report before a client reset will occur.
 The RlMRealm argument contains the local database state prior to client reset.
 */
typedef void(^RLMClientResetBeforeBlock)(RLMRealm * _Nonnull);

// ???: Is there really no way to label these arguments?
/**
 A block type used to report after a client reset occurred.
 The first RLMRealm argument contins the local database state prior to client reset.
 The second RLMRealm argument contains the server database state prior to client reset.
 */
typedef void(^RLMClientResetAfterBlock)(RLMRealm * _Nonnull, RLMRealm * _Nonnull);

/**
 A configuration object representing configuration state for a Realm which is intended to sync with a Realm Object
 Server.
 */
@interface RLMSyncConfiguration : NSObject

/// The user to which the remote Realm belongs.
@property (nonatomic, readonly) RLMUser *user;

/**
 The value this Realm is partitioned on. The partition key is a property defined in
 MongoDB Realm. All classes with a property with this value will be synchronized to the
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
@property (nonatomic, nullable) RLMClientResetBeforeBlock  beforeClientReset;

/**
 A callback which notifies after a client reset has occurred.
 -see: `RLMClientResetAfterBlock`
 */
@property (nonatomic, nullable) RLMClientResetAfterBlock  afterClientReset;

/**
 Whether nonfatal connection errors should cancel async opens.
 
 By default, if a nonfatal connection error such as a connection timing out occurs, any currently pending asyncOpen operations will ignore the error and continue to retry until it succeeds. If this is set to true, the open will instead fail and report the error.
 
 FIXME: This should probably be true by default in the next major version.
 */
@property (nonatomic) bool cancelAsyncOpenOnNonFatalErrors;

/// :nodoc:
- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(nullable id<RLMBSON>)partitionValue __attribute__((unavailable("Use [RLMUser configurationWithPartitionValue:] instead")));

/// :nodoc:
+ (RLMRealmConfiguration *)automaticConfiguration __attribute__((unavailable("Use [RLMUser configuration] instead")));

/// :nodoc:
+ (RLMRealmConfiguration *)automaticConfigurationForUser:(RLMUser *)user __attribute__((unavailable("Use [RLMUser configuration] instead")));

/// :nodoc:
- (instancetype)init __attribute__((unavailable("This type cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("This type cannot be created directly")));

@end

NS_ASSUME_NONNULL_END
