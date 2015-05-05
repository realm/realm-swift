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
public class ListBase: RLMListBase, Printable {
    // Printable requires a description property defined in Swift (and not obj-c),
    // and it has to be defined as @objc override, which can't be done in a
    // generic class.
    /// Returns a human-readable description of the objects contained in the list.
    @objc public override var description: String {
        return descriptionWithMaxDepth(RLMDescriptionMaxDepth)
    }

    @objc private func descriptionWithMaxDepth(depth: UInt) -> String {
        let type = "List<\(_rlmArray.objectClassName)>"
        return gsub("RLMArray <0x[a-z0-9]+>", type, _rlmArray.descriptionWithMaxDepth(depth)) ?? type
    }

    /// Returns the number of objects in this list.
    public var count: Int { return Int(_rlmArray.count) }
}

/**
`List<T>` is the container type in Realm used to define to-many relationships.

Lists hold a single `Object` subclass (`T`) which defines the "type" of the list.

Lists can be filtered and sorted with the same predicates as `Results<T>`.

When added as a property on `Object` models, the property must be declared as `let` and cannot be `dynamic`.
*/
public final class List<T: Object>: ListBase {

    // MARK: Properties

    /// The Realm the objects in this list belong to, or `nil` if the list's owning
    /// object does not belong to a realm (the list is standalone).
    public var realm: Realm? {
        if _rlmArray.realm == nil {
            return nil
        }
        return Realm(_rlmArray.realm)
    }

    // MARK: Initializers

    /// Creates a `List` that holds objects of type `T`.
    public override init() {
        super.init(array: RLMArray(objectClassName: T.className()))
    }

    internal init(_ rlmArray: RLMArray) {
        super.init(array: rlmArray)
    }

    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the list.

    :param: object The object whose index is being queried.

