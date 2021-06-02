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

import Realm
import Realm.Private

// MARK: - Property Types

extension Int: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .int }
}

extension Int8: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .int }
}

extension Int16: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .int }
}

extension Int32: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .int }
}

extension Int64: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .int }
}

extension Bool: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .bool }
}

extension Float: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .float }
}

extension Double: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .double }
}

extension String: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .string }
}

extension Data: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .data }
}

extension ObjectId: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .objectId }
}

extension Decimal128: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .decimal128 }
}

extension Date: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .date }
}

extension UUID: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .UUID }
}

extension AnyRealmValue: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .any }
}

extension NSString: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .string }
}

extension NSData: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .data }
}

extension NSDate: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .date }
}

// MARK: - Managed property getters/setters

public protocol _Int: BinaryInteger, _ManagedPropertyType, _DefaultConstructible, PrimaryKeyProperty, IndexableProperty {
}

extension _Int {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Self {
        return Self(RLMGetSwiftPropertyInt64(obj, key))
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Self? {
        var gotValue = false
        let ret = RLMGetSwiftPropertyInt64Optional(obj, key, &gotValue)
        return gotValue ? Self(ret) : nil
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Self) {
        RLMSetSwiftPropertyInt64(obj, key, Int64(value))
    }
}

extension Int: _Int {}
extension Int8: _Int {}
extension Int16: _Int {}
extension Int32: _Int {}
extension Int64: _Int {}

extension Bool: _ManagedPropertyType, _DefaultConstructible, PrimaryKeyProperty, IndexableProperty {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Bool {
        return RLMGetSwiftPropertyBool(obj, key)
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Bool? {
        var gotValue = false
        let ret = RLMGetSwiftPropertyBoolOptional(obj, key, &gotValue)
        return gotValue ? ret : nil
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Bool) {
        RLMSetSwiftPropertyBool(obj, key, (value))
    }
}

extension Float: _ManagedPropertyType, _DefaultConstructible {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Float {
        return RLMGetSwiftPropertyFloat(obj, key)
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Float? {
        var gotValue = false
        let ret = RLMGetSwiftPropertyFloatOptional(obj, key, &gotValue)
        return gotValue ? ret : nil
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Float) {
        RLMSetSwiftPropertyFloat(obj, key, (value))
    }
}

extension Double: _ManagedPropertyType, _DefaultConstructible {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Double {
        return RLMGetSwiftPropertyDouble(obj, key)
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Double? {
        var gotValue = false
        let ret = RLMGetSwiftPropertyDoubleOptional(obj, key, &gotValue)
        return gotValue ? ret : nil
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Double) {
        RLMSetSwiftPropertyDouble(obj, key, (value))
    }
}

extension String: _ManagedPropertyType, _DefaultConstructible, PrimaryKeyProperty, IndexableProperty {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> String {
        return RLMGetSwiftPropertyString(obj, key)!
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> String? {
        return RLMGetSwiftPropertyString(obj, key)
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: String) {
        RLMSetSwiftPropertyString(obj, key, value)
    }
}

extension Data: _ManagedPropertyType, _DefaultConstructible {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Data {
        return RLMGetSwiftPropertyData(obj, key)!
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Data? {
        return RLMGetSwiftPropertyData(obj, key)
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Data) {
        RLMSetSwiftPropertyData(obj, key, value)
    }
}

extension ObjectId: _ManagedPropertyType, _DefaultConstructible, PrimaryKeyProperty, IndexableProperty {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> ObjectId {
        return RLMGetSwiftPropertyObjectId(obj, key) as! ObjectId
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> ObjectId? {
        return RLMGetSwiftPropertyObjectId(obj, key).map(dynamicBridgeCast)
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: ObjectId) {
        RLMSetSwiftPropertyObjectId(obj, key, (value))
    }

    public static func _rlmDefaultValue() -> ObjectId {
        return Self.generate()
    }
}

extension Decimal128: _ManagedPropertyType, _DefaultConstructible {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Decimal128 {
        return RLMGetSwiftPropertyDecimal128(obj, key) as! Decimal128
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Decimal128? {
        return RLMGetSwiftPropertyDecimal128(obj, key).map(dynamicBridgeCast)
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Decimal128) {
        RLMSetSwiftPropertyDecimal128(obj, key, value)
    }
}

extension Date: _ManagedPropertyType, _DefaultConstructible, IndexableProperty {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Date {
        return RLMGetSwiftPropertyDate(obj, key)!
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Date? {
        return RLMGetSwiftPropertyDate(obj, key)
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Date) {
        RLMSetSwiftPropertyDate(obj, key, value)
    }
}

extension UUID: _ManagedPropertyType, _DefaultConstructible, PrimaryKeyProperty {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> UUID {
        return RLMGetSwiftPropertyUUID(obj, key)!
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> UUID? {
        return RLMGetSwiftPropertyUUID(obj, key)
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: UUID) {
        RLMSetSwiftPropertyUUID(obj, key, value)
    }
}

extension AnyRealmValue: _ManagedPropertyType, _DefaultConstructible {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> AnyRealmValue {
        return ObjectiveCSupport.convert(value: RLMGetSwiftPropertyAny(obj, key))
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> AnyRealmValue? {
        fatalError()
    }

    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: AnyRealmValue) {
        RLMSetSwiftPropertyAny(obj, key, value.objCValue as! RLMValue)
    }
}
