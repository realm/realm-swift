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
 - `@objc enum` which has been delcared as conforming to `RealmEnum`.
 - `RealmOptional<Value>` for optional numeric properties
 - `Object` subclasses, to model many-to-one relationships
 - `List<Element>`, to model many-to-many relationships

 `String`, `NSString`, `Date`, `NSDate`, `Data`, `NSData` and `Object` subclass properties can be declared as optional.
 `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `Float`, `Double`, `Bool`,  enum, and `List` properties cannot.
 To store an optional number, use `RealmOptional<Int>`, `RealmOptional<Float>`, `RealmOptional<Double>`, or
 `RealmOptional<Bool>` instead, which wraps an optional numeric value. Lists cannot be optional at all.

 All property types except for `List` and `RealmOptional` *must* be declared as `@objc dynamic var`. `List` and
 `RealmOptional` properties must be declared as non-dynamic `let` properties. Swift `lazy` properties are not allowed.

 Note that none of the restrictions listed above apply to properties that are configured to be ignored by Realm.

 ### Querying

 You can retrieve all objects of a given type from a Realm by calling the `objects(_:)` instance method.

 ### Relationships

 See our [Cocoa guide](http://realm.io/docs/cocoa) for more details.
 */
@objc(RealmSwiftObject)
open class Object: RLMObjectBase, ThreadConfined, RealmCollectionValue {
    /// :nodoc:
    public static func _rlmArray() -> RLMArray<AnyObject> {
        return RLMArray(objectClassName: className())
    }

    // MARK: Initializers

    /**
     Creates an unmanaged instance of a Realm object.

     Call `add(_:)` on a `Realm` instance to add an unmanaged object into that Realm.

     - see: `Realm().add(_:)`
     */
    public override required init() {
        super.init()
    }

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
    /// `invalidate()` is called on that Realm.
    public override final var isInvalidated: Bool { return super.isInvalidated }

    /// A human-readable description of the object.
    open override var description: String { return super.description }

    /**
     WARNING: This is an internal helper method not intended for public use.
     It is not considered part of the public API.
     :nodoc:
     */
    public override final class func _getProperties(withInstance instance: Any) -> [RLMProperty] {
        return ObjectUtil.getSwiftProperties(instance as! RLMObjectBase)
    }

    // MARK: Object Customization

    /**
     Override this method to specify the name of a property to be used as the primary key.

     Only properties of types `String` and `Int` can be designated as the primary key. Primary key properties enforce
     uniqueness for each value whenever the property is set, which incurs minor overhead. Indexes are created
     automatically for primary key properties.

     - returns: The name of the property designated as the primary key, or `nil` if the model has no primary key.
     */
    @objc open class func primaryKey() -> String? { return nil }

    /**
     Override this method to specify the names of properties to ignore. These properties will not be managed by
     the Realm that manages the object.

     - returns: An array of property names to ignore.
     */
    @objc open class func ignoredProperties() -> [String] { return [] }

    /**
     Returns an array of property names for properties which should be indexed.

     Only string, integer, boolean, `Date`, and `NSDate` properties are supported.

     - returns: An array of property names.
     */
    @objc open class func indexedProperties() -> [String] { return [] }

    // MARK: Key-Value Coding & Subscripting

    /// Returns or sets the value of the property with the given name.
    @objc open subscript(key: String) -> Any? {
        get {
            if realm == nil {
                return value(forKey: key)
            }
            return dynamicGet(key: key)
        }
        set(value) {
            if realm == nil {
                setValue(value, forKey: key)
            } else {
                RLMDynamicValidatedSet(self, key, value)
            }
        }
    }

    private func dynamicGet(key: String) -> Any? {
        let objectSchema = RLMObjectBaseObjectSchema(self)!
        guard let prop = objectSchema[key] else {
            throwRealmException("Invalid property name '\(key) for class \(objectSchema.className)")
        }
        if let accessor = prop.swiftAccessor {
            return accessor.get(Unmanaged.passUnretained(self).toOpaque() + ivar_getOffset(prop.swiftIvar!))
        }
        if let ivar = prop.swiftIvar, prop.array {
            return object_getIvar(self, ivar)
        }
        return RLMDynamicGet(self, prop)
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

     Notifications are delivered via the standard run loop, and so can't be
     delivered while the run loop is blocked by other activity. When
     notifications can't be delivered instantly, multiple notifications may be
     coalesced into a single notification.

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

     - parameter block: The block to call with information about changes to the object.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe(_ block: @escaping (ObjectChange) -> Void) -> NotificationToken {
        return RLMObjectAddNotificationBlock(self, { names, oldValues, newValues, error in
            if let error = error {
                block(.error(error as NSError))
                return
            }
            guard let names = names, let newValues = newValues else {
                block(.deleted)
                return
            }

            block(.change((0..<newValues.count).map { i in
                PropertyChange(name: names[i], oldValue: oldValues?[i], newValue: newValues[i])
            }))
        })
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
        return noWarnUnsafeBitCast(dynamicGet(key: propertyName) as! RLMListBase,
                                   to: List<DynamicObject>.self)
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

/**
 Information about a specific property which changed in an `Object` change notification.
 */
public struct PropertyChange {
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
public enum ObjectChange {
    /**
     If an error occurs, notification blocks are called one time with a `.error`
     result and an `NSError` containing details about the error. Currently the
     only errors which can occur are when opening the Realm on a background
     worker thread to calculate the change set. The callback will never be
     called again after `.error` is delivered.
     */
    case error(_: NSError)
    /**
     One or more of the properties of the object have been changed.
     */
    case change(_: [PropertyChange])
    /// The object has been deleted from the Realm.
    case deleted
}

/// Object interface which allows untyped getters and setters for Objects.
/// :nodoc:
public final class DynamicObject: Object {
    public override subscript(key: String) -> Any? {
        get {
            let value = RLMDynamicGetByName(self, key)
            if let array = value as? RLMArray<AnyObject> {
                return List<DynamicObject>(rlmArray: array)
            }
            return value
        }
        set(value) {
            RLMDynamicValidatedSet(self, key, value)
        }
    }

    /// :nodoc:
    public override func dynamicList(_ propertyName: String) -> List<DynamicObject> {
        return self[propertyName] as! List<DynamicObject>
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
}

/**
 An enum type which can be stored on a Realm Object.

 Only `@objc` enums backed by an Int can be stored on a Realm object, and the
 enum type must explicitly conform to this protocol. For example:

 ```
 @objc enum class MyEnum: Int, RealmEnum {
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
public protocol RealmEnum: RealmOptionalType, _ManagedPropertyType {
    /// :nodoc:
    // swiftlint:disable:next identifier_name
    static func _rlmToRawValue(_ value: Any) -> Any
    /// :nodoc:
    // swiftlint:disable:next identifier_name
    static func _rlmFromRawValue(_ value: Any) -> Any
}

// MARK: - Implementation

/// :nodoc:
public extension RealmEnum where Self: RawRepresentable, Self.RawValue: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    static func _rlmToRawValue(_ value: Any) -> Any {
        return (value as! Self).rawValue
    }
    // swiftlint:disable:next identifier_name
    static func _rlmFromRawValue(_ value: Any) -> Any {
        return Self.init(rawValue: value as! RawValue)!
    }
    // swiftlint:disable:next identifier_name
    static func _rlmProperty(_ prop: RLMProperty) {
        RawValue._rlmProperty(prop)
    }
}

