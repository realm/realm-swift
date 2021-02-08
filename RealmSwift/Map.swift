//
//  File.swift
//  RealmSwift
//
//  Created by Pavel Yakimenko on 27/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

import Foundation
import Realm
import Realm.Private

/**
 * Key-value collection. Where the key is a string and value is one of the available Realm types.
 * We use Map to don't intefere with the native Swift's Dictionary type.
 */
public final class Map<Element: RealmCollectionValue>: RLMDictionaryBase {

    // MARK: Properties

    /// The Realm which manages the dictionary, or `nil` if the dictionary is unmanaged.
    public var realm: Realm? {
        return _rlmDictionary.realm.map { Realm($0) }
    }

    /// Indicates if the dictionary can no longer be accessed.
    public var isInvalidated: Bool { return _rlmDictionary.isInvalidated }

    // MARK: Initializers

    /// Creates a `Map` that holds Realm model objects of type `Element`.
    public override init() {
        super.init()
    }

    internal init(objc _rlmDictionary: RLMDictionary<AnyObject>) {
        super.init(dictionary: _rlmDictionary)
    }

    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects in the collection, or `nil` if the
     collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func min<T: MinMaxType>(ofProperty property: String) -> T? {
        return _rlmDictionary.min(ofProperty: property).map(dynamicBridgeCast)
    }

    /**
     Returns the maximum (highest) value of the given property among all the objects in the collection, or `nil` if the
     collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func max<T: MinMaxType>(ofProperty property: String) -> T? {
        return _rlmDictionary.max(ofProperty: property).map(dynamicBridgeCast)
    }

    /**
    Returns the sum of the given property for objects in the collection, or `nil` if the collection is empty.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.
    */
    public func sum<T: AddableType>(ofProperty property: String) -> T {
        return dynamicBridgeCast(fromObjectiveC: _rlmDictionary.sum(ofProperty: property))
    }

    /**
     Returns the average value of a given property over all the objects in the collection, or `nil` if
     the collection is empty.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.
     */
    public func average<T: AddableType>(ofProperty property: String) -> T? {
        return _rlmDictionary.average(ofProperty: property).map(dynamicBridgeCast)
    }
    
    // MARK: Filtering

    /**
     Returns a `Results` containing all objects matching the given predicate in the dictionary.

     - parameter predicate: The predicate with which to filter the objects.
     */
    public func filter(_ predicate: NSPredicate) -> Results<Element> {
        return Results<Element>(_rlmDictionary.objects(with: predicate))
    }

    // MARK: Sorting

    /**
     Returns a `Results` containing the objects in the set, but sorted.

     Objects are sorted based on the values of the given key path. For example, to sort a set of `Student`s from
     youngest to oldest based on their `age` property, you might call
     `students.sorted(byKeyPath: "age", ascending: true)`.

     - warning: MutableSets may only be sorted by properties of boolean, `Date`, `NSDate`, single and double-precision
                floating point, integer, and string types.

     - parameter keyPath:  The key path to sort by.
     - parameter ascending: The direction to sort in.
     */
    public func sorted(byKeyPath keyPath: String, ascending: Bool = true) -> Results<Element> {
        return sorted(by: [SortDescriptor(keyPath: keyPath, ascending: ascending)])
    }

    /**
     Returns a `Results` containing the objects in the set, but sorted.

     - warning: MutableSets may only be sorted by properties of boolean, `Date`, `NSDate`, single and double-precision
                floating point, integer, and string types.

     - see: `sorted(byKeyPath:ascending:)`
    */
    public func sorted<S: Sequence>(by sortDescriptors: S) -> Results<Element>
        where S.Iterator.Element == SortDescriptor {
            return Results<Element>(_rlmDictionary.sortedResults(using: sortDescriptors.map { $0.rlmSortDescriptorValue }))
    }

    // MARK: Mutation

    /**
     Updates the value stored in the dictionary for the given key, or adds a new key-value pair if the key does not exist.
     */
    func updateValue(_ value: Element, forKey key: String) {
        _rlmDictionary[key] = dynamicBridgeCast(fromSwift: value) as AnyObject
    }

