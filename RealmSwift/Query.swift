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

/// Enum representing an option for `String` queries.
public enum StringOptions {
    /// A case-insensitive search.
    case caseInsensitive
    /// Search ignores diacritic marks.
    case diacriticInsensitive
}

/**
 `Query` is a class used to create type-safe query predicates.

 With `Query` you are given the ability to create Swift style query expression that will then
 be constructed into an `NSPredicate`. The `Query` class should not be instantiated directly
 and should be only used as a paramater within a closure that takes a query expression as an argument.
 Example:
 ```swift
 public func where(_ query: ((Query<Element>) -> Query<Element>)) -> Results<Element>
 ```

 You would then use the above function like so:
 ```swift
 let results = realm.objects(Person.self).query {
    $0.name == "Foo" || $0.name == "Bar" && $0.age >= 21
 }
 ```

 ## Supported predicate types

 ### Prefix
 - NOT `!`
 ```swift
 let results = realm.objects(Person.self).query {
    !$0.dogsName.contains("Fido") || !$0.name.contains("Foo")
 }
 ```

 ### Comparisions
 - Equals `==`
 - Not Equals `!=`
 - Greater Than `>`
 - Less Than `<`
 - Greater Than or Equal `>=`
 - Less Than or Equal `<=`
 - Between `.contains(_ range:)`

 ### Collections
 - IN `.contains(_ element:)`
 - Between `.contains(_ range:)`
 - ANY ... IN `.containsAnyIn(_ collection:)`


 ### Map
 - @allKeys `.keys`
 - @allValues `.values`

 ### Compound
 - AND `&&`
 - OR `||`

 ### Collection Aggregation
 - @avg `.avg`
 - @min `.min`
 - @max `.max`
 - @sum `.sum`
 - @count `.count`
 ```swift
 let results = realm.objects(Person.self).query {
    !$0.dogs.age.avg >= 0 || !$0.dogsAgesArray.avg >= 0
 }
 ```

 ### Other
 - NOT `!`
 - Subquery `($0.fooList.intCol >= 5).count > n`

 */
@dynamicMemberLookup
public struct Query<T: _RealmSchemaDiscoverable> {

    private var context: QueryContext


    /// Initializes a `Query` object.
    /// - Parameter isPrimitive: States is the query is on 'self' and will have no key path context.
    public init(isPrimitive: Bool = false) {
        self.context = QueryContext(isPrimitive: isPrimitive)
    }

    fileprivate init(context: QueryContext) {
        self.context = context
    }

    private func appendKeyPath(_ keyPath: String) -> NSExpression {
        if let node = context.node as? ComparisonNode, let left = node.left, left.expressionType == .keyPath {
            return NSExpression(forKeyPath: "\(left.keyPath).\(keyPath)")
        }
        return NSExpression(forKeyPath: keyPath)
    }

    private func appendKeyPathCollectionAggregate(_ aggregate: String) -> NSExpression {
        guard let node = context.node as? ComparisonNode, let left = node.left, left.expressionType == .keyPath else {
            throwRealmException("Could not construct predicate. Lhs must be a key path.")
        }
        var parts = left.keyPath.components(separatedBy: ".")
        parts.insert(aggregate, at: parts.index(after: 0))
        return NSExpression(forKeyPath: parts.joined(separator: "."))
    }

    private func applyCompound<V>(lhs: QueryNode,
                                  rhs: QueryNode,
                                  op: NSCompoundPredicate.LogicalType,
                                  subqueryCount: Int? = nil) -> Query<V> {
        var node = CompoundNode()
        node.left = lhs
        node.right = rhs
        node.compoundOperator = op
        var copy = context
        copy.node = node
        if let subqueryCount = subqueryCount {
            copy.subqueryCount = subqueryCount
        }
        return Query<V>(context: copy)
    }

    private func apply<V>(lhs: NSExpression) -> Query<V> {
        if var compoundNode = context.node as? CompoundNode,
           compoundNode.isMapSubscriptQuery,
           var rightNode = compoundNode.right as? ComparisonNode,
           rightNode.left?.expressionType == .keyPath,
           let left = rightNode.left {
            rightNode.left = .init(forKeyPath: "\(left.keyPath).\(lhs.keyPath)")
            compoundNode.right = rightNode
            var copy = context
            copy.node = compoundNode
            return Query<V>(context: copy)
        } else {
            var node = ComparisonNode()
            node.left = lhs
            var copy = context
            copy.node = node
            return Query<V>(context: copy)
        }
    }

