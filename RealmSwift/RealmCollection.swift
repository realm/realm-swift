////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

/**
 An iterator for a `RealmCollection` instance.
 */
@frozen public struct RLMIterator<Element: RealmCollectionValue>: IteratorProtocol {
    private var generatorBase: NSFastEnumerationIterator

    init(collection: RLMCollection) {
        generatorBase = NSFastEnumerationIterator(collection)
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public mutating func next() -> Element? {
        guard let next = generatorBase.next() else { return nil }
        return staticBridgeCast(fromObjectiveC: next) as Element
    }
}

/// :nodoc:
public protocol _RealmMapValue {
    /// The key of this element.
    associatedtype Key: _MapKey
    /// The value of this element.
    associatedtype Value: RealmCollectionValue
}

/**
 An iterator for a `RealmKeyedCollection` instance.
 */
@frozen public struct RLMMapIterator<Element: _RealmMapValue>: IteratorProtocol {
    private var generatorBase: NSFastEnumerationIterator
    private var collection: RLMDictionary<AnyObject, AnyObject>

    init(collection: RLMDictionary<AnyObject, AnyObject>) {
        self.collection = collection
        generatorBase = NSFastEnumerationIterator(collection)
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public mutating func next() -> Element? {
        let next = generatorBase.next()
        if let next = next as? Element.Key {
            let key: Element.Key = next
            let val: Element.Value = dynamicBridgeCast(fromObjectiveC: collection[key as AnyObject]!)
            return SingleMapEntry(key: key, value: val) as? Element
        }
        return nil
    }
}

/**
 An iterator for `Map<Key, Value>` which produces `(key: Key, value: Value)` pairs for each entry in the map.
 */
@frozen public struct RLMKeyValueIterator<Key: _MapKey, Value: RealmCollectionValue>: IteratorProtocol {
    private var generatorBase: NSFastEnumerationIterator
    private var collection: RLMDictionary<AnyObject, AnyObject>
    public typealias Element = (key: Key, value: Value)

    init(collection: RLMDictionary<AnyObject, AnyObject>) {
        self.collection = collection
        generatorBase = NSFastEnumerationIterator(collection)
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public mutating func next() -> Element? {
        let next = generatorBase.next()
        if let key = next as? Key,
           let value = collection[key as AnyObject].map(dynamicBridgeCast) as? Value {
            return (key: key, value: value)
        }
        return nil
    }
}

/**
 A `RealmCollectionChange` value encapsulates information about changes to collections
 that are reported by Realm notifications.

 The change information is available in two formats: a simple array of row
 indices in the collection for each type of change, and an array of index paths
 in a requested section suitable for passing directly to `UITableView`'s batch
 update methods.

 The arrays of indices in the `.update` case follow `UITableView`'s batching
 conventions, and can be passed as-is to a table view's batch update functions after being converted to index paths.
 For example, for a simple one-section table view, you can do the following:

 ```swift
 self.notificationToken = results.observe { changes in
     switch changes {
     case .initial:
         // Results are now populated and can be accessed without blocking the UI
         self.tableView.reloadData()
         break
     case .update(_, let deletions, let insertions, let modifications):
         // Query results have changed, so apply them to the TableView
         self.tableView.beginUpdates()
         self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) },
            with: .automatic)
         self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) },
            with: .automatic)
         self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) },
            with: .automatic)
         self.tableView.endUpdates()
         break
     case .error(let err):
         // An error occurred while opening the Realm file on the background worker thread
         fatalError("\(err)")
         break
     }
 }
 ```
 */
@frozen public enum RealmCollectionChange<CollectionType> {
    /**
     `.initial` indicates that the initial run of the query has completed (if
     applicable), and the collection can now be used without performing any
     blocking work.
     */
    case initial(CollectionType)

    /**
     `.update` indicates that a write transaction has been committed which
     either changed which objects are in the collection, and/or modified one
     or more of the objects in the collection.

     All three of the change arrays are always sorted in ascending order.

     - parameter deletions:     The indices in the previous version of the collection which were removed from this one.
     - parameter insertions:    The indices in the new collection which were added in this version.
     - parameter modifications: The indices of the objects which were modified in the previous version of this collection.
     */
    case update(CollectionType, deletions: [Int], insertions: [Int], modifications: [Int])

    /**
     Errors can no longer occur. This case is unused and will be removed in the
     next major version.
     */
    case error(Error)

    init(value: CollectionType?, change: RLMCollectionChange?, error: Error?) {
        if let error = error {
            self = .error(error)
        } else if let change = change {
            self = .update(value!,
                deletions: forceCast(change.deletions, to: [Int].self),
                insertions: forceCast(change.insertions, to: [Int].self),
                modifications: forceCast(change.modifications, to: [Int].self))
        } else {
            self = .initial(value!)
        }
    }
}

private func forceCast<A, U>(_ from: A, to type: U.Type) -> U {
    return from as! U
}

/// A type which can be stored in a Realm List, MutableSet, Map, or Results.
///
/// Declaring additional types as conforming to this protocol will not make them
/// actually work. Most of the logic for how to store values in Realm is not
/// implemented in Swift and there is currently no extension mechanism for
/// supporting more types.
public protocol RealmCollectionValue: Hashable, _HasPersistedType where PersistedType: RealmCollectionValue {
    // Get the zero/empty/nil value for this type. Used to supply a default
    // when the user does not declare one in their model.
    /// :nodoc:
    static func _rlmDefaultValue() -> Self
}


///  A type which can appear in a Realm collection inside an Optional.
///
/// :nodoc:
public protocol _RealmCollectionValueInsideOptional: RealmCollectionValue where PersistedType: _RealmCollectionValueInsideOptional {}

extension Int: _RealmCollectionValueInsideOptional {}
extension Int8: _RealmCollectionValueInsideOptional {}
extension Int16: _RealmCollectionValueInsideOptional {}
extension Int32: _RealmCollectionValueInsideOptional {}
extension Int64: _RealmCollectionValueInsideOptional {}
extension Float: _RealmCollectionValueInsideOptional {}
extension Double: _RealmCollectionValueInsideOptional {}
extension Bool: _RealmCollectionValueInsideOptional {}
extension String: _RealmCollectionValueInsideOptional {}
extension Date: _RealmCollectionValueInsideOptional {}
extension Data: _RealmCollectionValueInsideOptional {}
extension Decimal128: _RealmCollectionValueInsideOptional {}
extension ObjectId: _RealmCollectionValueInsideOptional {}
extension UUID: _RealmCollectionValueInsideOptional {}
extension AnyRealmValue: RealmCollectionValue {}
extension Optional: RealmCollectionValue where Wrapped: _RealmCollectionValueInsideOptional {
    public static func _rlmDefaultValue() -> Self {
        return .none
    }
}

/// :nodoc:
public protocol RealmCollectionBase: RandomAccessCollection, LazyCollectionProtocol, CustomStringConvertible, ThreadConfined where Element: RealmCollectionValue {
    // This typealias was needed with Swift 3.1. It no longer is, but remains
    // just in case someone was depending on it
    typealias ElementType = Element
}

// MARK: - RealmCollection protocol

/**
 A homogenous collection of `Object`s which can be retrieved, filtered, sorted, and operated upon.
*/
public protocol RealmCollection: RealmCollectionBase, Equatable where Iterator == RLMIterator<Element> {
    // MARK: Properties

    /// The Realm which manages the collection, or `nil` for unmanaged collections.
    var realm: Realm? { get }

