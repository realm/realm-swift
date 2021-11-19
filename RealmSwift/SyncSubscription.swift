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

internal class _AnySyncSubscriptionBox: ISyncSubscription {
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

internal final class _SyncSubscriptionBox<S: ISyncSubscription>: _AnySyncSubscriptionBox {
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
/// A protocol which defines a Subscription for using in a Flexible Sync transactions.
///
/// This is used as well to define a type-erasing wrapper.
internal protocol ISyncSubscription {
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

// TODO: Change to public
/// A type-erasing  wrapper over any `ISyncSubscription` conforming object.
///
/// An `AnySyncSubscription` instance forwards its operations to a base struct, hiding
/// the specifics of the underlying type which allow us to make operations over an array
/// of `AnySyncSubscriptions`.
internal struct AnySyncSubscription: ISyncSubscription {
    private let _box: _AnySyncSubscriptionBox

    /// When the subscription was created. Recorded automatically.
    internal var createdAt: Date {
        _box.createdAt
    }

    /// When the subscription was last updated. Recorded automatically.
    internal var updatedAt: Date  {
        _box.updatedAt
    }

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    internal var name: String  {
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
    internal init<S>(_ base: S) where S: ISyncSubscription {
        self._box = _SyncSubscriptionBox(base)
    }
}

// TODO: Add when public `@frozen`
// TODO: Change to public
/**
 `SyncSubscription` is  used to define a Flexible Sync's subscription, which
 can be added/remove or updated within a write subscription transaction.
 */
internal struct SyncSubscription<ObjectType: _RealmSchemaDiscoverable>: ISyncSubscription {
    /// When the subscription was created. Recorded automatically.
    private(set) var createdAt: Date = Date()

    /// When the subscription was last updated. Recorded automatically.
    var updatedAt: Date = Date()

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    var name: String = ""

    internal typealias QueryFunction = (Query<ObjectType>) -> Query<ObjectType>

    private(set) internal var query: QueryFunction

    internal init(name: String = "", query: @escaping QueryFunction) {
        self.name = name
        self.query = query
    }

    #if swift(>=5.4)
    /**
     Updates a Flexible Sync's subscription query and/or name.

     - warning: This method may only be called during a write transaction.

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

// TODO: Can we observer changes on the subscription set?
// Task to get state changes from the write transaction
// TODO: Add when public `@frozen`
internal struct SyncSubscriptionTask {
    // Notifies state changes for the write subscription transaction
    // if state is complete this will return complete, will
    // throw an error if someone updates the subscription set while waiting
    internal func observe(_ block: @escaping (SyncSubscriptionState) -> Void) {
        fatalError()
    }
}

#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, tvOS 15.0, iOS 15.0, watchOS 8.0, *)
extension SyncSubscriptionTask {
    // Notifies state changes for the write subscription transaction
    // if state is complete this will return complete, will
    // throw an error if someone updates the subscription set while waiting
    internal var state: AsyncStream<SyncSubscriptionState> {
        fatalError()
    }
}
#endif // swift(>=5.5)

// SubscriptionSet
extension Array where Element == AnySyncSubscription {
    // Creates a write transaction and updates the subscription set, this will not wait
    // for the server to acknowledge and see all the data associated with this collection of
    // subscriptions
    @discardableResult
    internal func write(_ block: (() throws -> Void)) throws -> SyncSubscriptionTask {
        fatalError()
    }

    // Wait for the server to acknowledge and send all the data associated with this
    // subscription set, if state is complete this will return immediately, will
    // throw an error if someone updates the subscription set will waiting
    // Completion block version
    internal func `observe`(completion: @escaping (Result<Void, Error>) -> Void) {
        fatalError()
    }

    #if swift(>=5.4)
    // Find subscription in the subscription set by subscription properties
    internal func first(named: String) -> AnySyncSubscription? {
        fatalError()
    }

    // Find subscription in the subscription set by query
    internal func first(@QueryBuilder _ `where`: () -> (AnySyncSubscription)) -> AnySyncSubscription? {
        fatalError()
    }

    // Add a query to the subscription set, this has to be done within a write block
    internal func `append`(@QueryBuilder _ to: () -> (AnySyncSubscription)) {
        fatalError()
    }

    // Remove subscription of subscription set by query, this has to be done within a write block
    internal func remove(@QueryBuilder _ to: () -> (AnySyncSubscription)) throws {
        fatalError()
    }
    #endif // swift(>=5.4)

    // Remove a subscription from the subscription set, this has to be done within a write block
    internal func remove(_ subscription: AnySyncSubscription) throws {
        fatalError()
    }

    // Remove subscription of subscription set by name, this has to be done within a write block
    internal func remove(named: String) throws {
        fatalError()
    }

    // Remove all subscriptions from the subscriptions set
    internal func removeAll() throws {
        fatalError()
    }

    // Remove all subscriptions from the subscriptions set by type
    internal func removeAll<T: Object>(ofType type: T.Type) throws {
        fatalError()
    }
}

#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, tvOS 15.0, iOS 15.0, watchOS 8.0, *)
extension Array where Element == AnySyncSubscription {
    // Asynchronously creates and commit a write transaction and updates the subscription set,
    // this will not wait for the server to acknowledge and see all the data associated with this
    // collection of subscription
    @discardableResult
    internal func write(_ block: (() throws -> Void)) async throws -> SyncSubscriptionTask {
        fatalError()
    }
}
#endif // swift(>=5.5)
