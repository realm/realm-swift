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

/// Enum representing an option for `String` queries.
public struct StringOptions: OptionSet, Sendable {
    /// :doc:
    public let rawValue: Int8
    /// :doc:
    public init(rawValue: Int8) {
        self.rawValue = rawValue
    }
    /// A case-insensitive search.
    public static let caseInsensitive = StringOptions(rawValue: 1)
    /// Query ignores diacritic marks.
    public static let diacriticInsensitive = StringOptions(rawValue: 2)
}

/**
 `Query` is a class used to create type-safe query predicates.

 With `Query` you are given the ability to create Swift style query expression that will then
 be constructed into an `NSPredicate`. The `Query` class should not be instantiated directly
 and should be only used as a parameter within a closure that takes a query expression as an argument.
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
public struct Query<T> {
    /// This initaliser should be used from callers who require queries on primitive collections.
    /// - Parameter isPrimitive: True if performing a query on a primitive collection.
    internal init(isPrimitive: Bool = false) {
        if isPrimitive {
            node = .keyPath(["self"], options: [.isCollection])
        } else {
            node = .keyPath([], options: [])
        }
    }

    private let node: QueryNode

    /**
     The `Query` struct works by compounding `QueryNode`s together in a tree structure.
     Each part of a query expression will be represented by one of the below static methods.
     For example in the simple expression `stringCol == 'Foo'`:

     The first static method that will be called from inside the query
     closure is `subscript<V>(dynamicMember member: KeyPath<T, V>)`
     this will extract the `stringCol` keypath. The last static method to be called in this expression is
     `func == <V>(_ lhs: Query<V>, _ rhs: V)` where the lhs is a `Query` which holds the `QueryNode`
     keyPath for `stringCol`. The rhs will be expressed as a constant in `QueryNode` and a tree will be built
     to represent an equals comparison.

     To build the tree we will do:
     ```
     Query<Bool>(.comparison(operator: .equal, lhs.node, .constant(rhs), options: []))
     ```
     This sets the comparison node as the root node for the expression and the new `Query` struct will be returned.

     When it comes time to build the predicate string with its arguments call `_constructPredicate()`. This will
     recursively traverse the tree and build the NSPredicate compatible string.
     */
    private init(_ node: QueryNode) {
        self.node = node
    }

    private func appendKeyPath(_ keyPath: String, options: KeyPathOptions) -> QueryNode {
        if case let .keyPath(kp, ops) = node {
            return .keyPath(kp + [keyPath], options: ops.union(options))
        } else if case .mapSubscript = node {
            throwRealmException("Cannot apply key path to Map subscripts.")
        }
        throwRealmException("Cannot apply a keypath to \(buildPredicate(node))")
    }

    private func buildCollectionAggregateKeyPath(_ aggregate: String) -> QueryNode {
        if case let .keyPath(kp, options) = node {
            var keyPaths = kp
            if keyPaths.count > 1 {
                keyPaths.insert(aggregate, at: 1)
            } else {
                keyPaths.append(aggregate)
            }
            return .keyPath(keyPaths, options: [options.subtracting(.requiresAny)])
        }
        throwRealmException("Cannot apply a keypath to \(buildPredicate(node))")
    }

    private func keyPathErasingAnyPrefix(appending keyPath: String? = nil) -> QueryNode {
        if case let .keyPath(kp, o) = node {
            if let keyPath = keyPath {
                return .keyPath(kp + [keyPath], options: [o.subtracting(.requiresAny)])
            }
            return .keyPath(kp, options: [o.subtracting(.requiresAny)])
        }
        throwRealmException("Cannot apply a keypath to \(buildPredicate(node))")
    }

    private func anySubscript(appending key: CollectionSubscript) -> QueryNode {
        if case .keyPath = node {
            return .mapAnySubscripts(keyPathErasingAnyPrefix(), keys: [key])
        } else if case let .mapAnySubscripts(kp, keys) = node {
            var tmpKeys = keys
            tmpKeys.append(key)
            return .mapAnySubscripts(kp, keys: tmpKeys)
        }
        throwRealmException("Cannot add subscript to \(buildPredicate(node))")
    }

    // MARK: Comparable

    /// :nodoc:
    public static func == (_ lhs: Query, _ rhs: T) -> Query<Bool> {
        .init(.comparison(operator: .equal, lhs.node, .constant(rhs), options: []))
    }
    /// :nodoc:
    public static func == (_ lhs: Query, _ rhs: Query) -> Query<Bool> {
        .init(.comparison(operator: .equal, lhs.node, rhs.node, options: []))
    }
    /// :nodoc:
    public static func != (_ lhs: Query, _ rhs: T) -> Query<Bool> {
        .init(.comparison(operator: .notEqual, lhs.node, .constant(rhs), options: []))
    }
    /// :nodoc:
    public static func != (_ lhs: Query, _ rhs: Query) -> Query<Bool> {
        .init(.comparison(operator: .notEqual, lhs.node, rhs.node, options: []))
    }

    // MARK: In

    /// Checks if the value is present in the collection.
    public func `in`<U: Sequence>(_ collection: U) -> Query<Bool> where U.Element == T {
        .init(.comparison(operator: .in, node, .constant(collection), options: []))
    }

    // MARK: Subscript

    /// :nodoc:
    public subscript<V>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        .init(appendKeyPath(_name(for: member), options: []))
    }
    /// :nodoc:
    public subscript<V: RealmKeyedCollection>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        .init(appendKeyPath(_name(for: member), options: [.isCollection, .requiresAny]))
    }
    /// :nodoc:
    public subscript<V: RealmCollectionBase>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        .init(appendKeyPath(_name(for: member), options: [.isCollection, .requiresAny]))
    }

    // MARK: Query Construction

    /// For testing purposes only. Do not use directly.
    public static func _constructForTesting() -> Query<T> {
        return Query<T>()
    }

    /// Constructs an NSPredicate compatible string with its accompanying arguments.
    /// - Note: This is for internal use only and is exposed for testing purposes.
    public func _constructPredicate() -> (String, [Any]) {
        return buildPredicate(node)
    }

    /// Creates an NSPredicate compatible string.
    /// - Returns: A tuple containing the predicate string and an array of arguments.

    /// Creates an NSPredicate from the query expression.
    internal var predicate: NSPredicate {
        let predicate = _constructPredicate()
        return NSPredicate(format: predicate.0, argumentArray: predicate.1)
    }
}

