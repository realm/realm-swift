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
    /// The subscription set has been superseded by an updated one, this typically means that
    /// someone is trying to write a subscription on a different instance of the subscription set.
    /// You should not use a superseded subscription set and instead obtain a new instance of
    /// the subscription set to write a subscription.
    case superseded

    public static func == (lhs: SyncSubscriptionState, rhs: SyncSubscriptionState) -> Bool {
        switch (lhs, rhs) {
        case (.complete, .complete), (.pending, .pending), (.superseded, .superseded):
            return true
        case (.error(let error), .error(let error2)):
            return error == error2
        default:
            return false
        }
    }
}

/// :nodoc:
public protocol _SyncSubscription {
    /// :nodoc:
    associatedtype Element: RealmCollectionValue

    /// Query string of the subscription.
    var query: String { get }

    /// When the subscription was created. Recorded automatically.
    var createdAt: Date { get }

    /// When the subscription was last updated. Recorded automatically.
    var updatedAt: Date { get}

    #if swift(>=5.6) && canImport(_Concurrency)
    @available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
    /**
     Removes the current subscription from the subscription set, associated to this `QueryResults`.
     */
    func unsubscribe() async throws
    #endif // canImport(_Concurrency)
}

// `SyncSubscription` includes all the common implementation for a subscription.
internal protocol SyncSubscription: _SyncSubscription {
    var _rlmSyncSubscription: RLMSyncSubscription? { get }
    init(_ rlmSyncSubscription: RLMSyncSubscription, _ results: Results<Element>)
}

extension SyncSubscription {
    /// Query string of the subscription.
    public var query: String {
        _rlmSyncSubscription!.queryString
    }

    /// When the subscription was created. Recorded automatically.
    public var createdAt: Date {
        _rlmSyncSubscription!.createdAt
    }

    /// When the subscription was last updated. Recorded automatically.
    public var updatedAt: Date {
        _rlmSyncSubscription!.updatedAt
    }
}

#if swift(>=5.6) && canImport(_Concurrency)
@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
extension SyncSubscription {
    /**
     Removes the current subscription from the subscription set, associated to this `QueryResults`.
     */
    public func unsubscribe() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let completion: (Error?) -> Void = { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            _rlmSyncSubscription?.unsubscribe(onComplete: completion)
        }
    }
}
#endif // canImport(_Concurrency)

/**
 A type-erased `QueryResults`.
*/
public struct AnyQueryResults: SyncSubscription, Sequence {

    public typealias Element = DynamicObject

    internal var results: Results<DynamicObject>
    internal var _rlmSyncSubscription: RLMSyncSubscription?

    init(_ rlmSyncSubscription: RLMSyncSubscription, _ results: Results<DynamicObject>) {
        self._rlmSyncSubscription = rlmSyncSubscription
        self.results = results
    }

    /// A human-readable description of the objects represented by the results..
    public var description: String {
        return RLMDescriptionWithMaxDepth("AnyQueryResults", results.collection, RLMDescriptionMaxDepth)
    }

    // MARK: Sequence

    /// Returns an iterator over the elements of this sequence.
    public func makeIterator() -> Results<Element>.Iterator {
        results.makeIterator()
    }

    /**
    Returns a `QueryResults` for the given type, returns nil if the results doesn't correspond to the given type.
     
    - parameter type: The type of the results to return.
     */
    public func `as`<T: Object>(type: T.Type) -> QueryResults<T>? {
        guard _rlmSyncSubscription!.objectClassName == "\(T.self)" else {
            return nil
        }
        return QueryResults(_rlmSyncSubscription!, unsafeBitCast(results, to: Results<T>.self))
    }
}

/**
 `QueryResults` wraps a sync subscription and contains the data for the subscription's query,

 `QueryResults` works exactly like `Results`and lazily evaluates only the first time it is accessed,
  and allows all the operations and subqueries over the results.
 */
@frozen public struct QueryResults<ElementType>: SyncSubscription, RealmCollectionImpl, Equatable where ElementType: RealmCollectionValue {
    public typealias Element = ElementType

    internal var _rlmSyncSubscription: RLMSyncSubscription?
    internal var results: Results<Element>
    var collection: RLMCollection {
        results.collection
    }

