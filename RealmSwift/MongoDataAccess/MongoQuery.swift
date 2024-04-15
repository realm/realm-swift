//
//  MongoQuery.swift
//  RealmSwift
//
//  Created by Jason Flax on 3/7/24.
//  Copyright © 2024 Realm. All rights reserved.
//

import Foundation

struct MongoQuery {
    class Node {
        var keyPath: String?
        var node: Node?
    }
}

package func buildFilter(_ root: QueryNode, subqueryCount: Int = 0) throws -> [String: Any] {
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
        fatalError()
    }
    
    func buildCompoundExpression(_ lhs: QueryNode,
                                 _ op: QueryNode.Operator,
                                 _ rhs: QueryNode,
                                 document: NSMutableDictionary) {
        switch op {
        case .and:
            document["$and"] = [build(lhs, root: NSMutableDictionary()),
                                build(rhs, root: NSMutableDictionary())]
        case .or:
            document["$or"] = [build(lhs, root: NSMutableDictionary()),
                               build(rhs, root: NSMutableDictionary())]
        default:
            throwRealmException("Unsupported operator \(op) for compound query expression")
        }
    }
    
    func buildBetween(_ lowerBound: QueryNode, _ upperBound: QueryNode) {
        //        formatStr.append(" BETWEEN {")
        //        build(lowerBound)
        //        formatStr.append(", ")
        //        build(upperBound)
        //        formatStr.append("}")
    }
    
    func buildBool(_ node: QueryNode,
                   document: NSMutableDictionary,
                   isNot: Bool = false) {
        if case let .keyPath(kp, _) = node {
            document[kp.joined(separator: ".")] = ["$eq": !isNot]
        }
    }
    
    func strOptions(_ options: StringOptions) -> String {
        if options == [] {
            return ""
        }
        return "[\(options.contains(.caseInsensitive) ? "c" : "")\(options.contains(.diacriticInsensitive) ? "d" : "")]"
    }
    
    func build(_ node: QueryNode, root: NSMutableDictionary, isNewNode: Bool = false) -> NSDictionary {
        switch node {
        case .constant(let value):
            fatalError()
            //            formatStr.append("%@")
            //            arguments.add(value ?? NSNull())
        case .keyPath(let kp, let options):
            if isNewNode {
                buildBool(node, document: root)
                return root
            }
            fatalError()
            //            if options.contains(.requiresAny) {
            //                formatStr.append("ANY ")
            //            }
            //            formatStr.append(kp.joined(separator: "."))
        case .not(let child):
            if case .keyPath = child,
               isNewNode {
                buildBool(child, document: root, isNot: true)
                return root
            }
            let built = build(child, root: NSMutableDictionary())
            root[built.allKeys.first!] = ["$not": built.allValues.first]
//            root["$not"] = build(child, root: NSMutableDictionary())
        case .comparison(operator: let op, let lhs, let rhs, let options):
            func unwrapComparison(lhs: QueryNode, rhs: QueryNode) -> (String, Any?) {
                if case let .keyPath(kp, _) = lhs,
                   case let .constant(value) = rhs {
                    guard !(kp.last?.starts(with: "@") ?? false) else {
                        throwRealmException("Aggregation operation \(kp.last ?? "<unknwon>") not currently supported in Query translator")
                    }
                    return (kp.joined(separator: "."), value)
                } else if case let .keyPath(kp, _) = rhs,
                          case let .constant(value) = lhs {
                    guard !(kp.last?.starts(with: "@") ?? false) else {
                        fatalError("Aggregation operation \(kp.last ?? "<unknwon>") not currently supported in Query translator")
                    }
                    return (kp.joined(separator: "."), value)
                } else {
                    throwRealmException("Could not read keyPath from comparison query")
                }
            }
            switch op {
            case .and, .or:
                buildCompoundExpression(lhs, op, rhs, document: root)
            case .contains:
                let (kp, value) = unwrapComparison(lhs: lhs, rhs: rhs)
                if let value = value as? String {
                    root[kp] = ["$regex": value]
                } else {
                    fatalError()
                }
            case .in:
                let (kp, value) = unwrapComparison(lhs: lhs, rhs: rhs)
                if let value = value as? any Collection {
                    root[kp] = ["$in": value]
                } else {
                    root[kp] = ["$elemMatch": ["$eq": value]]
                }
            default:
                let (kp, value) = unwrapComparison(lhs: lhs, rhs: rhs)
                switch op {
                case .equal:
                    root[kp] = ["$eq": value]
                case .notEqual:
                    guard case let .constant(value) = rhs else {
                        fatalError()
                    }
                    root[kp] = ["$ne": value]
                case .lessThan:
                    guard case let .constant(value) = rhs else {
                        fatalError()
                    }
                    root[kp] = ["$lt": value]
                case .lessThanEqual:
                    guard case let .constant(value) = rhs else {
                        fatalError()
                    }
                    root[kp] = ["$lte": value]
                case .greaterThan:
                    guard case let .constant(value) = rhs else {
                        fatalError()
                    }
                    root[kp] = ["$gt": value]
                case .greaterThanEqual:
                    guard case let .constant(value) = rhs else {
                        fatalError()
                    }
                    root[kp] = ["$gte": value]
                case .contains:
                    root[kp] = ["$elemMatch": [ value ]]
                case .in:
                    guard case let .constant(value) = rhs else {
                        fatalError()
                    }
                    if let value = value as? any Collection {
                        root[kp] = value.map {
                            [
                                "$eq": $0
                            ]
                        }
                    } else {
                        root[kp] = [
                            "$elemMatch": [
                                "$eq": value
                            ]
                        ]
                    }
                default:
                    throwRealmException("Invalid operator \(op) for comparison query expression")
                }
                //                buildExpression(lhs, "\(op.rawValue)\(strOptions(options))", rhs, prefix: prefix)
            }
        case .between(let lhs, let lowerBound, let upperBound):
            guard case let .keyPath(kp, options) = lhs,
                  case .constant(let lowerBound) = lowerBound,
                  case .constant(let upperBound) = upperBound else {
                throwRealmException("Invalid query BETWEEN: \(lhs)")
            }
            root[kp.joined(separator: ".")] = [
                "$gte": lowerBound,
                "$lt": upperBound
            ]
        case .subqueryCount(_):
            throwRealmException("Subqueries not supported")
        case .mapSubscript(_, _):
            fatalError()
            //            build(keyPath)
            //            formatStr.append("[%@]")
            //            arguments.add(key)
        case .geoWithin(let keyPath, let value):
            buildExpression(keyPath, QueryNode.Operator.in.rawValue, value, prefix: nil)
            fatalError()
        }
        return root
    }
    return build(root, root: NSMutableDictionary(), isNewNode: true) as! [String: Any]
}
