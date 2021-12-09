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

/// A protocol which defines a Subscription for using in a Flexible Sync transactions.
///
/// This is used to define a type-erasing wrapper.
protocol _SyncSubscription {
    /// Identifier of the subscription.
    var id: ObjectId { get }

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    var name: String { get }

    /// When the subscription was created. Recorded automatically.
    var createdAt: Date { get }

    /// When the subscription was created. Recorded automatically.
    var updatedAt: Date { get }

    #if swift(>=5.4)
    /**
     Updates a Flexible Sync's subscription query and/or name.

     - warning: This method may only be called during a write transaction.

     - parameter to: A query builder that produces a subscription which can be used to
                     update the subscription query and/or name.
     */
    func update<T>(_ to: () -> (SyncSubscription<T>)) throws where T: _RealmSchemaDiscoverable
    #endif // swift(>=5.4)
}

private class _AnySyncSubscriptionBase {
    var id: ObjectId { fatalError() }
    var name: String { fatalError() }
    var createdAt: Date { fatalError() }
    var updatedAt: Date { fatalError() }
    func update<T>(_ to: () -> (SyncSubscription<T>)) throws where T: _RealmSchemaDiscoverable { fatalError() }
}

// TODO: Add when public `@frozen`
// TODO: Change to public
/// An enum representing different states for the Subscription Set.
public enum SyncSubscriptionState {
    /// The subscription is complete and the server is in "steady-state" synchronization.
    case complete
    /// The subscription encountered an error.
    case error(Error)
    /// The subscription is persisted locally but not yet processed by the server,
    /// It may or may not have been seen by the server.
    case pending
}

// TODO: Change to public
/// A type-erasing  wrapper over any `ISyncSubscription` conforming object.
///
/// An `AnySyncSubscription` instance forwards its operations to a base struct, hiding
/// the specifics of the underlying type which allow us to make operations over an array
/// of `AnySyncSubscriptions`.
public struct AnySyncSubscription: _SyncSubscription {
    var id: ObjectId {
        _base.id
    }

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    public var name: String {
        _base.name
    }

    /// When the subscription was created. Recorded automatically.
    internal var createdAt: Date {
        _base.createdAt
    }

    /// When the subscription was last updated. Recorded automatically.
    public var updatedAt: Date {
        _base.updatedAt
    }

    #if swift(>=5.4)
    /**
     Updates a Flexible Sync's subscription query and/or name.

     - warning: This method may only be called during a write transaction.

     - parameter to: A query builder that produces a subscription which can be used to
                     update the subscription query and/or name.
     */
    public func update<T>(_ to: () -> (SyncSubscription<T>)) throws where T: _RealmSchemaDiscoverable {
        try _base.update(to)
    }
    #endif // swift(>=5.4)

    /// Creates a type-erased  `AnySyncSubscription` that wraps any `ISyncSubscription`
    /// conforming object.
    /// The type of the objects contained in the collection.
    fileprivate let _base: _AnySyncSubscriptionBase

    fileprivate init(_ base: _AnySyncSubscriptionBase) {
        self._base = base
    }
}

private final class _AnySyncSubscription: _AnySyncSubscriptionBase {
    /// Id of the subscription, which can be used to identify a subscription
    override var id: ObjectId {
        try! ObjectId(string: rlmSyncSubscription.identifier.stringValue)
    }

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    override var name: String {
        rlmSyncSubscription.name
    }

    /// When the subscription was created. Recorded automatically.
    override var createdAt: Date {
        rlmSyncSubscription.createdAt
    }

    /// When the subscription was last updated. Recorded automatically.
    override var updatedAt: Date {
        rlmSyncSubscription.updatedAt
    }

    // MARK: Internal

    fileprivate let rlmSyncSubscription: RLMSyncSubscription

    // MARK: Initializers

    fileprivate init(_ rlmSyncSubscription: RLMSyncSubscription) {
        self.rlmSyncSubscription = rlmSyncSubscription
    }

    #if swift(>=5.4)
    /**
     Updates a Flexible Sync's subscription query and/or name.

     - warning: This method may only be called during a write subscription block.

     - parameter to: A query builder that produces a subscription which can be used to
                     update the subscription query and/or name.
     */
//    override func update<T>(_ to: () -> (SyncSubscription<T>)) throws where T: _RealmSchemaDiscoverable {
//        fatalError()
//    }
    #endif // swift(>=5.4)
}

public protocol _TestSyncSubscription {
    var name: String? { get }
    var className: String { get }
    var predicate: NSPredicate { get }
}

internal protocol _AnySyncSubscriptionBox {
    /// The underlying base value, type-erased to `Any`.
    var _typeErasedBase: Any { get }

    var name: String? { get }

    var className: String { get }

    var predicate: NSPredicate { get }
}

internal struct _ConcreteSyncSubscriptionBox<T: _TestSyncSubscription>: _AnySyncSubscriptionBox {
    /// The underlying base value.
    var _base: T

    init(_ base: T) {
        self._base = base
    }

    /// The underlying base value, type-erased to `Any`.
    var _typeErasedBase: Any {
        return _base
    }

    public var name: String? { self._base.name }

    public var className: String { self._base.className }

    public var predicate: NSPredicate { self._base.predicate }
}

public struct _AnyTestSyncSubscription: _TestSyncSubscription {

    internal var _box: _AnySyncSubscriptionBox

