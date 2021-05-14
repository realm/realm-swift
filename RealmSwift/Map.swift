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

public protocol MapKeyType: Hashable { }
extension String: MapKeyType { }

/**
 Map is a key-value storage container used to store supported Realm types.
 
 Map is a generic type that is parameterized on the type it stores. This can be either an Object
 subclass or one of the following types: Bool, Int, Int8, Int16, Int32, Int64, Float, Double,
 String, Data, Date, Decimal128, and ObjectId (and their optional versions)
 
 Map only supports String as a key.
 
 Unlike Swift's native collections, `Map`s is a reference types, and are only immutable if the Realm that manages them
 is opened as read-only.
 
 A Map can be filtered and sorted with the same predicates as `Results<Value>`.
 
 Properties of `Map` type defined on `Object` subclasses must be declared as `let` and cannot be `dynamic`.
*/
public final class Map<Key: MapKeyType, Value: RealmCollectionValue>: RLMSwiftCollectionBase, RealmKeyedCollection {

    // MARK: Properties

    /// The Realm which manages the map, or `nil` if the map is unmanaged.
    public var realm: Realm? {
        return _rlmCollection.realm.map { Realm($0) }
    }

    /// Indicates if the map can no longer be accessed.
    public var isInvalidated: Bool { return _rlmCollection.isInvalidated }

    internal var rlmDictionary: RLMDictionary<AnyObject, AnyObject> {
        _rlmCollection as! RLMDictionary
    }

    private func objcKey(from swiftKey: Key) -> RLMDictionaryKey {
        guard let key = swiftKey as? RLMDictionaryKey else {
            throwRealmException("Could not cast \(String(describing: swiftKey.self)) to RLMDictionaryKey")
        }
        return key
    }

    // MARK: Initializers

    /// Creates a `Map` that holds Realm model objects of type `Value`.
    public override init() {
        super.init()
    }

    internal init(objc rlmDictionary: RLMDictionary<AnyObject, AnyObject>) {
        super.init(collection: rlmDictionary)
    }

    // MARK: Count

    /// Returns the number of key-value pairs in this map.
    @objc public var count: Int { return Int(_rlmCollection.count) }

    // MARK: Mutation

    /**
     Updates the value stored in the dictionary for the given key, or adds a new key-value pair if the key does not exist.

     - parameter value: a value's key path predicate.
     - parameter forKey: The direction to sort in.
     */
    public func updateValue(_ value: Value, forKey key: Key) {
        rlmDictionary[objcKey(from: key)] = dynamicBridgeCast(fromSwift: value) as AnyObject
    }

    /**
     Removes the given key and its associated object.
     */
    public func removeObject(for key: Key) {
        rlmDictionary.removeObject(for: objcKey(from: key))
    }

    /**
     Removes all objects from the dictionary. The objects are not removed from the Realm that manages them.

     - warning: This method may only be called during a write transaction.
     */
    public func removeAll() {
        rlmDictionary.removeAllObjects()
    }

    public subscript(key: Key) -> Value? {
        get {
            if rlmDictionary.type == .object {
                let obj = rlmDictionary[objcKey(from: key)]
                // A Map can keep the key of an object that has been deleted by the Realm.
                // If the object is deleted it will be stored as NSNull.null so we want to
                // return that as `nil`.
                if obj is NSNull {
                    return nil
                }
                return obj.map(dynamicBridgeCast)
            } else {
                return rlmDictionary[objcKey(from: key)].map(dynamicBridgeCast)
            }
        }
        set {
            if newValue == nil {
                // explicity set nil so it doesnt become NSNull
                rlmDictionary[objcKey(from: key)] = nil
            } else {
                rlmDictionary[objcKey(from: key)] = dynamicBridgeCast(fromSwift: newValue) as AnyObject
            }
        }
    }

    /**
     Returns a type of `AnyObject` for a specified key if it exists in the map.

     - parameter key: The key to the property whose values are desired.
     */
    @objc public func object(forKey key: AnyObject) -> AnyObject? {
        return rlmDictionary.object(for: key as! RLMDictionaryKey)
    }

    // MARK: KVC

    /**
     Returns a type of `Value` for a specified key if it exists in the map.

     Note that when using key-value coding, the key must be a string.

     - parameter key: The key to the property whose values are desired.
     */
    @nonobjc public func value(forKey key: String) -> AnyObject? {
        return rlmDictionary.value(forKey: key as RLMDictionaryKey)
            .map { dynamicBridgeCast(fromObjectiveC:$0) }
    }

