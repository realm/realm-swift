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

#if swift(>=3.0)

/**
Encapsulates iteration state and interface for iteration over a `RealmCollection`.
*/
public final class RLMIterator<T: Object>: IteratorProtocol {
    private var i: UInt = 0
    private let generatorBase : NSFastEnumerationIterator

    init(collection: RLMCollection) {
        generatorBase = NSFastEnumerationIterator(collection)
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public func next() -> T? { // swiftlint:disable:this valid_docs
        let accessor = generatorBase.next() as! T?
        if let accessor = accessor {
            RLMInitializeSwiftAccessorGenerics(accessor)
        }
        return accessor
    }
}

/**
 RealmCollectionChange is passed to the notification blocks for Realm
 collections, and reports the current state of the collection and what changes
 were made to the collection since the last time the notification was called.

 The arrays of indices in the .Update case follow UITableView's batching
 conventions, and can be passed as-is to a table view's batch update functions
 after converting to index paths in the appropriate section. For example, for a
 simple one-section table view, you can do the following:

    self.notificationToken = results.addNotificationBlock { changes
        switch changes {
        case .Initial:
            // Results are now populated and can be accessed without blocking the UI
            self.tableView.reloadData()
            break
        case .Update(_, let deletions, let insertions, let modifications):
            // Query results have changed, so apply them to the TableView
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) },
                withRowAnimation: .Automatic)
            self.tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) },
                withRowAnimation: .Automatic)
            self.tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) },
                withRowAnimation: .Automatic)
            self.tableView.endUpdates()
            break
        case .Error(let err):
            // An error occurred while opening the Realm file on the background worker thread
            fatalError("\(err)")
            break
        }
    }
 */
public enum RealmCollectionChange<T> {
    /// The initial run of the query has completed (if applicable), and the
    /// collection can now be used without performing any blocking work.
    case Initial(T)

    /// A write transaction has been committed which either changed which objects
    /// are in the collection and/or modified one or more of the objects in the
    /// collection.
    ///
    /// All three of the change arrays are always sorted in ascending order.
    ///
    /// - parameter deletions:     The indices in the previous version of the collection
    ///                            which were removed from this one.
    /// - parameter insertions:    The indices in the new collection which were added in
    ///                            this version.
    /// - parameter modifications: The indices of the objects in the new collection which
    ///                            were modified in this version.
    case Update(T, deletions: [Int], insertions: [Int], modifications: [Int])

    /// If an error occurs, notification blocks are called one time with a
    /// .Error result and an NSError with details. Currently the only thing
    /// that can fail is opening the Realm on a background worker thread to
    /// calculate the change set.
    case Error(NSError)

    static func fromObjc(value: T, change: RLMCollectionChange?, error: NSError?) -> RealmCollectionChange {
        if let error = error {
            return .Error(error)
        }
        if let change = change {
            return .Update(value,
                deletions: change.deletions as! [Int],
                insertions: change.insertions as! [Int],
                modifications: change.modifications as! [Int])
        }
        return .Initial(value)
    }
}

/**
A homogenous collection of `Object`s which can be retrieved, filtered, sorted,
and operated upon.
*/
public protocol RealmCollection: RandomAccessCollection, CustomStringConvertible {

    /// Element type contained in this collection.
    associatedtype Element: Object


    // MARK: Properties

    /// The Realm the objects in this collection belong to, or `nil` if the
    /// collection's owning object does not belong to a realm (the collection is
    /// standalone).
    var realm: Realm? { get }

    /// Indicates if the collection can no longer be accessed.
    ///
    /// The collection can no longer be accessed if `invalidate` is called on the containing `Realm`.
    var isInvalidated: Bool { get }

    /// Returns the number of objects in this collection.
    var count: Int { get }

    /// Returns a human-readable description of the objects contained in this collection.
    var description: String { get }


    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the collection.

    - parameter object: The object whose index is being queried.

