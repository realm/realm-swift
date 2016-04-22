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
import Realm.Private

/// :nodoc:
/// Internal class. Do not use directly.
public class ListBase: RLMListBase {
    // Printable requires a description property defined in Swift (and not obj-c),
    // and it has to be defined as @objc override, which can't be done in a
    // generic class.
    /// Returns a human-readable description of the objects contained in the List.
    @objc public override var description: String {
        return descriptionWithMaxDepth(RLMDescriptionMaxDepth)
    }

    @objc private func descriptionWithMaxDepth(depth: UInt) -> String {
        let type = "List<\(_rlmArray.objectClassName)>"
        return gsub("RLMArray <0x[a-z0-9]+>", template: type, string: _rlmArray.descriptionWithMaxDepth(depth)) ?? type
    }

    /// Returns the number of objects in this List.
    public var count: Int { return Int(_rlmArray.count) }
}

/**
`List<T>` is the container type in Realm used to define to-many relationships.

Lists hold a single `Object` subclass (`T`) which defines the "type" of the List.

Lists can be filtered and sorted with the same predicates as `Results<T>`.

When added as a property on `Object` models, the property must be declared as `let` and cannot be `dynamic`.
*/
public final class List<T: Object>: ListBase {

    /// Element type contained in this collection.
    public typealias Element = T

    // MARK: Properties

    /// The Realm the objects in this List belong to, or `nil` if the List's
    /// owning object does not belong to a Realm (the List is standalone).
    public var realm: Realm? {
        return _rlmArray.realm.map { Realm($0) }
    }

    /// Indicates if the List can no longer be accessed.
    public var invalidated: Bool { return _rlmArray.invalidated }

    // MARK: Initializers

    /// Creates a `List` that holds objects of type `T`.
    public override init() {
        super.init(array: RLMArray(objectClassName: (T.self as Object.Type).className()))
    }

    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the List.

    - parameter object: The object whose index is being queried.