// MARK: Numerics
extension Query where T: _HasPersistedType, T.PersistedType: _QueryNumeric {
    /// :nodoc:
    public static func > (_ lhs: Query, _ rhs: T) -> Query<Bool> {
        .init(.comparison(operator: .greaterThan, lhs.node, .constant(rhs), options: []))
    }
    /// :nodoc:
    public static func > (_ lhs: Query, _ rhs: Query) -> Query<Bool> {
        .init(.comparison(operator: .greaterThan, lhs.node, rhs.node, options: []))
    }
    /// :nodoc:
    public static func >= (_ lhs: Query, _ rhs: T) -> Query<Bool> {
        .init(.comparison(operator: .greaterThanEqual, lhs.node, .constant(rhs), options: []))
    }
    /// :nodoc:
    public static func >= (_ lhs: Query, _ rhs: Query) -> Query<Bool> {
        .init(.comparison(operator: .greaterThanEqual, lhs.node, rhs.node, options: []))
    }
    /// :nodoc:
    public static func < (_ lhs: Query, _ rhs: T) -> Query<Bool> {
        .init(.comparison(operator: .lessThan, lhs.node, .constant(rhs), options: []))
    }
    /// :nodoc:
    public static func < (_ lhs: Query, _ rhs: Query) -> Query<Bool> {
        .init(.comparison(operator: .lessThan, lhs.node, rhs.node, options: []))
    }
    /// :nodoc:
    public static func <= (_ lhs: Query, _ rhs: T) -> Query<Bool> {
        .init(.comparison(operator: .lessThanEqual, lhs.node, .constant(rhs), options: []))
    }
    /// :nodoc:
    public static func <= (_ lhs: Query, _ rhs: Query) -> Query<Bool> {
        .init(.comparison(operator: .lessThanEqual, lhs.node, rhs.node, options: []))
    }
}

// MARK: Compound

extension Query where T == Bool {
    /// :nodoc:
    public static prefix func ! (_ query: Query) -> Query<Bool> {
        .init(.not(query.node))
    }

    /// :nodoc:
    public static func && (_ lhs: Query, _ rhs: Query) -> Query<Bool> {
        .init(.comparison(operator: .and, lhs.node, rhs.node, options: []))
    }
    /// :nodoc:
    public static func || (_ lhs: Query, _ rhs: Query) -> Query<Bool> {
        .init(.comparison(operator: .or, lhs.node, rhs.node, options: []))
    }
}

// MARK: Mixed

