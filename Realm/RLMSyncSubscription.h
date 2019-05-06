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

#import <Realm/RLMRealm.h>
#import <Realm/RLMResults.h>

NS_ASSUME_NONNULL_BEGIN

/**
 `RLMSyncSubscriptionState` is an enumeration representing the possible state of a sync subscription.
 */
typedef RLM_CLOSED_ENUM(NSInteger, RLMSyncSubscriptionState) {
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

 When query-based sync is enabled for a synchronized Realm, the server only
 synchronizes objects to the client when they match a sync subscription
 registered by that client. A subscription consists of of a query (represented
 by an `RLMResults`) and an optional name.

 The state of the subscription can be observed using
 [Key-Value Observing](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html)
 on the `state` property.

 Subscriptions are created using `-[RLMResults subscribe]` or
 `-[RLMResults subscribeWithName:]`. Existing subscriptions for a Realm can be
 looked up with `-[RLMRealm subscriptions]` or `-[RLMRealm subscriptionWithName:]`.
 */
@interface RLMSyncSubscription : NSObject

/**
 The unique name for this subscription.

 This will be `nil` if this object was created with `-[RLMResults subscribe]`.
 Subscription objects read from a Realm with `-[RLMRealm subscriptions]` will
 always have a non-`nil` name and subscriptions which were not explicitly named
 will have an automatically generated one.
 */
@property (nonatomic, readonly, nullable) NSString *name;

/**
 The current state of the subscription. See `RLMSyncSubscriptionState`.
 */
@property (nonatomic, readonly) RLMSyncSubscriptionState state;

/**
 The error which occurred when registering this subscription, if any.

 Will be non-nil only when `state` is `RLMSyncSubscriptionStateError`.
 */
@property (nonatomic, readonly, nullable) NSError *error;

/**
 The raw query which this subscription is running on the server.

 This string is a serialized representation of the RLMResults which the
 subscription was created from. This representation does *not* use NSPredicate
 syntax, and is not guaranteed to remain consistent between versions of Realm.
 Any use of this other than manual inspection when debugging is likely to be
 incorrect.

 This is `nil` while the subscription is in the Creating state.
 */
@property (nonatomic, readonly, nullable) NSString *query;

/**
 When this subscription was first created.

 This value will be `nil` for subscriptions created with older versions of Realm
 which did not store the creation date. Newly created subscriptions should
 always have a non-nil creation date.
 */
@property (nonatomic, readonly, nullable) NSDate *createdAt;

/**
 When this subscription was last updated.

 This value will be `nil` for subscriptions created with older versions of Realm
 which did not store the update date. Newly created subscriptions should
 always have a non-nil update date.

 The update date is the time when the subscription was last updated by a call
 to `-[RLMResults subscribeWithOptions:]`, and not when the set of objects which
 match the subscription last changed.
 */
@property (nonatomic, readonly, nullable) NSDate *updatedAt;

/**
 When this subscription will be automatically removed.

 If the `timeToLive` parameter is set when creating a sync subscription, the
 subscription will be automatically removed the first time that any subscription
 is created, modified, or deleted after that time has elapsed.

 This property will be `nil` if the `timeToLive` option was not enabled.
 */
@property (nonatomic, readonly, nullable) NSDate *expiresAt;

/**
 How long this subscription will persist after last being updated.

 If the `timeToLive` parameter is set when creating a sync subscription, the
 subscription will be automatically removed the first time that any subscription
 is created, modified, or deleted after that time has elapsed.

 This property will be NaN if the `timeToLive` option was not enabled.
 */
@property (nonatomic, readonly) NSTimeInterval timeToLive;

/**
 Remove this subscription.

 Removing a subscription will delete all objects from the local Realm that were
 matched only by that subscription and not any remaining subscriptions. The
 deletion is performed by the server, and so has no immediate impact on the
 contents of the local Realm. If the device is currently offline, the removal
 will not be processed until the device returns online.

 Unsubscribing is an asynchronous operation and will not immediately remove the
 subscription from the Realm's list of subscriptions. Observe the state property
 to be notified of when the subscription has actually been removed.
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
 Configuration options for query-based sync subscriptions.
 */
@interface RLMSyncSubscriptionOptions : NSObject
/**
 The name of the subscription.

 Naming a subscription makes it possible to look up a subscription by name
 (using `-[RLMRealm subscriptionWithName:]`) or update an existing
 subscription rather than creating a new one.
 */
@property (nonatomic, copy, nullable) NSString *name;

/**
 Whether this should update an existing subscription with the same name.

 By default trying to create a subscription with a name that's already in use
 will fail unless the new subscription is an exact match for the existing one.
 If this is set to YES, instead the existing subscription will be updated using
 the query and options from the new subscription. This only works if the new
 subscription is for the same type of objects as the existing subscription.
 Trying to overwrite a subscription with a subscription of a different type of
 objects will fail.

 The `updatedAt` and (if `timeToLive` is used) `expiresAt` properties are
 updated whenever a subscription is overwritten even if nothing else has changed.
 */
@property (nonatomic) BOOL overwriteExisting;

/**
 How long (in seconds) a subscription should persist after being created.

 By default subscriptions are persistent, and last until they are explicitly
 removed by calling `unsubscribe()`. Subscriptions can instead be made temporary
 by setting the time to live to how long the subscription should remain. After
 that time has elapsed the subscription will be automatically removed.

 A time to live of 0 or less disables subscription expiration.
 */
@property (nonatomic) NSTimeInterval timeToLive;

/**
 The maximum number of top-level matches to include in this subscription.

 If more top-level objects than the limit match the query, only the first
 `limit` objects will be included. This respects the sort and distinct order of
 the query being subscribed to for the determination of what the "first" objects
 are.

 The limit does not count or apply to objects which are added indirectly due to
 being linked to by the objects in the subscription or due to being listed in
 `includeLinkingObjectProperties`. If the limit is larger than the number of
 objects which match the query, all objects will be included. A limit of zero is
 treated as unlimited.
 */
@property (nonatomic) NSUInteger limit;

/**
 Which RLMLinkingObjects properties should be included in the subscription.

 Outgoing links (i.e. `RLMArray` and `RLMObject` properties) are automatically
 included in sync subscriptions. That is, if you subscribe to a query which
 matches one object, every object which is reachable via links from that object
 are also included in the subscription.

 By default, RLMLinkingObjects properties do not work this way. Instead, they
 only report objects which happen to be included in a subscription. By naming
 a RLMLinkingObjects property in this array, it can instead be treated as if
 it was a RLMArray and include all objects which link to this object.

 Any keypath which ends in a RLMLinkingObject property can be included in this
 array, including ones involving intermediate links.
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> *includeLinkingObjectProperties;
@end

/**
 Support for subscribing to the results of object queries in a synced Realm.
 */
@interface RLMResults (SyncSubscription)

/**
 Subscribe to the query represented by this `RLMResults`.

 Subscribing to a query asks the server to synchronize all objects to the
 client which match the query, along with all objects which are reachable
 from those objects via links. This happens asynchronously, and the local
 client Realm may not immediately have all objects which match the query.
 Observe the `state` property of the returned subscription object to be
 notified of when the subscription has been processed by the server and
 all objects matching the query are available.

 The subscription will not be explicitly named. A name will be automatically
 generated for internal use. The exact format of this name may change without
 warning and should not be depended on.

 @return An object representing the newly-created subscription.

 @see RLMSyncSubscription
*/
- (RLMSyncSubscription *)subscribe;

/**
 Subscribe to the query represented by this `RLMResults`.

 Subscribing to a query asks the server to synchronize all objects to the
 client which match the query, along with all objects which are reachable
 from those objects via links. This happens asynchronously, and the local
 client Realm may not immediately have all objects which match the query.
 Observe the `state` property of the returned subscription object to be
 notified of when the subscription has been processed by the server and
 all objects matching the query are available.

 Creating a new subscription with the same name and query as an existing
 subscription will not create a new subscription, but instead will return
 an object referring to the existing sync subscription. This means that
 performing the same subscription twice followed by removing it once will
 result in no subscription existing.

 The newly created subscription will not be reported by
 `-[RLMRealm subscriptions]` or `-[RLMRealm subscriptionWithName:]` until
 `state` has transitioned from `RLMSyncSubscriptionStateCreating` to any of the
 other states.

 @param subscriptionName The name of the subscription.

 @return An object representing the newly-created subscription.

 @see RLMSyncSubscription
*/
- (RLMSyncSubscription *)subscribeWithName:(nullable NSString *)subscriptionName;

/**
 Subscribe to a subset of the query represented by this `RLMResults`.

 Subscribing to a query asks the server to synchronize all objects to the
 client which match the query, along with all objects which are reachable
 from those objects via links. This happens asynchronously, and the local
 client Realm may not immediately have all objects which match the query.
 Observe the `state` property of the returned subscription object to be
 notified of when the subscription has been processed by the server and
 all objects matching the query are available.

 Creating a new subscription with the same name and query as an existing
 subscription will not create a new subscription, but instead will return
 an object referring to the existing sync subscription. This means that
 performing the same subscription twice followed by removing it once will
 result in no subscription existing.

 The newly created subscription will not be reported by
 `-[RLMRealm subscriptions]` or `-[RLMRealm subscriptionWithName:]` until
 `state` has transitioned from `RLMSyncSubscriptionStateCreating` to any of the
 other states.

 The number of top-level matches may optionally be limited. This limit
 respects the sort and distinct order of the query being subscribed to,
 if any. Please note that the limit does not count or apply to objects
 which are added indirectly due to being linked to by the objects in the
 subscription. If the limit is larger than the number of objects which
 match the query, all objects will be included.

 @param subscriptionName The name of the subscription
 @param limit The maximum number of objects to include in the subscription.

 @return The subscription

 @see RLMSyncSubscription
 */
- (RLMSyncSubscription *)subscribeWithName:(nullable NSString *)subscriptionName limit:(NSUInteger)limit;

/**
 Subscribe to a subset of the query represented by this `RLMResults`.

 Subscribing to a query asks the server to synchronize all objects to the
 client which match the query, along with all objects which are reachable
 from those objects via links. This happens asynchronously, and the local
 client Realm may not immediately have all objects which match the query.
 Observe the `state` property of the returned subscription object to be
 notified of when the subscription has been processed by the server and
 all objects matching the query are available.

 Creating a new subscription with the same name and query as an existing
 subscription will not create a new subscription, but instead will return
 an object referring to the existing sync subscription. This means that
 performing the same subscription twice followed by removing it once will
 result in no subscription existing.

 The newly created subscription will not be reported by
 `-[RLMRealm subscriptions]` or `-[RLMRealm subscriptionWithName:]` until
 `state` has transitioned from `RLMSyncSubscriptionStateCreating` to any of the
 other states.

 @param options The additional configuration options for the subscription.
 @return The subscription.

 @see RLMSyncSubscription
 */
- (RLMSyncSubscription *)subscribeWithOptions:(RLMSyncSubscriptionOptions *)options;
@end

/**
 Support for managing existing subscriptions to object queries in a Realm.
 */
@interface RLMRealm (SyncSubscription)
/**
 Get a list of the query-based sync subscriptions made for this Realm.

 This list includes all subscriptions which are currently in the states `Pending`,
 `Created`, and `Error`. Newly created subscriptions which are still in the
 `Creating` state are not included, and calling this immediately after calling
 `-[RLMResults subscribe]` will typically not include that subscription. Similarly,
 because unsubscription happens asynchronously, this may continue to include
 subscriptions after `-[RLMSyncSubscription unsubscribe]` is called on them.

 This method can only be called on a Realm which is using query-based sync and
 will throw an exception if called on a non-synchronized or full-sync Realm.
 */
- (RLMResults<RLMSyncSubscription *> *)subscriptions;

/**
 Look up a specific query-based sync subscription by name.

 Subscriptions are created asynchronously, so calling this immediately after
 calling `subscribeWithName:` on a `RLMResults` will typically return `nil`.
 Only subscriptions which are currently in the states `Pending`, `Created`,
 and `Error` can be retrieved with this method.

 This method can only be called on a Realm which is using query-based sync and
 will throw an exception if called on a non-synchronized or full-sync Realm.

 @return The named subscription, or `nil` if no subscription exists with that name.
 */
- (nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
