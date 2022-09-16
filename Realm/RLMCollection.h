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

#import <Foundation/Foundation.h>

#import <Realm/RLMConstants.h>
#import <Realm/RLMThreadSafeReference.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RLMValue;
@class RLMRealm, RLMResults, RLMSortDescriptor, RLMNotificationToken, RLMCollectionChange, RLMSectionedResults;
typedef RLM_CLOSED_ENUM(int32_t, RLMPropertyType);
/// A callback which is invoked on each element in the Results collection which returns the section key.
typedef id<RLMValue> _Nullable(^RLMSectionedResultsKeyBlock)(id);

/**
 A homogenous collection of Realm-managed objects. Examples of conforming types
 include `RLMArray`, `RLMSet`, `RLMResults`, and `RLMLinkingObjects`.
 */
@protocol RLMCollection <NSFastEnumeration, RLMThreadConfined>

#pragma mark - Properties

/**
 The number of objects in the collection.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 The type of the objects in the collection.
 */
@property (nonatomic, readonly) RLMPropertyType type;

/**
 Indicates whether the objects in the collection can be `nil`.
 */
@property (nonatomic, readonly, getter = isOptional) BOOL optional;

/**
 The class name  of the objects contained in the collection.

 Will be `nil` if `type` is not RLMPropertyTypeObject.
 */
@property (nonatomic, readonly, copy, nullable) NSString *objectClassName;

/**
 The Realm which manages this collection, if any.
 */
@property (nonatomic, readonly, nullable) RLMRealm *realm;

/**
 Indicates if the collection is no longer valid.

 The collection becomes invalid if `invalidate` is called on the managing
 Realm. Unmanaged collections are never invalidated.
 */
@property (nonatomic, readonly, getter = isInvalidated) BOOL invalidated;

#pragma mark - Accessing Objects from a Collection

/**
 Returns the object at the index specified.

 @param index   The index to look up.

 @return An object of the type contained in the collection.
 */
- (id)objectAtIndex:(NSUInteger)index;

@optional

/**
 Returns an array containing the objects in the collection at the indexes
 specified by a given index set. `nil` will be returned if the index set
 contains an index out of the collections bounds.

 @param indexes The indexes in the collection to retrieve objects from.

 @return The objects at the specified indexes.
 */
- (nullable NSArray *)objectsAtIndexes:(NSIndexSet *)indexes;

/**
 Returns the first object in the collection.

 RLMSet is not ordered, and so for sets this will return an arbitrary object in
 the set. It is not guaraneed to be a different object from what `lastObject`
 gives even if the set has multiple objects in it.

 Returns `nil` if called on an empty collection.

 @return An object of the type contained in the collection.
 */
- (nullable id)firstObject;

/**
 Returns the last object in the collection.

 RLMSet is not ordered, and so for sets this will return an arbitrary object in
 the set. It is not guaraneed to be a different object from what `firstObject`
 gives even if the set has multiple objects in it.

 Returns `nil` if called on an empty collection.

 @return An object of the type contained in the collection.
 */
- (nullable id)lastObject;

/// :nodoc:
- (id)objectAtIndexedSubscript:(NSUInteger)index;

/**
 Returns the index of an object in the collection.

 Returns `NSNotFound` if the object is not found in the collection.

 @param object  An object (of the same type as returned from the `objectClassName` selector).
 */
- (NSUInteger)indexOfObject:(id)object;

/**
 Returns the index of the first object in the collection matching the predicate.

 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.

 @return    The index of the object, or `NSNotFound` if the object is not found in the collection.
 */
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args;

/**
 Returns the index of the first object in the collection matching the predicate.

 @param predicate   The predicate with which to filter the objects.

 @return    The index of the object, or `NSNotFound` if the object is not found in the collection.
 */
- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate;

@required

#pragma mark - Querying a Collection

/**
 Returns all objects matching the given predicate in the collection.

 This is only supported for managed collections.

 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.
 @return    An `RLMResults` containing objects that match the given predicate.
 */
- (RLMResults *)objectsWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (RLMResults *)objectsWhere:(NSString *)predicateFormat args:(va_list)args;

/**
 Returns all objects matching the given predicate in the collection.

 This is only supported for managed collections.

 @param predicate   The predicate with which to filter the objects.
 @return            An `RLMResults` containing objects that match the given predicate.
 */
- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate;

/**
 Returns a sorted `RLMResults` from the collection.

 This is only supported for managed collections.

 @param keyPath     The keyPath to sort by.
 @param ascending   The direction to sort in.
 @return    An `RLMResults` sorted by the specified key path.
 */
- (RLMResults *)sortedResultsUsingKeyPath:(NSString *)keyPath ascending:(BOOL)ascending;