    /**
     Indicates if the collection can no longer be accessed.

     The collection can no longer be accessed if `invalidate()` is called on the `Realm` that manages the collection.
     */
    var isInvalidated: Bool { get }

    /// The number of objects in the collection.
    var count: Int { get }

    /// A human-readable description of the objects contained in the collection.
    var description: String { get }

    // MARK: Object Retrieval

    /// Returns the first object in the collection, or `nil` if the collection is empty.
    var first: Element? { get }

    /// Returns the last object in the collection, or `nil` if the collection is empty.
    var last: Element? { get }

    // MARK: Index Retrieval

    /**
     Returns the index of an object in the collection, or `nil` if the object is not present.

     - parameter object: An object.
     */
    func index(of object: Element) -> Int?

    /**
     Returns the index of the first object matching the predicate, or `nil` if no objects match.

     This is only applicable to ordered collections, and will abort if the collection is unordered.

     - parameter predicate: The predicate to use to filter the objects.
     */
    func index(matching predicate: NSPredicate) -> Int?

    /**
     Returns the index of the first object matching the predicate, or `nil` if no objects match.

     This is only applicable to ordered collections, and will abort if the collection is unordered.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.
     */
    func index(matching predicateFormat: String, _ args: Any...) -> Int?

    // MARK: Object Retrieval

    /**
     Returns an array containing the objects in the collection at the indexes specified by a given index set.

     - warning: Throws if an index supplied in the IndexSet is out of bounds.

     - parameter indexes: The indexes in the collection to select objects from.
     */
    func objects(at indexes: IndexSet) -> [Element]

    // MARK: Filtering

    /**
     Returns a `Results` containing all objects matching the given predicate in the collection.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.
     */
    func filter(_ predicateFormat: String, _ args: Any...) -> Results<Element>

    /**
     Returns a `Results` containing all objects matching the given predicate in the collection.

     - parameter predicate: The predicate to use to filter the objects.
     */
    func filter(_ predicate: NSPredicate) -> Results<Element>

    // MARK: Sorting

    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     - warning: Collections may only be sorted by properties of boolean, `Date`, `NSDate`, single and double-precision
                floating point, integer, and string types.

     - see: `sorted(byKeyPath:ascending:)`

     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     */
    func sorted<S: Sequence>(by sortDescriptors: S) -> Results<Element> where S.Iterator.Element == SortDescriptor

    /**
     Returns a `Results` containing distinct objects based on the specified key paths.

     - parameter keyPaths:  The key paths to distinct on.
     */
    func distinct<S: Sequence>(by keyPaths: S) -> Results<Element> where S.Iterator.Element == String

    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects in the collection, or `nil` if the
     collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    func min<T: _HasPersistedType>(ofProperty property: String) -> T? where T.PersistedType: MinMaxType

    /**
     Returns the maximum (highest) value of the given property among all the objects in the collection, or `nil` if the
     collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    func max<T: _HasPersistedType>(ofProperty property: String) -> T? where T.PersistedType: MinMaxType

    /**
    Returns the sum of the given property for objects in the collection, or `nil` if the collection is empty.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.
    */
    func sum<T: _HasPersistedType>(ofProperty property: String) -> T where T.PersistedType: AddableType

    /**
     Returns the average value of a given property over all the objects in the collection, or `nil` if
     the collection is empty.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.
     */
    func average<T: _HasPersistedType>(ofProperty property: String) -> T? where T.PersistedType: AddableType

    // MARK: Key-Value Coding

    /**
     Returns an `Array` containing the results of invoking `valueForKey(_:)` with `key` on each of the collection's
     objects.

     - parameter key: The name of the property whose values are desired.
     */
    func value(forKey key: String) -> Any?

    /**
     Returns an `Array` containing the results of invoking `valueForKeyPath(_:)` with `keyPath` on each of the
     collection's objects.

     - parameter keyPath: The key path to the property whose values are desired.
     */
    func value(forKeyPath keyPath: String) -> Any?

    /**
     Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified `value` and `key`.

     - warning: This method may only be called during a write transaction.

     - parameter value: The object value.
     - parameter key:   The name of the property whose value should be set on each object.
     */
    func setValue(_ value: Any?, forKey key: String)

    // MARK: Notifications