    private func apply<V>(comparison: NSComparisonPredicate.Operator,
                          rhs: NSExpression,
                          stringOptions: Set<StringOptions>? = nil,
                          isCollectionContains: Bool = false,
                          modifier: NSComparisonPredicate.Modifier? = nil) -> Query<V> {
        if var subqueryNode = context.node as? SubqueryNode {
            guard var rightNode = subqueryNode.right as? ComparisonNode else {
                throwRealmException("Could not construct SUBQUERY. Right node is missing.")
            }
            rightNode.comparisonOperator = comparison
            rightNode.right = rhs
            rightNode.stringOptions = stringOptions
            subqueryNode.right = rightNode
            var contextCopy = context
            contextCopy.node = subqueryNode
            return Query<V>(context: contextCopy)
        } else if var comparisonNode = context.node as? ComparisonNode {
            comparisonNode.comparisonOperator = comparison
            comparisonNode.right = rhs
            comparisonNode.stringOptions = stringOptions
            comparisonNode.isCollectionContains = isCollectionContains
            comparisonNode.modifier = modifier
            var contextCopy = context
            contextCopy.node = comparisonNode
            return Query<V>(context: contextCopy)
        } else if var compoundNode = context.node as? CompoundNode,
                  var rightNode = compoundNode.right as? ComparisonNode {
            /// We should only enter this path when doing a query
            /// on a `Map` with a key subscript and checking if that
            /// `Map` contains a value.
            rightNode.comparisonOperator = comparison
            rightNode.right = rhs
            rightNode.stringOptions = stringOptions
            compoundNode.right = rightNode
            var contextCopy = context
            contextCopy.node = compoundNode
            return Query<V>(context: contextCopy)
        } else {
            throwRealmException("Could not construct query. Node must be a ComparisonNode.")
        }
    }

    private func appendSubquery<V>() -> Query<V> {
        var count = context.subqueryCount
        var node = SubqueryNode(count)
        node.left = context.node
        node.right = ComparisonNode(left: .init(forKeyPath: ".@count"))
        count += 1
        return Query<V>(context: QueryContext(isPrimitive: context.isPrimitive,
                                              node: node,
                                              subqueryCount: count))
    }

    // MARK: Prefix

    /// :nodoc:
    public static prefix func ! (_ query: Query) -> Query {
        var contextCopy = query.context
        contextCopy.node.requiresNotPrefix = true
        return Query(context: contextCopy)
    }

    // MARK: Comparable

    /// :nodoc:
    public static func == <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _RealmSchemaDiscoverable {
        return lhs.apply(comparison: .equalTo, rhs: .init(forConstantValue: rhs))
    }
    /// :nodoc:
    public static func != <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _RealmSchemaDiscoverable {
        return lhs.apply(comparison: .notEqualTo, rhs: .init(forConstantValue: rhs))
    }

    // MARK: Numerics

    /// :nodoc:
    public static func > <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        return lhs.apply(comparison: .greaterThan, rhs: .init(forConstantValue: rhs))
    }
    /// :nodoc:
    public static func >= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        return lhs.apply(comparison: .greaterThanOrEqualTo, rhs: .init(forConstantValue: rhs))
    }
    /// :nodoc:
    public static func < <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        return lhs.apply(comparison: .lessThan, rhs: .init(forConstantValue: rhs))

    }
    /// :nodoc:
    public static func <= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        return lhs.apply(comparison: .lessThanOrEqualTo, rhs: .init(forConstantValue: rhs))
    }

    // MARK: Compound

    /// :nodoc:
    public static func && (_ lhs: Query, _ rhs: Query) -> Query {
        return lhs.applyCompound(lhs: lhs.context.node,
                                 rhs: rhs.context.node,
                                 op: .and,
                                 subqueryCount: rhs.context.subqueryCount)
    }
    /// :nodoc:
    public static func || (_ lhs: Query, _ rhs: Query) -> Query {
        return lhs.applyCompound(lhs: lhs.context.node,
                                 rhs: rhs.context.node,
                                 op: .or,
                                 subqueryCount: rhs.context.subqueryCount)
    }

    // MARK: Subscript

    /// :nodoc:
    public subscript<V>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        let name = _name(for: member)
        return apply(lhs: appendKeyPath(name))
    }
    /// :nodoc:
    public subscript<V: RealmCollectionBase>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        let name = _name(for: member)
        return apply(lhs: appendKeyPath(name))
    }

    // MARK: Query Construction

    /// Creates an NSPredicate compatibe string.
    /// - Parameter isSubquery: States if expression need to be arraged in a special way to cater to subqueries.
    /// - Returns: A tuple containing the predicate string and an array of arguments.

    public func _constructPredicate(_ isSubquery: Bool = false) -> _PredicateData {
        return context.node.makePredicate(nil)
    }

    internal var predicate: NSPredicate {
        let predicate = _constructPredicate()
        return NSPredicate(format: predicate.string, argumentArray: predicate.args)
    }

    private func aggregateContains<U: _QueryNumeric, V>(_ lowerBound: U,
                                                        _ upperBound: U,
                                                        isClosedRange: Bool=false) -> Query<V> {
        guard let node = context.node as? ComparisonNode, node.left?.expressionType == .keyPath else {
            throwRealmException("Could not construct aggregate query, key path is missing.")
        }

        let leftNode = ComparisonNode(left: appendKeyPath("@min"),
                                      right: .init(forConstantValue: lowerBound),
                                      requiresNotPrefix: false,
                                      comparisonOperator: .greaterThanOrEqualTo)
        let rightNode = ComparisonNode(left: appendKeyPath("@max"),
                                       right: .init(forConstantValue: upperBound),
                                       requiresNotPrefix: false,
                                       comparisonOperator: isClosedRange ? .lessThanOrEqualTo : .lessThan)
        let compoundNode = CompoundNode(left: leftNode,
                                        right: rightNode,
                                        requiresNotPrefix: node.requiresNotPrefix,
                                        compoundOperator: .and)

        var contextCopy = context
        contextCopy.node = compoundNode
        return Query<V>(context: contextCopy)
    }

    private func doContainsAny<U: Sequence, V>(in collection: U) -> Query<V> {
        return apply(comparison: .in, rhs: .init(forConstantValue: collection.map(dynamicBridgeCast)), modifier: .any)
    }
}

