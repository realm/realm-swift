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

#import <Realm/RLMDefines.h>

RLM_ASSUME_NONNULL_BEGIN

@class RLMRealm, RLMResults, RLMObject, RLMSortDescriptor, RLMNotificationToken, RLMCollectionChange;

/**
 A homogenous collection of `RLMObject`s like `RLMArray` or `RLMResults`.
 */
@protocol RLMCollection <NSFastEnumeration>

@required

#pragma mark - Properties

/**
 Number of objects in the collection.
 */
@property (nonatomic, readonly, assign) NSUInteger count;

/**
 The class name (i.e. type) of the RLMObjects contained in this RLMCollection.
 */
@property (nonatomic, readonly, copy) NSString *objectClassName;

/**
 The Realm in which this collection is persisted. Returns nil for standalone collections.
 */
@property (nonatomic, readonly) RLMRealm *realm;

#pragma mark - Accessing Objects from a Collection

/**
 Returns the object at the index specified.

 @param index   The index to look up.

 @return An RLMObject of the type contained in this RLMCollection.
 */
- (id)objectAtIndex:(NSUInteger)index;

/**
 Returns the first object in the collection.

 Returns `nil` if called on an empty RLMCollection.

 @return An RLMObject of the type contained in this RLMCollection.
 */
- (nullable id)firstObject;

/**
 Returns the last object in the collection.

 Returns `nil` if called on an empty RLMCollection.

 @return An RLMObject of the type contained in this RLMCollection.
 */
- (nullable id)lastObject;

#pragma mark - Querying a Collection

/**
 Gets the index of an object.

 Returns NSNotFound if the object is not found in this RLMCollection.

 @param object  An object (of the same type as returned from the objectClassName selector).
 */
- (NSUInteger)indexOfObject:(RLMObject *)object;

/**
 Gets the index of the first object matching the predicate.

 @param predicateFormat The predicate format string which can accept variable arguments.

 @return    Index of object or NSNotFound if the object is not found in this RLMCollection.
 */
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args;

/**
 Gets the index of the first object matching the predicate.

 @param predicate   The predicate to filter the objects.

 @return    Index of object or NSNotFound if the object is not found in this RLMCollection.
 */
- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate;

/**
 Get objects matching the given predicate in the RLMCollection.

 @param predicateFormat The predicate format string which can accept variable arguments.

 @return    An RLMResults of objects that match the given predicate
 */
- (RLMResults *)objectsWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (RLMResults *)objectsWhere:(NSString *)predicateFormat args:(va_list)args;

/**
 Get objects matching the given predicate in the RLMCollection.

 @param predicate   The predicate to filter the objects.

 @return            An RLMResults of objects that match the given predicate
 */
- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate;

/**
 Get a sorted RLMResults from an RLMCollection.

 @param property    The property name to sort by.
 @param ascending   The direction to sort by.

 @return    An RLMResults sorted by the specified property.
 */
- (RLMResults *)sortedResultsUsingProperty:(NSString *)property ascending:(BOOL)ascending;

/**
 Get a sorted RLMResults from an RLMCollection.

 @param properties  An array of `RLMSortDescriptor`s to sort by.

 @return    An RLMResults sorted by the specified properties.
 */
- (RLMResults *)sortedResultsUsingDescriptors:(NSArray RLM_GENERIC(RLMSortDescriptor *) *)properties;

/// :nodoc:
- (id)objectAtIndexedSubscript:(NSUInteger)index;

/**
 Returns an NSArray containing the results of invoking `valueForKey:` using key on each of the collection's objects.

 @param key The name of the property.

 @return NSArray containing the results of invoking `valueForKey:` using key on each of the collection's objects.
 */
- (nullable id)valueForKey:(NSString *)key;

/**
 Invokes `setValue:forKey:` on each of the collection's objects using the specified value and key.

 @warning This method can only be called during a write transaction.

 @param value The object value.
 @param key   The name of the property.
 */
- (void)setValue:(nullable id)value forKey:(NSString *)key;

#pragma mark - Notifications