    /**
     Registers a block to be called each time the collection changes.

     The block will be asynchronously called with the initial results, and then called again after each write
     transaction which changes either any of the objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmCollectionChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     let dogs = realm.objects(Dog.self)
     print("dogs.count: \(dogs?.count)") // => 0
     let token = dogs.observe { changes in
         switch changes {
         case .initial(let dogs):
             // Will print "dogs.count: 1"
             print("dogs.count: \(dogs.count)")
             break
         case .update:
             // Will not be hit in this example
             break
         case .error:
             break
         }
     }
     try! realm.write {
         let dog = Dog()
         dog.name = "Rex"
         person.dogs.append(dog)
     }
     // end of run loop execution context
     ```

     If no key paths are given, the block will be executed on any insertion,
     modification, or deletion for all object properties and the properties of
     any nested, linked objects. If a key path or key paths are provided,
     then the block will be called for changes which occur only on the
     provided key paths. For example, if:
     ```swift
     class Dog: Object {
         @Persisted var name: String
         @Persisted var age: Int
         @Persisted var toys: List<Toy>
     }
     // ...
     let dogs = realm.objects(Dog.self)

     let token = dogs.observe(keyPaths: ["name"]) { changes in
         switch changes {
         case .initial(let dogs):
            // ...
         case .update:
            // This case is hit:
            // - after the token is initialized
            // - when the name property of an object in the
            // collection is modified
            // - when an element is inserted or removed
            //   from the collection.
            // This block is not triggered:
            // - when a value other than name is modified on
            //   one of the elements.
         case .error:
             // ...
         }
     }
     // end of run loop execution context
     ```
     - If the observed key path were `["toys.brand"]`, then any insertion or
     deletion to the `toys` list on any of the collection's elements would trigger the block.
     Changes to the `brand` value on any `Toy` that is linked to a `Dog` in this
     collection will trigger the block. Changes to a value other than `brand` on any `Toy` that
     is linked to a `Dog` in this collection would not trigger the block.
     Any insertion or removal to the `Dog` type collection being observed
     would also trigger a notification.
     - If the above example observed the `["toys"]` key path, then any insertion,
     deletion, or modification to the `toys` list for any element in the collection
     would trigger the block.
     Changes to any value on any `Toy` that is linked to a `Dog` in this collection
     would *not* trigger the block.
     Any insertion or removal to the `Dog` type collection being observed
     would still trigger a notification.

     - note: Multiple notification tokens on the same object which filter for
     separate key paths *do not* filter exclusively. If one key path
     change is satisfied for one notification token, then all notification
     token blocks for that object will execute.

     You must retain the returned token for as long as you want updates to be sent to the block. To stop receiving
     updates, call `invalidate()` on the token.

     - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

     - parameter keyPaths: Only properties contained in the key paths array will trigger
                           the block when they are modified. If `nil`, notifications
                           will be delivered for any property change on the object.
                           String key paths which do not correspond to a valid a property
                           will throw an exception. See description above for
                           more detail on linked properties.
     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    func observe(keyPaths: [String]?,
                 on queue: DispatchQueue?,
                 _ block: @escaping (RealmCollectionChange<Self>) -> Void) -> NotificationToken

#if swift(>=5.8)
    /**
    Registers a block to be called each time the collection changes.

    The block will be asynchronously called with an initial version of the
    collection, and then called again after each write transaction which changes
    either any of the objects in the collection, or which objects are in the
    collection.

    The `actor` parameter passed to the block is the actor which you pass to this
    function. This parameter is required to isolate the callback to the actor.

    The `change` parameter that is passed to the block reports, in the form of
    indices within the collection, which of the objects were added, removed, or
    modified after the previous notification. The `collection` field in the change
    enum will be isolated to the requested actor, and is safe to use within that
    actor only. See the ``RealmCollectionChange`` documentation for more
    information on the change information supplied and an example of how to use it
    to update a `UITableView`.

    Once the initial notification is delivered, the collection will be fully
    evaluated and up-to-date, and accessing it will never perform any blocking
    work. This guarantee holds only as long as you do not perform a write
    transaction on the same actor as notifications are being delivered to. If you
    do, accessing the collection before the next notification is delivered may need
    to rerun the query.

    Notifications are delivered to the given actor's executor. When notifications
    can't be delivered instantly, multiple notifications may be coalesced into a
    single notification. This can include the notification with the initial
    collection: any writes which occur before the initial notification is delivered
    may not produce change notifications.

    Adding, removing or assigning objects in the collection always produces a
    notification. By default, modifying the objects which a collection links to
    (and the objects which those objects link to, if applicable) will also report
    that index in the collection as being modified. If a non-empty array of
    keypaths is provided, then only modifications to those keypaths will mark the
    object as modified. For example:

    ```swift
    class Dog: Object {
        @Persisted var name: String
        @Persisted var age: Int
        @Persisted var toys: List<Toy>
    }

    let dogs = realm.objects(Dog.self)
    let token = await dogs.observe(keyPaths: ["name"], on: myActor) { actor, changes in
        switch changes {
        case .initial(let dogs):
            // Query has finished running and dogs can not be used without blocking
        case .update:
            // This case is hit:
            // - after the token is initialized
            // - when the name property of an object in the collection is modified
            // - when an element is inserted or removed from the collection.
            // This block is not triggered:
            // - when a value other than name is modified on one of the elements.
        case .error:
            // Can no longer happen but is left for backwards compatiblity
        }
    }
    ```
    - If the observed key path were `["toys.brand"]`, then any insertion or
      deletion to the `toys` list on any of the collection's elements would trigger
      the block. Changes to the `brand` value on any `Toy` that is linked to a `Dog`
      in this collection will trigger the block. Changes to a value other than
      `brand` on any `Toy` that is linked to a `Dog` in this collection would not
      trigger the block. Any insertion or removal to the `Dog` type collection being
      observed would also trigger a notification.
    - If the above example observed the `["toys"]` key path, then any insertion,
      deletion, or modification to the `toys` list for any element in the collection
      would trigger the block. Changes to any value on any `Toy` that is linked to a
      `Dog` in this collection would *not* trigger the block. Any insertion or
      removal to the `Dog` type collection being observed would still trigger a
      notification.

    You must retain the returned token for as long as you want updates to be sent
    to the block. To stop receiving updates, call `invalidate()` on the token.

    - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

    - parameter keyPaths: Only properties contained in the key paths array will trigger
                       the block when they are modified. If `nil` or empty, notifications
                       will be delivered for any property change on the object.
                       String key paths which do not correspond to a valid a property
                       will throw an exception. See description above for
                       more detail on linked properties.
    - parameter actor: The actor to isolate the notifications to.
    - parameter block: The block to be called whenever a change occurs.
    - returns: A token which must be held for as long as you want updates to be delivered.
    */
    @available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
    @_unsafeInheritExecutor
    func observe<A: Actor>(keyPaths: [String]?,
                           on actor: A,
                           _ block: @Sendable @escaping (isolated A, RealmCollectionChange<Self>) -> Void) async -> NotificationToken
#endif

    // MARK: Frozen Objects

    /// Returns true if this collection is frozen
    var isFrozen: Bool { get }

    /**
     Returns a frozen (immutable) snapshot of this collection.

     The frozen copy is an immutable collection which contains the same data as this collection
    currently contains, but will not update when writes are made to the containing Realm. Unlike
    live collections, frozen collections can be accessed from any thread.

     - warning: This method cannot be called during a write transaction, or when the containing
    Realm is read-only.
     - warning: Holding onto a frozen collection for an extended period while performing write
     transaction on the Realm may result in the Realm file growing to large sizes. See
     `Realm.Configuration.maximumNumberOfActiveVersions` for more information.
    */
    func freeze() -> Self

    /**
     Returns a live (mutable) version of this frozen collection.

     This method resolves a reference to a live copy of the same frozen collection.
     If called on a live collection, will return itself.
    */
    func thaw() -> Self?

    /**
     Sorts this collection from a given array of sort descriptors and performs sectioning via a
     user defined callback, returning the result as an instance of `SectionedResults`.

     - parameter sortDescriptors: An array of `SortDescriptor`s to sort by.
     - parameter keyBlock: A callback which is invoked on each element in the Results collection.
                           This callback is to return the section key for the element in the collection.

     - note: The primary sort descriptor must be responsible for determining the section key.

     - returns: An instance of `SectionedResults`.
     */
    func sectioned<Key: _Persistable>(sortDescriptors: [SortDescriptor],
                                      _ keyBlock: @escaping ((Element) -> Key)) -> SectionedResults<Key, Element>
}

// MARK: - Codable

extension RealmCollection where Element: Encodable {
    /// Encodes the contents of this collection into the given encoder.
    /// - parameter encoder The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for value in self {
            try container.encode(value)
        }
    }
}

// MARK: - Type-safe queries

public extension RealmCollection {
    /**
     Returns the index of the first object matching the query, or `nil` if no objects match.

     This is only applicable to ordered collections, and will abort if the collection is unordered.

     - Note: This should only be used with classes using the `@Persistable` property declaration.

     - Usage:
     ```
     obj.index(matching: { $0.fooCol < 456 })
     ```

     - Note: See ``Query`` for more information on what query operations are available.

     - parameter isIncluded: The query closure to use to filter the objects.
     */
    func index(matching isIncluded: ((Query<Element>) -> Query<Bool>)) -> Int? where Element: _RealmSchemaDiscoverable {
        let isPrimitive = Element._rlmType != .object
        return index(matching: isIncluded(Query<Element>(isPrimitive: isPrimitive)).predicate)
    }

    /**
     Returns a `Results` containing all objects matching the given query in the collection.

     - Note: This should only be used with classes using the `@Persistable` property declaration.

     - Usage:
     ```
     myCol.where {
        ($0.fooCol > 5) && ($0.barCol == "foobar")
     }
     ```

     - Note: See ``Query`` for more information on what query operations are available.

     - parameter isIncluded: The query closure to use to filter the objects.
     */
    func `where`(_ isIncluded: ((Query<Element>) -> Query<Bool>)) -> Results<Element> {
        return filter(isIncluded(Query()).predicate)
    }
}

// MARK: Collection protocol

public extension RealmCollection {
    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    var startIndex: Int { 0 }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    var endIndex: Int { count }

    /// Returns the position immediately after the given index.
    /// - parameter i: A valid index of the collection. `i` must be less than `endIndex`.
    func index(after i: Int) -> Int { return i + 1 }
    /// Returns the position immediately before the given index.
    /// - parameter i: A valid index of the collection. `i` must be greater than `startIndex`.
    func index(before i: Int) -> Int { return i - 1 }
}

// MARK: - Aggregation

/**
 Extension for RealmCollections where the Value is of an Object type that
 enables aggregatable operations.
 */
public extension RealmCollection where Element: ObjectBase {
    /**
     Returns the minimum (lowest) value of the given property among all the objects in the collection, or `nil` if the
     collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter keyPath: The keyPath of a property whose minimum value is desired.
     */
    func min<T: _HasPersistedType>(of keyPath: KeyPath<Element, T>) -> T? where T.PersistedType: MinMaxType {
        min(ofProperty: _name(for: keyPath))
    }

