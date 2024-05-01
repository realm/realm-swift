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
import Combine

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
///     @Persisted var address: Address?
///     @Persisted var friends: List<Person>
///     @Persisted var reviews: List<String>
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
// MARK: ProjectionObservable
/**
  A type erased Projection.
 
 ProjectionObservable is a Combine publisher
 */
public protocol ProjectionObservable: AnyObject, ThreadConfined {
    /// The Projection's underlying type - a child of Realm `Object` or `EmbeddedObject`.
    associatedtype Root: ObjectBase
    /// The object being projected
    var rootObject: Root { get }
    /// :nodoc:
    init(projecting object: Root)
}

/// ``Projection`` is a light weight model of the original Realm ``Object`` or ``EmbeddedObject``.
/// You can use `Projection` as a view model to minimize boilerplate.
///
/// Example of usage:
/// ```swift
/// public class Person: Object {
///     @Persisted var firstName = ""
///     @Persisted var lastName = ""
///     @Persisted var address: Address?
///     @Persisted var friends: List<Person>
///     @Persisted var reviews: List<String>
/// }
///
/// public class Address: EmbeddedObject {
///     @Persisted var city: String = ""
///     @Persisted var country = ""
/// }
///
/// class PersonProjection: Projection<Person> {
///     @Projected(\Person.firstName) var firstName
///     @Projected(\Person.lastName.localizedUppercase)
///     var lastNameCaps
///     @Projected(\Person.address.city) var homeCity
///     @Projected(\Person.friends.projectTo.firstName)
///     var friendsFirstName: ProjectedCollection<String>
/// }
/// ```
///
///  ### Supported property types
///
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
///
/// You can retrieve all Projections of a given type from a Realm by calling the `objects(_:)` of Realm or `init(projecting:)`
/// of Projection's class:
///
/// ```swift
/// let projections = realm.object(PersonProjection.self)
/// let personObject = realm.create(Person.self)
/// let singleProjection = PersonProjection(projecting: personObject)
/// ```
open class Projection<Root: ObjectBase & RealmCollectionValue & ThreadConfined>: RealmCollectionValue, ProjectionObservable {
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

