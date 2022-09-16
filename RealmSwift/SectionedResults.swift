////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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
 `RealmSectionedResult` defines properties and methods which are common between
 `SectionedResults` and `ResultSection`.
 */
public protocol RealmSectionedResult: RandomAccessCollection, Equatable, ThreadConfined {
    associatedtype Key: _Persistable, Hashable
    // MARK: Properties

    /// The Realm which manages the collection, or `nil` if the collection is invalidated.
    var realm: Realm? { get }

    /**
     Indicates if the collection can no longer be accessed.

     The collection can no longer be accessed if `invalidate()` is called on the `Realm` that manages the collection.
     */
    var isInvalidated: Bool { get }

    /// The number of objects in the collection.
    var count: Int { get }

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

    /// :nodoc:
    func observe(keyPaths: [String]?,
                 on queue: DispatchQueue?,
                 _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken
    /// :nodoc:
    func observe(on queue: DispatchQueue?,
                 _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken
}

extension RealmSectionedResult where Element: RLMObjectBase {
    /// :nodoc:
    func observe(keyPaths: [PartialKeyPath<Element>],
                 on queue: DispatchQueue?,
                 _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken {
        fatalError("abstract")
    }
}

/**
 `RealmSectionedResultImpl` implements properties and methods which are common between
 `SectionedResults` and `ResultSection`.
 */
internal protocol RealmSectionedResultImpl: RealmSectionedResult {
    associatedtype Collection: RLMSectionedResult
    var collection: Collection { get set }
    init(rlmSectionedResult: Collection)
}

extension RealmSectionedResultImpl {
    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int { 0 }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    public var endIndex: Int { count }
    /// The Realm which manages the object.
    public var realm: Realm? {
        collection.realm.map(Realm.init)
    }
    /// Indicates if the collection can no longer be accessed.
    public var isInvalidated: Bool {
        collection.isInvalidated
    }
    /// Returns true if this collection is frozen
    public var isFrozen: Bool {
        collection.isFrozen
    }
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
    public func freeze() -> Self {
        return Self(rlmSectionedResult: collection.freeze())
    }
    /// :nodoc:
    public func thaw() -> Self? {
        return Self(rlmSectionedResult: collection.thaw())
    }
    /// :nodoc:
    internal typealias ObjcSectionedResultsChange = (RLMSectionedResult?, RLMSectionedResultsChange?) -> Void
    /// :nodoc:
    internal func wrapObserveBlock(_ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> ObjcSectionedResultsChange {
        var col: Self?
        return { collection, change in
            if col == nil, let collection = collection {
                col = self.collection === collection ? self : Self(rlmSectionedResult: collection as! Self.Collection)
            }
            block(RealmSectionedResultsChange.fromObjc(value: col, change: change))
        }
    }
}

/// `SectionedResults` is a type safe collection which holds individual `ResultsSection`s as its elements.
/// The container is lazily evaluated, meaning that if the underlying collection has changed a full recalculation of the section keys will take place.
/// A `SectionedResults` instance can be observed and it also conforms to `ThreadConfined`.
public struct SectionedResults<Key: _Persistable & Hashable, Element: RealmCollectionValue>: RealmSectionedResultImpl {
    /// :nodoc:
    internal var collection: RLMSectionedResults<RLMValue, RLMValue>
    /// :nodoc:
    internal init(rlmSectionedResult: RLMSectionedResults<RLMValue, RLMValue>) {
        self.collection = rlmSectionedResult
    }

    /// An array of all keys in the sectioned results collection.
    public var allKeys: [Key] {
        collection.allKeys.map { Key._rlmFromObjc($0)! }
    }

    /// The total number of sections in this sectioned results collection.
    public var count: Int {
        Int(collection.count)
    }

    /**
     Returns the section at the given `index`.
     - parameter index: The index.
     */
    public subscript(_ index: Int) -> ResultsSection<Key, Element> {
        return ResultsSection<Key, Element>(rlmSectionedResult: collection[UInt(index)])
    }

    /**
     Returns the object at the given `IndexPath`.
     - parameter indexPath: The IndexPath.
     */
    public subscript(_ indexPath: IndexPath) -> Element {
        return self[indexPath.section][indexPath.item]
    }

    // MARK: Notifications

    /**
     Registers a block to be called each time the sectioned results collection changes.

     The block will be asynchronously called with the initial sectioned results collection, and then called again after each write
     transaction which changes either any of the objects in the sectioned results collection, or which objects are in the sectioned results collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmSectionedResultsChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial sectioned results collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     let dogs = realm.objects(Dog.self)
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     print("sectionedResults.count: \(sectionedResults?.count)") // => 0
     let token = sectionedResults.observe { changes in
         switch changes {
         case .initial(let sectionedResults):
             // Will print "sectionedResults.count: 1"
             print("sectionedResults.count: \(sectionedResults.count)")
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
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     let token = sectionedResults.observe(keyPaths: ["name"]) { changes in
         switch changes {
         case .initial(let sectionedResults):
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
     - Any modification to the section key path property which results in the object changing
     position in the section, or changing section entirely will trigger a notification.

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
    public func observe(keyPaths: [String]? = nil,
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken {
        return collection.addNotificationBlock(wrapObserveBlock(block), keyPaths: keyPaths, queue: queue)
    }

    /**
     Registers a block to be called each time the sectioned results collection changes.

     The block will be asynchronously called with the initial sectioned results collection, and then called again after each write
     transaction which changes either any of the objects in the sectioned results collection, or which objects are in the sectioned results collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmSectionedResultsChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial sectioned results collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     let dogs = realm.objects(Dog.self)
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     print("sectionedResults.count: \(sectionedResults?.count)") // => 0
     let token = sectionedResults.observe { changes in
         switch changes {
         case .initial(let sectionedResults):
             // Will print "sectionedResults.count: 1"
             print("sectionedResults.count: \(sectionedResults.count)")
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
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     let token = sectionedResults.observe(keyPaths: ["name"]) { changes in
         switch changes {
         case .initial(let sectionedResults):
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
     - Any modification to the section key path property which results in the object changing
     position in the section, or changing section entirely will trigger a notification.

     - note: Multiple notification tokens on the same object which filter for
     separate key paths *do not* filter exclusively. If one key path
     change is satisfied for one notification token, then all notification
     token blocks for that object will execute.

     You must retain the returned token for as long as you want updates to be sent to the block. To stop receiving
     updates, call `invalidate()` on the token.

     - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe(on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken {
        return collection.addNotificationBlock(wrapObserveBlock(block), keyPaths: nil, queue: queue)
    }

    /// :nodoc:
    public func makeIterator() -> RLMSectionedResultsIterator<Key, Element> {
        return RLMSectionedResultsIterator(collection: collection)
    }

    /// :nodoc:
    public static func == (lhs: SectionedResults<Key, Element>, rhs: SectionedResults<Key, Element>) -> Bool {
        return lhs.collection == rhs.collection
    }
}

extension SectionedResults where Element: RLMObjectBase {
    /**
     Registers a block to be called each time the sectioned results collection changes.

     The block will be asynchronously called with the initial sectioned results collection, and then called again after each write
     transaction which changes either any of the objects in the sectioned results collection, or which objects are in the sectioned results collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmSectionedResultsChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial sectioned results collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     let dogs = realm.objects(Dog.self)
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     print("sectionedResults.count: \(sectionedResults?.count)") // => 0
     let token = sectionedResults.observe { changes in
         switch changes {
         case .initial(let sectionedResults):
             // Will print "sectionedResults.count: 1"
             print("sectionedResults.count: \(sectionedResults.count)")
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
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     let token = sectionedResults.observe(keyPaths: ["name"]) { changes in
         switch changes {
         case .initial(let sectionedResults):
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
     - Any modification to the section key path property which results in the object changing
     position in the section, or changing section entirely will trigger a notification.

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
     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe(keyPaths: [PartialKeyPath<Element>],
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken {
        return collection.addNotificationBlock(wrapObserveBlock(block), keyPaths: keyPaths.map(_name(for:)), queue: queue)
    }
}

/// `ResultsSection` is a collection which allows access  to objects that belong to a given section key.
/// The collection is lazily evaluated, meaning that if the underlying collection has changed a full recalculation of the section keys will take place.
/// A `ResultsSection` instance can be observed and it also conforms to `ThreadConfined`.
public struct ResultsSection<Key: _Persistable & Hashable, T: RealmCollectionValue>: RealmSectionedResultImpl {
    public typealias Element = T
    /// :nodoc:
    internal var collection: RLMSection<RLMValue, RLMValue>
    /// :nodoc:
    internal init(rlmSectionedResult: RLMSection<RLMValue, RLMValue>) {
        self.collection = rlmSectionedResult
    }

    /// The total number of objects in this section.
    public var count: Int {
        Int(collection.count)
    }

    /// The key which represents this section.
    public var key: Key {
        return Key._rlmFromObjc(collection.key)!
    }
    /// :nodoc:
    public var id: Key {
        return Key._rlmFromObjc(collection.key)!
    }

    /**
     Returns the object at the given `index`.
     - parameter index: The index.
     */
    public subscript(_ index: Int) -> T {
        return T._rlmFromObjc(collection[UInt(index)])!
    }

    /**
     Registers a block to be called each time the sectioned results collection changes.

     The block will be asynchronously called with the initial sectioned results collection, and then called again after each write
     transaction which changes either any of the objects in the sectioned results collection, or which objects are in the sectioned results collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmSectionedResultsChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial sectioned results collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     let dogs = realm.objects(Dog.self)
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     print("sectionedResults.count: \(sectionedResults?.count)") // => 0
     let token = sectionedResults.observe { changes in
         switch changes {
         case .initial(let sectionedResults):
             // Will print "sectionedResults.count: 1"
             print("sectionedResults.count: \(sectionedResults.count)")
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
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     let token = sectionedResults.observe(keyPaths: ["name"]) { changes in
         switch changes {
         case .initial(let sectionedResults):
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
     - Any modification to the section key path property which results in the object changing
     position in the section, or changing section entirely will trigger a notification.

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
    public func observe(keyPaths: [String]? = nil,
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken {
        return collection.addNotificationBlock(wrapObserveBlock(block), keyPaths: keyPaths, queue: queue)
    }
    /**
     Registers a block to be called each time the sectioned results collection changes.

     The block will be asynchronously called with the initial sectioned results collection, and then called again after each write
     transaction which changes either any of the objects in the sectioned results collection, or which objects are in the sectioned results collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmSectionedResultsChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial sectioned results collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     let dogs = realm.objects(Dog.self)
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     print("sectionedResults.count: \(sectionedResults?.count)") // => 0
     let token = sectionedResults.observe { changes in
         switch changes {
         case .initial(let sectionedResults):
             // Will print "sectionedResults.count: 1"
             print("sectionedResults.count: \(sectionedResults.count)")
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
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     let token = sectionedResults.observe(keyPaths: ["name"]) { changes in
         switch changes {
         case .initial(let sectionedResults):
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
     - Any modification to the section key path property which results in the object changing
     position in the section, or changing section entirely will trigger a notification.

     - note: Multiple notification tokens on the same object which filter for
     separate key paths *do not* filter exclusively. If one key path
     change is satisfied for one notification token, then all notification
     token blocks for that object will execute.

     You must retain the returned token for as long as you want updates to be sent to the block. To stop receiving
     updates, call `invalidate()` on the token.

     - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe(on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken {
        return collection.addNotificationBlock(wrapObserveBlock(block), keyPaths: nil, queue: queue)
    }

    /// :nodoc:
    public func makeIterator() -> RLMSectionIterator<Element> {
        return RLMSectionIterator(collection: collection)
    }

    /// :nodoc:
    public static func == (lhs: ResultsSection<Key, Element>, rhs: ResultsSection<Key, Element>) -> Bool {
        return lhs.collection == rhs.collection
    }
}

extension ResultsSection where T: RLMObjectBase {
    /**
     Registers a block to be called each time the sectioned results collection changes.

     The block will be asynchronously called with the initial sectioned results collection, and then called again after each write
     transaction which changes either any of the objects in the sectioned results collection, or which objects are in the sectioned results collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmSectionedResultsChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date, and as long as you do
     not perform a write transaction on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     If no queue is given, notifications are delivered via the standard run loop, and so can't be delivered while the
     run loop is blocked by other activity. If a queue is given, notifications are delivered to that queue instead. When
     notifications can't be delivered instantly, multiple notifications may be coalesced into a single notification.
     This can include the notification with the initial sectioned results collection.

     For example, the following code performs a write transaction immediately after adding the notification block, so
     there is no opportunity for the initial notification to be delivered first. As a result, the initial notification
     will reflect the state of the Realm after the write transaction.

     ```swift
     let dogs = realm.objects(Dog.self)
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     print("sectionedResults.count: \(sectionedResults?.count)") // => 0
     let token = sectionedResults.observe { changes in
         switch changes {
         case .initial(let sectionedResults):
             // Will print "sectionedResults.count: 1"
             print("sectionedResults.count: \(sectionedResults.count)")
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
     let sectionedResults = dogs.sectioned(by: \.age, ascending: true)
     let token = sectionedResults.observe(keyPaths: ["name"]) { changes in
         switch changes {
         case .initial(let sectionedResults):
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
     - Any modification to the section key path property which results in the object changing
     position in the section, or changing section entirely will trigger a notification.

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
     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe(keyPaths: [PartialKeyPath<Element>],
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken {
        return collection.addNotificationBlock(wrapObserveBlock(block), keyPaths: keyPaths.map(_name(for:)), queue: queue)
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ResultsSection: Identifiable { }

@frozen public enum RealmSectionedResultsChange<Collection> {
    /**
     `.initial` indicates that the initial run of the query has completed (if
     applicable), and the collection can now be used without performing any
     blocking work.
     */
    case initial(Collection)

    /**
     `.update` indicates that a write transaction has been committed which
     either changed which objects are in the collection, and/or modified one
     or more of the objects in the collection.

     All three of the change arrays are always sorted in ascending order.

     - parameter deletions:     The indexPaths in the previous version of the collection which were removed from this one.
     - parameter insertions:    The indexPaths in the new collection which were added in this version.
     - parameter modifications: The indexPaths of the objects which were modified in the previous version of this collection.
     - parameter sectionsToInsert: The indexSet of the sections which were newly inserted into the sectioned results collection.
     - parameter sectionsToDelete: The indexSet of the sections which were recently deleted from the previous sectioned results collection.
     */
    case update(Collection, deletions: [IndexPath], insertions: [IndexPath], modifications: [IndexPath],
                sectionsToInsert: IndexSet, sectionsToDelete: IndexSet)

    /// :nodoc:
    static func fromObjc(value: Collection?, change: RLMSectionedResultsChange?) -> RealmSectionedResultsChange {
        if let change = change {
            return .update(value!,
                           deletions: change.deletions as [IndexPath],
                           insertions: change.insertions as [IndexPath],
                           modifications: change.modifications as [IndexPath],
                           sectionsToInsert: change.sectionsToInsert,
                           sectionsToDelete: change.sectionsToRemove)
        }
        return .initial(value!)
    }
}

/**
 An iterator for a `SectionedResults` instance.
 */
@frozen public struct RLMSectionedResultsIterator<Key: _Persistable & Hashable, Element: RealmCollectionValue>: IteratorProtocol {
    private var generatorBase: NSFastEnumerationIterator

    init(collection: RLMSectionedResults<RLMValue, RLMValue>) {
        generatorBase = NSFastEnumerationIterator(collection)
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public mutating func next() -> ResultsSection<Key, Element>? {
        guard let next = generatorBase.next() else { return nil }
        return ResultsSection<Key, Element>(rlmSectionedResult: next as! RLMSection<RLMValue, RLMValue>)
    }
}

/**
 An iterator for a `Section` instance.
 */
@frozen public struct RLMSectionIterator<Element: RealmCollectionValue>: IteratorProtocol {
    private var generatorBase: NSFastEnumerationIterator

    init(collection: RLMSection<RLMValue, RLMValue>) {
        generatorBase = NSFastEnumerationIterator(collection)
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public mutating func next() -> Element? {
        guard let next = generatorBase.next() else { return nil }
        return next as? Element
    }
}
