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

// MARK: ObjectiveCBridgeable

// Used for conversion from Objective-C types to Swift types
internal protocol ObjectiveCBridgeable  {
    /* FIXME: Remove protocol once SR-2393 bridges all integer types to `NSNumber`
     *        Instead, use `as AnyObject` and `as! [SwiftType]` to cast between. */
    static func bridging(objCValue: Any) -> Self
    var objCValue: Any { get }
}

// FIXME: Remove once Swift supports `as! Self` casts
private func forceCastToInferred<T, U>(_ x: T) -> U {
    return x as! U
}

extension NSNumber: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Self {
        return forceCastToInferred(objCValue)
    }
    var objCValue: Any {
        return self
    }
}
extension Double: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Double {
        return (objCValue as! NSNumber).doubleValue
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Float: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Float {
        return (objCValue as! NSNumber).floatValue
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Int: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Int {
        return (objCValue as! NSNumber).intValue
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Int8: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Int8 {
        return (objCValue as! NSNumber).int8Value
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Int16: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Int16 {
        return (objCValue as! NSNumber).int16Value
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Int32: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Int32 {
        return (objCValue as! NSNumber).int32Value
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Int64: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Int64 {
        return (objCValue as! NSNumber).int64Value
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Bool: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Bool {
        return (objCValue as! NSNumber).boolValue
    }
    var objCValue: Any {
        return NSNumber(value: self)
    }
}
extension Date: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Date   {
        return objCValue as! Date
    }
    var objCValue: Any {
        return self
    }
}
extension NSDate: ObjectiveCBridgeable {
    static func bridging(objCValue: Any) -> Self   {
        return forceCastToInferred(objCValue)
    }
    var objCValue: Any {
        return self
    }
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

// MARK: ObjectiveCBridgeable

// Used for conversion from Objective-C types to Swift types
internal protocol ObjectiveCBridgeable  {
    /* FIXME: Remove protocol once SR-2393 bridges all integer types to `NSNumber`
     *        Instead, use `as AnyObject` and `as! [SwiftType]` to cast between. */
    static func bridging(objCValue objCValue: AnyObject) -> Self
    var objCValue: AnyObject { get }
}

// FIXME: Remove once Swift supports `as! Self` casts
private func forceCastToInferred<T, U>(x: T) -> U {
    return x as! U
}

extension NSNumber: ObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Self {
        return forceCastToInferred(objCValue)
    }
    var objCValue: AnyObject {
        return self
    }
}
extension Double: ObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Double {
        return (objCValue as! NSNumber).doubleValue
    }
    var objCValue: AnyObject {
        return NSNumber(double: self)
    }
}
extension Float: ObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Float {
        return (objCValue as! NSNumber).floatValue
    }
    var objCValue: AnyObject {
        return NSNumber(float: self)
    }
}
extension Int: ObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Int {
        return (objCValue as! NSNumber).integerValue
    }
    var objCValue: AnyObject {
        return NSNumber(integer: self)
    }
}
extension Int8: ObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Int8 {
        return (objCValue as! NSNumber).charValue
    }
    var objCValue: AnyObject {
        return NSNumber(char: self)
    }
}
extension Int16: ObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Int16 {
        return (objCValue as! NSNumber).shortValue
    }
    var objCValue: AnyObject {
        return NSNumber(short: self)
    }
}
extension Int32: ObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Int32 {
        return (objCValue as! NSNumber).intValue
    }
    var objCValue: AnyObject {
        return NSNumber(int: self)
    }
}
extension Int64: ObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Int64 {
        return (objCValue as! NSNumber).longLongValue
    }
    var objCValue: AnyObject {
        return NSNumber(longLong: self)
    }
}
extension Bool: ObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Bool {
        return (objCValue as! NSNumber).boolValue
    }
    var objCValue: AnyObject {
        return NSNumber(bool: self)
    }
}
extension NSDate: ObjectiveCBridgeable {
    static func bridging(objCValue objCValue: AnyObject) -> Self   {
        func forceCastTrampoline<T, U>(x: T) -> U {
            return x as! U
        }
        return forceCastTrampoline(objCValue)
    }
    var objCValue: AnyObject {
        return self
    }
}

#endif