    :returns: The index of the given object, or `nil` if the object is not in the list.
    */
    public func indexOf(object: T) -> Int? {
        return notFoundToNil(_rlmArray.indexOfObject(unsafeBitCast(object, RLMObject.self)))
    }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` no objects match.

    :param: predicate The `NSPredicate` used to filter the objects.

    :returns: The index of the given object, or `nil` if no objects match.
    */
    public func indexOf(predicate: NSPredicate) -> Int? {
        return notFoundToNil(_rlmArray.indexOfObjectWithPredicate(predicate))
    }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if no objects match.

    :param: predicateFormat The predicate format string, optionally followed by a variable number
                            of arguments.

    :returns: The index of the given object, or `nil` if no objects match.
    */
    public func indexOf(predicateFormat: String, _ args: CVarArgType...) -> Int? {
        return indexOf(NSPredicate(format: predicateFormat, arguments: getVaList(args)))
    }

    // MARK: Object Retrieval

    /**
    Returns the object at the given `index` on get.
    Replaces the object at the given `index` on set.

    :warning: You can only set an object during a write transaction.

    :param: index The index.

    :returns: The object at the given `index`.
    */
    public subscript(index: Int) -> T {
        get {
            throwForNegativeIndex(index)
            return _rlmArray[UInt(index)] as! T
        }
        set {
            throwForNegativeIndex(index)
            return _rlmArray[UInt(index)] = newValue
        }
    }

    /// Returns the first object in the list, or `nil` if empty.
    public var first: T? { return _rlmArray.firstObject() as! T? }

    /// Returns the last object in the list, or `nil` if empty.
    public var last: T? { return _rlmArray.lastObject() as! T? }

    // MARK: KVC

    /**
    Returns an Array containing the results of invoking `valueForKey:` using key on each of the collection's objects.

    :param: key The name of the property.

    :returns: Array containing the results of invoking `valueForKey:` using key on each of the collection's objects.
    */
    public override func valueForKey(key: String) -> AnyObject? {
        return _rlmArray.valueForKey(key)
    }

    /**
    Invokes `setValue:forKey:` on each of the collection's objects using the specified value and key.

    :warning: This method can only be called during a write transaction.

    :param: value The object value.
    :param: key   The name of the property.
    */
    public override func setValue(value: AnyObject?, forKey key: String) {
        return _rlmArray.setValue(value, forKey: key)
    }

    // MARK: Filtering

    /**
    Returns `Results` containing list elements that match the given predicate.

    :param: predicateFormat The predicate format string which can accept variable arguments.

    :returns: `Results` containing list elements that match the given predicate.
    */
    public func filter(predicateFormat: String, _ args: CVarArgType...) -> Results<T> {
        return Results<T>(_rlmArray.objectsWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args))))
    }

    /**
    Returns `Results` containing list elements that match the given predicate.

    :param: predicate The predicate to filter the objects.

    :returns: `Results` containing list elements that match the given predicate.
    */
    public func filter(predicate: NSPredicate) -> Results<T> {
        return Results<T>(_rlmArray.objectsWithPredicate(predicate))
    }

    // MARK: Sorting

    /**
    Returns `Results` containing list elements sorted by the given property.

    :param: property  The property name to sort by.
    :param: ascending The direction to sort by.

    :returns: `Results` containing list elements sorted by the given property.
    */
    public func sorted(property: String, ascending: Bool = true) -> Results<T> {
        return sorted([SortDescriptor(property: property, ascending: ascending)])
    }

    /**
    Returns `Results` with elements sorted by the given sort descriptors.

    :param: sortDescriptors `SortDescriptor`s to sort by.

    :returns: `Results` with elements sorted by the given sort descriptors.
    */
    public func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>(sortDescriptors: S) -> Results<T> {
        return Results<T>(_rlmArray.sortedResultsUsingDescriptors(map(sortDescriptors) { $0.rlmSortDescriptorValue }))
    }

    // MARK: Mutation

    /**
    Appends the given object to the end of the list. If the object is from a
    different Realm it is copied to the List's Realm.

    :warning: This method can only be called during a write transaction.

    :param: object An object.
    */
    public func append(object: T) {
        _rlmArray.addObject(unsafeBitCast(object, RLMObject.self))
    }

    /**
    Appends the objects in the given sequence to the end of the list.

    :warning: This method can only be called during a write transaction.

    :param: objects A sequence of objects.
    */
    public func extend<S: SequenceType where S.Generator.Element == T>(objects: S) {
        for obj in SequenceOf<T>(objects) {
            _rlmArray.addObject(unsafeBitCast(obj, RLMObject.self))
        }
    }

    /**
    Inserts the given object at the given index.

    :warning: This method can only be called during a write transaction.
    :warning: Throws an exception when called with an index smaller than zero or greater than 
              or equal to the number of objects in the list.

    :param: object An object.
    :param: index  The index at which to insert the object.
    */
    public func insert(object: T, atIndex index: Int) {
        throwForNegativeIndex(index)
        _rlmArray.insertObject(unsafeBitCast(object, RLMObject.self), atIndex: UInt(index))
    }

    /**
    Removes the object at the given index from the list. Does not remove the object from the Realm.

    :warning: This method can only be called during a write transaction.
    :warning: Throws an exception when called with an index smaller than zero or greater than
              or equal to the number of objects in the list.

    :param: index The index at which to remove the object.
    */
    public func removeAtIndex(index: Int) {
        throwForNegativeIndex(index)
        _rlmArray.removeObjectAtIndex(UInt(index))
    }

    /**
    Removes the last object in the list. Does not remove the object from the Realm.

    :warning: This method can only be called during a write transaction.
    */
    public func removeLast() {
        _rlmArray.removeLastObject()
    }

    /**
    Removes all objects from the List. Does not remove the objects from the Realm.

    :warning: This method can only be called during a write transaction.
    */
    public func removeAll() {
        _rlmArray.removeAllObjects()
    }

    /**
    Replaces an object at the given index with a new object.

    :warning: This method can only be called during a write transaction.
    :warning: Throws an exception when called with an index smaller than zero or greater than
              or equal to the number of objects in the list.

    :param: index  The list index of the object to be replaced.
    :param: object An object to replace at the specified index.
    */
    public func replace(index: Int, object: T) {
        throwForNegativeIndex(index)
        _rlmArray.replaceObjectAtIndex(UInt(index), withObject: unsafeBitCast(object, RLMObject.self))
    }
}

extension List: ExtensibleCollectionType {
    // MARK: Sequence Support

    /// Returns a `GeneratorOf<T>` that yields successive elements in the list.
    public func generate() -> GeneratorOf<T> {
        let base = NSFastGenerator(_rlmArray)
        return GeneratorOf<T>() {
            return base.next() as! T?
        }
    }

    // MARK: ExtensibleCollection Support

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int { return 0 }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by zero or more applications of successor().
    public var endIndex: Int { return count }

    /// This method has no effect.
    public func reserveCapacity(capacity: Int) { }
}