/**
 Register a block to be called each time the RLMCollection changes.

 The block will be asynchronously called with the initial collection, and then
 called again after each write transaction which changes either any of the
 objects in the collection, or which objects are in the collection.

 The change parameter will be `nil` the first time the block is called with the
 initial collection. For each call after that, it will contain information about
 which rows in the collection were added, removed or modified. If a write transaction
 did not modify any objects in this collection, the block is not called at all.
 See the RLMCollectionChange documentation for information on how the changes
 are reported and an example of updating a UITableView.

 If an error occurs the block will be called with `nil` for the collection
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the RLMRealm on the background worker thread.

 At the time when the block is called, the RLMCollection object will be fully
 evaluated and up-to-date, and as long as you do not perform a write transaction
 on the same thread or explicitly call `-[RLMRealm refresh]`, accessing it will
 never perform blocking work.

 Notifications are delivered via the standard run loop, and so can't be
 delivered while the run loop is blocked by other activity. When
 notifications can't be delivered instantly, multiple notifications may be
 coalesced into a single notification. This can include the notification
 with the initial collection. For example, the following code performs a write
 transaction immediately after adding the notification block, so there is no
 opportunity for the initial notification to be delivered first. As a
 result, the initial notification will reflect the state of the Realm after
 the write transaction.

     id<RLMCollection> collection = [Dog allObjects];
     NSLog(@"dogs.count: %zu", dogs.count); // => 0
     self.token = [collection addNotificationBlock:^(id<RLMCollection> dogs,
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
 to be sent to the block. To stop receiving updates, call `-stop` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing realm is read-only.

 @param block The block to be called with the evaluated collection.
 @return A token which must be held for as long as you want collection notifications to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(id<RLMCollection> __nullable collection,
                                                         RLMCollectionChange *__nullable change,
                                                         NSError *__nullable error))block RLM_WARN_UNUSED_RESULT;

@end
/**
 An RLMSortDescriptor stores a property name and a sort order for use with
 `sortedResultsUsingDescriptors:`. It is similar to NSSortDescriptor, but supports
 only the subset of functionality which can be efficiently run by the query
 engine. RLMSortDescriptor instances are immutable.
 */
@interface RLMSortDescriptor : NSObject

#pragma mark - Properties

/**
 The name of the property which this sort descriptor orders results by.
 */
@property (nonatomic, readonly) NSString *property;

/**
 Whether this descriptor sorts in ascending or descending order.
 */
@property (nonatomic, readonly) BOOL ascending;

#pragma mark - Methods

/**
 Returns a new sort descriptor for the given property name and order.
 */
+ (instancetype)sortDescriptorWithProperty:(NSString *)propertyName ascending:(BOOL)ascending;

/**
 Returns a copy of the receiver with the sort order reversed.
 */
- (instancetype)reversedSortDescriptor;

@end

/**
 RLMCollectionChange is passed to the notification blocks registered with
 -addNotificationBlock on RLMArray and RLMResults, and reports what rows in the
 collection changed since the last time the notification block was called.

 The change information is available in two formats: a simple array of row
 indices in the collection for each type of change, and an array of index paths
 in a requested section suitable for passing directly to UITableView's batch
 update methods. A complete example of updating a `UITableView` named `tv`:

     [tv beginUpdates];
     [tv deleteRowsAtIndexPaths:[changes deletionsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv insertRowsAtIndexPaths:[changes insertionsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv reloadRowsAtIndexPaths:[changes modificationsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv endUpdates];

 All of the arrays in an RLMCollectionChange are always sorted in ascending order.
 */
@interface RLMCollectionChange : NSObject
/// The indices of objects in the previous version of the collection which have
/// been removed from this one.
@property (nonatomic, readonly) NSArray RLM_GENERIC(NSNumber *) *deletions;

/// The indices in the new version of the collection which were newly inserted.
@property (nonatomic, readonly) NSArray RLM_GENERIC(NSNumber *) *insertions;

/// The indices in the new version of the collection which were modified. For
/// RLMResults, this means that one or more of the properties of the object at
/// that index were modified (or an object linked to by that object was
/// modified). For RLMArray, the array itself being modified to contain a
/// different object at that index will also be reported as a modification.
@property (nonatomic, readonly) NSArray RLM_GENERIC(NSNumber *) *modifications;


- (NSArray RLM_GENERIC(NSIndexPath *)*)deletionsInSection:(NSUInteger)section;
- (NSArray RLM_GENERIC(NSIndexPath *)*)insertionsInSection:(NSUInteger)section;
- (NSArray RLM_GENERIC(NSIndexPath *)*)modificationsInSection:(NSUInteger)section;
@end

RLM_ASSUME_NONNULL_END