    /**
     Returns a type of `Value` for a specified key if it exists in the map.

     - parameter keyPath: The key to the property whose values are desired.
     */
    @nonobjc public func value(forKeyPath keyPath: String) -> AnyObject? {
        return rlmDictionary.value(forKeyPath: keyPath)
            .map { dynamicBridgeCast(fromObjectiveC:$0) }
    }

    /**
     Adds a given key-value pair to the dictionary or updates a given key should it already exist.

     - warning: This method can only be called during a write transaction.

     - parameter value: The object value.
     - parameter key:   The name of the property whose value should be set on each object.
    */
    public override func setValue(_ value: Any?, forKey key: String) {
        rlmDictionary.setValue(value, forKey: key)
    }

    // MARK: Filtering

    /**
     Returns a `Results` containing all matching key-value pairs the given predicate in the Map.

     - parameter predicate: The predicate with which to filter the objects.
     */
    public func filter(_ predicate: NSPredicate) -> Results<Value> {
        return Results<Value>(rlmDictionary.objects(with: predicate))
    }

    /**
     Returns a Boolean value indicating whether the Map contains the key-value pair
     satisfies the given predicate

     - parameter where: a closure that test if any key-pair of the given map represents the match.
     */
    public func contains(where predicate: @escaping (_ key: Key, _ value: Value) -> Bool) -> Bool {
        var found = false
        rlmDictionary.enumerateKeysAndObjects { (k, v, shouldStop) in
            if predicate(dynamicBridgeCast(fromObjectiveC: k), dynamicBridgeCast(fromObjectiveC: v)) {
                found = true
                shouldStop.pointee = true
            }
        }
        return found
    }

    // MARK: Sorting

    /**
     Returns a `Results` containing the objects in the dictionary, but sorted.

     Objects are sorted based on their values. For example, to sort a dictionary of `Date`s from
     neweset to oldest based, you might call `dates.sorted(ascending: true)`.

     - parameter ascending: The direction to sort in.
     */
    public func sorted(ascending: Bool = true) -> Results<Value> {
        return sorted(byKeyPath: "self", ascending: ascending)
    }

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
    public func sorted(byKeyPath keyPath: String, ascending: Bool = true) -> Results<Value> {
        return sorted(by: [SortDescriptor(keyPath: keyPath, ascending: ascending)])
    }

    /**
     Returns a `Results` containing the objects in the dictionary, but sorted.

     - warning: Dictionaries may only be sorted by properties of boolean, `Date`, `NSDate`, single and double-precision
                floating point, integer, and string types.

     - see: `sorted(byKeyPath:ascending:)`
    */
    public func sorted<S: Sequence>(by sortDescriptors: S) -> Results<Value>
        where S.Iterator.Element == SortDescriptor {
            return Results<Value>(_rlmCollection.sortedResults(using: sortDescriptors.map { $0.rlmSortDescriptorValue }))
    }

    /// Returns all of the keys in this dictionary.
    public var keys: [Key] {
        return rlmDictionary.allKeys.map(dynamicBridgeCast)
    }

    /// Returns all of the values in the dictionary.
    public var values: [Value] {
        return rlmDictionary.allValues.map(dynamicBridgeCast)
    }

    /// :nodoc:
    // swiftlint:disable:next identifier_name
    public func _observe(_ queue: DispatchQueue?,
                         _ block: @escaping (RealmDictionaryChange<AnyMap<Key, Value>>) -> Void)
        -> NotificationToken {
        return rlmDictionary.addNotificationBlock(wrapDictionaryObserveBlock(block), queue: queue)
    }

    /// :nodoc:
    public func index(of object: Value) -> MapIndex? {
        return MapIndex(offset: rlmDictionary.index(of: dynamicBridgeCast(fromSwift: object)))
    }

    /// :nodoc:
    public subscript(position: MapIndex) -> (Key, Value) {
        precondition((position.offset >= count && position.offset < count),
                     "Attempting to access Map elements using an invalid index.")
        let key = keys[Int(position.offset)]
        return (key, self[key]!)
    }

    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects in the collection, or `nil` if the
     dictionary is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func min<T: MinMaxType>(ofProperty property: String) -> T? {
        return rlmDictionary.min(ofProperty: property).map(dynamicBridgeCast)
    }

