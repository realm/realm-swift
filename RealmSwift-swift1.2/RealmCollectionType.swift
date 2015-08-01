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

/**
Encapsulates iteration state and interface for iteration over a
`RealmCollectionType`.
*/
public final class RLMGenerator<T: Object>: GeneratorType {
    private let generatorBase: NSFastGenerator

    internal init(collection: RLMCollection) {
        generatorBase = NSFastGenerator(collection)
    }

    /// Advance to the next element and return it, or `nil` if no next element
    /// exists.
    public func next() -> T? {
        let accessor = generatorBase.next() as! T?
        if let accessor = accessor {
            RLMInitializeSwiftListAccessor(accessor)
        }
        return accessor
    }
}

/**
A homogenous collection of `Object`s which can be retrieved, filtered, sorted,
and operated upon.
*/
public protocol RealmCollectionType: CollectionType {

    /// Element type contained in this collection.
    typealias Element: Object


    // MARK: Properties

    /// The Realm the objects in this collection belong to, or `nil` if the
    /// collection's owning object does not belong to a realm (the collection is
    /// standalone).
    var realm: Realm? { get }


    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the collection.

    :param: object The object whose index is being queried.

    :returns: The index of the given object, or `nil` if the object is not in the collection.
    */
    func indexOf(object: Element) -> Int?

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` no objects match.

    :param: predicate The `NSPredicate` used to filter the objects.

    :returns: The index of the given object, or `nil` if no objects match.
    */
    func indexOf(predicate: NSPredicate) -> Int?

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if no objects match.

    :param: predicateFormat The predicate format string, optionally followed by a variable number
    of arguments.

    :returns: The index of the given object, or `nil` if no objects match.
    */
    func indexOf(predicateFormat: String, _ args: CVarArgType...) -> Int?


    // MARK: Object Retrieval

    /// Returns the first object in the collection, or `nil` if empty.
    var first: Element? { get }

    /// Returns the last object in the collection, or `nil` if empty.
    var last: Element? { get }


    // MARK: Filtering

    /**
    Returns `Results` containing collection elements that match the given predicate.

    :param: predicateFormat The predicate format string which can accept variable arguments.

    :returns: `Results` containing collection elements that match the given predicate.
    */
    func filter(predicateFormat: String, _ args: CVarArgType...) -> Results<Element>

    /**
    Returns `Results` containing collection elements that match the given predicate.

    :param: predicate The predicate to filter the objects.

    :returns: `Results` containing collection elements that match the given predicate.
    */
    func filter(predicate: NSPredicate) -> Results<Element>


    // MARK: Sorting

    /**
    Returns `Results` containing collection elements sorted by the given property.

    :param: property  The property name to sort by.
    :param: ascending The direction to sort by.

    :returns: `Results` containing collection elements sorted by the given property.
    */
    func sorted(property: String, ascending: Bool) -> Results<Element>

    /**
    Returns `Results` with elements sorted by the given sort descriptors.

    :param: sortDescriptors `SortDescriptor`s to sort by.

    :returns: `Results` with elements sorted by the given sort descriptors.
    */
    func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>(sortDescriptors: S) -> Results<Element>


    // MARK: Aggregate Operations

    /**
    Returns the minimum value of the given property.

    :warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    :param: property The name of a property conforming to `MinMaxType` to look for a minimum on.

    :returns: The minimum value for the property amongst objects in the collection, or `nil` if the collection is empty.
    */
    func min<U: MinMaxType>(property: String) -> U?

    /**
    Returns the maximum value of the given property.

    :warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    :param: property The name of a property conforming to `MinMaxType` to look for a maximum on.

    :returns: The maximum value for the property amongst objects in the collection, or `nil` if the collection is empty.
    */
    func max<U: MinMaxType>(property: String) -> U?

    /**
    Returns the sum of the given property for objects in the collection.

    :warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    :param: property The name of a property conforming to `AddableType` to calculate sum on.

    :returns: The sum of the given property over all objects in the collection.
    */
    func sum<U: AddableType>(property: String) -> U

    /**
    Returns the average of the given property for objects in the collection.

    :warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    :param: property The name of a property conforming to `AddableType` to calculate average on.

    :returns: The average of the given property over all objects in the collection, or `nil` if the collection is empty.
    */
    func average<U: AddableType>(property: String) -> U?
}
