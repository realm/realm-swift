////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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
import Realm.Private

/**
 `AsymmetricObject` is a base class used to define asymmetric Realm objects.

 Asymmetric objects can only be created using the `create(_ type:, value:)`
 function, and cannot be added, removed or queried.
 When created, asymmetric objects will be synced unidirectionally to the MongoDB
 database and cannot be accessed locally.

 Linking an asymmetric object within an `Object` is not allowed and will throw an error.

 The property types supported on `AsymmetricObject` are the same as for `Object`,
 except for that asymmetric objects can only link to embedded objects, so `Object`
 and `List<Object>` properties are not supported (`EmbeddedObject` and
 `List<EmbeddedObject>` *are*).

 ```swift
 class Person: AsymmetricObject {
     @Persisted(primaryKey: true) var _id: ObjectId
     @Persisted var name: String
     @Persisted var age: Int
 }
 ```
 */
public typealias AsymmetricObject = RealmSwiftAsymmetricObject
extension AsymmetricObject {
    // MARK: Initializers

    /**
     Creates an unmanaged instance of a Realm object.

     The `value` argument is used to populate the object. It can be a key-value coding compliant object, an array or
     dictionary returned from the methods in `NSJSONSerialization`, or an `Array` containing one element for each
     managed property. An exception will be thrown if any required properties are not present and those properties were
     not defined with default values.

     When passing in an `Array` as the `value` argument, all properties must be present, valid and in the same order as
     the properties defined in the model.

     - parameter value:  The value used to populate the object.
     */
    public convenience init(value: Any) {
        self.init()
        RLMInitializeWithValue(self, value, .partialPrivateShared())
    }


    // MARK: Properties

    /// The object schema which lists the managed properties for the object.
    public var objectSchema: ObjectSchema {
        return ObjectSchema(RLMObjectBaseObjectSchema(self)!)
    }

    /// A human-readable description of the object.
    open override var description: String { return super.description }

    /**
     WARNING: This is an internal helper method not intended for public use.
     It is not considered part of the public API.
     :nodoc:
     */
    public override static func _getProperties() -> [RLMProperty] {
        ObjectUtil.getSwiftProperties(self)
    }

    // MARK: Object Customization

    /**
     Override this method to specify a map of public-private property names.
     This will set a different persisted property name on the Realm, and allows using the public name
     for any operation with the property. (Ex: Queries, Sorting, ...).
     This very helpful if you need to map property names from your `Device Sync` JSON schema
     to local property names.

     ```swift
     class Person: AsymmetricObject {
         @Persisted var firstName: String
         @Persisted var birthDate: Date
         @Persisted var age: Int

         override class public func propertiesMapping() -> [String : String] {
             ["firstName": "first_name",
              "birthDate": "birth_date"]
         }
     }
     ```

     - note: Only property that have a different column name have to be added to the properties mapping
     dictionary.

     - returns: A dictionary of public-private property names.
     */
    @objc open override class func propertiesMapping() -> [String: String] { return [:] }

    /// :nodoc:
    @available(*, unavailable, renamed: "propertiesMapping", message: "`_realmColumnNames` private API is unavailable in our Swift SDK, please use the override `.propertiesMapping()` instead.")
    @objc open override class func _realmColumnNames() -> [String: String] { return [:] }

    // MARK: Key-Value Coding & Subscripting

    /// Returns or sets the value of the property with the given name.
    @objc open subscript(key: String) -> Any? {
        get {
            return RLMDynamicGetByName(self, key)
        }
        set {
            dynamicSet(object: self, key: key, value: newValue)
        }
    }
}
