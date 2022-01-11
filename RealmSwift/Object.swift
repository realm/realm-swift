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
 `Object` is a class used to define Realm model objects.

 In Realm you define your model classes by subclassing `Object` and adding properties to be managed.
 You then instantiate and use your custom subclasses instead of using the `Object` class directly.

 ```swift
 class Dog: Object {
     @Persisted var name: String
     @Persisted var adopted: Bool
     @Persisted var siblings: List<Dog>
 }
 ```

 ### Supported property types

 - `String`
 - `Int`, `Int8`, `Int16`, `Int32`, `Int64`
 - `Float`
 - `Double`
 - `Bool`
 - `Date`
 - `Data`
 - `Decimal128`
 - `ObjectId`
 - `UUID`
 - `AnyRealmValue`
 - Any RawRepresentable enum whose raw type is a legal property type. Enums
   must explicitly be marked as conforming to `PersistableEnum`.
 - `Object` subclasses, to model many-to-one relationships
 - `EmbeddedObject` subclasses, to model owning one-to-one relationships

 All of the types above may also be `Optional`, with the exception of
 `AnyRealmValue`. `Object` and `EmbeddedObject` subclasses *must* be Optional.

 In addition to individual values, three different collection types are supported:
 - `List<Element>`: an ordered mutable collection similar to `Array`.
 - `MutableSet<Element>`: an unordered uniquing collection similar to `Set`.
 - `Map<String, Element>`: an unordered key-value collection similar to `Dictionary`.

 The Element type of collections may be any of the supported non-collection
 property types listed above. Collections themselves may not be Optional, but
 the values inside them may be, except for lists and sets of `Object` or
 `EmbeddedObject` subclasses.

 Finally, `LinkingObjects` properties can be used to track which objects link
 to this one.

 All properties which should be stored by Realm must be explicitly marked with
 `@Persisted`. Any properties not marked with `@Persisted` will be ignored
 entirely by Realm, and may be of any type.

 ### Querying

 You can retrieve all objects of a given type from a Realm by calling the `objects(_:)` instance method.

 ### Relationships

 See our [Swift guide](https://docs.mongodb.com/realm/sdk/swift/fundamentals/relationships/) for more details.
 */
public typealias Object = RealmSwiftObject
extension Object: _RealmCollectionValueInsideOptional {
    // MARK: Initializers

    /**
     Creates an unmanaged instance of a Realm object.

     The `value` argument is used to populate the object. It can be a key-value coding compliant object, an array or
     dictionary returned from the methods in `NSJSONSerialization`, or an `Array` containing one element for each
     managed property. An exception will be thrown if any required properties are not present and those properties were
     not defined with default values.

     When passing in an `Array` as the `value` argument, all properties must be present, valid and in the same order as
     the properties defined in the model.

     Call `add(_:)` on a `Realm` instance to add an unmanaged object into that Realm.

     - parameter value:  The value used to populate the object.
     */
    public convenience init(value: Any) {
        self.init()
        RLMInitializeWithValue(self, value, .partialPrivateShared())
    }


    // MARK: Properties

    /// The Realm which manages the object, or `nil` if the object is unmanaged.
    public var realm: Realm? {
        if let rlmReam = RLMObjectBaseRealm(self) {
            return Realm(rlmReam)
        }
        return nil
    }

    /// The object schema which lists the managed properties for the object.
    public var objectSchema: ObjectSchema {
        return ObjectSchema(RLMObjectBaseObjectSchema(self)!)
    }

    /// Indicates if the object can no longer be accessed because it is now invalid.
    ///
    /// An object can no longer be accessed if the object has been deleted from the Realm that manages it, or if
    /// `invalidate()` is called on that Realm. This property is key-value observable.
    @objc dynamic open override var isInvalidated: Bool { return super.isInvalidated }

    /// A human-readable description of the object.
    open override var description: String { return super.description }

    /**
     WARNING: This is an internal helper method not intended for public use.
     It is not considered part of the public API.
     :nodoc:
     */
    public override final class func _getProperties() -> [RLMProperty] {
        return ObjectUtil.getSwiftProperties(self)
    }

    // MARK: Object Customization

    /**
     Override this method to specify the name of a property to be used as the primary key.

     Only properties of types `String`, `Int`, `ObjectId` and `UUID` can be
     designated as the primary key. Primary key properties enforce uniqueness
     for each value whenever the property is set, which incurs minor overhead.
     Indexes are created automatically for primary key properties.

     - warning: This function is only applicable to legacy property declarations
                using `@objc`. When using `@Persisted`, use
                `@Persisted(primaryKey: true)` instead.
     - returns: The name of the property designated as the primary key, or
                `nil` if the model has no primary key.
     */
    @objc open class func primaryKey() -> String? { return nil }

    /**
     Override this method to specify the names of properties to ignore. These
     properties will not be managed by the Realm that manages the object.

     - warning: This function is only applicable to legacy property declarations
                using `@objc`. When using `@Persisted`, any properties not
                marked with `@Persisted` are automatically ignored.
     - returns: An array of property names to ignore.
     */
    @objc open class func ignoredProperties() -> [String] { return [] }

    /**
     Returns an array of property names for properties which should be indexed.

     Only string, integer, boolean, `Date`, and `NSDate` properties are supported.

     - warning: This function is only applicable to legacy property declarations
                using `@objc`. When using `@Persisted`, use
                `@Persisted(indexed: true)` instead.
     - returns: An array of property names.
     */
    @objc open class func indexedProperties() -> [String] { return [] }

    // MARK: Key-Value Coding & Subscripting

    /// Returns or sets the value of the property with the given name.
    @objc open subscript(key: String) -> Any? {
        get {
            RLMDynamicGetByName(self, key)
        }
        set {
            dynamicSet(object: self, key: key, value: newValue)
        }
    }

    // MARK: Notifications

    /**
     Registers a block to be called each time the object changes.

     The block will be asynchronously called after each write transaction which
     deletes the object or modifies any of the managed properties of the object,
     including self-assignments that set a property to its existing value.

     For write transactions performed on different threads or in different
     processes, the block will be called when the managing Realm is
     (auto)refreshed to a version including the changes, while for local write
     transactions it will be called at some point in the future after the write
     transaction is committed.

     If no key paths are given, the block will be executed on any insertion,
     modification, or deletion for all object properties and the properties of
     any nested, linked objects. If a key path or key paths are provided,
     then the block will be called for changes which occur only on the
     provided key paths. For example, if:
     ```swift
     class Dog: Object {
         @Persisted var name: String
         @Persisted var adopted: Bool
         @Persisted var siblings: List<Dog>
     }

     // ... where `dog` is a managed Dog object.
     dog.observe(keyPaths: ["adopted"], { changes in
        // ...
     })
     ```
     - The above notification block fires for changes to the
     `adopted` property, but not for any changes made to `name`.
     - If the observed key path were `["siblings"]`, then any insertion,
     deletion, or modification to the `siblings` list will trigger the block. A change to
     `someSibling.name` would not trigger the block (where `someSibling`
     is an element contained in `siblings`)
     - If the observed key path were `["siblings.name"]`, then any insertion or
     deletion to the `siblings` list would trigger the block. For objects
     contained in the `siblings` list, only modifications to their `name` property
     will trigger the block.

     - note: Multiple notification tokens on the same object which filter for
     separate key paths *do not* filter exclusively. If one key path
     change is satisfied for one notification token, then all notification
     token blocks for that object will execute.

     If no queue is given, notifications are delivered via the standard run
     loop, and so can't be delivered while the run loop is blocked by other
     activity. If a queue is given, notifications are delivered to that queue
     instead. When notifications can't be delivered instantly, multiple
     notifications may be coalesced into a single notification.

     Unlike with `List` and `Results`, there is no "initial" callback made after
     you add a new notification block.

     Only objects which are managed by a Realm can be observed in this way. You
     must retain the returned token for as long as you want updates to be sent
     to the block. To stop receiving updates, call `invalidate()` on the token.

     It is safe to capture a strong reference to the observed object within the
     callback block. There is no retain cycle due to that the callback is
     retained by the returned token and not by the object itself.

     - warning: This method cannot be called during a write transaction, or when
                the containing Realm is read-only.
     - parameter keyPaths: Only properties contained in the key paths array will trigger
                           the block when they are modified. If `nil`, notifications
                           will be delivered for any property change on the object.
                           String key paths which do not correspond to a valid a property
                           will throw an exception.
                           See description above for more detail on linked properties.
     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to call with information about changes to the object.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe<T: RLMObjectBase>(keyPaths: [String]? = nil,
                                          on queue: DispatchQueue? = nil,
                                          _ block: @escaping (ObjectChange<T>) -> Void) -> NotificationToken {
        return _observe(keyPaths: keyPaths, on: queue, block)
    }

    /**
     Registers a block to be called each time the object changes.

     The block will be asynchronously called after each write transaction which
     deletes the object or modifies any of the managed properties of the object,
     including self-assignments that set a property to its existing value.

     For write transactions performed on different threads or in different
     processes, the block will be called when the managing Realm is
     (auto)refreshed to a version including the changes, while for local write
     transactions it will be called at some point in the future after the write
     transaction is committed.

     If no key paths are given, the block will be executed on any insertion,
     modification, or deletion for all object properties and the properties of
     any nested, linked objects. If a key path or key paths are provided,
     then the block will be called for changes which occur only on the
     provided key paths. For example, if:
     ```swift
     class Dog: Object {
         @Persisted var name: String
         @Persisted var adopted: Bool
         @Persisted var siblings: List<Dog>
     }

     // ... where `dog` is a managed Dog object.
     dog.observe(keyPaths: [\Dog.adopted], { changes in
        // ...
     })
     ```
     - The above notification block fires for changes to the
     `adopted` property, but not for any changes made to `name`.
     - If the observed key path were `[\Dog.siblings]`, then any insertion,
     deletion, or modification to the `siblings` list will trigger the block. A change to
     `someSibling.name` would not trigger the block (where `someSibling`
     is an element contained in `siblings`)
     - If the observed key path were `[\Dog.siblings.name]`, then any insertion or
     deletion to the `siblings` list would trigger the block. For objects
     contained in the `siblings` list, only modifications to their `name` property
     will trigger the block.

     - note: Multiple notification tokens on the same object which filter for
     separate key paths *do not* filter exclusively. If one key path
     change is satisfied for one notification token, then all notification
     token blocks for that object will execute.

     If no queue is given, notifications are delivered via the standard run
     loop, and so can't be delivered while the run loop is blocked by other
     activity. If a queue is given, notifications are delivered to that queue
     instead. When notifications can't be delivered instantly, multiple
     notifications may be coalesced into a single notification.

     Unlike with `List` and `Results`, there is no "initial" callback made after
     you add a new notification block.

     Only objects which are managed by a Realm can be observed in this way. You
     must retain the returned token for as long as you want updates to be sent
     to the block. To stop receiving updates, call `invalidate()` on the token.

     It is safe to capture a strong reference to the observed object within the
     callback block. There is no retain cycle due to that the callback is
     retained by the returned token and not by the object itself.

     - warning: This method cannot be called during a write transaction, or when
                the containing Realm is read-only.
     - parameter keyPaths: Only properties contained in the key paths array will trigger
                           the block when they are modified. If `nil`, notifications
                           will be delivered for any property change on the object.
                           See description above for more detail on linked properties.
     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to call with information about changes to the object.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe<T: ObjectBase>(keyPaths: [PartialKeyPath<T>],
                                       on queue: DispatchQueue? = nil,
                                       _ block: @escaping (ObjectChange<T>) -> Void) -> NotificationToken {
        return _observe(keyPaths: keyPaths.map(_name(for:)), on: queue, block)
    }

    // MARK: Dynamic list

    /**
     Returns a list of `DynamicObject`s for a given property name.

     - warning:  This method is useful only in specialized circumstances, for example, when building
     components that integrate with Realm. If you are simply building an app on Realm, it is
     recommended to use instance variables or cast the values returned from key-value coding.

     - parameter propertyName: The name of the property.

     - returns: A list of `DynamicObject`s.

     :nodoc:
     */
    public func dynamicList(_ propertyName: String) -> List<DynamicObject> {
        if let dynamic = self as? DynamicObject {
            return dynamic[propertyName] as! List<DynamicObject>
        }
        let list = RLMDynamicGetByName(self, propertyName) as! RLMSwiftCollectionBase
        return List<DynamicObject>(collection: list._rlmCollection as! RLMArray<AnyObject>)
    }

    // MARK: Dynamic set

    /**
     Returns a set of `DynamicObject`s for a given property name.

     - warning:  This method is useful only in specialized circumstances, for example, when building
     components that integrate with Realm. If you are simply building an app on Realm, it is
     recommended to use instance variables or cast the values returned from key-value coding.

     - parameter propertyName: The name of the property.

     - returns: A set of `DynamicObject`s.

     :nodoc:
     */
    public func dynamicMutableSet(_ propertyName: String) -> MutableSet<DynamicObject> {
        if let dynamic = self as? DynamicObject {
            return dynamic[propertyName] as! MutableSet<DynamicObject>
        }
        let set = RLMDynamicGetByName(self, propertyName) as! RLMSwiftCollectionBase
        return MutableSet<DynamicObject>(collection: set._rlmCollection as! RLMSet<AnyObject>)
    }

    // MARK: Dynamic map

    /**
     Returns a map of `DynamicObject`s for a given property name.

     - warning:  This method is useful only in specialized circumstances, for example, when building
     components that integrate with Realm. If you are simply building an app on Realm, it is
     recommended to use instance variables or cast the values returned from key-value coding.

     - parameter propertyName: The name of the property.

     - returns: A map with a given key type with `DynamicObject` as the value.

     :nodoc:
     */
    public func dynamicMap<Key: _MapKey>(_ propertyName: String) -> Map<Key, DynamicObject?> {
        if let dynamic = self as? DynamicObject {
            return dynamic[propertyName] as! Map<Key, DynamicObject?>
        }
        let base = RLMDynamicGetByName(self, propertyName) as! RLMSwiftCollectionBase
        return Map<Key, DynamicObject?>(objc: base._rlmCollection as! RLMDictionary<AnyObject, AnyObject>)
    }

    // MARK: Comparison
    /**
     Returns whether two Realm objects are the same.

     Objects are considered the same if and only if they are both managed by the same
     Realm and point to the same underlying object in the database.

     - note: Equality comparison is implemented by `isEqual(_:)`. If the object type
             is defined with a primary key, `isEqual(_:)` behaves identically to this
             method. If the object type is not defined with a primary key,
             `isEqual(_:)` uses the `NSObject` behavior of comparing object identity.
             This method can be used to compare two objects for database equality
             whether or not their object type defines a primary key.

     - parameter object: The object to compare the receiver to.
     */
    public func isSameObject(as object: Object?) -> Bool {
        return RLMObjectBaseAreEqual(self, object)
    }
}

extension Object: ThreadConfined {
    /**
     Indicates if this object is frozen.

     - see: `Object.freeze()`
     */
    public var isFrozen: Bool { return realm?.isFrozen ?? false }

    /**
     Returns a frozen (immutable) snapshot of this object.

     The frozen copy is an immutable object which contains the same data as this
     object currently contains, but will not update when writes are made to the
     containing Realm. Unlike live objects, frozen objects can be accessed from any
     thread.

     - warning: Holding onto a frozen object for an extended period while performing write
     transaction on the Realm may result in the Realm file growing to large sizes. See
     `Realm.Configuration.maximumNumberOfActiveVersions` for more information.
     - warning: This method can only be called on a managed object.
     */
    public func freeze() -> Self {
        guard let realm = realm else { throwRealmException("Unmanaged objects cannot be frozen.") }
        return realm.freeze(self)
    }

    /**
     Returns a live (mutable) reference of this object.

     This method creates a managed accessor to a live copy of the same frozen object.
     Will return self if called on an already live object.
     */
    public func thaw() -> Self? {
        guard let realm = realm else { throwRealmException("Unmanaged objects cannot be thawed.") }
        return realm.thaw(self)
    }
}

/**
 Information about a specific property which changed in an `Object` change notification.
 */
@frozen public struct PropertyChange {
    /**
     The name of the property which changed.
    */
    public let name: String

    /**
     Value of the property before the change occurred. This is not supplied if
     the change happened on the same thread as the notification and for `List`
     properties.

     For object properties this will give the object which was previously
     linked to, but that object will have its new values and not the values it
     had before the changes. This means that `previousValue` may be a deleted
     object, and you will need to check `isInvalidated` before accessing any
     of its properties.
    */
    public let oldValue: Any?

    /**
     The value of the property after the change occurred. This is not supplied
     for `List` properties and will always be nil.
    */
    public let newValue: Any?
}

/**
 Information about the changes made to an object which is passed to `Object`'s
 notification blocks.
 */
@frozen public enum ObjectChange<T> {
    /**
     If an error occurs, notification blocks are called one time with a `.error`
     result and an `NSError` containing details about the error. Currently the
     only errors which can occur are when opening the Realm on a background
     worker thread to calculate the change set. The callback will never be
     called again after `.error` is delivered.
     */
    case error(_ error: NSError)
    /**
     One or more of the properties of the object have been changed.
     */
    case change(_: T, _: [PropertyChange])
    /// The object has been deleted from the Realm.
    case deleted
}

/// Object interface which allows untyped getters and setters for Objects.
/// :nodoc:
@objc(RealmSwiftDynamicObject)
@dynamicMemberLookup
public final class DynamicObject: Object {
    public override subscript(key: String) -> Any? {
        get {
            let value = RLMDynamicGetByName(self, key).flatMap(coerceToNil)
            if let array = value as? RLMArray<AnyObject> {
                return list(from: array)
            }
            if let set = value as? RLMSet<AnyObject> {
                return mutableSet(from: set)
            }
            if let dictionary = value as? RLMDictionary<AnyObject, AnyObject> {
                return map(from: dictionary)
            }
            return value
        }
        set(value) {
            RLMDynamicValidatedSet(self, key, value)
        }
    }

    public subscript(dynamicMember member: String) -> Any? {
        get {
            self[member]
        }
        set(value) {
            self[member] = value
        }
    }

    /// :nodoc:
    public override func value(forUndefinedKey key: String) -> Any? {
        return self[key]
    }

    /// :nodoc:
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        self[key] = value
    }

    /// :nodoc:
    public override class func shouldIncludeInDefaultSchema() -> Bool {
        return false
    }

    override public class func sharedSchema() -> RLMObjectSchema? {
        nil
    }

    private func list(from array: RLMArray<AnyObject>) -> Any {
        switch array.type {
        case .int:
            return array.isOptional ? List<Int?>(collection: array) : List<Int>(collection: array)
        case .double:
            return array.isOptional ? List<Double?>(collection: array) : List<Double>(collection: array)
        case .float:
            return array.isOptional ? List<Float?>(collection: array) : List<Float>(collection: array)
        case .decimal128:
            return array.isOptional ? List<Decimal128?>(collection: array) : List<Decimal128>(collection: array)
        case .bool:
            return array.isOptional ? List<Bool?>(collection: array) : List<Bool>(collection: array)
        case .UUID:
            return array.isOptional ? List<UUID?>(collection: array) : List<UUID>(collection: array)
        case .string:
            return array.isOptional ? List<String?>(collection: array) : List<String>(collection: array)
        case .data:
            return array.isOptional ? List<Data?>(collection: array) : List<Data>(collection: array)
        case .date:
            return array.isOptional ? List<Date?>(collection: array) : List<Date>(collection: array)
        case .any:
            return List<AnyRealmValue>(collection: array)
        case .linkingObjects:
            throwRealmException("Unsupported migration type of 'LinkingObjects' for type 'List'.")
        case .objectId:
            return array.isOptional ? List<ObjectId?>(collection: array) : List<ObjectId>(collection: array)
        case .object:
            return List<DynamicObject>(collection: array)
        }
    }

    private func mutableSet(from set: RLMSet<AnyObject>) -> Any {
        switch set.type {
        case .int:
            return set.isOptional ? MutableSet<Int?>(collection: set) : MutableSet<Int>(collection: set)
        case .double:
            return set.isOptional ? MutableSet<Double?>(collection: set) : MutableSet<Double>(collection: set)
        case .float:
            return set.isOptional ? MutableSet<Float?>(collection: set) : MutableSet<Float>(collection: set)
        case .decimal128:
            return set.isOptional ? MutableSet<Decimal128?>(collection: set) : MutableSet<Decimal128>(collection: set)
        case .bool:
            return set.isOptional ? MutableSet<Bool?>(collection: set) : MutableSet<Bool>(collection: set)
        case .UUID:
            return set.isOptional ? MutableSet<UUID?>(collection: set) : MutableSet<UUID>(collection: set)
        case .string:
            return set.isOptional ? MutableSet<String?>(collection: set) : MutableSet<String>(collection: set)
        case .data:
            return set.isOptional ? MutableSet<Data?>(collection: set) : MutableSet<Data>(collection: set)
        case .date:
            return set.isOptional ? MutableSet<Date?>(collection: set) : MutableSet<Date>(collection: set)
        case .any:
            return MutableSet<AnyRealmValue>(collection: set)
        case .linkingObjects:
            throwRealmException("Unsupported migration type of 'LinkingObjects' for type 'MutableSet'.")
        case .objectId:
            return set.isOptional ? MutableSet<ObjectId?>(collection: set) : MutableSet<ObjectId>(collection: set)
        case .object:
            return MutableSet<DynamicObject>(collection: set)
        }
    }

    private func map(from dictionary: RLMDictionary<AnyObject, AnyObject>) -> Any {
        switch dictionary.type {
        case .int:
            return dictionary.isOptional ? Map<String, Int?>(objc: dictionary) : Map<String, Int>(objc: dictionary)
        case .double:
            return dictionary.isOptional ? Map<String, Double?>(objc: dictionary) : Map<String, Double>(objc: dictionary)
        case .float:
            return dictionary.isOptional ? Map<String, Float?>(objc: dictionary) : Map<String, Float>(objc: dictionary)
        case .decimal128:
            return dictionary.isOptional ? Map<String, Decimal128?>(objc: dictionary) : Map<String, Decimal128>(objc: dictionary)
        case .bool:
            return dictionary.isOptional ? Map<String, Bool?>(objc: dictionary) : Map<String, Bool>(objc: dictionary)
        case .UUID:
            return dictionary.isOptional ? Map<String, UUID?>(objc: dictionary) : Map<String, UUID>(objc: dictionary)
        case .string:
            return dictionary.isOptional ? Map<String, String?>(objc: dictionary) : Map<String, String>(objc: dictionary)
        case .data:
            return dictionary.isOptional ? Map<String, Data?>(objc: dictionary) : Map<String, Data>(objc: dictionary)
        case .date:
            return dictionary.isOptional ? Map<String, Date?>(objc: dictionary) : Map<String, Date>(objc: dictionary)
        case .any:
            return Map<String, AnyRealmValue>(objc: dictionary)
        case .linkingObjects:
            throwRealmException("Unsupported migration type of 'LinkingObjects' for type 'Map'.")
        case .objectId:
            return dictionary.isOptional ? Map<String, ObjectId?>(objc: dictionary) : Map<String, ObjectId>(objc: dictionary)
        case .object:
            return Map<String, DynamicObject?>(objc: dictionary)
        }
    }
}

