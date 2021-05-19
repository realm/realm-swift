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

/**
 A homogenous key-value collection of `Object`s which can be retrieved, filtered, sorted, and operated upon.
*/
public protocol RealmKeyedCollection: RealmCollectionBase, Sequence {
    associatedtype Key: MapKeyType
    associatedtype Value: RealmCollectionValue

    // MARK: Properties

    /// The Realm which manages the map, or `nil` if the map is unmanaged.
    var realm: Realm? { get }

    /// Indicates if the map can no longer be accessed.
    var isInvalidated: Bool { get }

    /// Returns the number of key-value pairs in this map.
    var count: Int { get }

     /// A human-readable description of the objects contained in the Map.
    var description: String { get }

    // MARK: Mutation

    /**
     Updates the value stored in the dictionary for the given key, or adds a new key-value pair if the key does not exist.

     - parameter value: a value's key path predicate.
     - parameter forKey: The direction to sort in.
     */
    func updateValue(_ value: Value, forKey key: Key)

    /**
     Removes the given key and its associated object.
     */
    func removeObject(for key: Key)

    /**
     Removes all objects from the dictionary. The objects are not removed from the Realm that manages them.

     - warning: This method may only be called during a write transaction.
     */
    func removeAll()

    subscript(key: Key) -> Value? { get set }

    // MARK: KVC

    /**
     Returns a type of `Value` for a specified key if it exists in the map.

     Note that when using key-value coding, the key must be a string.

     - parameter key: The key to the property whose values are desired.
     */
    func value(forKey key: String) -> AnyObject?

    /**
     Returns a type of `Value` for a specified key if it exists in the map.

     - parameter keyPath: The key to the property whose values are desired.
     */
    func value(forKeyPath keyPath: String) -> AnyObject?

    /**
     Adds a given key-value pair to the dictionary or updates a given key should it already exist.

     - warning: This method can only be called during a write transaction.

     - parameter value: The object value.
     - parameter key:   The name of the property whose value should be set on each object.
    */
    func setValue(_ value: Any?, forKey key: String)

    // MARK: Filtering

    /**
     Returns a `Results` containing all matching key-value pairs the given predicate in the Map.

     - parameter predicate: The predicate with which to filter the objects.
     */
    func filter(_ predicate: NSPredicate) -> Results<Value>

    /**
     Returns a Boolean value indicating whether the Map contains the key-value pair
     satisfies the given predicate

     - parameter where: a closure that test if any key-pair of the given map represents the match.
     */
    func contains(where predicate: @escaping (_ key: Key, _ value: Value) -> Bool) -> Bool

    // MARK: Sorting

    /**
     Returns a `Results` containing the objects in the dictionary, but sorted.

     Objects are sorted based on their values. For example, to sort a dictionary of `Date`s from
     neweset to oldest based, you might call `dates.sorted(ascending: true)`.

     - parameter ascending: The direction to sort in.
     */
    func sorted(ascending: Bool) -> Results<Value>

    /**
     Returns a `Results` containing the objects in the dictionary, but sorted.

     Objects are sorted based on the values of the given key path. For example, to sort a dictionary of `Student`s from
     youngest to oldest based on their `age` property, you might call
     `students.sorted(byKeyPath: "age", ascending: true)`.

     - warning: Dictionaries may only be sorted by properties of boolean, `Date`, `NSDate`, single and double-precision
                floating point, integer, and string types.

     - parameter keyPath:  The key path to sort by.
     - parameter ascending: The direction to sort in.
     */
    func sorted(byKeyPath keyPath: String, ascending: Bool) -> Results<Value>

    /**
     Returns a `Results` containing the objects in the dictionary, but sorted.

     - warning: Dictionaries may only be sorted by properties of boolean, `Date`, `NSDate`, single and double-precision
                floating point, integer, and string types.

     - see: `sorted(byKeyPath:ascending:)`
    */
    func sorted<S: Sequence>(by sortDescriptors: S) -> Results<Value>
        where S.Iterator.Element == SortDescriptor

