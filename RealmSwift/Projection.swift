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

/// @Projected is used to declare properties on Projection protocols which should be
/// managed by Realm.
///
/// Example of usage:
/// ```
/// public class Person: Object {
///     @Persisted var firstName = ""
///     @Persisted var lastName = ""
///     @Persisted var address: Address? = nil
///     @Persisted var friends = List<Person>()
///     @Persisted var reviews = List<String>()
/// }
///
/// public class Address: EmbeddedObject {
///     @Persisted var city: String = ""
///     @Persisted var country = ""
/// }
///
/// struct PersonProjection: Projection {
///     @Projected(\Person.firstName) var firstName
///     @Projected(\Person.address.city) var homeCity
/// }
/// ```
@propertyWrapper
public struct Projected<T: ObjectBase, Value>: _Projected {
    fileprivate var projectedKeyPath: KeyPath<T, Value>!
    fileprivate var objectBase: ObjectBase! {
        storage.objectBase
    }
    private class Storage {
        var objectBase: ObjectBase?
        init() {}
    }
    private let storage = Storage()
    private var get: ((T) -> Value)!
    private var set: ((T, Value) -> ())!
    func set(object: ObjectBase) {
        storage.objectBase = object
    }
    /// :nodoc:
    public var wrappedValue: Value {
        get {
            get(objectBase! as! T)
        }
        set {
            precondition(projectedKeyPath is WritableKeyPath<T, Value>)
            set(objectBase! as! T, newValue)
        }
    }
    /// Declares a property which is lazily initialized to the type's default value.
    public init(_ projectedKeyPath: KeyPath<T, Value>) {
        self.projectedKeyPath = projectedKeyPath
        self.get = {
            return $0[keyPath: projectedKeyPath]
        }
        self.set = {
            var ref = $0
            ref[keyPath: projectedKeyPath as! WritableKeyPath<T, Value>] = $1
        }
    }
}

public protocol Projection: ThreadConfined {
    associatedtype Root: ObjectBase
    func observe(keyPaths: [PartialKeyPath<Self>], _ block: (ProjectionChange) -> Void) -> NotificationToken
}

public extension Projection {

    fileprivate subscript(label: String) -> _Projected {
        Mirror(reflecting: self).descendant(label)! as! _Projected
    }
    
    mutating func assign(_ object: Root) {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.value is _Projected {
                let keyPath =  \Self.[child.label!]
                self[keyPath: keyPath].set(object: object)
            }
        }
    }
}

fileprivate protocol _Projected {
#warning("TODO: Remove force unwrap")
    var objectBase: ObjectBase! { get }
    func set(object: ObjectBase)
}

public enum ProjectionChange {
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
    case change(_: ObjectBase, _: [PropertyChange])
    /// The object has been deleted from the Realm.
    case deleted
}

public extension Projection {
    func observe(keyPaths: [PartialKeyPath<Self>] = [], _ block: (ProjectionChange) -> Void) -> NotificationToken {
        if keyPaths.isEmpty {
//            projectionSchemas[ObjectIdentifier(type(of: self))]!.forEach { property in
//                (self[keyPath: property.keyPathOnProjection] as! _ProjectedBase).objectBase.observe(property.realmKeyPathString) { change in
//
//                }
//            }
        } else {
        }
        fatalError()
    }
    // Must also conform to `AssistedObjectiveCBridgeable`
    /**
     The Realm which manages the object, or `nil` if the object is unmanaged.
     Unmanaged objects are not confined to a thread and cannot be passed to methods expecting a
     `ThreadConfined` object.
     */
    var realm: Realm? {
        return nil
//        (self[keyPath: projectionSchemas[ObjectIdentifier(type(of: self))]!.first!.keyPathOnProjection] as! _ProjectedBase)
//            .objectBase.realm
    }
    /// Indicates if the object can no longer be accessed because it is now invalid.
    var isInvalidated: Bool {
        return false
    }
    /**
     Indicates if the object is frozen.
     Frozen objects are not confined to their source thread. Forming a `ThreadSafeReference` to a
     frozen object is allowed, but is unlikely to be useful.
     */
    var isFrozen: Bool {
        return false
    }
    /**
     Returns a frozen snapshot of this object.
     Unlike normal Realm live objects, the frozen copy can be read from any thread, and the values
     read will never update to reflect new writes to the Realm. Frozen collections can be queried
     like any other Realm collection. Frozen objects cannot be mutated, and cannot be observed for
     change notifications.
     Unmanaged Realm objects cannot be frozen.
     - warning: Holding onto a frozen object for an extended period while performing write
     transaction on the Realm may result in the Realm file growing to large sizes. See
     `Realm.Configuration.maximumNumberOfActiveVersions` for more information.
     */
    func freeze() -> Self {
        return self
    }
    /**
     Returns a live (mutable) reference of this object.
     Will return self if called on an already live object.
     */
    func thaw() -> Self? {
        return self
    }
}

private struct ProjectionProperty {
    let keyPathOnProjection: AnyKeyPath
    let realmKeyPathString: String
}

private let projectionSchemas: [ObjectIdentifier: [ProjectionProperty]] = [:]

extension Results {
    public func `as`<P: Projection>(_ projectionType: P.Type) -> Results<P> where P.Root == Element {
        /// add logic to Results to attach results objects to projection when
        /// queried:
        /// ```
        /// if Element.self is Projection.Type {
        ///    let projection = Element()
        ///    attachObjectBase(element, to: projection)
        ///    return projection
        /// }
        ///
        /// return element
        /// ```
        fatalError()
    }
}

@dynamicMemberLookup
public struct ElementMapper<Element> where Element: RealmCollectionValue {
    let list: List<Element>
    
    public subscript<V>(dynamicMember member: KeyPath<Element, V>) -> List<V> {
        let out = List<V>()
        list.forEach {
            out.append($0[keyPath: member])
        }
        return out
    }
}

extension List {
    public var projectTo: ElementMapper<Element> {
        get {
            return ElementMapper<Element>(list: self)
        }
    }
}
