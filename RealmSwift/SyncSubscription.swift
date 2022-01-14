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

import Foundation
import Realm
import Realm.Private

/// An enum representing different states for the Subscription Set.
@frozen public enum SyncSubscriptionState: Equatable {
    /// The subscription is complete and the server has sent all the data that matched the subscription
    /// queries at the time the subscription set was updated. The server is now in a steady-state
    /// synchronization mode where it will stream update as they come.
    case complete
    /// The subscription encountered an error and synchronization is paused for this Realm. You can
    /// still use the current subscription set to write a subscription.
    case error(Error)
    /// The subscription is persisted locally but not yet processed by the server, which means
    /// the server hasn't yet returned all the data that matched the updated subscription queries.
    case pending
    /// The subscription set has been super-ceded by an updated one, this typically means that
    /// someone is trying to write a subscription on a different instance of the subscription set.
    /// You should not use a super-ceded subscription set and instead obtain a new instance of
    /// the subscription set to write a subscription.
    case superceded

    public static func ==(lhs: SyncSubscriptionState, rhs: SyncSubscriptionState) -> Bool {
        switch (lhs, rhs) {
        case (.complete, .complete): fallthrough
        case (.pending, .pending): fallthrough
        case (.superceded, .superceded):
            return true
        case (.error(let error), .error(let error2)):
            return error == error2
        default:
            return false
        }
    }
}

/**
 `SyncSubscription` is  used to define a Flexible Sync subscription obtained from querying a
 subscription set, which can be used to read or remove/update a committed subscription.
 */
@frozen public struct SyncSubscription {

    // MARK: Initializers
    fileprivate let _rlmSyncSubscription: RLMSyncSubscription

    fileprivate init(_ rlmSyncSubscription: RLMSyncSubscription) {
        self._rlmSyncSubscription = rlmSyncSubscription
    }

    /// Identifier of the subscription.
    public var id: ObjectId {
        try! ObjectId(string: _rlmSyncSubscription.identifier.stringValue)
    }

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    public var name: String? {
        _rlmSyncSubscription.name
    }

    /// When the subscription was created. Recorded automatically.
    public var createdAt: Date {
        _rlmSyncSubscription.createdAt
    }

    /// When the subscription was last updated. Recorded automatically.
    public var updatedAt: Date {
        _rlmSyncSubscription.updatedAt
    }

    /**
     Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
     from the server when committed.

     - warning: This method may only be called during a write subscription block.

     - parameter to: A query builder that produces a subscription which can used to modify the query.
     */
    public func update<T: _RealmSchemaDiscoverable>(_ to: () -> (QuerySubscription<T>)) {
        let subscription = to()
        _rlmSyncSubscription.update(withClassName: subscription.className,
                                    predicate: subscription.predicate)
    }
}

/**
 `SubscriptionQuery` is  used to define an named/unnamed query subscription query, which
 can be added/remove or updated within a write subscription transaction.
 */
@frozen public struct QuerySubscription<ObjectType: _RealmSchemaDiscoverable> {
    // MARK: Internal
    fileprivate let name: String?
    private let query: QueryFunction

    fileprivate var className: String {
        return "\(ObjectType.self)"
    }

    fileprivate var predicate: NSPredicate {
        return query(Query()).predicate
    }

    public typealias QueryFunction = (Query<ObjectType>) -> Query<Bool>
    public init(name: String? = nil, query: @escaping QueryFunction) {
        self.name = name
        self.query = query
    }
}

#if swift(>=5.5)
@resultBuilder public struct QueryBuilder {
    public static func buildBlock<T: _RealmSchemaDiscoverable>(_ components: QuerySubscription<T>...) -> [QuerySubscription<T>] {
        return components
    }
}
#endif // swift(>=5.5)

/**
 `SyncSubscriptionSet` is  a collection of `SyncSubscription`s. This is the entry point
 for adding and removing `SyncSubscription`s.
 */
@frozen public struct SyncSubscriptionSet {

    // MARK: Internal

