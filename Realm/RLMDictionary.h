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

#ifndef RLMDictionary_h
#define RLMDictionary_h

#import <Foundation/Foundation.h>
#import <Realm/RLMCollection.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Key-value collection. Where the key is a string and value is one of the available Realm types.
 */
@interface RLMDictionary<RLMObjectType>: NSObject<RLMCollection>

/**
 Indicates if the dictionary is frozen.

 Frozen dictionaries are immutable and can be accessed from any thread. Frozen dictionaries
 are created by calling `-freeze` on a managed live dictionary. Unmanaged dictionaries are
 never frozen.
 */
@property (nonatomic, readonly, getter = isFrozen) BOOL frozen;

/**
 The class name of the objects contained in the dictionary.

 Will be `nil` if `type` is not RLMPropertyTypeObject.
 */
@property (nonatomic, readonly, copy, nullable) NSString *objectClassName;

/**
 The type of the value objects in the dictionary.
 */
@property (nonatomic, readonly, assign) RLMPropertyType type;

/**
 Indicates whether the objects in the collection can be `nil`.
 */
@property (nonatomic, readonly, getter = isOptional) BOOL optional;

/**
 The Realm which manages the dictionary. Returns `nil` for unmanaged set.
 */
@property (nonatomic, readonly, nullable) RLMRealm *realm;

/**
 The number of (key, value) pairs in the dictionary.
 */
@property (nonatomic, readonly, assign) NSUInteger count;

/**
 Registers a block to be called each time the dictionary changes.

 The block will be asynchronously called with the initial dictionary, and then
 called again after each write transaction which changes any of the objects in
 the dictionary, which objects are in the results.

 The `changes` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the set were added, removed or modified. If a write transaction
 did not modify any objects in the set, the block is not called at all.
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
     self.token = [person.dogs addNotificationBlock(RLMSet<Dog *> *dogs,
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
 @warning This method may only be called on a non-frozen managed set.

 @param block The block to be called each time the set changes.
 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMDictionary<RLMObjectType> *_Nullable set,
                                                         RLMCollectionChange *_Nullable changes,
                                                         NSError *_Nullable error))block
__attribute__((warn_unused_result));

- (NSUInteger)indexOfObject:(nonnull id)object;
- (NSUInteger)indexOfObjectWhere:(nonnull NSString *)predicateFormat, ...;
- (NSUInteger)indexOfObjectWhere:(nonnull NSString *)predicateFormat args:(va_list)args;
- (NSUInteger)indexOfObjectWithPredicate:(nonnull NSPredicate *)predicate;
- (nonnull id)objectAtIndex:(NSUInteger)index;
- (nonnull RLMResults *)objectsWhere:(nonnull NSString *)predicateFormat, ...;
- (nonnull RLMResults *)objectsWhere:(nonnull NSString *)predicateFormat args:(va_list)args;
- (nonnull RLMResults *)objectsWithPredicate:(nonnull NSPredicate *)predicate;
- (void)setValue:(nullable id)value forKey:(nonnull NSString *)key;
- (nonnull RLMResults *)sortedResultsUsingDescriptors:(nonnull NSArray<RLMSortDescriptor *> *)properties;
- (nonnull RLMResults *)sortedResultsUsingKeyPath:(nonnull NSString *)keyPath ascending:(BOOL)ascending;
- (nullable id)valueForKey:(nonnull NSString *)key;
- (NSUInteger)countByEnumeratingWithState:(nonnull NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nullable * _Nonnull)buffer count:(NSUInteger)len;

/**
 Indicates if the set can no longer be accessed.
 */
@property (nonatomic, readonly, getter = isInvalidated) BOOL invalidated;

- (instancetype)freeze;

@end
NS_ASSUME_NONNULL_END

#endif /* RLMDictionary_h */