        // Eagerly initialize the schema to ensure we report errors at a sensible time
        _ = schema
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
\t\(schema.map {
    "\t\(String($0.label))(\\.\($0.originPropertyKeyPathString)) = \(rootObject[keyPath: $0.projectedKeyPath]!);"
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
         @Persisted public var friends: List<Person>
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
     - warning: For projected properties where the original property has the same root property name,
                this will trigger a `PropertyChange` for each of the Projected properties even though
                the change only corresponds to one of them.
                For the following `Projection` object
                ```swift
                class PersonProjection: Projection<Person> {
                    @Projected(\Person.firstName) var name
                    @Projected(\Person.address.country) originCountry
                    @Projected(\Person.address.phone.number) mobile
                }

                let token = projectedPerson.observe { changes in
                    if case .change(_, let propertyChanges) = changes {
                        propertyChanges[0].newValue as? String, "Winterfell" // Will notify the new value
                        propertyChanges[1].newValue as? String, "555-555-555" // Will notify with the current value, which hasn't change.
                    }
                })

                try realm.write {
                    person.address.country = "Winterfell"
                }
                ```

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
    public func observe(keyPaths: [String]? = nil,
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (ObjectChange<Self>) -> Void) -> NotificationToken {
        var kps: [String] = schema.map(\.originPropertyKeyPathString)

        // NEXT-MAJOR: stop conflating empty array and nil
        if keyPaths?.isEmpty == false {
            kps = kps.filter { keyPaths!.contains($0) }
        }

        // If we're observing on a different queue, we need a projection which
        // wraps an object confined to that queue. We'll lazily create it the
        // first time the observation block is called. We can't create it now
        // as we're probably not on the queue. If we aren't observing on a queue,
        // we can just use ourself rather than allocating a new object
        var projection: Self?
        if queue == nil {
            projection = self
        }
        let schema = self.schema
        return RLMObjectBaseAddNotificationBlock(rootObject, kps, queue) { object, names, oldValues, newValues, error in
            assert(error == nil) // error is no longer used
            guard let names = names, let newValues = newValues else {
                block(.deleted)
                return
            }
            if projection == nil {
                projection = Self(projecting: object as! Self.Root)
            }

            // Mapping the old values to the projected values requires assigning
            // them to an object and then reading from the projected key path
            var unmanagedRoot: Self.Root?
            if let oldValues = oldValues {
                unmanagedRoot = Self.Root()
                for i in 0..<oldValues.count {
                    unmanagedRoot!.setValue(oldValues[i], forKey: names[i])
                }
            }

            var projectedChanges = [PropertyChange]()
            for i in 0..<newValues.count {
                let filter: (ProjectionProperty) -> Bool = { prop in
                    if prop.originPropertyKeyPathString.components(separatedBy: ".").first != names[i] {
                        return false
                    }
                    guard let keyPaths, !keyPaths.isEmpty else {
                        return true
                    }

                    // This will allow us to notify `PropertyChange`s associated only to the keyPaths passed by the user, instead of any Property which has the same root as the notified one.
                    return keyPaths.contains(prop.originPropertyKeyPathString)
                }
                for property in schema.filter(filter) {
                    // If the root is marked as modified this will build a `PropertyChange` for each of the Projection properties with the same original root, even if there is no change on their value.
                    var changeOldValue: Any?
                    if oldValues != nil {
                        changeOldValue = unmanagedRoot![keyPath: property.projectedKeyPath]
                    }
                    let changedNewValue = object[keyPath: property.projectedKeyPath]
                    projectedChanges.append(.init(name: property.label,
                                                  oldValue: changeOldValue,
                                                  newValue: changedNewValue))
                }
            }

            // keypath filtering means this should never actually be empty
            if !projectedChanges.isEmpty {
                block(.change(projection!, projectedChanges))
            }
        }
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
         @Persisted public var friends: List<Person>
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
    public func observe(keyPaths: [PartialKeyPath<Self>],
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (ObjectChange<Self>) -> Void) -> NotificationToken {
        observe(keyPaths: map(keyPaths: keyPaths), on: queue, block)
    }

    /**
     Registers a block to be called each time the projection's underlying object changes.

     The block will be asynchronously called on the actor after each write transaction which
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
         @Persisted public var friends: List<Person>
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

     Notifications are delivered to a function isolated to the given actor, on that
     actors executor. If the actor is performing blocking work, multiple
     notifications may be coalesced into a single notification.

     Unlike with Collection notifications, there is no "Initial" notification
     and there is no gap between when this function returns and when changes
     will first be captured.

     You must retain the returned token for as long as you want updates to be sent
     to the block. To stop receiving updates, call `invalidate()` on the token.

     - warning: This method cannot be called during a write transaction, or when
                the containing Realm is read-only.
     - parameter keyPaths: Only properties contained in the key paths array will trigger
                           the block when they are modified. If `nil`, notifications
                           will be delivered for any projected property change on the object.
                           String key paths which do not correspond to a valid projected property
                           will throw an exception.
     - parameter actor: The actor which notifications should be delivered on. The
                        block is passed this actor as an isolated parameter,
                        allowing you to access the actor synchronously from within the callback.
     - parameter block: The block to call with information about changes to the object.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    @available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
    @_unsafeInheritExecutor
    public func observe<A: Actor>(
        keyPaths: [String]? = nil, on actor: A,
        _ block: @Sendable @escaping (isolated A, ObjectChange<Self>) -> Void
    ) async -> NotificationToken {
        await with(self, on: actor) { actor, obj in
            obj.observe(keyPaths: keyPaths, on: nil) { (change: ObjectChange<Self>) in
                assumeOnActorExecutor(actor) { actor in
                    block(actor, change)
                }
            }
        } ?? NotificationToken()
    }

    /**
     Registers a block to be called each time the projection's underlying object changes.

     The block will be asynchronously called on the actor after each write transaction which
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
         @Persisted public var friends: List<Person>
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
     `Person.firstName` property of the the projection's underlying `Person` Object,
     but not for any changes made to `Person.lastName` or `Person.friends` list.
     - The notification block fires for changes of `PersonProjection.name` property, but not  for
     another projection's property change.
     - If the observed key path were `[\.firstFriendsName]`, then any insertion,
     deletion, or modification of the `firstName` of the `friends` list will trigger the block. A change to
     `someFriend.lastName` would not trigger the block (where `someFriend`
     is an element contained in `friends`)

     Notifications are delivered to a function isolated to the given actor, on that
     actors executor. If the actor is performing blocking work, multiple
     notifications may be coalesced into a single notification.

     Unlike with Collection notifications, there is no "Initial" notification
     and there is no gap between when this function returns and when changes
     will first be captured.

     You must retain the returned token for as long as you want updates to be sent
     to the block. To stop receiving updates, call `invalidate()` on the token.

     - warning: This method cannot be called during a write transaction, or when
                the containing Realm is read-only.
     - parameter keyPaths: Only properties contained in the key paths array will trigger
                           the block when they are modified. If `nil`, notifications
                           will be delivered for any projected property change on the object.
                           String key paths which do not correspond to a valid projected property
                           will throw an exception.
     - parameter actor: The actor which notifications should be delivered on. The
                        block is passed this actor as an isolated parameter,
                        allowing you to access the actor synchronously from within the callback.
     - parameter block: The block to call with information about changes to the object.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    @available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
    @_unsafeInheritExecutor
    public func observe<A: Actor>(
        keyPaths: [PartialKeyPath<Self>], on actor: A,
        _ block: @Sendable @escaping (isolated A, ObjectChange<Self>) -> Void
    ) async -> NotificationToken {
        await observe(keyPaths: map(keyPaths: keyPaths), on: actor, block)
    }

    fileprivate var schema: [ProjectionProperty] {
        projectionSchemaCache.schema(for: self)
    }

    private func map(keyPaths: [PartialKeyPath<Self>]) -> [String]? {
        if keyPaths.isEmpty {
            return nil
        }

        let names = NSMutableArray()
        let root = Root.keyPathRecorder(with: names)
        let projection = Self(projecting: root)
        return keyPaths.map {
            names.removeAllObjects()
            _ = projection[keyPath: $0]
            return names.componentsJoined(by: ".")
        }
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
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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

// MARK: - RealmSubscribable
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Projection: ObservableObject, RealmSubscribable where Root: ThreadConfined {
    /// A publisher that emits Void each time the projection changes.
    ///
    /// Despite the name, this actually emits *after* the projection has changed.
    public var objectWillChange: RealmPublishers.WillChange<Projection> {
        RealmPublishers.WillChange(self)
    }
}

// MARK: Implementation

private struct ProjectionProperty: @unchecked Sendable {
    let projectedKeyPath: AnyKeyPath
    let originPropertyKeyPathString: String
    let label: String
}

// A subset of OSAllocatedUnfairLock, which requires iOS 16
internal final class AllocatedUnfairLock<Value>: @unchecked Sendable {
    private var value: Value
    private let impl: os_unfair_lock_t = .allocate(capacity: 1)

    init(_ value: Value) {
        impl.initialize(to: os_unfair_lock())
        self.value = value
    }

    func withLock<R>(_ body: (inout Value) -> R) -> R {
        os_unfair_lock_lock(impl)
        let ret = body(&value)
        os_unfair_lock_unlock(impl)
        return ret
    }
}

// A property wrapper which unsafely disables concurrency checking for a property
// This is required when a property is guarded by something which concurrency
// checking doesn't understand (i.e. a lock instead of an actor)
@usableFromInline
@propertyWrapper
internal struct Unchecked<Wrapped>: @unchecked Sendable {
    public var wrappedValue: Wrapped
    public init(wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }
    public init(_ wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }
}

private final class ProjectionSchemaCache: @unchecked Sendable {
    private static let schema = AllocatedUnfairLock([ObjectIdentifier: [ProjectionProperty]]())

    fileprivate func schema<T: ProjectionObservable>(for obj: T) -> [ProjectionProperty] {
        let identifier = ObjectIdentifier(type(of: obj))
        if let schema = Self.schema.withLock({ $0[identifier] }) {
            return schema
        }

        var properties = [ProjectionProperty]()
        for child in Mirror(reflecting: obj).children {
            guard let label = child.label?.dropFirst() else { continue }
            guard let projected = child.value as? AnyProjected else { continue }

            let originPropertyLabel = _name(for: projected.projectedKeyPath as! PartialKeyPath<T.Root>)
            guard !originPropertyLabel.isEmpty else {
                throwRealmException("@Projected property '\(label)' must be a part of Realm object")
            }
            properties.append(.init(projectedKeyPath: projected.projectedKeyPath,
                                    originPropertyKeyPathString: originPropertyLabel,
                                    label: String(label)))
        }
        let p = properties
        Self.schema.withLock {
            // This might overwrite a schema generated by a different thread
            // if we happened to do the initialization on multiple threads at
            // once, but if so that's fine.
            $0[identifier] = p
        }
        return properties
    }
}

private let projectionSchemaCache = ProjectionSchemaCache()
