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
#if canImport(Combine)
import Combine
#endif

private protocol AnyProjected {
    var projectedKeyPath: AnyKeyPath { get }
}

// MARK: Projection

/// ``@Projected`` is used to declare properties on ``Projection`` protocols which should be
/// managed by Realm.
///
/// Example of usage:
/// ```swift
/// public class Person: Object {
///     @Persisted var firstName = ""
///     @Persisted var lastName = ""
///     @Persisted var address: Address? = nil
///     @Persisted var friends = List<Person>()
///     @Persisted var reviews = List<String>()
/// }
///
/// class PersonProjection: Projection<Person> {
///     @Projected(\Person.firstName) var firstName
///     @Projected(\Person.lastName.localizedUppercase) var lastNameCaps
///     @Projected(\Person.address.city) var homeCity
///     @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: ProjectedCollection<String>
/// }
///
/// let people: Results<PersonProjection> = realm.objects(PersonProjection.self)
/// ```
@propertyWrapper
public struct Projected<T: ObjectBase, Value>: AnyProjected {
    fileprivate var _projectedKeyPath: KeyPath<T, Value>
    var projectedKeyPath: AnyKeyPath {
        _projectedKeyPath
    }

    /// :nodoc:
    @available(*, unavailable, message: "@Persisted can only be used as a property on a Realm object")
    public var wrappedValue: Value {
        // The static subscript below is called instead of this when the property
        // wrapper is used on an ObjectBase subclass, which is the only thing we support.
        get { fatalError("called wrappedValue getter") }
        // swiftlint:disable:next unused_setter_value
        set { fatalError("called wrappedValue setter") }
    }

    /// :nodoc:
    public static subscript<EnclosingSelf: Projection<T>>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
        ) -> Value {
        get {
            let storage = observed[keyPath: storageKeyPath]
            return observed.rootObject[keyPath: storage._projectedKeyPath]
        }
        set {
            guard let keyPath = observed[keyPath: storageKeyPath].projectedKeyPath as? WritableKeyPath<T, Value> else {
                preconditionFailure("KeyPath is not writable")
            }
            var obj = observed.rootObject
            obj[keyPath: keyPath] = newValue
        }
    }

    /// Declares a property which is lazily initialized to the type's default value.
    public init(_ projectedKeyPath: KeyPath<T, Value>) {
        self._projectedKeyPath = projectedKeyPath
    }
}

// MARK: Projection Schema
private struct ProjectedMetadata {
    let projectedKeyPath: AnyKeyPath
    let originPropertyKeyPathString: String
    let label: String
}

private var schema = [ObjectIdentifier: [ProjectedMetadata]]()
private let projectionSchemaLock = NSLock()

// MARK: ProjectionOservable
/**
  A type erased Projection.
 
 ProjectionObservable is a Combine publisher
 */
public protocol ProjectionObservable: AnyObject {
    /// The Projection's underlying type - a child of Realm `Object` or `EmbeddedObject`.
    associatedtype Root: ObjectBase
    /// The object being projected
    var rootObject: Root { get }
    /// :nodoc:
    init(projecting object: Root)
}

extension ObjectChange {
    fileprivate static func processChange(_ objectChange: ObjectChange<T.Root>,
                                          _ projection: T) -> ObjectChange<T> where T: ProjectionObservable {
        let schema = projection._schema
        switch objectChange {
        case .error(let error):
            return .error(error)
        case .change(let object, let objectPropertyChanges):
            let newProjection = T(projecting: object)
            let projectedPropertyChanges: [PropertyChange] = objectPropertyChanges.map { propChange in
                // read the metadata for the property whose origin name matches
                // the changed property's name
                projectionSchemaLock.lock()
                let propertyMetadata = schema.first(where: {
                    $0.originPropertyKeyPathString == propChange.name
                })!
                projectionSchemaLock.unlock()
                var changeOldValue: Any?
                if let oldValue = propChange.oldValue {
                    // if there is an oldValue in the change, construct an empty Root
                    let newRoot = T.Root()
                    let processorProjection = T(projecting: newRoot)

                    // assign the oldValue to the empty root object
                    processorProjection.rootObject.setValue(oldValue, forKey: propChange.name)
                    changeOldValue = processorProjection.rootObject[keyPath: propertyMetadata.projectedKeyPath]
                }
                var changeNewValue: Any?
                if propChange.newValue != nil {
                    changeNewValue = newProjection.rootObject[keyPath: propertyMetadata.projectedKeyPath]
                }

                let valueName = String(propertyMetadata.label.dropFirst()) // this drops the _ from the property wrapper name
                return PropertyChange(name: valueName,
                                      oldValue: changeOldValue,
                                      newValue: changeNewValue)
            }
            return .change(newProjection, projectedPropertyChanges)
        case .deleted:
            return .deleted
        }
    }
}

