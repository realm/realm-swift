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

extension Int: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .int
    }
}

extension Int8: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .int
    }
}

extension Int16: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .int
    }
}

extension Int32: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .int
    }
}

extension Int64: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .int
    }
}

extension Bool: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .bool
    }
}

extension Float: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .float
    }
}

extension Double: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .double
    }
}

extension String: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .string
    }
}

extension Data: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .data
    }
}

extension ObjectId: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .objectId
    }
}

extension Decimal128: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .decimal128
    }
}

extension Date: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .date
    }
}

extension UUID: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ property: RLMProperty) {
        property.type = .UUID
    }
}

extension AnyRealmValue: _RealmSchemaDiscoverable {
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.type = .any
    }
}

extension NSString: _RealmSchemaDiscoverable {
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.type = .string
    }
}

extension NSData: _RealmSchemaDiscoverable {
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.type = .data
    }
}

extension NSDate: _RealmSchemaDiscoverable {
    static public func _rlmPopulateProperty(_ prop: RLMProperty) {
        prop.type = .date
    }
}
