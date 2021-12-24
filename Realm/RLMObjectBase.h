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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RLMRealm;
@class RLMSchema;
@class RLMObjectSchema;

/// :nodoc:
@interface RLMObjectBase : NSObject

@property (nonatomic, readonly, getter = isInvalidated) BOOL invalidated;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

+ (NSString *)className;

// Returns whether the class is included in the default set of classes managed by a Realm.
+ (BOOL)shouldIncludeInDefaultSchema;

+ (nullable NSString *)_realmObjectName;
+ (nullable NSDictionary<NSString *, NSString *> *)_realmColumnNames;

@end

/**
 `Object` is a class used to define Realm model objects.

 In Realm you define your model classes by subclassing `Object` and adding properties to be managed.
 You then instantiate and use your custom subclasses instead of using the `Object` class directly.

 ```swift
 class Dog: Object {
 @objc dynamic var name: String = ""
 @objc dynamic var adopted: Bool = false
 let siblings = List<Dog>()
 }
 ```

 ### Supported property types

 - `String`, `NSString`
 - `Int`
 - `Int8`, `Int16`, `Int32`, `Int64`
 - `Float`
 - `Double`
 - `Bool`
 - `Date`, `NSDate`
 - `Data`, `NSData`
 - `Decimal128`
 - `ObjectId`
 - `@objc enum` which has been delcared as conforming to `RealmEnum`.
 - `RealmOptional<Value>` for optional numeric properties
 - `Object` subclasses, to model many-to-one relationships
 - `EmbeddedObject` subclasses, to model owning one-to-one relationships
 - `List<Element>`, to model many-to-many relationships

 `String`, `NSString`, `Date`, `NSDate`, `Data`, `NSData`, `Decimal128`, and `ObjectId`  properties
 can be declared as optional. `Object` and `EmbeddedObject` subclasses *must* be declared as optional.
 `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `Float`, `Double`, `Bool`,  enum, and `List` properties cannot.
 To store an optional number, use `RealmOptional<Int>`, `RealmOptional<Float>`, `RealmOptional<Double>`, or
 `RealmOptional<Bool>` instead, which wraps an optional numeric value. Lists cannot be optional at all.

 All property types except for `List` and `RealmOptional` *must* be declared as `@objc dynamic var`. `List` and
 `RealmOptional` properties must be declared as non-dynamic `let` properties. Swift `lazy` properties are not allowed.

 Note that none of the restrictions listed above apply to properties that are configured to be ignored by Realm.

 ### Querying

 You can retrieve all objects of a given type from a Realm by calling the `objects(_:)` instance method.

 ### Relationships

 See our [Objective-C guide](https://docs.mongodb.com/realm/sdk/swift/fundamentals/relationships/) for more details.
 */
@interface RealmSwiftObject : RLMObjectBase
@end

/**
 `EmbeddedObject` is a base class used to define embedded Realm model objects.

 Embedded objects work similarly to normal objects, but are owned by a single
 parent Object (which itself may be embedded). Unlike normal top-level objects,
 embedded objects cannot be directly created in or added to a Realm. Instead,
 they can only be created as part of a parent object, or by assigning an
 unmanaged object to a parent object's property. Embedded objects are
 automatically deleted when the parent object is deleted or when the parent is
 modified to no longer point at the embedded object, either by reassigning an
 Object property or by removing the embedded object from the List containing it.

 Embedded objects can only ever have a single parent object which links to
 them, and attempting to link to an existing managed embedded object will throw
 an exception.

 The property types supported on `EmbeddedObject` are the same as for `Object`,
 except for that embedded objects cannot link to top-level objects, so `Object`
 and `List<Object>` properties are not supported (`EmbeddedObject` and
 `List<EmbeddedObject>` *are*).

 Embedded objects cannot have primary keys or indexed properties.

 ```swift
 class Owner: Object {
 @objc dynamic var name: String = ""
 let dogs = List<Dog>()
 }
 class Dog: EmbeddedObject {
 @objc dynamic var name: String = ""
 @objc dynamic var adopted: Bool = false
 let owner = LinkingObjects(fromType: Owner.self, property: "dogs")
 }
 ```
 */
@interface RealmSwiftEmbeddedObject : RLMObjectBase
@end

NS_ASSUME_NONNULL_END
