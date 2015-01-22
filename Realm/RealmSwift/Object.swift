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

import Realm
import Realm.Private

/**
In Realm you define your model classes by subclassing RLMObject and adding properties to be persisted.
You then instantiate and use your custom subclasses instead of using the RLMObject class directly.

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
public class Object : RLMObjectBase, Equatable {

    // MARK: Properties

    /// The Realm this object belongs to, or `nil` if the object
    /// does not belong to a realm (the object is standalone).
    // FIXME: Implement
    // public var realm: Realm? { return }

    /// The ObjectSchema which lists the persisted properties for this object.
    // FIXME: Implement
    // public var objectSchema: ObjectSchema { return }

    /// Indicates if an object can no longer be accessed.
    // FIXME: Implement
    // public var invalidated: Bool { return }

    // MARK: Initializers

    /**
    Initialize a standalone (unpersisted) Object.
    Call `add(_:)` on a `Realm` to add standalone objects to a realm.

    :see: Realm().add(_:)
    */
    public override init() {
	super.init()
    }

    /**
    Initialize a standalone (unpersisted) `Object` with values from an `Array<AnyObject>` or `Dictionary<String, AnyObject>`.
    Call `add(_:)` on a `Realm` to add standalone objects to a realm.

    :param: object The object used to populate the object. This can be any key/value coding compliant
		   object, or a JSON object such as those returned from the methods in `NSJSONSerialization`,
		   or an `Array` with one object for each persisted property. An exception will be
		   thrown if any required properties are not present and no default is set.
    */
    public override init(object: AnyObject) {
	super.init(object: object)
    }

    // MARK: Constructors

    /**
    Create an `Object` in the given `Realm` with the given object.

    Creates an instance of this object and adds it to the given `Realm` populating
    the object with the given object.

    :param: object The object used to populate the object. This can be any key/value coding compliant
		   object, or a JSON object such as those returned from the methods in `NSJSONSerialization`,
		   or an `Array` with one object for each persisted property. An exception will be
		   thrown if any required properties are not present and no default is set.

		   When passing in an `Array`, all properties must be present,
		   valid and in the same order as the properties defined in the model.
    :param: realm  The Realm in which this object is persisted.
		   The default Realm will be used if this argument is omitted.

    :returns: The created object.
    */
    public class func createWithObject(object: AnyObject, inRealm realm: Realm = defaultRealm()) -> Self {
	return unsafeBitCast(RLMCreateObjectInRealmWithValue(realm.rlmRealm, className(), object, .allZeros), self)
    }

    /**
    Create or update an `Object` in the given `Realm` with the given object.

    This method can only be called on object types with a primary key defined. If there is already
    an object with the same primary key value in the specified Realm its values are updated and the object
    is returned. Otherwise this creates and populates a new instance of this object in the specified Realm.

    :param: object The object used to populate the object. This can be any key/value coding compliant
		   object, or a JSON object such as those returned from the methods in `NSJSONSerialization`,
		   or an `Array` with one object for each persisted property. An exception will be
		   thrown if any required properties are not present and no default is set.

		   When passing in an `Array`, all properties must be present,
		   valid and in the same order as the properties defined in the model.
    :param: realm  The Realm in which this object is persisted.
		   The default Realm will be used if this argument is omitted.

    :returns: The created or updated object.

    :see: Object.primaryKey()
    */
    public class func createOrUpdateWithObject(object: AnyObject, inRealm realm: Realm = defaultRealm()) -> Self {
	return unsafeBitCast(RLMCreateObjectInRealmWithValue(realm.rlmRealm, className(), object, .allZeros), self)
    }

    // MARK: Object Retrieval

    /**
    Get the single object with the given primary key from the specified Realm,
    or from the default Realm if the `realm` argument is omitted.

    Returns `nil` if the object does not exist.

    This method requires that `primaryKey()` be overridden on the receiving subclass.

    :see: Object.primaryKey()

    :returns: An object of the subclass type or `nil` if an object with the given primary key does not exist.
    */
    public class func objectForPrimaryKey(key: AnyObject, inRealm realm: Realm = defaultRealm()) -> Self? {
	return unsafeBitCast(RLMGetObject(realm.rlmRealm, className(), key), self)
    }

    // MARK: Customizing

    /**
    Return an array of property names for properties which should be indexed. Only supported
    for string and int properties.

    :returns: `Array` of property names to index.
    */
    public class func indexedProperties() -> [String] { return [] } // FIXME: Use this

    /**
    Override to designate a property as the primary key for an `Object` subclass. Only properties of
    type String and Int can be designated as the primary key. Primary key
    properties enforce uniqueness for each value whenever the property is set which incurs some overhead.
    Indexes are created automatically for string primary key properties.

    :returns: Name of the property designated as the primary key, or `nil` if the model has no primary key.
    */
    public override class func primaryKey() -> String? { return nil } // FIXME: Use this

