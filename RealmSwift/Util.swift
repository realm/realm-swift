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

internal func throwRealmException(_ message: String, userInfo: [AnyHashable: Any]? = nil) -> Never {
    NSException(name: NSExceptionName(rawValue: RLMExceptionName), reason: message, userInfo: userInfo).raise()
    fatalError() // unreachable
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

extension ObjectBase {
    // Must *only* be used to call Realm Objective-C APIs that are exposed on `RLMObject`
    // but actually operate on `RLMObjectBase`. Do not expose cast value to user.
    internal func unsafeCastToRLMObject() -> RLMObject {
        return noWarnUnsafeBitCast(self, to: RLMObject.self)
    }
}

internal func coerceToNil(_ value: Any) -> Any? {
    if value is NSNull {
        return nil
    }
    // nil in Any is bridged to obj-c as NSNull. In the obj-c code we usually
    // convert NSNull back to nil, which ends up as Optional<Any>.none
    if case Optional<Any>.none = value {
        return nil
    }
    return value
}

// MARK: CustomObjectiveCBridgeable

internal extension _ObjcBridgeable {
    static func _rlmFromObjc(_ value: Any) -> Self? { _rlmFromObjc(value, insideOptional: false) }
}
/// :nodoc:
public func dynamicBridgeCast<T>(fromObjectiveC x: Any) -> T {
    if let bridged = failableDynamicBridgeCast(fromObjectiveC: x) as T? {
        return bridged
    }
    fatalError("Could not convert value '\(x)' to type '\(T.self)'")
}

/// :nodoc:
@usableFromInline
internal func failableDynamicBridgeCast<T>(fromObjectiveC x: Any) -> T? {
    if let bridgeableType = T.self as? _ObjcBridgeable.Type {
        return bridgeableType._rlmFromObjc(x).flatMap { $0 as? T }
    }
    if let value = x as? T {
        return value
    }
    return nil
}

/// :nodoc:
public func dynamicBridgeCast<T>(fromSwift x: T) -> Any {
    if let x = x as? _ObjcBridgeable {
        return x._rlmObjcValue
    }
    return x
}

@usableFromInline
internal func staticBridgeCast<T: _ObjcBridgeable>(fromSwift x: T) -> Any {
    return x._rlmObjcValue
}
@usableFromInline
internal func staticBridgeCast<T: _ObjcBridgeable>(fromObjectiveC x: Any) -> T {
    if let value = T._rlmFromObjc(x) {
        return value
    }
    throwRealmException("Could not convert value '\(x)' to type '\(T.self)'.")
}
@usableFromInline
internal func failableStaticBridgeCast<T: _ObjcBridgeable>(fromObjectiveC x: Any) -> T? {
    return T._rlmFromObjc(x)
}
