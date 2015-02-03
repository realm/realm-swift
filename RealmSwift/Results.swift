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

// MARK: MinMaxType

/// Types which can be used for min()/max().
public protocol MinMaxType {}
extension Double: MinMaxType {}
extension Float: MinMaxType {}
extension Int16: MinMaxType {}
extension Int32: MinMaxType {}
extension Int64: MinMaxType {}
extension Int: MinMaxType {}
extension NSDate: MinMaxType {}

// MARK: AddableType

/// Types which can be used for average()/sum().
public protocol AddableType {}
extension Double: AddableType {}
extension Float: AddableType {}
extension Int16: AddableType {}
extension Int32: AddableType {}
extension Int64: AddableType {}
extension Int: AddableType {}

/**
`Results` is an auto-updating container type in Realm returned from object
queries.

Results can be queried with the same predicates as `List<T>` and you can chain queries to further
filter query results.

Results cannot be created directly.
*/
public final class Results<T: Object>: Printable, SequenceType {

    // MARK: Properties

    internal let rlmResults: RLMResults

    /// Returns the Realm these results are associated with.
    public var realm: Realm { return Realm(rlmRealm: rlmResults.realm) }

    /// Returns a human-readable description of the objects contained in these results.
    public var description: String { return rlmResults.description }

    /// Returns the number of objects in these results.
    public var count: Int { return Int(rlmResults.count) }

    // MARK: Initializers

    internal init(_ rlmResults: RLMResults) {
        self.rlmResults = rlmResults
    }

    // MARK: Index Retrieval

    /**
    Returns the index of the given object, or `nil` if the object is not in the results.

    :param: object The object whose index is being queried.

    :returns: The index of the given object, or `nil` if the object is not in the results.
    */
    public func indexOf(object: T) -> Int? {
        return notFoundToNil(rlmResults.indexOfObject(unsafeBitCast(object, RLMObject.self)))
    }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if the object is not in the results.

    :param: predicate The predicate to filter the objects.

    :returns: The index of the given object, or `nil` if the object is not in the results.
    */
    public func indexOf(predicate: NSPredicate) -> Int? {
        return notFoundToNil(rlmResults.indexOfObjectWithPredicate(predicate))
    }

    /**
    Returns the index of the first object matching the given predicate,
    or `nil` if the object is not in the results.

    :param: predicateFormat The predicate format string which can accept variable arguments.

    :returns: The index of the given object, or `nil` if the object is not in the results.
    */
    public func indexOf(predicateFormat: String, _ args: CVarArgType...) -> Int? {
        return notFoundToNil(rlmResults.indexOfObjectWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args))))
    }

    // MARK: Object Retrieval

    /**
    Returns the object at the given `index`.

    :param: index The index.

    :returns: The object at the given `index`.
    */
    public subscript(index: Int) -> T {
        get {
            return rlmResults[UInt(index)] as T
        }
    }

    /// Returns the first object in the results, or `nil` if empty.
    public var first: T? { return rlmResults.firstObject() as T? }

    /// Returns the last object in the results, or `nil` if empty.
    public var last: T? { return rlmResults.lastObject() as T? }

    // MARK: Filtering

    /**
    Filters the results to the objects that match the given predicate.

    :param: predicateFormat The predicate format string which can accept variable arguments.

    :returns: Results containing objects that match the given predicate.
    */
    public func filter(predicateFormat: String, _ args: CVarArgType...) -> Results<T> {
        return Results<T>(rlmResults.objectsWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args))))
    }

    /**
    Filters the results to the objects that match the given predicate.

    :param: predicate The predicate to filter the objects.

    :returns: Results containing objects that match the given predicate.
    */
    public func filter(predicate: NSPredicate) -> Results<T> {
        return Results<T>(rlmResults.objectsWithPredicate(predicate))
    }

    // MARK: Sorting

    /**
    Returns `Results` with elements sorted by the given property name.

    :param: property  The property name to sort by.
    :param: ascending The direction to sort by.

    :returns: `Results` with elements sorted by the given property name.
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
        return Results<T>(rlmResults.sortedResultsUsingDescriptors(map(sortDescriptors) { $0.rlmSortDescriptorValue }))
    }

    // MARK: Aggregate Operations

    /**
    Returns the minimum value of the given property.

    :warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    :param: property The name of a property conforming to `MinMaxType` to look for a minimum on.

    :returns: The minimum value for the property amongst objects in the Results, or `nil` if the Results is empty.
    */
    public func min<U: MinMaxType>(property: String) -> U? {
        return rlmResults.minOfProperty(property) as U?
    }

    /**
    Returns the maximum value of the given property.

    :warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

    :param: property The name of a property conforming to `MinMaxType` to look for a maximum on.

    :returns: The maximum value for the property amongst objects in the Results, or `nil` if the Results is empty.
    */
    public func max<U: MinMaxType>(property: String) -> U? {
        return rlmResults.maxOfProperty(property) as U?
    }

    /**
    Returns the sum of the given property for objects in the Results.

    :warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    :param: property The name of a property conforming to `AddableType` to calculate sum on.

    :returns: The sum of the given property over all objects in the Results.
    */
    public func sum<U: AddableType>(property: String) -> U {
        return rlmResults.sumOfProperty(property) as AnyObject as U
    }

    /**
    Returns the average of the given property for objects in the Results.

    :warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

    :param: property The name of a property conforming to `AddableType` to calculate average on.

    :returns: The average of the given property over all objects in the Results.
    */
    public func average<U: AddableType>(property: String) -> U {
        return rlmResults.averageOfProperty(property) as AnyObject as U
    }

    // MARK: Sequence Support

    /// Returns a `GeneratorOf<T>` that yields successive elements in the results.
    public func generate() -> GeneratorOf<T> {
        var i: UInt = 0
        return GeneratorOf<T>() {
            if (i >= self.rlmResults.count) {
                return .None
            } else {
                return self.rlmResults[i++] as? T
            }
        }
    }
}
