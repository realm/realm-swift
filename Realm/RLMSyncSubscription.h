////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

@class RLMObjectId;

#pragma mark - Subscription States

/// The current state of the subscription. This can be used for ensuring that
/// the subscriptions are not errored and that it has been successfully
/// synced to the server.
typedef NS_ENUM(NSUInteger, RLMSyncSubscriptionState) {
    /// The subscription is complete and the server has sent all the data that matched the subscription
    /// queries at the time the subscription set was updated. The server is now in a steady-state
    /// synchronization mode where it will stream update as they come.
    RLMSyncSubscriptionStateComplete,
    /// The subscription encountered an error and synchronization is paused for this Realm. You can
    /// find the error calling error in the subscription set to get a description of the error. You can
    /// still use the current subscription set to write a subscription.
    RLMSyncSubscriptionStateError,
    /// The subscription is persisted locally but not yet processed by the server, which means
    /// the server hasn't yet returned all the data that matched the updated subscription queries.
    RLMSyncSubscriptionStatePending,
    /// The subscription set has been super-ceded by an updated one, this typically means that
    /// someone is trying to write a subscription on a different instance of the subscription set.
    /// You should not use a superseded subscription set and instead obtain a new instance of
    /// the subscription set to write a subscription.
    RLMSyncSubscriptionStateSuperseded
};

NS_ASSUME_NONNULL_BEGIN

/**
 `RLMSyncSubscription` is  used to define a Flexible Sync subscription obtained from querying a
 subscription set, which can be used to read or remove/update a committed subscription.
 */
@interface RLMSyncSubscription : NSObject

/// Name of the subscription. If not specified it will return nil.
@property (nonatomic, readonly, nullable) NSString *name;

/// When the subscription was created. Recorded automatically.
@property (nonatomic, readonly) NSDate *createdAt;

/// When the subscription was last updated. Recorded automatically.
@property (nonatomic, readonly) NSDate *updatedAt;

/**
 Updates a Flexible Sync's subscription query with an allowed query which will be used to bootstrap data
 from the server when committed.

 @warning This method may only be called during a write subscription block.

 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.
 */
- (void)updateSubscriptionWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (void)updateSubscriptionWhere:(NSString *)predicateFormat
                           args:(va_list)args;

/**
 Updates a Flexible Sync's subscription query with an allowed query which will be used to bootstrap data
 from the server when committed.

 @warning This method may only be called during a write subscription block.

 @param predicate The predicate with which to filter the objects on the server.
 */
- (void)updateSubscriptionWithPredicate:(NSPredicate *)predicate;

@end

/**
 `RLMSyncSubscriptionSet` is  a collection of `RLMSyncSubscription`s. This is the entry point
 for adding and removing `RLMSyncSubscription`s.
 */
@interface RLMSyncSubscriptionSet : NSObject <NSFastEnumeration>

/// The number of subscriptions in the subscription set.
@property (readonly) NSUInteger count;

/// Gets the error associated to the subscription set. This will be non-nil in case the current
/// state of the subscription set is `RLMSyncSubscriptionStateError`.
@property (nonatomic, readonly, nullable) NSError *error;

/// Gets the state associated to the subscription set.
@property (nonatomic, readonly) RLMSyncSubscriptionState state;

#pragma mark - Batch Update subscriptions

/**
 Synchronously performs any transactions (add/remove/update) to the subscription set within the block,
 this will not wait for the server to acknowledge and see all the data associated with this collection of subscriptions,
 and will return after committing the subscription transactions.

 @param block The block containing actions to perform to the subscription set.
 */
- (void)update:(__attribute__((noescape)) void(^)(void))block;
/// :nodoc:
- (void)write:(__attribute__((noescape)) void(^)(void))block __attribute__((unavailable("Renamed to -update")));

/**
 Synchronously performs any transactions (add/remove/update) to the subscription set within the block,
 this will not wait for the server to acknowledge and see all the data associated with this collection of subscriptions,
 and will return after committing the subscription transactions.

 @param block The block containing actions to perform to the subscription set.
 @param onComplete The block called upon synchronization of subscriptions to the server. Otherwise
                   an `Error`describing what went wrong will be returned by the block
 */
- (void)update:(__attribute__((noescape)) void(^)(void))block onComplete:(void(^)(NSError * _Nullable))onComplete;
/// :nodoc:
- (void)write:(__attribute__((noescape)) void(^)(void))block onComplete:(void(^)(NSError * _Nullable))onComplete __attribute__((unavailable("Renamed to -update:onComplete.")));

#pragma mark - Find subscription

/**
 Finds a subscription by the specified name.

 @param name The name used  to identify the subscription.

 @return A subscription for the given name.
 */