    /// Returns all of the keys in this dictionary.
    var keys: [Key] { get }

    /// Returns all of the values in the dictionary.
    var values: [Value] { get }

    subscript(position: MapIndex) -> (Key, Value) { get }

    /// :nodoc:
    func index(of object: Value) -> MapIndex?

    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects in the collection, or `nil` if the
     dictionary is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    func min<T: MinMaxType>(ofProperty property: String) -> T?

    /**
     Returns the maximum (highest) value of the given property among all the objects in the dictionary, or `nil` if the
     dictionary is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    func max<T: MinMaxType>(ofProperty property: String) -> T?

    /**
    Returns the sum of the given property for objects in the dictionary, or `nil` if the dictionary is empty.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.
    */
    func sum<T: AddableType>(ofProperty property: String) -> T

    /**
     Returns the average value of a given property over all the objects in the dictionary, or `nil` if
     the dictionary is empty.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.
     */
    func average<T: AddableType>(ofProperty property: String) -> T?

    // MARK: Notifications

    /**
     Registers a block to be called each time the dictionary changes.

     The block will be asynchronously called with the initial results, and then called again after each write
     transaction which changes either any of the objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction.

     At the time when the block is called, the dictionary will be fully evaluated and up-to-date, and as long as you do
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
    func observe(on queue: DispatchQueue?,
                 _ block: @escaping (RealmDictionaryChange<Self>) -> Void)
    -> NotificationToken

    /// :nodoc:
    // swiftlint:disable:next identifier_name
    func _observe(_ queue: DispatchQueue?,
                  _ block: @escaping (RealmDictionaryChange<AnyMap<Key, Value>>) -> Void)
        -> NotificationToken

    // MARK: Frozen Objects

    /// Returns if this collection is frozen
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
}

public extension RealmKeyedCollection where Value: MinMaxType {
    /**
     Returns the minimum (lowest) value of the collection, or `nil` if the collection is empty.
     */
    func min() -> Value? {
        return min(ofProperty: "self")
    }
    /**
     Returns the maximum (highest) value of the collection, or `nil` if the collection is empty.
     */
    func max() -> Value? {
        return max(ofProperty: "self")
    }
}

public extension RealmKeyedCollection where Value: OptionalProtocol, Value.Wrapped: MinMaxType {
    /**
     Returns the minimum (lowest) value of the collection, or `nil` if the collection is empty.
     */
    func min() -> Value.Wrapped? {
        return min(ofProperty: "self")
    }
    /**
     Returns the maximum (highest) value of the collection, or `nil` if the collection is empty.
     */
    func max() -> Value.Wrapped? {
        return max(ofProperty: "self")
    }
}

public extension RealmKeyedCollection where Value: AddableType {
    /**
     Returns the sum of the values in the collection, or `nil` if the collection is empty.
     */
    func sum() -> Value {
        return sum(ofProperty: "self")
    }
    /**
     Returns the average of all of the values in the collection.
     */
    func average<T: AddableType>() -> T? {
        return average(ofProperty: "self")
    }
}

public extension RealmKeyedCollection where Value: OptionalProtocol, Value.Wrapped: AddableType {
    /**
     Returns the sum of the values in the collection, or `nil` if the collection is empty.
     */
    func sum() -> Value.Wrapped {
        return sum(ofProperty: "self")
    }
    /**
     Returns the average of all of the values in the collection.
     */
    func average<T: AddableType>() -> T? {
        return average(ofProperty: "self")
    }
}

public extension RealmKeyedCollection where Value: Comparable {
    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     Objects are sorted based on their values. For example, to sort a collection of `Date`s from
     neweset to oldest based, you might call `dates.sorted(ascending: true)`.

     - parameter ascending: The direction to sort in.
     */
    func sorted(ascending: Bool = true) -> Results<Value> {
        return sorted(byKeyPath: "self", ascending: ascending)
    }
}

