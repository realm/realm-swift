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

public protocol SyncSubscription {
    associatedtype Element: Object

    var results: Results<Element> { get }
    var _rlmSyncSubscription: RLMSyncSubscription { get }
    init(_ rlmSyncSubscription: RLMSyncSubscription, results: Results<Element>)
}

extension SyncSubscription {
    public var realm: Realm? {
        results.realm
    }

    public var isInvalidated: Bool {
        results.isInvalidated
    }

    public func objects(at indexes: IndexSet) -> [Element] {
        results.objects(at: indexes)
    }

    public func distinct<S>(by keyPaths: S) -> Results<Element> where S : Sequence, S.Element == String {
        results.distinct(by: keyPaths)
    }

    public func sum<T>(ofProperty property: String) -> T where T : _HasPersistedType, T.PersistedType : AddableType {
        results.sum(ofProperty: property)
    }

    public func average<T>(ofProperty property: String) -> T? where T : _HasPersistedType, T.PersistedType : AddableType {
        results.average(ofProperty: property)
    }

    public func value(forKey key: String) -> Any? {
        results.value(forKey: key)
    }

    public func value(forKeyPath keyPath: String) -> Any? {
        results.value(forKeyPath: keyPath)
    }

    public func setValue(_ value: Any?, forKey key: String) {
        results.setValue(value, forKey: key)
    }

    public var isFrozen: Bool {
        results.isFrozen
    }

    public func freeze() -> Self {
        Self.init(_rlmSyncSubscription, results: results.freeze())
    }

    public func thaw() -> Self? {
        guard let results = results.thaw() else { return nil }
        return Self.init(_rlmSyncSubscription, results: results)
    }

    // MARK: Object Retrieval
    /**
     Returns the object at the given `index`.
     - parameter index: The index.
     */
    public subscript(position: Int) -> Element {
        results[position]
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

     - parameter type: The type of the object to be queried.
     - parameter query: A query which will be used to modify the query.
     */
    public func update(to query: @escaping (Query<Element>) -> Query<Bool>) {
        _rlmSyncSubscription.update(with: query(Query()).predicate)
    }

    public mutating func unsubscribe() {
        // STUB
    }
    /**
     Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
     from the server when committed.

     - warning: This method may only be called during a write subscription block.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments,
                                  which will be used to modify the query.
     */
    public func update(to predicateFormat: String, _ args: Any...) {
        _rlmSyncSubscription.update(with: NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args)))
    }

    /**
     Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
     from the server when committed.

     - warning: This method may only be called during a write subscription block.

     - parameter predicate: The predicate with which to filter the objects on the server, which
                            will be used to modify the query.
     */
    public func update(to predicate: NSPredicate) {
        _rlmSyncSubscription.update(with: predicate)
    }

    public func index(matching predicate: NSPredicate) -> Int? {
        results.index(matching: predicate)
    }

    public func filter(_ predicate: NSPredicate) -> Results<Element> {
        results.filter(predicate)
    }
    public func sorted<S>(by sortDescriptors: S) -> Results<Element> where S : Sequence, S.Element == SortDescriptor {
        results.sorted(by: sortDescriptors)
    }
    public func min<T>(ofProperty property: String) -> T? where T : _HasPersistedType, T.PersistedType : MinMaxType {
        results.min(ofProperty: property)
    }
    public func max<T>(ofProperty property: String) -> T? where T : _HasPersistedType, T.PersistedType : MinMaxType {
        results.max(ofProperty: property)
    }

}

public struct AnyQueryResults: SyncSubscription, Sequence {
    public func makeIterator() -> Results<Element>.Iterator {
        results.makeIterator()
    }

    public init(_ rlmSyncSubscription: RLMSyncSubscription, results: Results<DynamicObject>) {
        self._rlmSyncSubscription = rlmSyncSubscription
        self.results = results
    }

    public var results: Results<DynamicObject>

    public var _rlmSyncSubscription: RLMSyncSubscription

    public var description: String = ""

    public typealias Element = DynamicObject

    func `as`<T: Object>(type: T) {

    }
}

/**
 `SyncSubscription` is  used to define a Flexible Sync subscription obtained from querying a
 subscription set, which can be used to read or remove/update a committed subscription.
 */
