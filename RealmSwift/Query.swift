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

/// Enum representing an option for `String` queries.
public struct StringOptions: OptionSet {
    public let rawValue: Int8
    public init(rawValue: Int8) {
        self.rawValue = rawValue
    }
    /// A case-insensitive search.
    public static let caseInsensitive = StringOptions(rawValue: 1)
    /// Search ignores diacritic marks.
    public static let diacriticInsensitive = StringOptions(rawValue: 2)
}

private struct CollectionFlags: OptionSet {
    public let rawValue: Int8
    public init(rawValue: Int8) {
        self.rawValue = rawValue
    }
    static let rootIsCollection = CollectionFlags(rawValue: 1)
    static let finalIsCollection = CollectionFlags(rawValue: 1)
}

@dynamicMemberLookup
public struct Query<T: _RealmSchemaDiscoverable> {

    public init(isPrimitive: Bool = false) {
        if isPrimitive {
            node = .keyPath(["self"], collection: [.rootIsCollection, .finalIsCollection])
        } else {
            node = .keyPath([], collection: [])
        }
    }

    fileprivate let node: QueryNode

    private init(_ node: QueryNode) {
        self.node = node
    }

    private func appendKeyPath(_ keyPath: String, isCollection: Bool) -> QueryNode {
        if case let .keyPath(kp, c) = node {
            var flags = c
            if kp.count == 0 {
                if isCollection {
                    flags = [.rootIsCollection, .finalIsCollection]
                } else {
                    flags = []
                }
            } else if isCollection {
                flags.insert(.finalIsCollection)
            }

            return .keyPath(kp + [keyPath], collection: flags)
        } else if case let .mapSubscript(lhs, mapKeyPath, requiresNot) = node, case let .keyPath(kp, c) = mapKeyPath {
            return .mapSubscript(lhs, collectionKeyPath: .keyPath(kp + [keyPath], collection: c),
                                 requiresNot: requiresNot)
        }
        throwRealmException("Cannot apply a keypath to \(buildPredicate(node))")
    }

    private func extractCollectionName() -> QueryNode {
        if case let .keyPath(kp, flags) = node {
            if !kp.isEmpty {
                return .keyPath([kp[0]], collection: flags)
            }
        }
        throwRealmException("Cannot apply a keypath to \(buildPredicate(node))")
    }

    private func buildCollectionAggregateKeyPath(_ aggregate: String) -> QueryNode {
        if case let .keyPath(kp, flags) = node {
            var keyPaths = kp
            if keyPaths.count > 1 {
                keyPaths.insert(aggregate, at: 1)
            } else {
                keyPaths.append(aggregate)
            }
            return .keyPath(keyPaths, collection: flags)
        }
        throwRealmException("Cannot apply a keypath to \(buildPredicate(node))")
    }

    // MARK: Prefix

    /// :nodoc:
    public static prefix func ! (_ query: Query) -> Query {
        if case let .strContains(lhs, rhs, options: options) = query.node,
           case let .mapSubscript(mapLhs, mapName, _) = lhs {
            return Query(.strContains(.mapSubscript(mapLhs, collectionKeyPath: mapName, requiresNot: true),
                                      rhs,
                                      options: options))
        } else {
            return Query(.not(query.node))
        }
    }

    // MARK: Comparable

    /// :nodoc:
    public static func == <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _RealmSchemaDiscoverable {
        Query(.equal(lhs.node, .constant(rhs), options: []))
    }
    /// :nodoc:
    public static func != <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _RealmSchemaDiscoverable {
        Query(.notEqual(lhs.node, .constant(rhs), options: []))
    }

    // MARK: Numerics

