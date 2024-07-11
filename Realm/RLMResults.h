////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import <Realm/RLMCollection.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

/// A block type used for APIs which asynchronously return a `Results`.
typedef void(^RLMResultsCompletionBlock)(RLMResults * _Nullable, NSError * _Nullable);

/**
 Determines wait for download behavior when subscribing on RLMResults.
 @see ``[RLMResults subscribeWithName:waitForSync:onQueue:completion:]``
*/
typedef NS_ENUM(NSUInteger, RLMWaitForSyncMode) {
    /// `subscribeWithName`'s callback will be invoked once matching objects are downloaded
    /// from the server only when the subscription is created the first time. If the
    /// subscription already exists, the callback is invoked without waiting for new downloads.
    RLMWaitForSyncModeOnCreation,
    /// `subscribeWithName`'s callback will wait for downloads before being invoked.
    /// The callback can't be invoked in this mode unless an internet connection is established or a timeout is set.
    RLMWaitForSyncModeAlways,
    /// `subscribeWithName`'s callback is always invoked without waiting for downloads.
    RLMWaitForSyncModeNever
} NS_SWIFT_NAME(WaitForSyncMode);

@class RLMObject;

/**
 `RLMResults` is an auto-updating container type in Realm returned from object
 queries. It represents the results of the query in the form of a collection of objects.

 `RLMResults` can be queried using the same predicates as `RLMObject` and `RLMArray`,
 and you can chain queries to further filter results.

 `RLMResults` always reflect the current state of the Realm on the current thread,
 including during write transactions on the current thread. The one exception to
 this is when using `for...in` fast enumeration, which will always enumerate
 over the objects which matched the query when the enumeration is begun, even if
 some of them are deleted or modified to be excluded by the filter during the
 enumeration.

 `RLMResults` are lazily evaluated the first time they are accessed; they only
 run queries when the result of the query is requested. This means that
 chaining several temporary `RLMResults` to sort and filter your data does not
 perform any extra work processing the intermediate state.

 Once the results have been evaluated or a notification block has been added,
 the results are eagerly kept up-to-date, with the work done to keep them
 up-to-date done on a background thread whenever possible.

 `RLMResults` cannot be directly instantiated.
 */
@interface RLMResults<RLMObjectType> : NSObject<RLMCollection, NSFastEnumeration>

#pragma mark - Properties

/**
 The number of objects in the results collection.
 */
@property (nonatomic, readonly, assign) NSUInteger count;

/**
 The type of the objects in the results collection.
 */
@property (nonatomic, readonly, assign) RLMPropertyType type;

/**
 Indicates whether the objects in the collection can be `nil`.
 */
@property (nonatomic, readwrite, getter = isOptional) BOOL optional;

/**
 The class name  of the objects contained in the results collection.

 Will be `nil` if `type` is not RLMPropertyTypeObject.
 */
@property (nonatomic, readonly, copy, nullable) NSString *objectClassName;

/**
 The Realm which manages this results collection.
 */
@property (nonatomic, readonly) RLMRealm *realm;

/**
 Indicates if the results collection is no longer valid.

 The results collection becomes invalid if `invalidate` is called on the containing `realm`.
 An invalidated results collection can be accessed, but will always be empty.
 */
@property (nonatomic, readonly, getter = isInvalidated) BOOL invalidated;

#pragma mark - Accessing Objects from an RLMResults

/**
 Returns the object at the index specified.

 @param index   The index to look up.

 @return An object of the type contained in the results collection.
 */
- (RLMObjectType)objectAtIndex:(NSUInteger)index;

/**
 Returns an array containing the objects in the results at the indexes specified by a given index set.
 `nil` will be returned if the index set contains an index out of the arrays bounds.

 @param indexes The indexes in the results to retrieve objects from.

 @return The objects at the specified indexes.
 */
- (nullable NSArray<RLMObjectType> *)objectsAtIndexes:(NSIndexSet *)indexes;

/**
 Returns the first object in the results collection.

 Returns `nil` if called on an empty results collection.

 @return An object of the type contained in the results collection.
 */
- (nullable RLMObjectType)firstObject;