@frozen public struct QueryResults<Element: Object>: SyncSubscription, Sequence {
    public func makeIterator() -> Results<Element>.Iterator {
        results.makeIterator()
    }
    public var description: String = ""


    // MARK: Initializers
    public let _rlmSyncSubscription: RLMSyncSubscription
    public let results: Results<Element>

    public init(_ rlmSyncSubscription: RLMSyncSubscription, results: Results<Element>) {
        self._rlmSyncSubscription = rlmSyncSubscription
        self.results = results
    }

    // MARK: Object Retrieval
    /**
     Returns the object at the given `index`.
     - parameter index: The index.
     */
    public subscript(position: Int) -> Element {
        results[position]
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

     - parameter type: The type of the object to be queried.
     - parameter query: A query which will be used to modify the query.
     */
    public func update(to query: @escaping (Query<Element>) -> Query<Bool>) {
        _rlmSyncSubscription.update(with: query(Query()).predicate)
    }

    public func unsubscribe(_ block: () -> ()) {
        // STUB
    }
    /**
     Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
     from the server when committed.

     - warning: This method may only be called during a write subscription block.
     
     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments,
                                  which will be used to modify the query.
     */
    public func update(to predicateFormat: String, _ args: Any...) {
        _rlmSyncSubscription.update(with: NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args)))
    }

    /**
     Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
     from the server when committed.

     - warning: This method may only be called during a write subscription block.

     - parameter predicate: The predicate with which to filter the objects on the server, which
                            will be used to modify the query.
     */
    public func update(to predicate: NSPredicate) {
        _rlmSyncSubscription.update(with: predicate)
    }

    public func write(_ block: () -> ()) throws {
        try realm!.write {
            block()
        }
    }

    public func append<T: Object>(_ object: T) {
        realm!.add(object)
    }

    public func remove<T: Object>(_ object: T) {
        realm!.delete(object)
    }
}

/**
 `SubscriptionQuery` is  used to define an named/unnamed query subscription query, which
 can be added/remove or updated within a write subscription transaction.
 */
@frozen public struct QuerySubscription<T: Object> {
    // MARK: Internal
    fileprivate let name: String?
    fileprivate var className: String
    fileprivate var predicate: NSPredicate

    /// :nodoc:
    public typealias QueryFunction = (Query<T>) -> Query<Bool>

    /**
     Creates a `QuerySubscription` for the given type.

     - parameter name: Name of the subscription.
     - parameter query: The query for the subscription.
     */
    public init(name: String? = nil, query: @escaping QueryFunction) {
        self.name = name
        self.className = "\(T.self)"
        self.predicate = query(Query()).predicate
    }

    /**
     Creates a `QuerySubscription` for the given type.

     - parameter name: Name of the subscription.
     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments,
                                  which will be used to create the subscription.
     */
    public init(name: String? = nil, where predicateFormat: String, _ args: Any...) {
        self.name = name
        self.className = "\(T.self)"
        self.predicate = NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args))
    }

    /**
     Creates a `QuerySubscription` for the given type.

     - parameter name: Name of the subscription.
     - parameter predicate: The predicate defining the query used to filter the objects on the server..
     */
    public init(name: String? = nil, where predicate: NSPredicate) {
        self.name = name
        self.className = "\(T.self)"
        self.predicate = predicate
    }
}

/**
 `SyncSubscriptionSet` is  a collection of `SyncSubscription`s. This is the entry point
 for adding and removing `SyncSubscription`s.
 */
@frozen public struct SyncSubscriptionSet {
    // MARK: Internal

    internal let rlmSyncSubscriptionSet: RLMSyncSubscriptionSet
    private let realm: Realm

    // MARK: Initializers

    public init(configuration: Realm.Configuration) throws {
        self.realm = try Realm(configuration: configuration)
        self.rlmSyncSubscriptionSet = realm.rlmRealm.subscriptions
    }

    internal init(_ rlmSyncSubscriptionSet: RLMSyncSubscriptionSet, realm: Realm) {
        self.rlmSyncSubscriptionSet = rlmSyncSubscriptionSet
        self.realm = realm
    }