    /// A human-readable description of the objects represented by the results.
    public var description: String {
        return RLMDescriptionWithMaxDepth("QueryResults", collection, RLMDescriptionMaxDepth)
    }

    // MARK: Initializers
    init(_ rlmSyncSubscription: RLMSyncSubscription, _ results: Results<Element>) {
        self._rlmSyncSubscription = rlmSyncSubscription
        self.results = results
    }

    init(collection: RLMCollection) {
        fatalError("path should never be hit")
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
    public static func == (lhs: QueryResults<Element>, rhs: QueryResults<Element>) -> Bool {
        lhs.collection.isEqual(rhs.collection)
    }
}

extension QueryResults: Encodable where Element: Encodable {}

protocol _QuerySubscription {
    var className: String { get }
    var predicate: NSPredicate { get }
}

/**
 `QuerySubscription` is  used to define a subscription query, used to be able to add a query to a subscription set.
 */
@frozen public struct QuerySubscription<T: RealmFetchable>: _QuerySubscription {
    // MARK: Internal
    internal var className: String
    internal var predicate: NSPredicate

    /**
     Creates a `QuerySubscription` for the given type.

     - parameter query: The query for the subscription. if nil it will set the query to all documents for the collection.
     */
    public init(_ query: ((Query<T>) -> Query<Bool>)? = nil) {
        self.className = "\(T.self)"
        self.predicate = query?(Query()).predicate ?? NSPredicate(format: "TRUEPREDICATE")
    }

    /**
     Creates a `QuerySubscription` for the given type.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments,
                                  which will be used to create the subscription.
     */
    public init(_ predicateFormat: String, _ args: Any...) {
        self.className = "\(T.self)"
        self.predicate = NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args))
    }

    /**
     Creates a `QuerySubscription` for the given type.

     - parameter predicate: The predicate defining the query used to filter the objects on the server..
     */
    public init(_ predicate: NSPredicate) {
        self.className = "\(T.self)"
        self.predicate = predicate
    }
}

/**
 `SyncSubscriptionSet` is  a collection of `SyncSubscription`s. This is the entry point
 for adding `SyncSubscription`s.
 */
@frozen public struct SyncSubscriptionSet {
    // MARK: Private

    internal let rlmSyncSubscriptionSet: RLMSyncSubscriptionSet
    private let realm: Realm

    private func update(_ block: (() -> Void), onComplete: ((Error?) -> Void)? = nil) {
        rlmSyncSubscriptionSet.update(block, onComplete: onComplete ?? { _ in })
    }

    private func `append`(_ subscription: _QuerySubscription) {
        rlmSyncSubscriptionSet.addSubscription(withClassName: subscription.className,
                                               predicate: subscription.predicate)
    }

    // MARK: Initializers

    internal init(_ rlmSyncSubscriptionSet: RLMSyncSubscriptionSet, realm: Realm) {
        self.rlmSyncSubscriptionSet = rlmSyncSubscriptionSet
        self.realm = realm
    }

    internal init(_ rlmSyncSubscriptionSet: RLMSyncSubscriptionSet) {
        self.rlmSyncSubscriptionSet = rlmSyncSubscriptionSet
        self.realm = ObjectiveCSupport.convert(object: rlmSyncSubscriptionSet.realm)
    }

    // MARK: Internal

