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
 Types of properties which can be used with the minimum and maximum value APIs.

 - see: `min(ofProperty:)`, `max(ofProperty:)`
 */
@_marker public protocol MinMaxType {}
extension NSNumber: MinMaxType {}
extension Double: MinMaxType {}
extension Float: MinMaxType {}
extension Int: MinMaxType {}
extension Int8: MinMaxType {}
extension Int16: MinMaxType {}
extension Int32: MinMaxType {}
extension Int64: MinMaxType {}
extension Date: MinMaxType {}
extension NSDate: MinMaxType {}
extension Decimal128: MinMaxType {}
extension AnyRealmValue: MinMaxType {}
extension Optional: MinMaxType where Wrapped: MinMaxType {}

// MARK: AddableType

/**
 Types of properties which can be used with the sum and average value APIs.

 - see: `sum(ofProperty:)`, `average(ofProperty:)`
 */
@_marker public protocol AddableType {}
extension NSNumber: AddableType {}
extension Double: AddableType {}
extension Float: AddableType {}
extension Int: AddableType {}
extension Int8: AddableType {}
extension Int16: AddableType {}
extension Int32: AddableType {}
extension Int64: AddableType {}
extension Decimal128: AddableType {}
extension AnyRealmValue: AddableType {}
extension Optional: AddableType where Wrapped: AddableType {}

/**
 Types of properties which can be directly sorted or distincted.

 - see: `sum(ascending:)`, `distinct()`
 */
@_marker public protocol SortableType {}
extension AnyRealmValue: SortableType {}
extension Data: SortableType {}
extension Date: SortableType {}
extension Decimal128: SortableType {}
extension Double: SortableType {}
extension Float: SortableType {}
extension Int16: SortableType {}
extension Int32: SortableType {}
extension Int64: SortableType {}
extension Int8: SortableType {}
extension Int: SortableType {}
extension String: SortableType {}
extension Optional: SortableType where Wrapped: SortableType {}


/**
 Types which have properties that can be sorted or distincted on.
 */
@_marker public protocol KeypathSortable {}
extension ObjectBase: KeypathSortable {}
extension Projection: KeypathSortable {}

/**
 `Results` is an auto-updating container type in Realm returned from object queries.

 `Results` can be queried with the same predicates as `List<Element>`, and you can
 chain queries to further filter query results.

 `Results` always reflect the current state of the Realm on the current thread, including during write transactions on
 the current thread. The one exception to this is when using `for...in` enumeration, which will always enumerate over
 the objects which matched the query when the enumeration is begun, even if some of them are deleted or modified to be
 excluded by the filter during the enumeration.

 `Results` are lazily evaluated the first time they are accessed; they only run queries when the result of the query is
 requested. This means that chaining several temporary `Results` to sort and filter your data does not perform any
 unnecessary work processing the intermediate state.

 Once the results have been evaluated or a notification block has been added, the results are eagerly kept up-to-date,
 with the work done to keep them up-to-date done on a background thread whenever possible.

 Results instances cannot be directly instantiated.
 */
@frozen public struct Results<Element: RealmCollectionValue>: Equatable, RealmCollectionImpl {
    internal let collection: RLMCollection

    /// A human-readable description of the objects represented by the results.
    public var description: String {
        return RLMDescriptionWithMaxDepth("Results", collection, RLMDescriptionMaxDepth)
    }

    // MARK: Initializers

    internal init(collection: RLMCollection) {
        self.collection = collection
    }
    internal init(_ collection: RLMCollection) {
        self.collection = collection
    }

    // MARK: Object Retrieval
    /**
     Returns the object at the given `index`.
     - parameter index: The index.
     */
    public subscript(position: Int) -> Element {
        throwForNegativeIndex(position)
        return staticBridgeCast(fromObjectiveC: collection.object(at: UInt(position)))
    }

    // MARK: Equatable

    public static func == (lhs: Results<Element>, rhs: Results<Element>) -> Bool {
        lhs.collection.isEqual(rhs.collection)
    }

    /// :nodoc:
    public func makeIterator() -> RLMIterator<Element> {
        return RLMIterator(collection: collection)
    }

}

extension Results: Encodable where Element: Encodable {}