// A type which can be a managed property on a Realm object
/// :nodoc:
public protocol _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    func _rlmProperty(_ prop: RLMProperty)
    // swiftlint:disable:next identifier_name
    static func _rlmProperty(_ prop: RLMProperty)
    // swiftlint:disable:next identifier_name
    static func _rlmRequireObjc() -> Bool
}
/// :nodoc:
extension _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public func _rlmProperty(_ prop: RLMProperty) { }
    // swiftlint:disable:next identifier_name
    public static func _rlmRequireObjc() -> Bool { return true }
}

/// :nodoc:
extension Int: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .int
    }
}
/// :nodoc:
extension Int8: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .int
    }
}
/// :nodoc:
extension Int16: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .int
    }
}
/// :nodoc:
extension Int32: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .int
    }
}
/// :nodoc:
extension Int64: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .int
    }
}
/// :nodoc:
extension Float: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .float
    }
}
/// :nodoc:
extension Double: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .double
    }
}
/// :nodoc:
extension Bool: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .bool
    }
}
/// :nodoc:
extension String: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .string
    }
}
/// :nodoc:
extension NSString: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .string
    }
}
/// :nodoc:
extension Data: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .data
    }
}
/// :nodoc:
extension NSData: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .data
    }
}
/// :nodoc:
extension Date: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .date
    }
}
/// :nodoc:
extension NSDate: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.type = .date
    }
}

