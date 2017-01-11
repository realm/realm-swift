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

// MARK: Internal Helpers

internal func notFoundToNil(index: UInt) -> Int? {
    if index == UInt(NSNotFound) {
        return nil
    }
    return Int(index)
}

#if swift(>=3.0)

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

extension Object {
    // Must *only* be used to call Realm Objective-C APIs that are exposed on `RLMObject`
    // but actually operate on `RLMObjectBase`. Do not expose cast value to user.
    internal func unsafeCastToRLMObject() -> RLMObject {
        return unsafeBitCast(self, to: RLMObject.self)
    }
}

// MARK: CustomObjectiveCBridgeable

internal func dynamicBridgeCast<T>(fromObjectiveC x: Any) -> T {
    if let BridgeableType = T.self as? CustomObjectiveCBridgeable.Type {
        return BridgeableType.bridging(objCValue: x) as! T
    } else {
        return x as! T
    }
}

internal func dynamicBridgeCast<T>(fromSwift x: T) -> Any {
    if let x = x as? CustomObjectiveCBridgeable {
        return x.objCValue
    } else {
        return x
    }
}

// Used for conversion from Objective-C types to Swift types
internal protocol CustomObjectiveCBridgeable {
    /* FIXME: Remove protocol once SR-2393 bridges all integer types to `NSNumber`
     *        At this point, use `as! [SwiftType]` to cast between. */
    static func bridging(objCValue: Any) -> Self
    var objCValue: Any { get }
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
            return value
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

#else

internal func throwRealmException(message: String, userInfo: [String:AnyObject] = [:]) {
    NSException(name: RLMExceptionName, reason: message, userInfo: userInfo).raise()
}

internal func throwForNegativeIndex(int: Int, parameterName: String = "index") {
    if int < 0 {
        throwRealmException("Cannot pass a negative value for '\(parameterName)'.")
    }
}

internal func gsub(pattern: String, template: String, string: String, error: NSErrorPointer = nil) -> String? {
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    return regex?.stringByReplacingMatchesInString(string, options: [],
                                                   range: NSRange(location: 0, length: string.utf16.count),
                                                   withTemplate: template)
}

extension Object {
    // Must *only* be used to call Realm Objective-C APIs that are exposed on `RLMObject`
    // but actually operate on `RLMObjectBase`. Do not expose cast value to user.
    internal func unsafeCastToRLMObject() -> RLMObject {
        return unsafeBitCast(self, RLMObject.self)
    }
}

// MARK: CustomObjectiveCBridgeable

internal func dynamicBridgeCast<T>(fromObjectiveC x: AnyObject) -> T {
    if let BridgeableType = T.self as? CustomObjectiveCBridgeable.Type {
        return BridgeableType.bridging(objCValue: x) as! T
    } else {
        return x as! T
    }
}

internal func dynamicBridgeCast<T>(fromSwift x: T) -> AnyObject {
    if let x = x as? CustomObjectiveCBridgeable {
        return x.objCValue
    } else {
        return x as! AnyObject
    }
}

// Used for conversion from Objective-C types to Swift types
internal protocol CustomObjectiveCBridgeable {
    /* FIXME: Remove protocol once SR-2393 bridges all integer types to `NSNumber`
     *        At this point, use `as! [SwiftType]` to cast between. */
    static func bridging(objCValue objCValue: AnyObject) -> Self
    var objCValue: AnyObject { get }
}

extension Int8: CustomObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Int8 {
        return (objCValue as! NSNumber).charValue
    }
    var objCValue: AnyObject {
        return NSNumber(char: self)
    }
}
extension Int16: CustomObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Int16 {
        return (objCValue as! NSNumber).shortValue
    }
    var objCValue: AnyObject {
        return NSNumber(short: self)
    }
}
extension Int32: CustomObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Int32 {
        return (objCValue as! NSNumber).intValue
    }
    var objCValue: AnyObject {
        return NSNumber(int: self)
    }
}
extension Int64: CustomObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Int64 {
        return (objCValue as! NSNumber).longLongValue
    }
    var objCValue: AnyObject {
        return NSNumber(longLong: self)
    }
}

// MARK: AssistedObjectiveCBridgeable

internal protocol AssistedObjectiveCBridgeable {
    static func bridging(from objectiveCValue: Any, with metadata: Any?) -> Self
    var bridged: (objectiveCValue: Any, metadata: Any?) { get }
}

#endif
