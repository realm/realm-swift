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

public enum StringOptions {
    case caseInsensitive
    case diacriticInsensitive
}

internal enum QueryExpression {
    enum BasicComparision: String {
        case equal = "==" // TODO: @"string1 ==[c] string1"
        case notEqual = "!="
        case lessThan = "<"
        case greaterThan = ">"
        case greaterThenOrEqual = ">="
        case lessThanOrEqual = "<="
        case not = "NOT"
    }

    enum Comparision {
        case between(_RealmSchemaDiscoverable, _RealmSchemaDiscoverable) // Must be numeric
        case contains(_RealmSchemaDiscoverable) // `IN` operator.
    }

    enum Compound: String {
        case and = "&&"
        case or = "||"
    }

    enum StringSearch {
        case contains(String, Set<StringOptions>?)
        case like(String, Set<StringOptions>?)
        case beginsWith(String, Set<StringOptions>?)
        case endsWith(String, Set<StringOptions>?)
    }

    case keyPath(name: String, isCollection: Bool = false)
    case comparison(Comparision)
    case basicComparison(BasicComparision)
    case compound(Compound)
    case rhs(_RealmSchemaDiscoverable?)
    case subquery(String, String, [Any])
    case stringSearch(StringSearch)
}

@dynamicMemberLookup
public struct Query<T: _Persistable> {

    internal var tokens: [QueryExpression] = []

    init() { }
    init(expression: [QueryExpression]) {
        tokens = expression
    }

    // MARK: NOT

    public static prefix func ! (_ rhs: Query) -> Query {
        var tokensCopy = rhs.tokens
        tokensCopy.insert(.basicComparison(.not), at: 0)
        return Query(expression: tokensCopy)
    }

    // MARK: Comparable