// MARK: OptionalProtocol

extension Query where T: OptionalProtocol {
    /// :nodoc:
    public subscript<V>(dynamicMember member: KeyPath<T.Wrapped, V>) -> Query<V> where T.Wrapped: ObjectBase {
        let name = _name(for: member)
        return apply(lhs: appendKeyPath(name))
    }
}

// MARK: RealmCollection

extension Query where T: RealmCollection {
    /// :nodoc:
    public subscript<V>(dynamicMember member: KeyPath<T.Element, V>) -> Query<V> where T.Element: ObjectBase {
        let name = _name(for: member)
        return apply(lhs: appendKeyPath(name))
    }

    /// Query the count of the objects in the collection.
    public var count: Query<Int> {
        return apply(lhs: appendKeyPath("@count"))
    }
}

extension Query where T: RealmCollection {
    /// Checks if an element exists in this collection.
    public func contains<V>(_ value: T.Element) -> Query<V> {
        return apply(comparison: .in,
                     rhs: .init(forConstantValue: value),
                     stringOptions: nil,
                     isCollectionContains: true)
    }

    /// Checks if any elements contained in the given array are present in the collection.
    public func containsAny<U: Sequence, V>(in collection: U) -> Query<V> where U.Element == T.Element {
        return doContainsAny(in: collection)
    }
}

extension Query where T: RealmCollection, T.Element: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Element>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound)
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Element>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound, isClosedRange: true)
    }
}

extension Query where T: RealmCollection, T.Element: OptionalProtocol, T.Element.Wrapped: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Element.Wrapped>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound)
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Element.Wrapped>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound, isClosedRange: true)
    }
}

extension Query where T: RealmCollection, T.Element: _QueryNumeric {
    /// :nodoc:
    public static func == <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        return lhs.apply(comparison: .equalTo, rhs: .init(forConstantValue: rhs))
    }

    /// :nodoc:
    public static func != <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        return lhs.apply(comparison: .notEqualTo, rhs: .init(forConstantValue: rhs))
    }

    /// :nodoc:
    public static func > <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        return lhs.apply(comparison: .greaterThan, rhs: .init(forConstantValue: rhs))
    }

    /// :nodoc:
    public static func >= <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        return lhs.apply(comparison: .greaterThanOrEqualTo, rhs: .init(forConstantValue: rhs))
    }

    /// :nodoc:
    public static func < <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        return lhs.apply(comparison: .lessThan, rhs: .init(forConstantValue: rhs))
    }

    /// :nodoc:
    public static func <= <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        return lhs.apply(comparison: .lessThanOrEqualTo, rhs: .init(forConstantValue: rhs))
    }
}