    /**
     Returns the maximum (highest) value of the given property among all the objects in the collection, or `nil` if the
     collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter keyPath: The keyPath of a property whose minimum value is desired.
     */
    func max<T: _HasPersistedType>(of keyPath: KeyPath<Element, T>) -> T? where T.PersistedType: MinMaxType {
        max(ofProperty: _name(for: keyPath))
    }

    /**
    Returns the sum of the given property for objects in the collection, or `nil` if the collection is empty.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter keyPath: The keyPath of a property conforming to `AddableType` to calculate sum on.
    */
    func sum<T: _HasPersistedType>(of keyPath: KeyPath<Element, T>) -> T where T.PersistedType: AddableType {
        sum(ofProperty: _name(for: keyPath))
    }

    /**
     Returns the average value of a given property over all the objects in the collection, or `nil` if
     the collection is empty.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter keyPath: The keyPath of a property whose values should be summed.
     */
    func average<T: _HasPersistedType>(of keyPath: KeyPath<Element, T>) -> T? where T.PersistedType: AddableType {
        average(ofProperty: _name(for: keyPath))
    }

    /**
     Sorts and sections this collection from a given property key path, returning the result
     as an instance of `SectionedResults`. For every unique value retrieved from the
     keyPath a section key will be generated.

     - parameter keyPath: The property key path to sort & section on.
     - parameter ascending: The direction to sort in.

     - returns: An instance of `SectionedResults`.
     */
    func sectioned<Key: _Persistable>(by keyPath: KeyPath<Element, Key>,
                                      ascending: Bool = true) -> SectionedResults<Key, Element> where Element: ObjectBase {
        return sectioned(sortDescriptors: [.init(keyPath: _name(for: keyPath), ascending: ascending)], {
            return $0[keyPath: keyPath]
        })
    }

    /**
     Sorts and sections this collection from a given property key path, returning the result
     as an instance of `SectionedResults`. For every unique value retrieved from the
     keyPath a section key will be generated.

     - parameter keyPath: The property key path to sort & section on.
     - parameter sortDescriptors: An array of `SortDescriptor`s to sort by.

     - note: The primary sort descriptor must be responsible for determining the section key.

     - returns: An instance of `SectionedResults`.
     */
    func sectioned<Key: _Persistable>(by keyPath: KeyPath<Element, Key>,
                                      sortDescriptors: [SortDescriptor]) -> SectionedResults<Key, Element> where Element: ObjectBase {
        guard let sortDescriptor = sortDescriptors.first else {
            throwRealmException("Can not section Results with empty sortDescriptor parameter.")
        }
        let keyPathString = _name(for: keyPath)
        if keyPathString != sortDescriptor.keyPath {
            throwRealmException("The section key path must match the primary sort descriptor.")
        }
        return sectioned(sortDescriptors: sortDescriptors, { $0[keyPath: keyPath] })
    }

    /**
     Sorts this collection from a given array of `SortDescriptor`'s and performs sectioning
     via a user defined callback function.

     - parameter block: A callback which is invoked on each element in the collection.
                        This callback is to return the section key for the element in the collection.
     - parameter sortDescriptors: An array of `SortDescriptor`s to sort by.

     - note: The primary sort descriptor must be responsible for determining the section key.

     - returns: An instance of `SectionedResults`.
     */
    func sectioned<Key: _Persistable>(by block: @escaping ((Element) -> Key),
                                      sortDescriptors: [SortDescriptor]) -> SectionedResults<Key, Element> where Element: ObjectBase {
        return sectioned(sortDescriptors: sortDescriptors, block)
    }
}

public extension RealmCollection where Element.PersistedType: MinMaxType {
    /**
     Returns the minimum (lowest) value of the collection, or `nil` if the collection is empty.
     */
    func min() -> Element? {
        return min(ofProperty: "self")
    }
    /**
     Returns the maximum (highest) value of the collection, or `nil` if the collection is empty.
     */
    func max() -> Element? {
        return max(ofProperty: "self")
    }
}

public extension RealmCollection where Element.PersistedType: AddableType {
    /**
     Returns the sum of the values in the collection, or `nil` if the collection is empty.
     */
    func sum() -> Element {
        return sum(ofProperty: "self")
    }
    /**
     Returns the average of all of the values in the collection.
     */
    func average<T: _HasPersistedType>() -> T? where T.PersistedType: AddableType {
        return average(ofProperty: "self")
    }
}

// MARK: Sort and distinct

/**
 Extension for RealmCollections where the Value is of an Object type that
 enables sortable operations.
 */
public extension RealmCollection where Element: KeypathSortable {
    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     Objects are sorted based on the values of the given key path. For example, to sort a collection of `Student`s from
     youngest to oldest based on their `age` property, you might call
     `students.sorted(byKeyPath: "age", ascending: true)`.

     - warning: Collections may only be sorted by properties of boolean, `Date`, `NSDate`, single and double-precision
                floating point, integer, and string types.

     - parameter keyPath:   The key path to sort by.
     - parameter ascending: The direction to sort in.
     */
    func sorted(byKeyPath keyPath: String, ascending: Bool = true) -> Results<Element> {
        sorted(by: [SortDescriptor(keyPath: keyPath, ascending: ascending)])
    }

    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     Objects are sorted based on the values of the given key path. For example, to sort a collection of `Student`s from
     youngest to oldest based on their `age` property, you might call
     `students.sorted(byKeyPath: "age", ascending: true)`.

     - warning: Collections may only be sorted by properties of boolean, `Date`, `NSDate`, single and double-precision
                floating point, integer, and string types.

     - parameter keyPath:   The key path to sort by.
     - parameter ascending: The direction to sort in.
     */
    func sorted<T: _HasPersistedType>(by keyPath: KeyPath<Element, T>, ascending: Bool = true) -> Results<Element> where T.PersistedType: SortableType, Element: ObjectBase {
        sorted(by: [SortDescriptor(keyPath: keyPath, ascending: ascending)])
    }

    /**
     Returns a `Results` containing distinct objects based on the specified key paths

     - parameter keyPaths: The key paths used produce distinct results
     */
    func distinct<S: Sequence>(by keyPaths: S) -> Results<Element>
        where S.Iterator.Element == PartialKeyPath<Element>, Element: ObjectBase {
            return distinct(by: keyPaths.map(_name(for:)))
    }

}

public extension RealmCollection where Element.PersistedType: SortableType {
    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     Objects are sorted based on their values. For example, to sort a collection of `Date`s from
     neweset to oldest based, you might call `dates.sorted(ascending: true)`.

     - parameter ascending: The direction to sort in.
     */
    func sorted(ascending: Bool = true) -> Results<Element> {
        sorted(by: [SortDescriptor(keyPath: "self", ascending: ascending)])
    }