    public init<T: _TestSyncSubscription>(_ base: T) {
        self._box = _ConcreteSyncSubscriptionBox<T>(base)
    }

    /// The underlying base value.
    public var base: Any {
        return _box._typeErasedBase
    }

    public var name: String? {
        return _box.name
    }

    public var className: String {
        return _box.className
    }

    public var predicate: NSPredicate {
        return _box.predicate
    }
}

/**
 `SyncSubscription` is  used to define a Flexible Sync's subscription, which
 can be added/remove or updated within a write subscription transaction.
 */
@frozen public struct SyncSubscription<ObjectType: _RealmSchemaDiscoverable>: _TestSyncSubscription {
    public typealias QueryFunction = (Query<ObjectType>) -> Query<ObjectType>
    public let name: String?
    public let query: QueryFunction
    public init(name: String? = nil, query: @escaping QueryFunction) {
        self.name = name
        self.query = query
    }

    public var className: String {
        return "\(ObjectType.self)"
    }

    public var predicate: NSPredicate {
        return query(Query()).predicate
    }
}

#if swift(>=5.4)
@resultBuilder public struct QueryBuilder {
    public static func buildBlock<T: _RealmSchemaDiscoverable>(_ components: SyncSubscription<T>...) -> [_AnyTestSyncSubscription] {
        return components.map { _AnyTestSyncSubscription($0) }
    }
}
#endif // swift(>=5.4)

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
     Create and commit a write transaction and updates the subscription set,
     this will not wait for the server to acknowledge and see all the data associated with this
     collection of subscription.

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
     This will throw an error if someone updates the subscription set while on a write transaction.
     */
    public func observe(_ block: @escaping (SyncSubscriptionState) -> Void) {
        fatalError()
    }

    #if swift(>=5.4)
    /**
     Returns an `AnySyncSubscription` which encapsulates the resulted subscription from
     the search.

     - parameter named: The name of the subscription searching for.
     - returns: A `AnySubscription` struct encapsulating the subscription we are searching for.
     */
    public func first(named: String) -> AnySyncSubscription? {
        let rlmSubscription = rlmSyncSubscriptionSet.subscription(withName: named)
        guard let rlmSubscription = rlmSubscription else {
            return nil
        }
        let anySubscription = AnySyncSubscription(_AnySyncSubscription(rlmSubscription))
        return anySubscription
    }
    
    /**
     Returns an `AnySyncSubscription` which encapsulates the resulted subscription from
     the search.

     - parameter where: A query builder that produces a subscription which can be used to search
                        the subscription by query and/or name.
     - returns: An `AnySyncSubscription` struct encapsulating the subscription we are searching for.
     */
    public func first<T: _RealmSchemaDiscoverable>(`where`: () -> (SyncSubscription<T>)) -> AnySyncSubscription? {
        let subscription = `where`()
        let rlmSubscription = rlmSyncSubscriptionSet.subscription(withClassName: subscription.className,
                                                                  predicate: subscription.predicate)
        guard let rlmSubscription = rlmSubscription else {
            return nil
        }
        let anySubscription = AnySyncSubscription(_AnySyncSubscription(rlmSubscription))
        return anySubscription
    }

    /**
     Append an `AnySyncSubscription` to the subscription set which will be sent to the server when
     committed at the end of a write subscription block.

     - warning: This method may only be called during a write subscription block.

     - parameter to: A query builder that produces a subscription which can be added to the
     subscription set.
     */
    public func `append`(@QueryBuilder _ subscriptions: () -> ([_AnyTestSyncSubscription])) {
        let appendableSubscriptions = subscriptions()
        appendableSubscriptions.forEach { subscription in
            rlmSyncSubscriptionSet.addSubscription(withClassName: subscription.className,
                                                   subscriptionName: subscription.name,
                                                   predicate: subscription.predicate)
        }
    }

    /**
     Remove an `AnySyncSubscription`to the subscription set which will be removed from the server when
     committed at the end of a write subscription block.

     - warning: This method may only be called during a write subscription block.

     - parameter to: A query builder that produces a subscription which will be removed from the
     subscription set.
     */
    public func remove(@QueryBuilder _ subscriptions: () -> ([_AnyTestSyncSubscription])) {
        let removableSubscriptions = subscriptions()
        removableSubscriptions.forEach { subscription in
            rlmSyncSubscriptionSet.removeSubscription(withClassName: subscription.className,
                                                      predicate: subscription.predicate)
        }
    }
    #endif // swift(>=5.4)

    /**
     Removes an `AnySyncSubscription`to the subscription set which will be removed from the server when
     committed at the end of a write subscription block.

     - warning: This method may only be called during a write subscription block.
ion
     - parameter subscription: The subscription to be removed from the subscription set.
     */
    public func remove(_ subscription: AnySyncSubscription) {
//        rlmSyncSubscriptionSet.remove(subscription.)
//        fatalError()
    }

    /**
     Removes an `AnySyncSubscription`to the subscription set which will be removed from the server when
     committed at the end of a write subscription block.

     - warning: This method may only be called during a write subscription block.

     - parameter named: The name of the subscription to be removed from the subscription set.
     */
    public func remove(named: String) {
        rlmSyncSubscriptionSet.removeSubscription(withName: named)
    }

    /**
     Removes all subscriptions from the subscription set.

     - warning: This method may only be called during a write subscription block.
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
}

// TODO: Change to public
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