    - returns: The index of the given object, or `nil` if the object is not in the collection.
    */
    func index(of object: Element) -> Int?

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` no objects match.

    - parameter predicate: The `NSPredicate` used to filter the objects.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    func indexOfObject(for predicate: Predicate) -> Int?

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if no objects match.

    - parameter predicateFormat: The predicate format string, optionally followed by a variable number
    of arguments.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    func indexOfObject(for predicateFormat: String, _ args: AnyObject...) -> Int?


    // MARK: Filtering

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicateFormat: The predicate format string which can accept variable arguments.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    func filter(using predicateFormat: String, _ args: AnyObject...) -> Results<Element>

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicate: The predicate to filter the objects.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    func filter(using predicate: Predicate) -> Results<Element>


    // MARK: Sorting

    /**
    Returns `Results` containing collection elements sorted by the given property.

    - parameter property:  The property name to sort by.
    - parameter ascending: The direction to sort by.

    - returns: `Results` containing collection elements sorted by the given property.
    */
    func sorted(onProperty property: String, ascending: Bool) -> Results<Element>

    /**
    Returns `Results` with elements sorted by the given sort descriptors.

    - parameter sortDescriptors: `SortDescriptor`s to sort by.

    - returns: `Results` with elements sorted by the given sort descriptors.
    */
    func sorted<S: Sequence where S.Iterator.Element == SortDescriptor>(with sortDescriptors: S) -> Results<Element>


    // MARK: Aggregate Operations

    /**
    Returns the minimum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a minimum on.

    - returns: The minimum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    func minimumValue<U: MinMaxType>(ofProperty property: String) -> U?

    /**
    Returns the maximum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a maximum on.

    - returns: The maximum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    func maximumValue<U: MinMaxType>(ofProperty property: String) -> U?

    /**
    Returns the sum of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.

    - returns: The sum of the given property over all objects in the collection.
    */
    func sum<U: AddableType>(ofProperty property: String) -> U

    /**
    Returns the average of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate average on.

    - returns: The average of the given property over all objects in the collection, or `nil` if the
               collection is empty.
    */
    func average<U: AddableType>(ofProperty property: String) -> U?


    // MARK: Key-Value Coding

    /**
    Returns an Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.

    - parameter key: The name of the property.

    - returns: Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.
    */
    func value(forKey key: String) -> AnyObject?

    /**
     Returns an Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.

     - parameter keyPath: The key path to the property.

     - returns: Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.
     */
    func value(forKeyPath keyPath: String) -> AnyObject?

    /**
    Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified value and key.

    - warning: This method can only be called during a write transaction.

    - parameter value: The object value.
    - parameter key:   The name of the property.
    */
    func setValue(_ value: AnyObject?, forKey key: String)

    // MARK: Notifications

    /**
     Register a block to be called each time the collection changes.

     The block will be asynchronously called with the initial results, and then
     called again after each write transaction which changes either any of the
     objects in the collection, or which objects are in the collection.

     At the time when the block is called, the collection object will be fully
     evaluated and up-to-date, and as long as you do not perform a write
     transaction on the same thread or explicitly call realm.refresh(),
     accessing it will never perform blocking work.

     Notifications are delivered via the standard run loop, and so can't be
     delivered while the run loop is blocked by other activity. When
     notifications can't be delivered instantly, multiple notifications may be
     coalesced into a single notification. This can include the notification
     with the initial collection. For example, the following code performs a write
     transaction immediately after adding the notification block, so there is no
     opportunity for the initial notification to be delivered first. As a
     result, the initial notification will reflect the state of the Realm after
     the write transaction.

         let results = realm.objects(Dog)
         print("dogs.count: \(dogs?.count)") // => 0
         let token = dogs.addNotificationBlock { (changes: RealmCollectionChange) in
             switch changes {
                 case .Initial(let dogs):
                     // Will print "dogs.count: 1"
                     print("dogs.count: \(dogs.count)")
                     break
                 case .Update:
                     // Will not be hit in this example
                     break
                 case .Error:
                     break
             }
         }
         try! realm.write {
             let dog = Dog()
             dog.name = "Rex"
             person.dogs.append(dog)
         }
         // end of run loop execution context

     You must retain the returned token for as long as you want updates to continue
     to be sent to the block. To stop receiving updates, call stop() on the token.

     - warning: This method cannot be called during a write transaction, or when
                the source realm is read-only.

     - parameter block: The block to be called with the evaluated collection and change information.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    func addNotificationBlock(block: (RealmCollectionChange<Self>) -> Void) -> NotificationToken

    /// :nodoc:
    func _addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection<Element>>) -> Void) -> NotificationToken
}

private class _AnyRealmCollectionBase<T: Object> {
    typealias Wrapper = AnyRealmCollection<Element>
    typealias Element = T
    var realm: Realm? { fatalError() }
    var isInvalidated: Bool { fatalError() }
    var count: Int { fatalError() }
    var description: String { fatalError() }
    func index(of object: Element) -> Int? { fatalError() }
    func indexOfObject(for predicate: Predicate) -> Int? { fatalError() }
    func indexOfObject(for predicateFormat: String, _ args: AnyObject...) -> Int? { fatalError() }
    func filter(using predicateFormat: String, _ args: AnyObject...) -> Results<Element> { fatalError() }
    func filter(using predicate: Predicate) -> Results<Element> { fatalError() }
    func sorted(onProperty property: String, ascending: Bool) -> Results<Element> { fatalError() }
    func sorted<S: Sequence where S.Iterator.Element == SortDescriptor>(with sortDescriptors: S) -> Results<Element> {
        fatalError()
    }
    func minimumValue<U: MinMaxType>(ofProperty property: String) -> U? { fatalError() }
    func maximumValue<U: MinMaxType>(ofProperty property: String) -> U? { fatalError() }
    func sum<U: AddableType>(ofProperty property: String) -> U { fatalError() }
    func average<U: AddableType>(ofProperty property: String) -> U? { fatalError() }
    subscript(position: Int) -> Element { fatalError() }
    func makeIterator() -> RLMIterator<T> { fatalError() }
    var startIndex: Int { fatalError() }
    var endIndex: Int { fatalError() }
    func value(forKey key: String) -> AnyObject? { fatalError() }
    func value(forKeyPath keyPath: String) -> AnyObject? { fatalError() }
    func setValue(_ value: AnyObject?, forKey key: String) { fatalError() }
    func _addNotificationBlock(block: (RealmCollectionChange<Wrapper>) -> Void)
        -> NotificationToken { fatalError() }
}

private final class _AnyRealmCollection<C: RealmCollection>: _AnyRealmCollectionBase<C.Element> {
    let base: C
    init(base: C) {
        self.base = base
    }

    // MARK: Properties

    /// The Realm the objects in this collection belong to, or `nil` if the
    /// collection's owning object does not belong to a realm (the collection is
    /// standalone).
    override var realm: Realm? { return base.realm }

    /// Indicates if the collection can no longer be accessed.
    ///
    /// The collection can no longer be accessed if `invalidate` is called on the containing `Realm`.
    override var isInvalidated: Bool { return base.isInvalidated }

    /// Returns the number of objects in this collection.
    override var count: Int { return base.count }

    /// Returns a human-readable description of the objects contained in this collection.
    override var description: String { return base.description }


    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the collection.

    - parameter object: The object whose index is being queried.

    - returns: The index of the given object, or `nil` if the object is not in the collection.
    */
    override func index(of object: C.Element) -> Int? { return base.index(of: object) }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` no objects match.

    - parameter predicate: The `NSPredicate` used to filter the objects.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    override func indexOfObject(for predicate: Predicate) -> Int? { return base.indexOfObject(for: predicate) }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if no objects match.

    - parameter predicateFormat: The predicate format string, optionally followed by a variable number
    of arguments.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    override func indexOfObject(for predicateFormat: String, _ args: AnyObject...) -> Int? {
        return base.indexOfObject(for: Predicate(format: predicateFormat, argumentArray: args))
    }

    // MARK: Filtering

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicateFormat: The predicate format string which can accept variable arguments.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    override func filter(using predicateFormat: String, _ args: AnyObject...) -> Results<C.Element> {
        return base.filter(using: Predicate(format: predicateFormat, argumentArray: args))
    }

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicate: The predicate to filter the objects.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    override func filter(using predicate: Predicate) -> Results<C.Element> { return base.filter(using: predicate) }


