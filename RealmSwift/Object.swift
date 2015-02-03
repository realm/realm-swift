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

    :param: realm  The Realm in which this object is persisted.
    :param: object The object used to populate the object. This can be any key/value coding compliant
                   object, or a JSON object such as those returned from the methods in `NSJSONSerialization`,
                   or an `Array` with one object for each persisted property. An exception will be
                   thrown if any required properties are not present and no default is set.

                   When passing in an `Array`, all properties must be present,
                   valid and in the same order as the properties defined in the model.

    :returns: The created object.
    */
    public class func createInRealm(realm: Realm, withObject object: AnyObject) -> Self {
        return unsafeBitCast(RLMCreateObjectInRealmWithValue(realm.rlmRealm, className(), object, .allZeros), self)
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