extension Query where T: RealmCollection,
                      T.Element: _QueryNumeric {
    /// Returns the minimum value in the collection.
    public var min: Query {
        return apply(lhs: appendKeyPath("@min"))
    }

    /// Returns the maximum value in the collection.
    public var max: Query {
        return apply(lhs: appendKeyPath("@max"))
    }

    /// Returns the average in the collection.
    public var avg: Query {
        return apply(lhs: appendKeyPath("@avg"))
    }

    /// Returns the sum of all the values in the collection.
    public var sum: Query {
        return apply(lhs: appendKeyPath("@sum"))
    }
}

// MARK: RealmKeyedCollection

extension Query where T: RealmKeyedCollection {
    private func memberSubscript<U>(_ member: T.Key) -> Query<U> where T.Key: _RealmSchemaDiscoverable {
        guard let node = context.node as? ComparisonNode, node.left?.expressionType == .keyPath else {
            throwRealmException("Could not contruct predicate for Map. Key path is missing.")
        }

        let left = ComparisonNode(left: appendKeyPath("@allKeys"),
                                  right: .init(forConstantValue: member),
                                  comparisonOperator: .equalTo)
        let right = ComparisonNode(left: node.left,
                                   requiresNotPrefix: node.requiresNotPrefix)

        let compound = CompoundNode(left: left,
                                    right: right,
                                    compoundOperator: .and,
                                    isMapSubscriptQuery: true)
        var contextCopy = context
        contextCopy.node = compound
        return Query<U>(context: contextCopy)
    }

    /// Checks if any elements contained in the given array are present in the map's values.
    public func containsAny<U: Sequence, V>(in collection: U) -> Query<V> where U.Element == T.Value {
        return doContainsAny(in: collection)
    }
}

extension Query where T: RealmKeyedCollection, T.Key: _RealmSchemaDiscoverable {
    /// Checks if an element exists in this collection.
    public func contains<V>(_ value: T.Value) -> Query<V> {
        return apply(comparison: .in,
                     rhs: .init(forConstantValue: value),
                     isCollectionContains: true)
    }
    /// Allows a query over all values in the Map.
    public var values: Query<T.Value> {
        return apply(lhs: appendKeyPath("@allValues"))
    }
    /// :nodoc:
    public subscript(member: T.Key) -> Query<T.Value> {
        return memberSubscript(member)
    }
}

extension Query where T: RealmKeyedCollection, T.Key: _RealmSchemaDiscoverable, T.Value: OptionalProtocol, T.Value.Wrapped: _RealmSchemaDiscoverable {
    /// Allows a query over all values in the Map.
    public var values: Query<T.Value.Wrapped> {
        return apply(lhs: appendKeyPath("@allValues"))
    }
    /// :nodoc:
    public subscript(member: T.Key) -> Query<T.Value.Wrapped> {
        return memberSubscript(member)
    }
    /// :nodoc:
    public subscript(member: T.Key) -> Query<T.Value> where T.Value.Wrapped: ObjectBase {
        return memberSubscript(member)
    }
}

extension Query where T: RealmKeyedCollection, T.Key == String {
    /// Allows a query over all keys in the `Map`.
    public var keys: Query<String> {
        return apply(lhs: appendKeyPath("@allKeys"))
    }
}

extension Query where T: RealmKeyedCollection, T.Value: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Value>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound)
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Value>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound, isClosedRange: true)
    }
}

extension Query where T: RealmKeyedCollection, T.Value: OptionalProtocol, T.Value.Wrapped: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Value.Wrapped>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound)
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Value.Wrapped>) -> Query<V> {
        return aggregateContains(range.lowerBound, range.upperBound, isClosedRange: true)
    }
}

extension Query where T: RealmKeyedCollection,
                      T.Key: _RealmSchemaDiscoverable,
                      T.Value: _QueryNumeric {
    /// Returns the minimum value in the keyed collection.
    public var min: Query<T.Value> {
        return apply(lhs: appendKeyPath("@min"))
    }

    /// Returns the maximum value in the keyed collection.
    public var max: Query<T.Value> {
        return apply(lhs: appendKeyPath("@max"))
    }

    /// Returns the average in the keyed collection.
    public var avg: Query<T.Value> {
        return apply(lhs: appendKeyPath("@avg"))
    }

    /// Returns the sum of all the values in the keyed collection.
    public var sum: Query<T.Value> {
        return apply(lhs: appendKeyPath("@sum"))
    }

    /// Returns the count of all the values in the keyed collection.
    public var count: Query<T.Value> {
        return apply(lhs: appendKeyPath("@count"))
    }
}

// MARK: PersistableEnum