    /// :nodoc:
    public static func > <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        Query(.greaterThan(lhs.node, .constant(rhs)))
    }
    /// :nodoc:
    public static func >= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        Query(.greaterThanEqual(lhs.node, .constant(rhs)))
    }
    /// :nodoc:
    public static func < <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        Query(.lessThan(lhs.node, .constant(rhs)))

    }
    /// :nodoc:
    public static func <= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        Query(.lessThanEqual(lhs.node, .constant(rhs)))
    }

    // MARK: Compound

    /// :nodoc:
    public static func && (_ lhs: Query, _ rhs: Query) -> Query {
        Query(.and(lhs.node, rhs.node))
    }
    /// :nodoc:
    public static func || (_ lhs: Query, _ rhs: Query) -> Query {
        Query(.or(lhs.node, rhs.node))
    }

    // MARK: Subscript

    /// :nodoc:
    public subscript<V>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        Query<V>(appendKeyPath(_name(for: member), isCollection: V.self is UntypedCollection))
    }
    /// :nodoc:
    public subscript<V: RealmCollectionBase>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        Query<V>(appendKeyPath(_name(for: member), isCollection: true))
    }

    // MARK: Query Construction

    public func _constructPredicate() -> (String, [Any]) {
        return buildPredicate(node)
    }

    /// Creates an NSPredicate compatibe string.
    /// - Returns: A tuple containing the predicate string and an array of arguments.

    /// Creates an NSPredicate from the query expression.
    internal var predicate: NSPredicate {
        let predicate = _constructPredicate()
        return NSPredicate(format: predicate.0, argumentArray: predicate.1)
    }
}

// MARK: OptionalProtocol

extension Query where T: OptionalProtocol {
    /// :nodoc:
    public subscript<V>(dynamicMember member: KeyPath<T.Wrapped, V>) -> Query<V> where T.Wrapped: ObjectBase {
        Query<V>(appendKeyPath(_name(for: member), isCollection: V.self is UntypedCollection))
    }
}

// MARK: RealmCollection

extension Query where T: RealmCollection {
    /// :nodoc:
    public subscript<V>(dynamicMember member: KeyPath<T.Element, V>) -> Query<V> where T.Element: ObjectBase {
        Query<V>(appendKeyPath(_name(for: member), isCollection: true))
    }

    /// Query the count of the objects in the collection.
    public var count: Query<Int> {
        Query<Int>(appendKeyPath("@count", isCollection: false))
    }
}

extension Query where T: RealmCollection {
    /// Checks if an element exists in this collection.
    public func contains<V>(_ value: T.Element) -> Query<V> {
        Query<V>(.in(.constant(value), node))
    }

    /// Checks if any elements contained in the given array are present in the collection.
    public func containsAny<U: Sequence, V>(in collection: U) -> Query<V> where U.Element == T.Element {
        Query<V>(.any(.in(node, .constant(collection))))
    }
}

extension Query where T: RealmCollection, T.Element: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Element>) -> Query<V> {
        Query<V>(.and(.greaterThanEqual(appendKeyPath("@min", isCollection: true), .constant(range.lowerBound)),
                        .lessThan(appendKeyPath("@max", isCollection: true), .constant(range.upperBound))))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Element>) -> Query<V> {
        Query<V>(.and(.greaterThanEqual(appendKeyPath("@min", isCollection: true), .constant(range.lowerBound)),
                        .lessThanEqual(appendKeyPath("@max", isCollection: true), .constant(range.upperBound))))
    }
}

extension Query where T: RealmCollection, T.Element: OptionalProtocol, T.Element.Wrapped: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Element.Wrapped>) -> Query<V> {
        Query<V>(.and(.greaterThanEqual(appendKeyPath("@min", isCollection: true), .constant(range.lowerBound)),
                        .lessThan(appendKeyPath("@max", isCollection: true), .constant(range.upperBound))))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Element.Wrapped>) -> Query<V> {
        Query<V>(.and(.greaterThanEqual(appendKeyPath("@min", isCollection: true), .constant(range.lowerBound)),
                        .lessThanEqual(appendKeyPath("@max", isCollection: true), .constant(range.upperBound))))
    }
}

extension Query where T: RealmCollection, T.Element: _QueryNumeric {
    /// :nodoc:
    public static func == <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        Query<V>(.equal(lhs.node, .constant(rhs), options: []))
    }

    /// :nodoc:
    public static func != <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        Query<V>(.notEqual(lhs.node, .constant(rhs), options: []))
    }

    /// :nodoc:
    public static func > <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        Query<V>(.greaterThan(lhs.node, .constant(rhs)))
    }

    /// :nodoc:
    public static func >= <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        Query<V>(.greaterThanEqual(lhs.node, .constant(rhs)))
    }

    /// :nodoc:
    public static func < <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        Query<V>(.lessThan(lhs.node, .constant(rhs)))
    }

    /// :nodoc:
    public static func <= <V>(_ lhs: Query<T>, _ rhs: T.Element) -> Query<V> {
        Query<V>(.lessThanEqual(lhs.node, .constant(rhs)))
    }
}