    /**
     Returns a `Results` containing the distinct values in the collection.
     */
    func distinct() -> Results<Element> {
        return distinct(by: ["self"])
    }
}

// MARK: - Sectioned Results on primitives

public extension RealmCollection {
    /**
     Sorts this collection in ascending or descending order and performs sectioning
     via a user defined callback function.

     - parameter block: A callback which is invoked on each element in the collection.
                        This callback is to return the section key for the element in the collection.
     - parameter ascending: The direction to sort in.

     - returns: An instance of `SectionedResults`.
     */
    func sectioned<Key: _Persistable>(by block: @escaping ((Element) -> Key),
                                      ascending: Bool = true) -> SectionedResults<Key, Element> {
        sectioned(sortDescriptors: [.init(keyPath: "self", ascending: ascending)], block)
    }
}

// MARK: - NSPredicate builders

public extension RealmCollection {
    /**
     Returns the index of the first object matching the given predicate, or `nil` if no objects match.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.
     */
    func index(matching predicateFormat: String, _ args: Any...) -> Int? {
        return index(matching: NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args)))
    }

    /**
     Returns a `Results` containing all objects matching the given predicate in the collection.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.
     */
    func filter(_ predicateFormat: String, _ args: Any...) -> Results<Element> {
        return filter(NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args)))
    }
}

// MARK: - Observation

public extension RealmCollection {
    /**
     Registers a block to be called each time the collection changes.

     The block will be asynchronously called with the initial results, and then called again after each write
     transaction which changes either any of the objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmCollectionChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     let dogs = realm.objects(Dog.self)
     print("dogs.count: \(dogs?.count)") // => 0
     let token = dogs.observe { changes in
         switch changes {
         case .initial(let dogs):
             // Will print "dogs.count: 1"
             print("dogs.count: \(dogs.count)")
             break
         case .update:
             // Will not be hit in this example
             break
         case .error:
             break
         }
     }
     try! realm.write {
         let dog = Dog()
         dog.name = "Rex"
         person.dogs.append(dog)
     }
     // end of run loop execution context
     ```

     If no key paths are given, the block will be executed on any insertion,
     modification, or deletion for all object properties and the properties of
     any nested, linked objects. If a key path or key paths are provided,
     then the block will be called for changes which occur only on the
     provided key paths. For example, if:
     ```swift
     class Dog: Object {
         @Persisted var name: String
         @Persisted var age: Int
         @Persisted var toys: List<Toy>
     }
     // ...
     let dogs = realm.objects(Dog.self)

     let token = dogs.observe(keyPaths: [\Dog.name]) { changes in
         switch changes {
         case .initial(let dogs):
            // ...
         case .update:
            // This case is hit:
            // - after the token is initialized
            // - when the name property of an object in the
            // collection is modified
            // - when an element is inserted or removed
            //   from the collection.
            // This block is not triggered:
            // - when a value other than name is modified on
            //   one of the elements.
         case .error:
             // ...
         }
     }
     // end of run loop execution context
     ```
     - If the observed key path were `[\Dog.toys.brand]`, then any insertion or
     deletion to the `toys` list on any of the collection's elements would trigger the block.
     Changes to the `brand` value on any `Toy` that is linked to a `Dog` in this
     collection will trigger the block. Changes to a value other than `brand` on any `Toy` that
     is linked to a `Dog` in this collection would not trigger the block.
     Any insertion or removal to the `Dog` type collection being observed
     would also trigger a notification.
     - If the above example observed the `[\Dog.toys]` key path, then any insertion,
     deletion, or modification to the `toys` list for any element in the collection
     would trigger the block.
     Changes to any value on any `Toy` that is linked to a `Dog` in this collection
     would *not* trigger the block.
     Any insertion or removal to the `Dog` type collection being observed
     would still trigger a notification.

     - note: Multiple notification tokens on the same object which filter for
     separate key paths *do not* filter exclusively. If one key path
     change is satisfied for one notification token, then all notification
     token blocks for that object will execute.

     You must retain the returned token for as long as you want updates to be sent to the block. To stop receiving
     updates, call `invalidate()` on the token.

     - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

     - parameter keyPaths: Only properties contained in the key paths array will trigger
                           the block when they are modified. If `nil`, notifications
                           will be delivered for any property change on the object.
                           See description above for more detail on linked properties.
     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    func observe(keyPaths: [String]? = nil,
                 on queue: DispatchQueue? = nil,
                 _ block: @escaping (RealmCollectionChange<Self>) -> Void) -> NotificationToken {
        return self.observe(keyPaths: keyPaths, on: queue, block)
    }

#if swift(>=5.8)
    /**
    Registers a block to be called each time the collection changes.

    The block will be asynchronously called with an initial version of the
    collection, and then called again after each write transaction which changes
    either any of the objects in the collection, or which objects are in the
    collection.

    The `actor` parameter passed to the block is the actor which you pass to this
    function. This parameter is required to isolate the callback to the actor.

    The `change` parameter that is passed to the block reports, in the form of
    indices within the collection, which of the objects were added, removed, or
    modified after the previous notification. The `collection` field in the change
    enum will be isolated to the requested actor, and is safe to use within that
    actor only. See the ``RealmCollectionChange`` documentation for more
    information on the change information supplied and an example of how to use it
    to update a `UITableView`.

    Once the initial notification is delivered, the collection will be fully
    evaluated and up-to-date, and accessing it will never perform any blocking
    work. This guarantee holds only as long as you do not perform a write
    transaction on the same actor as notifications are being delivered to. If you
    do, accessing the collection before the next notification is delivered may need
    to rerun the query.

    Notifications are delivered to the given actor's executor. When notifications
    can't be delivered instantly, multiple notifications may be coalesced into a
    single notification. This can include the notification with the initial
    collection: any writes which occur before the initial notification is delivered
    may not produce change notifications.

    Adding, removing or assigning objects in the collection always produces a
    notification. By default, modifying the objects which a collection links to
    (and the objects which those objects link to, if applicable) will also report
    that index in the collection as being modified. If a non-empty array of
    keypaths is provided, then only modifications to those keypaths will mark the
    object as modified. For example:

    ```swift
    class Dog: Object {
        @Persisted var name: String
        @Persisted var age: Int
        @Persisted var toys: List<Toy>
    }

    let dogs = realm.objects(Dog.self)
    let token = await dogs.observe(keyPaths: ["name"], on: myActor) { actor, changes in
        switch changes {
        case .initial(let dogs):
            // Query has finished running and dogs can not be used without blocking
        case .update:
            // This case is hit:
            // - after the token is initialized
            // - when the name property of an object in the collection is modified
            // - when an element is inserted or removed from the collection.
            // This block is not triggered:
            // - when a value other than name is modified on one of the elements.
        case .error:
            // Can no longer happen but is left for backwards compatiblity
        }
    }
    ```
    - If the observed key path were `["toys.brand"]`, then any insertion or
      deletion to the `toys` list on any of the collection's elements would trigger
      the block. Changes to the `brand` value on any `Toy` that is linked to a `Dog`
      in this collection will trigger the block. Changes to a value other than
      `brand` on any `Toy` that is linked to a `Dog` in this collection would not
      trigger the block. Any insertion or removal to the `Dog` type collection being
      observed would also trigger a notification.
    - If the above example observed the `["toys"]` key path, then any insertion,
      deletion, or modification to the `toys` list for any element in the collection
      would trigger the block. Changes to any value on any `Toy` that is linked to a
      `Dog` in this collection would *not* trigger the block. Any insertion or
      removal to the `Dog` type collection being observed would still trigger a
      notification.

    You must retain the returned token for as long as you want updates to be sent
    to the block. To stop receiving updates, call `invalidate()` on the token.

    - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

    - parameter keyPaths: Only properties contained in the key paths array will trigger
                       the block when they are modified. If `nil` or empty, notifications
                       will be delivered for any property change on the object.
                       String key paths which do not correspond to a valid a property
                       will throw an exception. See description above for
                       more detail on linked properties.
    - parameter actor: The actor to isolate the notifications to.
    - parameter block: The block to be called whenever a change occurs.
    - returns: A token which must be held for as long as you want updates to be delivered.
    */
    @available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
    @_unsafeInheritExecutor
    func observe<A: Actor>(keyPaths: [String]? = nil,
                           on actor: A,
                           _ block: @Sendable @escaping (isolated A, RealmCollectionChange<Self>) -> Void) async -> NotificationToken {
        await self.observe(keyPaths: keyPaths, on: actor, block)
    }
#endif
}

