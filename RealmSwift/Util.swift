////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#if BUILDING_REALM_SWIFT_TESTS
import RealmSwift
#endif

// MARK: Internal Helpers

// Swift 3.1 provides fixits for some of our uses of unsafeBitCast
// to use unsafeDowncast instead, but the bitcast is required.
internal func noWarnUnsafeBitCast<T, U>(_ x: T, to type: U.Type) -> U {
    return unsafeBitCast(x, to: type)
}

/// Given a list of `Any`-typed varargs, unwrap any optionals and
/// replace them with the underlying value or NSNull.
internal func unwrapOptionals(in varargs: [Any]) -> [Any] {
    return varargs.map { arg in
        if let someArg = arg as Any? {
            return someArg
        }
        return NSNull()
    }
}

internal func notFoundToNil(index: UInt) -> Int? {
    if index == UInt(NSNotFound) {
        return nil
    }
    return Int(index)
}

internal func throwRealmException(_ message: String, userInfo: [AnyHashable: Any]? = nil) {
    NSException(name: NSExceptionName(rawValue: RLMExceptionName), reason: message, userInfo: userInfo).raise()
}

internal func throwForNegativeIndex(_ int: Int, parameterName: String = "index") {
    if int < 0 {
        throwRealmException("Cannot pass a negative value for '\(parameterName)'.")
    }
}

internal func gsub(pattern: String, template: String, string: String, error: NSErrorPointer = nil) -> String? {
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    return regex?.stringByReplacingMatches(in: string, options: [],
                                           range: NSRange(location: 0, length: string.utf16.count),
                                           withTemplate: template)
}

internal func cast<U, V>(_ value: U, to: V.Type) -> V {
    if let v = value as? V {
        return v
    }
    return unsafeBitCast(value, to: to)
}

extension Object {
    // Must *only* be used to call Realm Objective-C APIs that are exposed on `RLMObject`
    // but actually operate on `RLMObjectBase`. Do not expose cast value to user.
    internal func unsafeCastToRLMObject() -> RLMObject {
        return unsafeBitCast(self, to: RLMObject.self)
    }
}

// MARK: CustomObjectiveCBridgeable

/// :nodoc:
public func dynamicBridgeCast<T>(fromObjectiveC x: Any) -> T {
    if T.self == DynamicObject.self {
        return unsafeBitCast(x as AnyObject, to: T.self)
    } else if let bridgeableType = T.self as? CustomObjectiveCBridgeable.Type {
        return bridgeableType.bridging(objCValue: x) as! T
    } else {
        return x as! T
    }
}

/// :nodoc:
public func dynamicBridgeCast<T>(fromSwift x: T) -> Any {
    if let x = x as? CustomObjectiveCBridgeable {
        return x.objCValue
    } else {
        return x
    }
}

// Used for conversion from Objective-C types to Swift types
internal protocol CustomObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Self
    var objCValue: Any { get }
}

// FIXME: needed with swift 3.2
// Double isn't though?
extension Float: CustomObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Float {
        return (objCValue as! NSNumber).floatValue
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}

extension Int8: CustomObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Int8 {
        return (objCValue as! NSNumber).int8Value
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Int16: CustomObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Int16 {
        return (objCValue as! NSNumber).int16Value
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Int32: CustomObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Int32 {
        return (objCValue as! NSNumber).int32Value
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Int64: CustomObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Int64 {
        return (objCValue as! NSNumber).int64Value
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Optional: CustomObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Optional {
        if objCValue is NSNull {
            return nil
        } else {
            return .some(dynamicBridgeCast(fromObjectiveC: objCValue))
        }
    }
    var objCValue: Any {
        if let value = self {
            return dynamicBridgeCast(fromSwift: value)
        } else {
            return NSNull()
        }
    }
}

// MARK: AssistedObjectiveCBridgeable

internal protocol AssistedObjectiveCBridgeable {
    static func bridging(from objectiveCValue: Any, with metadata: Any?) -> Self
    var bridged: (objectiveCValue: Any, metadata: Any?) { get }
}