    public static func == <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Comparable {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.equal))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    public static func == <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: OptionalProtocol, V.Wrapped: _Persistable {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.equal))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    public static func != <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Comparable {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.notEqual))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    public static func != <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: OptionalProtocol, V.Wrapped: _Persistable {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.notEqual))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    // MARK: Numerics

    public static func > <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.greaterThan))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    public static func >= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.greaterThenOrEqual))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    public static func < <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.lessThan))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    public static func <= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _QueryNumeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.lessThanOrEqual))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    // MARK: Compound

    public static func && (_ lhs: Query, _ rhs: Query) -> Query {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.compound(.and))
        tokensCopy.append(contentsOf: rhs.tokens)
        return Query(expression: tokensCopy)
    }

    public static func || (_ lhs: Query, _ rhs: Query) -> Query {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.compound(.or))
        tokensCopy.append(contentsOf: rhs.tokens)
        return Query(expression: tokensCopy)
    }

    // MARK: Subquery

    public func subquery<V: RealmCollection>(_ keyPath: KeyPath<T, V>, _ block: ((Query<V>) -> Query<Int>)) -> Query<Int> where T: ObjectBase {
        var tokensCopy = tokens
        let name = _name(for: keyPath)
        let query = block(Query<V>(expression: tokensCopy))
        let queryStr = query.constructPredicate(true)
        tokensCopy.append(.subquery(name, queryStr.0, queryStr.1))
        return Query<Int>(expression: tokensCopy)
    }

    public subscript<V>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        let name = _name(for: member)
        var tokensCopy = tokens
        tokensCopy.append(.keyPath(name: name))
        return Query<V>(expression: tokensCopy)
    }

    public subscript<V: RealmCollectionBase>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        let name = _name(for: member)
        var tokensCopy = tokens
        tokensCopy.append(.keyPath(name: name, isCollection: true))
        return Query<V>(expression: tokensCopy)
    }

    internal func constructPredicate(_ isSubquery: Bool = false) -> (String, [Any]) {
        var predicateString: [String] = []
        var arguments: [Any] = []

        for (idx, token) in tokens.enumerated() {
            if case let .basicComparison(op) = token {
                if idx == 0 {
                    predicateString.append(op.rawValue)
                } else {
                    predicateString.append(" \(op.rawValue)")
                }
            }

            if case let .comparison(op) = token, case let .between(low, high) = op {
                predicateString.append(" BETWEEN {%@, %@}")
                arguments.append(contentsOf: [low, high])
            }

            if case let .comparison(op) = token, case let .contains(val) = op {
                predicateString.insert(" %@ IN ", at: predicateString.count-1)
                arguments.append(val)
            }

            if case let .compound(comp) = token {
                predicateString.append(" \(comp.rawValue) ")
            }

            if case let .keyPath(name, isCollection) = token {
                // For the non verbose subqery
                if isCollection && isSubquery {
                    predicateString.append("$obj")
                    continue
                }
                // Anything below the verbose subquery uses
                var needsDot = false
                if idx > 0, case .keyPath = tokens[idx-1] {
                    needsDot = true
                }
                // This is not the start of the string, and not part of a previous keyPath
                // So insert a space.
                if !predicateString.isEmpty && !needsDot {
                    predicateString.append(" ")
                }
                if needsDot {
                    predicateString.append(".")
                }
                if isSubquery && !needsDot {
                    predicateString.append("$obj.")
                }
                predicateString.append("\(name)")
            }

            if case let .stringSearch(s) = token {
                func optionsStr(_ options: Set<StringOptions>?) -> String {
                    guard let o = options else {
                        return ""
                    }
                    var str = "["
                    if o.contains(.caseInsensitive) {
                        str += "c"
                    }
                    if o.contains(.diacriticInsensitive) {
                        str += "d"
                    }
                    str += "]"
                    return str
                }
                switch s {
                    case let .contains(str, options):
                        predicateString.append(" CONTAINS\(optionsStr(options)) %@")
                        arguments.append(str)
                        break
                    case let .like(str, options):
                        predicateString.append(" LIKE\(optionsStr(options)) %@")
                        arguments.append(str)
                        break
                    case let .beginsWith(str, options):
                        predicateString.append(" BEGINSWITH\(optionsStr(options)) %@")
                        arguments.append(str)
                        break
                    case let .endsWith(str, options):
                        predicateString.append(" ENDSWITH\(optionsStr(options)) %@")
                        arguments.append(str)
                        break
                }
            }

            if case let .rhs(v) = token {
                predicateString.append(" %@")
                arguments.append(v.objCValue)
            }

            if case let .subquery(col, str, args) = token {
                predicateString.append("SUBQUERY(\(col), $obj, \(str)).@count")
                arguments.append(contentsOf: args)
            }
        }

        return (predicateString.joined(), arguments)
    }

    internal var predicate: NSPredicate {
        let predicate = constructPredicate()
        return NSPredicate(format: predicate.0, argumentArray: predicate.1)
    }
}

// MARK: OptionalProtocol

extension Query where T: OptionalProtocol {
    public subscript<V>(dynamicMember member: KeyPath<T.Wrapped, V>) -> Query<Optional<T.Wrapped>> {
        fatalError() // Can we reach this?
        //return Query<V>(expression: tokens)
    }

    public subscript<V>(dynamicMember member: KeyPath<T.Wrapped, V>) -> Query<V> where T.Wrapped: ObjectBase {
        let name = _name(for: member)
        var tokensCopy = tokens
        tokensCopy.append(.keyPath(name: name))
        return Query<V>(expression: tokensCopy)
    }
}

// MARK: RealmCollection

extension Query where T: RealmCollection {
    public subscript<V>(dynamicMember member: KeyPath<T.Element, V>) -> Query<V> where T.Element: ObjectBase {
        let name = _name(for: member)
        var tokensCopy = tokens
        tokensCopy.append(.keyPath(name: name))
        return Query<V>(expression: tokensCopy)
    }
}

// MARK: RealmKeyedCollection

extension Query where T: RealmKeyedCollection {
    public subscript<V>(dynamicMember member: KeyPath<T.Value, V>) -> Query<V> where T.Value: ObjectBase {
        let name = _name(for: member)
        var tokensCopy = tokens
        tokensCopy.append(.keyPath(name: name))
        return Query<V>(expression: tokensCopy)
    }
}

// MARK: String

