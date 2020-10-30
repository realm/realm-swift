////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

NS_ASSUME_NONNULL_BEGIN

@class RLMObject, RLMResults<RLMObjectType>;

@interface RLMSet<RLMObjectType> : NSObject<RLMCollection, NSFastEnumeration>

#pragma mark - Properties

/**
 The number of objects in the set.
 */
@property (nonatomic, readonly, assign) NSUInteger count;

@property (nonatomic, readonly) NSArray<RLMObjectType> *array;

/**
 The type of the objects in the set.
 */
@property (nonatomic, readonly, assign) RLMPropertyType type;

/**
 Indicates whether the objects in the collection can be `nil`.
 */
@property (nonatomic, readonly, getter = isOptional) BOOL optional;

/**
 The class name of the objects contained in the set.

 Will be `nil` if `type` is not RLMPropertyTypeObject.
 */
@property (nonatomic, readonly, copy, nullable) NSString *objectClassName;

/**
 The Realm which manages the set. Returns `nil` for unmanaged set.
 */
@property (nonatomic, readonly, nullable) RLMRealm *realm;

/**
 Indicates if the set can no longer be accessed.
 */
@property (nonatomic, readonly, getter = isInvalidated) BOOL invalidated;

/**
 Indicates if the set is frozen.

 Frozen sets are immutable and can be accessed from any thread. Frozen sets
 are created by calling `-freeze` on a managed live set. Unmanaged sets are
 never frozen.
 */
@property (nonatomic, readonly, getter = isFrozen) BOOL frozen;

#pragma mark - Accessing Objects from an Set

/**
 Returns the object at the index specified.

 @param index   The index to look up.

 @return An object of the type contained in the set.
 */
- (RLMObjectType)objectAtIndex:(NSUInteger)index;

/**
 Returns the first object in the set.

 Returns `nil` if called on an empty set.

 @return An object of the type contained in the set.
 */
- (nullable RLMObjectType)firstObject;

/**
 Returns the last object in the set.

 Returns `nil` if called on an empty set.

 @return An object of the type contained in the set.
 */
- (nullable RLMObjectType)lastObject;

#pragma mark - Adding, Removing, and Replacing Objects in a Set

/**
 Adds an object to the end of the set.

 @warning This method may only be called during a write transaction.

 @param object  An object of the type contained in the set.
 */
- (void)addObject:(RLMObjectType)object;

/**
 Adds an array of objects to the end of the set.

 @warning This method may only be called during a write transaction.

 @param objects     An enumerable object such as `NSArray`, `NSSet` or `RLMResults` which contains objects of the
                    same class as the set.
 */
- (void)addObjects:(id<NSFastEnumeration>)objects;

- (void)insertObject:(RLMObjectType)anObject atIndex:(NSUInteger)index;

- (void)removeObjectAtIndex:(NSUInteger)index;

- (void)removeLastObject;

/**
 Removes all objects from the set.

 @warning This method may only be called during a write transaction.
 */
- (void)removeAllObjects;

/// :nodoc:
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(RLMObjectType)anObject;


/**
 Moves the object at the given source index to the given destination index.

 Throws an exception if the index exceeds the bounds of the array.

 @warning This method may only be called during a write transaction.

 @param sourceIndex      The index of the object to be moved.
 @param destinationIndex The index to which the object at `sourceIndex` should be moved.
 */
- (void)moveObjectAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex
__attribute((unavailable("replaceObjectAtIndex:withObject: is not available with RLMSet.")));

/**
 Exchanges the objects in the array at given indices.

 Throws an exception if either index exceeds the bounds of the array.

 @warning This method may only be called during a write transaction.

 @param index1 The index of the object which should replace the object at index `index2`.
 @param index2 The index of the object which should replace the object at index `index1`.
 */
- (void)exchangeObjectAtIndex:(NSUInteger)index1 withObjectAtIndex:(NSUInteger)index2;

#pragma mark - Querying an Array

/**
 Returns the index of an object in the set.

 Returns `NSNotFound` if the object is not found in the set.

 @param object  An object (of the same type as returned from the `objectClassName` selector).
 */
- (NSUInteger)indexOfObject:(RLMObjectType)object;

/**
 Returns the index of the first object in the array matching the predicate.

 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.

 @return The index of the object, or `NSNotFound` if the object is not found in the set.
 */
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args;

/**
 Returns the index of the object in the set matching the predicate.

 @param predicate   The predicate with which to filter the objects.

 @return    The index of the object, or `NSNotFound` if the object is not found in the set.
 */
- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate;

/// :nodoc:
- (RLMResults<RLMObjectType> *)objectsWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (RLMResults<RLMObjectType> *)objectsWhere:(NSString *)predicateFormat args:(va_list)args;

/// :nodoc:
- (RLMResults<RLMObjectType> *)objectsWithPredicate:(NSPredicate *)predicate;

/// :nodoc:
- (RLMResults<RLMObjectType> *)sortedResultsUsingKeyPath:(NSString *)keyPath ascending:(BOOL)ascending;