/**
 Returns a sorted `RLMResults` from the collection.

 This is only supported for managed collections.

 @param properties  An array of `RLMSortDescriptor`s to sort by.
 @return    An `RLMResults` sorted by the specified properties.
 */
- (RLMResults *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties;

/**
 Returns a distinct `RLMResults` from the collection.

 This is only supported for managed collections.

 @param keyPaths  The key paths used produce distinct results
 @return    An `RLMResults` made distinct based on the specified key paths
 */
- (RLMResults *)distinctResultsUsingKeyPaths:(NSArray<NSString *> *)keyPaths;

/**
 Returns an `NSArray` containing the results of invoking `valueForKey:` using
 `key` on each of the collection's objects.

 @param key The name of the property.

 @return An `NSArray` containing results.
 */
- (nullable id)valueForKey:(NSString *)key;

/**
 Returns the value for the derived property identified by a given key path.

 @param keyPath A key path of the form relationship.property (with one or more relationships).

 @return The value for the derived property identified by keyPath.
 */
- (nullable id)valueForKeyPath:(NSString *)keyPath;

/**
 Invokes `setValue:forKey:` on each of the collection's objects using the specified `value` and `key`.

 @warning This method may only be called during a write transaction.

 @param value The object value.
 @param key   The name of the property.
 */
- (void)setValue:(nullable id)value forKey:(NSString *)key;

#pragma mark - Notifications

/**
Registers a block to be called each time the collection changes.

The block will be asynchronously called with the initial collection,
and then called again after each write transaction which changes either any
of the objects in the collection, or which objects are in the collection.

The `change` parameter will be `nil` the first time the block is called.
For each call after that, it will contain information about
which rows in the collection were added, removed or modified. If a
write transaction did not modify any objects in the results collection,
the block is not called at all. See the `RLMCollectionChange` documentation for
information on how the changes are reported and an example of updating a
`UITableView`.

 The error parameter is present only for backwards compatiblity and will always
 be `nil`.

At the time when the block is called, the collection object will be fully
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
         containing Realm is read-only or frozen.

@param block The block to be called whenever a change occurs.
@return A token which must be held for as long as you want updates to be delivered.
*/
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *_Nullable results,
                                                         RLMCollectionChange *_Nullable change,
                                                         NSError *_Nullable error))block
__attribute__((warn_unused_result));

/**
Registers a block to be called each time the collection changes.

The block will be asynchronously called with the initial collection,
and then called again after each write transaction which changes either any
of the objects in the collection, or which objects are in the collection.

The `change` parameter will be `nil` the first time the block is called.
For each call after that, it will contain information about
which rows in the collection were added, removed or modified. If a
write transaction did not modify any objects in the results collection,
the block is not called at all. See the `RLMCollectionChange` documentation for
information on how the changes are reported and an example of updating a
`UITableView`.

 The error parameter is present only for backwards compatiblity and will always
 be `nil`.

At the time when the block is called, the collection object will be fully
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
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *_Nullable results,
                                                         RLMCollectionChange *_Nullable change,
                                                         NSError *_Nullable error))block
                                         queue:(nullable dispatch_queue_t)queue
__attribute__((warn_unused_result));

/**
Registers a block to be called each time the collection changes.

The block will be asynchronously called with the initial collection,
and then called again after each write transaction which changes either any
of the objects in the collection, or which objects are in the collection.

The `change` parameter will be `nil` the first time the block is called.
For each call after that, it will contain information about
which rows in the collection were added, removed or modified. If a
write transaction did not modify any objects in the results collection,
the block is not called at all. See the `RLMCollectionChange` documentation for
information on how the changes are reported and an example of updating a
`UITableView`.

 The error parameter is present only for backwards compatiblity and will always
 be `nil`.

At the time when the block is called, the collection object will be fully
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
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *_Nullable results,
                                                         RLMCollectionChange *_Nullable change,
                                                         NSError *_Nullable error))block
                                      keyPaths:(nullable NSArray<NSString *> *)keyPaths
                                         queue:(nullable dispatch_queue_t)queue
__attribute__((warn_unused_result));

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

#pragma mark - Aggregating Property Values

/**
 Returns the minimum (lowest) value of the given property among all the objects
 in the collection.

     NSNumber *min = [results minOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose minimum value is desired. Only properties of
                 types `int`, `float`, `double`, and `NSDate` are supported.

 @return The minimum value of the property, or `nil` if the Results are empty.
 */
- (nullable id)minOfProperty:(NSString *)property;

/**
 Returns the maximum (highest) value of the given property among all the objects
 in the collection.

     NSNumber *max = [results maxOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose maximum value is desired. Only properties of
                 types `int`, `float`, `double`, and `NSDate` are supported.

 @return The maximum value of the property, or `nil` if the Results are empty.
 */
- (nullable id)maxOfProperty:(NSString *)property;