extension Query where T == String {
    public func like<V>(_ value: String, caseInsensitive: Bool = false) -> Query<V> {
        var tokensCopy = tokens
        tokensCopy.append(.stringSearch(.like(value, caseInsensitive ? [.caseInsensitive] : [])))
        return Query<V>(expression: tokensCopy)
    }

    public func contains<V>(_ value: String, options: Set<StringOptions>? = nil) -> Query<V> {
        var tokensCopy = tokens
        tokensCopy.append(.stringSearch(.contains(value, options)))
        return Query<V>(expression: tokensCopy)
    }

    public func starts<V>(with value: String, options: Set<StringOptions>? = nil) -> Query<V> {
        var tokensCopy = tokens
        tokensCopy.append(.stringSearch(.beginsWith(value, options)))
        return Query<V>(expression: tokensCopy)
    }

    public func ends<V>(with value: String, options: Set<StringOptions>? = nil) -> Query<V> {
        var tokensCopy = tokens
        tokensCopy.append(.stringSearch(.endsWith(value, options)))
        return Query<V>(expression: tokensCopy)
    }
}

// MARK: PersistableEnum

extension Query where T: PersistableEnum, T.RawValue: _Persistable {
    public static func == <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.equal))
        tokensCopy.append(.rhs(rhs.rawValue))
        return Query<V>(expression: tokensCopy)
    }

    public static func != <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.notEqual))
        tokensCopy.append(.rhs(rhs.rawValue))
        return Query<V>(expression: tokensCopy)
    }

    public static func > <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.greaterThan))
        tokensCopy.append(.rhs(rhs.rawValue))
        return Query<V>(expression: tokensCopy)
    }

    public static func >= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.greaterThenOrEqual))
        tokensCopy.append(.rhs(rhs.rawValue))
        return Query<V>(expression: tokensCopy)
    }

    public static func < <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.lessThan))
        tokensCopy.append(.rhs(rhs.rawValue))
        return Query<V>(expression: tokensCopy)
    }

    public static func <= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> where T.RawValue: _QueryNumeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.lessThanOrEqual))
        tokensCopy.append(.rhs(rhs.rawValue))
        return Query<V>(expression: tokensCopy)
    }
}

extension Query where T: OptionalProtocol, T.Wrapped: PersistableEnum, T.Wrapped.RawValue: _QueryNumeric {
    public static func > <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.greaterThan))
        if case Optional<Any>.none = rhs as Any {
            tokensCopy.append(.rhs(nil))
        } else {
            tokensCopy.append(.rhs(rhs._rlmInferWrappedType().rawValue))
        }
        return Query<V>(expression: tokensCopy)
    }

    public static func >= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.greaterThenOrEqual))
        if case Optional<Any>.none = rhs as Any {
            tokensCopy.append(.rhs(nil))
        } else {
            tokensCopy.append(.rhs(rhs._rlmInferWrappedType().rawValue))
        }
        return Query<V>(expression: tokensCopy)
    }

    public static func < <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.lessThan))
        if case Optional<Any>.none = rhs as Any {
            tokensCopy.append(.rhs(nil))
        } else {
            tokensCopy.append(.rhs(rhs._rlmInferWrappedType().rawValue))
        }
        return Query<V>(expression: tokensCopy)
    }

    public static func <= <V>(_ lhs: Query<T>, _ rhs: T) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.lessThanOrEqual))
        if case Optional<Any>.none = rhs as Any {
            tokensCopy.append(.rhs(nil))
        } else {
            tokensCopy.append(.rhs(rhs._rlmInferWrappedType().rawValue))
        }
        return Query<V>(expression: tokensCopy)
    }
}

// MARK: Data

extension Query where T == Data {
    public static func == <V>(_ lhs: Query<Data>, _ rhs: Data) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.equal))
        tokensCopy.append(.rhs(rhs))
        return Query<V>(expression: tokensCopy)
    }

    public static func != <V>(_ lhs: Query<Data>, _ rhs: Data) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.notEqual))
        tokensCopy.append(.rhs(rhs))
        return Query<V>(expression: tokensCopy)
    }
}

// MARK: Date

