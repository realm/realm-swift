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
    enum Comparision: String {
        case equal = "=="
        case notEqual = "!="
        case lessThan = "<"
        case greaterThan = ">"
        case greaterThenOrEqual = ">="
        case lessThanOrEqual = "<="
    }

    case keyPath(String)
    case comparison(Comparision)
    case rhs(_RealmSchemaDiscoverable)
}

@dynamicMemberLookup
public struct Query<T: _Persistable> {

    internal var tokens: [QueryExpression] = []

    init() { }
    init(expression: [QueryExpression]) {
        tokens = expression
    }

    // MARK: Comparable

    public static func == <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Comparable {
        var tokensCopy = lhs.tokens
        tokensCopy.append(.comparison(.equal))
        tokensCopy.append(.rhs(rhs))
        return Query(expression: tokensCopy)
    }

    public static func != <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Comparable {
        fatalError()
    }

    // MARK: Numerics

    public static func > <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Numeric {
        fatalError()
    }

    public static func >= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Numeric {
        fatalError()
    }

    public static func < <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Numeric {
        fatalError()
    }

    public static func <= <V>(_ lhs: Query<V>, _ rhs: V) -> Query where V: _Persistable, V: Numeric {
        fatalError()
    }

    // MARK: Compund

    public static func && (_ lhs: Query, _ rhs: Query) -> Query {
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
            if case let .comparison(op) = token {
                predicateString += " \(op.rawValue)"
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

            if case let .rhs(v) = token {
                predicateString += " %@"
                arguments.append(NSString(string: v as! String))
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

extension Query where T == String {
    public func matches<V>(_ value: String, options: Set<StringOptions>? = nil) -> Query<V> {
        fatalError()
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

extension Results where Element: Object {
    public func filter(_ query: ((Query<Element>) -> Query<Element>)) -> Results<Element> {
        let predicate = query(Query()).predicate
        return filter(predicate)
    }
}