public extension RealmCollection where Element: ObjectBase {
    /**
     Registers a block to be called each time the collection changes.

     The block will be asynchronously called with the initial results, and then called again after each write
     transaction which changes either any of the objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmCollectionChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     let dogs = realm.objects(Dog.self)
     print("dogs.count: \(dogs?.count)") // => 0
     let token = dogs.observe { changes in
         switch changes {
         case .initial(let dogs):
             // Will print "dogs.count: 1"
             print("dogs.count: \(dogs.count)")
             break
         case .update:
             // Will not be hit in this example
             break
         case .error:
             break
         }
     }
     try! realm.write {
         let dog = Dog()
         dog.name = "Rex"
         person.dogs.append(dog)
     }
     // end of run loop execution context
     ```

     If no key paths are given, the block will be executed on any insertion,
     modification, or deletion for all object properties and the properties of
     any nested, linked objects. If a key path or key paths are provided,
     then the block will be called for changes which occur only on the
     provided key paths. For example, if:
     ```swift
     class Dog: Object {
         @Persisted var name: String
         @Persisted var age: Int
         @Persisted var toys: List<Toy>
     }
     // ...
     let dogs = realm.objects(Dog.self)

     let token = dogs.observe(keyPaths: [\Dog.name]) { changes in
         switch changes {
         case .initial(let dogs):
            // ...
         case .update:
            // This case is hit:
            // - after the token is initialized
            // - when the name property of an object in the
            // collection is modified
            // - when an element is inserted or removed
            //   from the collection.
            // This block is not triggered:
            // - when a value other than name is modified on
            //   one of the elements.
         case .error:
             // ...
         }
     }
     // end of run loop execution context
     ```
     - If the observed key path were `[\Dog.toys.brand]`, then any insertion or
     deletion to the `toys` list on any of the collection's elements would trigger the block.
     Changes to the `brand` value on any `Toy` that is linked to a `Dog` in this
     collection will trigger the block. Changes to a value other than `brand` on any `Toy` that
     is linked to a `Dog` in this collection would not trigger the block.
     Any insertion or removal to the `Dog` type collection being observed
     would also trigger a notification.
     - If the above example observed the `[\Dog.toys]` key path, then any insertion,
     deletion, or modification to the `toys` list for any element in the collection
     would trigger the block.
     Changes to any value on any `Toy` that is linked to a `Dog` in this collection
     would *not* trigger the block.
     Any insertion or removal to the `Dog` type collection being observed
     would still trigger a notification.

     - note: Multiple notification tokens on the same object which filter for
     separate key paths *do not* filter exclusively. If one key path
     change is satisfied for one notification token, then all notification
     token blocks for that object will execute.

     You must retain the returned token for as long as you want updates to be sent to the block. To stop receiving
     updates, call `invalidate()` on the token.

     - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

     - parameter keyPaths: Only properties contained in the key paths array will trigger
                           the block when they are modified. See description above for more detail on linked properties.
     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    func observe(keyPaths: [PartialKeyPath<Element>],
                 on queue: DispatchQueue? = nil,
                 _ block: @escaping (RealmCollectionChange<Self>) -> Void) -> NotificationToken {
        return self.observe(keyPaths: keyPaths.map(_name(for:)), on: queue, block)
    }

#if swift(>=5.8)
    /**
    Registers a block to be called each time the collection changes.

    The block will be asynchronously called with an initial version of the
    collection, and then called again after each write transaction which changes
    either any of the objects in the collection, or which objects are in the
    collection.

    The `actor` parameter passed to the block is the actor which you pass to this
    function. This parameter is required to isolate the callback to the actor.

    The `change` parameter that is passed to the block reports, in the form of
    indices within the collection, which of the objects were added, removed, or
    modified after the previous notification. The `collection` field in the change
    enum will be isolated to the requested actor, and is safe to use within that
    actor only. See the ``RealmCollectionChange`` documentation for more
    information on the change information supplied and an example of how to use it
    to update a `UITableView`.

    Once the initial notification is delivered, the collection will be fully
    evaluated and up-to-date, and accessing it will never perform any blocking
    work. This guarantee holds only as long as you do not perform a write
    transaction on the same actor as notifications are being delivered to. If you
    do, accessing the collection before the next notification is delivered may need
    to rerun the query.

    Notifications are delivered to the given actor's executor. When notifications
    can't be delivered instantly, multiple notifications may be coalesced into a
    single notification. This can include the notification with the initial
    collection: any writes which occur before the initial notification is delivered
    may not produce change notifications.

    Adding, removing or assigning objects in the collection always produces a
    notification. By default, modifying the objects which a collection links to
    (and the objects which those objects link to, if applicable) will also report
    that index in the collection as being modified. If a non-empty array of
    keypaths is provided, then only modifications to those keypaths will mark the
    object as modified. For example:

    ```swift
    class Dog: Object {
        @Persisted var name: String
        @Persisted var age: Int
        @Persisted var toys: List<Toy>
    }

    let dogs = realm.objects(Dog.self)
    let token = await dogs.observe(keyPaths: [\.name], on: myActor) { actor, changes in
        switch changes {
        case .initial(let dogs):
            // Query has finished running and dogs can not be used without blocking
        case .update:
            // This case is hit:
            // - after the token is initialized
            // - when the name property of an object in the collection is modified
            // - when an element is inserted or removed from the collection.
            // This block is not triggered:
            // - when a value other than name is modified on one of the elements.
        case .error:
            // Can no longer happen but is left for backwards compatiblity
        }
    }
    ```
    - If the observed key path were `[\.toys.brand]`, then any insertion or
      deletion to the `toys` list on any of the collection's elements would trigger
      the block. Changes to the `brand` value on any `Toy` that is linked to a `Dog`
      in this collection will trigger the block. Changes to a value other than
      `brand` on any `Toy` that is linked to a `Dog` in this collection would not
      trigger the block. Any insertion or removal to the `Dog` type collection being
      observed would also trigger a notification.
    - If the above example observed the `[\.toys]` key path, then any insertion,
      deletion, or modification to the `toys` list for any element in the collection
      would trigger the block. Changes to any value on any `Toy` that is linked to a
      `Dog` in this collection would *not* trigger the block. Any insertion or
      removal to the `Dog` type collection being observed would still trigger a
      notification.

    You must retain the returned token for as long as you want updates to be sent
    to the block. To stop receiving updates, call `invalidate()` on the token.

    - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

    - parameter keyPaths: Only properties contained in the key paths array will trigger
                       the block when they are modified. If empty, notifications
                       will be delivered for any property change on the object.
                       String key paths which do not correspond to a valid a property
                       will throw an exception. See description above for
                       more detail on linked properties.
    - parameter actor: The actor to isolate the notifications to.
    - parameter block: The block to be called whenever a change occurs.
    - returns: A token which must be held for as long as you want updates to be delivered.
    */
    @available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
    @_unsafeInheritExecutor
    func observe<A: Actor>(keyPaths: [PartialKeyPath<Element>], on actor: A,
                           _ block: @Sendable @escaping (isolated A, RealmCollectionChange<Self>) -> Void) async -> NotificationToken {
        await observe(keyPaths: keyPaths.map(_name(for:)), on: actor, block)
    }
#endif
}

