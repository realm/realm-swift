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

internal enum QueryExpression {
    enum BasicComparision: String {
        case equal = "=="
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
        case matches(String, Set<StringOptions>?) // NOT SUPPORTED
        case contains(String, Set<StringOptions>?)
        case like(String, Set<StringOptions>?)

    }

    case keyPath(String)
    case comparison(Comparision)
    case basicComparison(BasicComparision)
    case compound(Compound)
    case rhs(_RealmSchemaDiscoverable)
    case subquery
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

    public static func != <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Comparable {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.notEqual))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    // MARK: Numerics

    public static func > <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Numeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.greaterThan))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    public static func >= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Numeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.greaterThenOrEqual))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    public static func < <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Numeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.lessThan))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    public static func <= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Numeric {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.basicComparison(.lessThanOrEqual))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    // MARK: Compund

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

    public func subquery<V: RealmCollection>(_ keyPath: KeyPath<T, V>, _ block: ((Query<V>) -> Query)) -> Query<Int> {
        fatalError()
    }

    public subscript<V>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase {
        let name = _name(for: member)
        var tokensCopy = tokens
        tokensCopy.append(.keyPath(name))
        return Query<V>(expression: tokensCopy)
    }

    internal func constructPredicate() -> NSPredicate {
        var predicateString = ""
        var arguments: [Any] = []

        for (idx, token) in tokens.enumerated() {
            if case let .basicComparison(op) = token {
                if idx == 0 {
                    predicateString += op.rawValue
                } else {
                    predicateString += " \(op.rawValue)"
                }
            }

            if case let .comparison(op) = token, case let .between(low, high) = op {
                predicateString += " BETWEEN {\(low), \(high)}"
            }

            if case let .compound(comp) = token {
                predicateString += " \(comp.rawValue) "
            }

            if case let .keyPath(kp) = token {
                var needsDot = false
                if idx > 0, case .keyPath(_) = tokens[idx-1] {
                    needsDot = true
                }
                // This is not the start of the string, and not part of a previous keyPath
                // So insert a space.
                if !predicateString.isEmpty && !needsDot {
                    predicateString += " "
                }
                if needsDot {
                    predicateString += "."
                }
                predicateString += "\(kp)"
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
                    case let .matches(str, options):
                        predicateString += " MATCHES\(optionsStr(options)) %@"
                        arguments.append(str)
                        break
                    case let .contains(str, options):
                        predicateString += " CONTAINS\(optionsStr(options)) %@"
                        arguments.append(str)
                        break
                    default:
                        fatalError()
                }
            }

            if case let .rhs(v) = token {
                predicateString += " %@"
                arguments.append(v)
            }
        }

        return NSPredicate(format: predicateString, argumentArray: arguments)
    }

    internal var predicate: NSPredicate {
        constructPredicate()
    }
}

public enum StringOptions {
    case caseInsensitive
    case diacriticInsensitive
}

extension Query where T: OptionalProtocol {
    public subscript<V>(dynamicMember member: KeyPath<T.Wrapped, V>) -> Query<V> {
        fatalError() // Can we reach this?
        //return Query<V>(expression: tokens)
    }

    public subscript<V>(dynamicMember member: KeyPath<T.Wrapped, V>) -> Query<V> where T.Wrapped: ObjectBase {
        let name = _name(for: member)
        var tokensCopy = tokens
        tokensCopy.append(.keyPath(name))
        return Query<V>(expression: tokensCopy)
    }
}

extension Query where T: RealmCollection {
    public subscript<V>(dynamicMember member: KeyPath<T.Element, V>) -> Query<V> where T.Element: ObjectBase {
        let name = _name(for: member)
        var tokensCopy = tokens
        tokensCopy.append(.keyPath(name))
        return Query<V>(expression: tokensCopy)
    }
}

extension Query where T == String {
    public func matches<V>(_ value: String, options: Set<StringOptions>? = nil) -> Query<V> {
        fatalError("Not supported")
//        var tokensCopy = tokens
//        tokensCopy.append(.stringSearch(.matches(value, options)))
//        return Query<V>(expression: tokensCopy)
    }

    public func contains<V>(_ value: String, options: Set<StringOptions>? = nil) -> Query<V> {
        var tokensCopy = tokens
        tokensCopy.append(.stringSearch(.contains(value, options)))
        return Query<V>(expression: tokensCopy)
    }
}

extension Query where T: RealmCollection, T.Element: _Persistable {

    public func between<V>(_ low: T.Element, _ high: T.Element) -> Query<V> {
        fatalError()
    }

    public var first: Query<T.Element> {
        var tokensCopy = tokens
//        tokensCopy.append("[FIRST]")
        return Query<T.Element>(expression: tokensCopy)
    }

    public var count: Query<Int> {
        fatalError()
    }
}

/// For subquerys. An expression wrapped in parentheses will produce a bool
/// so to create a valid subquery with `.count` we need to add this extension.
extension Query where T == Bool {
    public var count: Query<Int> {
        var tokensCopy = tokens
        tokensCopy.append(.subquery)
        return Query<Int>(expression: tokensCopy)
    }
}

extension Query where T: Numeric, T: _RealmSchemaDiscoverable {
    public func between<V>(_ low: T, _ high: T) -> Query<V> {
        var tokensCopy = tokens
        tokensCopy.append(.comparison(.between(low, high)))
        return Query<V>(expression: tokensCopy)
    }
}

extension Results where Element: Object {
    public func query(_ query: ((Query<Element>) -> Query<Element>)) -> Results<Element> {
        let predicate = query(Query()).predicate
        return filter(predicate)
    }
}