    internal let rlmSyncSubscriptionSet: RLMSyncSubscriptionSet

    // MARK: Initializers

    internal init(_ rlmSyncSubscriptionSet: RLMSyncSubscriptionSet) {
        self.rlmSyncSubscriptionSet = rlmSyncSubscriptionSet
    }

    /// The number of subscriptions in the subscription set.
    public var count: Int { return Int(rlmSyncSubscriptionSet.count) }

    /**
     Synchronously performs any transactions (add/remove/update) to the subscription set within the block,
     this will not wait for the server to acknowledge and see all the data associated with this collection of subscriptions,
     and will return after committing the subscription transactions.

     - parameter block: The block containing the subscriptions transactions to perform.

     - throws: An `NSError` if the transaction could not be completed successfully.
               If `block` throws, the function throws the propagated `ErrorType` instead.
     */
    public func write(_ block: (() -> Void), onComplete: ((Error?) -> Void)? = nil) {
        rlmSyncSubscriptionSet.write(block, onComplete: { error in
            onComplete?(error)
        })
    }

    public var state: SyncSubscriptionState {
        switch rlmSyncSubscriptionSet.state {
        case .pending:
            return .pending
        case .complete:
            return .complete
        case .superseded:
            return .superceded
        case .error:
            return .error(rlmSyncSubscriptionSet.error!)
        @unknown default:
            fatalError()
        }
    }

    /**
     Returns a subscription by the specified name.

     - parameter named: The name of the subscription searching for.
     - returns: A subscription for the given name.
     */
    public func first(named: String) -> SyncSubscription? {
        guard let rlmSubscription = rlmSyncSubscriptionSet.subscription(withName: named) else {
            return nil
        }
        return SyncSubscription(rlmSubscription)
    }

    /**
     Returns a subscription by the specified query.

     - parameter where: A query builder that produces a subscription which can be used to search
                        the subscription by query and/or name.
     - returns: A query builder that produces a subscription which can used to search for the subscription.
     */
    public func first<T: _RealmSchemaDiscoverable>(`where`: () -> (QuerySubscription<T>)) -> SyncSubscription? {
        let subscription = `where`()
        guard let rlmSubscription =  rlmSyncSubscriptionSet.subscription(withClassName: subscription.className,
                                                                         predicate: subscription.predicate) else {
            return nil
        }
        return SyncSubscription(rlmSubscription)
    }

    #if swift(>=5.5)
    /**
     Appends a subscription to the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter to: A query builder that produces a subscription which can be added to the
     subscription set.
     */
    public func `append`<T: _RealmSchemaDiscoverable>(@QueryBuilder _ subscriptions: () -> ([QuerySubscription<T>])) {
        let appendableSubscriptions = subscriptions()
        appendableSubscriptions.forEach { subscription in
            rlmSyncSubscriptionSet.addSubscription(withClassName: subscription.className,
                                                   subscriptionName: subscription.name,
                                                   predicate: subscription.predicate)
        }
    }

    /**
     Removes a subscription with the specified query for the object class from the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter to: A query builder that produces a subscription which will be removed from the
     subscription set.
     */
    public func remove<T: _RealmSchemaDiscoverable>(@QueryBuilder _ subscriptions: () -> ([QuerySubscription<T>])) {
        let removableSubscriptions = subscriptions()
        removableSubscriptions.forEach { subscription in
            rlmSyncSubscriptionSet.removeSubscription(withClassName: subscription.className,
                                                      predicate: subscription.predicate)
        }
    }
    #else
    /**
     Appends a subscription to the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter to: The subscription which can be added to the subscription set.
     */
    public func `append`<T: _RealmSchemaDiscoverable>(_ subscription: () -> (QuerySubscription<T>)) {
        let appendableSubscription = subscription()
        rlmSyncSubscriptionSet.addSubscription(withClassName: appendableSubscription.className,
                                               subscriptionName: appendableSubscription.name,
                                               predicate: appendableSubscription.predicate)
    }

