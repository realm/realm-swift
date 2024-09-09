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

import Foundation
import Realm.Private

// MARK: MinMaxType

/**
 Types of properties which can be used with the minimum and maximum value APIs.

 - see: `min(ofProperty:)`, `max(ofProperty:)`
 */
@_marker public protocol MinMaxType {}
extension NSNumber: MinMaxType {}
extension Double: MinMaxType {}
extension Float: MinMaxType {}
extension Int: MinMaxType {}
extension Int8: MinMaxType {}
extension Int16: MinMaxType {}
extension Int32: MinMaxType {}
extension Int64: MinMaxType {}
extension Date: MinMaxType {}
extension NSDate: MinMaxType {}
extension Decimal128: MinMaxType {}
extension AnyRealmValue: MinMaxType {}
extension Optional: MinMaxType where Wrapped: MinMaxType {}

// MARK: AddableType

/**
 Types of properties which can be used with the sum and average value APIs.

 - see: `sum(ofProperty:)`, `average(ofProperty:)`
 */
@_marker public protocol AddableType {}
extension NSNumber: AddableType {}
extension Double: AddableType {}
extension Float: AddableType {}
extension Int: AddableType {}
extension Int8: AddableType {}
extension Int16: AddableType {}
extension Int32: AddableType {}
extension Int64: AddableType {}
extension Decimal128: AddableType {}
extension AnyRealmValue: AddableType {}
extension Optional: AddableType where Wrapped: AddableType {}

/**
 Types of properties which can be directly sorted or distincted.

 - see: `sum(ascending:)`, `distinct()`
 */
@_marker public protocol SortableType {}
extension AnyRealmValue: SortableType {}
extension Data: SortableType {}
extension Date: SortableType {}
extension Decimal128: SortableType {}
extension Double: SortableType {}
extension Float: SortableType {}
extension Int16: SortableType {}
extension Int32: SortableType {}
extension Int64: SortableType {}
extension Int8: SortableType {}
extension Int: SortableType {}
extension String: SortableType {}
extension Optional: SortableType where Wrapped: SortableType {}


/**
 Types which have properties that can be sorted or distincted on.
 */
@_marker public protocol KeypathSortable {}
extension ObjectBase: KeypathSortable {}
extension Projection: KeypathSortable {}

/**
 `Results` is an auto-updating container type in Realm returned from object queries.

 `Results` can be queried with the same predicates as `List<Element>`, and you can
 chain queries to further filter query results.

 `Results` always reflect the current state of the Realm on the current thread, including during write transactions on
 the current thread. The one exception to this is when using `for...in` enumeration, which will always enumerate over
 the objects which matched the query when the enumeration is begun, even if some of them are deleted or modified to be
 excluded by the filter during the enumeration.

 `Results` are lazily evaluated the first time they are accessed; they only run queries when the result of the query is
 requested. This means that chaining several temporary `Results` to sort and filter your data does not perform any
 unnecessary work processing the intermediate state.

 Once the results have been evaluated or a notification block has been added, the results are eagerly kept up-to-date,
 with the work done to keep them up-to-date done on a background thread whenever possible.

 Results instances cannot be directly instantiated.
 */
@frozen public struct Results<Element: RealmCollectionValue>: Equatable, RealmCollectionImpl {
    internal let collection: RLMCollection

    /// A human-readable description of the objects represented by the results.
    public var description: String {
        return RLMDescriptionWithMaxDepth("Results", collection, RLMDescriptionMaxDepth)
    }

    // MARK: Initializers

    internal init(collection: RLMCollection) {
        self.collection = collection
    }
    internal init(_ collection: RLMCollection) {
        self.collection = collection
    }

    // MARK: Object Retrieval
    /**
     Returns the object at the given `index`.
     - parameter index: The index.
     */
    public subscript(position: Int) -> Element {
        throwForNegativeIndex(position)
        return staticBridgeCast(fromObjectiveC: collection.object(at: UInt(position)))
    }

    // MARK: Equatable

    public static func == (lhs: Results<Element>, rhs: Results<Element>) -> Bool {
        lhs.collection.isEqual(rhs.collection)
    }

    /// :nodoc:
    public func makeIterator() -> RLMIterator<Element> {
        return RLMIterator(collection: collection)
    }

