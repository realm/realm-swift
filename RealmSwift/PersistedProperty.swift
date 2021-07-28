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

/// @Persisted is used to declare properties on Object subclasses which should be
/// managed by Realm.
///
/// Example of usage:
/// ```
/// class MyModel: Object {
///     // A basic property declaration. A property with no
///     // default value supplied will default to `nil` for
///     // Optional types, zero for numeric types, false for Bool,
///     // an empty string/data, and a new random value for UUID
///     // and ObjectID.
///     @Persisted var basicIntProperty: Int
///
///     // Custom default values can be specified with the
///     // standard Swift syntax
///     @Persisted var intWithCustomDefault: Int = 5
///
///     // Properties can be indexed by passing `indexed: true`
///     // to the initializer.
///     @Persisted(indexed: true) var indexedString: String
///
///     // Properties can set as the class's primary key by
///     // passing `primaryKey: true` to the initializer
///     @Persisted(primaryKey: true) var _id: ObjectId
///
///     // List and set properties should always be declared
///     // with `: List` rather than `= List()`
///     @Persisted var listProperty: List<Int>
///     @Persisted var setProperty: MutableSet<MyObject>
///
///     // LinkingObjects properties require setting the source
///     // object link property name in the initializer
///     @Persisted(originProperty: "outgoingLink")
///     var incomingLinks: LinkingObjects<OtherModel>
///
///     // Properties which are not marked with @Persisted will
///     // be ignored entirely by Realm.
///     var ignoredProperty = true
/// }
/// ```
///
///  Int, Bool, String, ObjectId and Date properties can be indexed by passing
///  `indexed: true` to the initializer. Indexing a property improves the
///  performance of equality queries on that property, at the cost of slightly
///  worse write performance. No other operations currently use the index.
///
///  A property can be set as the class's primary key by passing `primaryKey: true`
///  to the initializer. Compound primary keys are not supported, and setting
///  more than one property as the primary key will throw an exception at
///  runtime. Only Int, String, UUID and ObjectID properties can be made the
///  primary key, and when using MongoDB Realm, the primary key must be named
///  `_id`. The primary key property can only be mutated on unmanaged objects,
///  and mutating it on an object which has been added to a Realm will throw an
///  exception.
///
///  Properties can optionally be given a default value using the standard Swift
///  syntax. If no default value is given, a value will be generated on first
///  access: `nil` for all Optional types, zero for numeric types, false for
///  Bool, an empty string/data, and a new random value for UUID and ObjectID.
///  List and MutableSet properties *should not* be defined by setting them to a
///  default value of an empty List/MutableSet. Doing so will work, but will
///  result in worse performance when accessing objects managed by a Realm.
///  Similarly, ObjectID properties *should not* be initialized to
///  `ObjectID.generate()`, as doing so will result in extra ObjectIDs being
///  generated and then discarded when reading from a Realm.
///
///  If a class has at least one @Persisted property, all other properties will be
///  ignored by Realm. This means that they will not be persisted and will not
///  be usable in queries and other operations such as sorting and aggregates
///  which require a managed property.
///
///  @Persisted cannot be used anywhere other than as a property on an Object or
///  EmbeddedObject subclass and trying to use it in other places will result in
///  runtime errors.
@propertyWrapper
public struct Persisted<Value: _Persistable> {
    private var storage: PropertyStorage<Value>

    /// :nodoc:
    @available(*, unavailable, message: "@Persisted can only be used as a property on a Realm object")
    public var wrappedValue: Value {
        // The static subscript below is called instead of this when the property
        // wrapper is used on an ObjectBase subclass, which is the only thing we support.
        get { fatalError("called wrappedValue getter") }
        // swiftlint:disable:next unused_setter_value
        set { fatalError("called wrappedValue setter") }
    }