/**
 Returns the sum of the values of a given property over all the objects in the collection.

     NSNumber *sum = [results sumOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose values should be summed. Only properties of
                 types `int`, `float`, and `double` are supported.

 @return The sum of the given property.
 */
- (NSNumber *)sumOfProperty:(NSString *)property;

/**
 Returns the average value of a given property over the objects in the collection.

     NSNumber *average = [results averageOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`, and `NSData` properties.

 @param property The property whose average value should be calculated. Only
                 properties of types `int`, `float`, and `double` are supported.

 @return    The average value of the given property, or `nil` if the Results are empty.
 */
- (nullable NSNumber *)averageOfProperty:(NSString *)property;

#pragma mark - Freeze

/**
 Indicates if the collection is frozen.

 Frozen collections are immutable and can be accessed from any thread. The
 objects read from a frozen collection will also be frozen.
 */
@property (nonatomic, readonly, getter=isFrozen) BOOL frozen;

/**
 Returns a frozen (immutable) snapshot of this collection.

 The frozen copy is an immutable collection which contains the same data as
 this collection currently contains, but will not update when writes are made
 to the containing Realm. Unlike live collections, frozen collections can be
 accessed from any thread.

 @warning This method cannot be called during a write transaction, or when the containing Realm is read-only.
 @warning Holding onto a frozen collection for an extended period while
          performing write transaction on the Realm may result in the Realm
          file growing to large sizes. See
          `RLMRealmConfiguration.maximumNumberOfActiveVersions`
          for more information.
 */
- (instancetype)freeze;

/**
 Returns a live version of this frozen collection.

 This method resolves a reference to a live copy of the same frozen collection.
 If called on a live collection, will return itself.
*/
- (instancetype)thaw;

@end

/**
 An `RLMSortDescriptor` stores a property name and a sort order for use with
 `sortedResultsUsingDescriptors:`. It is similar to `NSSortDescriptor`, but supports
 only the subset of functionality which can be efficiently run by Realm's query
 engine.

 `RLMSortDescriptor` instances are immutable.
 */
@interface RLMSortDescriptor : NSObject

#pragma mark - Properties

/**
 The key path which the sort descriptor orders results by.
 */
@property (nonatomic, readonly) NSString *keyPath;

/**
 Whether the descriptor sorts in ascending or descending order.
 */
@property (nonatomic, readonly) BOOL ascending;

#pragma mark - Methods

/**
 Returns a new sort descriptor for the given key path and sort direction.
 */
+ (instancetype)sortDescriptorWithKeyPath:(NSString *)keyPath ascending:(BOOL)ascending;

/**
 Returns a copy of the receiver with the sort direction reversed.
 */
- (instancetype)reversedSortDescriptor;

@end

/**
 A `RLMCollectionChange` object encapsulates information about changes to collections
 that are reported by Realm notifications.

 `RLMCollectionChange` is passed to the notification blocks registered with
 `-addNotificationBlock` on `RLMArray` and `RLMResults`, and reports what rows in the
 collection changed since the last time the notification block was called.

 The change information is available in two formats: a simple array of row
 indices in the collection for each type of change, and an array of index paths
 in a requested section suitable for passing directly to `UITableView`'s batch
 update methods. A complete example of updating a `UITableView` named `tv`:

     [tv beginUpdates];
     [tv deleteRowsAtIndexPaths:[changes deletionsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv insertRowsAtIndexPaths:[changes insertionsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv reloadRowsAtIndexPaths:[changes modificationsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv endUpdates];

 All of the arrays in an `RLMCollectionChange` are always sorted in ascending order.
 */
@interface RLMCollectionChange : NSObject
/// The indices of objects in the previous version of the collection which have
/// been removed from this one.
@property (nonatomic, readonly) NSArray<NSNumber *> *deletions;

/// The indices in the new version of the collection which were newly inserted.
@property (nonatomic, readonly) NSArray<NSNumber *> *insertions;

/**
 The indices in the new version of the collection which were modified.

 For `RLMResults`, this means that one or more of the properties of the object at
 that index were modified (or an object linked to by that object was
 modified).

 For `RLMArray`, the array itself being modified to contain a
 different object at that index will also be reported as a modification.
 */
@property (nonatomic, readonly) NSArray<NSNumber *> *modifications;

/// Returns the index paths of the deletion indices in the given section.
- (NSArray<NSIndexPath *> *)deletionsInSection:(NSUInteger)section;

/// Returns the index paths of the insertion indices in the given section.
- (NSArray<NSIndexPath *> *)insertionsInSection:(NSUInteger)section;

/// Returns the index paths of the modification indices in the given section.
- (NSArray<NSIndexPath *> *)modificationsInSection:(NSUInteger)section;
@end

NS_ASSUME_NONNULL_END