extension Query where T: PersistableEnum, T.RawValue: _RealmSchemaDiscoverable {
    /// :nodoc:
    public static func == <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        lhs.apply(comparison: .equalTo, rhs: .init(forConstantValue: rhs.rawValue))
    }
    /// :nodoc:
    public static func != <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        lhs.apply(comparison: .notEqualTo, rhs: .init(forConstantValue: rhs.rawValue))
    }
    /// :nodoc:
    public static func > <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        lhs.apply(comparison: .greaterThan, rhs: .init(forConstantValue: rhs.rawValue))
    }
    /// :nodoc:
    public static func >= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        lhs.apply(comparison: .greaterThanOrEqualTo, rhs: .init(forConstantValue: rhs.rawValue))
    }
    /// :nodoc:
    public static func < <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        lhs.apply(comparison: .lessThan, rhs: .init(forConstantValue: rhs.rawValue))
    }
    /// :nodoc:
    public static func <= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        lhs.apply(comparison: .lessThanOrEqualTo, rhs: .init(forConstantValue: rhs.rawValue))
    }
}

extension Query where T: PersistableEnum,
                      T.RawValue: _QueryNumeric {
    /// Returns the minimum value in the collection based on the keypath.
    public var min: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@min"))
    }

    /// Returns the maximum value in the collection based on the keypath.
    public var max: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@max"))
    }

    /// Returns the average in the collection based on the keypath.
    public var avg: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@avg"))
    }

    /// Returns the sum of all the values in the collection based on the keypath.
    public var sum: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@sum"))
    }

    /// Returns the count of all the values in the collection based on the keypath.
    public var count: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@count"))
    }
}

// MARK: Optional

extension Query where T: OptionalProtocol,
                      T.Wrapped: PersistableEnum,
                      T.Wrapped.RawValue: _RealmSchemaDiscoverable {

    private func appendOptionalEnum<V>(comparison: NSComparisonPredicate.Operator,
                                       rhs: T) -> Query<V> {
        if case Optional<Any>.none = rhs as Any {
            return apply(comparison: comparison, rhs: .init(forConstantValue: nil))
        } else {
            return apply(comparison: comparison, rhs: .init(forConstantValue: rhs._rlmInferWrappedType().rawValue))
        }
    }
    /// :nodoc:
    public static func == <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        lhs.appendOptionalEnum(comparison: .equalTo, rhs: rhs)
    }
    /// :nodoc:
    public static func != <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        lhs.appendOptionalEnum(comparison: .notEqualTo, rhs: rhs)
    }
}

extension Query where T: OptionalProtocol, T.Wrapped: PersistableEnum, T.Wrapped.RawValue: _QueryNumeric {
    /// :nodoc:
    public static func > <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        lhs.appendOptionalEnum(comparison: .greaterThan, rhs: rhs)
    }
    /// :nodoc:
    public static func >= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        lhs.appendOptionalEnum(comparison: .greaterThanOrEqualTo, rhs: rhs)
    }
    /// :nodoc:
    public static func < <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        lhs.appendOptionalEnum(comparison: .lessThan, rhs: rhs)
    }
    /// :nodoc:
    public static func <= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        lhs.appendOptionalEnum(comparison: .lessThanOrEqualTo, rhs: rhs)
    }
}

extension Query where T: OptionalProtocol,
                      T.Wrapped: PersistableEnum,
                      T.Wrapped.RawValue: _QueryNumeric {
    /// Returns the minimum value in the collection based on the keypath.
    public var min: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@min"))
    }

    /// Returns the maximum value in the collection based on the keypath.
    public var max: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@max"))
    }

    /// Returns the average in the collection based on the keypath.
    public var avg: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@avg"))
    }

    /// Returns the sum of all the value in the collection based on the keypath.
    public var sum: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@sum"))
    }
}

// MARK: _QueryNumeric

extension Query where T: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T>) -> Query<V> {
        let leftNode: Query<V> = apply(comparison: .greaterThanOrEqualTo,
                                       rhs: .init(forConstantValue: range.lowerBound))
        let rightNode: Query<V> = apply(comparison: .lessThan,
                                        rhs: .init(forConstantValue: range.upperBound))
        return applyCompound(lhs: leftNode.context.node,
                             rhs: rightNode.context.node,
                             op: .and,
                             subqueryCount: context.subqueryCount)
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T>) -> Query<V> {
        let args = [dynamicBridgeCast(fromSwift: range.lowerBound),
                    dynamicBridgeCast(fromSwift: range.upperBound)]
        return apply(comparison: .between,
                     rhs: .init(format: "{%@, %@}", argumentArray: args))
    }
}

// MARK: _QueryString

