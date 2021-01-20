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
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        if !prop.optional && !prop.collection {
            throwRealmException("Object property '\(prop.name)' must be marked as optional.")
        }
        if prop.optional && prop.array {
            throwRealmException("List<\(className())> property '\(prop.name)' must not be marked as optional.")
        }
        if prop.optional && prop.set {
            throwRealmException("MutableSet<\(className())> property '\(prop.name)' must not be marked as optional.")
        }
        prop.type = .object
        prop.objectClassName = className()
    }
}

extension EmbeddedObject: _RealmSchemaDiscoverable {
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        Object._rlmPopulateProperty(prop)
        prop.objectClassName = className()
    }
}

extension List: _RealmSchemaDiscoverable where Element: _RealmSchemaDiscoverable {
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.array = true
        prop.swiftAccessor = ListAccessor<Element>.self
        Element._rlmPopulateProperty(prop)
    }
    public static func _rlmRequireObjc() -> Bool { return false }
}

extension MutableSet: _RealmSchemaDiscoverable where Element: _RealmSchemaDiscoverable {
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.set = true
        prop.swiftAccessor = SetAccessor<Element>.self
        Element._rlmPopulateProperty(prop)
    }
    public static func _rlmRequireObjc() -> Bool { return false }
}

extension LinkingObjects: _RealmSchemaDiscoverable {
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.array = true
        prop.type = .linkingObjects
        prop.objectClassName = Element.className()
        prop.swiftAccessor = LinkingObjectsAccessor<Element>.self
    }
    public func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.linkOriginPropertyName = self.propertyName
    }
    public static func _rlmRequireObjc() -> Bool { return false }
}

extension RealmOptional: _RealmSchemaDiscoverable where Value: _RealmSchemaDiscoverable {
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        Value._rlmPopulateProperty(prop)
        prop.optional = true
        prop.swiftAccessor = RealmOptionalAccessor<Value>.self
    }
    public static func _rlmRequireObjc() -> Bool { return false }
}

extension Optional: _RealmSchemaDiscoverable where Wrapped: _RealmSchemaDiscoverable {
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.optional = true
        Wrapped._rlmPopulateProperty(prop)
    }
}

extension RealmProperty: _RealmSchemaDiscoverable where Value: _RealmSchemaDiscoverable {
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        Value._rlmPopulateProperty(prop)
        prop.swiftAccessor = RealmPropertyAccessor<Value>.self
    }
    public static func _rlmRequireObjc() -> Bool { return false }
}