    /// Created to be used to get results for SwiftUI
    internal func subscribeToQuery<T: RealmFetchable>(_ query: NSPredicate, _ callback: @escaping (Result<QueryResults<T>, Error>) -> Void) {
        let querySubscription = QuerySubscription<T>(query)
        let block = {
            rlmSyncSubscriptionSet.addSubscription(withClassName: querySubscription.className,
                                                   predicate: querySubscription.predicate)
        }

        rlmSyncSubscriptionSet.update(block, queue: DispatchQueue.main) { (error: Error?) in
            if let error = error {
                callback(.failure(error))
            } else {
                callback(.success(QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: querySubscription.className, predicate: querySubscription.predicate)!,
                                               realm.objects(T.self).filter(querySubscription.predicate))))
            }
        }
    }

    // MARK: Public

    /// Returns the current state for the subscription set.
    public var state: SyncSubscriptionState {
        switch rlmSyncSubscriptionSet.state {
        case .pending:
            return .pending
        case .complete:
            return .complete
        case .superseded:
            return .superseded
        case .error:
            return .error(rlmSyncSubscriptionSet.error!)
        @unknown default:
            fatalError()
        }
    }

    /**
     Returns a `QueryResults` for the specified query.

     - parameter type: The type of the object to be queried.
     - parameter where: A query builder that produces a subscription which can be used to search
                        the subscription by query and/or name.
     - returns: `QueryResults` for the given query containing the data for the query.
     */
    public func first<T: Object>(ofType type: T.Type, `where` query: @escaping (Query<T>) -> Query<Bool>) -> QueryResults<T>? {
        let predicate = query(Query()).predicate
        return rlmSyncSubscriptionSet.subscription(withClassName: "\(T.self)", predicate: predicate).map {
            QueryResults($0, realm.objects(T.self).filter(predicate))
        }
    }

    /// The number of subscriptions in the subscription set.
    public var count: Int { return Int(rlmSyncSubscriptionSet.count) }

    // MARK: Subscription Retrieval

    /**
     Returns a `AnyQueryResults` representing the query results at the given `position`.

     - parameter position: The index for the resulting subscription.
     */
    public subscript(position: Int) -> AnyQueryResults? {
        throwForNegativeIndex(position)
        return rlmSyncSubscriptionSet.object(at: UInt(position)).map {
            AnyQueryResults($0, realm.dynamicObjects($0.objectClassName))
        }
    }

    /// Returns a `AnyQueryResults` representing the first object in the subscription set list, or `nil` if there is no subscriptions.
    public var first: AnyQueryResults? {
        return rlmSyncSubscriptionSet.firstObject().map {
            AnyQueryResults($0, realm.dynamicObjects($0.objectClassName))
        }
    }

    /// Returns a `AnyQueryResults` representing the last object in the subscription set list, or `nil` if there is no subscriptions.
    public var last: AnyQueryResults? {
        return rlmSyncSubscriptionSet.lastObject().map {
            AnyQueryResults($0, realm.dynamicObjects($0.objectClassName))
        }
    }
}

extension SyncSubscriptionSet: Sequence {
    // MARK: Sequence Support

    /// Returns a `SyncSubscriptionSetIterator` that yields successive elements in the subscription collection.
    public func makeIterator() -> SyncSubscriptionSetIterator {
        return SyncSubscriptionSetIterator(rlmSyncSubscriptionSet, realm)
    }
}

/**
 This struct enables sequence-style enumeration for `SyncSubscriptionSet`.
 */
@frozen public struct SyncSubscriptionSetIterator: IteratorProtocol {
    private let rlmSubscriptionSet: RLMSyncSubscriptionSet
    private let realm: Realm
    private var index: Int = -1

    init(_ rlmSubscriptionSet: RLMSyncSubscriptionSet, _ realm: Realm) {
        self.rlmSubscriptionSet = rlmSubscriptionSet
        self.realm = realm
    }

    private func nextIndex(for index: Int?) -> Int? {
        if let index = index, index < self.rlmSubscriptionSet.count - 1 {
            return index + 1
        }
        return nil
    }

    mutating public func next() -> AnyQueryResults? {
        if let index = self.nextIndex(for: self.index) {
            self.index = index
            return rlmSubscriptionSet.object(at: UInt(index)).map {
                AnyQueryResults($0, realm.dynamicObjects($0.objectClassName))
            }
        }
        return nil
    }
}

#if swift(>=5.6) && canImport(_Concurrency)
@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
extension SyncSubscriptionSet {
    /**
     Asynchronously creates a write transaction and updates the subscription set,
     this will not wait for the server to acknowledge and see all the data associated with this
     collection of subscription.

     - parameter block: The block containing the subscriptions transactions to perform.

     - throws: An `NSError` if the transaction could not be completed successfully.
               If `block` throws, the function throws the propagated `ErrorType` instead.
     */
    @MainActor
    private func update(_ block: (() -> Void)) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            update(block) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    private func subscribe(_ subscriptions: _QuerySubscription...) async throws {
        try await update {
            subscriptions.forEach { subscription in
                self.append(subscription)
            }
        }
    }