extension Query where T: _QueryString {
    /**
     Checks for all elements in this collection that equal the given value.
     `?` and `*` are allowed as wildcard characters, where `?` matches 1 character and `*` matches 0 or more characters.
     - parameter value: value used.
     - parameter caseInsensitive: `true` if it is a case-insensitive search.
     */
    public func like<V>(_ value: T, caseInsensitive: Bool = false) -> Query<V> {
        return apply(comparison: .like, rhs: .init(forConstantValue: value),
                     stringOptions: caseInsensitive ? [.caseInsensitive] : nil)
    }
}

// MARK: _QueryBinary

extension Query where T: _QueryBinary {
    /**
     Checks for all elements in this collection that contains the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the Search query.
     */
    public func contains<V>(_ value: T, options: Set<StringOptions>? = nil) -> Query<V> {
        return apply(comparison: .contains, rhs: .init(forConstantValue: value),
                     stringOptions: options)
    }

    /**
     Checks for all elements in this collection that starts with the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the Search query.
     */
    public func starts<V>(with value: T, options: Set<StringOptions>? = nil) -> Query<V> {
        return apply(comparison: .beginsWith, rhs: .init(forConstantValue: value),
                     stringOptions: options)
    }

    /**
     Checks for all elements in this collection that ends with the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the Search query.
     */
    public func ends<V>(with value: T, options: Set<StringOptions>? = nil) -> Query<V> {
        return apply(comparison: .endsWith, rhs: .init(forConstantValue: value),
                     stringOptions: options)
    }

    /**
     Checks for all elements in this collection that equals the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the Search query.
     */
    public func equals<V>(_ value: T, options: Set<StringOptions>? = nil) -> Query<V> {
        return apply(comparison: .equalTo, rhs: .init(forConstantValue: value),
                     stringOptions: options)
    }

    /**
     Checks for all elements in this collection that are not equal to the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the Search query.
     */
    public func notEquals<V>(_ value: T, options: Set<StringOptions>? = nil) -> Query<V> {
        return apply(comparison: .notEqualTo, rhs: .init(forConstantValue: value),
                     stringOptions: options)
    }
}

extension Query where T: OptionalProtocol, T.Wrapped: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Wrapped>) -> Query<V> {
        let leftNode: Query<V> = apply(comparison: .greaterThanOrEqualTo,
                                       rhs: .init(forConstantValue: range.lowerBound))
        let rightNode: Query<V> = apply(comparison: .lessThan,
                                        rhs: .init(forConstantValue: range.upperBound))
        return applyCompound(lhs: leftNode.context.node,
                             rhs: rightNode.context.node,
                             op: .and,
                             subqueryCount: context.subqueryCount)
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Wrapped>) -> Query<V> {
        let args = [dynamicBridgeCast(fromSwift: range.lowerBound),
                    dynamicBridgeCast(fromSwift: range.upperBound)]
        return apply(comparison: .between,
                     rhs: .init(format: "{%@, %@}", argumentArray: args))
    }
}

// MARK: Subquery

extension Query where T == Bool {
    /// Completes a subquery expression.
    /// ```
    /// ($0.myCollection.age >= 21).count > 0
    /// ```
    public var count: Query<Int> {
        return appendSubquery()
    }
}

// MARK: Keypath Collection Aggregates

/**
 You can use only use aggregates in numeric types as a keypath on a collection.
 ```swift
 let results = realm.objects(Person.self).query {
 !$0.dogs.age.avg >= 0
 }
 ```
 Where `dogs` is an array of objects.
 */
extension Query where T: _QueryNumeric {
    /// Returns the minimum value of the objects in the collection based on the keypath.
    public var min: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@min"))
    }

    /// Returns the maximum value of the objects in the collection based on the keypath.
    public var max: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@max"))
    }

    /// Returns the average of the objects in the collection based on the keypath.
    public var avg: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@avg"))
    }

    /// Returns the sum of the objects in the collection based on the keypath.
    public var sum: Query {
        return apply(lhs: appendKeyPathCollectionAggregate("@sum"))
    }
}

/// Tag protocol for all numeric types.
public protocol _QueryNumeric: _RealmSchemaDiscoverable { }
extension Int: _QueryNumeric { }
extension Int8: _QueryNumeric { }
extension Int16: _QueryNumeric { }
extension Int32: _QueryNumeric { }
extension Int64: _QueryNumeric { }
extension Float: _QueryNumeric { }
extension Double: _QueryNumeric { }
extension Decimal128: _QueryNumeric { }
extension Date: _QueryNumeric { }
extension AnyRealmValue: _QueryNumeric { }
extension Optional: _QueryNumeric where Wrapped: _QueryNumeric { }

