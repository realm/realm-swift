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

/// A protocol which defines a Subscription for using in a Flexible Sync transactions.
///
/// This is used to define a type-erasing wrapper.
protocol _SyncSubscription {
    /// When the subscription was created. Recorded automatically.
    var createdAt: Date { get }

    /// When the subscription was created. Recorded automatically.
    var updatedAt: Date { get }

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    var name: String { get }

    #if swift(>=5.4)
    /**
     Updates a Flexible Sync's subscription query and/or name.

     - warning: This method may only be called during a write transaction.

     - parameter to: A query builder that produces a subscription which can be used to
                     update the subscription query and/or name.
     */
    func update(@QueryBuilder _ to: () -> (AnySyncSubscription)) throws
    #endif // swift(>=5.4)
}

class _AnySyncSubscriptionBox: _SyncSubscription {
    var createdAt: Date {
        fatalError("Must be overriden", file: #file, line: #line)
    }

    var updatedAt: Date {
        fatalError("Must be overriden", file: #file, line: #line)
    }

    var name: String {
        fatalError("Must be overriden", file: #file, line: #line)
    }

    #if swift(>=5.4)
    func update(@QueryBuilder _ to: () -> (AnySyncSubscription)) throws {
        fatalError("Must be overriden")
    }
    #endif // swift(>=5.4)
}

final class _SyncSubscriptionBox<S: _SyncSubscription>: _AnySyncSubscriptionBox {
    private var _base: S

    override var createdAt: Date {
        _base.createdAt
    }

    override var updatedAt: Date {
        _base.updatedAt
    }

    override var name: String {
        _base.name
    }

    #if swift(>=5.4)
    override func update(@QueryBuilder _ to: () -> (AnySyncSubscription)) throws {
        try _base.update(to)
    }
    #endif // swift(>=5.4)

    init(_ base: S) {
        self._base = base
    }
}

// TODO: Add when public `@frozen`
// TODO: Change to public
/// An enum representing different states for the Subscription Set.
internal enum SyncSubscriptionState {
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
internal struct AnySyncSubscription: _SyncSubscription {
    private let _box: _AnySyncSubscriptionBox

    /// When the subscription was created. Recorded automatically.
    internal var createdAt: Date {
        _box.createdAt
    }

    /// When the subscription was last updated. Recorded automatically.
    internal var updatedAt: Date {
        _box.updatedAt
    }

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    internal var name: String {
        _box.name
    }

    #if swift(>=5.4)
    /**
     Updates a Flexible Sync's subscription query and/or name.

     - warning: This method may only be called during a write transaction.

     - parameter to: A query builder that produces a subscription which can be used to
                     update the subscription query and/or name.
     */
    func update(@QueryBuilder _ to: () -> (AnySyncSubscription)) throws {
        try _box.update(to)
    }
    #endif // swift(>=5.4)

    /// Creates a type-erased  `AnySyncSubscription` that wraps any `ISyncSubscription`
    /// conforming object.
    internal init<S>(_ base: S) where S: _SyncSubscription {
        self._box = _SyncSubscriptionBox(base)
    }
}

// TODO: Add when public `@frozen`
// TODO: Change to public
/**
 `SyncSubscription` is  used to define a Flexible Sync's subscription, which
 can be added/remove or updated within a write subscription transaction.
 */
internal struct SyncSubscription<ObjectType: _RealmSchemaDiscoverable>: _SyncSubscription {
    /// When the subscription was created. Recorded automatically.
    private(set) var createdAt: Date = Date()

    /// When the subscription was last updated. Recorded automatically.
    private(set) var updatedAt: Date = Date()

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    private(set) var name: String = ""

    internal typealias QueryFunction = (Query<ObjectType>) -> Query<ObjectType>

    private(set) internal var query: QueryFunction

    internal init(name: String = "", query: @escaping QueryFunction) {
        self.name = name
        self.query = query
    }

    #if swift(>=5.4)
    /**
     Updates a Flexible Sync's subscription query and/or name.

     - warning: This method may only be called during a write subscription block.

     - parameter to: A query builder that produces a subscription which can be used to
                     update the subscription query and/or name.
     */
    func update(@QueryBuilder _ to: () -> (AnySyncSubscription)) throws {
        fatalError("Missing Implementation")
    }
    #endif // swift(>=5.4)
}

// TODO: Change to public
#if swift(>=5.4)
@resultBuilder internal struct QueryBuilder {
    internal static func buildBlock<T: _RealmSchemaDiscoverable>(_ component: SyncSubscription<T>) -> AnySyncSubscription {
        return AnySyncSubscription(component)
    }
}
#endif // swift(>=5.4)

// TODO: Change to public
// TODO: Add when public `@frozen`
/**
 A task object which can be used to observe state changes on the subscription set.
 */
internal struct SyncSubscriptionTask {
    /**
     Notifies state changes for the subscription set.
     During a write batch transaction to the server, it will return complete when the server is on
     "steady-state" synchronization.
     This will throw an error if someone updates the subscription set while on a write transaction.
     */
    internal func observe(_ block: @escaping (SyncSubscriptionState) -> Void) {
        fatalError()
    }
}

// TODO: Change to public
#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, tvOS 15.0, iOS 15.0, watchOS 8.0, *)
extension SyncSubscriptionTask {
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

// TODO: Change to public
extension Array where Element == AnySyncSubscription {
    /**
     Create and commit a write transaction and updates the subscription set,
     this will not wait for the server to acknowledge and see all the data associated with this
     collection of subscription.

     - parameter block: The block containing the subscriptions transactions to perform.
     - returns: A task object which can be used to observe the state changes of
                the subscription set.

     - throws: An `NSError` if the transaction could not be completed successfully.
               If `block` throws, the function throws the propagated `ErrorType` instead.
     */
    @discardableResult
    internal func write(_ block: (() throws -> Void)) throws -> SyncSubscriptionTask {
        fatalError()
    }

    #if swift(>=5.4)
    /**
     Returns an `AnySyncSubscription` which encapsulates the resulted subscription from
     the search.

     - parameter named: The name of the subscription searching for.
     - returns: A `AnySubscription` struct encapsulating the subscription we are searching for.
     */
    internal func first(named: String) -> AnySyncSubscription? {
        fatalError()
    }

    /**
     Returns an `AnySyncSubscription` which encapsulates the resulted subscription from
     the search.

     - parameter where: A query builder that produces a subscription which can be used to search
                        the subscription by query and/or name.
     - returns: An `AnySyncSubscription` struct encapsulating the subscription we are searching for.
     */
    internal func first(@QueryBuilder _ `where`: () -> (AnySyncSubscription)) -> AnySyncSubscription? {
        fatalError()
    }

    /**
     Append an `AnySyncSubscription` to the subscription set which will be sent to the server when
     committed at the end of a write subscription block.

     - warning: This method may only be called during a write subscription block.

     - parameter to: A query builder that produces a subscription which can be added to the
                     subscription set.
     */
    internal func `append`(@QueryBuilder _ to: () -> (AnySyncSubscription)) {
        fatalError()
    }

    /**
     Remove an `AnySyncSubscription`to the subscription set which will be removed from the server when
     committed at the end of a write subscription block.

     - warning: This method may only be called during a write subscription block.

     - parameter to: A query builder that produces a subscription which will be removed from the
                     subscription set.
     */
    internal func remove(@QueryBuilder _ to: () -> (AnySyncSubscription)) {
        fatalError()
    }
    #endif // swift(>=5.4)

    /**
     Removes an `AnySyncSubscription`to the subscription set which will be removed from the server when
     committed at the end of a write subscription block.

     - warning: This method may only be called during a write subscription block.

     - parameter subscription: The subscription to be removed from the subscription set.
     */
    internal func remove(_ subscription: AnySyncSubscription) {
        fatalError()
    }

    /**
     Removes an `AnySyncSubscription`to the subscription set which will be removed from the server when
     committed at the end of a write subscription block.

     - warning: This method may only be called during a write subscription block.

     - parameter named: The name of the subscription to be removed from the subscription set.
     */
    internal func remove(named: String) {
        fatalError()
    }

    /**
     Removes all subscriptions from the subscription set.

     - warning: This method may only be called during a write subscription block.
     */
    internal func removeAll() {
        fatalError()
    }

    /**
     Removes zero or none subscriptions of the given type from the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter type: The type of the objects to be removed.
     */
    internal func removeAll<T: Object>(ofType type: T.Type) {
        fatalError()
    }
}

// TODO: Change to public
#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, tvOS 15.0, iOS 15.0, watchOS 8.0, *)
extension Array where Element == AnySyncSubscription {
    /**
     Asynchronously creates and commit a write transaction and updates the subscription set,
     this will not wait for the server to acknowledge and see all the data associated with this
     collection of subscription.

     - parameter block: The block containing the subscriptions transactions to perform.
     - returns: A task object which can be used to observe the state changes of
                the subscription set.

     - throws: An `NSError` if the transaction could not be completed successfully.
               If `block` throws, the function throws the propagated `ErrorType` instead.
     */
    @discardableResult
    internal func write(_ block: (() throws -> Void)) async throws -> SyncSubscriptionTask {
        fatalError()
    }
}
#endif // swift(>=5.5)
