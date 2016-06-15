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

// MARK: MinMaxType

/**
 A protocol describing types of properties which can be used with the minimum and maximum value APIs.

 - see: `minimumValue(ofProperty:)`, `maximumValue(ofProperty:)`
 */
public protocol MinMaxType {}
extension Double: MinMaxType {}
extension Float: MinMaxType {}
extension Int: MinMaxType {}
extension Int8: MinMaxType {}
extension Int16: MinMaxType {}
extension Int32: MinMaxType {}
extension Int64: MinMaxType {}
extension NSDate: MinMaxType {}

// MARK: AddableType

/**
 A protocol describing types of properties which can be used with the sum and average value APIs.

 - see: `sum(ofProperty:)`, `average(ofProperty:)`
 */
public protocol AddableType {}
extension Double: AddableType {}
extension Float: AddableType {}
extension Int: AddableType {}
extension Int8: AddableType {}
extension Int16: AddableType {}
extension Int32: AddableType {}
extension Int64: AddableType {}

/**
 `Results` is an auto-updating container type in Realm returned from object queries.

 `Results` can be queried with the same predicates as `List<T>`, and queries can be chained to further filter query
 results.

 The contents of a `Results` object always reflect the current state of the Realm on the current thread, including
 during write transactions on the current thread. The one exception to this is when using `for...in` enumeration, which
 will always enumerate over the objects which matched the query when the enumeration is begun, even if some of them are
 deleted or modified to be excluded by the filter during the enumeration.

 `Results` objects are lazily evaluated the first time they are accessed: they only run queries when the result of the
 query is requested. This means that chaining several temporary `Results` to sort and filter your data does not perform
 any unnecessary work processing the intermediate state.

 Once the `Results` object has been evaluated or a notification block has been added, the results are eagerly kept
 up-to-date, with the necessary work done on a background thread whenever possible.

 `Results` objects cannot be directly instantiated.
 */
public final class Results<T: Object>: NSObject, NSFastEnumeration {

    internal let rlmResults: RLMResults<RLMObject>

    public override var description: String {
        let type = "Results<\(rlmResults.objectClassName)>"
        return gsub(pattern: "RLMResults <0x[a-z0-9]+>", template: type, string: rlmResults.description) ?? type
    }

    // MARK: Fast Enumeration

    public func countByEnumerating(with state: UnsafeMutablePointer<NSFastEnumerationState>,
                   objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>!,
                   count len: Int) -> Int {
        return Int(rlmResults.countByEnumerating(with: state, objects: buffer, count: UInt(len)))
    }

    /// The type of the elements contained within the results collection.
    public typealias Element = T

    // MARK: Properties

    /**
     The Realm which manages the results collection.
     
     - note: Despite being marked as a value of optional type, this property will never return `nil`.
    */
    public var realm: Realm? { return Realm(rlmResults.realm) }

    /**
     Indicates if the results collection is no longer valid.

     The results collection becomes invalid if `invalidate()` is called on the Realm managing it. An invalidated
     results collection can be accessed, but will always be empty.
     */
    public var isInvalidated: Bool { return rlmResults.isInvalidated }

    /// The number of objects represented by the results collection.
    public var count: Int { return Int(rlmResults.count) }

    // MARK: Initializers

    internal init(_ rlmResults: RLMResults<RLMObject>) {
        self.rlmResults = rlmResults
    }

    // MARK: Index Retrieval

    /**
     Returns the index of an object in the results collection, or `nil` if the object is not present.

     - parameter object: An object.
     */
    public func index(of object: T) -> Int? {
        return notFoundToNil(index: rlmResults.index(of: unsafeBitCast(object, to: RLMObject.self)))
    }

    /**
     Returns the index of the first object in the results collection matching the predicate, or `nil` if no objects
     match.

     - parameter predicate: The predicate with which to filter the objects.
     */
    public func indexOfObject(for predicate: Predicate) -> Int? {
        return notFoundToNil(index: rlmResults.indexOfObject(with: predicate))
    }