/// Tag protocol for all types that are compatible with `String`.
public protocol _QueryString: _QueryBinary { }
extension String: _QueryString { }
extension Optional: _QueryString where Wrapped: _QueryString { }

/// Tag protocol for all types that are compatible with `Binary`.
public protocol _QueryBinary { }
extension Data: _QueryBinary { }
extension Optional: _QueryBinary where Wrapped: _QueryBinary { }

/// A type for boxing the required data used for constructing an NSPredicate.
public struct _PredicateData {
    /// The format string of the NSPredicate.
    public var string: String
    /// The arguments of the NSPredicate.
    public var args: [Any]
    ///  Used for storing the name of the collection if this predicate is a subquery.
    internal var collectionName: String?

    internal init(string: String, args: [Any], collectionName: String? = nil) {
        self.string = string
        self.args = args
        self.collectionName = collectionName
    }

    mutating func applyOpeningParenthesis() {
        string.insert("(", at: string.startIndex)
    }

    mutating func applyClosingParenthesis() {
        string.append(")")
    }

    mutating func applyNotPrefix() {
        string.insert(contentsOf: "NOT ", at: string.startIndex)
    }

    internal static func + (lhs: _PredicateData, rhs: _PredicateData) -> _PredicateData {
        let collectionName = lhs.collectionName != nil ? lhs.collectionName : rhs.collectionName
        let seperator = lhs.string.isEmpty ? "" : " "
        return _PredicateData(string: lhs.string + seperator + rhs.string,
                              args: lhs.args + rhs.args,
                              collectionName: collectionName)
    }
}

private protocol QueryNode {
    var requiresNotPrefix: Bool { get set }
    func makePredicate(_ subqueryName: String?) -> _PredicateData
}

extension QueryNode {
    func subqueryKeyPath(_ keyPath: String, colName: String) -> (keyPath: String, collectionName: String) {
        var keyPaths = keyPath.components(separatedBy: ".")
        let collectionName = keyPaths.removeFirst()
        keyPaths.insert(colName, at: 0)
        return (keyPath: keyPaths.joined(separator: "."), collectionName: collectionName)
    }
}

private struct SubqueryNode: QueryNode {
    var left: QueryNode?
    var right: QueryNode?
    var subqueryCount: Int
    var requiresNotPrefix: Bool = false

    init(_ count: Int) {
        self.subqueryCount = count
    }

    func makePredicate(_ subqueryName: String?) -> _PredicateData {
        var leftPredicate: _PredicateData!
        var rightPredicate: _PredicateData!

        let col = "$col\(subqueryCount)"
        if let left = left {
            leftPredicate = left.makePredicate(col)
        }

        if let right = right {
            rightPredicate = right.makePredicate(nil)
        }

        guard let collectionName = leftPredicate.collectionName else {
            throwRealmException("Could not construct SUBQUERY predicate.")
        }

        let format = "SUBQUERY(\(collectionName), \(col), \(leftPredicate.string))" + rightPredicate.string
        return _PredicateData(string: format, args: leftPredicate.args + rightPredicate.args)
    }
}

private struct CompoundNode: QueryNode {
    var left: QueryNode?
    var right: QueryNode?
    var requiresNotPrefix: Bool = false
    var compoundOperator: NSCompoundPredicate.LogicalType?
    var isMapSubscriptQuery: Bool = false

    func makePredicate(_ subqueryName: String?) -> _PredicateData {
        var predicates: [_PredicateData] = []

        if requiresNotPrefix && !isMapSubscriptQuery {
            predicates.append(_PredicateData(string: "NOT", args: []))
        }

        if let leftLeaf = left {
            var predicate = leftLeaf.makePredicate(subqueryName)
            predicate.applyOpeningParenthesis()
            predicates.append(predicate)
        }

        if let op = compoundOperator {
            switch op {
                case .and:
                    predicates.append(_PredicateData(string: "&&", args: []))
                case .or:
                    predicates.append(_PredicateData(string: "||", args: []))
                default:
                    throwRealmException("Could not construct predicate. Unsupported compound operator present.")
            }
        }

        if let rightLeft = right {
            var predicate = rightLeft.makePredicate(subqueryName)
            if requiresNotPrefix && isMapSubscriptQuery {
                predicate.applyNotPrefix()
            }
            predicate.applyClosingParenthesis()
            predicates.append(predicate)
        }

        return predicates.reduce(_PredicateData(string: "", args: []), +)
    }
}

