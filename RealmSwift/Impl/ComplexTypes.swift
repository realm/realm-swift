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

extension Object: SchemaDiscoverable, _OptionalPersistable, _BuiltInPersistable, _DefaultConstructible {
    public static var _rlmType: PropertyType { .object }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        if !prop.optional && !prop.collection {
            throwRealmException("Object property '\(prop.name)' must be marked as optional.")
        }
        if prop.optional && prop.array {
            throwRealmException("List<\(className())> property '\(prop.name)' must not be marked as optional.")
        }
        if prop.optional && prop.set {
            throwRealmException("MutableSet<\(className())> property '\(prop.name)' must not be marked as optional.")
        }
        if !prop.optional && prop.dictionary {
            throwRealmException("Map<String, \(className())> property '\(prop.name)' must be marked as optional.")
        }
        prop.objectClassName = className()
    }

    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Self {
        fatalError("Non-optional Object properties are not allowed.")
    }

    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: UInt16) -> Self? {
//        FIXME: gives Assertion failed: (LocalSelf && "no local self metadata"), function getLocalSelfMetadata, file /src/swift-source/swift/lib/IRGen/GenHeap.cpp, line 1686.
//        return RLMGetSwiftPropertyObject(obj, key).map(dynamicBridgeCast)
        if let value = RLMGetSwiftPropertyObject(obj, key) {
            return (value as! Self)
        }
        return nil
    }

    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: Object) {
        RLMSetSwiftPropertyObject(obj, key, value)
    }
}

extension EmbeddedObject: SchemaDiscoverable, _OptionalPersistable, _BuiltInPersistable, _DefaultConstructible {
    public static var _rlmType: PropertyType { .object }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        Object._rlmPopulateProperty(prop)
        prop.objectClassName = className()
    }

    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Self {
        fatalError("Non-optional EmbeddedObject properties are not allowed.")
    }

    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: UInt16) -> Self? {
        if let value = RLMGetSwiftPropertyObject(obj, key) {
            return (value as! Self)
        }
        return nil
    }

    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: EmbeddedObject) {
        RLMSetSwiftPropertyObject(obj, key, value)
    }
}

extension List: SchemaDiscoverable where Element: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Element._rlmType }
    public static var _rlmOptional: Bool { Element._rlmOptional }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.array = true
        prop.swiftAccessor = ListAccessor<Element>.self
        Element._rlmPopulateProperty(prop)
    }
}

extension List: _Persistable, _DefaultConstructible where Element: _Persistable {
    public typealias _RealmValue = List
    public static var _rlmRequiresCaching: Bool { true }

    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Self {
        return Self(objc: RLMGetSwiftPropertyArray(obj, key))
    }

    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: UInt16) -> Self? {
        fatalError("List properties cannot be optional")
    }

    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: List) {
        let array = RLMGetSwiftPropertyArray(obj, key)
        if array.isEqual(value.rlmArray) { return }
        array.removeAllObjects()
        array.addObjects(value.rlmArray)
    }

    public static func _rlmSetAccessor(_ prop: RLMProperty) {
        prop.swiftAccessor = PersistedListAccessor<Element>.self
    }
}

extension MutableSet: SchemaDiscoverable where Element: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Element._rlmType }
    public static var _rlmOptional: Bool { Element._rlmOptional }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.set = true
        prop.swiftAccessor = SetAccessor<Element>.self
        Element._rlmPopulateProperty(prop)
    }
}

extension MutableSet: _Persistable, _DefaultConstructible where Element: _Persistable {
    public typealias _RealmValue = MutableSet
    public static var _rlmRequiresCaching: Bool { true }

    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Self {
        return Self(objc: RLMGetSwiftPropertySet(obj, key))
    }

    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: UInt16) -> Self? {
        fatalError("Set properties cannot be optional")
    }

    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: MutableSet) {
        let set = RLMGetSwiftPropertySet(obj, key)
        if set.isEqual(value.rlmSet) { return }
        set.removeAllObjects()
        set.addObjects(value.rlmSet)
    }

    public static func _rlmSetAccessor(_ prop: RLMProperty) {
        prop.swiftAccessor = PersistedSetAccessor<Element>.self
    }
}

extension Map: SchemaDiscoverable where Value: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Value._rlmType }
    public static var _rlmOptional: Bool { Value._rlmOptional }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.dictionary = true
        prop.swiftAccessor = MapAccessor<Key, Value>.self
        prop.dictionaryKeyType = Key._rlmType
        Value._rlmPopulateProperty(prop)
    }
}

extension Map: _Persistable, _DefaultConstructible where Value: _Persistable {
    public typealias _RealmValue = Map
    public static var _rlmRequiresCaching: Bool { true }

    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Self {
        return Self(objc: RLMGetSwiftPropertyMap(obj, key))
    }

    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: UInt16) -> Self? {
        return Self(objc: RLMGetSwiftPropertyMap(obj, key))
    }

    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: Map) {
        let map = RLMGetSwiftPropertyMap(obj, key)
        if map.isEqual(value.rlmDictionary) { return }
        map.removeAllObjects()
        map.addEntries(fromDictionary: value.rlmDictionary)
    }

    public static func _rlmSetAccessor(_ prop: RLMProperty) {
        prop.swiftAccessor = PersistedMapAccessor<Key, Value>.self
    }
}