    - returns: The index of the given object, or `nil` if the object is not in the List.
    */
    public func indexOf(object: T) -> Int? {
        return notFoundToNil(_rlmArray.indexOfObject(unsafeBitCast(object, RLMObject.self)))
    }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` no objects match.

    - parameter predicate: The `NSPredicate` used to filter the objects.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    public func indexOf(predicate: NSPredicate) -> Int? {
        return notFoundToNil(_rlmArray.indexOfObjectWithPredicate(predicate))
    }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if no objects match.

    - parameter predicateFormat: The predicate format string, optionally
                                 followed by a variable number of arguments.

    - returns: The index of the first matching object, or `nil` if no objects match.
    */
    public func indexOf(predicateFormat: String, _ args: AnyObject...) -> Int? {
        return indexOf(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    // MARK: Object Retrieval

    /**
    Returns the object at the given `index` on get.
    Replaces the object at the given `index` on set.

    - warning: You can only set an object during a write transaction.

    - parameter index: The index.

    - returns: The object at the given `index`.
    */
    public subscript(index: Int) -> T {
        get {
            throwForNegativeIndex(index)
            return _rlmArray[UInt(index)] as! T
        }
        set {
            throwForNegativeIndex(index)
            return _rlmArray[UInt(index)] = unsafeBitCast(newValue, RLMObject.self)
        }
    }

    /// Returns the first object in the List, or `nil` if empty.
    public var first: T? { return _rlmArray.firstObject() as! T? }

    /// Returns the last object in the List, or `nil` if empty.
    public var last: T? { return _rlmArray.lastObject() as! T? }

    // MARK: KVC

    /**
    Returns an Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.

    - parameter key: The name of the property.

    - returns: Array containing the results of invoking `valueForKey(_:)` using key on each of the collection's objects.
    */
    public override func valueForKey(key: String) -> AnyObject? {
        return _rlmArray.valueForKey(key)
    }

    /**
     Returns an Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.

     - parameter keyPath: The key path to the property.

     - returns: Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.
     */
    public override func valueForKeyPath(keyPath: String) -> AnyObject? {
        return _rlmArray.valueForKeyPath(keyPath)
    }

    /**
    Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified value and key.

    - warning: This method can only be called during a write transaction.

    - parameter value: The object value.
    - parameter key:   The name of the property.
    */
    public override func setValue(value: AnyObject?, forKey key: String) {
        return _rlmArray.setValue(value, forKey: key)
    }

    // MARK: Filtering

    /**
    Returns `Results` containing elements that match the given predicate.

    - parameter predicateFormat: The predicate format string which can accept variable arguments.

    - returns: `Results` containing elements that match the given predicate.
    */
    public func filter(predicateFormat: String, _ args: AnyObject...) -> Results<T> {
        return Results<T>(_rlmArray.objectsWithPredicate(NSPredicate(format: predicateFormat, argumentArray: args)))
    }

    /**
    Returns `Results` containing elements that match the given predicate.

    - parameter predicate: The predicate to filter the objects.

    - returns: `Results` containing elements that match the given predicate.
    */
    public func filter(predicate: NSPredicate) -> Results<T> {
        return Results<T>(_rlmArray.objectsWithPredicate(predicate))
    }

    // MARK: Sorting

    /**
    Returns `Results` containing elements sorted by the given property.

    - parameter property:  The property name to sort by.
    - parameter ascending: The direction to sort by.

    - returns: `Results` containing elements sorted by the given property.
    */
    public func sorted(property: String, ascending: Bool = true) -> Results<T> {
        return sorted([SortDescriptor(property: property, ascending: ascending)])
    }

    /**
    Returns `Results` with elements sorted by the given sort descriptors.

    - parameter sortDescriptors: `SortDescriptor`s to sort by.

    - returns: `Results` with elements sorted by the given sort descriptors.
    */
    public func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>(sortDescriptors: S) -> Results<T> {
        return Results<T>(_rlmArray.sortedResultsUsingDescriptors(sortDescriptors.map { $0.rlmSortDescriptorValue }))
    }

    // MARK: Aggregate Operations

    /**
    Returns the minimum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a minimum on.

    - returns: The minimum value for the property amongst objects in the List, or `nil` if the List is empty.
    */
    public func min<U: MinMaxType>(property: String) -> U? {
        return filter(NSPredicate(value: true)).min(property)
    }

    /**
    Returns the maximum value of the given property.

    - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    - parameter property: The name of a property conforming to `MinMaxType` to look for a maximum on.

    - returns: The maximum value for the property amongst objects in the List, or `nil` if the List is empty.
    */
    public func max<U: MinMaxType>(property: String) -> U? {
        return filter(NSPredicate(value: true)).max(property)
    }

    /**
    Returns the sum of the given property for objects in the List.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate sum on.

    - returns: The sum of the given property over all objects in the List.
    */
    public func sum<U: AddableType>(property: String) -> U {
        return filter(NSPredicate(value: true)).sum(property)
    }

    /**
    Returns the average of the given property for objects in the List.

    - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    - parameter property: The name of a property conforming to `AddableType` to calculate average on.

    - returns: The average of the given property over all objects in the List, or `nil` if the List is empty.
    */
    public func average<U: AddableType>(property: String) -> U? {
        return filter(NSPredicate(value: true)).average(property)
    }

    // MARK: Mutation

    /**
    Appends the given object to the end of the List. If the object is from a
    different Realm it is copied to the List's Realm.

    - warning: This method can only be called during a write transaction.

    - parameter object: An object.
    */
    public func append(object: T) {
        _rlmArray.addObject(unsafeBitCast(object, RLMObject.self))
    }

    /**
    Appends the objects in the given sequence to the end of the List.

    - warning: This method can only be called during a write transaction.

    - parameter objects: A sequence of objects.
    */
    public func appendContentsOf<S: SequenceType where S.Generator.Element == T>(objects: S) {
        for obj in objects {
            _rlmArray.addObject(unsafeBitCast(obj, RLMObject.self))
        }
    }

    /**
    Inserts the given object at the given index.

    - warning: This method can only be called during a write transaction.
    - warning: Throws an exception when called with an index smaller than zero
               or greater than or equal to the number of objects in the List.

    - parameter object: An object.
    - parameter index:  The index at which to insert the object.
    */
    public func insert(object: T, atIndex index: Int) {
        throwForNegativeIndex(index)
        _rlmArray.insertObject(unsafeBitCast(object, RLMObject.self), atIndex: UInt(index))
    }

    /**
    Removes the object at the given index from the List. Does not remove the object from the Realm.

    - warning: This method can only be called during a write transaction.
    - warning: Throws an exception when called with an index smaller than zero
               or greater than or equal to the number of objects in the List.

    - parameter index: The index at which to remove the object.
    */
    public func removeAtIndex(index: Int) {
        throwForNegativeIndex(index)
        _rlmArray.removeObjectAtIndex(UInt(index))
    }

    /**
    Removes the last object in the List. Does not remove the object from the Realm.

    - warning: This method can only be called during a write transaction.
    */
    public func removeLast() {
        _rlmArray.removeLastObject()
    }

    /**
    Removes all objects from the List. Does not remove the objects from the Realm.

    - warning: This method can only be called during a write transaction.
    */
    public func removeAll() {
        _rlmArray.removeAllObjects()
    }

    /**
    Replaces an object at the given index with a new object.

    - warning: This method can only be called during a write transaction.
    - warning: Throws an exception when called with an index smaller than zero
               or greater than or equal to the number of objects in the List.

    - parameter index:  The index of the object to be replaced.
    - parameter object: An object to replace at the specified index.
    */
    public func replace(index: Int, object: T) {
        throwForNegativeIndex(index)
        _rlmArray.replaceObjectAtIndex(UInt(index), withObject: unsafeBitCast(object, RLMObject.self))
    }

    /**
    Moves the object at the given source index to the given destination index.

    - warning: This method can only be called during a write transaction.
    - warning: Throws an exception when called with an index smaller than zero or greater than
               or equal to the number of objects in the List.

    - parameter from:  The index of the object to be moved.
    - parameter to:    index to which the object at `from` should be moved.
    */
    public func move(from from: Int, to: Int) { // swiftlint:disable:this variable_name
        throwForNegativeIndex(from)
        throwForNegativeIndex(to)
        _rlmArray.moveObjectAtIndex(UInt(from), toIndex: UInt(to))
    }

    /**
    Exchanges the objects in the List at given indexes.

    - warning: Throws an exception when either index exceeds the bounds of the List.
    - warning: This method can only be called during a write transaction.

    - parameter index1: The index of the object with which to replace the object at index `index2`.
    - parameter index2: The index of the object with which to replace the object at index `index1`.
    */
    public func swap(index1: Int, _ index2: Int) {
        throwForNegativeIndex(index1, parameterName: "index1")
        throwForNegativeIndex(index2, parameterName: "index2")
        _rlmArray.exchangeObjectAtIndex(UInt(index1), withObjectAtIndex: UInt(index2))
    }

    // MARK: Notifications

    /**
    Register a block to be called each time the List changes.

    The block will be asynchronously called with the initial list, and then
    called again after each write transaction which changes the list or any of
    the items in the list.

    The block is called on the same thread as it was added on, and can only
    be added on threads which are currently within a run loop. Unless you are
    specifically creating and running a run loop on a background thread, this
    will normally only be the main thread.

    Notifications are delivered via the standard run loop, and so can't be
    delivered while the run loop is blocked by other activity. When
    notifications can't be delivered instantly, multiple notifications may be
    coalesced into a single notification. This can include the notification
    with the initial list. For example, the following code performs a write
    transaction immediately after adding the notification block, so there is no
    opportunity for the initial notification to be delivered first. As a
    result, the initial notification will reflect the state of the Realm after
    the write transaction.

        let person = realm.objects(Person).first!
        print("dogs.count: \(person.dogs.count)") // => 0
        let token = person.dogs.addNotificationBlock { (dogs: List) in
            // Only fired once for the example
            print("dogs.count: \(dogs.count)") // will only print "dogs.count: 1"
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
     - warning: This method can only be called on Lists which are stored on an
                Object which has been added to or retrieved from a Realm.

    - parameter block: The block to be called each time the list changes.
    - returns: A token which must be held for as long as you want notifications to be delivered.
    */
    @available(*, deprecated=1, message="Use addNotificationBlock with changes")
    @warn_unused_result(message="You must hold on to the NotificationToken returned from addNotificationBlock")
    public func addNotificationBlock(block: (list: List<T>) -> ()) -> NotificationToken {
        return _rlmArray.addNotificationBlock { _, _, _ in block(list: self) }
    }

    /**
    Register a block to be called each time the List changes.

    The block will be asynchronously called with the initial list, and then
    called again after each write transaction which changes the list or any of
    the items in the list.

    This version of this method reports which of the objects in the List were
    added, removed, or modified in each write transaction as indices within the
    List. See the RealmCollectionChange documentation for more information on
    the change information supplied and an example of how to use it to update
    a UITableView.

    The block is called on the same thread as it was added on, and can only
    be added on threads which are currently within a run loop. Unless you are
    specifically creating and running a run loop on a background thread, this
    will normally only be the main thread.

    Notifications can't be delivered as long as the run loop is blocked by
    other activity. When notifications can't be delivered instantly, multiple
    notifications may be coalesced into a single notification. This can include
    the notification with the initial list. For example, the following code
    performs a write transaction immediately after adding the notification block,
    so there is no opportunity for the initial notification to be delivered first.
    As a result, the initial notification will reflect the state of the Realm
    after the write transaction, and will not include change information.

        let person = realm.objects(Person).first!
        print("dogs.count: \(person.dogs.count)") // => 0
        let token = person.dogs.addNotificationBlock { (changes: RealmCollectionChange) in
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
     - warning: This method can only be called on Lists which are stored on an
                Object which has been added to or retrieved from a Realm.

    - parameter block: The block to be called each time the list changes.
    - returns: A token which must be held for as long as you want notifications to be delivered.
    */
    @warn_unused_result(message="You must hold on to the NotificationToken returned from addNotificationBlock")
    public func addNotificationBlock(block: (RealmCollectionChange<List>) -> ()) -> NotificationToken {
        return _rlmArray.addNotificationBlock { list, change, error in
            block(RealmCollectionChange.fromObjc(self, change: change, error: error))
        }
    }
}

extension List: RealmCollectionType, RangeReplaceableCollectionType {
    // MARK: Sequence Support

    /// Returns a `GeneratorOf<T>` that yields successive elements in the List.
    public func generate() -> RLMGenerator<T> {
        return RLMGenerator(collection: _rlmArray)
    }

    // MARK: RangeReplaceableCollection Support

    /**
    Replace the given `subRange` of elements with `newElements`.

    - parameter subRange:    The range of elements to be replaced.
    - parameter newElements: The new elements to be inserted into the List.
    */
    public func replaceRange<C: CollectionType where C.Generator.Element == T>(subRange: Range<Int>,
                                                                               with newElements: C) {
        for _ in subRange {
            removeAtIndex(subRange.startIndex)
        }
        for x in newElements.reverse() {
            insert(x, atIndex: subRange.startIndex)
        }
    }

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int { return 0 }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    public var endIndex: Int { return count }

    /// :nodoc:
    public func _addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection<T>>) -> Void) ->
        NotificationToken {
        let anyCollection = AnyRealmCollection(self)
        return _rlmArray.addNotificationBlock { _, change, error in
            block(RealmCollectionChange.fromObjc(anyCollection, change: change, error: error))
        }
    }
}