private struct ComparisonNode: QueryNode {
    /// The lhs of this predicate expression.
    var left: NSExpression?
    /// The rhs of this predicate expression.
    var right: NSExpression?
    /// A flag used to insert a `NOT` prefix to the format string.
    var requiresNotPrefix: Bool = false
    /// The comparison operator this node wants to perform.
    var comparisonOperator: NSComparisonPredicate.Operator?
    /// An options set for string / binary queries.
    var stringOptions: Set<StringOptions>?
    /// A flag to help identify an `"%@ IN myCol"` type predicate.
    var isCollectionContains: Bool = false
    /// Modifier for this node. This is only used to prefix `ANY` to an expression.
    var modifier: NSComparisonPredicate.Modifier? = nil

    func makePredicate(_ subqueryName: String?) -> _PredicateData {
        guard let left = left, let comparisonOperator = comparisonOperator, let right = right else {
            throwRealmException("Could not construct predicate. Node is missing a lhs, rhs or comparisonOperator.")
        }

        func buildLeft() -> _PredicateData {
            switch left.expressionType {
                case .keyPath:
                    if let subqueryName = subqueryName {
                        let subqueryKeyPath = subqueryKeyPath(left.keyPath, colName: subqueryName)
                        return _PredicateData(string: subqueryKeyPath.keyPath,
                                              args: [],
                                              collectionName: subqueryKeyPath.collectionName)
                    } else {
                        return _PredicateData(string: left.keyPath, args: [])
                    }
                default:
                    throwRealmException("Could not construct predicate. Unsupported expression type.")
            }
        }

        func buildComparison() -> _PredicateData {
            var formatString = ""
            switch comparisonOperator {
                case .equalTo:
                    formatString += "=="
                case .notEqualTo:
                    formatString += "!="
                case .greaterThan:
                    formatString += ">"
                case .greaterThanOrEqualTo:
                    formatString += ">="
                case .lessThan:
                    formatString += "<"
                case .lessThanOrEqualTo:
                    formatString += "<="
                case .between:
                    formatString += "BETWEEN"
                case .like:
                    formatString += "LIKE"
                case .beginsWith:
                    formatString += "BEGINSWITH"
                case .endsWith:
                    formatString += "ENDSWITH"
                case .contains:
                    formatString += "CONTAINS"
                case .in:
                    formatString += "IN"
                default:
                    throwRealmException("Could not create predicate. Unsupported predicate operator.")
            }

            if let stringOptions = stringOptions, !stringOptions.isEmpty {
                formatString += "["

                if stringOptions.contains(.caseInsensitive) {
                    formatString += "c"
                }

                if stringOptions.contains(.diacriticInsensitive) {
                    formatString += "d"
                }

                formatString += "]"
            }

            return _PredicateData(string: formatString, args: [])
        }

        func buildRight() -> _PredicateData {
            switch right.expressionType {
                case .constantValue:
                    return _PredicateData(string: "%@",
                                          args: [right.constantValue.objCValue])
                case .aggregate:
                    guard let arguments = right.collection as? [NSExpression] else {
                        throwRealmException("Could not construct predicate. Invalid collection argument.")
                    }
                    return _PredicateData(string: "{%@, %@}",
                                          args: arguments.map { $0.constantValue.objCValue })
                default:
                    throwRealmException("Could not construct predicate. Unsupported expression type.")
            }
        }

        func buildPrefix() -> _PredicateData {
            var strs: [String] = []

            if requiresNotPrefix {
                strs.append("NOT")
            }

            if let modifier = modifier, modifier == .any {
                strs.append("ANY")
            }

            return _PredicateData(string: strs.joined(separator: " "), args: [])
        }

        if isCollectionContains {
            // An `IN` query for checking if an element exists in an array
            // requires that the rhs be placed on the lhs of the expression.
            return buildPrefix() + buildRight() + buildComparison() + buildLeft()
        } else {
            return buildPrefix() + buildLeft() + buildComparison() + buildRight()
        }
    }
}

private struct QueryContext {
    var node: QueryNode = ComparisonNode()
    // Helps give Subquery collection vars a unique name.
    var subqueryCount = 0
    // Indicates if the query builder should use 'self' as the keypath.
    var isPrimitive = false

    init(isPrimitive: Bool, node: QueryNode, subqueryCount: Int) {
        self.isPrimitive = isPrimitive
        self.node = node
        self.subqueryCount = subqueryCount
    }

    init(isPrimitive: Bool) {
        self.isPrimitive = isPrimitive
        if isPrimitive {
            node = ComparisonNode(left: .init(forKeyPath: "SELF"))
        }
    }
}