    /// Declares a property which is lazily initialized to the type's default value.
    public init() {
        storage = .unmanagedNoDefault(indexed: false, primary: false)
    }
    /// Declares a property which defaults to the given value.
    public init(wrappedValue value: Value) {
        storage = .unmanaged(value: value, indexed: false, primary: false)
    }

    /// :nodoc:
    public static subscript<EnclosingSelf: ObjectBase>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
        ) -> Value {
        get {
            return observed[keyPath: storageKeyPath].get(observed)
        }
        set {
            observed[keyPath: storageKeyPath].set(observed, value: newValue)
        }
    }

    // Called via RLMInitializeSwiftAccessor() to initialize the wrapper on a
    // newly created managed accessor object.
    internal mutating func initialize(_ object: ObjectBase, key: PropertyKey) {
        storage = .managed(key: key)
    }

    // Collection types use this instead of the above because when promoting a
    // unmanaged object to a managed object we want to reuse the existing collection
    // object if it exists. Currently it always will exist because we read the
    // value of the property first, but there's a potential optimization to
    // skip initializing it on that read.
    internal mutating func initializeCollection(_ object: ObjectBase, key: PropertyKey) -> Value? {
        if case let .unmanaged(value, _, _) = storage {
            storage = .managedCached(value: value, key: key)
            return value
        }
        if case let .unmanagedObserved(value, _) = storage {
            storage = .managedCached(value: value, key: key)
            return value
        }
        storage = .managed(key: key)
        return nil
    }

    internal mutating func get(_ object: ObjectBase) -> Value {
        switch storage {
        case let .unmanaged(value, _, _):
            return value
        case .unmanagedNoDefault:
            let value = Value._rlmDefaultValue(false)
            storage = .unmanaged(value: value)
            return value
        case let .unmanagedObserved(value, key):
            if let lastAccessedNames = object.lastAccessedNames {
                var name: String = ""
                if Value._rlmType == .linkingObjects {
                    name = RLMObjectBaseObjectSchema(object)!.computedProperties[Int(key)].name
                } else {
                    name = RLMObjectBaseObjectSchema(object)!.properties[Int(key)].name
                }
                lastAccessedNames.add(name)
                return Value._rlmKeyPathRecorder(with: lastAccessedNames)
            }
            return value
        case let .managed(key):
            let v = Value._rlmGetProperty(object, key)
            if Value._rlmRequiresCaching {
                // Collection types are initialized once and stored on the
                // object rather than on every access. Non-collection types
                // cannot be cached without some mechanism for knowing when to
                // reread them which we don't currently have.
                storage = .managedCached(value: v, key: key)
            }
            return v
        case let .managedCached(value, _):
            return value
        }
    }

    internal mutating func set(_ object: ObjectBase, value: Value) {
        if value is MutableRealmCollection {
            (get(object) as! MutableRealmCollection).assign(value)
            return
        }
        switch storage {
        case let .unmanagedObserved(_, key):
            let name = RLMObjectBaseObjectSchema(object)!.properties[Int(key)].name
            object.willChangeValue(forKey: name)
            storage = .unmanagedObserved(value: value, key: key)
            object.didChangeValue(forKey: name)
        case .managed(let key), .managedCached(_, let key):
            Value._rlmSetProperty(object, key, value)
        case .unmanaged, .unmanagedNoDefault:
            storage = .unmanaged(value: value, indexed: false, primary: false)
        }
    }

    // Initialize an unmanaged property for observation
    internal mutating func observe(_ object: ObjectBase, property: RLMProperty) {
        let value: Value
        switch storage {
        case let .unmanaged(v, _, _):
            value = v
        case .unmanagedNoDefault:
            value = Value._rlmDefaultValue(false)
        case .unmanagedObserved, .managed, .managedCached:
            return
        }
        // Mutating a collection triggers a KVO notification on the parent, so
        // we need to ensure that the collection has a pointer to its parent.
        if let value = value as? MutableRealmCollection {
            value.setParent(object, property)
        }
        storage = .unmanagedObserved(value: value, key: PropertyKey(property.index))
    }
}