/// :nodoc:
extension Object: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        if !prop.optional && !prop.array {
            throwRealmException("Object property '\(prop.name)' must be marked as optional.")
        }
        if prop.optional && prop.array {
            throwRealmException("List<\(className())> property '\(prop.name)' must not be marked as optional.")
        }
        prop.type = .object
        prop.objectClassName = className()
    }
}

/// :nodoc:
extension List: _ManagedPropertyType where Element: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.array = true
        Element._rlmProperty(prop)
    }
    // swiftlint:disable:next identifier_name
    public static func _rlmRequireObjc() -> Bool { return false }
}

/// :nodoc:
class LinkingObjectsAccessor<Element: Object>: RLMManagedPropertyAccessor {
    @objc override class func initializeObject(_ ptr: UnsafeMutableRawPointer,
                                               parent: RLMObjectBase, property: RLMProperty) {
        ptr.assumingMemoryBound(to: LinkingObjects.self).pointee.handle = RLMLinkingObjectsHandle(object: parent, property: property)
    }
    @objc override class func get(_ ptr: UnsafeMutableRawPointer) -> Any {
        return ptr.assumingMemoryBound(to: LinkingObjects<Element>.self).pointee
    }
}

/// :nodoc:
extension LinkingObjects: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.array = true
        prop.type = .linkingObjects
        prop.objectClassName = Element.className()
        prop.swiftAccessor = LinkingObjectsAccessor<Element>.self
    }
    // swiftlint:disable:next identifier_name
    public func _rlmProperty(_ prop: RLMProperty) {
        prop.linkOriginPropertyName = self.propertyName
    }
    // swiftlint:disable:next identifier_name
    public static func _rlmRequireObjc() -> Bool { return false }
}

/// :nodoc:
extension Optional: _ManagedPropertyType where Wrapped: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.optional = true
        Wrapped._rlmProperty(prop)
    }
}

/// :nodoc:
extension RealmOptional: _ManagedPropertyType where Value: _ManagedPropertyType {
    // swiftlint:disable:next identifier_name
    public static func _rlmProperty(_ prop: RLMProperty) {
        prop.optional = true
        Value._rlmProperty(prop)
    }
    // swiftlint:disable:next identifier_name
    public static func _rlmRequireObjc() -> Bool { return false }
}

/// :nodoc:
internal class ObjectUtil {
    private static let runOnce: Void = {
        RLMSwiftAsFastEnumeration = { (obj: Any) -> Any? in
            // Intermediate cast to AnyObject due to https://bugs.swift.org/browse/SR-8651
            if let collection = obj as AnyObject as? _RealmCollectionEnumerator {
                return collection._asNSFastEnumerator()
            }
            return nil
        }
    }()

    private class func swiftVersion() -> NSString {
#if SWIFT_PACKAGE
        return "5.1"
#else
        return swiftLanguageVersion as NSString
#endif
    }

    // If the property is a storage property for a lazy Swift property, return
    // the base property name (e.g. `foo.storage` becomes `foo`). Otherwise, nil.
    private static func baseName(forLazySwiftProperty name: String) -> String? {
        // A Swift lazy var shows up as two separate children on the reflection tree:
        // one named 'x', and another that is optional and is named 'x.storage'. Note
        // that '.' is illegal in either a Swift or Objective-C property name.
        if let storageRange = name.range(of: ".storage", options: [.anchored, .backwards]) {
            return String(name[..<storageRange.lowerBound])
        }
        // Xcode 11 changed the name of the storage property to "$__lazy_storage_$_propName"
        if let storageRange = name.range(of: "$__lazy_storage_$_", options: [.anchored]) {
            return String(name[storageRange.upperBound...])
        }
        return nil
    }

