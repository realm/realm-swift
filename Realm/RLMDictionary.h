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

#import <Realm/RLMCollection.h>

NS_ASSUME_NONNULL_BEGIN

@class RLMObject, RLMResults<RLMObjectType>;

@protocol RLMDictionaryKey <NSCopying>
@end

@interface NSString (RLMDictionaryKey)<RLMDictionaryKey>
@end

/**
 * Key-value collection. Where the key is a string and value is one of the available Realm types.
 */
@interface RLMDictionary<RLMKeyType, RLMObjectType>: NSObject<RLMCollection>

#pragma mark - Properties

/**
 The number of (key, value) pairs in the dictionary.
 */
@property (nonatomic, readonly, assign) NSUInteger count;

/**
 The type of the value objects in the dictionary.
 */
@property (nonatomic, readonly, assign) RLMPropertyType type;

/**
 The type of the key object in the dictionary.
 */
@property (nonatomic, readonly, assign) RLMPropertyType keyType;

/**
 Indicates whether the objects in the collection can be `nil`.
 */
@property (nonatomic, readonly, getter = isOptional) BOOL optional;

/**
 The class name of the objects contained in the dictionary.

 Will be `nil` if `type` is not RLMPropertyTypeObject.
 */
@property (nonatomic, readonly, copy, nullable) NSString *objectClassName;

/**
 The Realm which manages the dictionary. Returns `nil` for unmanaged dictionary.RLMDictionaryKey
 */
@property (nonatomic, readonly, nullable) RLMRealm *realm;

/**
 Indicates if the dictionary can no longer be accessed.
 */
@property (nonatomic, readonly, getter = isInvalidated) BOOL invalidated;

/**
 Indicates if the dictionary is frozen.

 Frozen dictionaries are immutable and can be accessed from any thread. Frozen dictionaries
 are created by calling `-freeze` on a managed live dictionary. Unmanaged dictionaries are
 never frozen.
 */
@property (nonatomic, readonly, getter = isFrozen) BOOL frozen;

#pragma mark - Accessing Objects from an Dictionary

/**
 Returns the value associated with a given key.

 @param key The name of the property.

 @return A value associated with a given key or `nil`.
 */
- (nullable id)valueForKey:(nonnull RLMKeyType <RLMDictionaryKey>)key;

/**
 Returns an object, if present, for a given key in the dictionary.
 */
- (nullable RLMObjectType)objectForKey:(nonnull RLMKeyType <RLMDictionaryKey>)key;

/**
 Returns an array containing the dictionary’s keys.
 */
@property(readonly, copy) NSArray<RLMKeyType <RLMDictionaryKey>> *allKeys;

/**
 Returns an array containing the dictionary’s values.
 */
@property(readonly, copy) NSArray<RLMObjectType> *allValues;

/// :nodoc:
- (nullable RLMObjectType)objectForKeyedSubscript:(RLMKeyType <RLMDictionaryKey>)key;

/**
 Applies a given block object to the each key-value pair of the dictionary
 */
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(RLMKeyType <RLMDictionaryKey> key, RLMObjectType obj, BOOL *stop))block;

#pragma mark - Adding, Removing, and Replacing Objects in a Dictionary

/**
 Replace the data of a dictionary with the data of another dictionary.
 */
- (void)setDictionary:(RLMDictionary<RLMKeyType <RLMDictionaryKey>, RLMObjectType> *)otherDictionary;

/**
 Delete all dictionary's keys and values.
 */
- (void)removeAllObjects;

/**
 Adds an array of distinct objects to the set.

 @warning This method may only be called during a write transaction.

 @param objects      `NSDictionary` which contains objects of the
                    same class as the dictionary.
 */
- (void)addObjects:(NSDictionary *)objects;

/**
 Delete dictionary's values for a given keys.
 */
- (void)removeObjectsForKeys:(NSArray<RLMKeyType> *)keyArray;