/// ``Projection`` is a light weight model of the original Realm ``Object`` or ``EmbeddedObject``.
/// You can use `Projection` as a view model to minimize boilerplate.
///
/// Example of usage:
/// ```swift
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
/// class PersonProjection: Projection<Person> {
///     @Projected(\Person.firstName) var firstName
///     @Projected(\Person.lastName.localizedUppercase) var lastNameCaps
///     @Projected(\Person.address.city) var homeCity
///     @Projected(\Person.friends.projectTo.firstName) var friendsFirstName: ProjectedCollection<String>
/// }
/// ```
///  ### Supported property types
/// Projection can transform the original `@Persisted` properties in several ways:
/// - `Passthrough` - `Projection`'s property will have same name and type as original object. See `PersonProjection.firstName`.
/// - `Rename` - Projection's property will have same type as original object just with the new name.
/// - `Keypath resolution` - you can access the certain properties of the projected `Object`. See `PersonProjection.lastNameCaps` and `PersonProjection.homeCity`.
/// - `Collection mapping` - `List` and `MutableSet`of `Object`s or `EmbeddedObject`s  can be projected as a collection of primitive values.
///     See `PersonProjection.friendsFirstName`.
/// - `Exclusion` - all properties of the original Realm object that were not defined in the projection model will be excluded from projection.
///     Any changes happened on those properties will not trigger a change notification for the `Projection`.
///     You still can access the original `Object` or `EmbeddedObject` and observe notifications directly on it.
/// - note: each `@Persisted` property can be `@Projected` in different ways in the same Projection class.
/// Each `Object` or `EmbeddedObject` can have sevaral projections of same or different classes at once.
///
/// ### Querying
/// You can retrieve all Projections of a given type from a Realm by calling the `objects(_:)` of Realm or `init(projecting:)`
/// of Projection's class:
/// ```swift
/// let projections = realm.object(PersonProjection.self)
/// let personObject = realm.create(Person.self)
/// let singleProjection = PersonProjection(projecting: personObject)
/// ```
open class Projection<Root: ObjectBase & RealmCollectionValue>: RealmCollectionValue, ProjectionObservable {
    /// :nodoc:
    public typealias PersistedType = Root

    /// The object being projected
    public let rootObject: Root

    /**
     Create a new projection.
     - parameter object: The object to project.
     */
    public required init(projecting object: Root) {
        self.rootObject = object
        // Initialize schema for projection class
        _ = _schema
    }
    /// :nodoc:
    public static func == (lhs: Projection, rhs: Projection) -> Bool {
        RLMObjectBaseAreEqual(lhs.rootObject, rhs.rootObject)
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        let hashVal = rootObject.hashValue
        hasher.combine(hashVal)
    }
    /// :nodoc:
    open var description: String {
        return """
\(type(of: self))<\(type(of: rootObject))> <\(Unmanaged.passUnretained(rootObject).toOpaque())> {
\t\(_schema.map {
    "\t\(String($0.label.dropFirst()))(\\.\($0.originPropertyKeyPathString)) = \(rootObject[keyPath: $0.projectedKeyPath]!);"
}.joined(separator: "\n"))
}
"""
    }

    /// :nodoc:
    public static func _rlmDefaultValue() -> Self {
        fatalError()
    }

}