public extension RealmKeyedCollection where Value: OptionalProtocol, Value.Wrapped: Comparable {
    /**
     Returns a `Results` containing the objects in the collection, but sorted.

     Objects are sorted based on their values. For example, to sort a collection of `Date`s from
     neweset to oldest based, you might call `dates.sorted(ascending: true)`.

     - parameter ascending: The direction to sort in.
     */
    func sorted(ascending: Bool = true) -> Results<Value> {
        return sorted(byKeyPath: "self", ascending: ascending)
    }
}

/// :nodoc:
private class _AnyMapBase<Key: MapKeyType, Value: RealmCollectionValue>: AssistedObjectiveCBridgeable {
    typealias Wrapper = AnyMap<Key, Value>
    var realm: Realm? { fatalError() }
    var isInvalidated: Bool { fatalError() }
    var count: Int { fatalError() }
    var description: String { fatalError() }
    func updateValue(_ value: Value, forKey key: Key) { fatalError() }
    func removeObject(for key: Key) { fatalError() }
    func removeAll() { fatalError() }
    subscript(key: Key) -> Value? {
        get { fatalError() }
        set { fatalError() }
    }
    func value(forKey key: String) -> AnyObject? { fatalError() }
    func value(forKeyPath keyPath: String) -> AnyObject? { fatalError() }
    func setValue(_ value: Any?, forKey key: String) { fatalError() }
    func filter(_ predicate: NSPredicate) -> Results<Value> { fatalError() }
    func contains(where predicate: @escaping (Key, Value) -> Bool) -> Bool { fatalError() }
    func sorted(ascending: Bool) -> Results<Value> { fatalError() }
    func sorted(byKeyPath keyPath: String, ascending: Bool) -> Results<Value> { fatalError() }
    func sorted<S>(by sortDescriptors: S) -> Results<Value> where S: Sequence, S.Element == SortDescriptor { fatalError() }
    var keys: [Key] { fatalError() }
    var values: [Value] { fatalError() }
    subscript(position: MapIndex) -> (Key, Value) { fatalError() }
    func index(of object: Value) -> MapIndex? { fatalError() }
    func min<T: MinMaxType>(ofProperty property: String) -> T? { fatalError() }
    func max<T: MinMaxType>(ofProperty property: String) -> T? { fatalError() }
    func sum<T: AddableType>(ofProperty property: String) -> T { fatalError() }
    func average<T: AddableType>(ofProperty property: String) -> T? { fatalError() }
    // swiftlint:disable:next identifier_name
    func _observe(_ queue: DispatchQueue?, _ block: @escaping (RealmDictionaryChange<Wrapper>) -> Void)
        -> NotificationToken { fatalError() }
    var isFrozen: Bool { fatalError() }
    func freeze() -> Wrapper { fatalError() }
    func thaw() -> Wrapper? { fatalError() }
    func asNSFastEnumerator() -> Any { fatalError() }
    func makeIterator() -> RLMMapIterator<SingleMapEntry<Key, Value>> { fatalError() }
    class func bridging(from objectiveCValue: Any, with metadata: Any?) -> Self { fatalError() }
    var bridged: (objectiveCValue: Any, metadata: Any?) { fatalError() }
}

/// :nodoc:
private final class _AnyMap<C: RealmKeyedCollection>: _AnyMapBase<C.Key, C.Value> {
    var base: C
    init(base: C) {
        self.base = base
    }

    // MARK: Properties

    override var realm: Realm? { base.realm }
    override var isInvalidated: Bool { base.isInvalidated }
    override var count: Int { base.count }
    override var description: String { base.description }
    override var keys: [C.Key] { base.keys }
    override var values: [C.Value] { base.values }

    // MARK: Mutation

    override func updateValue(_ value: C.Value, forKey key: C.Key) { base.updateValue(value, forKey: key) }
    override func removeObject(for key: C.Key) { base.removeObject(for: key) }
    override func removeAll() { base.removeAll() }
    override subscript(key: C.Key) -> C.Value? {
        get { base[key] }
        set { base[key] = newValue }
    }