extension Persisted: Decodable where Value: Decodable {
    public init(from decoder: Decoder) throws {
        storage = .unmanaged(value: try decoder.decodeOptional(Value.self), indexed: false, primary: false)
    }
}

extension Persisted: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        switch storage {
        case .unmanaged(let value, _, _):
            try value.encode(to: encoder)
        case .unmanagedObserved(let value, _):
            try value.encode(to: encoder)
        case .unmanagedNoDefault:
            try Value._rlmDefaultValue(false).encode(to: encoder)
        default:
            // We need a reference to the parent object to be able to read from
            // a managed property. There's probably a way to do this with some
            // sort of custom adapter that keeps track of the current parent
            // at each level of recursion, but it's not trivial.
            throw EncodingError.invalidValue(self, .init(codingPath: encoder.codingPath, debugDescription: "Only unmanaged Realm objects can be encoded using automatic Codable synthesis. You must explicitly define encode(to:) on your model class to support managed Realm objects."))
        }
    }
}

/// :nodoc:
/// Protocol for a PropertyWrapper to properly handle Coding when the wrappedValue is Optional
public protocol OptionalCodingWrapper {
    associatedtype WrappedType: ExpressibleByNilLiteral
    init(wrappedValue: WrappedType)
}

/// :nodoc:
extension KeyedDecodingContainer {
    // This is used to override the default decoding behaviour for OptionalCodingWrapper to allow a value to avoid a missing key Error
    public func decode<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T where T: Decodable, T: OptionalCodingWrapper {
        return try decodeIfPresent(T.self, forKey: key) ?? T(wrappedValue: nil)
    }
}

extension Persisted: OptionalCodingWrapper where Value: ExpressibleByNilLiteral {
}

/**
 An enum type which can be used with @Persisted.

 Persisting an enum in Realm requires that it have a raw value and that the raw value by a type which Realm can store.
 The enum also has to be explicitly marked as conforming to this protocol as Swift does not let us do so implicitly.

 ```
 enum IntEnum: Int, PersistableEnum {
    case first = 1
    case second = 2
    case third = 7
 }
 enum StringEnum: String, PersistableEnum {
    case first = "a"
    case second = "b"
    case third = "g"
 }
 ```

 If the Realm contains a value which is not a valid member of the enum (such as if it was written by a different sync client which disagrees on which values are valid), optional enum properties will return `nil`, and non-optional properties will abort the process.
 */
public protocol PersistableEnum: _OptionalPersistable, RawRepresentable, CaseIterable, RealmEnum { }

extension PersistableEnum {
    /// :nodoc:
    public init() { self = Self.allCases.first! }
}

/// A type which can be indexed.
///
/// This protocol is merely a tag and declaring additional types as conforming
/// to it will simply result in runtime errors rather than compile-time errors.
public protocol _Indexable {}

extension Persisted where Value: _Indexable {
    /// Declares an indexed property which is lazily initialized to the type's default value.
    public init(indexed: Bool) {
        storage = .unmanagedNoDefault(indexed: indexed)
    }
    /// Declares an indexed property which defaults to the given value.
    public init(wrappedValue value: Value, indexed: Bool) {
        storage = .unmanaged(value: value, indexed: indexed)
    }
}

/// A type which can be made the primary key of an object.
///
/// This protocol is merely a tag and declaring additional types as conforming
/// to it will simply result in runtime errors rather than compile-time errors.
public protocol _PrimaryKey {}

extension Persisted where Value: _PrimaryKey {
    /// Declares the primary key property which is lazily initialized to the type's default value.
    public init(primaryKey: Bool) {
        storage = .unmanagedNoDefault(primary: primaryKey)
    }
    /// Declares the primary key property which defaults to the given value.
    public init(wrappedValue value: Value, primaryKey: Bool) {
        storage = .unmanaged(value: value, primary: primaryKey)
    }
}