extension Query where T == AnyRealmValue {
    /// :nodoc:
    public subscript(position: Int) -> Query<AnyRealmValue> {
        .init(anySubscript(appending: .index(position)))

    }
    /// :nodoc:
    public subscript(key: String) -> Query<AnyRealmValue> {
        .init(anySubscript(appending: .key(key)))
    }
    /// Query all indexes or keys in a mixed nested collecttion.
    public var any: Query<AnyRealmValue> {
        .init(anySubscript(appending: .all))
    }
}

// MARK: OptionalProtocol

extension Query where T: OptionalProtocol {
    /// :nodoc:
    public subscript<V>(dynamicMember member: KeyPath<T.Wrapped, V>) -> Query<V> where T.Wrapped: ObjectBase {
        .init(appendKeyPath(_name(for: member), options: []))
    }
}

// MARK: RealmCollection

extension Query where T: RealmCollection {
    /// :nodoc:
    public subscript<V>(dynamicMember member: KeyPath<T.Element, V>) -> Query<V> where T.Element: ObjectBase {
        .init(appendKeyPath(_name(for: member), options: []))
    }

    /// Query the count of the objects in the collection.
    public var count: Query<Int> {
        .init(keyPathErasingAnyPrefix(appending: "@count"))
    }
}

extension Query where T: RealmCollection {
    /// Checks if an element exists in this collection.
    public func contains(_ value: T.Element) -> Query<Bool> {
        .init(.comparison(operator: .in, .constant(value), keyPathErasingAnyPrefix(), options: []))
    }

    /// Checks if any elements contained in the given array are present in the collection.
    public func containsAny<U: Sequence>(in collection: U) -> Query<Bool> where U.Element == T.Element {
        .init(.comparison(operator: .in, node, .constant(collection), options: []))
    }
}