    // MARK: Key-Value Coding

    override func value(forKey key: String) -> AnyObject? { base.value(forKey: key) }
    override func value(forKeyPath keyPath: String) -> AnyObject? { base.value(forKeyPath: keyPath) }
    override func setValue(_ value: Any?, forKey key: String) { base.setValue(value, forKey: key) }

    // MARK: Filtering

    override func filter(_ predicate: NSPredicate) -> Results<C.Value> { base.filter(predicate) }
    override func contains(where predicate: @escaping (C.Key, C.Value) -> Bool) -> Bool { base.contains(where: predicate) }

    // MARK: Sorting

    override func sorted(ascending: Bool) -> Results<C.Value> { base.sorted(ascending: ascending) }
    override func sorted(byKeyPath keyPath: String, ascending: Bool) -> Results<C.Value> { base.sorted(byKeyPath: keyPath, ascending: ascending) }
    override func sorted<S>(by sortDescriptors: S) -> Results<C.Value> where S: Sequence, S.Element == SortDescriptor { base.sorted(by: sortDescriptors) }

    // MARK: Indexes

    override subscript(position: MapIndex) -> (C.Key, C.Value) { base[position] }
    override func index(of object: C.Value) -> MapIndex? { base.index(of: object) }

    // MARK: Aggregate Operations

    override func min<T: MinMaxType>(ofProperty property: String) -> T? { base.min(ofProperty: property) }
    override func max<T: MinMaxType>(ofProperty property: String) -> T? { base.max(ofProperty: property) }
    override func sum<T: AddableType>(ofProperty property: String) -> T { base.sum(ofProperty: property) }
    override func average<T: AddableType>(ofProperty property: String) -> T? { base.average(ofProperty: property) }

    // MARK: Notifications

    override func _observe(_ queue: DispatchQueue?, _ block: @escaping (RealmDictionaryChange<Wrapper>) -> Void)
        -> NotificationToken { base._observe(queue, block) }
    override var isFrozen: Bool { base.isFrozen }

    // MARK: Sequence Support

    override func asNSFastEnumerator() -> Any { base.asNSFastEnumerator() }
    override func makeIterator() -> RLMMapIterator<SingleMapEntry<C.Key, C.Value>> {
        base.makeIterator() as! RLMMapIterator<SingleMapEntry<C.Key, C.Value>>
    }

    // MARK: AssistedObjectiveCBridgeable

    override class func bridging(from objectiveCValue: Any, with metadata: Any?) -> _AnyMap {
        return _AnyMap(
            base: (C.self as! AssistedObjectiveCBridgeable.Type).bridging(from: objectiveCValue, with: metadata) as! C)
    }

    override var bridged: (objectiveCValue: Any, metadata: Any?) {
        return (base as! AssistedObjectiveCBridgeable).bridged
    }


    override func freeze() -> AnyMap<C.Key, C.Value> { return AnyMap(base.freeze()) }
    override func thaw() -> AnyMap<C.Key, C.Value>? { return AnyMap(base.thaw()!)  }
}
/**
 A type-erased `RealmKeyedCollection`.

 Instances of `RealmKeyedCollection` forward operations to an opaque underlying collection having the same `Key`, `Value` type.
 */
public struct AnyMap<Key: MapKeyType, Value: RealmCollectionValue>: RealmKeyedCollection {
    /// The type of the objects contained in the collection.
    fileprivate let base: _AnyMapBase<Key, Value>

    fileprivate init(base: _AnyMapBase<Key, Value>) {
        self.base = base
    }

    /// Creates an `RealmKeyedCollection` wrapping `base`.
    public init<C: RealmKeyedCollection>(_ base: C) where C.Key == Key, C.Value == Value {
        self.base = _AnyMap(base: base)
    }

    /// :nodoc:
    public typealias Wrapper = AnyMap<Key, Value>

    // MARK: Properties