    /**
     Removes a subscription with the specified query for the object class from the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter to: The subscription which will be removed from the subscription set.
     */
    public func remove<T: _RealmSchemaDiscoverable>(_ subscription: () -> (QuerySubscription<T>)) {
        let removableSubscription = subscription()
        rlmSyncSubscriptionSet.removeSubscription(withClassName: removableSubscription.className,
                                                  predicate: removableSubscription.predicate)
    }
    #endif // swift(>=5.5)

    /**
     Removes a subscription from the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter subscription: The subscription to be removed from the subscription set.
     */
    public func remove(_ subscription: SyncSubscription) {
        rlmSyncSubscriptionSet.remove(subscription._rlmSyncSubscription)
    }

    /**
     Removes a subscription with the specified name from the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter named: The name of the subscription to be removed from the subscription set.
     */
    public func remove(named: String) {
        rlmSyncSubscriptionSet.removeSubscription(withName: named)
    }

    /**
     Removes all subscriptions from the subscription set.

     - warning: This method may only be called during a write subscription block.
     - warning: Removing all subscriptions will result in an error if no new subscription is added. Server should
              acknowledge at least one subscription.
     */
    public func removeAll() {
        rlmSyncSubscriptionSet.removeAllSubscriptions()
    }

    /**
     Removes zero or none subscriptions of the given type from the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter type: The type of the objects to be removed.
     */
    public func removeAll<T: Object>(ofType type: T.Type) {
        rlmSyncSubscriptionSet.removeAllSubscriptions(withClassName: type.className())
    }

    // MARK: Subscription Retrieval

    /**
     Returns the subscription at the given `index`.

     - parameter index: The index.
     */
    public subscript(position: Int) -> SyncSubscription? {
        throwForNegativeIndex(position)
        return rlmSyncSubscriptionSet.object(at: UInt(position)).map { SyncSubscription($0) }
    }

    /// Returns the first object in the SyncSubscription list, or `nil` if the subscriptions are empty.
    public var first: SyncSubscription? {
        return rlmSyncSubscriptionSet.firstObject().map { SyncSubscription($0) }
    }

    /// Returns the last object in the SyncSubscription list, or `nil` if the subscriptions are empty.
    public var last: SyncSubscription? {
        return rlmSyncSubscriptionSet.lastObject().map { SyncSubscription($0) }
    }
}

extension SyncSubscriptionSet: Sequence {
    // MARK: Sequence Support

    /// Returns a `SyncSubscriptionSetIterator` that yields successive elements in the subscription collection.
    public func makeIterator() -> SyncSubscriptionSetIterator {
        return SyncSubscriptionSetIterator(rlmSyncSubscriptionSet)
    }
}

@frozen public struct SyncSubscriptionSetIterator: IteratorProtocol {
    private let rlmSubscriptionSet: RLMSyncSubscriptionSet
    private var index: Int = -1

    init(_ rlmSubscriptionSet: RLMSyncSubscriptionSet) {
        self.rlmSubscriptionSet = rlmSubscriptionSet
    }

    private func nextIndex(for index: Int?) -> Int? {
        if let index = index, index < self.rlmSubscriptionSet.count - 1 {
            return index + 1
        }
        return nil
    }

    mutating public func next() -> RLMSyncSubscription? {
        if let index = self.nextIndex(for: self.index) {
            self.index = index
            return rlmSubscriptionSet.object(at: UInt(index))
        }
        return nil
    }
}

#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, tvOS 15.0, iOS 15.0, watchOS 8.0, *)
extension SyncSubscriptionSet {
    /**
     Asynchronously creates and commit a write transaction and updates the subscription set,
     this will not wait for the server to acknowledge and see all the data associated with this
     collection of subscription.

     - parameter block: The block containing the subscriptions transactions to perform.

     - throws: An `NSError` if the transaction could not be completed successfully.
               If `block` throws, the function throws the propagated `ErrorType` instead.
     */
    public func write(_ block: (() -> Void)) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            rlmSyncSubscriptionSet.write(block) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
#endif // swift(>=5.5)
