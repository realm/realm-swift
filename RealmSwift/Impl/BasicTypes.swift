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