    /// The Realm which manages the map, or `nil` if the map is unmanaged.
    public var realm: Realm? { return base.realm }

    /**
     Indicates if the map can no longer be accessed.

     The map can no longer be accessed if `invalidate()` is called on the containing `realm`.
     */
    public var isInvalidated: Bool { base.isInvalidated }

    /// The number of objects in the map.
    public var count: Int { base.count }
    /// A human-readable description of the objects contained in the map.
    public var description: String { base.description }

    /// Returns all of the keys in this dictionary.
    public var keys: [Key] { base.keys }

    /// Returns all of the values in the dictionary.
    public var values: [Value] { base.values }

    // MARK: Mutation

    /**
     Updates the value stored in the dictionary for the given key, or adds a new key-value pair if the key does not exist.

     - parameter value: a value's key path predicate.
     - parameter forKey: The direction to sort in.
     */
    public func updateValue(_ value: Value, forKey key: Key) { base.updateValue(value, forKey: key) }
    /**
     Removes the given key and its associated object.
     */
    public func removeObject(for key: Key) { base.removeObject(for: key) }

    /**
     Removes all objects from the dictionary. The objects are not removed from the Realm that manages them.

     - warning: This method may only be called during a write transaction.
     */
    public func removeAll() { base.removeAll() }

    /// :nodoc:
    public subscript(key: Key) -> Value? {
        get { return base[key] }
        set { base[key] = newValue }
    }

    // MARK: KVC

    /**
     Returns a type of `Value` for a specified key if it exists in the map.

     Note that when using key-value coding, the key must be a string.

     - parameter key: The key to the property whose values are desired.
     */
    public func value(forKey key: String) -> AnyObject? { base.value(forKey: key) }

    /**
     Returns a type of `Value` for a specified key if it exists in the map.

     - parameter keyPath: The key to the property whose values are desired.
     */
    public func value(forKeyPath keyPath: String) -> AnyObject? { base.value(forKeyPath: keyPath) }

    /**
     Adds a given key-value pair to the dictionary or updates a given key should it already exist.

     - warning: This method can only be called during a write transaction.

     - parameter value: The object value.
     - parameter key:   The name of the property whose value should be set on each object.
    */
    public func setValue(_ value: Any?, forKey key: String) { base.setValue(value, forKey: key) }

    // MARK: Filtering

    /**
     Returns a `Results` containing all matching key-value pairs the given predicate in the Map.

     - parameter predicate: The predicate with which to filter the objects.
     */
    public func filter(_ predicate: NSPredicate) -> Results<Value> { base.filter(predicate) }

    /**
     Returns a Boolean value indicating whether the Map contains the key-value pair
     satisfies the given predicate

     - parameter where: a closure that test if any key-pair of the given map represents the match.
     */
    public func contains(where predicate: @escaping (Key, Value) -> Bool) -> Bool { base.contains(where: predicate) }

    // MARK: Sorting

    /**
     Returns a `Results` containing the objects in the dictionary, but sorted.

     Objects are sorted based on their values. For example, to sort a dictionary of `Date`s from
     neweset to oldest based, you might call `dates.sorted(ascending: true)`.

     - parameter ascending: The direction to sort in.
     */
    public func sorted(ascending: Bool) -> Results<Value> { base.sorted(ascending: ascending) }

    /**
     Returns a `Results` containing the objects in the dictionary, but sorted.

     Objects are sorted based on the values of the given key path. For example, to sort a dictionary of `Student`s from
     youngest to oldest based on their `age` property, you might call
     `students.sorted(byKeyPath: "age", ascending: true)`.

     - warning: Dictionaries may only be sorted by properties of boolean, `Date`, `NSDate`, single and double-precision
                floating point, integer, and string types.

     - parameter keyPath:  The key path to sort by.
     - parameter ascending: The direction to sort in.
     */
    public func sorted(byKeyPath keyPath: String, ascending: Bool) -> Results<Value> { base.sorted(byKeyPath: keyPath, ascending: ascending) }

