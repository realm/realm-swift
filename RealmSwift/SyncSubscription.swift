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

// State Updates
// Some operations will return a `SubscriptionTask` which can be used to get state updates (There will be a Combine API as well not described here)
internal enum SyncSubscriptionState: Equatable {
    internal static func == (lhs: SyncSubscriptionState, rhs: SyncSubscriptionState) -> Bool {
        true
    }

    // Subscription is complete and the server is in "steady-state" synchronization.
    case complete
    // The Subscription encountered an error.
    case error(Error)
    // The server is processing the subscription and updating the Realm data
    // with new matches
    case pending
}

internal protocol AnySyncSubscription {}

internal class SyncSubscription<Element: Object>: AnySyncSubscription {
    internal typealias QueryFunction = (Query<Element>) -> Query<Element>

    // When the subscription was created. Recorded automatically.
    internal var createdAt: Date = Date()

    // When the subscription was last updated. Recorded automatically.
    internal var updatedAt: Date = Date()

    // Name of the subscription, if not specified it will return the value in Query
    internal var name: String = ""

    // Update query for subscription
    internal func update(@QueryBuilder _ to: () -> (AnySyncSubscription)) throws {
        fatalError()
    }

    private(set) internal var query: QueryFunction
    internal init(name: String = "", query: @escaping QueryFunction) {
        self.name = name
        self.query = query
    }
}

internal protocol QueryBuilderComponent {}

@resultBuilder internal struct QueryBuilder {
    internal static func buildBlock(_ components: AnySyncSubscription...) -> [AnySyncSubscription] {
        return components
    }

    internal static func buildBlock(_ component: AnySyncSubscription) -> AnySyncSubscription {
        return component
    }
}

internal protocol AnyQueryBuilderComponent {}

// Realm operations
// Realm will only allow getting all the subscriptions and subscribe to a query
extension Realm {
    // Get the active subscription set for this realm.
    internal var subscriptions: [AnySyncSubscription] {
        fatalError()
    }
}

// TODO: Can we observer changes on the subscription set?
// Task to get state changes from the write transaction
// @frozen
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
    internal func observe() -> AsyncStream<SyncSubscriptionState> {
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

    // Find subscription in the subscription set by subscription properties
    internal func first<Element: Object>(`where`: @escaping (SyncSubscription<Element>) -> Bool) -> SyncSubscription<Element>? {
        fatalError()
    }

    // Find subscription in the subscription set by query
    internal func first<Element: Object>(@QueryBuilder _ `where`: () -> (AnySyncSubscription)) -> SyncSubscription<Element>? {
        fatalError()
    }

    // Add a queries to the subscription set, this has to be done within a write block
    internal func `append`(@QueryBuilder _ to: () -> ([AnySyncSubscription])) {
        fatalError()
    }

    // Add a query to the subscription set, this has to be done within a write block
    internal func `append`(@QueryBuilder _ to: () -> (AnySyncSubscription)) {
        fatalError()
    }

    // Remove a subscription from the subscription set, this has to be done within a write block
    internal func remove(_ subscription: AnySyncSubscription) throws {
        fatalError()
    }

    // Remove subscriptions of subscription set by query, this has to be done within a write block
    internal func remove(@QueryBuilder _ to: () -> ([AnySyncSubscription])) throws {
        fatalError()
    }

    // Remove subscription of subscription set by query, this has to be done within a write block
    internal func remove(@QueryBuilder _ to: () -> (AnySyncSubscription)) throws {
        fatalError()
    }

    // Remove subscription of subscription set by name, this has to be done within a write block
    internal func remove(_ name: String) throws {
        fatalError()
    }

    // Remove all subscriptions from the subscriptions set
    internal func removeAll() throws {
        fatalError()
    }

    // Remove all subscriptions from the subscriptions set by type
    internal func removeAll<Element: Object>(ofType type: Element.Type) throws {
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

#if !(os(iOS) && (arch(i386) || arch(arm)))
import Combine

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension Array where Element == AnySyncSubscription {
    // Asynchronously creates and commit a write transaction and updates the subscription set,
    // this will not wait for the server to acknowledge and see all the data associated with this
    // collection of subscription
    @discardableResult
    internal func writeAsync(_ block: @escaping (() throws -> Void)) -> RealmPublishers.SyncSubscriptionPublisher {
        return RealmPublishers.SyncSubscriptionPublisher(block)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension RealmPublishers {
    //@frozen
    internal struct SyncSubscriptionPublisher: Publisher {
        internal func receive<S>(subscriber: S) where S: Subscriber, Error == S.Failure, Void == S.Input {
            fatalError()
        }

        /// This publisher can fail it cannot commit the subscriptions transactions to the realm
        internal typealias Failure = Error
        /// This publisher emits when the operations on the write block are committed
        internal typealias Output = Void

        private let block: (() throws -> Void)

        internal init(_ block: @escaping (() throws -> Void)) {
            self.block = block
        }

        internal func observe() -> SyncSubscriptionStatePublisher {
            fatalError()
        }
    }

    //@frozen
    internal struct SyncSubscriptionStatePublisher: Publisher {
        internal func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, SyncSubscriptionState == S.Input {
            fatalError()
        }

        /// This publisher will fail if there is an error on the state observations
        internal typealias Failure = Error
        /// This publisher emits states for the subscription set
        internal typealias Output = SyncSubscriptionState
    }
}
#endif
