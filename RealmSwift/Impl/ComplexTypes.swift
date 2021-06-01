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

extension Object: _RealmSchemaDiscoverable {
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
}

extension EmbeddedObject: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .object }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.objectClassName = className()
    }
}

extension List: _RealmSchemaDiscoverable where Element: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Element._rlmType }
    public static var _rlmOptional: Bool { Element._rlmOptional }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.array = true
        prop.swiftAccessor = ListAccessor<Element>.self
        Element._rlmPopulateProperty(prop)
    }
}

extension MutableSet: _RealmSchemaDiscoverable where Element: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Element._rlmType }
    public static var _rlmOptional: Bool { Element._rlmOptional }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.set = true
        prop.swiftAccessor = SetAccessor<Element>.self
        Element._rlmPopulateProperty(prop)
    }
}

extension Map: _RealmSchemaDiscoverable where Value: _RealmSchemaDiscoverable {
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

extension LinkingObjects: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { .linkingObjects }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.array = true
        prop.objectClassName = Element.className()
        prop.swiftAccessor = LinkingObjectsAccessor<Element>.self
    }
    public func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.linkOriginPropertyName = self.propertyName
    }
}

@available(*, deprecated)
extension RealmOptional: _RealmSchemaDiscoverable where Value: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Value._rlmType }
    public static var _rlmOptional: Bool { true }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        Value._rlmPopulateProperty(prop)
        prop.swiftAccessor = RealmOptionalAccessor<Value>.self
    }
}

extension Optional: _RealmSchemaDiscoverable where Wrapped: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Wrapped._rlmType }
    public static var _rlmOptional: Bool { true }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        Wrapped._rlmPopulateProperty(prop)
    }
}

extension RealmProperty: _RealmSchemaDiscoverable where Value: _RealmSchemaDiscoverable {
    public static var _rlmType: PropertyType { Value._rlmType }
    public static var _rlmOptional: Bool { Value._rlmOptional }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        Value._rlmPopulateProperty(prop)
        prop.swiftAccessor = RealmPropertyAccessor<Value>.self
    }
}
