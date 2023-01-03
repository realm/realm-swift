////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

@protocol RLMValue;
@class RLMResults<RLMObjectType>;

/**
 A `RLMSectionedResultsChange` object encapsulates information about changes to sectioned
 results that are reported by Realm notifications.

 `RLMSectionedResultsChange` is passed to the notification blocks registered with
 `-addNotificationBlock` on `RLMSectionedResults`, and reports what sections and rows in the
 collection changed since the last time the notification block was called.

 A complete example of updating a `UITableView` named `tv`:

     [tv beginUpdates];
     [tv deleteRowsAtIndexPaths:changes.deletions withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv insertRowsAtIndexPaths:changes.insertions withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv reloadRowsAtIndexPaths:changes.modifications withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv insertSections:changes.sectionsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv deleteSections:changes.sectionsToRemove withRowAnimation:UITableViewRowAnimationAutomatic];
     [tv endUpdates];

 All of the arrays in an `RLMSectionedResultsChange` are always sorted in ascending order.
 */
@interface RLMSectionedResultsChange : NSObject
/// The index paths of objects in the previous version of the collection which have
/// been removed from this one.
@property (nonatomic, readonly) NSArray<NSIndexPath *> *deletions;
/// The index paths in the new version of the collection which were newly inserted.
@property (nonatomic, readonly) NSArray<NSIndexPath *> *insertions;
/// The index paths in the old version of the collection which were modified.
@property (nonatomic, readonly) NSArray<NSIndexPath *> *modifications;
/// The indices of the sections to be inserted.
@property (nonatomic, readonly) NSIndexSet *sectionsToInsert;
/// The indices of the sections to be removed.
@property (nonatomic, readonly) NSIndexSet *sectionsToRemove;
/// Returns the index paths of the deletion indices in the given section.
- (NSArray<NSIndexPath *> *)deletionsInSection:(NSUInteger)section;
/// Returns the index paths of the insertion indices in the given section.
- (NSArray<NSIndexPath *> *)insertionsInSection:(NSUInteger)section;
/// Returns the index paths of the modification indices in the given section.
- (NSArray<NSIndexPath *> *)modificationsInSection:(NSUInteger)section;
@end


/// The `RLMSectionedResult` protocol defines properties and methods common to both `RLMSectionedResults and RLMSection`
@protocol RLMSectionedResult <NSFastEnumeration, RLMThreadConfined>

#pragma mark - Object Access

/// The count of objects in the collection.
@property (nonatomic, readonly) NSUInteger count;
/// Returns the object for a given index in the collection.
- (id)objectAtIndexedSubscript:(NSUInteger)index;
/// Returns the object for a given index in the collection.
- (id)objectAtIndex:(NSUInteger)index;

#pragma mark - Freeze

/**
 Returns a frozen (immutable) snapshot of this collection.

 The frozen copy is an immutable collection which contains the same data as this
 collection currently contains, but will not update when writes are made to the
 containing Realm. Unlike live arrays, frozen collections can be accessed from any
 thread.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning Holding onto a frozen collection for an extended period while performing
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
/**
 Indicates if the underlying collection is frozen.

 Frozen collections are immutable and can be accessed from any thread.
 */
@property (nonatomic, readonly, getter = isFrozen) BOOL frozen;

#pragma mark - Sectioned Results Notifications

/**
 Registers a block to be called each time the collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSection` / `RLMSectionedResults` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"sectionedResults.count: %zu", sectionedResults.count); // => 1
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @param block The block to be called whenever a change occurs.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(id<RLMSectionedResult>, RLMSectionedResultsChange *))block __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSection` / `RLMSectionedResults` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"sectionedResults.count: %zu", sectionedResults.count); // => 1
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @param block The block to be called whenever a change occurs.
 @param queue The serial queue to deliver notifications to.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(id<RLMSectionedResult>, RLMSectionedResultsChange *))block
                                         queue:(dispatch_queue_t)queue __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSection` / `RLMSectionedResults` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"sectionedResults.count: %zu", sectionedResults.count); // => 1
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @param block The block to be called whenever a change occurs.
 @param keyPaths The block will be called for changes occurring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(id<RLMSectionedResult>, RLMSectionedResultsChange *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSection` / `RLMSectionedResults` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"sectionedResults.count: %zu", sectionedResults.count); // => 1
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @note When filtering with key paths a notification will be fired in the following scenarios:
    - An object in the collection has been modified at the filtered properties.
    - An object has been modified on the section key path property, and the result of that modification has changed it's position in the section, or the object may need to move to another section.
    - An object of the same observed type has been inserted or deleted from the Realm.

 @param block The block to be called whenever a change occurs.
 @param keyPaths The block will be called for changes occurring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.
 @param queue The serial queue to deliver notifications to.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(id<RLMSectionedResult>, RLMSectionedResultsChange *))block
                                      keyPaths:(nullable NSArray<NSString *> *)keyPaths
                                         queue:(nullable dispatch_queue_t)queue __attribute__((warn_unused_result));

@end

/// An RLMSection contains the objects which belong to a specified section key.
@interface RLMSection<RLMKeyType: id<RLMValue>, RLMObjectType> : NSObject<RLMSectionedResult>
/// The value that represents the key in this section.
@property (nonatomic, readonly) RLMKeyType key;
/// The count of objects in the section.
@property (nonatomic, readonly) NSUInteger count;
/// Returns the object for a given index in the section.
- (RLMObjectType)objectAtIndexedSubscript:(NSUInteger)index;
/// Returns the object for a given index in the section.
- (RLMObjectType)objectAtIndex:(NSUInteger)index;

#pragma mark - Freeze

/**
 Returns a frozen (immutable) snapshot of this section.

 The frozen copy is an immutable section which contains the same data as this
 section currently contains, but will not update when writes are made to the
 containing Realm. Unlike live arrays, frozen collections can be accessed from any
 thread.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning Holding onto a frozen section for an extended period while performing
          write transaction on the Realm may result in the Realm file growing
          to large sizes. See `RLMRealmConfiguration.maximumNumberOfActiveVersions`
          for more information.
 */
