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

extension Int: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .int }
}

extension Int8: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .int }
}

extension Int16: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .int }
}

extension Int32: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .int }
}

extension Int64: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .int }
}

extension Bool: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .bool }
}

extension Float: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .float }
}

extension Double: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .double }
}

extension String: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .string }
}

extension Data: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .data }
}

extension ObjectId: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .objectId }
}

extension Decimal128: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .decimal128 }
}

extension Date: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .date }
}

extension UUID: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .UUID }
}

extension AnyRealmValue: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .any }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        if prop.optional {
            var type = "AnyRealmValue"
            if prop.array {
                type = "List<AnyRealmValue>"
            } else if prop.set {
                type = "MutableSet<AnyRealmValue>"
            } else if prop.dictionary {
                type = "Map<String, AnyRealmValue>"
            }
            throwRealmException("\(type) property '\(prop.name)' must not be marked as optional: nil values are represented as AnyRealmValue.none")
        }
    }
}

extension NSString: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .string }
}

extension NSData: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .data }
}

extension NSDate: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .date }
}

// MARK: - Modern property getters/setters

private protocol _Int: BinaryInteger, _OptionalPersistable, _PrimaryKey, _Indexable {
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

extension Bool: _OptionalPersistable, _DefaultConstructible, _PrimaryKey, _Indexable {
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

extension Float: _OptionalPersistable, _DefaultConstructible {
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

extension Double: _OptionalPersistable, _DefaultConstructible {
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

extension String: _OptionalPersistable, _DefaultConstructible, _PrimaryKey, _Indexable {
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

extension Data: _OptionalPersistable, _DefaultConstructible {
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

extension ObjectId: _OptionalPersistable, _DefaultConstructible, _PrimaryKey, _Indexable {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> ObjectId {
        return RLMGetSwiftPropertyObjectId(obj, key) as! ObjectId
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> ObjectId? {
        return RLMGetSwiftPropertyObjectId(obj, key).flatMap(failableDynamicBridgeCast)
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: ObjectId) {
        RLMSetSwiftPropertyObjectId(obj, key, (value))
    }

    public static func _rlmDefaultValue(_ forceDefaultInitialization: Bool) -> ObjectId {
        return Self.generate()
    }
}

extension Decimal128: _OptionalPersistable, _DefaultConstructible {
    @inlinable
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Decimal128 {
        return RLMGetSwiftPropertyDecimal128(obj, key) as! Decimal128
    }

    @inlinable
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Decimal128? {
        return RLMGetSwiftPropertyDecimal128(obj, key).flatMap(failableDynamicBridgeCast)
    }

    @inlinable
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Decimal128) {
        RLMSetSwiftPropertyDecimal128(obj, key, value)
    }
}

extension Date: _OptionalPersistable, _DefaultConstructible, _Indexable {
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

extension UUID: _OptionalPersistable, _DefaultConstructible, _PrimaryKey {
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

extension AnyRealmValue: _Persistable, _DefaultConstructible {
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

    public static func _rlmSetAccessor(_ prop: RLMProperty) {
        prop.swiftAccessor = BridgedPersistedPropertyAccessor<Self>.self
    }
}