extension Query where T: RealmCollection, T.Element: Comparable {
    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: Range<T.Element>) -> Query<Bool> {
        .init(.comparison(operator: .and,
                          .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                          .comparison(operator: .lessThan, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: ClosedRange<T.Element>) -> Query<Bool> {
        .init(.comparison(operator: .and,
                          .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                          .comparison(operator: .lessThanEqual, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
    }
}

extension Query where T: RealmCollection, T.Element: OptionalProtocol, T.Element.Wrapped: Comparable {
    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: Range<T.Element.Wrapped>) -> Query<Bool> {
        .init(.comparison(operator: .and,
                          .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                          .comparison(operator: .lessThan, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: ClosedRange<T.Element.Wrapped>) -> Query<Bool> {
        .init(.comparison(operator: .and,
                          .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                          .comparison(operator: .lessThanEqual, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
    }
}

extension Query where T: RealmCollection {
    /// :nodoc:
    public static func == (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool> {
        .init(.comparison(operator: .equal, lhs.node, .constant(rhs), options: []))
    }

    /// :nodoc:
    public static func != (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool> {
        .init(.comparison(operator: .notEqual, lhs.node, .constant(rhs), options: []))
    }
}

extension Query where T: RealmCollection, T.Element.PersistedType: _QueryNumeric {
    /// :nodoc:
    public static func > (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool> {
        .init(.comparison(operator: .greaterThan, lhs.node, .constant(rhs), options: []))
    }

    /// :nodoc:
    public static func >= (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool> {
        .init(.comparison(operator: .greaterThanEqual, lhs.node, .constant(rhs), options: []))
    }

    /// :nodoc:
    public static func < (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool> {
        .init(.comparison(operator: .lessThan, lhs.node, .constant(rhs), options: []))
    }

    /// :nodoc:
    public static func <= (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool> {
        .init(.comparison(operator: .lessThanEqual, lhs.node, .constant(rhs), options: []))
    }

    /// Returns the minimum value in the collection.
    public var min: Query<T.Element> {
        .init(keyPathErasingAnyPrefix(appending: "@min"))
    }

    /// Returns the maximum value in the collection.
    public var max: Query<T.Element> {
        .init(keyPathErasingAnyPrefix(appending: "@max"))
    }

    /// Returns the average in the collection.
    public var avg: Query<T.Element> {
        .init(keyPathErasingAnyPrefix(appending: "@avg"))
    }

    /// Returns the sum of all the values in the collection.
    public var sum: Query<T.Element> {
        .init(keyPathErasingAnyPrefix(appending: "@sum"))
    }
}

// MARK: RealmKeyedCollection

extension Query where T: RealmKeyedCollection {
    /// Checks if any elements contained in the given array are present in the map's values.
    public func containsAny<U: Sequence>(in collection: U) -> Query<Bool> where U.Element == T.Value {
        .init(.comparison(operator: .in, node, .constant(collection), options: []))
    }

    /// Checks if an element exists in this collection.
    public func contains(_ value: T.Value) -> Query<Bool> {
        .init(.comparison(operator: .in, .constant(value), keyPathErasingAnyPrefix(), options: []))
    }
    /// Allows a query over all values in the Map.
    public var values: Query<T.Value> {
        .init(appendKeyPath("@allValues", options: []))
    }
    /// :nodoc:
    public subscript(member: T.Key) -> Query<T.Value> {
        .init(.mapSubscript(keyPathErasingAnyPrefix(), key: member))
    }
}

extension Query where T: RealmKeyedCollection, T.Key == String {
    /// Allows a query over all keys in the `Map`.
    public var keys: Query<String> {
        .init(appendKeyPath("@allKeys", options: []))
    }
}

extension Query where T: RealmKeyedCollection, T.Value: Comparable {
    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: Range<T.Value>) -> Query<Bool> {
        .init(.comparison(operator: .and,
                          .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                          .comparison(operator: .lessThan, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: ClosedRange<T.Value>) -> Query<Bool> {
        .init(.comparison(operator: .and,
                          .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                          .comparison(operator: .lessThanEqual, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
    }
}

extension Query where T: RealmKeyedCollection, T.Value: OptionalProtocol, T.Value.Wrapped: Comparable {
    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: Range<T.Value.Wrapped>) -> Query<Bool> {
        .init(.comparison(operator: .and,
                          .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                          .comparison(operator: .lessThan, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: ClosedRange<T.Value.Wrapped>) -> Query<Bool> {
        .init(.comparison(operator: .and,
                          .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                          .comparison(operator: .lessThanEqual, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
    }
}

extension Query where T: RealmKeyedCollection, T.Value.PersistedType: _QueryNumeric {
    /// Returns the minimum value in the keyed collection.
    public var min: Query<T.Value> {
        .init(keyPathErasingAnyPrefix(appending: "@min"))
    }

    /// Returns the maximum value in the keyed collection.
    public var max: Query<T.Value> {
        .init(keyPathErasingAnyPrefix(appending: "@max"))
    }

    /// Returns the average in the keyed collection.
    public var avg: Query<T.Value> {
        .init(keyPathErasingAnyPrefix(appending: "@avg"))
    }

    /// Returns the sum of all the values in the keyed collection.
    public var sum: Query<T.Value> {
        .init(keyPathErasingAnyPrefix(appending: "@sum"))
    }
}

extension Query where T: RealmKeyedCollection {
    /// Returns the count of all the values in the keyed collection.
    public var count: Query<Int> {
        .init(keyPathErasingAnyPrefix(appending: "@count"))
    }
}

// MARK: - PersistableEnum

extension Query where T: PersistableEnum, T.RawValue: _RealmSchemaDiscoverable {
    /// Query on the rawValue of the Enum rather than the Enum itself.
    ///
    /// This can be used to write queries which can be expressed on the
    /// RawValue but not the enum. For example, this lets you query for
    /// `.starts(with:)` on a string enum where the prefix is not a member of
    /// the enum.
    public var rawValue: Query<T.RawValue> {
        .init(node)
    }
}
extension Query where T: OptionalProtocol, T.Wrapped: PersistableEnum, T.Wrapped.RawValue: _RealmSchemaDiscoverable {
    /// Query on the rawValue of the Enum rather than the Enum itself.
    ///
    /// This can be used to write queries which can be expressed on the
    /// RawValue but not the enum. For example, this lets you query for
    /// `.starts(with:)` on a string enum where the prefix is not a member of
    /// the enum.
    public var rawValue: Query<T.Wrapped.RawValue?> {
        .init(node)
    }
}

// The actual collection type returned in these doesn't matter because it's
// only used to constrain the set of operations available, and the collections
// all have the same operations.
extension Query where T: RealmCollection, T.Element: PersistableEnum, T.Element.RawValue: RealmCollectionValue {
    /// Query on the rawValue of the Enums in the collection rather than the Enums themselves.
    ///
    /// This can be used to write queries which can be expressed on the
    /// RawValue but not the enum. For example, this lets you query for
    /// `.starts(with:)` on a string enum where the prefix is not a member of
    /// the enum.
    public var rawValue: Query<AnyRealmCollection<T.Element.RawValue>> {
        .init(node)
    }
}
extension Query where T: RealmKeyedCollection, T.Value: PersistableEnum, T.Value.RawValue: RealmCollectionValue {
    /// Query on the rawValue of the Enums in the collection rather than the Enums themselves.
    ///
    /// This can be used to write queries which can be expressed on the
    /// RawValue but not the enum. For example, this lets you query for
    /// `.starts(with:)` on a string enum where the prefix is not a member of
    /// the enum.
    public var rawValue: Query<Map<T.Key, T.Value.RawValue>> {
        .init(node)
    }
}
extension Query where T: RealmCollection, T.Element: OptionalProtocol, T.Element.Wrapped: PersistableEnum, T.Element.Wrapped.RawValue: _RealmCollectionValueInsideOptional {
    /// Query on the rawValue of the Enums in the collection rather than the Enums themselves.
    ///
    /// This can be used to write queries which can be expressed on the
    /// RawValue but not the enum. For example, this lets you query for
    /// `.starts(with:)` on a string enum where the prefix is not a member of
    /// the enum.
    public var rawValue: Query<AnyRealmCollection<T.Element.Wrapped.RawValue?>> {
        .init(node)
    }
}
extension Query where T: RealmKeyedCollection, T.Value: OptionalProtocol, T.Value.Wrapped: PersistableEnum, T.Value.Wrapped.RawValue: _RealmCollectionValueInsideOptional {
    /// Query on the rawValue of the Enums in the collection rather than the Enums themselves.
    ///
    /// This can be used to write queries which can be expressed on the
    /// RawValue but not the enum. For example, this lets you query for
    /// `.starts(with:)` on a string enum where the prefix is not a member of
    /// the enum.
    public var rawValue: Query<Map<T.Key, T.Value.Wrapped.RawValue?>> {
        .init(node)
    }
}

// MARK: - CustomPersistable

extension Query where T: _HasPersistedType {
    /// Query on the persistableValue of the value rather than the value itself.
    ///
    /// This can be used to write queries which can be expressed on the
    /// persisted type but not on the type itself, such as range queries
    /// on the persistable value or to query for values which can't be
    /// converted to the mapped type.
    ///
    /// For types which don't conform to PersistableEnum, CustomPersistable or
    /// FailableCustomPersistable this doesn't do anything useful.
    public var persistableValue: Query<T.PersistedType> {
        .init(node)
    }
}

// The actual collection type returned in these doesn't matter because it's
// only used to constrain the set of operations available, and the collections
// all have the same operations.
extension Query where T: RealmCollection {
    /// Query on the persistableValue of the values in the collection rather
    /// than the values themselves.
    ///
    /// This can be used to write queries which can be expressed on the
    /// persisted type but not on the type itself, such as range queries
    /// on the persistable value or to query for values which can't be
    /// converted to the mapped type.
    ///
    /// For types which don't conform to PersistableEnum, CustomPersistable or
    /// FailableCustomPersistable this doesn't do anything useful.
    public var persistableValue: Query<AnyRealmCollection<T.Element.PersistedType>> {
        .init(node)
    }
}
extension Query where T: RealmKeyedCollection {
    /// Query on the persistableValue of the values in the collection rather
    /// than the values themselves.
    ///
    /// This can be used to write queries which can be expressed on the
    /// persisted type but not on the type itself, such as range queries
    /// on the persistable value or to query for values which can't be
    /// converted to the mapped type.
    ///
    /// For types which don't conform to PersistableEnum, CustomPersistable or
    /// FailableCustomPersistable this doesn't do anything useful.
    public var persistableValue: Query<Map<T.Key, T.Value.PersistedType>> {
        .init(node)
    }
}

// MARK: _QueryNumeric

extension Query where T: Comparable {
    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: Range<T>) -> Query<Bool> {
        .init(.comparison(operator: .and,
                          .comparison(operator: .greaterThanEqual, node, .constant(range.lowerBound), options: []),
                          .comparison(operator: .lessThan, node, .constant(range.upperBound), options: []), options: []))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: ClosedRange<T>) -> Query<Bool> {
        .init(.between(node,
                       lowerBound: .constant(range.lowerBound),
                       upperBound: .constant(range.upperBound)))
    }
}

// MARK: _QueryString

extension Query where T: _HasPersistedType, T.PersistedType: _QueryString {
    /**
     Checks for all elements in this collection that equal the given value.
     `?` and `*` are allowed as wildcard characters, where `?` matches 1 character and `*` matches 0 or more characters.
     - parameter value: value used.
     - parameter caseInsensitive: `true` if it is a case-insensitive search.
     */
    public func like(_ value: T, caseInsensitive: Bool = false) -> Query<Bool> {
        .init(.comparison(operator: .like, node, .constant(value), options: caseInsensitive ? [.caseInsensitive] : []))
    }

    /**
     Checks for all elements in this collection that equal the given value.
     `?` and `*` are allowed as wildcard characters, where `?` matches 1 character and `*` matches 0 or more characters.
     - parameter value: value used.
     - parameter caseInsensitive: `true` if it is a case-insensitive search.
     */
    public func like<U>(_ column: Query<U>, caseInsensitive: Bool = false) -> Query<Bool> {
        .init(.comparison(operator: .like, node, column.node, options: caseInsensitive ? [.caseInsensitive] : []))
    }
}

// MARK: _QueryBinary

extension Query where T: _HasPersistedType, T.PersistedType: _QueryBinary {
    /**
     Checks for all elements in this collection that contains the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the search query.
     */
    public func contains(_ value: T, options: StringOptions = []) -> Query<Bool> {
        .init(.comparison(operator: .contains, node, .constant(value), options: options))
    }

    /**
     Compares that this column contains a value in another column.
     - parameter column: The other column.
     - parameter options: A Set of options used to evaluate the search query.
     */
    public func contains<U>(_ column: Query<U>, options: StringOptions = []) -> Query<Bool> where U: _Persistable, U.PersistedType: _QueryBinary {
        .init(.comparison(operator: .contains, node, column.node, options: options))
    }

    /**
     Checks for all elements in this collection that starts with the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the search query.
     */
    public func starts(with value: T, options: StringOptions = []) -> Query<Bool> {
        .init(.comparison(operator: .beginsWith, node, .constant(value), options: options))
    }

    /**
     Compares that this column starts with a value in another column.
     - parameter column: The other column.
     - parameter options: A Set of options used to evaluate the search query.
     */
    public func starts<U>(with column: Query<U>, options: StringOptions = []) -> Query<Bool> {
        .init(.comparison(operator: .beginsWith, node, column.node, options: options))
    }

    /**
     Checks for all elements in this collection that ends with the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the search query.
     */
    public func ends(with value: T, options: StringOptions = []) -> Query<Bool> {
        .init(.comparison(operator: .endsWith, node, .constant(value), options: options))
    }

    /**
     Compares that this column ends with a value in another column.
     - parameter column: The other column.
     - parameter options: A Set of options used to evaluate the search query.
     */
    public func ends<U>(with column: Query<U>, options: StringOptions = []) -> Query<Bool> {
        .init(.comparison(operator: .endsWith, node, column.node, options: options))
    }

    /**
     Checks for all elements in this collection that equals the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the search query.
     */
    public func equals(_ value: T, options: StringOptions = []) -> Query<Bool> {
        .init(.comparison(operator: .equal, node, .constant(value), options: options))
    }

    /**
     Compares that this column is equal to the value in another given column.
     - parameter column: The other column.
     - parameter options: A Set of options used to evaluate the search query.
     */
    public func equals<U>(_ column: Query<U>, options: StringOptions = []) -> Query<Bool> {
        .init(.comparison(operator: .equal, node, column.node, options: options))
    }

    /**
     Checks for all elements in this collection that are not equal to the given value.
     - parameter value: value used.
     - parameter options: A Set of options used to evaluate the search query.
     */
    public func notEquals(_ value: T, options: StringOptions = []) -> Query<Bool> {
        .init(.comparison(operator: .notEqual, node, .constant(value), options: options))
    }

    /**
     Compares that this column is not equal to the value in another given column.
     - parameter column: The other column.
     - parameter options: A Set of options used to evaluate the search query.
     */
    public func notEquals<U>(_ column: Query<U>, options: StringOptions = []) -> Query<Bool> {
        .init(.comparison(operator: .notEqual, node, column.node, options: options))
    }
}

extension Query where T: OptionalProtocol, T.Wrapped: Comparable {
    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: Range<T.Wrapped>) -> Query<Bool> {
        .init(.comparison(operator: .and,
                          .comparison(operator: .greaterThanEqual, node, .constant(range.lowerBound), options: []),
                          .comparison(operator: .lessThan, node, .constant(range.upperBound), options: []), options: []))
    }

    /// Checks for all elements in this collection that are within a given range.
    public func contains(_ range: ClosedRange<T.Wrapped>) -> Query<Bool> {
        .init(.between(node,
                       lowerBound: .constant(range.lowerBound),
                       upperBound: .constant(range.upperBound)))
    }
}

// MARK: Subquery

extension Query where T == Bool {
    /// Completes a subquery expression.
    /// - Usage:
    /// ```
    /// (($0.myCollection.age >= 21) && ($0.myCollection.siblings == 4))).count >= 5
    /// ```
    /// - Note:
    /// Do not mix collections within a subquery expression. It is
    /// only permitted to reference a single collection per each subquery.
    public var count: Query<Int> {
        .init(.subqueryCount(node))
    }
}

// MARK: Keypath Collection Aggregates

/**
 You can use only use aggregates in numeric types where the root keypath is a collection.
 ```swift
 let results = realm.objects(Person.self).query {
    !$0.dogs.age.avg >= 0
 }
 ```
 Where `dogs` is an array of objects.
 */
extension Query where T: _HasPersistedType, T.PersistedType: _QueryNumeric {
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

public extension Query where T: OptionalProtocol, T.Wrapped: EmbeddedObject {
    /**
    Use `geoWithin` function to filter objects whose location points lie within a certain area,
    using a Geospatial shape (`GeoBox`, `GeoPolygon` or `GeoCircle`).

     - note: There is no dedicated type to store Geospatial points, instead points should be stored as
     [GeoJson-shaped](https://www.mongodb.com/docs/manual/reference/geojson/)
     embedded object. Geospatial queries (`geoWithin`) can only be executed
     in such a type of objects and will throw otherwise.
     - see: `GeoPoint`
    */
    func geoWithin<U: RLMGeospatial>(_ value: U) -> Query<Bool> {
        .init(.geoWithin(node, .constant(value)))
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
extension Optional: _QueryNumeric where Wrapped: _Persistable, Wrapped.PersistedType: _QueryNumeric { }

/// Tag protocol for all types that are compatible with `String`.
public protocol _QueryString: _QueryBinary { }
extension String: _QueryString { }
extension Optional: _QueryString where Wrapped: _Persistable, Wrapped.PersistedType: _QueryString { }

/// Tag protocol for all types that are compatible with `Binary`.
public protocol _QueryBinary { }
extension Data: _QueryBinary { }
extension Optional: _QueryBinary where Wrapped: _Persistable, Wrapped.PersistedType: _QueryBinary { }

// MARK: QueryNode -

private indirect enum QueryNode {
    enum Operator: String {
        case or = "||"
        case and = "&&"
        case equal = "=="
        case notEqual = "!="
        case lessThan = "<"
        case lessThanEqual = "<="
        case greaterThan = ">"
        case greaterThanEqual = ">="
        case `in` = "IN"
        case contains = "CONTAINS"
        case beginsWith = "BEGINSWITH"
        case endsWith = "ENDSWITH"
        case like = "LIKE"
    }

    case not(_ child: QueryNode)
    case constant(_ value: Any?)

    case keyPath(_ value: [String], options: KeyPathOptions)

    case comparison(operator: Operator, _ lhs: QueryNode, _ rhs: QueryNode, options: StringOptions)
    case between(_ lhs: QueryNode, lowerBound: QueryNode, upperBound: QueryNode)

    case subqueryCount(_ child: QueryNode)
    case mapSubscript(_ keyPath: QueryNode, key: Any)
    case mapAnySubscripts(_ keyPath: QueryNode, keys: [CollectionSubscript])
    case geoWithin(_ keyPath: QueryNode, _ value: QueryNode)
}

private enum CollectionSubscript {
    case index(Int)
    case key(String)
    case all
}

private func buildPredicate(_ root: QueryNode, subqueryCount: Int = 0) -> (String, [Any]) {
    let formatStr = NSMutableString()
    let arguments = NSMutableArray()
    var subqueryCounter = subqueryCount

    func buildExpression(_ lhs: QueryNode,
                         _ op: String,
                         _ rhs: QueryNode,
                         prefix: String? = nil) {

        if case let .keyPath(_, lhsOptions) = lhs,
           case let .keyPath(_, rhsOptions) = rhs,
           lhsOptions.contains(.isCollection), rhsOptions.contains(.isCollection) {
            throwRealmException("Comparing two collection columns is not permitted.")
        }
        formatStr.append("(")
        if let prefix = prefix {
            formatStr.append(prefix)
        }
        build(lhs)
        formatStr.append(" \(op) ")
        build(rhs)
        formatStr.append(")")
    }

    func buildCompoundExpression(_ lhs: QueryNode,
                                 _ op: String,
                                 _ rhs: QueryNode,
                                 prefix: String? = nil) {
        if let prefix = prefix {
            formatStr.append(prefix)
        }
        formatStr.append("(")
        build(lhs, isNewNode: true)
        formatStr.append(" \(op) ")
        build(rhs, isNewNode: true)
        formatStr.append(")")
    }

    func buildBetween(_ lowerBound: QueryNode, _ upperBound: QueryNode) {
        formatStr.append(" BETWEEN {")
        build(lowerBound)
        formatStr.append(", ")
        build(upperBound)
        formatStr.append("}")
    }

    func buildBool(_ node: QueryNode, isNot: Bool = false) {
        if case let .keyPath(kp, _) = node {
            formatStr.append(kp.joined(separator: "."))
            formatStr.append(" == \(isNot ? "false" : "true")")
        }
    }

    func strOptions(_ options: StringOptions) -> String {
        if options == [] {
            return ""
        }
        return "[\(options.contains(.caseInsensitive) ? "c" : "")\(options.contains(.diacriticInsensitive) ? "d" : "")]"
    }

    func build(_ node: QueryNode, prefix: String? = nil, isNewNode: Bool = false) {
        switch node {
        case .constant(let value):
            formatStr.append("%@")
            arguments.add(value ?? NSNull())
        case .keyPath(let kp, let options):
            if isNewNode {
                buildBool(node)
                return
            }
            if options.contains(.requiresAny) {
                formatStr.append("ANY ")
            }

            formatStr.append(kp.joined(separator: "."))
        case .not(let child):
            if case .keyPath = child,
               isNewNode {
                buildBool(child, isNot: true)
                return
            }
            build(child, prefix: "NOT ")
        case .comparison(operator: let op, let lhs, let rhs, let options):
            switch op {
            case .and, .or:
                buildCompoundExpression(lhs, op.rawValue, rhs, prefix: prefix)
            default:
                buildExpression(lhs, "\(op.rawValue)\(strOptions(options))", rhs, prefix: prefix)
            }
        case .between(let lhs, let lowerBound, let upperBound):
            formatStr.append("(")
            build(lhs)
            buildBetween(lowerBound, upperBound)
            formatStr.append(")")
        case .subqueryCount(let inner):
            subqueryCounter += 1
            let (collectionName, node) = SubqueryRewriter.rewrite(inner, subqueryCounter)
            formatStr.append("SUBQUERY(\(collectionName), $col\(subqueryCounter), ")
            build(node)
            formatStr.append(").@count")
        case .mapSubscript(let keyPath, let key):
            build(keyPath)
            formatStr.append("[%@]")
            arguments.add(key)
        case .mapAnySubscripts(let keyPath, let keys):
            build(keyPath)
            for key in keys {
                switch key {
                case .index(let index):
                    formatStr.append("[%@]")
                    arguments.add(index)
                case .key(let key):
                    formatStr.append("[%@]")
                    arguments.add(key)
                case .all:
                    formatStr.append("[%K]")
                    arguments.add("#any")
                }
            }
        case .geoWithin(let keyPath, let value):
            buildExpression(keyPath, QueryNode.Operator.in.rawValue, value, prefix: nil)
        }
    }
    build(root, isNewNode: true)
    return (formatStr as String, (arguments as! [Any]))
}

private struct KeyPathOptions: OptionSet {
    let rawValue: Int8
    init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    static let isCollection = KeyPathOptions(rawValue: 1)
    static let requiresAny = KeyPathOptions(rawValue: 2)
}

private struct SubqueryRewriter {
    private var collectionName: String?
    private var counter: Int
    private mutating func rewrite(_ node: QueryNode) -> QueryNode {
        switch node {
        case .keyPath(let kp, let options):
            if options.contains(.isCollection) {
                precondition(kp.count > 0)
                collectionName = kp[0]
                var copy = kp
                copy[0] = "$col\(counter)"
                return .keyPath(copy, options: [.isCollection])
            }
            return node
        case .not(let child):
            return .not(rewrite(child))
        case .comparison(operator: let op, let lhs, let rhs, options: let options):
            return .comparison(operator: op, rewrite(lhs), rewrite(rhs), options: options)
        case .between(let lhs, let lowerBound, let upperBound):
            return .between(rewrite(lhs), lowerBound: rewrite(lowerBound), upperBound: rewrite(upperBound))
        case .subqueryCount(let inner):
            return .subqueryCount(inner)
        case .constant:
            return node
        case .mapSubscript:
            throwRealmException("Subqueries do not support map subscripts.")
        case .mapAnySubscripts:
            throwRealmException("Subqueries do not support AnyRealmValue subscripts.")
        case .geoWithin(let keyPath, let value):
            return .geoWithin(keyPath, value)
        }
    }

    static fileprivate func rewrite(_ node: QueryNode, _ counter: Int) -> (String, QueryNode) {
        var rewriter = SubqueryRewriter(counter: counter)
        let rewritten = rewriter.rewrite(node)
        guard let collectionName = rewriter.collectionName else {
            throwRealmException("Subqueries must contain a keypath starting with a collection.")
        }
        return (collectionName, rewritten)
    }
}
