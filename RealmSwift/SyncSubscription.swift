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

/**
 `SyncSubscription` is  used to define a Flexible Sync subscription obtained from querying a
 subscription set, which can be used to read or remove/update a committed subscription.
 */
@usableFromInline
struct SyncSubscription {

    // MARK: Initializers
    fileprivate let _rlmSyncSubscription: RLMSyncSubscription

    fileprivate init(_ rlmSyncSubscription: RLMSyncSubscription) {
        self._rlmSyncSubscription = rlmSyncSubscription
    }

    /// Name of the subscription, if not specified it will return the value in Query as a String.
    var name: String? {
        _rlmSyncSubscription.name
    }

    /// When the subscription was created. Recorded automatically.
    var createdAt: Date {
        _rlmSyncSubscription.createdAt
    }

    /// When the subscription was last updated. Recorded automatically.
    var updatedAt: Date {
        _rlmSyncSubscription.updatedAt
    }
}

/**
 `SubscriptionQuery` is  used to define an named/unnamed query subscription query, which
 can be added/remove or updated within a write subscription transaction.
 */
struct QuerySubscription<T: RealmFetchable> {
    // MARK: Internal
    internal var className: String
    internal var predicate: NSPredicate

    /**
     Creates a `QuerySubscription` for the given type.

     - parameter query: The query for the subscription. if nil it will set the query to all documents for the collection.
     */
    init(_ query: ((Query<T>) -> Query<Bool>)? = nil) {
        self.className = "\(T.self)"
        self.predicate = query?(Query()).predicate ?? NSPredicate(format: "TRUEPREDICATE")
    }

    /**
     Creates a `QuerySubscription` for the given type.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments,
                                  which will be used to create the subscription.
     */
    init(_ predicateFormat: String, _ args: Any...) {
        self.className = "\(T.self)"
        self.predicate = NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args))
    }

    /**
     Creates a `QuerySubscription` for the given type.

     - parameter predicate: The predicate defining the query used to filter the objects on the server..
     */
    init(_ predicate: NSPredicate) {
        self.className = "\(T.self)"
        self.predicate = predicate
    }
}

/**
 `SyncSubscriptionSet` is  a collection of `SyncSubscription`s. This is the entry point
 for adding and removing `SyncSubscription`s.
 */
@frozen public struct SyncSubscriptionSet {
    internal let rlmSyncSubscriptionSet: RLMSyncSubscriptionSet

    // MARK: Initializers

    internal init(_ rlmSyncSubscriptionSet: RLMSyncSubscriptionSet) {
        self.rlmSyncSubscriptionSet = rlmSyncSubscriptionSet
    }

    /// The number of subscriptions in the subscription set.
    public var count: Int { return Int(rlmSyncSubscriptionSet.count) }

    // MARK: Internal

    /**
     Synchronously performs any transactions (add/remove/update) to the subscription set within the block.
     This will not wait for the server to acknowledge and see all the data associated with this collection of subscriptions,
     and will return after committing the subscription transactions.

     - parameter block:      The block containing the subscriptions transactions to perform.
     - parameter onComplete: The block called upon synchronization of subscriptions to the server. Otherwise
                             an `Error`describing what went wrong will be returned by the block
     */
    internal func update(_ block: (() -> Void), queue: DispatchQueue? = nil, onComplete: ((Error?) -> Void)? = nil) {
        rlmSyncSubscriptionSet.update(block, queue: queue, onComplete: onComplete ?? { _ in })
    }

    /// Returns the current state for the subscription set.
    internal var state: SyncSubscriptionState {
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
     Returns a subscription by the specified query.

     - parameter type: The type of the object to be queried.
     - parameter where: A query builder that produces a subscription which can be used to search
                        the subscription by query and/or name.
     - returns: A query builder that produces a subscription which can used to search for the subscription.
     */
    internal func first<T: RealmCollectionValue>(ofType type: T.Type, `where` predicate: NSPredicate) -> SyncSubscription? {
        return rlmSyncSubscriptionSet.subscription(withClassName: "\(T.self)", predicate: predicate).map(SyncSubscription.init)
    }

    /**
     Appends one or several subscriptions to the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter subscriptions: The subscriptions to be added to the subscription set.
     */
    internal func `append`<T: RealmFetchable>(_ subscriptions: QuerySubscription<T>...) {
        subscriptions.forEach { subscription in
            rlmSyncSubscriptionSet.addSubscription(withClassName: subscription.className,
                                                   predicate: subscription.predicate)
        }
    }

    /**
     Removes one or several subscriptions from the subscription set.

     - warning: This method may only be called during a write subscription block.

     - parameter subscription: The subscription to be removed from the subscription set.
     */
    internal func remove(_ subscriptions: SyncSubscription...) {
        subscriptions.forEach { subscription in
            rlmSyncSubscriptionSet.remove(subscription._rlmSyncSubscription)
        }
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
    internal func update(_ block: (() -> Void)) async throws {
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
#endif // swift(>=5.6)
