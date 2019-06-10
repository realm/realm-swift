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

import Realm

/**
 `ObjectiveCSupport` is a class providing methods for Swift/Objective-C interoperability.

 With `ObjectiveCSupport` you can either retrieve the internal ObjC representations of the Realm objects,
 or wrap ObjC Realm objects with their Swift equivalents.

 Use this to provide public APIs that support both platforms.

 :nodoc:
 **/
public final class ObjectiveCSupport {

    /// Convert a `Results` to a `RLMResults`.
    public static func convert<T>(object: Results<T>) -> RLMResults<AnyObject> {
        return object.rlmResults
    }

    /// Convert a `RLMResults` to a `Results`.
    public static func convert(object: RLMResults<AnyObject>) -> Results<Object> {
        return Results(object)
    }

    /// Convert a `List` to a `RLMArray`.
    public static func convert<T>(object: List<T>) -> RLMArray<AnyObject> {
        return object._rlmArray
    }

    /// Convert a `RLMArray` to a `List`.
    public static func convert(object: RLMArray<AnyObject>) -> List<Object> {
        return List(rlmArray: object)
    }

    /// Convert a `LinkingObjects` to a `RLMResults`.
    public static func convert<T>(object: LinkingObjects<T>) -> RLMResults<AnyObject> {
        return object.rlmResults
    }

    /// Convert a `RLMLinkingObjects` to a `Results`.
    public static func convert(object: RLMLinkingObjects<RLMObject>) -> Results<Object> {
        return Results(object)
    }

    /// Convert a `Realm` to a `RLMRealm`.
    public static func convert(object: Realm) -> RLMRealm {
        return object.rlmRealm
    }

    /// Convert a `RLMRealm` to a `Realm`.
    public static func convert(object: RLMRealm) -> Realm {
        return Realm(object)
    }

    /// Convert a `Migration` to a `RLMMigration`.
    public static func convert(object: Migration) -> RLMMigration {
        return object.rlmMigration
    }

    /// Convert a `RLMMigration` to a `Migration`.
    public static func convert(object: RLMMigration) -> Migration {
        return Migration(object)
    }

    /// Convert a `ObjectSchema` to a `RLMObjectSchema`.
    public static func convert(object: ObjectSchema) -> RLMObjectSchema {
        return object.rlmObjectSchema
    }

    /// Convert a `RLMObjectSchema` to a `ObjectSchema`.
    public static func convert(object: RLMObjectSchema) -> ObjectSchema {
        return ObjectSchema(object)
    }

    /// Convert a `Property` to a `RLMProperty`.
    public static func convert(object: Property) -> RLMProperty {
        return object.rlmProperty
    }

    /// Convert a `RLMProperty` to a `Property`.
    public static func convert(object: RLMProperty) -> Property {
        return Property(object)
    }

    /// Convert a `Realm.Configuration` to a `RLMRealmConfiguration`.
    public static func convert(object: Realm.Configuration) -> RLMRealmConfiguration {
        return object.rlmConfiguration
    }

    /// Convert a `RLMRealmConfiguration` to a `Realm.Configuration`.
    public static func convert(object: RLMRealmConfiguration) -> Realm.Configuration {
        return .fromRLMRealmConfiguration(object)
    }

    /// Convert a `Schema` to a `RLMSchema`.
    public static func convert(object: Schema) -> RLMSchema {
        return object.rlmSchema
    }

    /// Convert a `RLMSchema` to a `Schema`.
    public static func convert(object: RLMSchema) -> Schema {
        return Schema(object)
    }

    /// Convert a `SortDescriptor` to a `RLMSortDescriptor`.
    public static func convert(object: SortDescriptor) -> RLMSortDescriptor {
        return object.rlmSortDescriptorValue
    }

    /// Convert a `RLMSortDescriptor` to a `SortDescriptor`.
    public static func convert(object: RLMSortDescriptor) -> SortDescriptor {
        return SortDescriptor(keyPath: object.keyPath, ascending: object.ascending)
    }

    /// Convert a `RLMShouldCompactOnLaunchBlock` to a Realm Swift compact block.
    public static func convert(object: @escaping RLMShouldCompactOnLaunchBlock) -> (Int, Int) -> Bool {
        return { totalBytes, usedBytes in
            return object(UInt(totalBytes), UInt(usedBytes))
        }
    }

    /// Convert a Realm Swift compact block to a `RLMShouldCompactOnLaunchBlock`.
    public static func convert(object: @escaping (Int, Int) -> Bool) -> RLMShouldCompactOnLaunchBlock {
        return { totalBytes, usedBytes in
            return object(Int(totalBytes), Int(usedBytes))
        }
    }
}