    /**
     Appends the query to the current subscription set and waits for the server to acknowledge the subscription,
     returns a `QueryResults` containing all the data associated to this query.

     - parameter query: The query which will be used for the subscription.
     - returns: `QueryResults` for the given subscription containing the data for the query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T: RealmFetchable>(to query: @escaping ((Query<T>) -> Query<Bool>)) async throws -> QueryResults<T> {
        let query = QuerySubscription<T>(query)
        try await subscribe(query)
        return QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                            realm.objects(T.self).filter(query.predicate))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a `QueryResults` containing all the data associated to this object type.

     - parameter type: The type of the object to be queried,.
     - returns: `QueryResults` for the given subscription containing the data for the query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T: RealmFetchable>(to type: T.Type) async throws -> QueryResults<T> {
        let query = QuerySubscription<T>()
        try await subscribe(query)
        return QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                            realm.objects(T.self))
    }

    /**
     Appends the query to the current subscription set and waits for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>) async throws -> (QueryResults<T1>, QueryResults<T2>) {
        try await subscribe(query, query2)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query3: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable, T3: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>, _ query3: QuerySubscription<T3>) async throws -> (QueryResults<T1>, QueryResults<T2>, QueryResults<T3>) {
        try await subscribe(query, query2, query3)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query3.className, predicate: query3.predicate)!,
                             realm.objects(T3.self).filter(query3.predicate)))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query3: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query4: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable, T3: RealmFetchable, T4: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>, _ query3: QuerySubscription<T3>, _ query4: QuerySubscription<T4>) async throws -> (QueryResults<T1>, QueryResults<T2>, QueryResults<T3>, QueryResults<T4>) {
        try await subscribe(query, query2, query3, query4)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query3.className, predicate: query3.predicate)!,
                             realm.objects(T3.self).filter(query3.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query4.className, predicate: query4.predicate)!,
                             realm.objects(T4.self).filter(query4.predicate)))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query3: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query4: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query5: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable, T3: RealmFetchable, T4: RealmFetchable, T5: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>, _ query3: QuerySubscription<T3>, _ query4: QuerySubscription<T4>, _ query5: QuerySubscription<T5>) async throws -> (QueryResults<T1>, QueryResults<T2>, QueryResults<T3>, QueryResults<T4>, QueryResults<T5>) {
        try await subscribe(query, query2, query3, query4, query5)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query3.className, predicate: query3.predicate)!,
                             realm.objects(T3.self).filter(query3.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query4.className, predicate: query4.predicate)!,
                             realm.objects(T4.self).filter(query4.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query5.className, predicate: query5.predicate)!,
                             realm.objects(T5.self).filter(query5.predicate)))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query3: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query4: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query5: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query6: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable, T3: RealmFetchable, T4: RealmFetchable, T5: RealmFetchable, T6: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>, _ query3: QuerySubscription<T3>, _ query4: QuerySubscription<T4>, _ query5: QuerySubscription<T5>, _ query6: QuerySubscription<T6>) async throws -> (QueryResults<T1>, QueryResults<T2>, QueryResults<T3>, QueryResults<T4>, QueryResults<T5>, QueryResults<T6>) {
        try await subscribe(query, query2, query3, query4, query5, query6)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query3.className, predicate: query3.predicate)!,
                             realm.objects(T3.self).filter(query3.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query4.className, predicate: query4.predicate)!,
                             realm.objects(T4.self).filter(query4.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query5.className, predicate: query5.predicate)!,
                             realm.objects(T5.self).filter(query5.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query6.className, predicate: query6.predicate)!,
                             realm.objects(T6.self).filter(query6.predicate)))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query3: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query4: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query5: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query6: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query7: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable, T3: RealmFetchable, T4: RealmFetchable, T5: RealmFetchable, T6: RealmFetchable, T7: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>, _ query3: QuerySubscription<T3>, _ query4: QuerySubscription<T4>, _ query5: QuerySubscription<T5>, _ query6: QuerySubscription<T6>, _ query7: QuerySubscription<T6>) async throws -> (QueryResults<T1>, QueryResults<T2>, QueryResults<T3>, QueryResults<T4>, QueryResults<T5>, QueryResults<T6>, QueryResults<T7>) {
        try await subscribe(query, query2, query3, query4, query5, query6, query7)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query3.className, predicate: query3.predicate)!,
                             realm.objects(T3.self).filter(query3.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query4.className, predicate: query4.predicate)!,
                             realm.objects(T4.self).filter(query4.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query5.className, predicate: query5.predicate)!,
                             realm.objects(T5.self).filter(query5.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query6.className, predicate: query6.predicate)!,
                             realm.objects(T6.self).filter(query6.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query7.className, predicate: query7.predicate)!,
                             realm.objects(T7.self).filter(query7.predicate)))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query3: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query4: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query5: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query6: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query7: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query8: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable, T3: RealmFetchable, T4: RealmFetchable, T5: RealmFetchable, T6: RealmFetchable, T7: RealmFetchable, T8: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>, _ query3: QuerySubscription<T3>, _ query4: QuerySubscription<T4>, _ query5: QuerySubscription<T5>, _ query6: QuerySubscription<T6>, _ query7: QuerySubscription<T7>, _ query8: QuerySubscription<T8>) async throws -> (QueryResults<T1>, QueryResults<T2>, QueryResults<T3>, QueryResults<T4>, QueryResults<T5>, QueryResults<T6>, QueryResults<T7>, QueryResults<T8>) {
        try await subscribe(query, query2, query3, query4, query5, query6, query7, query8)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query3.className, predicate: query3.predicate)!,
                             realm.objects(T3.self).filter(query3.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query4.className, predicate: query4.predicate)!,
                             realm.objects(T4.self).filter(query4.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query5.className, predicate: query5.predicate)!,
                             realm.objects(T5.self).filter(query5.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query6.className, predicate: query6.predicate)!,
                             realm.objects(T6.self).filter(query6.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query7.className, predicate: query7.predicate)!,
                             realm.objects(T7.self).filter(query7.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query8.className, predicate: query8.predicate)!,
                             realm.objects(T8.self).filter(query8.predicate)))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query3: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query4: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query5: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query6: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query7: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query8: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query9: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable, T3: RealmFetchable, T4: RealmFetchable, T5: RealmFetchable, T6: RealmFetchable, T7: RealmFetchable, T8: RealmFetchable, T9: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>, _ query3: QuerySubscription<T3>, _ query4: QuerySubscription<T4>, _ query5: QuerySubscription<T5>, _ query6: QuerySubscription<T6>, _ query7: QuerySubscription<T7>, _ query8: QuerySubscription<T8>, _ query9: QuerySubscription<T9>) async throws -> (QueryResults<T1>, QueryResults<T2>, QueryResults<T3>, QueryResults<T4>, QueryResults<T5>, QueryResults<T6>, QueryResults<T7>, QueryResults<T8>, QueryResults<T9>) {
        try await subscribe(query, query2, query3, query4, query5, query6, query7, query8, query9)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query3.className, predicate: query3.predicate)!,
                             realm.objects(T3.self).filter(query3.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query4.className, predicate: query4.predicate)!,
                             realm.objects(T4.self).filter(query4.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query5.className, predicate: query5.predicate)!,
                             realm.objects(T5.self).filter(query5.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query6.className, predicate: query6.predicate)!,
                             realm.objects(T6.self).filter(query6.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query7.className, predicate: query7.predicate)!,
                             realm.objects(T7.self).filter(query7.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query8.className, predicate: query8.predicate)!,
                             realm.objects(T8.self).filter(query8.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query9.className, predicate: query9.predicate)!,
                             realm.objects(T9.self).filter(query9.predicate)))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query3: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query4: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query5: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query6: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query7: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query8: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query9: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query10: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable, T3: RealmFetchable, T4: RealmFetchable, T5: RealmFetchable, T6: RealmFetchable, T7: RealmFetchable, T8: RealmFetchable, T9: RealmFetchable, T10: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>, _ query3: QuerySubscription<T3>, _ query4: QuerySubscription<T4>, _ query5: QuerySubscription<T5>, _ query6: QuerySubscription<T6>, _ query7: QuerySubscription<T7>, _ query8: QuerySubscription<T8>, _ query9: QuerySubscription<T9>, _ query10: QuerySubscription<T10>) async throws -> (QueryResults<T1>, QueryResults<T2>, QueryResults<T3>, QueryResults<T4>, QueryResults<T5>, QueryResults<T6>, QueryResults<T7>, QueryResults<T8>, QueryResults<T9>, QueryResults<T10>) {
        try await subscribe(query, query2, query3, query4, query5, query6, query7, query8, query9, query10)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query3.className, predicate: query3.predicate)!,
                             realm.objects(T3.self).filter(query3.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query4.className, predicate: query4.predicate)!,
                             realm.objects(T4.self).filter(query4.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query5.className, predicate: query5.predicate)!,
                             realm.objects(T5.self).filter(query5.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query6.className, predicate: query6.predicate)!,
                             realm.objects(T6.self).filter(query6.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query7.className, predicate: query7.predicate)!,
                             realm.objects(T7.self).filter(query7.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query8.className, predicate: query8.predicate)!,
                             realm.objects(T8.self).filter(query8.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query9.className, predicate: query9.predicate)!,
                             realm.objects(T9.self).filter(query9.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query10.className, predicate: query10.predicate)!,
                             realm.objects(T10.self).filter(query10.predicate)))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query3: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query4: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query5: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query6: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query7: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query8: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query9: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query10: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query11: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable, T3: RealmFetchable, T4: RealmFetchable, T5: RealmFetchable, T6: RealmFetchable, T7: RealmFetchable, T8: RealmFetchable, T9: RealmFetchable, T10: RealmFetchable, T11: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>, _ query3: QuerySubscription<T3>, _ query4: QuerySubscription<T4>, _ query5: QuerySubscription<T5>, _ query6: QuerySubscription<T6>, _ query7: QuerySubscription<T7>, _ query8: QuerySubscription<T8>, _ query9: QuerySubscription<T9>, _ query10: QuerySubscription<T10>, _ query11: QuerySubscription<T11>) async throws -> (QueryResults<T1>, QueryResults<T2>, QueryResults<T3>, QueryResults<T4>, QueryResults<T5>, QueryResults<T6>, QueryResults<T7>, QueryResults<T8>, QueryResults<T9>, QueryResults<T10>, QueryResults<T11>) {
        try await subscribe(query, query2, query3, query4, query5, query6, query7, query8, query9, query10, query11)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query3.className, predicate: query3.predicate)!,
                             realm.objects(T3.self).filter(query3.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query4.className, predicate: query4.predicate)!,
                             realm.objects(T4.self).filter(query4.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query5.className, predicate: query5.predicate)!,
                             realm.objects(T5.self).filter(query5.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query6.className, predicate: query6.predicate)!,
                             realm.objects(T6.self).filter(query6.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query7.className, predicate: query7.predicate)!,
                             realm.objects(T7.self).filter(query7.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query8.className, predicate: query8.predicate)!,
                             realm.objects(T8.self).filter(query8.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query9.className, predicate: query9.predicate)!,
                             realm.objects(T9.self).filter(query9.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query10.className, predicate: query10.predicate)!,
                             realm.objects(T10.self).filter(query10.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query11.className, predicate: query11.predicate)!,
                             realm.objects(T11.self).filter(query11.predicate)))
    }

    /**
     Appends the query to the current subscription set and wait for the server to acknowledge the subscription,
     returns a tuple of `QueryResults`s containing all the data associated to this queries.

     - parameter query: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query2: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query3: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query4: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query5: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query6: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query7: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query8: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query9: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query10: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query11: A `QuerySubscription` representing the query which will be used for the subscription.
     - parameter query12: A `QuerySubscription` representing the query which will be used for the subscription.
     - returns: A tuple of `QueryResults`s for the given subscriptions containing the data for each query.

     - throws: An `NSError` if the subscription couldn't be completed by the client or server.
     */
    @MainActor
    public func subscribe<T1: RealmFetchable, T2: RealmFetchable, T3: RealmFetchable, T4: RealmFetchable, T5: RealmFetchable, T6: RealmFetchable, T7: RealmFetchable, T8: RealmFetchable, T9: RealmFetchable, T10: RealmFetchable, T11: RealmFetchable, T12: RealmFetchable>(to query: QuerySubscription<T1>, _ query2: QuerySubscription<T2>, _ query3: QuerySubscription<T3>, _ query4: QuerySubscription<T4>, _ query5: QuerySubscription<T5>, _ query6: QuerySubscription<T6>, _ query7: QuerySubscription<T7>, _ query8: QuerySubscription<T8>, _ query9: QuerySubscription<T9>, _ query10: QuerySubscription<T10>, _ query11: QuerySubscription<T11>, _ query12: QuerySubscription<T12>) async throws -> (QueryResults<T1>, QueryResults<T2>, QueryResults<T3>, QueryResults<T4>, QueryResults<T5>, QueryResults<T6>, QueryResults<T7>, QueryResults<T8>, QueryResults<T9>, QueryResults<T10>, QueryResults<T11>, QueryResults<T12>) {
        try await subscribe(query, query2, query3, query4, query5, query6, query7, query8, query9, query10, query11, query12)
        return (QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query.className, predicate: query.predicate)!,
                             realm.objects(T1.self).filter(query.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query2.className, predicate: query2.predicate)!,
                             realm.objects(T2.self).filter(query2.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query3.className, predicate: query3.predicate)!,
                             realm.objects(T3.self).filter(query3.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query4.className, predicate: query4.predicate)!,
                             realm.objects(T4.self).filter(query4.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query5.className, predicate: query5.predicate)!,
                             realm.objects(T5.self).filter(query5.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query6.className, predicate: query6.predicate)!,
                             realm.objects(T6.self).filter(query6.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query7.className, predicate: query7.predicate)!,
                             realm.objects(T7.self).filter(query7.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query8.className, predicate: query8.predicate)!,
                             realm.objects(T8.self).filter(query8.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query9.className, predicate: query9.predicate)!,
                             realm.objects(T9.self).filter(query9.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query10.className, predicate: query10.predicate)!,
                             realm.objects(T10.self).filter(query10.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query11.className, predicate: query11.predicate)!,
                             realm.objects(T11.self).filter(query11.predicate)),
                QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: query12.className, predicate: query12.predicate)!,
                             realm.objects(T12.self).filter(query12.predicate)))
    }

    /**
     Removes all subscriptions from the subscription set.
     */
    public func unsubscribeAll() async throws {
        try await update {
            rlmSyncSubscriptionSet.removeAllSubscriptions()
        }
    }

    /**
     Removes zero or none subscriptions of the given type from the subscription set.

     - parameter type: The type of the subscriptions to be removed.
     */
    public func unsubscribeAll<T: Object>(ofType type: T.Type) async throws {
        try await update {
            rlmSyncSubscriptionSet.removeAllSubscriptions(withClassName: type.className())
        }
    }
}
#endif // canImport(_Concurrency)

extension User {
    /**
     Return a `Realm` for the given configuration and injects the sync configuration associated to a flexible sync session.

     - parameter configuration: The configuration for the realm. This can be used if any custom configuration is needed.

     - returns: A `Realm`.
     */
    public func realm(configuration: Realm.Configuration = Realm.Configuration()) throws -> Realm {
        return try Realm(configuration: flexibleSyncConfiguration(configuration))
    }

    /**
     Create a flexible sync configuration instance, which can be used to open a realm  which
     supports flexible sync.

     It won't be possible to combine flexible and partition sync in the same app, which means if you open
     a realm with a flexible sync configuration, you won't be able to open a realm with a PBS configuration
     and the other way around.

     - parameter configuration: The configuration for the realm. This can be used if any custom configuration is needed.

     - returns: A `Realm.Configuration` instance with a flexible sync configuration.
     */
    public func flexibleSyncConfiguration(_ configuration: Realm.Configuration = Realm.Configuration()) -> Realm.Configuration {
        let config = configuration.rlmConfiguration
        config.syncConfiguration = self.__flexibleSyncConfiguration().syncConfiguration
        return ObjectiveCSupport.convert(object: config)
    }
}