    /**
     Returns the maximum (highest) value of the given property among all the objects in the collection, or `nil` if the
     dictionary is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func max<T: MinMaxType>(ofProperty property: String) -> T? {
        return rlmDictionary.max(ofProperty: property).map(dynamicBridgeCast)
    }

    /**
    Returns the sum of the given property for objects in the collection, or `nil` if the dictionary is empty.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.
    */
    public func sum<T: AddableType>(ofProperty property: String) -> T {
        return dynamicBridgeCast(fromObjectiveC: rlmDictionary.sum(ofProperty: property))
    }

    /**
     Returns the average value of a given property over all the objects in the collection, or `nil` if
     the dictionary is empty.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.
     */
    public func average<T: AddableType>(ofProperty property: String) -> T? {
        return rlmDictionary.average(ofProperty: property).map(dynamicBridgeCast)
    }

    // MARK: Notifications

    /**
     Registers a block to be called each time the dictionary changes.

     The block will be asynchronously called with the initial results, and then called again after each write
     transaction which changes either any of the objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of
     the objects were added, removed, or modified during each write transaction. See the `RealmCollectionChange`
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

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
    public func observe(on queue: DispatchQueue?,
                        _ block: @escaping (RealmDictionaryChange<AnyMap<Key, Value>>) -> Void)
    -> NotificationToken {
        return rlmDictionary.addNotificationBlock(wrapDictionaryObserveBlock(block), queue: queue)
    }

    // MARK: Frozen Objects

    public var isFrozen: Bool {
        return _rlmCollection.isFrozen
    }

    public func freeze() -> Map {
        return Map(objc: rlmDictionary.freeze())
    }

    public func thaw() -> Map? {
        return Map(objc: rlmDictionary.thaw())
    }

    // swiftlint:disable:next identifier_name
    @objc class func _unmanagedCollection() -> RLMDictionary<AnyObject, AnyObject> {
        return Value._rlmDictionary()
    }

    /**
     Returns a human-readable description of the objects contained in the Map.
     */
    @objc public override var description: String {
        return descriptionWithMaxDepth(RLMDescriptionMaxDepth)
    }

    @objc private func descriptionWithMaxDepth(_ depth: UInt) -> String {
        return RLMDictionaryDescriptionWithMaxDepth("Map", rlmDictionary, depth)
    }
}

extension Map where Value: MinMaxType {
    /**
     Returns the minimum (lowest) value in the map, or `nil` if the map is empty.
     */
    public func min() -> Value? {
        return _rlmCollection.min(ofProperty: "self").map(dynamicBridgeCast)
    }

    /**
     Returns the maximum (highest) value in the map, or `nil` if the map is empty.
     */
    public func max() -> Value? {
        return _rlmCollection.max(ofProperty: "self").map(dynamicBridgeCast)
    }
}

extension Map where Value: OptionalProtocol, Value.Wrapped: MinMaxType {
    /**
     Returns the minimum (lowest) value of the dictionary, or `nil` if the dictionary is empty.
     */
    public func min() -> Value.Wrapped? {
        return _rlmCollection.min(ofProperty: "self").map(dynamicBridgeCast)
    }
    /**
     Returns the maximum (highest) value of the dictionary, or `nil` if the dictionary is empty.
     */
    public func max() -> Value.Wrapped? {
        return _rlmCollection.max(ofProperty: "self").map(dynamicBridgeCast)
    }
}

extension Map where Value: AddableType {
    /**
     Returns the sum of the values in the map.
     */
    public func sum() -> Value {
        return sum(ofProperty: "self")
    }

    /**
     Returns the average of the values in the map, or `nil` if the map is empty.
     */
    public func average<T: AddableType>() -> T? {
        return average(ofProperty: "self")
    }
}

public extension Map where Value: OptionalProtocol, Value.Wrapped: AddableType {
    /**
     Returns the sum of the values in the dictionary, or `nil` if the dictionary is empty.
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

// MARK: - AssistedObjectiveCBridgeable

extension Map: AssistedObjectiveCBridgeable {
    internal static func bridging(from objectiveCValue: Any, with metadata: Any?) -> Map {
        guard let objectiveCValue = objectiveCValue as? RLMDictionary<AnyObject, AnyObject> else { preconditionFailure() }
        return Map(objc: objectiveCValue)
    }

    internal var bridged: (objectiveCValue: Any, metadata: Any?) {
        return (objectiveCValue: _rlmCollection, metadata: nil)
    }
}

// MARK: Sequence Support

extension Map: Sequence {
    /// Returns a `RLMMapIterator` that yields successive elements in the `Map`.
    public func makeIterator() -> RLMMapIterator<SingleMapEntry<Key, Value>> {
        return RLMMapIterator(collection: rlmDictionary)
    }

    /// :nodoc:
    public func asNSFastEnumerator() -> Any {
        return _rlmCollection
    }
}

/**
 A `RealmDictionaryChange` value encapsulates information about changes to dictionaries
 that are reported by Realm notifications.
 */
@frozen public enum RealmDictionaryChange<Collection> where Collection: RealmKeyedCollection {
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