extension RealmCollection {
    /**
     Sorts and sections this collection from a given property key path, returning the result
     as an instance of `SectionedResults`. For every unique value retrieved from the
     keyPath a section key will be generated.

     - parameter keyPath: The property key path to sort on.
     - parameter ascending: The direction to sort in.

     - returns: An instance of `SectionedResults`.
     */
    public func sectioned<Key: _Persistable, O: ObjectBase>(by keyPath: KeyPath<Element, Key>,
                                                            ascending: Bool = true) -> SectionedResults<Key, Element> where Element: Projection<O> {
        let keyPathString = _name(for: keyPath)
        return sectioned(sortDescriptors: [.init(keyPath: keyPathString, ascending: ascending)], {
            return $0[keyPath: keyPath]
        })
    }

    /**
     Sorts and sections this collection from a given property key path, returning the result
     as an instance of `SectionedResults`. For every unique value retrieved from the
     keyPath a section key will be generated.

     - parameter keyPath: The property key path to sort on.
     - parameter sortDescriptors: An array of `SortDescriptor`s to sort by.

     - note: The primary sort descriptor must be responsible for determining the section key.

     - returns: An instance of `SectionedResults`.
     */
    public func sectioned<Key: _Persistable, O: ObjectBase>(by keyPath: KeyPath<Element, Key>,
                                                            sortDescriptors: [SortDescriptor]) -> SectionedResults<Key, Element> where Element: Projection<O> {
        guard let sortDescriptor = sortDescriptors.first else {
            throwRealmException("Can not section Results with empty sortDescriptor parameter.")
        }
        let keyPathString = _name(for: keyPath)
        if keyPathString != sortDescriptor.keyPath {
            throwRealmException("The section key path must match the primary sort descriptor.")
        }
        return sectioned(sortDescriptors: sortDescriptors, { $0[keyPath: keyPath] })
    }

    /**
     Sorts this collection from a given array of sort descriptors and performs sectioning from
     a user defined callback, returning the result as an instance of `SectionedResults`.

     - parameter block: A callback which is invoked on each element in the Results collection.
                        This callback is to return the section key for the element in the collection.
     - parameter sortDescriptors: An array of `SortDescriptor`s to sort by.

     - note: The primary sort descriptor must be responsible for determining the section key.

     - returns: An instance of `SectionedResults`.
     */
    public func sectioned<Key: _Persistable, O: ObjectBase>(by block: @escaping ((Element) -> Key),
                                                            sortDescriptors: [SortDescriptor]) -> SectionedResults<Key, Element> where Element: Projection<O> {
        return sectioned(sortDescriptors: sortDescriptors, block)
    }
}

/**
 A type-erased `RealmCollection`.

 Instances of `RealmCollection` forward operations to an opaque underlying
 collection having the same `Element` type. This type can be used to write
 non-generic code which can operate on or store multiple types of Realm
 collections. It does not have any runtime overhead over using the original
 collection directly.
 */
@frozen public struct AnyRealmCollection<Element: RealmCollectionValue>: RealmCollectionImpl {
    internal let collection: RLMCollection
    internal var lastAccessedNames: NSMutableArray?
    internal init(collection: RLMCollection) {
        self.collection = collection
    }

    /// Creates an `AnyRealmCollection` wrapping `base`.
    public init<C: RealmCollection & _ObjcBridgeable>(_ base: C) where C.Element == Element {
        self.collection = base._rlmObjcValue as! RLMCollection
    }

    /**
     Returns the object at the given `index`.
     - parameter index: The index.
     */
    public subscript(position: Int) -> Element {
        throwForNegativeIndex(position)
        return staticBridgeCast(fromObjectiveC: collection.object(at: UInt(position)))
    }

    /// A human-readable description of the objects represented by the linking objects.
    public var description: String {
        return RLMDescriptionWithMaxDepth("AnyRealmCollection", collection, RLMDescriptionMaxDepth)
    }

    public static func == (lhs: AnyRealmCollection<Element>, rhs: AnyRealmCollection<Element>) -> Bool {
        lhs.collection.isEqual(rhs.collection)
    }

    /// :nodoc:
    public func makeIterator() -> RLMIterator<Element> {
        return RLMIterator(collection: collection)
    }

}

extension AnyRealmCollection: Encodable where Element: Encodable {}

/**
 ProjectedCollection is a special type of collection for Projection's properties which
 should be used when you want to project a `List` of Realm Objects to a list of values.
 You don't need to instantiate this type manually. Use it by calling `projectTo` on a `List` property:
 ```swift
 class PersistedListObject: Object {
     @Persisted public var people: List<CommonPerson>
 }

 class ListProjection: Projection<PersistedListObject> {
     @Projected(\PersistedListObject.people.projectTo.firstName) var strings: ProjectedCollection<String>
 }
 ```
*/
public struct ProjectedCollection<Element>: RandomAccessCollection, CustomStringConvertible, ThreadConfined where Element: RealmCollectionValue {
    public typealias Index = Int
    /**
     Returns the index of the first object in the list matching the predicate, or `nil` if no objects match.

     - parameter predicate: The predicate with which to filter the objects.
     */
    public func index(matching predicate: NSPredicate) -> Int? {
        backingCollection.index(matching: predicate)
    }