/**
 Delete dictionary's value for a given key.
 */
- (void)removeObjectForKey:(RLMKeyType <RLMDictionaryKey>)key;

/**
 Add a value for a given key indictioanry.
 */
- (void)setObject:(RLMObjectType)obj forKeyedSubscript:(RLMKeyType <RLMDictionaryKey>)key;

/**
 Adds a given key-value pair to the dictionary.
 */
- (void)setObject:(RLMObjectType)anObject forKey:(RLMKeyType <RLMDictionaryKey>)aKey;

/**
 Adds to the receiving dictionary the entries from another dictionary.
 */
- (void)addEntriesFromDictionary:(RLMDictionary<RLMKeyType <RLMDictionaryKey>, RLMObjectType> *)otherDictionary;

#pragma mark - Querying a Dictionary

/**
 Returns the index of an object in the dictionary.

 Returns `NSNotFound` if the object is not found in the dictionary.

 @param object  An object (of the same type as returned from the `objectClassName` selector).
 */
- (NSUInteger)indexOfObject:(RLMObjectType)object;

/**
 Returns the index of the first object in the array matching the predicate.

 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.

 @return    The index of the object, or `NSNotFound` if the object is not found in the dictionary.
 */
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args;

/**
 Returns the index of the first object in the dictionary matching the predicate.

 @param predicate   The predicate with which to filter the objects.

 @return    The index of the object, or `NSNotFound` if the object is not found in the dictionary.
 */
- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate;

/**
 Returns all the objects matching the given predicate in the dictionary.

 @param predicateFormat A predicate format string, optionally followed by a variable number of arguments.

 @return                An `RLMResults` of objects that match the given predicate.
 */
- (RLMResults<RLMObjectType> *)objectsWhere:(NSString *)predicateFormat, ...;

/// :nodoc:
- (RLMResults<RLMObjectType> *)objectsWhere:(NSString *)predicateFormat args:(va_list)args;

/**
 Returns all the objects matching the given predicate in the dictionary.

 @param predicate   The predicate with which to filter the objects.

 @return            An `RLMResults` of objects that match the given predicate
 */
- (RLMResults<RLMObjectType> *)objectsWithPredicate:(NSPredicate *)predicate;

/**
 Returns a sorted `RLMResults` from the dictionary.

 @param keyPath     The key path to sort by.
 @param ascending   The direction to sort in.

 @return    An `RLMResults` sorted by the specified key path.
 */
- (RLMResults<RLMObjectType> *)sortedResultsUsingKeyPath:(NSString *)keyPath ascending:(BOOL)ascending;

/**
 Returns a sorted `RLMResults` from the dictionary.

 @param properties  An array of `RLMSortDescriptor`s to sort by.

 @return    An `RLMResults` sorted by the specified properties.
 */