/**
 An enum type which can be stored on a Realm Object.

 Only `@objc` enums backed by an Int can be stored on a Realm object, and the
 enum type must explicitly conform to this protocol. For example:

 ```
 @objc enum MyEnum: Int, RealmEnum {
    case first = 1
    case second = 2
    case third = 7
 }

 class MyModel: Object {
    @objc dynamic enumProperty = MyEnum.first
    let optionalEnumProperty = RealmOptional<MyEnum>()
 }
 ```
 */
public protocol RealmEnum: RealmOptionalType, _RealmSchemaDiscoverable {
}

// MARK: - Implementation

/// :nodoc:
public extension RealmEnum where Self: RawRepresentable, Self.RawValue: _RealmSchemaDiscoverable & _ObjcBridgeable {
    var _rlmObjcValue: Any { rawValue._rlmObjcValue }
    static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Self? {
        if let value = value as? Self {
            return value
        }
        if let value = value as? RawValue {
            return Self(rawValue: value)
        }
        return nil
    }
    static func _rlmPopulateProperty(_ prop: RLMProperty) {
        RawValue._rlmPopulateProperty(prop)
    }
    static var _rlmType: PropertyType { RawValue._rlmType }
}

internal func dynamicSet(object: ObjectBase, key: String, value: Any?) {
    let bridgedValue: Any?
    if let v1 = value, let v2 = v1 as AnyObject as? _ObjcBridgeable {
        bridgedValue = v2._rlmObjcValue
    } else {
        bridgedValue = value
    }
    if RLMObjectBaseRealm(object) == nil {
        object.setValue(bridgedValue, forKey: key)
    } else {
        RLMDynamicValidatedSet(object, key, bridgedValue)
    }
}