extension Query where T == Date {
    public static func > <V>(_ lhs: Query<Date>, _ rhs: Date) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.greaterThan))
        tokensCopy.append(.rhs(rhs))
        return Query<V>(expression: tokensCopy)
    }
}

// MARK: UUID

extension Query where T == UUID {
    public static func == <V>(_ lhs: Query<UUID>, _ rhs: UUID) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.equal))
        tokensCopy.append(.rhs(rhs))
        return Query<V>(expression: tokensCopy)
    }

    public static func != <V>(_ lhs: Query<UUID>, _ rhs: UUID) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.notEqual))
        tokensCopy.append(.rhs(rhs))
        return Query<V>(expression: tokensCopy)
    }
}

// MARK: Bool

extension Query where T == Bool {

    public static func == <V>(_ lhs: Query<Bool>, _ rhs: Bool) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.equal))
        tokensCopy.append(.rhs(rhs))
        return Query<V>(expression: tokensCopy)
    }

    public static func != <V>(_ lhs: Query<Bool>, _ rhs: Bool) -> Query<V> {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.notEqual))
        tokensCopy.append(.rhs(rhs))
        return Query<V>(expression: tokensCopy)
    }

    public func subqueryCount() -> Query<Int> {
        let collections = Set(tokens.filter {
            if case let .keyPath(_, isCollection) = $0 {
                return isCollection ? true : false
            }
            return false
        }.map { kp -> String in
            if case let .keyPath(name, _) = kp {
                return name
            }
            fatalError()
        })

        if collections.count > 1 {
            throwRealmException("Subquery predicates will only work on one collection at a time, split your query up.")
        }
        let queryStr = constructPredicate(true)
        let newTokens: [QueryExpression] = [.subquery(collections.first!, queryStr.0, queryStr.1)]
        return Query<Int>(expression: newTokens)
    }
}

extension Query where T: RealmCollection, T.Element: _Persistable {
    public func between<V>(_ low: T.Element, _ high: T.Element) -> Query<V> {
        fatalError()
    }

    public func contains<V>(_ value: T.Element) -> Query<V> {
        var tokensCopy = tokens
        tokensCopy.append(.comparison(.contains(value)))
        return Query<V>(expression: tokensCopy)
    }
}

extension Query where T: RealmKeyedCollection, T.Key: _Persistable , T.Value: _Persistable {
    public func between<V>(_ low: T.Value, _ high: T.Value) -> Query<V> {
        fatalError()
    }

    public func contains<V>(_ value: T.Value) -> Query<V> {
        var tokensCopy = tokens
        tokensCopy.append(.comparison(.contains(value)))
        return Query<V>(expression: tokensCopy)
    }

    public var keys: Query<T.Key> {
        return Query<T.Key>(expression: tokens)
    }

    public var values: Query<T.Value> {
        return Query<T.Value>(expression: tokens)
    }

    public subscript(member: T.Key) -> Query<T.Value> {
        // mapCol["Bar"] -> mapCol.@allKeys == 'Bar'
        return Query<T.Value>(expression: tokens)
    }
}

extension Query where T: Numeric, T: _RealmSchemaDiscoverable {
    public func between<V>(_ low: T, _ high: T) -> Query<V> {
        var tokensCopy = tokens
        tokensCopy.append(.comparison(.between(low, high)))
        return Query<V>(expression: tokensCopy)
    }

    public func contains<V>(_ range: Range<T>) -> Query<V> {
        var tokensCopy = tokens
        //tokensCopy.append(.comparison(.between(low, high)))
        return Query<V>(expression: tokensCopy)
    }

    public func contains<V>(_ range: ClosedRange<T>) -> Query<V> {
        var tokensCopy = tokens
        tokensCopy.append(.comparison(.between(range.lowerBound, range.upperBound)))
        return Query<V>(expression: tokensCopy)
    }
}

extension Results where Element: Object {
    public func query(_ query: ((Query<Element>) -> Query<Element>)) -> Results<Element> {
        let predicate = query(Query()).predicate
        return filter(predicate)
    }
}

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
extension Optional: _QueryNumeric where Wrapped: _QueryNumeric { }