//    /**
//    Override to return an array of property names to ignore. These properties will not be persisted
//    and are treated as transient.
//
//    :returns: `Array` of property names to ignore.
//    */
//    public class func ignoredProperties() -> [String] { return  [] } // FIXME: Use this
//
//    // MARK: Inverse Relationships
//
//    /**
//    Get an `Array` of objects of type `className` which have this object as the given property value. This can
//    be used to get the inverse relationship value for `Object` and `List` properties.
//
//    @param className   The type of object on which the relationship to query is defined.
//    @param property    The name of the property which defines the relationship.
//
//    :returns: An `Array` of objects of type `className` which have this object as their value for the `propertyName` property.
//    */
//    public func linkingObjectsOfClass(className: String, forProperty propertyName: String) -> [Object] {
//        return unsafeBitCast(self, RLMObject.self).linkingObjectsOfClass(className, forProperty: propertyName) as [Object]
//    }

    // MARK: Property Retrieval

    /// Returns or sets the value of the property with the given name.
    public subscript(key: String) -> AnyObject? {
	get {
	    return super[key]
	}
	set {
	    super[key] = newValue
	}
    }

    // MARK: Private Initializers

    // FIXME: None of these initializers should be exposed in the public interface.

    /**
    WARNING: This is an internal initializer for Realm that must be `public`, but is
	     not intended to be used directly.

    This initializer is called by the Objective-C accessor creation code, and if it's
    not overridden in Swift, the inline property initializers don't get called,
    and we require them for `List<>` properties.

    :param: realm         The realm to which this object belongs.
    :param: schema        The schema for the object's class.
    :param: defaultValues Whether the default values for this model should be used.
    */
    public override init(realm: RLMRealm, schema: RLMObjectSchema, defaultValues: Bool) {
	super.init(realm: realm, schema: schema, defaultValues: defaultValues)
    }

    /**
    WARNING: This is an internal initializer for Realm that must be `public`, but is
	     not intended to be used directly.

    This initializer is called by the Objective-C accessor creation code, and if it's
    not overridden in Swift, the inline property initializers don't get called,
    and we require them for `List<>` properties.

    :param: realm  The realm to which this object belongs.
    :param: schema The realm's schema.
    */
    public override init(object: AnyObject, schema: RLMSchema) {
	super.init(object: object, schema: schema)
    }

    /**
    WARNING: This is an internal initializer for Realm that must be `public`, but is
	     not intended to be used directly.

    This initializer is called by the Objective-C accessor creation code, and if it's
    not overridden in Swift, the inline property initializers don't get called,
    and we require them for `List<>` properties.

    :param: objectSchema The schema for the object's class.
    */
    public override init(objectSchema: RLMObjectSchema) {
	super.init(objectSchema: objectSchema)
    }
}

// MARK: Equatable

/// Returns whether both objects are equal.
public func == <T: Object>(lhs: T, rhs: T) -> Bool {
    return lhs.isEqualToObject(rhs)
}

// FIXME: Move to separate file
/// Internal class. Do not use directly.
public class ObjectUtil : NSObject {
    // Get the names of all properties in the object which are of type List<>
    @objc private class func getGenericListPropertyNames(obj: AnyObject) -> NSArray {
        let reflection = reflect(obj)

        var properties = [String]()

        // Skip the first property (super):
        // super is an implicit property on Swift objects
        for i in 1..<reflection.count {
            let mirror = reflection[i].1
            if mirror.valueType is RLMListBase.Type {
                properties.append(reflection[i].0)
            }
        }

        return properties
    }

}
