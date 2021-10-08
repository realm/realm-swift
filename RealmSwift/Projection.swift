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

fileprivate protocol AnyProjected {
    var projectedKeyPath: AnyKeyPath { get }
}

// MARK: Projection

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
///     typealias Root = Person
///
///     @Projected(\Person.firstName) var firstName
///     @Projected(\Person.address.city) var homeCity
///     @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: ProjectedList<String>
/// }
///
/// let people: [PersonProjection] = realm.objects(PersonProjection.self)
/// ```
@propertyWrapper
public struct Projected<T: ObjectBase, Value>: AnyProjected {
//    func bind(ptr: UnsafeMutableRawPointer) -> AnyKeyPath {
//        ptr.assumingMemoryBound(to: Self.self).pointee.projectedKeyPath
//    }
    fileprivate var _projectedKeyPath: KeyPath<T, Value>!
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
            if let lastAccessedNames = observed.rootObject.lastAccessedNames {
                lastAccessedNames.add(_name(for: storage._projectedKeyPath!))
            }
            return observed.rootObject[keyPath: storage._projectedKeyPath]
        }
        set {
            precondition(observed[keyPath: storageKeyPath].projectedKeyPath is WritableKeyPath<T, Value>,
                         "KeyPath is not writable")
            observed.rootObject[keyPath: observed[keyPath: storageKeyPath].projectedKeyPath as! WritableKeyPath<T, Value>] = newValue
        }
    }

    /// Declares a property which is lazily initialized to the type's default value.
    public init(_ projectedKeyPath: KeyPath<T, Value>) {
        self._projectedKeyPath = projectedKeyPath
    }
}

// MARK: Projection Schema
fileprivate struct ProjectedMetadata {
    let projectedKeyPath: AnyKeyPath
    let originPropertyKeyPathString: String
    let label: String
}

fileprivate struct ProjectionMetadata {
    let propertyMetadatas: [ProjectedMetadata]
    let mirror: Mirror
}

private var schema = [ObjectIdentifier: ProjectionMetadata]()

// MARK: ProjectionOservable
public protocol ProjectionObservable: AnyObject {
    associatedtype Root: ObjectBase
    var rootObject: Root { get }
    init(projecting object: Root)
}

public enum ProjectionChange<T: ProjectionObservable> {
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
    case change(_: T, _: [ProjectedPropertyChange])
    /// The object has been deleted from the Realm.
    case deleted

    fileprivate static func processChange(_ objectChange: ObjectChange<T.Root>, _ schema: ProjectionMetadata) -> ProjectionChange<T> {
        switch objectChange {
        case .error(let error):
            return .error(error)
        case .change(let object, let objectPropertyChanges):
            let newProjection = T(projecting: object)
            let projectedPropertyChanges: [ProjectedPropertyChange] = objectPropertyChanges.map { propChange in
                let metadata = schema
                // read the metadata for the property whose origin name matches
                // the changed property's name
                let propertyMetadata = metadata.propertyMetadatas.first(where: {
                    $0.originPropertyKeyPathString == propChange.name
                })!
                var change: (name: String?, oldValue: Any?, newValue: Any?) = (nil, nil, nil)
                if let oldValue = propChange.oldValue {
                    // if there is an oldValue in the change, construct an empty Root
                    let newRoot = T.Root()

                    let processorProjection = T(projecting: newRoot)

                    // assign the oldValue to the empty root object
                    processorProjection.rootObject.setValue(oldValue, forKey: propChange.name)
                    change.oldValue = processorProjection.rootObject[keyPath: propertyMetadata.projectedKeyPath]
                }
                if propChange.newValue != nil {
                    change.newValue = newProjection.rootObject[keyPath: propertyMetadata.projectedKeyPath]
                }

                change.name = String(propertyMetadata.label.dropFirst()) // this drops the _ from the property wrapper name
                return ProjectedPropertyChange(name: change.name!,
                                               oldValue: change.oldValue,
                                               newValue: change.newValue)
            }
            return .change(newProjection, projectedPropertyChanges)
        case .deleted:
            return .deleted
        }
    }
}

