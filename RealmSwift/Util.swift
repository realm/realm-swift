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
import os.log

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

internal func logRuntimeIssue(_ message: StaticString) {
    if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
        // Reporting a runtime issue to Xcode requires pretending to be
        // one of the system libraries which are allowed to do so. We do
        // this by looking up a symbol defined by SwiftUI, getting the
        // dso information from that, and passing that to os_log() to
        // claim that we're SwiftUI. As this is obviously not a particularly legal thing to do, we only do it in debug and simulator builds.
        var dso = #dsohandle
        #if DEBUG || targetEnvironment(simulator)
        let sym = dlsym(dlopen(nil, RTLD_LAZY), "$s7SwiftUI3AppMp")
        var info = Dl_info()
        dladdr(sym, &info)
        if let base = info.dli_fbase {
            dso = UnsafeRawPointer(base)
        }
        #endif
        let log = OSLog(subsystem: "com.apple.runtime-issues", category: "Realm")
        os_log(.fault, dso: dso, log: log, message)
    } else {
        print(message)
    }
}

@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
@_unavailableFromAsync
internal func assumeOnMainActorExecutor(_ operation: @MainActor () throws -> Void,
                                        file: StaticString = #fileID, line: UInt = #line
) rethrows {
#if compiler(>=5.10)
    // This is backdeployable in Xcode 15.3+, but not 15.1
    try MainActor.assumeIsolated(operation)
#else
    if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) {
        return try MainActor.assumeIsolated(operation)
    }

    precondition(Thread.isMainThread, file: file, line: line)
    return try withoutActuallyEscaping(operation) { fn in
        try unsafeBitCast(fn, to: (() throws -> ()).self)()
    }
#endif
}

@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
extension Actor {
    @_unavailableFromAsync
    internal func invokeIsolated<Ret, Arg>(_ operation: (isolated Self, Arg) throws -> Ret, _ arg: Arg,
                                           file: StaticString = #fileID, line: UInt = #line
    ) rethrows -> Ret {
#if compiler(>=5.10)
        // This is backdeployable in Xcode 15.3+, but not 15.1
        preconditionIsolated(file: file, line: line)
#else
        if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) {
            preconditionIsolated(file: file, line: line)
        }
#endif

        return try withoutActuallyEscaping(operation) { fn in
            try unsafeBitCast(fn, to: ((Self, Arg) throws -> Ret).self)(self, arg)
        }
    }
}