- (nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name;

/**
 Finds a subscription by the query for the specified object class name.

 @param objectClassName The class name for the model class to be queried.
 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.

 @return A subscription for the given query..
 */
- (nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                      where:(NSString *)predicateFormat, ...;

/// :nodoc:
- (nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                      where:(NSString *)predicateFormat
                                                       args:(va_list)args;

/**
 Finds a subscription by the query for the specified object class name.

 @param objectClassName The class name for the model class to be queried.
 @param predicate The predicate used to  to filter the objects on the server.

 @return A subscription for the given query..
 */
- (nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                  predicate:(NSPredicate *)predicate;

#pragma mark - Add a Subscription

/**
 Adds a new subscription to the subscription set which will be sent to the server when
 committed at the end of a write subscription block.

 @warning This method may only be called during a write subscription block.

 @param objectClassName The class name for the model class to be queried.
 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.
 */
- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                               where:(NSString *)predicateFormat, ...;

/// :nodoc:
- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                               where:(NSString *)predicateFormat
                                args:(va_list)args;

/**
 Adds a new subscription to the subscription set which will be sent to the server when
 committed at the end of a write subscription block.

 @warning This method may only be called during a write subscription block.

 @param objectClassName The class name for the model class to be queried.
 @param name The name used  the identify the subscription.
 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.
 */
- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(NSString *)name
                               where:(NSString *)predicateFormat, ...;

/// :nodoc:
- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(NSString *)name
                               where:(NSString *)predicateFormat
                                args:(va_list)args;

/**
 Adds a new subscription to the subscription set which will be sent to the server when
 committed at the end of a write subscription block.

 @warning This method may only be called during a write subscription block.

 @param objectClassName The class name for the model class to be queried.
 @param predicate The predicate defining the query for the subscription.
 */
- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                           predicate:(NSPredicate *)predicate;

/**
 Adds a new subscription to the subscription set which will be sent to the server when
 committed at the end of a write subscription block.

 @warning This method may only be called during a write subscription block.

 @param objectClassName The class name for the model class to be queried.
 @param name The name used to identify the subscription.
 @param predicate The predicate defining the query for the subscription.
 */
- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(nullable NSString *)name
                           predicate:(NSPredicate *)predicate;

#pragma mark - Remove Subscription

/**
 Removes a subscription with the specified name from the subscription set.

 @warning This method may only be called during a write subscription block.

 @param name The name used  the identify the subscription.
 */
- (void)removeSubscriptionWithName:(NSString *)name;

/**
 Removes a subscription with the specified query for the object class from the subscription set.

 @warning This method may only be called during a write subscription block.

 @param objectClassName The class name for the model class to be queried.
 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.
 */
- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat, ...;

/// :nodoc:
- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat
                                   args:(va_list)args;

/**
 Removes a subscription with the specified query for the object class from the subscription set.

 @warning This method may only be called during a write subscription block.

 @param objectClassName The class name for the model class to be queried.
 @param predicate  The predicate which will be used to identify the subscription to be removed.
 */
- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                              predicate:(NSPredicate *)predicate;

/**
 Removes the subscription from the subscription set.

 @warning This method may only be called during a write subscription block.

 @param subscription An instance of the subscription to be removed.
 */
- (void)removeSubscription:(RLMSyncSubscription *)subscription;

#pragma mark - Remove Subscriptions

/**
 Removes all subscription from the subscription set.

 @warning This method may only be called during a write subscription block.
 @warning Removing all subscriptions will result in an error if no new subscription is added. Server should
          acknowledge at least one subscription.
 */
- (void)removeAllSubscriptions;

/**
 Removes all subscription with the specified class name.

 @param className The class name for the model class to be queried.

 @warning This method may only be called during a write subscription block.
 */
- (void)removeAllSubscriptionsWithClassName:(NSString *)className;

#pragma mark - SubscriptionSet Collection

/**
 Returns the subscription at the given `index`.

 @param index The index.

 @return A subscription for the given index in the subscription set.
 */
- (nullable RLMSyncSubscription *)objectAtIndex:(NSUInteger)index;

/**
 Returns the first object in the subscription set list, or `nil` if the subscriptions are empty.

 @return A subscription.
 */
- (nullable RLMSyncSubscription *)firstObject;

/**
 Returns the last object in the subscription set, or `nil` if the subscriptions are empty.

 @return A subscription.
 */
- (nullable RLMSyncSubscription *)lastObject;

#pragma mark - Subscript

/**
 Returns the subscription at the given `index`.

 @param index The index.

 @return A subscription for the given index in the subscription set.
 */
- (id)objectAtIndexedSubscript:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
