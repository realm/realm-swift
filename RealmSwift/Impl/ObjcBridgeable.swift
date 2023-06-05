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

/// A type which can be bridged to and from Objective-C.
///
/// Do not use this protocol or the functions it adds directly.
public protocol _ObjcBridgeable {
    static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Self?
    var _rlmObjcValue: Any { get }
}
/// A type where the default logic suffices for bridging and we don't need to do anything special.
internal protocol DefaultObjcBridgeable: _ObjcBridgeable {}
extension DefaultObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Self? { value as? Self }
    public var _rlmObjcValue: Any { self }
}
/// A type which needs custom logic, but doesn't care if it's being bridged inside an Optional
internal protocol BuiltInObjcBridgeable: _ObjcBridgeable {
    static func _rlmFromObjc(_ value: Any) -> Self?
}
extension BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Self? {
        return _rlmFromObjc(value)
    }
}

extension Bool: DefaultObjcBridgeable {}
extension Int: DefaultObjcBridgeable {}
extension Double: DefaultObjcBridgeable {}
extension Date: DefaultObjcBridgeable {}
extension String: DefaultObjcBridgeable {}
extension Data: DefaultObjcBridgeable {}
extension ObjectId: DefaultObjcBridgeable {}
extension UUID: DefaultObjcBridgeable {}
extension NSNumber: DefaultObjcBridgeable {}
extension NSDate: DefaultObjcBridgeable {}

extension ObjectBase: BuiltInObjcBridgeable {
    public class func _rlmFromObjc(_ value: Any) -> Self? {
        if let value = value as? Self {
            return value
        }
        if Self.self === DynamicObject.self, let object = value as? ObjectBase {
            // Without `as AnyObject` this will produce a warning which incorrectly
            // claims it could be replaced with `unsafeDowncast()`
            return unsafeBitCast(object as AnyObject, to: Self.self)
        }
        return nil
    }
    public var _rlmObjcValue: Any { self }
}

// `NSNumber as? T` coerces values which can't be exact represented for some
// types and fails for others. We want to always coerce, for backwards
// compatibility if nothing else.
extension Float: BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any) -> Self? {
        return (value as? NSNumber)?.floatValue
    }
    public var _rlmObjcValue: Any {
        return NSNumber(value: self)
    }
}
extension Int8: BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any) -> Self? {
        return (value as? NSNumber)?.int8Value
    }
    public var _rlmObjcValue: Any {
        // Promote to Int before boxing as otherwise 0 and 1 will get treated
        // as Bool instead.
        return NSNumber(value: Int16(self))
    }
}
extension Int16: BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any) -> Self? {
        return (value as? NSNumber)?.int16Value
    }
    public var _rlmObjcValue: Any {
        return NSNumber(value: self)
    }
}
extension Int32: BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any) -> Self? {
        return (value as? NSNumber)?.int32Value
    }
    public var _rlmObjcValue: Any {
        return NSNumber(value: self)
    }
}
extension Int64: BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any) -> Self? {
        return (value as? NSNumber)?.int64Value
    }
    public var _rlmObjcValue: Any {
        return NSNumber(value: self)
    }
}

extension Optional: BuiltInObjcBridgeable, _ObjcBridgeable where Wrapped: _ObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any) -> Self? {
        // ?? here gives the nonsensical error "Left side of nil coalescing operator '??' has non-optional type 'Wrapped?', so the right side is never used"
        if let value = Wrapped._rlmFromObjc(value, insideOptional: true) {
            return .some(value)
        }
        // We have a double-optional here and need to explicitly specify that we
        // successfully converted to `nil`, as opposed to failing to bridge.
        return .some(Self.none)
    }
    public var _rlmObjcValue: Any {
        if let value = self {
            return value._rlmObjcValue
        }
        return NSNull()
    }
}
extension Decimal128: BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any) -> Decimal128? {
        if let value = value as? Decimal128 {
            return .some(value)
        }
        if let number = value as? NSNumber {
            return Decimal128(number: number)
        }
        if let str = value as? String {
            return .some((try? Decimal128(string: str)) ?? Decimal128("nan"))
        }
        return .none
    }
    public var _rlmObjcValue: Any {
        return self
    }
}
extension AnyRealmValue: BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any) -> Self? {
        if let any = value as? Self {
            return any
        }
        if let any = value as? RLMValue {
            return ObjectiveCSupport.convert(value: any)
        }
        return Self?.none // We need to explicitly say which .none we want here
    }
    public var _rlmObjcValue: Any {
        return ObjectiveCSupport.convert(value: self) ?? NSNull()
    }
}

// MARK: - Collections

extension Map: BuiltInObjcBridgeable {
    public var _rlmObjcValue: Any { _rlmCollection }
    public static func _rlmFromObjc(_ value: Any) -> Self? {
        (value as? RLMCollection).map(Self.init(collection:))
    }
}
extension RealmCollectionImpl {
    public var _rlmObjcValue: Any { self.collection }
    public static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Self? {
        (value as? RLMCollection).map(Self.init(collection:))
    }
}

extension LinkingObjects: _ObjcBridgeable {}
extension Results: _ObjcBridgeable {}
extension AnyRealmCollection: _ObjcBridgeable {}
extension List: _ObjcBridgeable {}
extension MutableSet: _ObjcBridgeable {}

extension SectionedResults: BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Self? {
        (value as? RLMSectionedResults<RLMValue, RLMValue>).map(Self.init(rlmSectionedResult:))
    }
    public var _rlmObjcValue: Any {
        self.collection
    }
}

extension ResultsSection: BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Self? {
        (value as? RLMSection<RLMValue, RLMValue>).map(Self.init(rlmSectionedResult:))
    }
    public var _rlmObjcValue: Any {
        self.collection
    }
}

extension RLMSwiftCollectionBase: Equatable {
    public static func == (lhs: RLMSwiftCollectionBase, rhs: RLMSwiftCollectionBase) -> Bool {
        return lhs.isEqual(rhs)
    }
}

extension Projection: BuiltInObjcBridgeable {
    public static func _rlmFromObjc(_ value: Any) -> Self? {
        return (value as? Root).map(Self.init(projecting:))
    }

    public var _rlmObjcValue: Any {
        self.rootObject
    }
}

public protocol _PossiblyAggregateable: _ObjcBridgeable {
    associatedtype PersistedType
}
extension NSDate: _PossiblyAggregateable {}
extension NSNumber: _PossiblyAggregateable {}