     - parameter insertions:    The indices in the new collection which were added in this version.
     - parameter modifications: The indices of the objects in the new collection which were modified in this version.
     */
    case update(Collection, insertions: [Collection.Key], modifications: [Collection.Key])

    /**
     If an error occurs, notification blocks are called one time with a `.error`
     result and an `NSError` containing details about the error. This can only
     currently happen if opening the Realm on a background thread to calcuate
     the change set fails. The callback will never be called again after it is
     invoked with a .error value.
     */
    case error(Error)

    static func fromObjc(value: Collection?, change: RLMDictionaryChange?, error: Error?) -> RealmDictionaryChange {
        if let error = error {
            return .error(error)
        }
        if let change = change {
            return .update(value!,
                           insertions: change.insertions as! [Collection.Key],
                           modifications: change.modifications as! [Collection.Key])
        }
        return .initial(value!)
    }
}


extension Map {
    // We want to pass the same object instance to the change callback each time.
    // If the callback is being called on the source thread the instance should
    // be `self`, but if it's on a different thread it needs to be a new Swift
    // wrapper for the obj-c type, which we'll construct the first time the
    // callback is called.
    internal typealias ObjcCollectionChange = (RLMDictionary<AnyObject, AnyObject>?, RLMDictionaryChange?, Error?) -> Void

    internal func wrapDictionaryObserveBlock(_ block: @escaping (RealmDictionaryChange<AnyMap<Key, Value>>) -> Void) -> ObjcCollectionChange {
        var anyCollection: AnyMap<Key, Value>?
        return { collection, change, error in
            if anyCollection == nil, let collection = collection {
                anyCollection = AnyMap(self.isSameObjcCollection(collection) ? self : Self(objc: collection))
            }
            block(RealmDictionaryChange.fromObjc(value: anyCollection, change: change, error: error))
        }
    }

    internal func isSameObjcCollection(_ rlmDictionary: RLMDictionary<AnyObject, AnyObject>) -> Bool {
        return _rlmCollection === rlmDictionary
    }

    internal func wrapDictionaryObserveBlock(_ block: @escaping (RealmDictionaryChange<Self>) -> Void) -> ObjcCollectionChange {
        var col: Self?
        return { collection, change, error in
            if col == nil, let collection = collection {
                col = self.isSameObjcCollection(collection) ? self as! Self: Self(objc: collection)
            }
            block(RealmDictionaryChange.fromObjc(value: col, change: change, error: error))
        }
    }
}

/// Container type which holds the offset of the element in the Map.
public struct MapIndex {
    public var offset: UInt
}

/// Container for holding a single key-value entry in a Map. This is used where a tuple cannot be expressed as a generic arguement.
public struct SingleMapEntry<Key: MapKeyType, Value: RealmCollectionValue>: RealmMapValue, Hashable {
    /// :nodoc:
    public static func == (lhs: SingleMapEntry, rhs: SingleMapEntry) -> Bool {
        return lhs.value == rhs.value
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    /// :nodoc:
    public var key: Self.Key
    /// :nodoc:
    public var value: Self.Value
}

/**
 A homogenous key-value collection of `Object`s which can be retrieved, filtered, sorted, and operated upon.
*/
public protocol RealmKeyedCollection: _RealmCollectionEnumerator, ThreadConfined, Sequence {
    associatedtype Key: MapKeyType
    associatedtype Value: RealmCollectionValue

    // MARK: Properties

    /// The Realm which manages the map, or `nil` if the map is unmanaged.
    var realm: Realm? { get }

    /// Indicates if the map can no longer be accessed.
    var isInvalidated: Bool { get }