    /**
     Returns the index of the first object in the results collection matching the predicate, or `nil` if no objects
     match.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.`
     */
    public func indexOfObject(for predicateFormat: String, _ args: AnyObject...) -> Int? {
        return notFoundToNil(index: rlmResults.indexOfObject(with: Predicate(format: predicateFormat,
                                                                             argumentArray: args)))
    }

    // MARK: Object Retrieval

    public subscript(position: Int) -> T {
        throwForNegativeIndex(position)
        return unsafeBitCast(rlmResults.object(at: UInt(position)), to: T.self)
    }

    /// Returns the first object in the results collection, or `nil` if the collection is empty.
    public var first: T? { return unsafeBitCast(rlmResults.firstObject(), to: Optional<T>.self) }

    /// Returns the last object in the results collection, or `nil` if the collection is empty.
    public var last: T? { return unsafeBitCast(rlmResults.lastObject(), to: Optional<T>.self) }

    // MARK: KVC

    /**
     Returns an `Array` containing the results of invoking `value(forKey:)` with `key` on each of the objects
     represented by the results collection.

     - parameter key: The name of the property whose values are desired.
     */
    public override func value(forKey key: String) -> AnyObject? {
        return value(forKeyPath: key)
    }

    /**
     Returns an `Array` containing the results of invoking `value(forKeyPath:)` with `keyPath` on each of the objects
     represented by the results collection.

     - parameter keyPath: The key path to the property whose values are desired.
     */
    public override func value(forKeyPath keyPath: String) -> AnyObject? {
        return rlmResults.value(forKeyPath: keyPath)
    }

    /**
     Invokes `setValue(_:forKey:)` on each of the objects represented by the results collection using the specified
     `value` and `key`.

     - warning: This method may only be called during a write transaction.

     - parameter value: The object value.
     - parameter key:   The name of the property whose value should be set on each object.
     */
    public override func setValue(_ value: AnyObject?, forKey key: String) {
        return rlmResults.setValue(value, forKeyPath: key)
    }

    // MARK: Filtering

    /**
     Returns a `Results` containing all objects in the results collection matching the given predicate.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.
     */
    public func filter(using predicateFormat: String, _ args: AnyObject...) -> Results<T> {
        return Results<T>(rlmResults.objects(with: Predicate(format: predicateFormat, argumentArray: args)))
    }

    /**
     Returns a `Results` containing all objects in the results collection matching the given predicate.

     - parameter predicate: The predicate with which to filter the objects.
     */
    public func filter(using predicate: Predicate) -> Results<T> {
        return Results<T>(rlmResults.objects(with: predicate))
    }

    // MARK: Sorting

    /**
     Returns a `Results` containing all the objects represented by the results collection, but sorted.

     Objects are sorted based on the values of the given property. For example, to sort a collection of `Student`s from
     youngest to oldest based on their `age` property, you might call
     `students.sorted(onProperty: "age", ascending: true)`.

     - warning:  Collections may only be sorted by properties of boolean, `NSDate`, single and double-precision floating
                 point, integer, and string types.

     - parameter property:  The name of the property to sort by.
     - parameter ascending: The direction to sort in.
     */
    public func sorted(onProperty property: String, ascending: Bool = true) -> Results<T> {
        return sorted(with: [SortDescriptor(property: property, ascending: ascending)])
    }

    /**
     Returns a `Results` containing all the objects represented by the results collection, but sorted.

     - warning:  Collections may only be sorted by properties of boolean, `NSDate`, single and double-precision floating
                 point, integer, and string types.

     - see: `sorted(onProperty:ascending:)`

     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     */
    public func sorted<S: Sequence where S.Iterator.Element == SortDescriptor>(with sortDescriptors: S) -> Results<T> {
        return Results<T>(rlmResults.sortedResults(using: sortDescriptors.map { $0.rlmSortDescriptorValue }))
    }

    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects represented by the results
     collection, or `nil` if the results collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.
     */
    public func minimumValue<U: MinMaxType>(ofProperty property: String) -> U? {
        return rlmResults.min(ofProperty: property) as! U?
    }

