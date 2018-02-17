////////////////////////////////////////////////////////////////////////////
//
// Copyright 2018 Realm Inc.
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

#import <Realm/RLMResults.h>

NS_ASSUME_NONNULL_BEGIN

/**
 `RLMSyncSubscriptionState` is an enumeration representing the possible state of a sync subscription.
 */
typedef NS_ENUM(NSInteger, RLMSyncSubscriptionState) {
    /**
     An error occurred while creating the subscription or while the server was processing it.
     */
    RLMSyncSubscriptionStateError = -1,

    /**
     The subscription is being created, but has not yet been written to the synced Realm.
     */
    RLMSyncSubscriptionStateCreating = 2,

    /**
     The subscription has been created, and is waiting to be processed by the server.
     */
    RLMSyncSubscriptionStatePending = 0,

    /**
     The subscription has been processed by the server, and objects matching the subscription
     are now being synchronized to this client.
     */
    RLMSyncSubscriptionStateComplete = 1,

    /**
     This subscription has been removed.
     */
    RLMSyncSubscriptionStateInvalidated = 3,
};

/**
 `RLMSyncSubscription` represents a subscription to a set of objects in a synced Realm.

 When partial sync is enabled for a synced Realm, the only objects that the server synchronizes to the
 client are those that match a sync subscription registered by that client. A subscription consists of
 of a query (represented by an `RLMResults`) and an optional name.

 The state of the subscription can be observed using [Key-Value Observing](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html) on the `state` property.

 Subscriptions are created using `-[RLMResults subscribe]` or `-[RLMResults subscribeWithName:]`.
 */
@interface RLMSyncSubscription : NSObject

/**
 The unique name for this subscription.

 This will be `nil` if a name was not provided when the subscription was created.
 */
@property (nonatomic, readonly, nullable) NSString *name;

/**
 The state of the subscription. See `RLMSyncSubscriptionState`.
 */
@property (nonatomic, readonly) RLMSyncSubscriptionState state;

/**
 The error associated with this subscription, if any.

 Will be non-nil only when `state` is `RLMSyncSubscriptionStateError`.
 */
@property (nonatomic, readonly, nullable) NSError *error;

/**
 Remove this subscription.

 Removing a subscription will delete all objects from the local Realm that were matched
 only by that subscription and not any remaining subscriptions. The deletion is performed
 by the server, and so has no immediate impact on the contents of the local Realm. If the
 device is currently offline, the removal will not be processed until the device returns online.
 */
- (void)unsubscribe;

#pragma mark - Unavailable Methods

/**
 `-[RLMSyncSubscription init]` is not available because `RLMSyncSubscription` cannot be created directly.
 */
- (instancetype)init __attribute__((unavailable("RLMSyncSubscription cannot be created directly")));

/**
 `+[RLMSyncSubscription new]` is not available because `RLMSyncSubscription` cannot be created directly.
 */
+ (instancetype)new __attribute__((unavailable("RLMSyncSubscription cannot be created directly")));

@end

/**
 Support for subscribing to the results of object queries in a synced Realm.
 */
@interface RLMResults (SyncSubscription)

/**
 Subscribe to the query represented by this `RLMResults`.

 The subscription will not be explicitly named.

 @return The subscription

 @see RLMSyncSubscription
*/
- (RLMSyncSubscription *)subscribe;

/**
 Subscribe to the query represented by this `RLMResults`.

 @param subscriptionName The name of the subscription

 @return The subscription

 @see RLMSyncSubscription
*/
- (RLMSyncSubscription *)subscribeWithName:(NSString *)subscriptionName;
@end

NS_ASSUME_NONNULL_END
