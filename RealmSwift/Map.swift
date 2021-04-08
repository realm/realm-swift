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

public protocol MapKeyType { }
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
    public var count: Int { return Int(_rlmCollection.count) }

    // MARK: KVC

    /**
     Returns a type of `Value` for a specified key if it exists in the map.

     - parameter key: The key to the property whose values are desired.
     */
    @nonobjc public func value(forKey key: Key) -> Value? {
        guard let value = rlmDictionary.object(for: dynamicBridgeCast(fromSwift: key) as! RLMDictionaryKey) else {
            return nil
        }
        return dynamicBridgeCast(fromObjectiveC: value)
    }

    /**
     Returns a type of `Value` for a specified key if it exists in the map.

     - parameter keyPath: The key to the property whose values are desired.
     */
    @nonobjc public func value(forKeyPath keyPath: String) -> Value? {
        guard let value = rlmDictionary.value(forKeyPath: keyPath) else {
            return nil
        }
        return dynamicBridgeCast(fromObjectiveC: value)
    }

    /**
     Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified `value` and `key`.

     - warning: This method can only be called during a write transaction.

     - parameter value: The object value.
     - parameter key:   The name of the property whose value should be set on each object.
    */
    public override func setValue(_ value: Any?, forKey key: String) {
        return rlmDictionary.setObject(dynamicBridgeCast(fromSwift: value) as AnyObject,
                                      for: key as RLMDictionaryKey)

    }

    // MARK: Filtering

    /**
     Returns a `Results` containing all matching key-value pairs the given predicate in the Map.

     - parameter predicate: The predicate with which to filter the objects.
     */
    public func filter(_ predicate: NSPredicate) -> Results<SingleMapEntry<Key, Value>> {
        return Results<SingleMapEntry>(_rlmCollection.objects(with: predicate))
    }

    /**
     Returns a Boolean value indicating whether the Map contains the
     given object.

     - parameter object: The value to find in the Map.
     */
    public func contains(_ object: Value) -> Bool {
        fatalError("Not implemented in Map. Please use contains(where:).")
    }

    /**
     Returns a Boolean value indicating whether the Map contains the key-value pair
     satisfies the given predicate

     - parameter where: a closure that test if any key-pair of the given map represents the match.
     */
    public func contains(where predicate: @escaping (_ key: String, _ value: Value) -> Bool) -> Bool {
        var found: Bool = false
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

     Pairs are sorted based on the given keyPath for a value.

     - parameter byKeyPath: a value's key path predicate.
     - parameter ascending: The direction to sort in.
     */
    public func sorted(byKeyPath keyPath: String, ascending: Bool) -> Results<SingleMapEntry<Key, Value>> {
        fatalError("Not implemented in Map")
    }

    public func sorted<S>(by sortDescriptors: S) -> Results<SingleMapEntry<Key, Value>>
        where S: Sequence, S.Element == SortDescriptor {
        fatalError("Not implemented in Map")
    }

    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects in the collection, or `nil` if the
     collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func min<T: MinMaxType>(ofProperty property: String) -> T? {
        return _rlmCollection.min(ofProperty: property).map(dynamicBridgeCast)
    }

    /**
     Returns the maximum (highest) value of the given property among all the objects in the collection, or `nil` if the
     collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func max<T: MinMaxType>(ofProperty property: String) -> T? {
        return _rlmCollection.max(ofProperty: property).map(dynamicBridgeCast)
    }

    /**
    Returns the sum of the given property for objects in the collection, or `nil` if the collection is empty.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.
    */
    public func sum<T: AddableType>(ofProperty property: String) -> T {
        return dynamicBridgeCast(fromObjectiveC: _rlmCollection.sum(ofProperty: property))
    }

    /**
     Returns the average value of a given property over all the objects in the collection, or `nil` if
     the collection is empty.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.
     */
    public func average<T: AddableType>(ofProperty property: String) -> T? {
        return _rlmCollection.average(ofProperty: property).map(dynamicBridgeCast)
    }

    // MARK: Mutation

//    /**
//     Inserts an object to the set if not already present.
//
//     - warning: This method may only be called during a write transaction.
//
//     - parameter object: An object.
//     */
//    public func insert(_ object: Element) {
//        rlmDictionary.add(dynamicBridgeCast(fromSwift: object) as AnyObject)
//    }
//
//    /**
//     Inserts the given sequence of objects into the set if not already present.
//
//     - warning: This method may only be called during a write transaction.
//    */
//    public func insert<S: Sequence>(objectsIn objects: S) where S.Iterator.Element == Element {
//        for obj in objects {
//            rlmDictionary.add(dynamicBridgeCast(fromSwift: obj) as AnyObject)
//        }
//    }

    /**
     Updates the value stored in the dictionary for the given key, or adds a new key-value pair if the key does not exist.

     - parameter value: a value's key path predicate.
     - parameter forKey: The direction to sort in.
     */
    public func updateValue(_ value: Value, forKey key: Key) {
        rlmDictionary[key as! RLMDictionaryKey] = dynamicBridgeCast(fromSwift: value) as AnyObject
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
            let value = rlmDictionary.object(for: key as! RLMDictionaryKey) as? Value
            return value != nil ? dynamicBridgeCast(fromObjectiveC: value) : nil
        }
        set {
            rlmDictionary.setObject(dynamicBridgeCast(fromSwift: newValue) as AnyObject, for: dynamicBridgeCast(fromSwift: key) as! RLMDictionaryKey)
        }
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
//        return rlmDictionary.addNotificationBlock(wrapObserveBlock(block), queue: queue)
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

//    @objc
//    public override func countByEnumerating(with state: UnsafeMutablePointer<NSFastEnumerationState>, objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>, count len: UInt) -> UInt {
//        
//        var theState = state.pointee
//        if theState.state != 0 {
//            return 0
//        }
//
//        // We need to enumerate a copy of the backing dictionary so that it doesn't
//        // reflect changes made during enumeration. This copy has to be autoreleased
//        // (since there's nowhere for us to store a strong reference), and uses
//        // RLMDictionaryHolder rather than an NSDictionary because NSDictionary doesn't guarantee
//        // that it'll use a single contiguous block of memory, and if it doesn't
//        // we'd need to forward multiple calls to this method to the same NSArray,
//        // which would require holding a reference to it somewhere.
//        var copy: RLMDictionaryHolder = RLMDictionaryHolder()
//        copy->items = std::make_unique<id[]>(_backingCollection.count);
//
//    //    std::vector<std::pair<id<RLMDictionaryKey>, id>> pairs;
//        NSUInteger i = 0;
//        if ([_backingCollection isKindOfClass:[NSDictionary class]]) {
//            for (id key in _backingCollection) {
//        //        copy->items[i++] = std::make_pair(key, _backingCollection[key]);
//                copy->items[i++] = (key, _backingCollection[key]);
//            }
//        }
//        state->itemsPtr = (__unsafe_unretained id *)(void *)copy->items.get();
//    //    state->itemsPtr = (__unsafe_unretained id *)(void *)(&pairs[0]);
//        // needs to point to something valid, but the whole point of this is so
//        // that it can't be changed
//        state->mutationsPtr = state->extra;
//        state->state = i;
//
//        return i;
//    }
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

//extension Map: RealmCollection {
extension Map: Sequence {

    public typealias Index = Int
    public typealias Indices = Range<Int>
//    public typealias SubSequence = Slice<Map>

    public func index(matching predicateFormat: String, _ args: Any...) -> Int? {
        fatalError()
    }

    public func index(matching predicate: NSPredicate) -> Int? {
        fatalError()
    }

    public var keys: [Key] {
        return dynamicBridgeCast(fromObjectiveC: rlmDictionary.allKeys)
    }

    public var values: [Value] {
        return dynamicBridgeCast(fromObjectiveC: rlmDictionary.allValues)
    }

    // MARK: Sequence Support

    /// Returns the first object in the list, or `nil` if the list is empty.
    public var first: Value? {
        return values[0]
    }

    /// Returns the last object in the list, or `nil` if the list is empty.
    public var last: Value? {
        return values[count - 1]
    }

    /// Returns a `RLMMapIterator` that yields successive elements in the `Map`.
    public func makeIterator() -> RLMMapIterator<SingleMapEntry<Key, Value>> {
        return RLMMapIterator(collection: rlmDictionary)
//        return RLMIterator(collection: rlmDictionary)
    }

    /// :nodoc:
    public func asNSFastEnumerator() -> Any {
        return _rlmCollection
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
                         _ block: @escaping (RealmCollectionChange<AnyRealmCollection<SingleMapEntry<Key, Value>>>) -> Void)
        -> NotificationToken {
        fatalError()
//        return rlmDictionary.addNotificationBlock(wrapObserveBlock(block), queue: queue)
    }

    // MARK: Object Retrieval

    public subscript(position: Int) -> Value {
        return dynamicBridgeCast(fromObjectiveC: rlmDictionary.allValues[position]) as Value
//        let key = dynamicBridgeCast(fromObjectiveC: rlmDictionary.allKeys[position]) as Key
//        let val = self[key]!
//        return MapElement(key: key, value: val)
    }
    public subscript(position: Int) -> (Key, Value) {
        let key = dynamicBridgeCast(fromObjectiveC: rlmDictionary.allKeys[position]) as Key
        let val = self[key]!
        return (key, val)
    }

    /// :nodoc:
    public func index(of object: Value) -> Int? {
//        fatalError()
        return Int(rlmDictionary.index(of: object))
    }

    public func index(of object: (Key, Value)) -> Int? {
        fatalError()
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
//
//extension Map {
//    public func filter(_ predicate: NSPredicate) -> Results<(Key, Value)> {
//        return Results<(Key, Value)>(_rlmCollection.objects(with: predicate))
//    }

//    public func sorted(byKeyPath keyPath: String, ascending: Bool) -> Results<(Key, Value)> {
//        fatalError("Not implemented in Map")
//    }
//
//    public func sorted<S>(by sortDescriptors: S) -> Results<(Key, Value)> where S : Sequence, S.Element == SortDescriptor {
//        fatalError("Not implemented in Map")
//    }
//
//    public subscript(key: (Key, Value)) -> Value? {
//        get {
//            let value = rlmDictionary.object(for: key.1 as! RLMDictionaryKey) as? Value
//            return value != nil ? dynamicBridgeCast(fromObjectiveC: value) : nil
//        }
//        set {
//            rlmDictionary.setObject(dynamicBridgeCast(fromSwift: newValue) as AnyObject, for: dynamicBridgeCast(fromSwift: key.0) as! RLMDictionaryKey)
//        }
//    }
//
//    public func makeIterator() -> RLMMapIterator<Key, Value> {
//        return RLMMapIterator(collection: rlmDictionary)
////        return RLMIterator(collection: rlmDictionary)
//    }
//
//    public func _observe(_ queue: DispatchQueue?,
//                         _ block: @escaping (RealmCollectionChange<AnyRealmCollection<(Key, Value)>>) -> Void)
//        -> NotificationToken {
//        fatalError()
////        return rlmDictionary.addNotificationBlock(wrapObserveBlock(block), queue: queue)
//    }
//
//    public subscript(position: Int) -> (Key, Value) {
//        let key = dynamicBridgeCast(fromObjectiveC: rlmDictionary.allKeys[position]) as Key
//        let val = self[key]!
//        return (key, val)
//
////        fatalError()
////        return dynamicBridgeCast(fromObjectiveC: rlmDictionary[rlmDictionary.allKeys[position]]) as Value
////        let key = dynamicBridgeCast(fromObjectiveC: rlmDictionary.allKeys[position]) as Key
////        let val = self[key]!
////        return MapElement(key: key, value: val)
//    }
//
//    public func index(of object: (Key, Value)) -> Int? {
//        fatalError()
//    }
//
//    static func == (lhs: Map<Key, Value>, rhs: Map<Key, Value>) -> Bool {
//        return lhs.keys == rhs.keys && lhs.values == rhs.values
//    }
//}