    /// The number of subscriptions in the subscription set.
    public var count: Int { return Int(rlmSyncSubscriptionSet.count) }

    /**
     Synchronously performs any transactions (add/remove/update) to the subscription set within the block.
     This will not wait for the server to acknowledge and see all the data associated with this collection of subscriptions,
     and will return after committing the subscription transactions.

     - parameter block:      The block containing the subscriptions transactions to perform.
     - parameter onComplete: The block called upon synchronization of subscriptions to the server. Otherwise
                             an `Error`describing what went wrong will be returned by the block
     */
    public func write(_ block: (() -> Void), onComplete: ((Error?) -> Void)? = nil) {
        rlmSyncSubscriptionSet.write(block, onComplete: onComplete ?? { _ in })
    }

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
     Returns a subscription by the specified name.

     - parameter named: The name of the subscription searching for.
     - returns: A subscription for the given name.
     */
    public func first(named: String) -> AnyQueryResults? {
        return rlmSyncSubscriptionSet.subscription(withName: named).map {
            AnyQueryResults($0, results: realm.dynamicObjects($0.objectClassName))
        }
    }

    /**
     Returns a subscription by the specified query.

     - parameter type: The type of the object to be queried.
     - parameter where: A query builder that produces a subscription which can be used to search
                        the subscription by query and/or name.
     - returns: A query builder that produces a subscription which can used to search for the subscription.
     */
    public func first<T: Object>(ofType type: T.Type, `where` query: @escaping (Query<T>) -> Query<Bool>) -> QueryResults<T>? {
        return rlmSyncSubscriptionSet.subscription(withClassName: "\(T.self)", predicate: query(Query()).predicate).map {
            QueryResults($0, results: realm.objects(T.self))
        }
    }

    /**
     Returns a subscription by the specified query.

     - parameter type: The type of the object to be queried.
     - parameter where: A query builder that produces a subscription which can be used to search
                        the subscription by query and/or name.
     - returns: A query builder that produces a subscription which can used to search for the subscription.
     */
    public func first<T: Object>(ofType type: T.Type, `where` predicateFormat: String, _ args: Any...) -> QueryResults<T>? {
        return rlmSyncSubscriptionSet.subscription(withClassName: "\(T.self)", predicate: NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args))).map {
            QueryResults($0, results: realm.objects(T.self))
        }
    }

    /**
     Returns a subscription by the specified query.

     - parameter type: The type of the object to be queried.
     - parameter where: A query builder that produces a subscription which can be used to search
                        the subscription by query and/or name.
     - returns: A query builder that produces a subscription which can used to search for the subscription.
     */
    public func first<T: Object>(ofType type: T.Type, `where` predicate: NSPredicate) -> QueryResults<T>? {
        return rlmSyncSubscriptionSet.subscription(withClassName: "\(T.self)", predicate: predicate).map {
            QueryResults($0, results: realm.objects(T.self))
        }
    }

    /**
     Appends one or several subscriptions to the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter subscriptions: The subscriptions to be added to the subscription set.
     */
    public func `append`<T: Object>(_ subscriptions: QuerySubscription<T>...) {
        subscriptions.forEach { subscription in
            rlmSyncSubscriptionSet.addSubscription(withClassName: subscription.className,
                                                   subscriptionName: subscription.name,
                                                   predicate: subscription.predicate)
        }
    }

    public func subscribe<T: Object>(to query: @escaping (Query<T>) -> Query<Bool>) -> QueryResults<T> {
        let qs = QuerySubscription<T>(name: nil, query: query)
        rlmSyncSubscriptionSet.addSubscription(withClassName: qs.className, predicate: qs.predicate)
        return QueryResults(rlmSyncSubscriptionSet.subscription(withClassName: qs.className, predicate: qs.predicate)!,
                                   results: realm.objects(T.self))
    }

    /**
     Removes a subscription with the specified query.

     - warning: This method may only be called during a write subscription block.

     - parameter type: The type of the object to be removed.
     - parameter to: A query for the subscription to be removed from the subscription set.
     */
    public func remove<T: Object>(ofType type: T.Type, _ query: @escaping (Query<T>) -> Query<Bool>) {
        rlmSyncSubscriptionSet.removeSubscription(withClassName: "\(T.self)",
                                                  predicate: query(Query()).predicate)
    }

    /**
     Removes a subscription with the specified query.

     - warning: This method may only be called during a write subscription block.

     - parameter type: The type of the object to be removed.
     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments,
                                  which will be used to identify the subscription to be removed.
     */
    public func remove<T: Object>(ofType type: T.Type, where predicateFormat: String, _ args: Any...) {
        rlmSyncSubscriptionSet.removeSubscription(withClassName: "\(T.self)",
                                                  predicate: NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args)))
    }

    /**
     Removes a subscription with the specified query.

     - warning: This method may only be called during a write subscription block.

     - parameter type: The type of the object to be removed.
     - parameter predicate: The predicate which will be used to identify the subscription to be removed.
     */
    public func remove<T: Object>(ofType type: T.Type, where predicate: NSPredicate) {
        rlmSyncSubscriptionSet.removeSubscription(withClassName: "\(T.self)",
                                                  predicate: predicate)
    }

    /**
     Removes one or several subscriptions from the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter subscription: The subscription to be removed from the subscription set.
     */
    public func remove(_ subscriptions: AnyQueryResults...) {
        subscriptions.forEach { subscription in
            rlmSyncSubscriptionSet.remove(subscription._rlmSyncSubscription)
        }
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
     Returns the subscription at the given `position`.

     - parameter position: The index for the resulting subscription.
     */
    public subscript(position: Int) -> AnyQueryResults? {
        throwForNegativeIndex(position)
        return rlmSyncSubscriptionSet.object(at: UInt(position)).map {
            AnyQueryResults($0, results: realm.dynamicObjects($0.objectClassName))
        }
    }

    /// Returns the first object in the SyncSubscription list, or `nil` if the subscriptions are empty.
    public var first: AnyQueryResults? {
        return rlmSyncSubscriptionSet.firstObject().map {
            AnyQueryResults($0, results: realm.dynamicObjects($0.objectClassName))
        }
    }

    /// Returns the last object in the SyncSubscription list, or `nil` if the subscriptions are empty.
    public var last: AnyQueryResults? {
        return rlmSyncSubscriptionSet.lastObject().map {
            AnyQueryResults($0, results: realm.dynamicObjects($0.objectClassName))
        }
    }
}