    /**
     Removes the given key and its associated object.
     */
    public func removeValue(for key: String) {
        _rlmDictionary.removeObject(forKey: key)
    }

    /**
     Removes all objects from the set. The objects are not removed from the Realm that manages them.

     - warning: This method may only be called during a write transaction.
     */
    public func removeAll() {
        _rlmDictionary.removeAllObjects()
    }

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
     let results = realm.objects(Dog.self)
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
         person.dogs.insert(dog)
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
    public func observe(on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmCollectionChange<Map>) -> Void) -> NotificationToken {
        return _rlmDictionary.addNotificationBlock(wrapObserveBlock(block), queue: queue)
    }

    // MARK: Frozen Objects

    public var isFrozen: Bool {
        return _rlmDictionary.isFrozen
    }

    public func freeze() -> Map {
        return Map(objc: _rlmDictionary.freeze())
    }

    public func thaw() -> Map? {
        return Map(objc: _rlmDictionary.thaw())
    }

    // swiftlint:disable:next identifier_name
    @objc class func _unmanagedDictionary() -> RLMDictionary<AnyObject> {
        return Element._rlmDictionary()
    }
}

extension Map where Element: MinMaxType {
    /**
     Returns the minimum (lowest) value in the map, or `nil` if the map is empty.
     */
    public func min() -> Element? {
        return _rlmDictionary.min(ofProperty: "self").map(dynamicBridgeCast)
    }

    /**
     Returns the maximum (highest) value in the map, or `nil` if the map is empty.
     */
    public func max() -> Element? {
        return _rlmDictionary.max(ofProperty: "self").map(dynamicBridgeCast)
    }
}

extension Map where Element: AddableType {
    /**
     Returns the sum of the values in the map.
     */
    public func sum() -> Element {
        return sum(ofProperty: "self")
    }

    /**
     Returns the average of the values in the map, or `nil` if the map is empty.
     */
    public func average<T: AddableType>() -> T? {
        return average(ofProperty: "self")
    }
}

extension Map: RealmCollection {
    /// The type of the objects stored within the set.
    public typealias ElementType = Element

    // MARK: Sequence Support

    /// Returns a `RLMIterator` that yields successive elements in the `Map`.
    public func makeIterator() -> RLMIterator<Element> {
        return RLMIterator(collection: _rlmDictionary)
    }

    /// :nodoc:
    public func asNSFastEnumerator() -> Any {
        return _rlmDictionary
    }

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int { return 0 }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    public var endIndex: Int { return count }

    public func index(after i: Int) -> Int { return i + 1 }
    public func index(before i: Int) -> Int { return i - 1 }

    /// :nodoc:
    // swiftlint:disable:next identifier_name
    public func _observe(_ queue: DispatchQueue?,
                         _ block: @escaping (RealmCollectionChange<AnyRealmCollection<Element>>) -> Void)
        -> NotificationToken {
            return _rlmDictionary.addNotificationBlock(wrapObserveBlock(block), queue: queue)
    }

    // MARK: Object Retrieval

    /**
     - warning: Ordering is not guaranteed on a Dictionary. Subscripting is implemented for
                convenience should not be relied on.
     */
    public subscript(position: Int) -> Element {
        return dynamicBridgeCast(fromObjectiveC: self.object(at: UInt(position)))
    }

    /// :nodoc:
    public func index(of object: Element) -> Int? {
        fatalError("index(of:) is not available on Map")
    }

    /// :nodoc:
    public func index(matching predicate: NSPredicate) -> Int? {
        fatalError("index(matching:) is not available on Map")
    }

    /**
     - warning: Ordering is not guaranteed on a Map. `first` is implemented for
                convenience should not be relied on.
     */
    public var first: Element? {
        return self[0]
    }

    /**
     - warning: Ordering is not guaranteed on a Map. `last` is implemented for
                convenience should not be relied on.
     */
    public var last: Element? {
        return self[count-1]
    }
}
