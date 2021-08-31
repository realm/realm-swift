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

fileprivate protocol _Projected {
    var objectBase: ObjectBase! { get }
    func set(object: ObjectBase)
    func observe<T: ObjectBase>(keyPaths: [String]?, on queue: DispatchQueue?, _ block: @escaping (ObjectChange<T>) -> Void) -> NotificationToken
    var hit: Bool { get }
    var keyPathString: String? { get }
    var value: Any? { get }
}

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
///     public typealias Root = Person
///     public init() {
///     }
///     @Projected(\Person.firstName) var firstName
///     @Projected(\Person.address.city) var homeCity
///     @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: ProjectedList<String>
/// }
///
/// let people: [PersonProjection] = realm.objects(PersonProjection.self)
/// ```
@propertyWrapper
public struct Projected<T: ObjectBase, Value>: _Projected {

    fileprivate var hit: Bool = false
    public var keyPathString: String?

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
    
    var value: Any? {
        get {
            wrappedValue
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
        self.keyPathString = _name(for: projectedKeyPath)
    }

    public func observe<T: ObjectBase>(keyPaths: [String]? = nil,
                                       on queue: DispatchQueue? = nil,
                                       _ block: @escaping (ObjectChange<T>) -> Void) -> NotificationToken {
        return objectBase._observe(keyPaths: keyPaths, on: queue, block)
    }
}

public protocol _Projection: ThreadConfined {
    var value: ObjectBase { get }
    init<T: ObjectBase>(object: T)
}

// MARK: AssistedObjectiveCBridgeable

extension _Projection {

    internal static func bridging(from objectiveCValue: Any, with metadata: Any?) -> Self {
////        return forceCastToInferred(objectiveCValue)
//        type(of:objectiveCValue).brid
//        (objectiveCValue as! AssistedObjectiveCBridgeable).bridging(from: objectiveCValue, with: metadata)
//        let value = forceCastToInferred(objectiveCValue)
////        let projectionClass = metadata as! _Projection.Type
        return Self(object: objectiveCValue as! ObjectBase)
    }

    internal var bridged: (objectiveCValue: Any, metadata: Any?) {
        return (objectiveCValue: value.unsafeCastToRLMObject(), metadata: Self.self)
//        fatalError()
    }
}

public protocol Projection: _Projection, RealmCollectionValue {
    associatedtype Root: ObjectBase

    init()
}

/// Projection allows to create a light weight const reflection of the original Realm objects with a minimal effort.
/// And use them as a model in your application.
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
///     public typealias Root = Person
///     public init() {
///     }
///     @Projected(\Person.firstName) var firstName
///     @Projected(\Person.address.city) var homeCity
///     @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: ProjectedList<String>
/// }
/// ```
public extension Projection {

    init(_ object: Root) {
        self.init()
        assign(object)
    }

    init<T: ObjectBase>(object: T) {
        self.init(object as! Root)
    }

    fileprivate func projectedProperties() -> [String: _Projected] {
        return Mirror(reflecting: self).children.reduce([String: _Projected]()) { dict, child in
            var dict = dict
            if let projected = child.value as? _Projected,
               let label = child.label {
                dict[label] = projected
            }
            return dict
        }
    }
    
    fileprivate subscript(label: String) -> _Projected {
        projectedProperties()[label]!
    }

    func assign(_ object: Root) {
//        guard projectedProperties().count > 0 else {
//            fatalError("Projection \(self) should have at least one @Projected property")
//        }
        for (_, projected) in projectedProperties() {
            projected.set(object: object)
        }
    }
}

/**
 Information about a specific property which changed in an `Object` change notification.
 */
@frozen public struct ProjectedChange {
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

public enum ProjectionChange<T: Projection> {
    /**
     If an error occurs, notification blocks are called one time with a `.error`
     result and an `NSError` containing details about the error. Currently the
     only errors which can occur are when opening the Realm on a background
     worker thread to calculate the change set. The callback will never be
     called again after `.error` is delivered.
     */
    case error(_ error: Error)
    /**
     One or more of the properties of the object have been changed.
     */
    case change(_: T, _: [ProjectedChange])
    /// The object has been deleted from the Realm.
    case deleted
    
