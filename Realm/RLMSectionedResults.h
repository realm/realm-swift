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

NS_ASSUME_NONNULL_BEGIN

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

/// An RLMSection contains the objects which below to a specified section key.
@interface RLMSection<RLMObjectType> : NSObject<NSFastEnumeration, RLMThreadConfined>
/// The count of objects in this section.
@property (nonatomic, readonly, assign) NSUInteger count;
/// The value that represents the key in this section.
@property (nonatomic, readonly) id<RLMValue> key;
/// Returns the object for a given index in the section.
- (RLMObjectType)objectAtIndexedSubscript:(NSUInteger)index;
/// Returns the object for a given index in the section.
- (id)objectAtIndex:(NSUInteger)index;

#pragma mark - RLMSection Notifications

/**
 Registers a block to be called each time the section changes.

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

 If an error occurs the block will be called with `nil` for the results
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the Realm on the background worker thread.

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
    RLMSection<Dog *> *section = sectionedResults[0]; // Objects already exist for Dog.
    self.token = [results addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes,
                                   NSError *error) {
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

 @param block The block to be called whenever a change occurs.
 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSection *, RLMSectionedResultsChange *, NSError *))block __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the section changes.

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

 If an error occurs the block will be called with `nil` for the results
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the Realm on the background worker thread.

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
    RLMSection<Dog *> *section = sectionedResults[0]; // Objects already exist for Dog.
    self.token = [results addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes,
                                   NSError *error) {
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
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSection *, RLMSectionedResultsChange *, NSError *))block
                                         queue:(dispatch_queue_t)queue __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the section changes.

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

 If an error occurs the block will be called with `nil` for the results
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the Realm on the background worker thread.

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
    RLMSection<Dog *> *section = sectionedResults[0]; // Objects already exist for Dog.
    self.token = [results addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes,
                                   NSError *error) {
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

 @param block The block to be called whenever a change occurs.
 @param keyPaths The block will be called for changes occuring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSection *, RLMSectionedResultsChange *, NSError *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the section changes.

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

 If an error occurs the block will be called with `nil` for the results
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the Realm on the background worker thread.

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
    RLMSection<Dog *> *section = sectionedResults[0]; // Objects already exist for Dog.
    self.token = [results addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes,
                                   NSError *error) {
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
 @param keyPaths The block will be called for changes occuring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSection *, RLMSectionedResultsChange *, NSError *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths
                                         queue:(dispatch_queue_t)queue __attribute__((warn_unused_result));

@end

@interface RLMSectionedResults<RLMObjectType> : NSObject<NSFastEnumeration, RLMThreadConfined>
/// The total amount of sections in this collection.
@property (nonatomic, readonly, assign) NSUInteger count;
/// Returns the section at a given index.
- (RLMSection<RLMObjectType> *)objectAtIndexedSubscript:(NSUInteger)index;
/// Returns the section at a given index.
- (RLMSection<RLMObjectType> *)objectAtIndex:(NSUInteger)index;

/**
 Indicates if the underlying collection is frozen.

 Frozen collections are immutable and can be accessed from any thread.
 */
@property (nonatomic, readonly, getter = isFrozen) BOOL frozen;

/**
 Registers a block to be called each time the sectioned results collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which index paths in the sectioned results collection were added, removed or modified. If a
 write transaction did not modify any objects in the sectioned results collection,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 If an error occurs the block will be called with `nil` for the results
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the Realm on the background worker thread.

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
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes,
                                           NSError *error) {
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

 @param block The block to be called whenever a change occurs.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSectionedResults *, RLMSectionedResultsChange *, NSError *))block __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the sectioned results collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which index paths in the sectioned results collection were added, removed or modified. If a
 write transaction did not modify any objects in the sectioned results collection,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 If an error occurs the block will be called with `nil` for the results
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the Realm on the background worker thread.

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
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes,
                                           NSError *error) {
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
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSectionedResults *, RLMSectionedResultsChange *, NSError *))block
                                         queue:(dispatch_queue_t)queue __attribute__((warn_unused_result));
/**
 Registers a block to be called each time the sectioned results collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which index paths in the sectioned results collection were added, removed or modified. If a
 write transaction did not modify any objects in the sectioned results collection,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 If an error occurs the block will be called with `nil` for the results
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the Realm on the background worker thread.

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
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes,
                                           NSError *error) {
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

 @param block The block to be called whenever a change occurs.
 @param keyPaths The block will be called for changes occuring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSectionedResults *, RLMSectionedResultsChange *, NSError *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths __attribute__((warn_unused_result));

/**
 Registers a block to be called each time the sectioned results collection changes.

 The block will be asynchronously called with the initial sectioned results collection,
 and then called again after each write transaction which changes either any
 of the objects in the results, or which objects are in the results.

 The `change` parameter will be `nil` the first time the block is called.
 For each call after that, it will contain information about
 which index paths in the sectioned results collection were added, removed or modified. If a
 write transaction did not modify any objects in the sectioned results collection,
 the block is not called at all. See the `RLMSectionedResultsChange` documentation for
 information on how the changes are reported and an example of updating a
 `UITableView`.

 If an error occurs the block will be called with `nil` for the results
 parameter and a non-`nil` error. Currently the only errors that can occur are
 when opening the Realm on the background worker thread.

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
    self.token = [sectionedResults addNotificationBlock:^(RLMSectionedResults *sectionedResults, RLMSectionedResultsChange *changes,
                                           NSError *error) {
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
 @param keyPaths The block will be called for changes occuring on these keypaths. If no
 key paths are given, notifications are delivered for every property key path.

 @return A token which must be held for as long as you want updates to be delivered.
 */
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMSectionedResults *, RLMSectionedResultsChange *, NSError *))block
                                      keyPaths:(nullable NSArray<NSString *> *)keyPaths
                                         queue:(nullable dispatch_queue_t)queue __attribute__((warn_unused_result));

@end

NS_ASSUME_NONNULL_END