extension ProjectionObservable {
    /**
     Registers a block to be called each time the projection's underlying object changes.

     The block will be asynchronously called after each write transaction which
     deletes the underlying object or modifies any of the projected properties of the object,
     including self-assignments that set a property to its existing value.

     For write transactions performed on different threads or in different
     processes, the block will be called when the managing Realm is
     (auto)refreshed to a version including the changes, while for local write
     transactions it will be called at some point in the future after the write
     transaction is committed.

     If no key paths are given, the block will be executed on any insertion,
     modification, or deletion for all projected  properties, including projected properties of
     any nested, linked objects. If a key path or key paths are provided,
     then the block will be called for changes which occur only on the
     provided key paths. For example, if:
     
     ```swift
     class Person: Object {
         @Persisted var firstName: String
         @Persisted var lastName = ""
         @Persisted public var friends = List<Person>()
     }

     class PersonProjection: Projection<Person> {
         @Projected(\Person.firstName) var name
         @Projected(\Person.lastName.localizedUppercase) var lastNameCaps
         @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: ProjectedCollection<String>
     }

     let token = projectedPerson.observe(keyPaths: ["name"], { changes in
        // ...
     })
     ```
     - The above notification block fires for changes to the
     `Person.firstName` property of the the projection's underlying `Person` Object,
     but not for any changes made to `Person.lastName` or `Person.friends` list.
     - The notification block fires for changes of `PersonProjection.name` property, but not  for
     another projection's property change.
     - If the observed key path were `["firstFriendsName"]`, then any insertion,
     deletion, or modification of the `firstName` of the `friends` list will trigger the block. A change to
     `someFriend.lastName` would not trigger the block (where `someFriend`
     is an element contained in `friends`)

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

     You must retain the returned token for as long as you want updates to be sent
     to the block. To stop receiving updates, call `invalidate()` on the token.

     It is safe to capture a strong reference to the observed object within the
     callback block. There is no retain cycle due to that the callback is
     retained by the returned token and not by the object itself.

     - warning: This method cannot be called during a write transaction, or when
                the containing Realm is read-only.
     - parameter keyPaths: Only properties contained in the key paths array will trigger
                           the block when they are modified. If `nil`, notifications
                           will be delivered for any projected property change on the object.
                           String key paths which do not correspond to a valid projected property
                           will throw an exception.
     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to call with information about changes to the object.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe(keyPaths: [String] = [],
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (ObjectChange<Self>) -> Void) -> NotificationToken {
        let kps: [String]
        if keyPaths.isEmpty {
            kps = _schema.map(\.originPropertyKeyPathString)
        } else {
            kps = _schema.filter { keyPaths.contains($0.originPropertyKeyPathString) }.map(\.originPropertyKeyPathString)
        }
        return rootObject._observe(keyPaths: kps, on: queue, { change in
            block(ObjectChange<Self>.processChange(change, self))
        })
    }

    /**
     Registers a block to be called each time the projection's underlying object changes.

     The block will be asynchronously called after each write transaction which
     deletes the underlying object or modifies any of the projected properties of the object,
     including self-assignments that set a property to its existing value.

     For write transactions performed on different threads or in different
     processes, the block will be called when the managing Realm is
     (auto)refreshed to a version including the changes, while for local write
     transactions it will be called at some point in the future after the write
     transaction is committed.

     If no key paths are given, the block will be executed on any insertion,
     modification, or deletion for all projected  properties, including projected properties of
     any nested, linked objects. If a key path or key paths are provided,
     then the block will be called for changes which occur only on the
     provided key paths. For example, if:
     
     ```swift
     class Person: Object {
         @Persisted var firstName: String
         @Persisted var lastName = ""
         @Persisted public var friends = List<Person>()
     }

     class PersonProjection: Projection<Person> {
         @Projected(\Person.firstName) var name
         @Projected(\Person.lastName.localizedUppercase) var lastNameCaps
         @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: ProjectedCollection<String>
     }

     let token = projectedPerson.observe(keyPaths: [\PersonProjection.name], { changes in
        // ...
     })
     ```
     - The above notification block fires for changes to the
     `firstName` property of the Object, but not for any changes
     made to `lastName` or `friends` list.
     - If the observed key path were `[\PersonProjection.firstFriendsName]`, then any insertion,
     deletion, or modification of the `firstName` of the `friends` list will trigger the block. A change to
     `someFriend.lastName` would not trigger the block (where `someFriend`
     is an element contained in `friends`)

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

     You must retain the returned token for as long as you want updates to be sent
     to the block. To stop receiving updates, call `invalidate()` on the token.

     It is safe to capture a strong reference to the observed object within the
     callback block. There is no retain cycle due to that the callback is
     retained by the returned token and not by the object itself.

     - warning: This method cannot be called during a write transaction, or when
                the containing Realm is read-only.
     - parameter keyPaths: Only properties contained in the key paths array will trigger
                           the block when they are modified. If `nil`, notifications
                           will be delivered for any projected property change on the object.
                           String key paths which do not correspond to a valid projected property
                           will throw an exception.
     - parameter queue: The serial dispatch queue to receive notification on. If
                        `nil`, notifications are delivered to the current thread.
     - parameter block: The block to call with information about changes to the object.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func observe(keyPaths: [PartialKeyPath<Self>] = [],
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (ObjectChange<Self>) -> Void) -> NotificationToken {
        var kps: [String]
        if keyPaths.isEmpty {
            kps = _schema.map(\.originPropertyKeyPathString)
        } else {
            kps = []
            let root = Root.keyPathRecorder(with: [])
            let projection = Self(projecting: root) // tracer time
            for keyPath in keyPaths {
                root.lastAccessedNames = NSMutableArray()
                _ = projection[keyPath: keyPath]
                kps.append(root.lastAccessedNames!.componentsJoined(by: "."))
            }
        }
        return rootObject._observe(keyPaths: kps, on: queue, { change in
            block(ObjectChange<Self>.processChange(change, self))
        })
    }

    fileprivate var _schema: [ProjectedMetadata] {
        projectionSchemaLock.lock()
        defer {
            projectionSchemaLock.unlock()
        }
        let identifier = ObjectIdentifier(type(of: self))
        if let schema = schema[identifier] {
            return schema
        }

        let mirror = Mirror(reflecting: self)
        let metadatas: [ProjectedMetadata] = mirror.children.compactMap { child in
            guard let projected = child.value as? AnyProjected else {
                return nil
            }
            let originPropertyLabel = _name(for: projected.projectedKeyPath as! PartialKeyPath<Root>)
            guard !originPropertyLabel.isEmpty else {
                projectionSchemaLock.unlock()
                throwRealmException("@Projected property '\(child.label!)' must be a part of Realm object")
            }
            return ProjectedMetadata(projectedKeyPath: projected.projectedKeyPath,
                                     originPropertyKeyPathString: originPropertyLabel,
                                     label: child.label!)
        }
        schema[identifier] = metadatas
        return metadatas
    }
}
/**
 Information about a specific property which changed in an `Object` change notification.
 */
@frozen public struct ProjectedPropertyChange {
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

// MARK: Notifications
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
public extension Projection {
    /// :nodoc:
    func addObserver(_ observer: NSObject,
                     forKeyPath keyPath: String,
                     options: NSKeyValueObservingOptions = [],
                     context: UnsafeMutableRawPointer?) {
        rootObject.addObserver(observer, forKeyPath: keyPath, options: options, context: context)
    }