    // MARK: Sorting

    /**
    Returns `Results` containing collection elements sorted by the given property.

    - parameter property:  The property name to sort by.
    - parameter ascending: The direction to sort by.

    - returns: `Results` containing collection elements sorted by the given property.
    */
    override func sorted(onProperty property: String, ascending: Bool) -> Results<C.Element> {
        return base.sorted(onProperty: property, ascending: ascending)
    }

    /**
    Returns `Results` with elements sorted by the given sort descriptors.

    - parameter sortDescriptors: `SortDescriptor`s to sort by.

    - returns: `Results` with elements sorted by the given sort descriptors.
    */
    override func sorted<S: Sequence where S.Iterator.Element == SortDescriptor>
                        (with sortDescriptors: S) -> Results<C.Element> {
        return base.sorted(with: sortDescriptors)
    }


    // MARK: Aggregate Operations

    /**
    Returns the minimum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a minimum on.

    - returns: The minimum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    override func minimumValue<U: MinMaxType>(ofProperty property: String) -> U? {
        return base.minimumValue(ofProperty: property)
    }

    /**
    Returns the maximum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a maximum on.

    - returns: The maximum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    override func maximumValue<U: MinMaxType>(ofProperty property: String) -> U? {
        return base.maximumValue(ofProperty: property)
    }

    /**
    Returns the sum of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.

    - returns: The sum of the given property over all objects in the collection.
    */
    override func sum<U: AddableType>(ofProperty property: String) -> U {
        return base.sum(ofProperty: property)
    }

    /**
    Returns the average of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate average on.

    - returns: The average of the given property over all objects in the collection, or `nil` if the
               collection is empty.
    */
    override func average<U: AddableType>(ofProperty property: String) -> U? {
        return base.average(ofProperty: property)
    }


    // MARK: Sequence Support

    /**
    Returns the object at the given `index`.

    - parameter index: The index.

    - returns: The object at the given `index`.
    */
    override subscript(position: Int) -> C.Element {
        // FIXME: it should be possible to avoid this force-casting
        return unsafeBitCast(base[position as! C.Index], to: C.Element.self)
    }

    /// Returns a `RLMIterator` that yields successive elements in the collection.
    override func makeIterator() -> RLMIterator<Element> {
        // FIXME: it should be possible to avoid this force-casting
        return base.makeIterator() as! RLMIterator<Element>
    }


    // MARK: Collection Support

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    override var startIndex: Int {
        // FIXME: it should be possible to avoid this force-casting
        return base.startIndex as! Int
    }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    override var endIndex: Int {
        // FIXME: it should be possible to avoid this force-casting
        return base.endIndex as! Int
    }


    // MARK: Key-Value Coding

    /**
    Returns an Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.

    - parameter key: The name of the property.

    - returns: Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.
    */
    override func value(forKey key: String) -> AnyObject? { return base.value(forKey: key) }

    /**
     Returns an Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.

     - parameter keyPath: The key path to the property.

     - returns: Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
       collection's objects.
     */
    override func value(forKeyPath keyPath: String) -> AnyObject? { return base.value(forKeyPath: keyPath) }

    /**
    Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified value and key.

    - warning: This method can only be called during a write transaction.

    - parameter value: The object value.
    - parameter key:   The name of the property.
    */
    override func setValue(_ value: AnyObject?, forKey key: String) { base.setValue(value, forKey: key) }

    // MARK: Notifications

    /// :nodoc:
    override func _addNotificationBlock(block: (RealmCollectionChange<Wrapper>) -> Void)
        -> NotificationToken { return base._addNotificationBlock(block: block) }
}

/**
A type-erased `RealmCollection`.

Forwards operations to an arbitrary underlying collection having the same
Element type, hiding the specifics of the underlying `RealmCollection`.
*/
public final class AnyRealmCollection<T: Object>: RealmCollection {

    public func index(after i: Int) -> Int { return i + 1 }
    public func index(before i: Int) -> Int { return i - 1 }

    /// Element type contained in this collection.
    public typealias Element = T
    private let base: _AnyRealmCollectionBase<T>

    /// Creates an AnyRealmCollection wrapping `base`.
    public init<C: RealmCollection where C.Element == T>(_ base: C) {
        self.base = _AnyRealmCollection(base: base)
    }

    // MARK: Properties

    /// The Realm the objects in this collection belong to, or `nil` if the
    /// collection's owning object does not belong to a realm (the collection is
    /// standalone).
    public var realm: Realm? { return base.realm }

    /// Indicates if the collection can no longer be accessed.
    ///
    /// The collection can no longer be accessed if `invalidate` is called on the containing `Realm`.
    public var isInvalidated: Bool { return base.isInvalidated }

    /// Returns the number of objects in this collection.
    public var count: Int { return base.count }

    /// Returns a human-readable description of the objects contained in this collection.
    public var description: String { return base.description }


    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the collection.

    - parameter object: The object whose index is being queried.

