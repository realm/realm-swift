////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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
In Realm you define your model classes by subclassing `Object` and adding properties to be persisted.
You then instantiate and use your custom subclasses instead of using the Object class directly.

```swift
class Dog: Object {
    dynamic var name: String = ""
    dynamic var adopted: Bool = false
    let siblings = List<Dog>
}
```

### Supported property types

- `String`
- `Int`
- `Float`
- `Double`
- `Bool`
- `NSDate`
- `NSData`
- `Object` subclasses for to-one relationships
- `List<T: Object>` for to-many relationships

### Querying

You can gets `Results` of an Object subclass via tha `objects(_:)` free function or
the `objects(_:)` instance method on `Realm`.

### Relationships

See our [Cocoa guide](http://realm.io/docs/cocoa) for more details.
*/
public class Object: RLMObjectBase {

    // MARK: Initializers

    /**
    Initialize a standalone (unpersisted) Object.
    Call `add(_:)` on a `Realm` to add standalone objects to a realm.

    - see: Realm().add(_:)
    */
    public required override init() {
        super.init()
    }

    /**
    Initialize a standalone (unpersisted) `Object` with values from an `Array<AnyObject>` or `Dictionary<String, AnyObject>`.
    Call `add(_:)` on a `Realm` to add standalone objects to a realm.

    - parameter value: The value used to populate the object. This can be any key/value coding compliant
                       object, or a JSON object such as those returned from the methods in `NSJSONSerialization`,
                       or an `Array` with one object for each persisted property. An exception will be
                       thrown if any required properties are not present and no default is set.
    */
    public init(value: AnyObject) {
        self.dynamicType.sharedSchema() // ensure this class' objectSchema is loaded in the partialSharedSchema
        super.init(value: value, schema: RLMSchema.partialSharedSchema())
    }


    // MARK: Properties

    /// The `Realm` this object belongs to, or `nil` if the object
    /// does not belong to a realm (the object is standalone).
    public var realm: Realm? {
        if let rlmReam = RLMObjectBaseRealm(self) {
            return Realm(rlmReam)
        }
        return nil
    }

    /// The `ObjectSchema` which lists the persisted properties for this object.
    public var objectSchema: ObjectSchema {
        return ObjectSchema(RLMObjectBaseObjectSchema(self))
    }

    /// Indicates if an object can no longer be accessed.
    public override var invalidated: Bool { return super.invalidated }

    /// Returns a human-readable description of this object.
    public override var description: String { return super.description }

    #if os(OSX)
    /// Helper to return the class name for an Object subclass.
    public final override var className: String { return "" }
    #else
    /// Helper to return the class name for an Object subclass.
    public final var className: String { return "" }
    #endif

    // MARK: Object Customization

    /**
    Override to designate a property as the primary key for an `Object` subclass. Only properties of
    type String and Int can be designated as the primary key. Primary key
    properties enforce uniqueness for each value whenever the property is set which incurs some overhead.
    Indexes are created automatically for primary key properties.

    - returns: Name of the property designated as the primary key, or `nil` if the model has no primary key.
    */
    public class func primaryKey() -> String? { return nil }

    /**
    Override to return an array of property names to ignore. These properties will not be persisted
    and are treated as transient.

    - returns: `Array` of property names to ignore.
    */
    public class func ignoredProperties() -> [String] { return [] }

    /**
    Return an array of property names for properties which should be indexed. Only supported
    for string and int properties.

    - returns: `Array` of property names to index.
    */
    public class func indexedProperties() -> [String] { return [] }


    // MARK: Inverse Relationships

    /**
    Get an `Array` of objects of type `className` which have this object as the given property value. This can
    be used to get the inverse relationship value for `Object` and `List` properties.

    - parameter className: The type of object on which the relationship to query is defined.
    - parameter property:  The name of the property which defines the relationship.

    - returns: A `Results` of objects of type `className` which have this object as their value for the `propertyName` property.
    */
    public func linkingObjects<T: Object>(type: T.Type, forProperty propertyName: String) -> Results<T> {
        // FIXME: use T.className()
        let rlmResults = RLMObjectBaseLinkingObjectsOfClass(self, (T.self as Object.Type).className(), propertyName)
        return Results<T>(rlmResults)
    }

    // MARK: Key-Value Coding & Subscripting

    /// Returns or sets the value of the property with the given name.
    public subscript(key: String) -> AnyObject? {
        get {
            if realm == nil {
                return self.valueForKey(key)
            }
            let property = RLMValidatedGetProperty(self, key)
            if property.type == .Array {
                return self.listForProperty(property)
            }
            return RLMDynamicGet(self, property)
        }
        set(value) {
            if realm == nil {
                self.setValue(value, forKey: key)
            }
            else {
                RLMDynamicValidatedSet(self, key, value)
            }
        }
    }

    // MARK: Equatable

    /// Returns whether both objects are equal.
    /// Objects are considered equal when they are both from the same Realm
    /// and point to the same underlying object in the database.
    public override func isEqual(object: AnyObject?) -> Bool {
        return RLMObjectBaseAreEqual(self as RLMObjectBase?, object as? RLMObjectBase);
    }

    // MARK: Private functions

    // FIXME: None of these functions should be exposed in the public interface.

    /**
    WARNING: This is an internal initializer not intended for public use.
    :nodoc:
    */
    public override init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }

    /**
    WARNING: This is an internal initializer not intended for public use.
    :nodoc:
    */
    public override init(value: AnyObject, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }

    // Helper for getting the list object for a property
    internal func listForProperty(prop: RLMProperty) -> RLMListBase {
        return object_getIvar(self, prop.swiftListIvar) as! RLMListBase
    }
}



