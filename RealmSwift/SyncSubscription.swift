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

/// An error describing the error from the server after a write transaction to the subscription set.
enum SyncSubscriptionError: Error {
    case error(message: String)
}

/// An enum representing different states for the Subscription Set.
@frozen public enum SyncSubscriptionState {
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
}

public protocol _SyncSubscription {
    var rlmSyncSubscription: RLMSyncSubscription { get }
}

/// A protocol which defines a Subscription for using in a Flexible Sync transactions.
///
/// This is used to define a type-erasing wrapper.
public protocol SyncSubscription: _SyncSubscription {
    /// Identifier of the subscription.
    var id: ObjectId { get }

    /// Name of the subscription. If not specified it will return nil.
    var name: String? { get }

    /// When the subscription was created. Recorded automatically.
    var createdAt: Date { get }

    /// When the subscription was last updated. Recorded automatically.
    var updatedAt: Date { get }

    /**
     Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
     from the server when committed.

     - warning: This method may only be called during a write transaction.

     - parameter to: A query builder that produces a subscription which can used to modify the query.
     */
    func update<T: _RealmSchemaDiscoverable>(_ to: () -> (QuerySubscription<T>))
}

internal protocol _AnySyncSubscriptionBox {
    /// `_SyncSubscription` requirements.
    var _id: ObjectId { get }
    var _name: String? { get }
    var _createdAt: Date { get }
    var _updatedAt: Date { get }
    func _update<T: _RealmSchemaDiscoverable>(_ to: () -> (QuerySubscription<T>))

    /// The underlying base value, type-erased to `Any`.
    var _typeErasedBase: Any { get }
    var _rlmSyncSubscription: RLMSyncSubscription { get }

    /// Returns the underlying value unboxed to the given type, if possible.
    func _unboxed<U: SyncSubscription>(to type: U.Type) -> U?
}

/// A type-erasing  wrapper over any `ISyncSubscription` conforming object.
///
/// An `AnySyncSubscription` instance forwards its operations to a base struct, hiding
/// the specifics of the underlying type which allow us to make operations over an array
/// of `AnySyncSubscriptions`.
public struct AnySyncSubscription: SyncSubscription {

    internal var _box: _AnySyncSubscriptionBox

    internal init(_box: _AnySyncSubscriptionBox) {
        self._box = _box
    }

    /// Creates a type-erased derivative from the given derivative.
    public init<T: SyncSubscription>(_ base: T) {
        self._box = _AnySyncSubscription<T>(base)
    }

    /// The underlying base value.
    public var base: Any {
        _box._typeErasedBase
    }

    public var rlmSyncSubscription: RLMSyncSubscription {
        _box._rlmSyncSubscription
    }

    /// Identifier of the subscription.
    public var id: ObjectId {
        _box._id
    }

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    public var name: String? {
        _box._name
    }

    /// When the subscription was created. Recorded automatically.
    public var createdAt: Date {
        _box._createdAt
    }

    /// When the subscription was last updated. Recorded automatically.
    public var updatedAt: Date {
        _box._updatedAt
    }

    /**
     Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
     from the server when committed.

     - warning: This method may only be called during a write transaction.

     - parameter to: A query builder that produces a subscription which can used to modify the query.
     */
    public func update<T: _RealmSchemaDiscoverable>(_ to: () -> (QuerySubscription<T>)) {
        _box._update(to)
    }
}

private final class _AnySyncSubscription<T: SyncSubscription>: _AnySyncSubscriptionBox {

    /// The underlying base value.
    var _base: T

    init(_ base: T) {
        self._base = base
    }

    /// The underlying base value, type-erased to `Any`.
    var _typeErasedBase: Any {
        return _base
    }

    var _rlmSyncSubscription: RLMSyncSubscription {
        return _base.rlmSyncSubscription
    }

    func _unboxed<U: SyncSubscription>(to type: U.Type) -> U? {
        return (self as? _AnySyncSubscription<U>)?._base
    }

    var _id: ObjectId {
        _base.id
    }

    var _name: String? {
        _base.name
    }

    var _createdAt: Date {
        _base.createdAt
    }

    var _updatedAt: Date {
        _base.updatedAt
    }

    func _update<T: _RealmSchemaDiscoverable>(_ to: () -> (QuerySubscription<T>)) {
        _base.update(to)
    }
}

/**
 `QuerySyncSubscription` is  used to define a Flexible Sync's subscription, which
 can be added/remove or updated within a write subscription transaction.
 */
@frozen public struct QuerySyncSubscription: SyncSubscription {

    // MARK: Initializers
    fileprivate let _rlmSyncSubscription: RLMSyncSubscription

    fileprivate init(_ rlmSyncSubscription: RLMSyncSubscription) {
        self._rlmSyncSubscription = rlmSyncSubscription
    }