    /// Returns the number of key-value pairs in this map.
    var count: Int  { get }

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
                        _ block: @escaping (RealmDictionaryChange<AnyMap<Key, Value>>) -> Void)
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

/// :nodoc:
private class _AnyMapBase<Key: MapKeyType, Value: RealmCollectionValue>: AssistedObjectiveCBridgeable {
    typealias Wrapper = AnyMap<Key, Value>
    var realm: Realm? { fatalError() }
    var isInvalidated: Bool { fatalError() }
    var count: Int { fatalError() }
    var description: String  { fatalError() }
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
    func sorted<S>(by sortDescriptors: S) -> Results<Value> where S : Sequence, S.Element == SortDescriptor { fatalError() }
    var keys: [Key] { fatalError() }
    var values: [Value] { fatalError() }
    subscript(position: MapIndex) -> (Key, Value) { fatalError() }
    func index(of object: Value) -> MapIndex? { fatalError() }
    func min<T: MinMaxType>(ofProperty property: String) -> T? { fatalError() }
    func max<T: MinMaxType>(ofProperty property: String) -> T? { fatalError() }
    func sum<T: AddableType>(ofProperty property: String) -> T { fatalError() }
    func average<T: AddableType>(ofProperty property: String) -> T? { fatalError() }
    func observe(on queue: DispatchQueue?, _ block: @escaping (RealmDictionaryChange<Wrapper>) -> Void)
        -> NotificationToken { fatalError() }
    func _observe(_ queue: DispatchQueue?, _ block: @escaping (RealmDictionaryChange<Wrapper>) -> Void)
        -> NotificationToken { fatalError() }
    var isFrozen: Bool { fatalError() }
    func freeze() -> Wrapper { fatalError() }
    func thaw() -> Wrapper? { fatalError() }
    func _asNSFastEnumerator() -> Any { fatalError() }
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

    override var realm: Realm? { base.realm }
    override var isInvalidated: Bool { base.isInvalidated }
    override var count: Int { base.count }
    override var description: String  { base.description }
    override func updateValue(_ value: C.Value, forKey key: C.Key) { base.updateValue(value, forKey: key) }
    override func removeObject(for key: C.Key) { base.removeObject(for: key) }
    override func removeAll() { base.removeAll() }
    override subscript(key: C.Key) -> C.Value? {
        get { base[key] }
        set { base[key] = newValue }
    }
    override func value(forKey key: String) -> AnyObject? { base.value(forKey: key) }
    override func value(forKeyPath keyPath: String) -> AnyObject? { base.value(forKeyPath: keyPath) }
    override func setValue(_ value: Any?, forKey key: String) { base.setValue(value, forKey: key) }
    override func filter(_ predicate: NSPredicate) -> Results<C.Value> { base.filter(predicate) }
    override func contains(where predicate: @escaping (C.Key, C.Value) -> Bool) -> Bool { base.contains(where: predicate) }
    override func sorted(ascending: Bool) -> Results<C.Value> { base.sorted(ascending: ascending) }
    override func sorted(byKeyPath keyPath: String, ascending: Bool) -> Results<C.Value> { base.sorted(byKeyPath: keyPath, ascending: ascending) }
    override func sorted<S>(by sortDescriptors: S) -> Results<C.Value> where S : Sequence, S.Element == SortDescriptor { base.sorted(by: sortDescriptors) }
    override var keys: [C.Key] { base.keys }
    override var values: [C.Value] { base.values }
    override subscript(position: MapIndex) -> (C.Key, C.Value) { base[position] }
    override func index(of object: C.Value) -> MapIndex? { base.index(of: object) }
    override func min<T: MinMaxType>(ofProperty property: String) -> T? { base.min(ofProperty: property) }
    override func max<T: MinMaxType>(ofProperty property: String) -> T? { base.max(ofProperty: property) }
    override func sum<T: AddableType>(ofProperty property: String) -> T { base.sum(ofProperty: property) }
    override func average<T: AddableType>(ofProperty property: String) -> T? { base.average(ofProperty: property) }
    override func observe(on queue: DispatchQueue?, _ block: @escaping (RealmDictionaryChange<Wrapper>) -> Void)
        -> NotificationToken { base.observe(on: queue, block) }
    override func _observe(_ queue: DispatchQueue?, _ block: @escaping (RealmDictionaryChange<Wrapper>) -> Void)
        -> NotificationToken { base._observe(queue, block) }
    override var isFrozen: Bool { base.isFrozen }

    override func freeze() -> AnyMap<C.Key, C.Value> { return AnyMap(base.freeze()) }
    override func thaw() -> AnyMap<C.Key, C.Value>? { return AnyMap(base.thaw()!)  }