    init(_ objectChange: ObjectChange<ObjectBase>) {
        switch objectChange {
        case .error(let error):
            self = .error(error)
        case .change(let object, let objectPropertyChanges):
            guard let object = object as? T.Root else {
                fatalError()
            }
            let newProjection = T(object)
            let projectedPropertyChanges: [ProjectedChange] = objectPropertyChanges.map { propChange in
                let name = newProjection.projectionPropertyName(propChange.name)!
                let publicName = name.first == "_" ? String(name.dropFirst()) : name
                let keyPath = \T.[name]
                let newValue: Any? = newProjection[keyPath: keyPath].value
                if let projectedValue = newValue, let realmValue = propChange.newValue,
                   ProjectionChange.isEqual(projectedValue, realmValue) {
                    return ProjectedChange(name: publicName , oldValue: propChange.oldValue, newValue: propChange.newValue)
                }
                // cannot provide old value if it was processed in some way.
                return ProjectedChange(name: publicName , oldValue: nil, newValue: propChange.newValue)
            }
            self = .change(newProjection, projectedPropertyChanges)
        case .deleted:
            self = ProjectionChange.deleted
        }
    }
    
    static func isEqual(_ l: Any, _ r: Any) -> Bool {
        guard let l = l as? AnyHashable, let r = r as? AnyHashable else { return false }
        return l == r
    }
}

extension Projection {

    // MARK: Notifications
    private func activatePropertyKeyPaths() {
        for (name, _) in projectedProperties() {
            let keyPath = \Self.[name]
            _ = self[keyPath: keyPath]
        }
    }
    
    public func observe(keyPaths: [PartialKeyPath<Self>] = [],
                        _ block: @escaping (ProjectionChange<Self>) -> Void) -> NotificationToken {
        if keyPaths.isEmpty {
            activatePropertyKeyPaths()
            let keyPaths = projectedProperties().compactMap { $0.value.keyPathString }
            return realmObject._observe(keyPaths: keyPaths, on: nil, { change in
                block(ProjectionChange<Self>(change))
            })
        } else {
            activatePropertyKeyPaths()
            let filteredProjectedKeyPaths = keyPaths.compactMap { (self[keyPath: $0] as? _Projected)?.keyPathString }
            return realmObject._observe(keyPaths: filteredProjectedKeyPaths, on: nil, { change in
                block(ProjectionChange<Self>(change))
            })
        }
    }

    public func observe(keyPaths: [String]? = nil,
                                       on queue: DispatchQueue? = nil,
                                       _ block: @escaping (ProjectionChange<Self>) -> Void) -> NotificationToken {
        return realmObject._observe(keyPaths: keyPaths, on: queue) { change in
            block(ProjectionChange<Self>(change))
        }
    }

    // Must also conform to `AssistedObjectiveCBridgeable`
    /**
     The Realm which manages the object, or `nil` if the object is unmanaged.
     Note: Projection can be instantiated for the managed objects only therefore realm will never be nil.
     Unmanaged objects are not confined to a thread and cannot be passed to methods expecting a
     `ThreadConfined` object.
     */
    public var realm: Realm? {
        if let object = realmObject as? ThreadConfined {
            return object.realm
        }
        fatalError("Realm cannot be nil")
    }

    /// Indicates if the object can no longer be accessed because it is now invalid.
    public var isInvalidated: Bool {
        return realmObject.isInvalidated
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
        guard let object = realmObject as? ThreadConfined else {
            throwRealmException("Projection underlying object cannot be frozen.")
        }
        let frozenObject = object.freeze()
        return Self(frozenObject as! Root)
    }
    /**
     Returns a live (mutable) reference of this object.
     Will return self if called on an already live object.
     */
    public func thaw() -> Self? {
        guard let object = realmObject as? ThreadConfined else {
            throwRealmException("Projection underlying object cannot be thawed.")
        }
        if let thawedObject = object.thaw() as? Root {
            return Self(thawedObject)
        }
        return nil
    }
    
    fileprivate func projectionPropertyName(_ projectedPropertyName: String) -> String? {
        return projectedProperties().first(where: { $0.value.keyPathString == projectedPropertyName })?.key
    }
    
    public var value: ObjectBase { realmObject }
}

extension Projection {
    public static func _rlmDefaultValue(_ forceDefaultInitialization: Bool) -> Self {
        fatalError()
    }
    
    public static var _rlmType: PropertyType {
        fatalError()
    }
    
    public static var _rlmOptional: Bool {
        fatalError()
    }
    
    public static var _rlmRequireObjc: Bool { false }
    
    public func _rlmPopulateProperty(_ prop: RLMProperty) {
        fatalError()
    }

    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        fatalError()
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        RLMObjectBaseAreEqual(lhs.realmObject, rhs.realmObject)
    }