    // MARK: Flexible Sync

#if compiler(<6)
    /**
     Creates a SyncSubscription matching the Results' local query.
     After committing the subscription to the realm's local subscription set, the method
     will wait for downloads according to `WaitForSyncMode`.

     ### Unnamed subscriptions ###
     If `.subscribe()` is called without a name whose query matches an unnamed subscription, another subscription is not created.

     If `.subscribe()` is called without a name whose query matches a named subscription, an additional  unnamed subscription is created.
     ### Named Subscriptions ###
     If `.subscribe()` is called with a name whose query matches an unnamed subscription, an additional named subscription is created.
     ### Existing name and query ###
     If `.subscribe()` is called with a name whose name is taken on a different query, the old subscription is updated with the new query.

     If `.subscribe()` is called with a name that's in already in use by an identical query, no new subscription is created.


     - Note: This method will wait for all data to be downloaded before returning when `WaitForSyncMode.always` and `.onCreation` (when the subscription is first created) is used. This requires an internet connection if no timeout is set.

     - Note: This method opens a update transaction that creates or updates a subscription.
     It's advised to *not* loop over this method in order to create multiple subscriptions.
     This could create a performance bottleneck by opening multiple unnecessary update transactions.
     To create multiple subscriptions at once use `SyncSubscription.update`.

     - parameter name: The name applied to the subscription
     - parameter waitForSync: ``WaitForSyncMode`` Determines the download behavior for the subscription. Defaults to `.onCreation`.
     - parameter timeout: An optional client timeout. The client will cancel waiting for subscription downloads after this time has elapsed. Reaching this timeout doesn't imply a server error.
     - returns: Returns `self`.

     - warning: This function is only supported for main thread and
                actor-isolated Realms.
     - warning: This API is currently in `Preview` and may be subject to changes in the future.
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @_unsafeInheritExecutor
    public func subscribe(name: String? = nil, waitForSync: WaitForSyncMode = .onCreation, timeout: TimeInterval? = nil) async throws -> Results<Element> {
        guard let actor = realm?.rlmRealm.actor as? Actor else {
            fatalError("`subscribe` can only be called on main thread or actor-isolated Realms")
        }

        var rlmResults = ObjectiveCSupport.convert(object: self)
        let scheduler = await RLMScheduler.actor(actor, invoke: actor.invoke, verify: actor.verifier())
        rlmResults = try await rlmResults.subscribe(withName: name, waitForSync: waitForSync, confinedTo: scheduler, timeout: timeout ?? 0)
        return self
    }
#else
    /**
     Creates a SyncSubscription matching the Results' local query.
     After committing the subscription to the realm's local subscription set, the method
     will wait for downloads according to `WaitForSyncMode`.

     ### Unnamed subscriptions ###
     If `.subscribe()` is called without a name whose query matches an unnamed subscription, another subscription is not created.

     If `.subscribe()` is called without a name whose query matches a named subscription, an additional  unnamed subscription is created.
     ### Named Subscriptions ###
     If `.subscribe()` is called with a name whose query matches an unnamed subscription, an additional named subscription is created.
     ### Existing name and query ###
     If `.subscribe()` is called with a name whose name is taken on a different query, the old subscription is updated with the new query.

     If `.subscribe()` is called with a name that's in already in use by an identical query, no new subscription is created.


     - Note: This method will wait for all data to be downloaded before returning when `WaitForSyncMode.always` and `.onCreation` (when the subscription is first created) is used. This requires an internet connection if no timeout is set.

     - Note: This method opens a update transaction that creates or updates a subscription.
     It's advised to *not* loop over this method in order to create multiple subscriptions.
     This could create a performance bottleneck by opening multiple unnecessary update transactions.
     To create multiple subscriptions at once use `SyncSubscription.update`.

     - parameter name: The name applied to the subscription
     - parameter waitForSync: ``WaitForSyncMode`` Determines the download behavior for the subscription. Defaults to `.onCreation`.
     - parameter timeout: An optional client timeout. The client will cancel waiting for subscription downloads after this time has elapsed. Reaching this timeout doesn't imply a server error.
     - returns: Returns `self`.

     - warning: This function is only supported for main thread and
                actor-isolated Realms.
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func subscribe(
        name: String? = nil,
        waitForSync: WaitForSyncMode = .onCreation,
        timeout: TimeInterval? = nil,
        _isolation: isolated any Actor = #isolation
    ) async throws -> Results<Element> {
        guard let actor = realm?.rlmRealm.actor as? Actor else {
            fatalError("`subscribe` can only be called on main thread or actor-isolated Realms")
        }

        let rlmResults = ObjectiveCSupport.convert(object: self)
        let scheduler = await RLMScheduler.actor(actor, invoke: actor.invoke, verify: actor.verifier())
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            rlmResults.subscribe(withName: name, waitForSync: waitForSync, confinedTo: scheduler, timeout: timeout ?? 0) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        return self
    }
#endif

    /**
     Removes a SyncSubscription matching the Results' local filter.

     The method returns after committing the subscription removal to the realm's
     local subscription set. Calling this method will not wait for objects to
     be removed from the realm.

     In order for a named subscription to be removed, the Results
     must have previously created the subscription. For example:
     ```
     let results1 = try await realm.objects(Dog.self).where { $0.age > 1 }.subscribe(name: "adults")
     let results2 = try await realm.objects(Dog.self).where { $0.age > 1 }.subscribe(name: "overOne")
     let results3 = try await realm.objects(Dog.self).where { $0.age > 1 }.subscribe()
     // This will unsubscribe from the subscription named "overOne". The "adults" and unnamed
     // subscription still remain.
     results2.unsubscribe()
     ```

     - Note: This method opens an update transaction that removes a subscription.
     It is advised to *not* use this method to batch multiple subscription changes
     to the server.
     To unsubscribe multiple subscriptions at once use `SyncSubscription.update`.

     - warning: Calling unsubscribe on a Results does not remove the local filter from the `Results`. After calling unsubscribe,
     Results may still contain objects because other subscriptions may exist in the realm's subscription set.
     - warning: This API is currently in `Preview` and may be subject to changes in the future.
     */
    public func unsubscribe() {
        let rlmResults = ObjectiveCSupport.convert(object: self)
        rlmResults.unsubscribe()
    }
}

extension Results: Encodable where Element: Encodable {}
