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

import Realm
import Realm.Private

/// Internal class. Do not use directly.
public class ListBase: RLMListBase, Printable {
    // Printable requires a description property defined in Swift (and not obj-c),
    // and it has to be defined as @objc override, which can't be done in a
    // generic class.
    /// Returns a human-readable description of the objects contained in the list.
    @objc public override var description: String { return _rlmArray.description }

    /// Returns the number of objects in this list.
    public var count: Int { return Int(_rlmArray.count) }
}

/**
 List<T> is the container type in Realm used to define to-many relationships.

 Lists hold a single `Object` subclass, `T`, which defines the "type" of the list.

 Lists can be filtered and sorted with the same predicates as `Results<T>`.
*/
public final class List<T: Object>: ListBase, SequenceType {
    // MARK: Properties

    /// The Realm the objects in this list belong to, or `nil` if the list's owning
    /// object does not belong to a realm (the list is standalone).
    public var realm: Realm? {
        if _rlmArray.realm == nil {
            return nil
        }
        return Realm(rlmRealm: _rlmArray.realm)
    }

    // MARK: Initializers

    /// Creates a List that holds objects of type `T`.
    public override init() {
        super.init(array: RLMArray(objectClassName: T.className()))
    }

    /**
    Creates a List that is backed by the given `RLMArray`.

    :param: rlmArray The RLMArray that backs the list.
    */
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
    or `nil` if the object is not in the list.

    :param: predicate The predicate to filter the objects.

    :returns: The index of the given object, or `nil` if the object is not in the list.
    */
    public func indexOf(predicate: NSPredicate) -> Int? {
        return notFoundToNil(_rlmArray.indexOfObjectWithPredicate(predicate))
    }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if the object is not in the list.

    :param: predicateFormat The predicate format to filter the objects.

    :returns: The index of the given object, or `nil` if the object is not in the list.
    */
    public func indexOf(predicateFormat: String, _ args: CVarArgType...) -> Int? {
        return notFoundToNil(_rlmArray.indexOfObjectWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args))))
    }

    // MARK: Object Retrieval

    /**
    Returns the object at the given `index`.

    :warning: You can only set an object during a write transaction.

    :param: index The index.

    :returns: The object at the given `index`.
    */
    public subscript(index: Int) -> T {
        get {
            return _rlmArray[UInt(index)] as T
        }
        set {
            return _rlmArray[UInt(index)] = newValue
        }
    }

    /// Returns the first object in the list, or `nil` if empty.
    public var first: T? { return _rlmArray.firstObject() as T? }

    /// Returns the last object in the list, or `nil` if empty.
    public var last: T? { return _rlmArray.lastObject() as T? }

    // MARK: Subarray Retrieval

    /**
    Filters the List to the objects that match the given predicate.

    :param: predicateFormat The predicate format string which can accept variable arguments.

    :returns: Results containing objects that match the given predicate.
    */
    public func filter(predicateFormat: String, _ args: CVarArgType...) -> Results<T> {
        return Results<T>(_rlmArray.objectsWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args))))
    }

    /**
    Filters the List to the objects that match the given predicate.

    :param: predicateFormat The predicate to filter the objects.

    :returns: Results containing objects that match the given predicate.
    */
    public func filter(predicate: NSPredicate) -> Results<T> {
        return Results<T>(_rlmArray.objectsWithPredicate(predicate))
    }

    // MARK: Sorting

    /**
    Returns a sorted version of the list.

    :param: property  The property name to sort by.
    :param: ascending The direction to sort by.

    :returns: Results containing the objects in the list sorted by the given property.
    */
    public func sorted(property: String, ascending: Bool = true) -> Results<T> {
        return Results<T>(_rlmArray.sortedResultsUsingProperty(property, ascending: ascending))
    }

    // MARK: Sequence support

    /**
    Returns a `GeneratorOf<T>` that yields successive elements in the list.

    :returns: A `GeneratorOf<T>` that yields successive elements in the list.
    */
    public func generate() -> GeneratorOf<T> {
        var i: UInt = 0
        return GeneratorOf<T>() {
            if (i >= self._rlmArray.count) {
                return .None
            } else {
                return self._rlmArray[i++] as? T
            }
        }
    }

    // MARK: Mutation

    /**
    Appends the given object to the end of the list.

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
    public func append<S: SequenceType where S.Generator.Element == T>(objects: S) {
	for obj in SequenceOf<T>(objects) { // Workaround for http://stackoverflow.com/questions/26918594
	    _rlmArray.addObject(unsafeBitCast(obj, RLMObject.self))
	}
    }

    /**
    Inserts the given object at the given index.

    :warning: This method can only be called during a write transaction.
    :warning: Throws an exception when called with an index greater than the number of objects in the list.

    :param: object An object.
    :param: index  The index at which to insert the object.
    */
    public func insert(object: T, atIndex index: Int) {
        _rlmArray.insertObject(unsafeBitCast(object, RLMObject.self), atIndex: UInt(index))
    }

    /**
    Removes the object at the given index.

    :warning: This method can only be called during a write transaction.
    :warning: Throws an exception when called with an index greater than the number of objects in the list.

    :param: index The index at which to remove the object.
    */
    public func remove(index: Int) {
        _rlmArray.removeObjectAtIndex(UInt(index))
    }

    /**
    Removes the given object from the list.

    :warning: This method can only be called during a write transaction.

    :param: object An object.
    */
    public func remove(object: T) {
        if let index = indexOf(object) {
            remove(index)
        }
    }

    /**
    Removes the last object in the List. Does not remove the object from the Realm.

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

    Throws an exception when called with an index greater than the number of objects in this List.

    :warning: This method can only be called during a write transaction.

    :param: index  The list index of the object to be replaced.
    :param: object An object to replace at the specified index.
    */
    public func replace(index: Int, object: T) {
        _rlmArray.replaceObjectAtIndex(UInt(index), withObject: unsafeBitCast(object, RLMObject.self))
    }
}

// MARK: Private helpers

/**
Converts `NSNotFound` to `nil`, otherwise returns `index` as an `Int`.

:param: index Value to convert.

:returns: `nil` if `index` is `NSNotFound`, `index` as an `Int` otherwise.
*/
internal func notFoundToNil(index: UInt) -> Int? {
    if index == UInt(NSNotFound) {
	return nil
    }
    return Int(index)
}