    public var rlmSyncSubscription: RLMSyncSubscription {
        _rlmSyncSubscription
    }

    /// Identifier of the subscription.
    public var id: ObjectId {
        try! ObjectId(string: rlmSyncSubscription.identifier.stringValue)
    }

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    public var name: String? {
        rlmSyncSubscription.name
    }

    /// When the subscription was created. Recorded automatically.
    public var createdAt: Date {
        rlmSyncSubscription.createdAt
    }

    /// When the subscription was last updated. Recorded automatically.
    public var updatedAt: Date {
        rlmSyncSubscription.updatedAt
    }

    /**
     Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
     from the server when committed.

     - warning: This method may only be called during a write subscription block.

     - parameter to: A query builder that produces a subscription which can used to modify the query.
     */
    public func update<T: _RealmSchemaDiscoverable>(_ to: () -> (QuerySubscription<T>)) {
        let subscription = to()
        rlmSyncSubscription.update(withClassName: subscription.className,
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

@resultBuilder public struct QueryBuilder {
    public static func buildBlock<T: _RealmSchemaDiscoverable>(_ components: QuerySubscription<T>...) -> [QuerySubscription<T>] {
        return components
    }
}

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
    public func write(_ block: (() -> Void)) throws {
        try rlmSyncSubscriptionSet.write(block)
    }

    /**
     Notifies state changes for the subscription set.
     During a write batch transaction to the server, it will return complete when the server is on
     "steady-state" synchronization.
     */
    public func observe(_ block: @escaping (SyncSubscriptionState) -> Void) {
        rlmSyncSubscriptionSet.observe { state in
            block(mapState(state))
        }
    }

    private func mapState(_ state: RLMSyncSubscriptionState) -> SyncSubscriptionState {
        switch state {
        case .pending:
            return .pending
        case .complete:
            return .complete
        case .superceded:
            return .superceded
        case .error:
            return .error(SyncSubscriptionError.error(message: rlmSyncSubscriptionSet.error?.localizedDescription ?? ""))
        @unknown default:
            fatalError()
        }
    }

    /**
     Returns a subscription by the specified name.

     - parameter named: The name of the subscription searching for.
     - returns: A subscription for the given name.
     */
    public func first(named: String) -> AnySyncSubscription? {
        let rlmSubscription = rlmSyncSubscriptionSet.subscription(withName: named)
        guard let rlmSubscription = rlmSubscription else {
            return nil
        }
        let anySubscription = AnySyncSubscription(QuerySyncSubscription(rlmSubscription))
        return anySubscription
    }

    /**
     Returns a subscription by the specified query.

     - parameter where: A query builder that produces a subscription which can be used to search
                        the subscription by query and/or name.
     - returns: A query builder that produces a subscription which can used to search for the subscription.
     */
    public func first<T: _RealmSchemaDiscoverable>(`where`: () -> (QuerySubscription<T>)) -> AnySyncSubscription? {
        let subscription = `where`()
        let rlmSubscription = rlmSyncSubscriptionSet.subscription(withClassName: subscription.className,
                                                                  predicate: subscription.predicate)
        guard let rlmSubscription = rlmSubscription else {
            return nil
        }
        let anySubscription = AnySyncSubscription(QuerySyncSubscription(rlmSubscription))
        return anySubscription
    }

    /**
     Append a subscription to the subscription set.

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

    /**
     Removes a subscription from the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter subscription: The subscription to be removed from the subscription set.
     */
    public func remove(_ subscription: AnySyncSubscription) {
        rlmSyncSubscriptionSet.remove(subscription.rlmSyncSubscription)
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
    public subscript(position: Int) -> AnySyncSubscription? {
        throwForNegativeIndex(position)
        return rlmSyncSubscriptionSet.object(at: UInt(position)).map { AnySyncSubscription(QuerySyncSubscription($0)) }
    }

    /// Returns the first object in the SyncSubscription list, or `nil` if the subscriptions are empty.
    public var first: AnySyncSubscription? {
        return rlmSyncSubscriptionSet.firstObject().map { AnySyncSubscription(QuerySyncSubscription($0)) }
    }

    /// Returns the last object in the SyncSubscription list, or `nil` if the subscriptions are empty.
    public var last: AnySyncSubscription? {
        return rlmSyncSubscriptionSet.lastObject().map { AnySyncSubscription(QuerySyncSubscription($0)) }
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
    internal func write(_ block: (() throws -> Void)) async throws {
        fatalError()
    }

    /**
     Notifies state changes for the subscription set.
     During a write batch transaction to the server, it will return complete when the server is on
     "steady-state" synchronization.
     This will throw an error if someone updates the subscription set while on a write transaction.
     */
    internal var state: AsyncStream<SyncSubscriptionState> {
        fatalError()
    }
}
#endif // swift(>=5.5)