    override func _asNSFastEnumerator() -> Any { base._asNSFastEnumerator() }
    override func makeIterator() -> RLMMapIterator<SingleMapEntry<C.Key, C.Value>> {
        base.makeIterator() as! RLMMapIterator<SingleMapEntry<C.Key, C.Value>>
    }

    override class func bridging(from objectiveCValue: Any, with metadata: Any?) -> _AnyMap {
        return _AnyMap(
            base: (C.self as! AssistedObjectiveCBridgeable.Type).bridging(from: objectiveCValue, with: metadata) as! C)
    }

    override var bridged: (objectiveCValue: Any, metadata: Any?) {
        return (base as! AssistedObjectiveCBridgeable).bridged
    }
}
/**
 A type-erased `RealmKeyedCollection`.

 Instances of `RealmKeyedCollection` forward operations to an opaque underlying collection having the same `Key`, `Value` type.
 */
public struct AnyMap<Key: MapKeyType, Value: RealmCollectionValue>: RealmKeyedCollection {

    public typealias Wrapper = AnyMap<Key, Value>
    public var realm: Realm? { base.realm }
    public var isInvalidated: Bool { base.isInvalidated }
    public var count: Int { base.count }
    public var description: String  { base.description }
    public func updateValue(_ value: Value, forKey key: Key) { base.updateValue(value, forKey: key) }
    public func removeObject(for key: Key) { base.removeObject(for: key) }
    public func removeAll() { base.removeAll() }
    public subscript(key: Key) -> Value? {
        get { return base[key] }
        set { base[key] = newValue }
    }
    public func value(forKey key: String) -> AnyObject? { base.value(forKey: key) }
    public func value(forKeyPath keyPath: String) -> AnyObject? { base.value(forKeyPath: keyPath) }
    public func setValue(_ value: Any?, forKey key: String) { base.setValue(value, forKey: key) }
    public func filter(_ predicate: NSPredicate) -> Results<Value> { base.filter(predicate) }
    public func contains(where predicate: @escaping (Key, Value) -> Bool) -> Bool { base.contains(where: predicate) }
    public func sorted(ascending: Bool) -> Results<Value> { base.sorted(ascending: ascending) }
    public func sorted(byKeyPath keyPath: String, ascending: Bool) -> Results<Value> { base.sorted(byKeyPath: keyPath, ascending: ascending) }
    public func sorted<S>(by sortDescriptors: S) -> Results<Value> where S : Sequence, S.Element == SortDescriptor { base.sorted(by: sortDescriptors) }
    public var keys: [Key] { base.keys }
    public var values: [Value] { base.values }
    public subscript(position: MapIndex) -> (Key, Value) { base[position] }
    public func index(of object: Value) -> MapIndex? { base.index(of: object) }
    public func min<T: MinMaxType>(ofProperty property: String) -> T? { base.min(ofProperty: property) }
    public func max<T: MinMaxType>(ofProperty property: String) -> T? { base.max(ofProperty: property) }
    public func sum<T: AddableType>(ofProperty property: String) -> T { base.sum(ofProperty: property) }
    public func average<T: AddableType>(ofProperty property: String) -> T? { base.average(ofProperty: property) }
    public func observe(on queue: DispatchQueue?, _ block: @escaping (RealmDictionaryChange<Wrapper>) -> Void)
        -> NotificationToken { base.observe(on: queue, block) }
    public func _observe(_ queue: DispatchQueue?, _ block: @escaping (RealmDictionaryChange<Wrapper>) -> Void)
        -> NotificationToken { base._observe(queue, block) }
    public var isFrozen: Bool { base.isFrozen }
    public func freeze() -> Wrapper { base.freeze() }
    public func thaw() -> Wrapper? { base.thaw() }
    public func _asNSFastEnumerator() -> Any { base._asNSFastEnumerator() }
    public func makeIterator() -> RLMMapIterator<SingleMapEntry<Key, Value>> {
        return base.makeIterator()
    }

    /// The type of the objects contained in the collection.
    fileprivate let base: _AnyMapBase<Key, Value>

    fileprivate init(base: _AnyMapBase<Key, Value>) {
        self.base = base
    }

    /// Creates an `RealmKeyedCollection` wrapping `base`.
    public init<C: RealmKeyedCollection>(_ base: C) where C.Key == Key, C.Value == Value {
        self.base = _AnyMap(base: base)
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