- (instancetype)freeze;
/**
 Returns a live version of this frozen section.

 This method resolves a reference to a live copy of the same frozen section.
 If called on a live section, will return itself.
*/
- (instancetype)thaw;
/**
 Indicates if the underlying section is frozen.

 Frozen sections are immutable and can be accessed from any thread.
 */
@property (nonatomic, readonly, getter = isFrozen) BOOL frozen;

#pragma mark - Section Notifications

/**
 Registers a block to be called each time the section changes.

 The block will be asynchronously called with the initial section,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSection` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    RLMSection<Dog *> *section = sectionedResults[0] // section with dogs aged '5' already exists.

    self.token = [section addNotificationBlock:^(RLMSection *section, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"section.count: %zu", section.count); // => 2
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @param block The block to be called whenever a change occurs.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSection<RLMKeyType, RLMObjectType> *, RLMSectionedResultsChange *))block __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the section changes.

 The block will be asynchronously called with the initial section,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSection` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    RLMSection<Dog *> *section = sectionedResults[0] // section with dogs aged '5' already exists.

    self.token = [section addNotificationBlock:^(RLMSection *section, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"section.count: %zu", section.count); // => 2
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @param block The block to be called whenever a change occurs.
 @param queue The serial queue to deliver notifications to.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSection<RLMKeyType, RLMObjectType> *, RLMSectionedResultsChange *))block
                                         queue:(dispatch_queue_t)queue __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the section changes.

 The block will be asynchronously called with the initial section,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSection` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    RLMSection<Dog *> *section = sectionedResults[0] // section with dogs aged '5' already exists.

    self.token = [section addNotificationBlock:^(RLMSection *section, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"section.count: %zu", section.count); // => 2
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @note When filtering with key paths a notification will be fired in the following scenarios:
    - An object in the collection has been modified at the filtered properties.
    - An object has been modified on the section key path property, and the result of that modification has changed it's position in the section, or the object may need to move to another section.
    - An object of the same observed type has been inserted or deleted from the Realm.

 @param block The block to be called whenever a change occurs.
 @param keyPaths The block will be called for changes occurring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSection<RLMKeyType, RLMObjectType> *, RLMSectionedResultsChange *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the section changes.

 The block will be asynchronously called with the initial section,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSection` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    RLMSection<Dog *> *section = sectionedResults[0] // section with dogs aged '5' already exists.

    self.token = [section addNotificationBlock:^(RLMSection *section, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"section.count: %zu", section.count); // => 2
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @note When filtering with key paths a notification will be fired in the following scenarios:
    - An object in the collection has been modified at the filtered properties.
    - An object has been modified on the section key path property, and the result of that modification has changed it's position in the section, or the object may need to move to another section.
    - An object of the same observed type has been inserted or deleted from the Realm.

 @param block The block to be called whenever a change occurs.
 @param keyPaths The block will be called for changes occurring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.
 @param queue The serial queue to deliver notifications to.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSection<RLMKeyType, RLMObjectType> *, RLMSectionedResultsChange *))block
                                      keyPaths:(nullable NSArray<NSString *> *)keyPaths
                                         queue:(nullable dispatch_queue_t)queue __attribute__((warn_unused_result));
@end

/// A lazily evaluated collection that holds elements in sections determined by a section key.
@interface RLMSectionedResults<RLMKeyType: id<RLMValue>, RLMObjectType: id<RLMValue>> : NSObject<RLMSectionedResult>
/// An array of all keys in the sectioned results collection.
@property (nonatomic) NSArray<RLMKeyType> *allKeys;
/// The total amount of sections in this collection.
@property (nonatomic, readonly, assign) NSUInteger count;
/// Returns the section at a given index.
- (RLMSection<RLMKeyType, RLMObjectType> *)objectAtIndexedSubscript:(NSUInteger)index;
/// Returns the section at a given index.
- (RLMSection<RLMKeyType, RLMObjectType> *)objectAtIndex:(NSUInteger)index;

#pragma mark - Freeze

/**
 Returns a frozen (immutable) snapshot of this sectioned results collection.

 The frozen copy is an immutable sectioned results collection which contains the same data as this
 sectioned results collection currently contains, but will not update when writes are made to the
 containing Realm. Unlike live sectioned results collections, frozen sectioned results collection
 can be accessed from any thread.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning Holding onto a frozen sectioned results collection for an extended period while performing
          write transaction on the Realm may result in the Realm file growing
          to large sizes. See `RLMRealmConfiguration.maximumNumberOfActiveVersions`
          for more information.
 */