    /**
     Returns a `Results` containing the objects in the dictionary, but sorted.

     - warning: Dictionaries may only be sorted by properties of boolean, `Date`, `NSDate`, single and double-precision
                floating point, integer, and string types.

     - see: `sorted(byKeyPath:ascending:)`
    */
    public func sorted<S>(by sortDescriptors: S) -> Results<Value> where S: Sequence, S.Element == SortDescriptor { base.sorted(by: sortDescriptors) }

    public subscript(position: MapIndex) -> (Key, Value) { base[position] }
    public func index(of object: Value) -> MapIndex? { base.index(of: object) }

    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects in the collection, or `nil` if the
     dictionary is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func min<T: MinMaxType>(ofProperty property: String) -> T? { base.min(ofProperty: property) }

    /**
     Returns the maximum (highest) value of the given property among all the objects in the collection, or `nil` if the
     dictionary is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func max<T: MinMaxType>(ofProperty property: String) -> T? { base.max(ofProperty: property) }

    /**
    Returns the sum of the given property for objects in the collection, or `nil` if the dictionary is empty.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.
    */
    public func sum<T: AddableType>(ofProperty property: String) -> T { base.sum(ofProperty: property) }

    /**
     Returns the average value of a given property over all the objects in the collection, or `nil` if
     the dictionary is empty.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.
     */
    public func average<T: AddableType>(ofProperty property: String) -> T? { base.average(ofProperty: property) }

    // MARK: Notifications

    /**
     Registers a block to be called each time the dictionary changes.

     The block will be asynchronously called with the initial results, and then called again after each write
     transaction which changes either any of the objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction.

     At the time when the block is called, the dictionary will be fully evaluated and up-to-date, and as long as you do
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
         person.dogs["foo"] = dog
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
    public func observe(on queue: DispatchQueue?, _ block: @escaping (RealmDictionaryChange<Wrapper>) -> Void)
    -> NotificationToken { base._observe(queue, block) }

    /// :nodoc:
    // swiftlint:disable:next identifier_name
    public func _observe(_ queue: DispatchQueue?, _ block: @escaping (RealmDictionaryChange<Wrapper>) -> Void)
        -> NotificationToken { base._observe(queue, block) }

    // MARK: Frozen Objects

    /// Returns if this map is frozen.
    public var isFrozen: Bool { base.isFrozen }

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
    public func freeze() -> Wrapper { base.freeze() }

    /**
     Returns a live version of this frozen collection.

     This method resolves a reference to a live copy of the same frozen collection.
     If called on a live collection, will return itself.
    */
    public func thaw() -> Wrapper? { base.thaw() }

    // MARK: Sequence Support

    /// :nodoc:
    internal func asNSFastEnumerator() -> Any { base.asNSFastEnumerator() }

    /// Returns a `RLMMapIterator` that yields successive elements in the collection.
    public func makeIterator() -> RLMMapIterator<SingleMapEntry<Key, Value>> {
        return base.makeIterator()
    }
}

// MARK: AssistedObjectiveCBridgeable

private struct AnyMapBridgingMetadata<Key: MapKeyType, Value: RealmCollectionValue> {
    var baseMetadata: Any?
    var baseType: _AnyMapBase<Key, Value>.Type
}

extension AnyMap: AssistedObjectiveCBridgeable {
    internal static func bridging(from objectiveCValue: Any, with metadata: Any?) -> AnyMap {
        guard let metadata = metadata as? AnyMapBridgingMetadata<Key, Value> else { preconditionFailure() }
        return AnyMap(base: metadata.baseType.bridging(from: objectiveCValue, with: metadata.baseMetadata))
    }

    internal var bridged: (objectiveCValue: Any, metadata: Any?) {
        return (
            objectiveCValue: base.bridged.objectiveCValue,
            metadata: AnyMapBridgingMetadata(baseMetadata: base.bridged.metadata, baseType: type(of: base))
        )
    }
}