    - returns: The index of the given object, or `nil` if the object is not in the collection.
    */
    public func index(of object: Element) -> Int? { return base.index(of: object) }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` no objects match.

    - parameter predicate: The `NSPredicate` used to filter the objects.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    public func indexOfObject(for predicate: Predicate) -> Int? { return base.indexOfObject(for: predicate) }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if no objects match.

    - parameter predicateFormat: The predicate format string, optionally followed by a variable number
    of arguments.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    public func indexOfObject(for predicateFormat: String, _ args: AnyObject...) -> Int? {
        return base.indexOfObject(for: Predicate(format: predicateFormat, argumentArray: args))
    }

    // MARK: Filtering

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicateFormat: The predicate format string which can accept variable arguments.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    public func filter(using predicateFormat: String, _ args: AnyObject...) -> Results<Element> {
        return base.filter(using: Predicate(format: predicateFormat, argumentArray: args))
    }

    /**
    Returns `Results` containing collection elements that match the given predicate.

    - parameter predicate: The predicate to filter the objects.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    public func filter(using predicate: Predicate) -> Results<Element> { return base.filter(using: predicate) }


    // MARK: Sorting

    /**
    Returns `Results` containing collection elements sorted by the given property.

    - parameter property:  The property name to sort by.
    - parameter ascending: The direction to sort by.

    - returns: `Results` containing collection elements sorted by the given property.
    */
    public func sorted(onProperty property: String, ascending: Bool) -> Results<Element> {
        return base.sorted(onProperty: property, ascending: ascending)
    }

    /**
    Returns `Results` with elements sorted by the given sort descriptors.

    - parameter sortDescriptors: `SortDescriptor`s to sort by.

    - returns: `Results` with elements sorted by the given sort descriptors.
    */
    public func sorted<S: Sequence where S.Iterator.Element == SortDescriptor>
                      (with sortDescriptors: S) -> Results<Element> {
        return base.sorted(with: sortDescriptors)
    }


    // MARK: Aggregate Operations

    /**
    Returns the minimum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a minimum on.

    - returns: The minimum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    public func minimumValue<U: MinMaxType>(ofProperty property: String) -> U? {
        return base.minimumValue(ofProperty: property)
    }

    /**
    Returns the maximum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a maximum on.

    - returns: The maximum value for the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    public func maximumValue<U: MinMaxType>(ofProperty property: String) -> U? {
        return base.maximumValue(ofProperty: property)
    }

    /**
    Returns the sum of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.

    - returns: The sum of the given property over all objects in the collection.
    */
    public func sum<U: AddableType>(ofProperty property: String) -> U { return base.sum(ofProperty: property) }

    /**
    Returns the average of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate average on.

    - returns: The average of the given property over all objects in the collection, or `nil` if the
               collection is empty.
    */
    public func average<U: AddableType>(ofProperty property: String) -> U? { return base.average(ofProperty: property) }


    // MARK: Sequence Support

    /**
    Returns the object at the given `index`.

    - parameter index: The index.

    - returns: The object at the given `index`.
    */
    public subscript(position: Int) -> T { return base[position] }

    /// Returns a `RLMIterator` that yields successive elements in the collection.
    public func makeIterator() -> RLMIterator<T> { return base.makeIterator() }


    // MARK: Collection Support

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int { return base.startIndex }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    public var endIndex: Int { return base.endIndex }


    // MARK: Key-Value Coding

    /**
    Returns an Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.

    - parameter key: The name of the property.

    - returns: Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.
    */
    public func value(forKey key: String) -> AnyObject? { return base.value(forKey: key) }

    /**
     Returns an Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.

     - parameter keyPath: The key path to the property.

     - returns: Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.
     */
    public func value(forKeyPath keyPath: String) -> AnyObject? { return base.value(forKeyPath: keyPath) }

    /**
    Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified value and key.

    - warning: This method can only be called during a write transaction.

    - parameter value: The object value.
    - parameter key:   The name of the property.
    */
    public func setValue(_ value: AnyObject?, forKey key: String) { base.setValue(value, forKey: key) }

    // MARK: Notifications

    /**
     Register a block to be called each time the collection changes.

     The block will be asynchronously called with the initial results, and then
     called again after each write transaction which changes either any of the
     objects in the collection, or which objects are in the collection.

     At the time when the block is called, the collection object will be fully
     evaluated and up-to-date, and as long as you do not perform a write
     transaction on the same thread or explicitly call realm.refresh(),
     accessing it will never perform blocking work.

     Notifications are delivered via the standard run loop, and so can't be
     delivered while the run loop is blocked by other activity. When
     notifications can't be delivered instantly, multiple notifications may be
     coalesced into a single notification. This can include the notification
     with the initial collection. For example, the following code performs a write
     transaction immediately after adding the notification block, so there is no
     opportunity for the initial notification to be delivered first. As a
     result, the initial notification will reflect the state of the Realm after
     the write transaction.

         let results = realm.objects(Dog)
         print("dogs.count: \(dogs?.count)") // => 0
         let token = dogs.addNotificationBlock { (changes: RealmCollectionChange) in
             switch changes {
                 case .Initial(let dogs):
                     // Will print "dogs.count: 1"
                     print("dogs.count: \(dogs.count)")
                     break
                 case .Update:
                     // Will not be hit in this example
                     break
                 case .Error:
                     break
             }
         }
         try! realm.write {
             let dog = Dog()
             dog.name = "Rex"
             person.dogs.append(dog)
         }
         // end of run loop execution context

     You must retain the returned token for as long as you want updates to continue
     to be sent to the block. To stop receiving updates, call stop() on the token.

     - warning: This method cannot be called during a write transaction, or when
                the source realm is read-only.

     - parameter block: The block to be called with the evaluated collection and change information.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection>) -> ())
        -> NotificationToken { return base._addNotificationBlock(block: block) }

    /// :nodoc:
    public func _addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection>) -> ())
        -> NotificationToken { return base._addNotificationBlock(block: block) }
}


// MARK: Unavailable

extension AnyRealmCollection {
    @available(*, unavailable, renamed:"isInvalidated")
    public var invalidated : Bool { fatalError() }

    @available(*, unavailable, renamed:"indexOfObject(for:)")
    public func index(of predicate: Predicate) -> Int? { fatalError() }

    @available(*, unavailable, renamed:"indexOfObject(for:_:)")
    public func index(of predicateFormat: String, _ args: AnyObject...) -> Int? { fatalError() }

    @available(*, unavailable, renamed:"filter(using:)")
    public func filter(_ predicate: Predicate) -> Results<T> { fatalError() }

    @available(*, unavailable, renamed:"filter(using:_:)")
    public func filter(_ predicateFormat: String, _ args: AnyObject...) -> Results<T> { fatalError() }

    @available(*, unavailable, renamed:"sorted(onProperty:ascending:)")
    public func sorted(_ property: String, ascending: Bool = true) -> Results<T> { fatalError() }

    @available(*, unavailable, renamed:"sorted(with:)")
    public func sorted<S: Sequence where S.Iterator.Element == SortDescriptor>(_ sortDescriptors: S) -> Results<T> {
        fatalError()
    }

    @available(*, unavailable, renamed:"minimumValue(ofProperty:)")
    public func min<U: MinMaxType>(_ property: String) -> U? { fatalError() }

    @available(*, unavailable, renamed:"maximumValue(ofProperty:)")
    public func max<U: MinMaxType>(_ property: String) -> U? { fatalError() }

    @available(*, unavailable, renamed:"sum(ofProperty:)")
    public func sum<U: AddableType>(_ property: String) -> U { fatalError() }

    @available(*, unavailable, renamed:"average(ofProperty:)")
    public func average<U: AddableType>(_ property: String) -> U? { fatalError() }
}

#else

/**
 An iterator for a `RealmCollectionType` instance.
*/
public final class RLMGenerator<T: Object>: GeneratorType {
    private let generatorBase: NSFastGenerator

    internal init(collection: RLMCollection) {
        generatorBase = NSFastGenerator(collection)
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public func next() -> T? { // swiftlint:disable:this valid_docs
        let accessor = generatorBase.next() as! T?
        if let accessor = accessor {
            RLMInitializeSwiftAccessorGenerics(accessor)
        }
        return accessor
    }
}

/**
 A `RealmCollectionChange` value encapsulates information about changes to collections
 that are reported by Realm notifications.

 The change information is available in two formats: a simple array of row
 indices in the collection for each type of change, and an array of index paths
 in a requested section suitable for passing directly to `UITableView`'s batch
 update methods.

 The arrays of indices in the `.Update` case follow `UITableView`'s batching
 conventions, and can be passed as-is to a table view's batch update functions after being converted to index paths.
 For example, for a simple one-section table view, you can do the following:

 ```swift
 self.notificationToken = results.addNotificationBlock { changes in
     switch changes {
     case .Initial:
         // Results are now populated and can be accessed without blocking the UI
         self.tableView.reloadData()
         break
     case .Update(_, let deletions, let insertions, let modifications):
         // Query results have changed, so apply them to the TableView
         self.tableView.beginUpdates()
         self.tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) },
             withRowAnimation: .Automatic)
         self.tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) },
             withRowAnimation: .Automatic)
         self.tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) },
             withRowAnimation: .Automatic)
         self.tableView.endUpdates()
         break
     case .Error(let err):
         // An error occurred while opening the Realm file on the background worker thread
         fatalError("\(err)")
         break
     }
 }
 ```
 */
public enum RealmCollectionChange<T> {
    /// `.Initial` indicates that the initial run of the query has completed (if applicable), and the
    /// collection can now be used without performing any blocking work.
    case Initial(T)

    /// `.Update` indicates that a write transaction has been committed which either changed which objects
    /// are in the collection, and/or modified one or more of the objects in the collection.
    ///
    /// All three of the change arrays are always sorted in ascending order.
    ///
    /// - parameter deletions:     The indices in the previous version of the collection
    ///                            which were removed from this one.
    /// - parameter insertions:    The indices in the new collection which were added in
    ///                            this version.
    /// - parameter modifications: The indices of the objects in the new collection which
    ///                            were modified in this version.
    case Update(T, deletions: [Int], insertions: [Int], modifications: [Int])

    /// If an error occurs, notification blocks are called one time with a
    /// `.Error` result and an `NSError` containing details about the error. This can only currently happen if the
    /// Realm is opened on a background worker thread to calculate the change set.
    case Error(NSError)

    static func fromObjc(value: T, change: RLMCollectionChange?, error: NSError?) -> RealmCollectionChange {
        if let error = error {
            return .Error(error)
        }
        if let change = change {
            return .Update(value,
                deletions: change.deletions as! [Int],
                insertions: change.insertions as! [Int],
                modifications: change.modifications as! [Int])
        }
        return .Initial(value)
    }
}

/**
 A homogenous collection of `Object`s which can be retrieved, filtered, sorted,
 and operated upon.
*/
public protocol RealmCollectionType: CollectionType, CustomStringConvertible {

    /// The type of the objects contained in the collection.
    associatedtype Element: Object


    // MARK: Properties

    /// The Realm which manages the collection, or `nil` for unmanaged collections.
    var realm: Realm? { get }

    /// Indicates if the collection can no longer be accessed.
    ///
    /// The collection can no longer be accessed if `invalidate` is called on the `Realm` that manages the collection.
    var invalidated: Bool { get }

    /// The number of objects in the collection.
    var count: Int { get }

    /// A human-readable description of the objects contained in the collection.
    var description: String { get }


    // MARK: Index Retrieval

    /**
     Returns the index of an object in the collection, or `nil` if the object is not present.

     - parameter object: An object.
     */
    func indexOf(object: Element) -> Int?

    /**
     Returns the index of the first object matching the predicate, or `nil` if no objects match.

     - parameter predicate: The predicate to use to filter the objects.
     */
    func indexOf(predicate: NSPredicate) -> Int?

    /**
     Returns the index of the first object matching the predicate, or `nil` if no objects match.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.
     */
    func indexOf(predicateFormat: String, _ args: AnyObject...) -> Int?


    // MARK: Filtering

    /**
     Returns all objects matching the given predicate in the collection.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.

     - returns: A `Results` containing objects that match the given predicate.
     */
    func filter(predicateFormat: String, _ args: AnyObject...) -> Results<Element>

    /**
     Returns all objects matching the given predicate in the collection.

     - parameter predicate: The predicate to use to filter the objects.

     - returns: A `Results` containing objects that match the given predicate.
     */
    func filter(predicate: NSPredicate) -> Results<Element>


    // MARK: Sorting

    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     Objects are sorted based on the values of the given property. For example, to sort a collection of `Student`s from
     youngest to oldest based on their `age` property, you might call `students.sorted("age", ascending: true)`.

     - warning: Collections may only be sorted by properties of boolean, `NSDate`, single and double-precision floating
                point, integer, and string types.

     - parameter property:  The name of the property to sort by.
     - parameter ascending: The direction to sort in.
     */
    func sorted(property: String, ascending: Bool) -> Results<Element>

    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     - warning: Collections may only be sorted by properties of boolean, `NSDate`, single and double-precision floating
                point, integer, and string types.

     - see: `sorted(_:ascending:)`

     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     */
    func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>(sortDescriptors: S) -> Results<Element>


    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects represented by the collection.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.

     - returns: The minimum value of the property, or `nil` if the collection is empty.
     */
    func min<U: MinMaxType>(property: String) -> U?

    /**
     Returns the maximum (highest) value of the given property among all the objects represented by the collection.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.

     - returns: The maximum value of the property, or `nil` if the collection is empty.
     */
    func max<U: MinMaxType>(property: String) -> U?

    /**
     Returns the sum of the values of a given property over all the objects represented by the collection.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.

     - returns: The sum of the given property.
     */
    func sum<U: AddableType>(property: String) -> U

    /**
     Returns the average value of a given property over all the objects represented by the collection.

     - warning: Only the name of a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose average value should be calculated.

     - returns: The average value of the given property, or `nil` if the collection is empty.
     */
    func average<U: AddableType>(property: String) -> U?


    // MARK: Key-Value Coding

    /**
     Returns an `Array` containing the results of invoking `valueForKey(_:)` with `key` on each of the collection's
     objects.

     - parameter key: The name of the property whose values are desired.
     */
    func valueForKey(key: String) -> AnyObject?

    /**
     Returns an `Array` containing the results of invoking `valueForKeyPath(_:)` with `keyPath` on each of the
     collection's objects.

     - parameter keyPath: The key path to the property whose values are desired.
     */
    func valueForKeyPath(keyPath: String) -> AnyObject?

    /**
     Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified `value` and `key`.

     - warning: This method may only be called during a write transaction.

     - parameter value: The object value.
     - parameter key:   The name of the property whose value should be set on each object.
     */
    func setValue(value: AnyObject?, forKey key: String)

    // MARK: Notifications

    /**
     Registers a block to be called each time the collection changes.

     The block will be asynchronously called with the initial results, and then
     called again after each write transaction which changes either any of the
     objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the
     collection, which of the objects were added, removed, or modified during each write transaction. See the
     `RealmCollectionChange` documentation for more information on the change information supplied and an example of how
     to use it to update a `UITableView`.

     At the time when the block is called, the collection will be fully
     evaluated and up-to-date, and as long as you do not perform a write
     transaction on the same thread or explicitly call `realm.refresh()`,
     accessing it will never perform blocking work.

     Notifications are delivered via the standard run loop, and so can't be
     delivered while the run loop is blocked by other activity. When
     notifications can't be delivered instantly, multiple notifications may be
     coalesced into a single notification. This can include the notification
     with the initial collection. For example, the following code performs a write
     transaction immediately after adding the notification block, so there is no
     opportunity for the initial notification to be delivered first. As a
     result, the initial notification will reflect the state of the Realm after
     the write transaction.

     ```swift
     let results = realm.objects(Dog.self)
     print("dogs.count: \(dogs?.count)") // => 0
     let token = dogs.addNotificationBlock { changes in
         switch changes {
             case .Initial(let dogs):
                 // Will print "dogs.count: 1"
                 print("dogs.count: \(dogs.count)")
                 break
             case .Update:
                 // Will not be hit in this example
                 break
             case .Error:
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
     updates, call `stop()` on the token.

     - warning: This method cannot be called during a write transaction, or when
                the containing Realm is read-only.

     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be retained for as long as you want updates to be delivered.
     */
    func addNotificationBlock(block: (RealmCollectionChange<Self>) -> Void) -> NotificationToken

    /// :nodoc:
    func _addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection<Element>>) -> Void) -> NotificationToken
}