- (instancetype)freeze;
/**
 Returns a live version of this frozen sectioned results collection.

 This method resolves a reference to a live copy of the same frozen sectioned results collection.
 If called on a live section, will return itself.
*/
- (instancetype)thaw;
/**
 Indicates if the underlying sectioned results collection is frozen.

 Frozen sectioned results collections are immutable and can be accessed from any thread.
 */
@property (nonatomic, readonly, getter = isFrozen) BOOL frozen;

#pragma mark - Sectioned Results Notifications

/**
 Registers a block to be called each time the sectioned results collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSectionedResults` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"sectionedResults.count: %zu", sectionedResults.count); // => 1
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @param block The block to be called whenever a change occurs.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSectionedResults<RLMKeyType, RLMObjectType> *, RLMSectionedResultsChange *))block __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the sectioned results collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSectionedResults` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"sectionedResults.count: %zu", sectionedResults.count); // => 1
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @param block The block to be called whenever a change occurs.
 @param queue The serial queue to deliver notifications to.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSectionedResults<RLMKeyType, RLMObjectType> *, RLMSectionedResultsChange *))block
                                         queue:(dispatch_queue_t)queue __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the sectioned results collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSectionedResults` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"sectionedResults.count: %zu", sectionedResults.count); // => 1
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @note When filtering with key paths a notification will be fired in the following scenarios:
    - An object in the collection has been modified at the filtered properties.
    - An object has been modified on the section key path property, and the result of that modification has changed it's position in the section, or the object may need to move to another section.
    - An object of the same observed type has been inserted or deleted from the Realm.

 @param block The block to be called whenever a change occurs.
 @param keyPaths The block will be called for changes occurring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSectionedResults<RLMKeyType, RLMObjectType> *, RLMSectionedResultsChange *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the sectioned results collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which rows in the section were added, removed or modified. If a
 write transaction did not modify any objects in the section,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 At the time when the block is called, the `RLMSectionedResults` object will be fully
 evaluated and up-to-date.

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
    RLMSectionedResults<Dog *> *sectionedResults = [results sectionedResultsUsingKeyPath:@"age" ascending:YES];
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes) {
         // Only fired once for the example
         NSLog(@"sectionedResults.count: %zu", sectionedResults.count); // => 1
     }];
     [realm transactionWithBlock:^{
         Dog *dog = [[Dog alloc] init];
         dog.name = @"Rex";
         dog.age = 5;
         [realm addObject:dog];
     }];
     // end of run loop execution context

 You must retain the returned token for as long as you want updates to continue
 to be sent to the block. To stop receiving updates, call `-invalidate` on the token.

 @warning This method cannot be called during a write transaction, or when the
          containing Realm is read-only.
 @warning The queue must be a serial queue.

 @note When filtering with key paths a notification will be fired in the following scenarios:
    - An object in the collection has been modified at the filtered properties.
    - An object has been modified on the section key path property, and the result of that modification has changed it's position in the section, or the object may need to move to another section.
    - An object of the same observed type has been inserted or deleted from the Realm.

 @param block The block to be called whenever a change occurs.
 @param keyPaths The block will be called for changes occurring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.
 @param queue The serial queue to deliver notifications to.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSectionedResults<RLMKeyType, RLMObjectType> *, RLMSectionedResultsChange *))block
                                      keyPaths:(nullable NSArray<NSString *> *)keyPaths
                                         queue:(nullable dispatch_queue_t)queue __attribute__((warn_unused_result));
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