extension Query where T: RealmCollection,
                      T.Element: _QueryNumeric {
    /// Returns the minimum value in the collection.
    public var min: Query<T.Element> {
        Query<T.Element>(appendKeyPath("@min", isCollection: false))
    }

    /// Returns the maximum value in the collection.
    public var max: Query<T.Element> {
        Query<T.Element>(appendKeyPath("@max", isCollection: false))
    }

    /// Returns the average in the collection.
    public var avg: Query<T.Element> {
        Query<T.Element>(appendKeyPath("@avg", isCollection: false))
    }

    /// Returns the sum of all the values in the collection.
    public var sum: Query<T.Element> {
        Query<T.Element>(appendKeyPath("@sum", isCollection: false))
    }
}

// MARK: RealmKeyedCollection

extension Query where T: RealmKeyedCollection {
    /// Creates an expression that allows an equals comparison on a maps keys on the lhs, and on the rhs
    /// the ability to compare values in the map. e.g. `((mapString.@allKeys == %@) && NOT mapString CONTAINS %@)`
    private func mapSubscript<U>(_ member: T.Key) -> Query<U> where T.Key: _RealmSchemaDiscoverable {
        return Query<U>(.mapSubscript(.equal(appendKeyPath("@allKeys", isCollection: true),
                                                        .constant(member), options: []),
                                      collectionKeyPath: extractCollectionName(),
                                      requiresNot: false))
    }

    /// Checks if any elements contained in the given array are present in the map's values.
    public func containsAny<U: Sequence, V>(in collection: U) -> Query<V> where U.Element == T.Value {
        Query<V>(.any(.in(node, .constant(collection))))
    }
}

extension Query where T: RealmKeyedCollection, T.Key: _RealmSchemaDiscoverable {
    /// Checks if an element exists in this collection.
    public func contains<V>(_ value: T.Value) -> Query<V> {
        Query<V>(.in(.constant(value), node))
    }
    /// Allows a query over all values in the Map.
    public var values: Query<T.Value> {
        Query<T.Value>(appendKeyPath("@allValues", isCollection: false))
    }
    /// :nodoc:
    public subscript(member: T.Key) -> Query<T.Value> {
        return mapSubscript(member)
    }
}

extension Query where T: RealmKeyedCollection, T.Key: _RealmSchemaDiscoverable, T.Value: OptionalProtocol, T.Value.Wrapped: _RealmSchemaDiscoverable {
    /// Allows a query over all values in the Map.
    public var values: Query<T.Value.Wrapped> {
        Query<T.Value.Wrapped>(appendKeyPath("@allValues", isCollection: false))
    }
    /// :nodoc:
    public subscript(member: T.Key) -> Query<T.Value.Wrapped> {
        return mapSubscript(member)
    }
    /// :nodoc:
    public subscript(member: T.Key) -> Query<T.Value> where T.Value.Wrapped: ObjectBase {
        return mapSubscript(member)
    }
}

extension Query where T: RealmKeyedCollection, T.Key == String {
    /// Allows a query over all keys in the `Map`.
    public var keys: Query<String> {
        Query<String>(appendKeyPath("@allKeys", isCollection: false))
    }
}

extension Query where T: RealmKeyedCollection, T.Value: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Value>) -> Query<V> {
        Query<V>(.and(.greaterThanEqual(appendKeyPath("@min", isCollection: true), .constant(range.lowerBound)),
                      .lessThan(appendKeyPath("@max", isCollection: true), .constant(range.upperBound))))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Value>) -> Query<V> {
        Query<V>(.and(.greaterThanEqual(appendKeyPath("@min", isCollection: true), .constant(range.lowerBound)),
                      .lessThanEqual(appendKeyPath("@max", isCollection: true), .constant(range.upperBound))))
    }
}

extension Query where T: RealmKeyedCollection, T.Value: OptionalProtocol, T.Value.Wrapped: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Value.Wrapped>) -> Query<V> {
        Query<V>(.and(.greaterThanEqual(appendKeyPath("@min", isCollection: true), .constant(range.lowerBound)),
                      .lessThan(appendKeyPath("@max", isCollection: true), .constant(range.upperBound))))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Value.Wrapped>) -> Query<V> {
        Query<V>(.and(.greaterThanEqual(appendKeyPath("@min", isCollection: true), .constant(range.lowerBound)),
                      .lessThanEqual(appendKeyPath("@max", isCollection: true), .constant(range.upperBound))))
    }
}