private class _AnyRealmCollectionBase<T: Object> {
    typealias Wrapper = AnyRealmCollection<Element>
    typealias Element = T
    var realm: Realm? { fatalError() }
    var invalidated: Bool { fatalError() }
    var count: Int { fatalError() }
    var description: String { fatalError() }
    func indexOf(object: Element) -> Int? { fatalError() }
    func indexOf(predicate: NSPredicate) -> Int? { fatalError() }
    func indexOf(predicateFormat: String, _ args: AnyObject...) -> Int? { fatalError() }
    func filter(predicateFormat: String, _ args: AnyObject...) -> Results<Element> { fatalError() }
    func filter(predicate: NSPredicate) -> Results<Element> { fatalError() }
    func sorted(property: String, ascending: Bool) -> Results<Element> { fatalError() }
    func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>(sortDescriptors: S) -> Results<Element> {
        fatalError()
    }
    func min<U: MinMaxType>(property: String) -> U? { fatalError() }
    func max<U: MinMaxType>(property: String) -> U? { fatalError() }
    func sum<U: AddableType>(property: String) -> U { fatalError() }
    func average<U: AddableType>(property: String) -> U? { fatalError() }
    subscript(index: Int) -> Element { fatalError() }
    func generate() -> RLMGenerator<T> { fatalError() }
    var startIndex: Int { fatalError() }
    var endIndex: Int { fatalError() }
    func valueForKey(key: String) -> AnyObject? { fatalError() }
    func valueForKeyPath(keyPath: String) -> AnyObject? { fatalError() }
    func setValue(value: AnyObject?, forKey key: String) { fatalError() }
    func _addNotificationBlock(block: (RealmCollectionChange<Wrapper>) -> Void)
        -> NotificationToken { fatalError() }
}