    /**
     Returns the maximum (highest) value of the given property among all the objects represented by the results
     collection, or `nil` if the results collection is empty.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.

     - returns: The maximum value of the property, or `nil` if the collection is empty.
     */
    public func maximumValue<U: MinMaxType>(ofProperty property: String) -> U? {
        return rlmResults.max(ofProperty: property) as! U?
    }

    /**
     Returns the sum of the values of a given property over all the objects represented by the results collection.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.

     - returns: The sum of the given property.
     */
    public func sum<U: AddableType>(ofProperty property: String) -> U {
        return rlmResults.sum(ofProperty: property) as AnyObject as! U
    }

    /**
     Returns the average value of a given property over all the objects represented by the results collection, or `nil`
     if the results collection is empty.

     - warning: Only the name of a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose average value should be calculated.

     - returns: The average value of the given property, or `nil` if the collection is empty.
     */
    public func average<U: AddableType>(ofProperty property: String) -> U? {
        return rlmResults.average(ofProperty: property) as! U?
    }

    // MARK: Notifications

    /**
     Registers a block to be called each time the results collection changes.

     The block will be asynchronously called with the initial results, and then called again after each write
     transaction which changes either any of the objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the collection, which of 
     the objects were added, removed, or modified during each write transaction. See the `RealmCollectionChange` 
     documentation for more information on the change information supplied and an example of how to use it to update a
     `UITableView`.

     At the time when the block is called, the collection will be fully evaluated and up-to-date. As long as you do not 
     perform a write transaction on the same thread or explicitly call `refresh()` on the Realm, accessing it will never
     perform blocking work.

     Notifications are delivered via the standard run loop, and so can't be delivered while the run loop is blocked by
     other activity. When notifications can't be delivered instantly, multiple notifications may be coalesced into a
     single notification. This can include the notification with the initial collection. For example, the following code
     performs a write transaction immediately after adding the notification block, so there is no opportunity for the
     initial notification to be delivered first. As a result, the initial notification will reflect the state of the
     Realm after the write transaction.

     ```swift
     let dogs = realm.objects(Dog.self)
     print("dogs.count: \(dogs?.count)") // => 0
     let token = dogs.addNotificationBlock { (changes: RealmCollectionChange) in
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

     You must retain the returned token for as long as you want updates to continue to be sent to the block. To stop
     receiving updates, call `stop()` on the token.

     - warning: This method cannot be called during a write transaction, or when the containing Realm is read-only.

     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be retained for as long as you want updates to be delivered.
     */
    public func addNotificationBlock(block: ((RealmCollectionChange<Results>) -> Void)) -> NotificationToken {
        return rlmResults.addNotificationBlock { results, change, error in
            block(RealmCollectionChange.fromObjc(value: self, change: change, error: error))
        }
    }
}

extension Results: RealmCollection {
    // MARK: Sequence Support

    /// Returns a `RLMIterator` that yields successive elements in the results.
    public func makeIterator() -> RLMIterator<T> {
        return RLMIterator(collection: rlmResults)
    }

    // MARK: Collection Support

    public var startIndex: Int { return 0 }
    public var endIndex: Int { return count }
    public func index(after i: Int) -> Int { return i + 1 }
    public func index(before i: Int) -> Int { return i - 1 }

    /// :nodoc:
    public func _addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection<T>>) -> Void) ->
        NotificationToken {
        let anyCollection = AnyRealmCollection(self)
        return rlmResults.addNotificationBlock { _, change, error in
            block(RealmCollectionChange.fromObjc(value: anyCollection, change: change, error: error))
        }
    }
}

// MARK: Unavailable

extension Results {
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