extension Query where T: RealmKeyedCollection,
                      T.Key: _RealmSchemaDiscoverable,
                      T.Value: _QueryNumeric {
    /// Returns the minimum value in the keyed collection.
    public var min: Query<T.Value> {
        Query<T.Value>(appendKeyPath("@min", isCollection: false))
    }

    /// Returns the maximum value in the keyed collection.
    public var max: Query<T.Value> {
        Query<T.Value>(appendKeyPath("@max", isCollection: false))
    }

    /// Returns the average in the keyed collection.
    public var avg: Query<T.Value> {
        Query<T.Value>(appendKeyPath("@avg", isCollection: false))
    }

    /// Returns the sum of all the values in the keyed collection.
    public var sum: Query<T.Value> {
        Query<T.Value>(appendKeyPath("@sum", isCollection: false))
    }

    /// Returns the count of all the values in the keyed collection.
    public var count: Query<T.Value> {
        Query<T.Value>(appendKeyPath("@count", isCollection: false))
    }
}

// MARK: PersistableEnum

extension Query where T: PersistableEnum, T.RawValue: _RealmSchemaDiscoverable {
    /// :nodoc:
    public static func == <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        Query<V>(.equal(lhs.node, .constant(rhs.rawValue), options: []))
    }
    /// :nodoc:
    public static func != <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        Query<V>(.notEqual(lhs.node, .constant(rhs.rawValue), options: []))
    }
    /// :nodoc:
    public static func > <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        Query<V>(.greaterThan(lhs.node, .constant(rhs.rawValue)))
    }
    /// :nodoc:
    public static func >= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        Query<V>(.greaterThanEqual(lhs.node, .constant(rhs.rawValue)))
    }
    /// :nodoc:
    public static func < <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        Query<V>(.lessThan(lhs.node, .constant(rhs.rawValue)))
    }
    /// :nodoc:
    public static func <= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        Query<V>(.lessThanEqual(lhs.node, .constant(rhs.rawValue)))
    }
}

extension Query where T: PersistableEnum,
                      T.RawValue: _QueryNumeric {
    /// Returns the minimum value in the collection based on the keypath.
    public var min: Query {
        Query(buildCollectionAggregateKeyPath("@min"))
    }

    /// Returns the maximum value in the collection based on the keypath.
    public var max: Query {
        Query(buildCollectionAggregateKeyPath("@max"))
    }

    /// Returns the average in the collection based on the keypath.
    public var avg: Query {
        Query(buildCollectionAggregateKeyPath("@avg"))
    }

    /// Returns the sum of all the values in the collection based on the keypath.
    public var sum: Query {
        Query(buildCollectionAggregateKeyPath("@sum"))
    }

    /// Returns the count of all the values in the collection based on the keypath.
    public var count: Query {
        Query(buildCollectionAggregateKeyPath("@count"))
    }
}

// MARK: Optional

extension Query where T: OptionalProtocol,
                      T.Wrapped: PersistableEnum,
                      T.Wrapped.RawValue: _RealmSchemaDiscoverable {
    /// :nodoc:
    public static func == <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        return Query<V>(.equal(lhs.node, lhs.enumValue(rhs), options: []))
    }
    /// :nodoc:
    public static func != <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        return Query<V>(.notEqual(lhs.node, lhs.enumValue(rhs), options: []))
    }

    private func enumValue(_ rhs: T) -> QueryNode {
        if case Optional<Any>.none = rhs as Any {
            return .constant(nil)
        } else {
            return .constant(rhs._rlmInferWrappedType().rawValue)
        }
    }
}

extension Query where T: OptionalProtocol, T.Wrapped: PersistableEnum, T.Wrapped.RawValue: _QueryNumeric {
    /// :nodoc:
    public static func > <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        Query<V>(.greaterThan(lhs.node, lhs.enumValue(rhs)))
    }
    /// :nodoc:
    public static func >= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        Query<V>(.greaterThanEqual(lhs.node, lhs.enumValue(rhs)))
    }
    /// :nodoc:
    public static func < <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        Query<V>(.lessThan(lhs.node, lhs.enumValue(rhs)))
    }
    /// :nodoc:
    public static func <= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        Query<V>(.lessThanEqual(lhs.node, lhs.enumValue(rhs)))
    }
}