extension LinkingObjects: SchemaDiscoverable {
    public static var _rlmType: PropertyType { .linkingObjects }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.array = true
        prop.objectClassName = Element.className()
        prop.swiftAccessor = LinkingObjectsAccessor<Element>.self
        if prop.linkOriginPropertyName == nil {
            throwRealmException("LinkingObjects<\(prop.objectClassName!)> property '\(prop.name)' must set the origin property name with @Persisted(originProperty: \"name\").")
        }
    }
    public func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.linkOriginPropertyName = self.propertyName
    }
}

@available(*, deprecated)
extension RealmOptional: SchemaDiscoverable, _RealmSchemaDiscoverable where Value: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Value._rlmType }
    public static var _rlmOptional: Bool { true }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        Value._rlmPopulateProperty(prop)
        prop.swiftAccessor = RealmOptionalAccessor<Value>.self
    }
}

extension LinkingObjects: _Persistable where Element: _Persistable {
    public typealias _RealmValue = Self
    public static func _rlmDefaultValue(_ forceDefaultInitialization: Bool) -> Self {
        if forceDefaultInitialization {
            return .init(propertyName: "", handle: nil)
        } else {
            fatalError("LinkingObjects properties must set the origin property name")
        }
    }

    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> LinkingObjects {
        let prop = RLMObjectBaseObjectSchema(obj)!.computedProperties[Int(key)]
        return Self(propertyName: prop.name, handle: RLMLinkingObjectsHandle(object: obj, property: prop))
    }

    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: UInt16) -> LinkingObjects? {
        fatalError("LinkingObjects properties cannot be optional")
    }

    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: LinkingObjects) {
        fatalError("LinkingObjects properties are read-only")
    }

    public static func _rlmSetAccessor(_ prop: RLMProperty) {
        prop.swiftAccessor = PersistedLinkingObjectsAccessor<Element>.self
    }
}

extension Optional: SchemaDiscoverable, _RealmSchemaDiscoverable where Wrapped: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Wrapped._rlmType }
    public static var _rlmOptional: Bool { true }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        Wrapped._rlmPopulateProperty(prop)
    }
}

extension Optional: _Persistable where Wrapped: _OptionalPersistable {
    public typealias _RealmValue = Self

    public static func _rlmDefaultValue(_ forceDefaultInitialization: Bool) -> Self {
        if forceDefaultInitialization {
            return Wrapped()
        }
        return .none
    }
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Wrapped? {
        return Wrapped._rlmGetPropertyOptional(obj, key)
    }
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: UInt16) -> Wrapped?? {
        fatalError("Double-optional properties are not supported")
    }
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: Wrapped?) {
        if let value = value {
            Wrapped._rlmSetProperty(obj, key, value)
        } else {
            RLMSetSwiftPropertyNil(obj, key)
        }
    }
    public static func _rlmSetAccessor(_ prop: RLMProperty) {
        Wrapped._rlmSetAccessor(prop)
    }
}

extension Optional: _PrimaryKey where Wrapped: _Persistable, Wrapped._RealmValue: _PrimaryKey {}
extension Optional: _Indexable where Wrapped: _Persistable, Wrapped._RealmValue: _Indexable {}

extension RealmProperty: _RealmSchemaDiscoverable, SchemaDiscoverable where Value: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Value._rlmType }
    public static var _rlmOptional: Bool { Value._rlmOptional }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        Value._rlmPopulateProperty(prop)
        prop.swiftAccessor = RealmPropertyAccessor<Value>.self
    }
}

extension RawRepresentable where RawValue: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { RawValue._rlmType }
    public static var _rlmOptional: Bool { RawValue._rlmOptional }
    public static var _rlmRequireObjc: Bool { false }
    public func _rlmPopulateProperty(_ prop: RLMProperty) { }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        RawValue._rlmPopulateProperty(prop)
    }
}

extension RawRepresentable where Self: _OptionalPersistable, RawValue: _OptionalPersistable {
    public typealias _RealmValue = RawValue
    public static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Self {
        return Self(rawValue: RawValue._rlmGetProperty(obj, key))!
    }
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Self? {
        return RawValue._rlmGetPropertyOptional(obj, key).flatMap(Self.init)
    }
    public static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Self) {
        RawValue._rlmSetProperty(obj, key, value.rawValue)
    }
    public static func _rlmSetAccessor(_ prop: RLMProperty) {
        if prop.optional {
            prop.swiftAccessor = BridgedPersistedPropertyAccessor<Optional<Self>>.self
        } else {
            prop.swiftAccessor = PersistedEnumAccessor<Self>.self
        }
    }
}

extension PersistableEnum {
    public static func _rlmDefaultValue(_ forceDefaultInitialization: Bool) -> Self {
        return self.allCases.first!
    }
}