    // Reflect an object, returning only children representing managed Realm properties.
    private static func getNonIgnoredMirrorChildren(for object: Any) -> [Mirror.Child] {
        let ignoredPropNames: Set<String>
        if let realmObject = object as? Object {
            ignoredPropNames = Set(type(of: realmObject).ignoredProperties())
        } else {
            ignoredPropNames = Set()
        }
        return Mirror(reflecting: object).children.filter { (prop: Mirror.Child) -> Bool in
            guard let label = prop.label else {
                return false
            }
            if ignoredPropNames.contains(label) {
                return false
            }
            if let lazyBaseName = baseName(forLazySwiftProperty: label) {
                if ignoredPropNames.contains(lazyBaseName) {
                    return false
                }
                // Managed lazy property; not currently supported.
                // FIXME: revisit this once Swift gets property behaviors/property macros.
                throwRealmException("Lazy managed property '\(lazyBaseName)' is not allowed on a Realm Swift object"
                    + " class. Either add the property to the ignored properties list or make it non-lazy.")
            }
            return true
        }
    }

    internal class func getSwiftProperties(_ object: RLMObjectBase) -> [RLMProperty] {
        _ = ObjectUtil.runOnce

        let cls = type(of: object)

        var indexedProperties: Set<String>!
        let columnNames = cls._realmColumnNames()
        if let realmObject = object as? Object {
            indexedProperties = Set(type(of: realmObject).indexedProperties())
        } else {
            indexedProperties = Set()
        }

        return getNonIgnoredMirrorChildren(for: object).compactMap { prop in
            guard let label = prop.label else { return nil }
            var rawValue = prop.value
            if let value = rawValue as? RealmEnum {
                rawValue = type(of: value)._rlmToRawValue(value)
            }

            guard let value = rawValue as? _ManagedPropertyType else {
                if class_getProperty(cls, label) != nil {
                    throwRealmException("Property \(cls).\(label) is declared as \(type(of: prop.value)), which is not a supported managed Object property type. If it is not supposed to be a managed property, either add it to `ignoredProperties()` or do not declare it as `@objc dynamic`. See https://realm.io/docs/swift/latest/api/Classes/Object.html for more information.")
                }
                if prop.value as? RealmOptionalProtocol != nil {
                    throwRealmException("Property \(cls).\(label) has unsupported RealmOptional type \(type(of: prop.value)). Extending RealmOptionalType with custom types is not currently supported. ")
                }
                return nil
            }

            RLMValidateSwiftPropertyName(label)
            let valueType = type(of: value)

            let property = RLMProperty()
            property.name = label
            property.indexed = indexedProperties.contains(label)
            property.columnName = columnNames?[label]
            valueType._rlmProperty(property)
            value._rlmProperty(property)

            if let objcProp = class_getProperty(cls, label) {
                var count: UInt32 = 0
                let attrs = property_copyAttributeList(objcProp, &count)!
                defer {
                    free(attrs)
                }
                var computed = true
                for i in 0..<Int(count) {
                    let attr = attrs[i]
                    switch attr.name[0] {
                    case Int8(UInt8(ascii: "R")): // Read only
                        return nil
                    case Int8(UInt8(ascii: "V")): // Ivar name
                        computed = false
                    case Int8(UInt8(ascii: "G")): // Getter name
                        property.getterName = String(cString: attr.value)
                    case Int8(UInt8(ascii: "S")): // Setter name
                        property.setterName = String(cString: attr.value)
                    default:
                        break
                    }
                }

                // If there's no ivar name and no ivar with the same name as
                // the property then this is a computed property and we should
                // implicitly ignore it
                if computed && class_getInstanceVariable(cls, label) == nil {
                    return nil
                }
            } else if valueType._rlmRequireObjc() {
                // Implicitly ignore non-@objc dynamic properties
                return nil
            } else {
                property.swiftIvar = class_getInstanceVariable(cls, label)
            }

            property.updateAccessors()
            return property
        }
    }
}

// MARK: AssistedObjectiveCBridgeable

// FIXME: Remove when `as! Self` can be written
private func forceCastToInferred<T, V>(_ x: T) -> V {
    return x as! V
}

extension Object: AssistedObjectiveCBridgeable {
    internal static func bridging(from objectiveCValue: Any, with metadata: Any?) -> Self {
        return forceCastToInferred(objectiveCValue)
    }

    internal var bridged: (objectiveCValue: Any, metadata: Any?) {
        return (objectiveCValue: unsafeCastToRLMObject(), metadata: nil)
    }
}