/// Object interface which allows untyped getters and setters for Objects.
/// :nodoc:
public final class DynamicObject : Object {
    private var listProperties = [String: List<DynamicObject>]()

    // Override to create List<DynamicObject> on access
    internal override func listForProperty(prop: RLMProperty) -> RLMListBase {
        if let list = listProperties[prop.name] {
            return list
        }
        let list = List<DynamicObject>()
        listProperties[prop.name] = list
        return list
    }

    /// :nodoc:
    public override func valueForUndefinedKey(key: String) -> AnyObject? {
        return self[key]
    }

    /// :nodoc:
    public override func setValue(value: AnyObject?, forUndefinedKey key: String) {
        self[key] = value
    }

    /// :nodoc:
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false;
    }
}

/// :nodoc:
/// Internal class. Do not use directly.
public class ObjectUtil: NSObject {
    @objc private class func ignoredPropertiesForClass(type: AnyClass) -> NSArray? {
        if let type = type as? Object.Type {
            return type.ignoredProperties() as NSArray?
        }
        return nil
    }

    @objc private class func indexedPropertiesForClass(type: AnyClass) -> NSArray? {
        if let type = type as? Object.Type {
            return type.indexedProperties() as NSArray?
        }
        return nil
    }

    // Get the names of all properties in the object which are of type List<>.
    @objc private class func getGenericListPropertyNames(object: AnyObject) -> NSArray {
        return Mirror(reflecting: object).children.filter { (prop: Mirror.Child) in
            return prop.value.dynamicType is RLMListBase.Type
        }.flatMap { (prop: Mirror.Child) in
            return prop.label
        }
    }

    @objc private class func initializeListProperty(object: RLMObjectBase, property: RLMProperty, array: RLMArray) {
        (object as! Object).listForProperty(property)._rlmArray = array
    }

    @objc private class func getOptionalPropertyNames(object: AnyObject) -> NSArray {
        return Mirror(reflecting: object).children.filter { (prop: Mirror.Child) in
            return Mirror(reflecting: prop.value).displayStyle == .Optional
        }.flatMap { (prop: Mirror.Child) in
            return prop.label
        }
    }

    @objc private class func requiredPropertiesForClass(_: AnyClass) -> NSArray? {
        return nil
    }
}