/// :nodoc:
// Constraining the LinkingObjects initializer to only LinkingObjects require
// doing so via a protocol which only that type conforms to.
public protocol LinkingObjectsProtocol {
    init(fromType: Element.Type, property: String)
    associatedtype Element
}
extension Persisted where Value: LinkingObjectsProtocol {
    /// Declares a LinkingObjects property with the given origin property name.
    ///
    /// - param originProperty: The name of the property on the linking object type which links to this object.
    public init(originProperty: String) {
        self.init(wrappedValue: Value(fromType: Value.Element.self, property: originProperty))
    }
}
extension LinkingObjects: LinkingObjectsProtocol {}

// MARK: - Implementation

/// :nodoc:
extension Persisted: DiscoverablePersistedProperty where Value: _Persistable {
    public static var _rlmType: PropertyType { Value._rlmType }
    public static var _rlmOptional: Bool { Value._rlmOptional }
    public static var _rlmRequireObjc: Bool { false }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        // The label reported by Mirror has an underscore prefix added to it
        // as it's the actual storage rather than the compiler-magic getter/setter
        prop.name = String(prop.name.dropFirst())
        Value._rlmPopulateProperty(prop)
        Value._rlmSetAccessor(prop)
    }
    public func _rlmPopulateProperty(_ prop: RLMProperty) {
        switch storage {
        case let .unmanaged(value, indexed, primary):
            value._rlmPopulateProperty(prop)
            prop.indexed = indexed || primary
            prop.isPrimary = primary
        case let .unmanagedNoDefault(indexed, primary):
            prop.indexed = indexed || primary
            prop.isPrimary = primary
        default:
            fatalError()
        }
    }
}

// The actual storage for modern properties on objects.
//
// A newly created @Persisted will be either .unmanaged or .unmanagedNoDefault
// depending on whether the user supplied a default value with `= value` when
// defining the property. .unmanagedNoDefault turns into .unmanaged the first
// time the property is read from, using a default value generated for the type.
// If an unmanaged object is observed, that specific property is switched to
// .unmanagedObserved so that the property can look up its name in the setter.
//
// When a new managed accessor is created, all properties are set to .managed.
// When an existing unmanaged object is added to a Realm, existing non-collection
// properties are set to .unmanaged, and collections are set to .managedCached,
// reusing the existing instance of the collection (which are themselves promoted
// to managed).
//
// The indexed and primary members of the unmanaged cases are used only for
// schema discovery and are not always preserved once the Persisted is actually
// used for anything.
private enum PropertyStorage<T> {
    // An unmanaged value. This is used as the initial state if the user did
    // supply a default value, or if an unmanaged property is read or written
    // (but not observed).
    case unmanaged(value: T, indexed: Bool = false, primary: Bool = false)

    // The property is unmanaged and does not yet have a value. This state is
    // used if the user does not supply a default value in their model definition
    // and will be converted to the zero/empty value for the type when this
    // property is first used.
    case unmanagedNoDefault(indexed: Bool = false, primary: Bool = false)

    // The property is unmanaged and the parent object has (or previously had)
    // KVO observers, so we performed the additional initialization to set the
    // property key on each property. We do not track indexed/primary in this
    // state because those are needed only for schema discovery. An unmanaged
    // property never transitions from this state back to .unmanaged.
    case unmanagedObserved(value: T, key: PropertyKey)

    // The property is managed and so only needs to store the key to get/set
    // the value on the parent object.
    case managed(key: PropertyKey)

    // The property is managed and is storing a value which will be returned each
    // time. This is used only for collection properties, which are themselves
    // live objects and so only need to be created once. Caching them is both a
    // performance optimization (creating them involves a few memory allocations)
    // and is required for KVO to work correctly.
    case managedCached(value: T, key: PropertyKey)
}