/**
 Returns the last object in the results collection.

 Returns `nil` if called on an empty results collection.

 @return An object of the type contained in the results collection.
 */
- (nullable RLMObjectType)lastObject;

#pragma mark - Querying Results

/**
 Returns the index of an object in the results collection.

 Returns `NSNotFound` if the object is not found in the results collection.

 @param object  An object (of the same type as returned from the `objectClassName` selector).
 */
- (NSUInteger)indexOfObject:(RLMObjectType)object;

/**
 Returns the index of the first object in the results collection matching the predicate.

 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.

 @return    The index of the object, or `NSNotFound` if the object is not found in the results collection.
 */
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args;

/**
 Returns the index of the first object in the results collection matching the predicate.

 @param predicate   The predicate with which to filter the objects.

 @return    The index of the object, or `NSNotFound` if the object is not found in the results collection.
 */
- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate;

/**
 Returns all the objects matching the given predicate in the results collection.

 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.

 @return                An `RLMResults` of objects that match the given predicate.
 */
- (RLMResults<RLMObjectType> *)objectsWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (RLMResults<RLMObjectType> *)objectsWhere:(NSString *)predicateFormat args:(va_list)args;

/**
 Returns all the objects matching the given predicate in the results collection.

 @param predicate   The predicate with which to filter the objects.

 @return            An `RLMResults` of objects that match the given predicate.
 */
- (RLMResults<RLMObjectType> *)objectsWithPredicate:(NSPredicate *)predicate;

/**
 Returns a sorted `RLMResults` from an existing results collection.

 @param keyPath     The key path to sort by.
 @param ascending   The direction to sort in.

 @return    An `RLMResults` sorted by the specified key path.
 */
- (RLMResults<RLMObjectType> *)sortedResultsUsingKeyPath:(NSString *)keyPath ascending:(BOOL)ascending;

/**
 Returns a sorted `RLMResults` from an existing results collection.

 @param properties  An array of `RLMSortDescriptor`s to sort by.

 @return    An `RLMResults` sorted by the specified properties.
 */
