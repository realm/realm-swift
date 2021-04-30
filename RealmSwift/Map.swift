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
 
 Unlike Swift's native collections, Map is a reference types, and are only immutable if the Realm that manages them
 is opened as read-only.
 
 A Map can be filtered and sorted with the same predicates as Results<Value>.
 
 Properties of Map type defined on Object subclasses must be declared as let and cannot be dynamic.
*/
public final class Map<Key: MapKeyType, Value: RealmCollectionValue>: RLMSwiftCollectionBase {

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
    public func removeValue(for key: String) {
        rlmDictionary.removeObject(for: key as RLMDictionaryKey)
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
            return rlmDictionary[objcKey(from: key)].map(dynamicBridgeCast)
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

    // MARK: KVC

    /**
     Returns a type of `Value` for a specified key if it exists in the map.

     - parameter key: The key to the property whose values are desired.
     */
    @nonobjc public func value(forKey key: Key) -> Value? {
        return rlmDictionary.value(forKey: objcKey(from: key))
            .map { dynamicBridgeCast(fromObjectiveC:$0) }
    }

    /**
     Returns a type of `Value` for a specified key if it exists in the map.

     - parameter keyPath: The key to the property whose values are desired.
     */
    @nonobjc public func value(forKeyPath keyPath: String) -> Value? {
        return rlmDictionary.value(forKeyPath: keyPath)
            .map { dynamicBridgeCast(fromObjectiveC:$0) }
    }

    /**
     Returns a type of `AnyObject` for a specified key if it exists in the map.

     - parameter key: The key to the property whose values are desired.
     */
    @objc public func object(forKey key: AnyObject) -> AnyObject? {
        return rlmDictionary.object(for: key as! RLMDictionaryKey)
    }

    /**
     Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified `value` and `key`.

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
        rlmDictionary.enumerateKeysAndObjects { (key, value, shouldStop) in
            if predicate(dynamicBridgeCast(fromObjectiveC: key), dynamicBridgeCast(fromObjectiveC: value)) {
                found = true
                shouldStop.pointee = true
            }
        }
        return found
    }

    // MARK: Sorting

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
        return dynamicBridgeCast(fromObjectiveC: rlmDictionary.allKeys)
    }

    /// Returns all of the values in the dictionary.
    public var values: [Value] {
        return dynamicBridgeCast(fromObjectiveC: rlmDictionary.allValues)
    }

    /// :nodoc:
    // swiftlint:disable:next identifier_name
    public func _observe(_ queue: DispatchQueue?,
                         _ block: @escaping (RealmCollectionChange<AnyRealmCollection<SingleMapEntry<Key, Value>>>) -> Void)
        -> NotificationToken {
        fatalError()
//        return rlmDictionary.addNotificationBlock(wrapObserveBlock(block), queue: queue)
    }

    public subscript(position: Index) -> (Key, Value) {
        precondition((position.offset >= count && position.offset < count),
                     "Attempting to access Map elements using an invalid index.")
        let key = keys[Int(position.offset)]
        return (key, self[key]!)
    }

    /// :nodoc:
    public func index(of object: Value) -> Index? {
        return Index(offset: rlmDictionary.index(of: dynamicBridgeCast(fromSwift: object)))
    }

    /// Container type which holds the offset of the element in the Map.
    public struct Index {
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

    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects in the collection, or `nil` if the
     collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func min<T: MinMaxType>(ofProperty property: String) -> T? {
        return rlmDictionary.min(ofProperty: property).map(dynamicBridgeCast)
    }

    /**
     Returns the maximum (highest) value of the given property among all the objects in the collection, or `nil` if the
     collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func max<T: MinMaxType>(ofProperty property: String) -> T? {
        return rlmDictionary.max(ofProperty: property).map(dynamicBridgeCast)
    }

    /**
    Returns the sum of the given property for objects in the collection, or `nil` if the collection is empty.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.
    */
    public func sum<T: AddableType>(ofProperty property: String) -> T {
        return dynamicBridgeCast(fromObjectiveC: rlmDictionary.sum(ofProperty: property))
    }

    /**
     Returns the average value of a given property over all the objects in the collection, or `nil` if
     the collection is empty.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.
     */
    public func average<T: AddableType>(ofProperty property: String) -> T? {
        return rlmDictionary.average(ofProperty: property).map(dynamicBridgeCast)
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
        fatalError()
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