extension Query where T: OptionalProtocol,
                      T.Wrapped: PersistableEnum,
                      T.Wrapped.RawValue: _QueryNumeric {
    /// Returns the minimum value in the collection based on the keypath.
    public var min: Query {
        Query(buildCollectionAggregateKeyPath("@min"))
    }

    /// Returns the maximum value in the collection based on the keypath.
    public var max: Query {
        Query(buildCollectionAggregateKeyPath("@max"))
    }

    /// Returns the average in the collection based on the keypath.
    public var avg: Query {
        Query(buildCollectionAggregateKeyPath("@avg"))
    }

    /// Returns the sum of all the value in the collection based on the keypath.
    public var sum: Query {
        Query(buildCollectionAggregateKeyPath("@sum"))
    }
}

// MARK: _QueryNumeric

extension Query where T: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T>) -> Query<V> {
        Query<V>(.and(.greaterThanEqual(node, .constant(range.lowerBound)),
                        .lessThan(node, .constant(range.upperBound))))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T>) -> Query<V> {
        Query<V>(.between(node,
                          lowerBound: .constant(range.lowerBound),
                          upperBound: .constant(range.upperBound)))
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
        Query<V>(.like(node, .constant(value), options: caseInsensitive ? [.caseInsensitive] : []))
    }
}

// MARK: _QueryBinary

extension Query where T: _QueryBinary {
    /**
     Checks for all elements in this collection that contains the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the Search query.
     */
    public func contains<V>(_ value: T, options: StringOptions = []) -> Query<V> {
        Query<V>(.strContains(node, .constant(value), options: options))
    }

    /**
     Checks for all elements in this collection that starts with the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the Search query.
     */
    public func starts<V>(with value: T, options: StringOptions = []) -> Query<V> {
        Query<V>(.beginsWith(node, .constant(value), options: options))
    }

    /**
     Checks for all elements in this collection that ends with the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the Search query.
     */
    public func ends<V>(with value: T, options: StringOptions = []) -> Query<V> {
        Query<V>(.endsWith(node, .constant(value), options: options))
    }

    /**
     Checks for all elements in this collection that equals the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the Search query.
     */
    public func equals<V>(_ value: T, options: StringOptions = []) -> Query<V> {
        Query<V>(.equal(node, .constant(value), options: options))
    }

    /**
     Checks for all elements in this collection that are not equal to the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the Search query.
     */
    public func notEquals<V>(_ value: T, options: StringOptions = []) -> Query<V> {
        Query<V>(.notEqual(node, .constant(value), options: options))
    }
}

extension Query where T: OptionalProtocol, T.Wrapped: _QueryNumeric {
    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: Range<T.Wrapped>) -> Query<V> {
        Query<V>(.and(.greaterThanEqual(node, .constant(range.lowerBound)),
                        .lessThan(node, .constant(range.upperBound))))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains<V>(_ range: ClosedRange<T.Wrapped>) -> Query<V> {
        Query<V>(.between(node,
                          lowerBound: .constant(range.lowerBound),
                          upperBound: .constant(range.upperBound)))
    }
}

// MARK: Subquery

extension Query where T == Bool {
    /// Completes a subquery expression.
    /// - Usage:
    /// ```
    /// ($0.myCollection.age >= 21).count > 0
    /// ```
    /// - Note:
    /// Do not mix collections within a subquery expression. It is
    /// only permitted to reference a single collection per each subquery.
    public var count: Query<Int> {
        Query<Int>(.subqueryCount(node))
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
        Query(buildCollectionAggregateKeyPath("@min"))
    }

    /// Returns the maximum value of the objects in the collection based on the keypath.
    public var max: Query {
        Query(buildCollectionAggregateKeyPath("@max"))
    }

    /// Returns the average of the objects in the collection based on the keypath.
    public var avg: Query {
        Query(buildCollectionAggregateKeyPath("@avg"))
    }