    /// :nodoc:
    func removeObserver(_ observer: NSObject,
                        forKeyPath keyPath: String,
                        context: UnsafeMutableRawPointer?) {
        rootObject.removeObserver(observer, forKeyPath: keyPath, context: context)
    }

    /// :nodoc:
    func removeObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        rootObject.removeObserver(observer, forKeyPath: keyPath)
    }
}

// MARK: ThreadConfined
extension Projection: ThreadConfined where Root: ThreadConfined {
    /**
     The Realm which manages the object, or `nil` if the object is unmanaged.
     Note: Projection can be instantiated for the managed objects only therefore realm will never be nil.
     Unmanaged objects are not confined to a thread and cannot be passed to methods expecting a
     `ThreadConfined` object.
     */
    public var realm: Realm? {
        rootObject.realm
    }

    /// Indicates if the object can no longer be accessed because it is now invalid.
    public var isInvalidated: Bool {
        return rootObject.isInvalidated
    }
    /**
     Indicates if the object is frozen.
     Frozen objects are not confined to their source thread. Forming a `ThreadSafeReference` to a
     frozen object is allowed, but is unlikely to be useful.
     */
    public var isFrozen: Bool {
        return realm?.isFrozen ?? false
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
    public func freeze() -> Self {
        let frozenObject = rootObject.freeze()
        return Self(projecting: frozenObject)
    }
    /**
     Returns a live (mutable) reference of this object.
     Will return self if called on an already live object.
     */
    public func thaw() -> Self? {
        if let thawedObject = rootObject.thaw() {
            return Self(projecting: thawedObject)
        }
        return nil
    }
}

#if canImport(Combine)
// MARK: - RealmSubscribable
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension ProjectionObservable {
    /// :nodoc:
    public func _observe<S>(_ keyPaths: [String]?, on queue: DispatchQueue?, _ subscriber: S) -> NotificationToken where S: Subscriber, S.Input == Self {
        return observe(keyPaths: keyPaths ?? [], on: queue) { (change: ObjectChange<S.Input>) in
            switch change {
            case .change(let projection, _):
                _ = subscriber.receive(projection)
            case .deleted:
                subscriber.receive(completion: .finished)
            case .error(let error):
                fatalError("Unexpected error \(error)")
            }
        }
    }

    /// :nodoc:
    public func _observe<S>(_ keyPaths: [String]?, _ subscriber: S) -> NotificationToken where S: Subscriber, S.Input == Void {
        return observe(keyPaths: [PartialKeyPath<Self>](), { _ in _ = subscriber.receive() })
    }
}
#if !(os(iOS) && (arch(i386) || arch(arm)))
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension Projection: ObservableObject, RealmSubscribable where Root: ThreadConfined {
    /// A publisher that emits Void each time the projection changes.
    ///
    /// Despite the name, this actually emits *after* the projection has changed.
    public var objectWillChange: RealmPublishers.WillChange<Projection> {
        RealmPublishers.WillChange(self)
    }
}
#endif // !(os(iOS) && (arch(i386) || arch(arm)))

#endif // canImport(Combine)