private final class _AnyRealmCollection<C: RealmCollectionType>: _AnyRealmCollectionBase<C.Element> {
    let base: C
    init(base: C) {
        self.base = base
    }

    // TODO (az): copyedit private docstrings
    // MARK: Properties

    /// The Realm the objects in this collection belong to, or `nil` if the
    /// collection's owning object does not belong to a realm (the collection is
    /// unmanaged).
    override var realm: Realm? { return base.realm }

    /// Indicates if the collection can no longer be accessed.
    ///
    /// The collection can no longer be accessed if `invalidate` is called on the containing `Realm`.
    override var invalidated: Bool { return base.invalidated }

    /// Returns the number of objects in this collection.
    override var count: Int { return base.count }

    /// Returns a human-readable description of the objects contained in this collection.
    override var description: String { return base.description }


    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the collection.

    - parameter object: The object whose index is being queried.
    */
    override func indexOf(object: C.Element) -> Int? { return base.indexOf(object) }

    /**
    Returns the index of the first object matching the given predicate, or `nil` no objects match.

    - parameter predicate: The `NSPredicate` used to filter the objects.
    */
    override func indexOf(predicate: NSPredicate) -> Int? { return base.indexOf(predicate) }

    /**
    Returns the index of the first object matching the given predicate, or `nil` if no objects match.

    - parameter predicateFormat: A predicate format string, optionally followed by a variable number
                                 of arguments.
    */
    override func indexOf(predicateFormat: String, _ args: AnyObject...) -> Int? {
        return base.indexOf(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    // MARK: Filtering

    /**
    Returns a `Results` containing collection elements that match the given predicate.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number
                                  of arguments.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    override func filter(predicateFormat: String, _ args: AnyObject...) -> Results<C.Element> {
        return base.filter(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    /**
    Returns a `Results` containing collection elements that match the given predicate.

    - parameter predicate: The predicate to use to filter the objects.

    - returns: `Results` containing collection elements that match the given predicate.
    */
    override func filter(predicate: NSPredicate) -> Results<C.Element> { return base.filter(predicate) }


    // MARK: Sorting

    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     Objects are sorted based on the values of the given property. For example, to sort a collection of `Student`s from
     youngest to oldest based on their `age` property, you might call `students.sorted("age", ascending: true)`.

     - warning: Collections may only be sorted by properties of boolean, `NSDate`, single and double-precision floating
                point, integer, and string types.

     - parameter property:  The name of the property to sort by.
     - parameter ascending: The direction to sort in.
     */
    override func sorted(property: String, ascending: Bool) -> Results<C.Element> {
        return base.sorted(property, ascending: ascending)
    }

    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     - warning: Collections may only be sorted by properties of boolean, `NSDate`, single and double-precision floating
                point, integer, and string types.

     - see: `sorted(_:ascending:)`

     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     */
    override func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>
                        (sortDescriptors: S) -> Results<C.Element> {
        return base.sorted(sortDescriptors)
    }


    // MARK: Aggregate Operations

    /**
    Returns the minimum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a minimum on.

    - returns: The minimum value of the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    override func min<U: MinMaxType>(property: String) -> U? { return base.min(property) }

    /**
    Returns the maximum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a maximum on.

    - returns: The maximum value of the property amongst objects in the collection, or `nil` if the
               collection is empty.
    */
    override func max<U: MinMaxType>(property: String) -> U? { return base.max(property) }

    /**
    Returns the sum of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.

    - returns: The sum of the given property over all objects in the collection.
    */
    override func sum<U: AddableType>(property: String) -> U { return base.sum(property) }

    /**
    Returns the average of the given property for objects in the collection.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate average on.

    - returns: The average of the given property over all objects in the collection, or `nil` if the
               collection is empty.
    */
    override func average<U: AddableType>(property: String) -> U? { return base.average(property) }


    // MARK: Sequence Support

    /**
    Returns the object at the given `index`.

    - parameter index: The index.

    - returns: The object at the given `index`.
    */
    override subscript(index: Int) -> C.Element {
        // FIXME: it should be possible to avoid this force-casting
        return unsafeBitCast(base[index as! C.Index], C.Element.self)
    }

    /// Returns an `RLMGenerator` that yields successive elements in the collection.
    override func generate() -> RLMGenerator<Element> {
        // FIXME: it should be possible to avoid this force-casting
        return base.generate() as! RLMGenerator<Element>
    }


    // MARK: Collection Support

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    override var startIndex: Int {
        // FIXME: it should be possible to avoid this force-casting
        return base.startIndex as! Int
    }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    override var endIndex: Int {
        // FIXME: it should be possible to avoid this force-casting
        return base.endIndex as! Int
    }


    // MARK: Key-Value Coding

    /**
    Returns an Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.

    - parameter key: The name of the property.

    - returns: Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.
    */
    override func valueForKey(key: String) -> AnyObject? { return base.valueForKey(key) }

    /**
     Returns an Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.

     - parameter keyPath: The key path to the property.

     - returns: Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
       collection's objects.
     */
    override func valueForKeyPath(keyPath: String) -> AnyObject? { return base.valueForKeyPath(keyPath) }

    /**
    Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified value and key.

    - warning: This method can only be called during a write transaction.

    - parameter value: The object value.
    - parameter key:   The name of the property.
    */
    override func setValue(value: AnyObject?, forKey key: String) { base.setValue(value, forKey: key) }

    // MARK: Notifications

    /// :nodoc:
    override func _addNotificationBlock(block: (RealmCollectionChange<Wrapper>) -> Void)
        -> NotificationToken { return base._addNotificationBlock(block) }
}

/**
 A type-erased `RealmCollectionType`.

 Instances of `RealmCollectionType` forward operations to an opaque underlying collection having the same `Element`
 type.
 */
public final class AnyRealmCollection<T: Object>: RealmCollectionType {

    /// The type of the objects contained in the collection.
    public typealias Element = T
    private let base: _AnyRealmCollectionBase<T>

    /// Creates an `AnyRealmCollection` wrapping `base`.
    public init<C: RealmCollectionType where C.Element == T>(_ base: C) {
        self.base = _AnyRealmCollection(base: base)
    }

    // MARK: Properties

    /// The Realm which manages this collection, or `nil` if the collection is unmanaged.
    public var realm: Realm? { return base.realm }

    /// Indicates if the collection can no longer be accessed.
    ///
    /// The collection can no longer be accessed if `invalidate` is called on the containing `realm`.
    public var invalidated: Bool { return base.invalidated }

    /// The number of objects in the collection.
    public var count: Int { return base.count }

    /// A human-readable description of the objects contained in the collection.
    public var description: String { return base.description }


    // MARK: Index Retrieval

    /**
     Returns the index of the given object, or `nil` if the object is not in the collection.

     - parameter object: An object.
     */
    public func indexOf(object: Element) -> Int? { return base.indexOf(object) }

    /**
     Returns the index of the first object matching the given predicate, or `nil` if no objects match.

     - parameter predicate: The predicate with which to filter the objects.
     */
    public func indexOf(predicate: NSPredicate) -> Int? { return base.indexOf(predicate) }

    /**
     Returns the index of the first object matching the given predicate, or `nil` if no objects match.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.
     */
    public func indexOf(predicateFormat: String, _ args: AnyObject...) -> Int? {
        return base.indexOf(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    // MARK: Filtering

    /**
     Returns a `Results` containing all objects matching the given predicate in the collection.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.
     */
    public func filter(predicateFormat: String, _ args: AnyObject...) -> Results<Element> {
        return base.filter(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    /**
     Returns a `Results` containing all objects matching the given predicate in the collection.

     - parameter predicate: The predicate with which to filter the objects.

     - returns: A `Results` containing objects that match the given predicate.
     */
    public func filter(predicate: NSPredicate) -> Results<Element> { return base.filter(predicate) }


    // MARK: Sorting

    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     Objects are sorted based on the values of the given property. For example, to sort a collection of `Student`s from
     youngest to oldest based on their `age` property, you might call `students.sorted("age", ascending: true)`.

     - warning: Collections may only be sorted by properties of boolean, `NSDate`, single and double-precision floating
                point, integer, and string types.

     - parameter property:  The name of the property to sort by.
     - parameter ascending: The direction to sort in.
     */
    public func sorted(property: String, ascending: Bool) -> Results<Element> {
        return base.sorted(property, ascending: ascending)
    }

    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     - warning: Collections may only be sorted by properties of boolean, `NSDate`, single and double-precision floating
                point, integer, and string types.

     - see: `sorted(_:ascending:)`

     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     */
    public func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>
                      (sortDescriptors: S) -> Results<Element> {
        return base.sorted(sortDescriptors)
    }


    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects represented by the collection.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.

     - returns: The minimum value of the property, or `nil` if the collection is empty.
     */
    public func min<U: MinMaxType>(property: String) -> U? { return base.min(property) }

    /**
     Returns the maximum (highest) value of the given property among all the objects represented by the collection.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.

     - returns: The maximum value of the property, or `nil` if the collection is empty.
     */
    public func max<U: MinMaxType>(property: String) -> U? { return base.max(property) }

    /**
     Returns the sum of the values of a given property over all the objects represented by the collection.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.

     - returns: The sum of the given property.
     */
    public func sum<U: AddableType>(property: String) -> U { return base.sum(property) }

    /**
     Returns the average value of a given property over all the objects represented by the collection.

     - warning: Only the name of a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose average value should be calculated.

     - returns: The average value of the given property, or `nil` if the collection is empty.
     */
    public func average<U: AddableType>(property: String) -> U? { return base.average(property) }


    // MARK: Sequence Support

    /**
     Returns the object at the given `index`.

     - parameter index: The index.

     - returns: The object at the given `index`.
    */
    public subscript(index: Int) -> T { return base[index] }

    /// Returns an `RLMGenerator` that yields successive elements in the collection.
    public func generate() -> RLMGenerator<T> { return base.generate() }


    // MARK: Collection Support

    /// The position of the first element in a non-empty collection.
    /// Identical to `endIndex` in an empty collection.
    public var startIndex: Int { return base.startIndex }

    /// The collection's "past the end" position.
    /// `endIndex` is not a valid argument to `subscript`, and is always reachable from `startIndex` by
    /// zero or more applications of `successor()`.
    public var endIndex: Int { return base.endIndex }


    // MARK: Key-Value Coding

    /**
     Returns an `Array` containing the results of invoking `valueForKey(_:)` with `key` on each of the collection's
     objects.

     - parameter key: The name of the property whose values are desired.

     - returns: An `Array` containing the results.
     */
    public func valueForKey(key: String) -> AnyObject? { return base.valueForKey(key) }

    /**
     Returns an `Array` containing the results of invoking `valueForKeyPath(_:)` with `keyPath` on each of the
     collection's objects.

     - parameter keyPath: The key path to the property whose values are desired.

     - returns: An `Array` containing the results.
     */
    public func valueForKeyPath(keyPath: String) -> AnyObject? { return base.valueForKeyPath(keyPath) }

    /**
     Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified `value` and `key`.

     - warning: This method may only be called during a write transaction.

     - parameter value: The value to set the property to.
     - parameter key:   The name of the property whose value should be set on each object.
     */
    public func setValue(value: AnyObject?, forKey key: String) { base.setValue(value, forKey: key) }

    // MARK: Notifications

    /**
     Registers a block to be called each time the collection changes.

     The block will be asynchronously called with the initial results, and then
     called again after each write transaction which changes either any of the
     objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the
     collection, which of the objects were added, removed, or modified during each write transaction. See the
     `RealmCollectionChange` documentation for more information on the change information supplied and an example of how
     to use it to update a `UITableView`.

     At the time when the block is called, the collection will be fully
     evaluated and up-to-date, and as long as you do not perform a write
     transaction on the same thread or explicitly call `realm.refresh()`,
     accessing it will never perform blocking work.

     Notifications are delivered via the standard run loop, and so can't be
     delivered while the run loop is blocked by other activity. When
     notifications can't be delivered instantly, multiple notifications may be
     coalesced into a single notification. This can include the notification
     with the initial collection. For example, the following code performs a write
     transaction immediately after adding the notification block, so there is no
     opportunity for the initial notification to be delivered first. As a
     result, the initial notification will reflect the state of the Realm after
     the write transaction.

     ```swift
     let results = realm.objects(Dog.self)
     print("dogs.count: \(dogs?.count)") // => 0
     let token = dogs.addNotificationBlock { changes in
         switch changes {
             case .Initial(let dogs):
                 // Will print "dogs.count: 1"
                 print("dogs.count: \(dogs.count)")
                 break
             case .Update:
                 // Will not be hit in this example
                 break
             case .Error:
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
     updates, call `stop()` on the token.

     - warning: This method cannot be called during a write transaction, or when
                the containing Realm is read-only.

     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be retained for as long as you want updates to be delivered.
     */
    public func addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection>) -> ())
        -> NotificationToken { return base._addNotificationBlock(block) }

    /// :nodoc:
    public func _addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection>) -> ())
        -> NotificationToken { return base._addNotificationBlock(block) }
}

#endif