- (RLMResults<RLMObjectType> *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties;

/**
 Returns a distinct `RLMResults` from an existing results collection.
 
 @param keyPaths  The key paths used produce distinct results
 
 @return    An `RLMResults` made distinct based on the specified key paths
 */
- (RLMResults<RLMObjectType> *)distinctResultsUsingKeyPaths:(NSArray<NSString *> *)keyPaths;

#pragma mark - Notifications

/**
 Registers a block to be called each time the results collection changes.

 The block will be asynchronously called with the initial results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the results collection were added, removed or modified. If a
 write transaction did not modify any objects in the results collection,
 the block is not called at all. See the `RLMCollectionChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 The error parameter is present only for backwards compatibility and will always
 be `nil`.

 At the time when the block is called, the `RLMResults` object will be fully
 evaluated and up-to-date, and as long as you do not perform a write transaction
 on the same thread or explicitly call `-[RLMRealm refresh]`, accessing it will
 never perform blocking work.

 Notifications are delivered via the standard run loop, and so can't be
 delivered while the run loop is blocked by other activity. When
 notifications can't be delivered instantly, multiple notifications may be
 coalesced into a single notification. This can include the notification
 with the initial results. For example, the following code performs a write
 transaction immediately after adding the notification block, so there is no
 opportunity for the initial notification to be delivered first. As a
 result, the initial notification will reflect the state of the Realm after
 the write transaction.

     RLMResults<Dog *> *results = [Dog allObjects];
     NSLog(@"dogs.count: %zu", dogs.count); // => 0
     self.token = [results addNotificationBlock:^(RLMResults *dogs,
                                                  RLMCollectionChange *changes,
                                                  NSError *error) {
         // Only fired once for the example
         NSLog(@"dogs.count: %zu", dogs.count); // => 1
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.

 @param block The block to be called whenever a change occurs.
 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults<RLMObjectType> *_Nullable results,
                                                         RLMCollectionChange *_Nullable change,
                                                         NSError *_Nullable error))block
__attribute__((warn_unused_result));

/**
 Registers a block to be called each time the results collection changes.

 The block will be asynchronously called with the initial results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the results collection were added, removed or modified. If a
 write transaction did not modify any objects in the results collection,
 the block is not called at all. See the `RLMCollectionChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 The error parameter is present only for backwards compatibility and will always
 be `nil`.

 At the time when the block is called, the `RLMResults` object will be fully
 evaluated and up-to-date, and as long as you do not perform a write transaction
 on the same thread or explicitly call `-[RLMRealm refresh]`, accessing it will
 never perform blocking work.

 Notifications are delivered on the given queue. If the queue is blocked and
 notifications can't be delivered instantly, multiple notifications may be
 coalesced into a single notification.

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called when the containing Realm is read-only or frozen.
 @warning The queue must be a serial queue.

 @param block The block to be called whenever a change occurs.
 @param queue The serial queue to deliver notifications to.
 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults<RLMObjectType> *_Nullable results,
                                                         RLMCollectionChange *_Nullable change,
                                                         NSError *_Nullable error))block
                                         queue:(nullable dispatch_queue_t)queue
__attribute__((warn_unused_result));

/**
 Registers a block to be called each time the results collection changes.

 The block will be asynchronously called with the initial results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the results collection were added, removed or modified. If a
 write transaction did not modify any objects in the results collection,
 the block is not called at all. See the `RLMCollectionChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 The error parameter is present only for backwards compatibility and will always
 be `nil`.

 At the time when the block is called, the `RLMResults` object will be fully
 evaluated and up-to-date, and as long as you do not perform a write transaction
 on the same thread or explicitly call `-[RLMRealm refresh]`, accessing it will
 never perform blocking work.

 Notifications are delivered on the given queue. If the queue is blocked and
 notifications can't be delivered instantly, multiple notifications may be
 coalesced into a single notification.

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called when the containing Realm is read-only or frozen.
 @warning The queue must be a serial queue.

 @param block The block to be called whenever a change occurs.
 @param queue The serial queue to deliver notifications to.
 @param keyPaths The block will be called for changes occurring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.
 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults<RLMObjectType> *_Nullable results,
                                                         RLMCollectionChange *_Nullable change,
                                                         NSError *_Nullable error))block
                                      keyPaths:(nullable NSArray<NSString *> *)keyPaths
                                         queue:(nullable dispatch_queue_t)queue
__attribute__((warn_unused_result));

/**
 Registers a block to be called each time the results collection changes.

 The block will be asynchronously called with the initial results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the results collection were added, removed or modified. If a
 write transaction did not modify any objects in the results collection,
 the block is not called at all. See the `RLMCollectionChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 The error parameter is present only for backwards compatibility and will always
 be `nil`.

 At the time when the block is called, the `RLMResults` object will be fully
 evaluated and up-to-date, and as long as you do not perform a write transaction
 on the same thread or explicitly call `-[RLMRealm refresh]`, accessing it will
 never perform blocking work.

 Notifications are delivered via the standard run loop, and so can't be
 delivered while the run loop is blocked by other activity. When
 notifications can't be delivered instantly, multiple notifications may be
 coalesced into a single notification. This can include the notification
 with the initial results. For example, the following code performs a write
 transaction immediately after adding the notification block, so there is no
 opportunity for the initial notification to be delivered first. As a
 result, the initial notification will reflect the state of the Realm after
 the write transaction.

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called when the containing Realm is read-only or frozen.
 @warning The queue must be a serial queue.

 @param block The block to be called whenever a change occurs.
 @param keyPaths The block will be called for changes occurring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.
 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults<RLMObjectType> *_Nullable results,
                                                         RLMCollectionChange *_Nullable change,
                                                         NSError *_Nullable error))block
                                      keyPaths:(nullable NSArray<NSString *> *)keyPaths
__attribute__((warn_unused_result));

#pragma mark - Flexible Sync

/**
 Creates a RLMSyncSubscription matching the RLMResults's local filter.

 After committing the subscription to the realm's local subscription set, the method
 will wait for downloads according to ``RLMWaitForSyncMode`` behavior.

 ### Unnamed subscriptions ###
 If `subscribeWithCompletion:` is called without a name whose query matches an unnamed subscription, another subscription is not created.

 If `subscribeWithCompletion:` is called without a name whose query matches a named subscription, an additional  unnamed subscription is created.
 ### Named Subscriptions ###
 If `subscribeWithCompletion:` is called with a name whose query matches an unnamed subscription, an additional named subscription is created.
 ### Existing name and query ###
 If `subscribeWithCompletion:` is called with a name whose name is taken on a different query, the old subscription is updated with the new query.

 @note This method opens an update block transaction that creates or updates a subscription.
 It's advised to *not* loop over this method in order to create multiple subscriptions at once.
 This could create a performance bottleneck by opening multiple unnecessary write transactions.
 @see: `[RLMSyncSubscription update:queue:onComplete:]` in order to create multiple subscriptions.

 @param queue The queue where the completion dispatches.
 @param completion The completion block called after the subscription completes. The callback
 will wait for downloads according to the value in `waitForSyncMode`.
 @see ``RLMWaitForSyncMode``
 @warning This API is currently in `Preview` and may be subject to changes in the future.
 */
- (void)subscribeWithCompletionOnQueue:(dispatch_queue_t _Nullable)queue
                            completion:(RLMResultsCompletionBlock)completion;

/**
 Creates a RLMSyncSubscription matching the RLMResults's local filter.

 After committing the subscription to the realm's local subscription set, the method
 will wait for downloads according to ``RLMWaitForSyncMode`` behavior.

 ### Unnamed subscriptions ###
 If `subscribeWithCompletion:` is called without a name whose query matches an unnamed subscription, another subscription is not created.

 If `subscribeWithCompletion:` is called without a name whose query matches a named subscription, an additional  unnamed subscription is created.
 ### Named Subscriptions ###
 If `subscribeWithCompletion:` is called with a name whose query matches an unnamed subscription, an additional named subscription is created.
 ### Existing name and query ###
 If `subscribeWithCompletion:` is called with a name whose name is taken on a different query, the old subscription is updated with the new query.

 @note This method opens an update block transaction that creates or updates a subscription.
 It's advised to *not* loop over this method in order to create multiple subscriptions at once.
 This could create a performance bottleneck by opening multiple unnecessary write transactions.
 @see: `[RLMSyncSubscription update:queue:onComplete:]` in order to create multiple subscriptions.

 @param name The name used to identify the subscription.
 @param queue The queue where the completion dispatches.
 @param completion The completion block called after the subscription completes. The callback
 will wait for downloads according to the value in `waitForSyncMode`.
 @see ``RLMWaitForSyncMode``
 @warning This API is currently in `Preview` and may be subject to changes in the future.
 */
- (void)subscribeWithName:(NSString *_Nullable)name
                  onQueue:(dispatch_queue_t _Nullable)queue
               completion:(RLMResultsCompletionBlock)completion;

/**
 Creates a RLMSyncSubscription matching the RLMResults's local filter.

 After committing the subscription to the realm's local subscription set, the method
 will wait for downloads according to the ``RLMWaitForSyncMode``.

 ### Unnamed subscriptions ###
 If `subscribeWithCompletion:` is called without a name whose query matches an unnamed subscription, another subscription is not created.

 If `subscribeWithCompletion:` is called without a name whose query matches a named subscription, an additional  unnamed subscription is created.
 ### Named Subscriptions ###
 If `subscribeWithCompletion:` is called with a name whose query matches an unnamed subscription, an additional named subscription is created.
 ### Existing name and query ###
 If `subscribeWithCompletion:` is called with a name whose name is taken on a different query, the old subscription is updated with the new query.

 @note This method opens an update block transaction that creates or updates a subscription.
 It's advised to *not* loop over this method in order to create multiple subscriptions at once.
 This could create a performance bottleneck by opening multiple unnecessary write transactions.
 @see: `[RLMSyncSubscription update:queue:onComplete:]` in order to create multiple subscriptions.

 @param name The name used  to identify the subscription.
 @param waitForSyncMode Dictates when the completion handler is called
 @param queue The queue where the completion dispatches.
 @param completion The completion block called after the subscription completes. The callback
 will wait for downloads according to the value in `waitForSyncMode`.
 @see ``RLMWaitForSyncMode``
 @warning This API is currently in `Preview` and may be subject to changes in the future.
 */
- (void)subscribeWithName:(NSString *_Nullable)name
              waitForSync:(RLMWaitForSyncMode)waitForSyncMode
                  onQueue:(dispatch_queue_t _Nullable)queue
               completion:(RLMResultsCompletionBlock)completion
__attribute__((swift_attr("@_unsafeInheritExecutor")));

/**
 Creates a RLMSyncSubscription matching the RLMResults's local filter.

 After committing the subscription to the realm's local subscription set, the method
 will wait for downloads according to the ``RLMWaitForSyncMode``.

 ### Unnamed subscriptions ###
 If `subscribeWithCompletion:` is called without a name whose query matches an unnamed subscription, another subscription is not created.

 If `subscribeWithCompletion:` is called without a name whose query matches a named subscription, an additional  unnamed subscription is created.
 ### Named Subscriptions ###
 If `subscribeWithCompletion:` is called with a name whose query matches an unnamed subscription, an additional named subscription is created.
 ### Existing name and query ###
 If `subscribeWithCompletion:` is called with a name whose name is taken on a different query, the old subscription is updated with the new query.

 @note This method opens an update block transaction that creates or updates a subscription.
 It's advised to *not* loop over this method in order to create multiple subscriptions at once.
 This could create a performance bottleneck by opening multiple unnecessary write transactions.
 @see: `[RLMSyncSubscription update:queue:onComplete:]` in order to create multiple subscriptions.

 @param name The name used  to identify the subscription.
 @param waitForSyncMode Dictates when the completion handler is called
 @param queue The queue where the completion dispatches.
 @param timeout A timeout which ends waiting for downloads
 via the completion handler. If the timeout is exceeded the completion
 handler returns an error.
 @param completion The completion block called after the subscription completes. The callback
 will wait for downloads according to the value in `waitForSyncMode`.
 @see ``RLMWaitForSyncMode``
 @warning This API is currently in `Preview` and may be subject to changes in the future.
 */
- (void)subscribeWithName:(NSString *_Nullable)name
              waitForSync:(RLMWaitForSyncMode)waitForSyncMode
                  onQueue:(dispatch_queue_t _Nullable)queue
                  timeout:(NSTimeInterval)timeout
               completion:(RLMResultsCompletionBlock)completion
__attribute__((swift_attr("@_unsafeInheritExecutor")));

/**
 Removes a RLMSubscription matching the RLMResults'slocal filter.

 The method returns after committing the subscription removal to the
 realm's local subscription set. Calling this method will not wait for objects to
 be removed from the realm.

 Calling unsubscribe on a RLMResults does not remove the local filter from the RLMResults.
 After calling unsubscribe, RLMResults may still contain objects because
 other subscriptions may exist in the RLMRealm's subscription set.

 @note In order for a named subscription to be removed, the RLMResults
 must have previously created the subscription.
 The `RLMResults` returned in the completion block when calling `subscribe` can be used to unsubscribe from the same subscription.

 @note This method opens an update block transaction that creates or updates a subscription.
 It's advised to *not* loop over this method in order to create multiple subscriptions at once.
 This could create a performance bottleneck by opening multiple unnecessary write transactions.
 @see: ``[RLMSyncSubscription update:queue:onComplete:]`` in order to create multiple subscriptions.
 @warning This API is currently in `Preview` and may be subject to changes in the future.
 */
- (void)unsubscribe;

#pragma mark - Aggregating Property Values

/**
 Returns the minimum (lowest) value of the given property among all the objects
 represented by the results collection.

     NSNumber *min = [results minOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose minimum value is desired. Only properties of types `int`, `float`, `double`, and
                 `NSDate` are supported.

 @return The minimum value of the property, or `nil` if the Results are empty.
 */
- (nullable id)minOfProperty:(NSString *)property;

/**
 Returns the maximum (highest) value of the given property among all the objects represented by the results collection.

     NSNumber *max = [results maxOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose maximum value is desired. Only properties of
                 types `int`, `float`, `double`, and `NSDate` are supported.

 @return The maximum value of the property, or `nil` if the Results are empty.
 */
- (nullable id)maxOfProperty:(NSString *)property;

/**
 Returns the sum of the values of a given property over all the objects represented by the results collection.

     NSNumber *sum = [results sumOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose values should be summed. Only properties of
                 types `int`, `float`, and `double` are supported.

 @return The sum of the given property.
 */
- (NSNumber *)sumOfProperty:(NSString *)property;

/**
 Returns the average value of a given property over the objects represented by the results collection.

     NSNumber *average = [results averageOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose average value should be calculated. Only
                 properties of types `int`, `float`, and `double` are supported.

 @return    The average value of the given property, or `nil` if the Results are empty.
 */
- (nullable NSNumber *)averageOfProperty:(NSString *)property;

/// :nodoc:
- (RLMObjectType)objectAtIndexedSubscript:(NSUInteger)index;

#pragma mark - Sectioned Results

/**
 Sorts and sections this collection from a given property key path, returning the result
 as an instance of `RLMSectionedResults`.

 @param keyPath The property key path to sort on.
 @param ascending The direction to sort in.
 @param keyBlock  A callback which is invoked on each element in the Results collection.
                 This callback is to return the section key for the element in the collection.

 @return An instance of RLMSectionedResults.
 */
- (RLMSectionedResults *)sectionedResultsSortedUsingKeyPath:(NSString *)keyPath
                                                  ascending:(BOOL)ascending
                                                   keyBlock:(RLMSectionedResultsKeyBlock)keyBlock;

/**
 Sorts and sections this collection from a given array of sort descriptors, returning the result
 as an instance of `RLMSectionedResults`.

 @param sortDescriptors  An array of `RLMSortDescriptor`s to sort by.
 @param keyBlock  A callback which is invoked on each element in the Results collection.
                 This callback is to return the section key for the element in the collection.

 @note The primary sort descriptor must be responsible for determining the section key.

 @return An instance of RLMSectionedResults.
 */
- (RLMSectionedResults *)sectionedResultsUsingSortDescriptors:(NSArray<RLMSortDescriptor *> *)sortDescriptors
                                                     keyBlock:(RLMSectionedResultsKeyBlock)keyBlock;

#pragma mark - Freeze

/**
 Indicates if the result are frozen.

 Frozen Results are immutable and can be accessed from any thread.The objects
 read from a frozen Results will also be frozen.
 */
@property (nonatomic, readonly, getter=isFrozen) BOOL frozen;

/**
 Returns a frozen (immutable) snapshot of these results.

 The frozen copy is an immutable collection which contains the same data as
 this collection currently contains, but will not update when writes are made
 to the containing Realm. Unlike live Results, frozen Results can be accessed
 from any thread.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning Holding onto a frozen collection for an extended period while
          performing write transaction on the Realm may result in the Realm
          file growing to large sizes. See
          `RLMRealmConfiguration.maximumNumberOfActiveVersions` for more
          information.
 */
- (instancetype)freeze;

/**
 Returns a live version of this frozen collection.

 This method resolves a reference to a live copy of the same frozen collection.
 If called on a live collection, will return itself.
*/
- (instancetype)thaw;

#pragma mark - Unavailable Methods

/**
 `-[RLMResults init]` is not available because `RLMResults` cannot be created directly.
 `RLMResults` can be obtained by querying a Realm.
 */
- (instancetype)init __attribute__((unavailable("RLMResults cannot be created directly")));

/**
 `+[RLMResults new]` is not available because `RLMResults` cannot be created directly.
 `RLMResults` can be obtained by querying a Realm.
 */
+ (instancetype)new __attribute__((unavailable("RLMResults cannot be created directly")));

@end

/**
 `RLMLinkingObjects` is an auto-updating container type. It represents a collection of objects that link to its
 parent object.

 For more information, please see the "Inverse Relationships" section in the
 [documentation](https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/model-data/relationships/).
 */
@interface RLMLinkingObjects<RLMObjectType: RLMObject *> : RLMResults
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