    fileprivate var realmObject: ObjectBase {
        get {
            projectedProperties().first!.value.objectBase
        }
    }

    public func hash(into hasher: inout Hasher) {
        let hashVal = realmObject.hashValue
        hasher.combine(hashVal)
    }
}

/// ProjectedList is a special type of collection for Projection's properties
/// You don't need to instantialte this type manually.
///
public final class ProjectedList<NewElement>: RandomAccessCollection where NewElement: RealmCollectionValue {
    public func index(matching predicate: NSPredicate) -> Int? {
        backingList.index(matching: predicate)
    }
    public func observe(on queue: DispatchQueue?, _ block: @escaping (RealmCollectionChange<ProjectedList<NewElement>>) -> Void) -> NotificationToken {
        backingList.observe(on: queue, {
            switch $0 {
            case .initial(let collection):
                block(.initial(Self(collection, keyPathToNewElement: self.keyPath as! KeyPath<Object, NewElement>)))
            case .update(let collection, deletions: let deletions, insertions: let insertions, modifications: let modifications):
                block(.update(Self(collection, keyPathToNewElement: self.keyPath as! KeyPath<Object, NewElement>), deletions: deletions, insertions: insertions, modifications: modifications))
            case .error(let error):
                block(.error(error))
            }
        })
    }
    public subscript(position: Int) -> NewElement {
        get {
            backingList[position][keyPath: keyPath] as! NewElement
        }
        set {
            backingList[position].setValue(newValue, forKeyPath: propertyName)
        }
    }
    public var startIndex: Int {
        backingList.startIndex
    }
    public var endIndex: Int {
        backingList.endIndex
    }
    public var realm: Realm?
    public var isInvalidated: Bool {
        backingList.isInvalidated
    }

    public var description: String {
        backingList.map({$0[keyPath: self.keyPath] as! Element}).description
    }
    public func index(of object: Element) -> Int? {
        backingList.map({$0[keyPath: self.keyPath] as! Element}).firstIndex(of: object)
    }
    public var isFrozen: Bool {
        backingList.isFrozen
    }
    public func freeze() -> Self {
        backingList = backingList.freeze()
        return self
    }
    public func thaw() -> Self? {
        guard let backingList = backingList.thaw() else {
            return nil
        }
        self.backingList = backingList
        return self
    }
    public typealias Element = NewElement
    public typealias Index = Int
    private var backingList: List<Object>
    private let keyPath: AnyKeyPath
    private let propertyName: String
    init<OriginalElement: ObjectBase>(_ list: List<OriginalElement>,
                                      keyPathToNewElement: KeyPath<OriginalElement, NewElement>) {
        self.backingList = ObjectiveCSupport.convert(object: list.rlmArray)
        self.keyPath = keyPathToNewElement
        self.propertyName = _name(for: keyPathToNewElement)
    }
}

@dynamicMemberLookup
public struct ElementMapper<Element> where Element: ObjectBase, Element: RealmCollectionValue {
    var list: List<Element>
    public subscript<V>(dynamicMember member: KeyPath<Element, V>) -> ProjectedList<V> {
        ProjectedList(list, keyPathToNewElement: member)
    }
}

extension List where Element: ObjectBase, Element: RealmCollectionValue {
    public var projectTo: ElementMapper<Element> {
        ElementMapper(list: self)
    }
}

public extension Projection {

    private func realmObjectKeyPath(_ projectionKeyPath: String) -> String? {
        let projectionKeyPath = projectionKeyPath.first == "_" ? projectionKeyPath : "_" + projectionKeyPath
        guard let property = projectedProperties()[projectionKeyPath] else {
            return nil
        }
        return property.keyPathString
    }
    func addObserver(_ observer: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions = [], context: UnsafeMutableRawPointer?) {
        guard let keyPath = realmObjectKeyPath(keyPath) else {
            fatalError()
        }
        realmObject.addObserver(observer, forKeyPath: keyPath, options: options, context: context)
    }

    @available(macOS 10.7, *)
    func removeObserver(_ observer: NSObject, forKeyPath keyPath: String, context: UnsafeMutableRawPointer?) {
        guard let keyPath = realmObjectKeyPath(keyPath) else {
            fatalError()
        }
        realmObject.removeObserver(observer, forKeyPath: keyPath, context: context)
    }

    func removeObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        guard let keyPath = realmObjectKeyPath(keyPath) else {
            fatalError()
        }
        realmObject.removeObserver(observer, forKeyPath: keyPath)
    }
}