    /**
     Registers a block to be called each time the collection changes.

     The block will be asynchronously called with the initial results, and then called again after each write
     transaction which changes either any of the objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmCollectionChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     class Person: Object {
         @Persisted var dogs: List<Dog>
     }
     class PersonProjection: Projection<Person> {
         @Projected(\Person.dogs.projectTo.name) var dogsNames: ProjectedCollection<String>
     }
     // ...
     let dogsNames = personProjection.dogsNames
     print("dogsNames.count: \(dogsNames?.count)") // => 0
     let token = dogsNames.observe { changes in
         switch changes {
         case .initial(let dogsNames):
             // Will print "dogsNames.count: 1"
             print("dogsNames.count: \(dogsNames.count)")
             break
         case .update:
             // Will not be hit in this example
             break
         case .error:
             break
         }
     }
     try! realm.write {
         let dog = Dog()
         dog.name = "Rex"
         person.dogs.append(dog)
     }
     // end of run loop execution context
     ```

     You must retain the returned token for as long as you want updates to be sent to the block. To stop receiving
     updates, call `invalidate()` on the token.

     - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe(on queue: DispatchQueue?,
                        _ block: @escaping (RealmCollectionChange<ProjectedCollection<Element>>) -> Void) -> NotificationToken {
        backingCollection.observe(on: queue, {
            switch $0 {
            case .initial(let collection):
                block(.initial(Self(collection.collection, keyPath: keyPath, propertyName: propertyName)))
            case .update(let collection,
                         deletions: let deletions,
                         insertions: let insertions,
                         modifications: let modifications):
                block(.update(Self(collection.collection, keyPath: keyPath, propertyName: propertyName),
                              deletions: deletions,
                              insertions: insertions,
                              modifications: modifications))
            case .error(let error):
                block(.error(error))
            }
        })
    }
    /**
     Registers a block to be called each time the collection changes.

     The block will be asynchronously called with the initial results, and then called again after each write
     transaction which changes either any of the objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmCollectionChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     class Person: Object {
         @Persisted var dogs: List<Dog>
     }
     class PersonProjection: Projection<Person> {
         @Projected(\Person.dogs.projectTo.name) var dogNames: ProjectedCollection<String>
     }
     // ...
     let dogNames = personProjection.dogNames
     print("dogNames.count: \(dogNames?.count)") // => 0
     let token = dogs.observe { changes in
         switch changes {
         case .initial(let dogNames):
             // Will print "dogNames.count: 1"
             print("dogNames.count: \(dogNames.count)")
             break
         case .update:
             // Will not be hit in this example
             break
         case .error:
             break
         }
     }
     try! realm.write {
         let dog = Dog()
         dog.name = "Rex"
         person.dogs.append(dog)
     }
     // end of run loop execution context
     ```

     If no key paths are given, the block will be executed on any insertion,
     modification, or deletion for all object properties and the properties of
     any nested, linked objects. If a key path or key paths are provided,
     then the block will be called for changes which occur only on the
     provided key paths. For example, if:
     ```swift
     class Person: Object {
         @Persisted var dogs: List<Dog>
     }
     class PersonProjection: Projection<Person> {
         @Projected(\Person.dogs.projectTo.name) var dogNames: ProjectedCollection<String>
     }
     // ...
     let dogNames = personProjection.dogNames
     let token = dogNames.observe(keyPaths: ["name"]) { changes in
         switch changes {
         case .initial(let dogNames):
            // ...
         case .update:
            // This case is hit:
            // - after the token is initialized
            // - when the name property of an object in the
            // collection is modified
            // - when an element is inserted or removed
            //   from the collection.
            // This block is not triggered:
            // - when a value other than name is modified on
            //   one of the elements.
         case .error:
             // ...
         }
     }
     // end of run loop execution context
     ```
     Changes to any other value that is linked to a `Dog` in this collection
     would *not* trigger the block.
     Any insertion or removal to the `Dog` type collection being observed
     would still trigger a notification.

     - note: Multiple notification tokens on the same object which filter for
     separate key paths *do not* filter exclusively. If one key path
     change is satisfied for one notification token, then all notification
     token blocks for that object will execute.

     You must retain the returned token for as long as you want updates to be sent to the block. To stop receiving
     updates, call `invalidate()` on the token.

     - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

     - parameter keyPaths: Only properties contained in the key paths array will trigger
                           the block when they are modified. If `nil`, notifications
                           will be delivered for any property change on the object.
                           String key paths which do not correspond to a valid a property
                           will throw an exception.
                           See description above for more detail on linked properties.
     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe(keyPaths: [String]? = nil, on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmCollectionChange<ProjectedCollection<Element>>) -> Void)
        -> NotificationToken {
            backingCollection.observe(keyPaths: keyPaths, on: queue) {
                switch $0 {
                case .initial(let collection):
                    block(.initial(Self(collection.collection, keyPath: keyPath, propertyName: propertyName)))
                case .update(let collection,
                             deletions: let deletions,
                             insertions: let insertions,
                             modifications: let modifications):
                    block(.update(Self(collection.collection, keyPath: keyPath, propertyName: propertyName),
                                  deletions: deletions,
                                  insertions: insertions,
                                  modifications: modifications))
                case .error(let error):
                    block(.error(error))
                }
            }
        }

    /**
     Returns the object at the given index (get), or replaces the object at the given index (set).

     - warning: You can only set an object during a write transaction.

     - parameter index: The index of the object to retrieve or replace.
     */
    public subscript(position: Int) -> Element {
        get {
            backingCollection[position][keyPath: keyPath] as! Element
        }
        set {
            backingCollection[position].setValue(newValue, forKeyPath: propertyName)
        }
    }

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int {
        backingCollection.startIndex
    }
    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    public var endIndex: Int {
        backingCollection.endIndex
    }
    /// The Realm which manages the object.
    public var realm: Realm? {
        backingCollection.realm
    }
    /// Indicates if the collection can no longer be accessed.
    public var isInvalidated: Bool {
        backingCollection.isInvalidated
    }
    /// A human-readable description of the object.
    public var description: String {
        var description = "ProjectedCollection<\(Element.self)> {\n"
        for (i, v) in self.enumerated() {
            description += "\t[\(i)] \(v)\n"
        }
        return description + "}"
    }
    /**
     Returns the index of an object in the linking objects, or `nil` if the object is not present.

     - parameter object: The object whose index is being queried.
     */
    public func index(of object: Element) -> Int? {
        return backingCollection.map { $0[keyPath: self.keyPath] as! Element }.firstIndex(of: object)
    }
    public var isFrozen: Bool {
        backingCollection.isFrozen
    }
    public func freeze() -> Self {
        Self(backingCollection.freeze().collection, keyPath: keyPath, propertyName: propertyName)
    }
    public func thaw() -> Self? {
        guard let backingCollection = backingCollection.thaw() else {
            return nil
        }
        return Self(backingCollection.collection, keyPath: keyPath, propertyName: propertyName)
    }

    private let backingCollection: AnyRealmCollection<Object>
    private let keyPath: AnyKeyPath
    private let propertyName: String

    init(_ collection: RLMCollection, keyPath: AnyKeyPath, propertyName: String) {
        self.backingCollection = AnyRealmCollection(collection: collection)
        self.keyPath = keyPath
        self.propertyName = propertyName
    }
}

/**
 `CollectionElementMapper` transforms the actual collection objects into a `ProjectedCollection`.

 For example:
 ```swift
 class Person: Object {
     @Persisted var dogs: List<Dog>
 }
 class PersonProjection: Projection<Person> {
     @Projected(\Person.dogs.projectTo.name) var dogNames: ProjectedCollection<String>
 }
```
 In this code the `Person`'s dogs list will be prijected to the list of dogs names via `projectTo`
 */
@dynamicMemberLookup
public struct CollectionElementMapper<Element> where Element: ObjectBase & RealmCollectionValue {
    let collection: RLMCollection
    /// :nodoc:
    public subscript<V>(dynamicMember member: KeyPath<Element, V>) -> ProjectedCollection<V> {
        ProjectedCollection(collection, keyPath: member, propertyName: _name(for: member))
    }
}

extension List where Element: ObjectBase & RealmCollectionValue {
    /**
     `projectTo` will map the original `List` of `Objects` or `List` of `EmbeddedObjects` in to `ProjectedCollection`.

     For example:
     ```swift
     class Person: Object {
         @Persisted var dogs: List<Dog>
     }
     class PersonProjection: Projection<Person> {
         @Projected(\Person.dogs.projectTo.name) var dogNames: ProjectedCollection<String>
     }
    ```
     In this code the `Person`'s dogs list will be prijected to the list of dogs names via `projectTo`
     */
    public var projectTo: CollectionElementMapper<Element> {
        CollectionElementMapper(collection: collection)
    }
}

extension MutableSet where Element: ObjectBase & RealmCollectionValue {
    /**
     `MutableSetElementMapper` transforms the actual `MutableSet` of `Objects` or `MutableSet` of `EmbeddedObjects` in to `ProjectedCollection`.

     For example:
     ```swift
     class Person: Object {
         @Persisted var dogs: MutableSet<Dog>
     }
     class PersonProjection: Projection<Person> {
         @Projected(\Person.dogs.projectTo.name) var dogNames: ProjectedCollection<String>
     }
    ```
     In this code the `Person`'s dogs set will be prijected to the projected set of dogs names via `projectTo`
     Note: This is not the actual *set* data type therefore projected elements can contain duplicates.
     */
    public var projectTo: CollectionElementMapper<Element> {
        CollectionElementMapper(collection: collection)
    }
}