    /// Returns the sum of the objects in the collection based on the keypath.
    public var sum: Query {
        Query(buildCollectionAggregateKeyPath("@sum"))
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

// MARK: QueryNode -

private indirect enum QueryNode {
    case any(_ child: QueryNode)
    case constant(_ value: Any?)

    case keyPath(_ value: [String], collection: CollectionFlags)

    case not(_ child: QueryNode)
    case and(_ lhs: QueryNode, _ rhs: QueryNode)
    case or(_ lhs: QueryNode, _ rhs: QueryNode)

    case equal(_ lhs: QueryNode, _ rhs: QueryNode, options: StringOptions)
    case notEqual(_ lhs: QueryNode, _ rhs: QueryNode, options: StringOptions)
    case lessThan(_ lhs: QueryNode, _ rhs: QueryNode)
    case lessThanEqual(_ lhs: QueryNode, _ rhs: QueryNode)
    case greaterThan(_ lhs: QueryNode, _ rhs: QueryNode)
    case greaterThanEqual(_ lhs: QueryNode, _ rhs: QueryNode)
    case `in`(_ lhs: QueryNode, _ rhs: QueryNode)
    case between(_ lhs: QueryNode, lowerBound: QueryNode, upperBound: QueryNode)

    case like(_ lhs: QueryNode, _ rhs: QueryNode, options: StringOptions)
    case strContains(_ lhs: QueryNode, _ rhs: QueryNode, options: StringOptions)
    case beginsWith(_ lhs: QueryNode, _ rhs: QueryNode, options: StringOptions)
    case endsWith(_ lhs: QueryNode, _ rhs: QueryNode, options: StringOptions)

    case subqueryCount(_ child: QueryNode)
    case mapSubscript(_ lhs: QueryNode, collectionKeyPath: QueryNode, requiresNot: Bool)
}

private func buildPredicate(_ root: QueryNode, subqueryCount: Int = 0) -> (String, [Any]) {
    let formatStr = NSMutableString()
    let arguments = NSMutableArray()
    var subqueryCounter = subqueryCount
    var mapRequiresClosingParenthesis = false

    func buildComparison(_ lhs: QueryNode, _ op: String, _ rhs: QueryNode) {
        build(lhs)
        formatStr.append(" \(op) ")
        build(rhs)
        if mapRequiresClosingParenthesis {
            formatStr.append(")")
            mapRequiresClosingParenthesis = false
        }
    }

    func buildCompound(_ lhs: QueryNode, _ op: String, _ rhs: QueryNode) {
        formatStr.append("(")
        build(lhs)
        formatStr.append(" \(op) ")
        build(rhs)
        formatStr.append(")")
    }

    func buildBetween(_ lowerBound: QueryNode, _ upperBound: QueryNode) {
        formatStr.append(" BETWEEN {")
        build(lowerBound)
        formatStr.append(", ")
        build(upperBound)
        formatStr.append("}")
    }

    func strOptions(_ options: StringOptions) -> String {
        if options == [] {
            return ""
        }
        return "[\(options.contains(.caseInsensitive) ? "c" : "")\(options.contains(.diacriticInsensitive) ? "d" : "")]"
    }

    func build(_ node: QueryNode) {
        switch node {
        case .any(let child):
            formatStr.append("ANY ")
            build(child)
        case .constant(let value):
            formatStr.append("%@")
            arguments.add(value ?? NSNull())
        case .keyPath(let kp, _):
            formatStr.append(kp.joined(separator: "."))
        case .not(let child):
            formatStr.append("NOT ")
            build(child)
        case .and(let lhs, let rhs):
            buildCompound(lhs, "&&", rhs)
        case .or(let lhs, let rhs):
            buildCompound(lhs, "||", rhs)
        case .equal(let lhs, let rhs, let options):
            buildComparison(lhs, "==\(strOptions(options))", rhs)
        case .notEqual(let lhs, let rhs, let options):
            buildComparison(lhs, "!=\(strOptions(options))", rhs)
        case .lessThan(let lhs, let rhs):
            buildComparison(lhs, "<", rhs)
        case .lessThanEqual(let lhs, let rhs):
            buildComparison(lhs, "<=", rhs)
        case .greaterThan(let lhs, let rhs):
            buildComparison(lhs, ">", rhs)
        case .greaterThanEqual(let lhs, let rhs):
            buildComparison(lhs, ">=", rhs)
        case .`in`(let lhs, let rhs):
            buildComparison(lhs, "IN", rhs)
        case .between(let lhs, let lowerBound, let upperBound):
            formatStr.append("(")
            build(lhs)
            buildBetween(lowerBound, upperBound)
            formatStr.append(")")
        case .strContains(let lhs, let rhs, let options):
            buildComparison(lhs, "CONTAINS\(strOptions(options))", rhs)
        case .beginsWith(let lhs, let rhs, let options):
            buildComparison(lhs, "BEGINSWITH\(strOptions(options))", rhs)
        case .endsWith(let lhs, let rhs, let options):
            buildComparison(lhs, "ENDSWITH\(strOptions(options))", rhs)
        case .like(let lhs, let rhs, let options):
            buildComparison(lhs, "LIKE\(strOptions(options))", rhs)
        case .subqueryCount(let inner):
            subqueryCounter += 1
            let (collectionName, node) = SubqueryRewriter.rewrite(inner, subqueryCounter)
            formatStr.append("SUBQUERY(\(collectionName), $col\(subqueryCounter), ")
            build(node)
            formatStr.append(").@count")
        case .mapSubscript(let lhs, let collectionKeyPath, let requiresNot):
            formatStr.append("(")
            build(lhs)
            formatStr.append(" && ")
            if requiresNot {
                formatStr.append("NOT ")
            }
            build(collectionKeyPath)
            mapRequiresClosingParenthesis = true
        }
    }
    build(root)
    return (formatStr as String, (arguments as! [Any]))
}

struct SubqueryRewriter {
    private var collectionName: String?
    private var counter: Int
    private mutating func rewrite(_ node: QueryNode) -> QueryNode {

        switch node {
        case .any(let child):
            return .any(rewrite(child))
        case .keyPath(let kp, let collectionFlags):
            if collectionFlags.contains(.rootIsCollection) {
                precondition(kp.count > 0)
                collectionName = kp[0]
                var copy = kp
                copy[0] = "$col\(counter)"
                return .keyPath(copy, collection: collectionFlags.intersection([.finalIsCollection]))
            }
            return node
        case .not(let child):
            return .not(rewrite(child))
        case .and(let lhs, let rhs):
            return .and(rewrite(lhs), rewrite(rhs))
        case .or(let lhs, let rhs):
            return .or(rewrite(lhs), rewrite(rhs))
        case .equal(let lhs, let rhs, let options):
            return .equal(rewrite(lhs), rewrite(rhs), options: options)
        case .notEqual(let lhs, let rhs, let options):
            return .notEqual(rewrite(lhs), rewrite(rhs), options: options)
        case .lessThan(let lhs, let rhs):
            return .lessThan(rewrite(lhs), rewrite(rhs))
        case .lessThanEqual(let lhs, let rhs):
            return .lessThanEqual(rewrite(lhs), rewrite(rhs))
        case .greaterThan(let lhs, let rhs):
            return .greaterThan(rewrite(lhs), rewrite(rhs))
        case .greaterThanEqual(let lhs, let rhs):
            return .greaterThanEqual(rewrite(lhs), rewrite(rhs))
        case .`in`(let lhs, let rhs):
            return .`in`(rewrite(lhs), rewrite(rhs))
        case .between(let lhs, let lowerBound, let upperBound):
            return .between(rewrite(lhs), lowerBound: rewrite(lowerBound), upperBound: rewrite(upperBound))
        case .strContains(let lhs, let rhs, let options):
            return .strContains(rewrite(lhs), rewrite(rhs), options: options)
        case .beginsWith(let lhs, let rhs, let options):
            return .beginsWith(rewrite(lhs), rewrite(rhs), options: options)
        case .endsWith(let lhs, let rhs, let options):
            return .endsWith(rewrite(lhs), rewrite(rhs), options: options)
        case .subqueryCount(let inner):
            return .subqueryCount(inner)
        case .constant:
            return node
        case let .like(lhs, rhs, options):
            return .like(rewrite(lhs), rewrite(rhs), options: options)
        case .mapSubscript:
            throwRealmException("Subqueries do not support map subscripts.")
        }
    }

    static fileprivate func rewrite(_ node: QueryNode, _ counter: Int) -> (String, QueryNode) {
        var rewriter = SubqueryRewriter(counter: counter)
        let rewritten = rewriter.rewrite(node)
        guard let collectionName = rewriter.collectionName else {
            throwRealmException("Subquery must contain keypath starting with a collection")
        }
        return (collectionName, rewritten)
    }
}