/// Projections are a light weight structure of  the original Realm objects with a minimal effort.
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
/// class PersonProjection: Projection<Person> {
///     @Projected(\Person.firstName) var firstName
///     @Projected(\Person.lastName.localizedUppercase) var lastNameCaps
///     @Projected(\Person.address.city) var homeCity
///     @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: ProjectedList<String>
/// }
/// ```
open class Projection<Root: ObjectBase>: RealmCollectionValue, ProjectionObservable {

    /// The object being projected
    public var rootObject: Root

    /**
     Create a new projection.
     - parameter object: The object to project.
     */
    public required init(projecting object: Root) {
        self.rootObject = object
    }
}

extension ProjectionObservable {
    public func observe(keyPaths: [String] = [],
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (ProjectionChange<Self>) -> Void) -> NotificationToken {
        let kps: [String]
        if keyPaths.isEmpty {
            kps = _schema.propertyMetadatas.map(\.originPropertyKeyPathString)
        } else {
            kps = _schema.propertyMetadatas.filter { keyPaths.contains($0.originPropertyKeyPathString) }.map(\.originPropertyKeyPathString)
        }
        return rootObject._observe(keyPaths: kps,
                                   on: queue, { change in
            block(ProjectionChange.processChange(change, self._schema))
        })
    }

    public func observe(keyPaths: [PartialKeyPath<Self>] = [],
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (ProjectionChange<Self>) -> Void) -> NotificationToken {
        let kps: [String]
        if keyPaths.isEmpty {
            kps = _schema.propertyMetadatas.map { $0.originPropertyKeyPathString }
        } else {
            let emptyRoot = Root()
            emptyRoot.lastAccessedNames = NSMutableArray()
            emptyRoot.prepareForRecording()
            let emptyProjection = Self(projecting: emptyRoot) // tracer time
            keyPaths.forEach {
                emptyProjection[keyPath: $0]
            }
            kps = emptyRoot.lastAccessedNames! as! [String]
        }
        return rootObject._observe(keyPaths: kps,
                                   on: queue, { change in
            block(ProjectionChange.processChange(change, self._schema))
        })
    }