- (RLMResults<RLMObjectType> *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties;

/**
 Returns a distinct `RLMResults` from the dictionary.

 @param keyPaths     The key paths to distinct on.

 @return    An `RLMResults` with the distinct values of the keypath(s).
 */
- (RLMResults<RLMObjectType> *)distinctResultsUsingKeyPaths:(NSArray<NSString *> *)keyPaths;

#pragma mark - Aggregating Property Values

/**
 Returns the minimum (lowest) value of the given property among all the values in the dictionary.

     NSNumber *min = [object.dictionaryProperty minOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`,  `RLMArray`,  `RLMSet`, and `NSData` properties.

 @param property The property whose minimum value is desired. Only properties of
                 types `int`, `float`, `double`, and `NSDate` are supported.

 @return The minimum value of the property, or `nil` if the dictionary is empty.
 */
- (nullable id)minOfProperty:(NSString *)property;

/**
 Returns the maximum (highest) value of the given property among all the objects in the dictionary.

     NSNumber *max = [object.dictionaryProperty maxOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`,  `RLMSet`, and `NSData` properties.

 @param property The property whose maximum value is desired. Only properties of
                 types `int`, `float`, `double`, and `NSDate` are supported.

 @return The maximum value of the property, or `nil` if the dictionary is empty.
 */
- (nullable id)maxOfProperty:(NSString *)property;

/**
 Returns the sum of distinct values of a given property over all the objects in the dictionary.

     NSNumber *sum = [object.dictionaryProperty sumOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMArray`,  `RLMSet and `NSData` properties.

 @param property The property whose values should be summed. Only properties of
                 types `int`, `float`, and `double` are supported.

 @return The sum of the given property.
 */
- (NSNumber *)sumOfProperty:(NSString *)property;

/**
 Returns the average value of a given property over the objects in the dictionary.

     NSNumber *average = [object.dictionaryProperty averageOfProperty:@"age"];

 @warning You cannot use this method on `RLMObject`, `RLMSet`,  `RLMArray`, and `NSData` properties.

 @param property The property whose average value should be calculated. Only
                 properties of types `int`, `float`, and `double` are supported.

 @return    The average value of the given property, or `nil` if the dictionary is empty.
 */
- (nullable NSNumber *)averageOfProperty:(NSString *)property;

#pragma mark - Notifications

/**
 Registers a block to be called each time the dictionary changes.

 The block will be asynchronously called with the initial dictionary, and then
 called again after each write transaction which changes any of the objects in
 the dictionary or which objects are in the results.

 The `changes` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the dictionary were added, removed or modified. If a write transaction
 did not modify any objects in the dictionary, the block is not called at all.
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
     self.token = [person.dogs addNotificationBlock(RLMDictionary<Dog *> *dogs,
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
 @warning This method may only be called on a non-frozen managed dictionary.

 @param block The block to be called each time the dictionary changes.
 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMDictionary<RLMKeyType <RLMDictionaryKey>, RLMObjectType> *_Nullable dictionary,
                                                         RLMCollectionChange *_Nullable changes,
                                                         NSError *_Nullable error))block
__attribute__((warn_unused_result));

/**
 Registers a block to be called each time the dictionary changes.

 The block will be asynchronously called with the initial dictionary, and then
 called again after each write transaction which changes any of the key-value in
 the dictionary or which objects are in the results.

 The `changes` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the dictionary were added, removed or modified. If a write transaction
 did not modify any objects in the dictionary, the block is not called at all.
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
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMDictionary<RLMKeyType <RLMDictionaryKey>, RLMObjectType> *_Nullable dictionary,
                                                         RLMCollectionChange *_Nullable changes,
                                                         NSError *_Nullable error))block
                                         queue:(nullable dispatch_queue_t)queue
__attribute__((warn_unused_result));

#pragma mark - Freeze

/**
 Returns a frozen (immutable) snapshot of a dictionary.

 The frozen copy is an immutable dictionary which contains the same data as this
 dictionary currently contains, but will not update when writes are made to the
 containing Realm. Unlike live dictionaries, frozen dictionaries can be accessed from any
 thread.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning This method may only be called on a managed dictionary.
 @warning Holding onto a frozen dictionary for an extended period while performing
          write transaction on the Realm may result in the Realm file growing
          to large sizes. See `RLMRealmConfiguration.maximumNumberOfActiveVersions`
          for more information.
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
 `-[RLMDictionary init]` is not available because `RLMDictionary`s cannot be created directly.
 `RLMDictionary` properties on `RLMObject`s are lazily created when accessed.
 */
- (instancetype)init __attribute__((unavailable("RLMDictionary cannot be created directly")));
/**
 `+[RLMDictionary new]` is not available because `RLMDictionary`s cannot be created directly.
 `RLMDictionary` properties on `RLMObject`s are lazily created when accessed.
 */
+ (instancetype)new __attribute__((unavailable("RLMDictionary cannot be created directly")));

@end
NS_ASSUME_NONNULL_END
