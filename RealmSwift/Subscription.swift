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

public protocol AnySubscription {}

public class Subscription<Element: Object>: AnySubscription {
    public typealias QueryFunction = (Query<Element>) -> Query<Element>

    // When the subscription was created. Recorded automatically.
    public var createdAt: Date = Date()

    // When the subscription was last updated. Recorded automatically.
    public var updatedAt: Date = Date()

    // Name of the subscription, if not specified it will return the value in Query
    public var name: String = ""

    // Update query for subscription
    public func update(@QueryBuilder _ to: () -> (AnySubscription)) throws {
        fatalError()
    }

    private(set) public var query: QueryFunction
    public init(name: String = "", query: @escaping QueryFunction) {
        self.name = name
        self.query = query
    }
}

public protocol QueryBuilderComponent {}

@resultBuilder public struct QueryBuilder {
    public static func buildBlock(_ components: AnySubscription...) -> [AnySubscription] {
        return components
    }

    public static func buildBlock(_ component: AnySubscription) -> AnySubscription {
        return component
    }
}

public protocol AnyQueryBuilderComponent {}

// Realm operations
// Realm will only allow getting all the subscriptions and subscribe to a query
extension Realm {
    // Get all subscriptions for this Realm.
    /*private(set)*/ public var subscriptions: [AnySubscription] {
        fatalError()
    }
}

// TODO: Can we observer changes on the subscription set?
// Task to get state changes from the write transaction
@frozen public struct SubscriptionTask {
    // Notifies state changes for the write subscription transaction
    // if state is complete this will return complete, will
    // throw an error if someone updates the subscription set while waiting
    public func observe(_ block: @escaping (SubscriptionState) -> Void) {
        fatalError()
    }
}

#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, tvOS 15.0, iOS 15.0, watchOS 8.0, *)
extension SubscriptionTask {
    // Notifies state changes for the write subscription transaction
    // if state is complete this will return complete, will
    // throw an error if someone updates the subscription set while waiting
    public func observe() -> AsyncStream<SubscriptionState> {
        fatalError()
    }
}
#endif // swift(>=5.5)
// SubscriptionSet
extension Array where Element == AnySubscription {
    // Creates a write transaction and updates the subscription set, this will not wait
    // for the server to acknowledge and see all the data associated with this collection of
    // subscriptions
    @discardableResult
    public func write(_ block: (() throws -> ())) throws -> SubscriptionTask {
        fatalError()
    }

    // Wait for the server to acknowledge and send all the data associated with this
    // subscription set, if state is complete this will return immediately, will
    // throw an error if someone updates the subscription set will waiting
    // Completion block version
    public func `observe`(completion: @escaping (Result<Void, Error>) -> Void) {
        fatalError()
    }

    // Find subscription in the subscription set by subscription properties
    public func first<Element: Object>(`where`: @escaping (Subscription<Element>) -> Bool) -> Subscription<Element>? {
        fatalError()
    }

    // Find subscription in the subscription set by query
    public func first<Element: Object>(@QueryBuilder _ `where`: () -> (AnySubscription)) -> Subscription<Element>? {
        fatalError()
    }

    // Add a queries to the subscription set, this has to be done within a write block
    public func `append`(@QueryBuilder _ to: () -> ([AnySubscription])) {
        fatalError()
    }

    // Add a query to the subscription set, this has to be done within a write block
    public func `append`(@QueryBuilder _ to: () -> (AnySubscription)) {
        fatalError()
    }

    // Remove a subscription from the subscription set, this has to be done within a write block
    public func remove(_ subscription: AnySubscription) throws {
        fatalError()
    }

    // Remove subscriptions of subscription set by query, this has to be done within a write block
    public func remove(@QueryBuilder _ to: () -> ([AnySubscription])) throws {
        fatalError()
    }

    // Remove subscription of subscription set by query, this has to be done within a write block
    public func remove(@QueryBuilder _ to: () -> (AnySubscription)) throws {
        fatalError()
    }

    // Remove subscription of subscription set by name, this has to be done within a write block
    public func remove(_ name: String) throws {
        fatalError()
    }

    // Remove all subscriptions from the subscriptions set
    public func removeAll() throws {
        fatalError()
    }

    // Remove all subscriptions from the subscriptions set by type
    public func removeAll<Element: Object>(ofType type: Element.Type) throws {
        fatalError()
    }
}

#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, tvOS 15.0, iOS 15.0, watchOS 8.0, *)
extension Array where Element == AnySubscription {
    // Asynchronously creates and commit a write transaction and updates the subscription set,
    // this will not wait for the server to acknowledge and see all the data associated with this
    // collection of subscription
    @discardableResult
    public func write(_ block: (() throws -> ())) async throws -> SubscriptionTask {
        fatalError()
    }
}
#endif // swift(>=5.5)
//
//#if !(os(iOS) && (arch(i386) || arch(arm)))
//import Combine
//
//@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
//extension Array where Element == AnySubscription {
//    // Wait for the server to acknowledge and send all the data associated with this
//    // subscription set, if state is complete this will return immediately, will
//    // throw an error if someone updates the subscription set will waiting
//    public func waitForSync() -> Future<Void, Error> {
//        return Future { self.waitForSync(completion: $0) }
//    }
//}
//#endif // canImport(Combine)

// State Updates
// Some operations will return a `SubscriptionTask` which can be used to get state updates (There will be a Combine API as well not described here)
public enum SubscriptionState: Equatable {
    public static func == (lhs: SubscriptionState, rhs: SubscriptionState) -> Bool {
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