extension SyncSubscriptionSet: Sequence {
    // MARK: Sequence Support

    /// Returns a `SyncSubscriptionSetIterator` that yields successive elements in the subscription collection.
    public func makeIterator() -> SyncSubscriptionSetIterator {
        return SyncSubscriptionSetIterator(rlmSyncSubscriptionSet)
    }
}

/**
 This struct enables sequence-style enumeration for `SyncSubscriptionSet`.
 */
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

#if swift(>=5.6) && canImport(_Concurrency)
@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
extension SyncSubscriptionSet {
    /**
     Asynchronously creates and commit a write transaction and updates the subscription set,
     this will not wait for the server to acknowledge and see all the data associated with this
     collection of subscription.

     - parameter block: The block containing the subscriptions transactions to perform.

     - throws: An `NSError` if the transaction could not be completed successfully.
               If `block` throws, the function throws the propagated `ErrorType` instead.
     */
    @MainActor
    public func write(_ block: (() -> Void)) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            write(block) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

@available(macOS 12.0, tvOS 15.0, iOS 15.0, watchOS 8.0, *)
extension QueryResults {
    public func unsubscribe() async throws {
        // STUB
    }
}

class Person: Object {
    @Persisted var name: String
    @Persisted var age: Int
}

// MARK: EXAMPLE

@available(macOSApplicationExtension 12.0, *)
public func show() async throws {
let app = App(id: "my-app-id")
let user = try await app.login(credentials: .anonymous)
let subscriptions = try SyncSubscriptionSet(configuration: user.flexibleSyncConfiguration())
let results: QueryResults<Person> = try await subscriptions.subscribe(to: { person in
    person.age > 18
})
results.forEach { person in
    print(person.name)
}
let newPerson = Person()
newPerson.age = 18
try results.write {
    results.append(newPerson)
}
try results.write {
    results.remove(newPerson)
}
try await results.unsubscribe()
}

#endif // swift(>=5.5)