/// :nodoc:
- (RLMResults<RLMObjectType> *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties;

/// :nodoc:
- (RLMResults<RLMObjectType> *)distinctResultsUsingKeyPaths:(NSArray<NSString *> *)keyPaths;

/// :nodoc:
- (RLMObjectType)objectAtIndexedSubscript:(NSUInteger)index;

/// :nodoc:
- (void)setObject:(RLMObjectType)newValue atIndexedSubscript:(NSUInteger)index;


- (void)intersectSet:(RLMSet<RLMObjectType> *)set;

- (void)minusSet:(RLMSet<RLMObjectType> *)set;

- (void)unionSet:(RLMSet<RLMObjectType> *)set;

- (BOOL)intersectsSet:(RLMSet<id> *)set;

- (BOOL)isSubsetOfSet:(RLMSet<id> *)set;

#pragma mark - Notifications

/**
 Registers a block to be called each time the array changes.

 The block will be asynchronously called with the initial array, and then
 called again after each write transaction which changes any of the objects in
 the array, which objects are in the results, or the order of the objects in the
 array.

 The `changes` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the array were added, removed or modified. If a write transaction
 did not modify any objects in the array, the block is not called at all.
 See the `RLMCollectionChange` documentation for information on how the changes
 are reported and an example of updating a `UITableView`.

 If an error occurs the block will be called with `nil` for the results
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the Realm on the background worker thread.

 Notifications are delivered via the standard run loop, and so can't be
 delivered while the run loop is blocked by other activity. When
 notifications can't be delivered instantly, multiple notifications may be
 coalesced into a single notification. This can include the notification
 with the initial results. For example, the following code performs a write
 transaction immediately after adding the notification block, so there is no
 opportunity for the initial notification to be delivered first. As a
 result, the initial notification will reflect the state of the Realm after
 the write transaction.

     Person *person = [[Person allObjectsInRealm:realm] firstObject];
     NSLog(@"person.dogs.count: %zu", person.dogs.count); // => 0
     self.token = [person.dogs addNotificationBlock(RLMArray<Dog *> *dogs,
                                                    RLMCollectionChange *changes,
                                                    NSError *error) {
         // Only fired once for the example
         NSLog(@"dogs.count: %zu", dogs.count) // => 1
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         [person.dogs addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning This method may only be called on a non-frozen managed array.

 @param block The block to be called each time the array changes.
 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSet<RLMObjectType> *_Nullable set,
                                                         RLMCollectionChange *_Nullable changes,
                                                         NSError *_Nullable error))block
__attribute__((warn_unused_result));

/**
 Registers a block to be called each time the array changes.

 The block will be asynchronously called with the initial array, and then
 called again after each write transaction which changes any of the objects in
 the array, which objects are in the results, or the order of the objects in the
 array.

 The `changes` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the array were added, removed or modified. If a write transaction
 did not modify any objects in the array, the block is not called at all.
 See the `RLMCollectionChange` documentation for information on how the changes
 are reported and an example of updating a `UITableView`.

 If an error occurs the block will be called with `nil` for the results
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the Realm on the background worker thread.

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
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSet<RLMObjectType> *_Nullable set,
                                                         RLMCollectionChange *_Nullable changes,
                                                         NSError *_Nullable error))block
                                         queue:(nullable dispatch_queue_t)queue
__attribute__((warn_unused_result));

#pragma mark - Aggregating Property Values

/**
 Returns the minimum (lowest) value of the given property among all the objects in the array.

     NSNumber *min = [object.arrayProperty minOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose minimum value is desired. Only properties of
                 types `int`, `float`, `double`, and `NSDate` are supported.

 @return The minimum value of the property, or `nil` if the array is empty.
 */
- (nullable id)minOfProperty:(NSString *)property;

/**
 Returns the maximum (highest) value of the given property among all the objects in the array.

     NSNumber *max = [object.arrayProperty maxOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose maximum value is desired. Only properties of
                 types `int`, `float`, `double`, and `NSDate` are supported.

 @return The maximum value of the property, or `nil` if the array is empty.
 */
- (nullable id)maxOfProperty:(NSString *)property;

/**
 Returns the sum of the values of a given property over all the objects in the array.

     NSNumber *sum = [object.arrayProperty sumOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose values should be summed. Only properties of
                 types `int`, `float`, and `double` are supported.

 @return The sum of the given property.
 */
- (NSNumber *)sumOfProperty:(NSString *)property;

/**
 Returns the average value of a given property over the objects in the array.

     NSNumber *average = [object.arrayProperty averageOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose average value should be calculated. Only
                 properties of types `int`, `float`, and `double` are supported.

 @return    The average value of the given property, or `nil` if the array is empty.
 */
- (nullable NSNumber *)averageOfProperty:(NSString *)property;

#pragma mark - Freeze

/**
 Returns a frozen (immutable) snapshot of this array.

 The frozen copy is an immutable array which contains the same data as this
 array currently contains, but will not update when writes are made to the
 containing Realm. Unlike live arrays, frozen arrays can be accessed from any
 thread.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning This method may only be called on a managed array.
 @warning Holding onto a frozen array for an extended period while performing
          write transaction on the Realm may result in the Realm file growing
          to large sizes. See `RLMRealmConfiguration.maximumNumberOfActiveVersions`
          for more information.
 */
- (instancetype)freeze;

#pragma mark - Unavailable Methods

/**
 `-[RLMArray init]` is not available because `RLMArray`s cannot be created directly.
 `RLMArray` properties on `RLMObject`s are lazily created when accessed.
 */
- (instancetype)init __attribute__((unavailable("RLMSets cannot be created directly")));

/**
 `+[RLMArray new]` is not available because `RLMArray`s cannot be created directly.
 `RLMArray` properties on `RLMObject`s are lazily created when accessed.
 */
+ (instancetype)new __attribute__((unavailable("RLMSet cannot be created directly")));

@end

/// :nodoc:
@interface RLMSet (Swift)
// for use only in Swift class definitions
- (instancetype)initWithObjectClassName:(NSString *)objectClassName;
@end

NS_ASSUME_NONNULL_END