    fileprivate var _schema: ProjectionMetadata {
        if schema[ObjectIdentifier(Self.self)] == nil {
            let mirror = Mirror(reflecting: self)
            let metadatas: [ProjectedMetadata] = mirror.children.compactMap { child in
                guard let projected = child.value as? AnyProjected else {
                    return nil
                }
                return ProjectedMetadata(projectedKeyPath: projected.projectedKeyPath,
                                         originPropertyKeyPathString: _name(for: projected.projectedKeyPath as! PartialKeyPath<Root>),
                                         label: child.label!)
            }
            schema[ObjectIdentifier(Self.self)] = ProjectionMetadata(propertyMetadatas: metadatas,
                                                                     mirror: mirror)
        }
        return schema[ObjectIdentifier(Self.self)]!
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
    func addObserver(_ observer: NSObject,
                     forKeyPath keyPath: String,
                     options: NSKeyValueObservingOptions = [],
                     context: UnsafeMutableRawPointer?) {
        rootObject.addObserver(observer, forKeyPath: keyPath, options: options, context: context)
    }

    func removeObserver(_ observer: NSObject,
                        forKeyPath keyPath: String,
                        context: UnsafeMutableRawPointer?) {
        rootObject.removeObserver(observer, forKeyPath: keyPath, context: context)
    }

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

extension Projection {
    public static var _rlmType: PropertyType {
        fatalError()
    }
    
    public static var _rlmOptional: Bool {
        fatalError()
    }
    public static func _rlmDefaultValue(_ forceDefaultInitialization: Bool) -> Self {
        fatalError()
    }
    public static var _rlmRequireObjc: Bool { false }
    
    public func _rlmPopulateProperty(_ prop: RLMProperty) {
        fatalError()
    }

    public static func _rlmPopulateProperty(_ prop: RLMProperty) {
        fatalError()
    }
    
    public static func ==(lhs: Projection, rhs: Projection) -> Bool {
        RLMObjectBaseAreEqual(lhs.rootObject, rhs.rootObject)
    }

    public func hash(into hasher: inout Hasher) {
        let hashVal = rootObject.hashValue
        hasher.combine(hashVal)
    }
}

// MARK: Projected List
/// ProjectedList is a special type of collection for Projection's properties
/// You don't need to instantialte this type manually.
public struct ProjectedList<NewElement>: RandomAccessCollection where NewElement: RealmCollectionValue {
    public typealias Element = NewElement
    public typealias Index = Int

    public func index(matching predicate: NSPredicate) -> Int? {
        backingList.index(matching: predicate)
    }

    public func observe(on queue: DispatchQueue?,
                        _ block: @escaping (RealmCollectionChange<ProjectedList<NewElement>>) -> Void) -> NotificationToken {
        backingList.observe(on: queue, {
            switch $0 {
            case .initial(let collection):
                block(.initial(Self(collection,
                                    keyPathToNewElement: self.keyPath as! KeyPath<Object, NewElement>)))
            case .update(let collection,
                         deletions: let deletions,
                         insertions: let insertions,
                         modifications: let modifications):
                block(.update(Self(collection,
                                   keyPathToNewElement: self.keyPath as! KeyPath<Object, NewElement>),
                              deletions: deletions,
                              insertions: insertions,
                              modifications: modifications))
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
    public mutating func freeze() -> Self {
        backingList = backingList.freeze()
        return self
    }
    public mutating func thaw() -> Self? {
        guard let backingList = backingList.thaw() else {
            return nil
        }
        self.backingList = backingList
        return self
    }

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

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
@dynamicMemberLookup
public struct ElementMapper<Element> where Element: ObjectBase, Element: RealmCollectionValue {
    var list: List<Element>
    public subscript<V>(dynamicMember member: KeyPath<Element, V>) -> ProjectedList<V> {
        ProjectedList(list, keyPathToNewElement: member)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension List where Element: ObjectBase, Element: RealmCollectionValue {
    public var projectTo: ElementMapper<Element> {
        ElementMapper(list: self)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension Projection: AssistedObjectiveCBridgeable {
    internal static func bridging(from objectiveCValue: Any, with metadata: Any?) -> Self {
        return Self(projecting: Root.bridging(from: objectiveCValue, with: metadata))
    }

    internal var bridged: (objectiveCValue: Any, metadata: Any?) {
        return self.rootObject.bridged
    }
}

#if canImport(Combine)
// MARK: - RealmSubscribable
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension ProjectionObservable {
    /// :nodoc:
    public func _observe<S>(_ keyPaths: [String]?, on queue: DispatchQueue?, _ subscriber: S) -> NotificationToken where S: Subscriber, S.Input == Self, S.Failure == Error {
        return observe(keyPaths: keyPaths ?? [], on: queue) { (change: ProjectionChange<S.Input>) in
            switch change {
            case .change(let projection, _):
                _ = subscriber.receive(projection)
            case .deleted:
                subscriber.receive(completion: .finished)
            case .error(let error):
                subscriber.receive(completion: .failure(error))
            }
        }
    }

    /// :nodoc:
    public func _observe<S>(_ keyPaths: [String]?, _ subscriber: S) -> NotificationToken where S : Subscriber, S.Failure == Never, S.Input == Void {
        return observe(keyPaths: [PartialKeyPath<Self>](), { _ in _ = subscriber.receive() })
    }
}
@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension Projection: ObservableObject, RealmSubscribable where Root: ThreadConfined {
    /// A publisher that emits Void each time the projection changes.
    ///
    /// Despite the name, this actually emits *after* the projection has changed.
    public var objectWillChange: RealmPublishers.WillChange<Projection> {
        RealmPublishers.WillChange(self)
    }
}
#endif
