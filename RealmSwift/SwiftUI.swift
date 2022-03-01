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

import Foundation

#if !(os(iOS) && (arch(i386) || arch(arm)))
import SwiftUI
import Combine
import Realm
import Realm.Private

private func safeWrite<Value>(_ value: Value, _ block: (Value) -> Void) where Value: ThreadConfined {
    let thawed = value.realm == nil ? value : value.thaw() ?? value
    if let realm = thawed.realm, !realm.isInWriteTransaction {
        try! realm.write {
            block(thawed)
        }
    } else {
        block(thawed)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private func createBinding<T: ThreadConfined, V>(
    _ value: T,
    forKeyPath keyPath: ReferenceWritableKeyPath<T, V>) -> Binding<V> {

    guard let value = value.isFrozen ? value.thaw() : value else {
        throwRealmException("Could not bind value")
    }

    // store last known value outside of the binding so that we can reference it if the parent
    // is invalidated
    var lastValue = value[keyPath: keyPath]
    return Binding(get: {
        guard !value.isInvalidated else { return lastValue }
        lastValue = value[keyPath: keyPath]
        return lastValue
    }, set: { newValue in
        guard !value.isInvalidated else { return }
        safeWrite(value) { value in
            value[keyPath: keyPath] = newValue
        }
    })
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private func createCollectionBinding<T: ThreadConfined, V: RLMSwiftCollectionBase & ThreadConfined>(
    _ value: T,
    forKeyPath keyPath: ReferenceWritableKeyPath<T, V>) -> Binding<V> {

    guard let value = value.isFrozen ? value.thaw() : value else {
        throwRealmException("Could not bind value")
    }

    var lastValue = value[keyPath: keyPath]
    return Binding(get: {
        guard !value.isInvalidated else { return lastValue }
        lastValue = value[keyPath: keyPath]
        if lastValue.realm != nil {
            lastValue = lastValue.freeze()
        }
        return lastValue
    }, set: { newValue in
        guard !value.isInvalidated else { return }
        safeWrite(value) { value in
            value[keyPath: keyPath] = newValue
        }
    })
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private func createEquatableBinding<T: ThreadConfined, V: Equatable>(
    _ value: T,
    forKeyPath keyPath: ReferenceWritableKeyPath<T, V>) -> Binding<V> {

    guard let value = value.isFrozen ? value.thaw() : value else {
        throwRealmException("Could not bind value")
    }

    var lastValue = value[keyPath: keyPath]
    return Binding(get: {
        guard !value.isInvalidated else { return lastValue }
        lastValue = value[keyPath: keyPath]
        return lastValue
    }, set: { newValue in
        guard !value.isInvalidated else { return }
        guard value[keyPath: keyPath] != newValue else { return }
        safeWrite(value) { value in
            value[keyPath: keyPath] = newValue
        }
    })
}

// MARK: SwiftUIKVO

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@objc(RLMSwiftUIKVO) internal final class SwiftUIKVO: NSObject {
    /// Objects must have observers removed before being added to a realm.
    /// They are stored here so that if they are appended through the Bound Property
    /// system, they can be de-observed before hand.
    fileprivate static var observedObjects = [NSObject: SwiftUIKVO.Subscription]()

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    struct Subscription: Combine.Subscription {
        let observer: NSObject
        let value: NSObject
        let keyPaths: [String]

        var combineIdentifier: CombineIdentifier {
            CombineIdentifier(value)
        }

        func request(_ demand: Subscribers.Demand) {
        }

        func cancel() {
            removeObservers()
            SwiftUIKVO.observedObjects.removeValue(forKey: value)
        }

        fileprivate func removeObservers() {
            guard SwiftUIKVO.observedObjects.keys.contains(value) else {
                return
            }
            keyPaths.forEach {
                value.removeObserver(observer, forKeyPath: $0)
            }
        }

        fileprivate func addObservers() {
            guard SwiftUIKVO.observedObjects.keys.contains(value) else {
                return
            }
            keyPaths.forEach {
                value.addObserver(observer, forKeyPath: $0, options: .init(), context: nil)
            }
        }
    }
    private let receive: () -> Void

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        receive()
    }

    init<S>(subscriber: S) where S: Subscriber, S.Input == Void {
        receive = { _ = subscriber.receive() }
        super.init()
    }
}

// MARK: - ObservableStorage
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private final class ObservableStoragePublisher<ObjectType>: Publisher where ObjectType: ThreadConfined & RealmSubscribable {
    public typealias Output = Void
    public typealias Failure = Never

    var subscribers = [AnySubscriber<Void, Never>]()
    private let value: ObjectType
    private let keyPaths: [String]?
    private let unwrappedValue: ObjectBase?

    init(_ value: ObjectType, _ keyPaths: [String]? = nil) {
        self.value = value
        self.keyPaths = keyPaths
        self.unwrappedValue = nil
    }

    init(_ value: ObjectType, _ keyPaths: [String]? = nil) where ObjectType: ObjectBase {
        self.value = value
        self.keyPaths = keyPaths
        self.unwrappedValue = value
    }

    init(_ value: ObjectType, _ keyPaths: [String]? = nil) where ObjectType: ProjectionObservable {
        self.value = value
        self.keyPaths = keyPaths
        self.unwrappedValue = value.rootObject
    }

    func send() {
        subscribers.forEach {
            _ = $0.receive()
        }
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subscribers.append(AnySubscriber(subscriber))
        if value.realm != nil && !value.isInvalidated, let value = value.thaw() {
            // This path is for cases where the object is already managed. If an
            // unmanaged object becomes managed it will continue to use KVO.
            let token =  value._observe(keyPaths, subscriber)
            subscriber.receive(subscription: ObservationSubscription(token: token))
        } else if let value = unwrappedValue, !value.isInvalidated {
            // else if the value is unmanaged
            let schema = ObjectSchema(RLMObjectBaseObjectSchema(value)!)
            let kvo = SwiftUIKVO(subscriber: subscriber)

            var keyPaths = [String]()
            for property in schema.properties {
                keyPaths.append(property.name)
                value.addObserver(kvo, forKeyPath: property.name, options: .init(), context: nil)
            }
            let subscription = SwiftUIKVO.Subscription(observer: kvo, value: value, keyPaths: keyPaths)
            subscriber.receive(subscription: subscription)
            SwiftUIKVO.observedObjects[value] = subscription
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private class ObservableStorage<ObservedType>: ObservableObject where ObservedType: RealmSubscribable & ThreadConfined & Equatable {
    @Published var value: ObservedType {
        willSet {
            if newValue != value {
                objectWillChange.subscribers.forEach {
                    $0.receive(subscription: ObservationSubscription(token: newValue._observe(keyPaths, $0)))
                }
                objectWillChange.send()
            }
        }
    }

    var objectWillChange: ObservableStoragePublisher<ObservedType>
    var keyPaths: [String]?

    init(_ value: ObservedType, _ keyPaths: [String]? = nil) {
        self.value = value.realm != nil && !value.isInvalidated ? value.thaw() ?? value : value
        self.objectWillChange = ObservableStoragePublisher(value, keyPaths)
        self.keyPaths = keyPaths
    }

    init(_ value: ObservedType, _ keyPaths: [String]? = nil) where ObservedType: ObjectBase {
        self.value = value.realm != nil && !value.isInvalidated ? value.thaw() ?? value : value
        self.objectWillChange = ObservableStoragePublisher(value, keyPaths)
        self.keyPaths = keyPaths
    }

    init(_ value: ObservedType, _ keyPaths: [String]? = nil) where ObservedType: ProjectionObservable {
        self.value = value.realm != nil && !value.isInvalidated ? value.thaw() ?? value : value
        self.objectWillChange = ObservableStoragePublisher(value, keyPaths)
        self.keyPaths = keyPaths
    }
}

// MARK: - StateRealmObject

/// A property wrapper type that instantiates an observable object.
///
/// Create a state realm object in a ``SwiftUI/View``, ``SwiftUI/App``, or
/// ``SwiftUI/Scene`` by applying the `@StateRealmObject` attribute to a property
/// declaration and providing an initial value that conforms to the
/// <doc://com.apple.documentation/documentation/Combine/ObservableObject>
/// protocol:
///
///     @StateRealmObject var model = DataModel()
///
/// SwiftUI creates a new instance of the object only once for each instance of
/// the structure that declares the object. When published properties of the
/// observable realm object change, SwiftUI updates the parts of any view that depend
/// on those properties. If unmanaged, the property will be read from the object itself,
/// otherwise, it will be read from the underlying Realm. Changes to the value will update
/// the view asynchronously:
///
///     Text(model.title) // Updates the view any time `title` changes.
///
/// You can pass the state object into a property that has the
/// ``SwiftUI/ObservedRealmObject`` attribute.
///
/// Get a ``SwiftUI/Binding`` to one of the state object's properties using the
/// `$` operator. Use a binding when you want to create a two-way connection to
/// one of the object's properties. For example, you can let a
/// ``SwiftUI/Toggle`` control a Boolean value called `isEnabled` stored in the
/// model:
///
///     Toggle("Enabled", isOn: $model.isEnabled)
///
/// This will write the modified `isEnabled` property to the `model` object's Realm.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper public struct StateRealmObject<T: RealmSubscribable & ThreadConfined & Equatable>: DynamicProperty {
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @StateObject private var storage: ObservableStorage<T>
    private let defaultValue: T

    /// :nodoc:
    public var wrappedValue: T {
        get {
            let value = storage.value
            if value.realm == nil {
                // if unmanaged return the unmanaged value
                return value
            } else if value.isInvalidated {
                // if invalidated, return the default value
                return defaultValue
            }
            // else return the frozen value. the frozen value
            // will be consumed by SwiftUI, which requires
            // the ability to cache and diff objects and collections
            // during some timeframe. The ObjectType is frozen so that
            // SwiftUI can cache state. other access points will thaw
            // the ObjectType
            return value.freeze()
        }
        nonmutating set {
            storage.value = newValue
        }
    }
    /// :nodoc:
    public var projectedValue: Binding<T> {
        Binding(get: {
            let value = self.storage.value
            if value.isInvalidated {
                return self.defaultValue
            }
            return value
        }, set: { newValue in
            self.storage.value = newValue
        })
    }
    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The List reference to wrap and observe.
     */
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public init<Value>(wrappedValue: T) where T == List<Value> {
        self._storage = StateObject(wrappedValue: ObservableStorage(wrappedValue))
        defaultValue = T()
    }
    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The Map reference to wrap and observe.
     */
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public init<Key, Value>(wrappedValue: T) where T == Map<Key, Value> {
        self._storage = StateObject(wrappedValue: ObservableStorage(wrappedValue))
        defaultValue = T()
    }
    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The ObjectBase reference to wrap and observe.
     */
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public init(wrappedValue: T) where T: ObjectBase & Identifiable {
        self._storage = StateObject(wrappedValue: ObservableStorage(wrappedValue))
        defaultValue = T()
    }
    /**
     Initialize a RealmState struct for a given Projection type.
     - parameter wrappedValue The Projection reference to wrap and observe.
     */
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public init(wrappedValue: T) where T: ProjectionObservable {
        self._storage = StateObject(wrappedValue: ObservableStorage(wrappedValue))
        defaultValue = T(projecting: T.Root())
    }

    /// :nodoc:
    public var _publisher: some Publisher {
        self.storage.objectWillChange
    }
}

// MARK: ObservedResults
/**
 A type which can be used with @ObservedResults propperty wrapper. Children class of Realm Object or Projection.
 It's made to specialize the init methods of ObservedResults.
 */
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol _ObservedResultsValue: RealmCollectionValue { }

/// :nodoc:
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Object: _ObservedResultsValue { }

/// :nodoc:
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Projection: _ObservedResultsValue { }

/// A property wrapper type that represents the results of a query on a realm.
///
/// The results use the realm configuration provided by
/// the environment value `EnvironmentValues/realmConfiguration`.
///
/// Unlike non-SwiftUI results collections, the ObservedResults is mutable. Writes to an ObservedResults collection implicitly
/// perform a write transaction. If you add an object to the ObservedResults that the associated query would filter out, the object
/// is added to the realm but not included in the ObservedResults.
///
/// Given `@ObservedResults var v` in SwiftUI, `$v` refers to a `BoundCollection`.
///
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper public struct ObservedResults<ResultType>: DynamicProperty, BoundCollection where ResultType: _ObservedResultsValue & RealmFetchable & KeypathSortable & Identifiable {
    private class Storage: ObservableStorage<Results<ResultType>> {
        var setupHasRun = false
        private func didSet() {
            if setupHasRun {
                setupValue()
            }
        }

        func setupValue() {
            /// A base value to reset the state of the query if a user reassigns the `filter` or `sortDescriptor`
            let realm = try! Realm(configuration: configuration ?? Realm.Configuration.defaultConfiguration)
            value = realm.objects(ResultType.self)
            if let sortDescriptor = sortDescriptor {
                value = value.sorted(byKeyPath: sortDescriptor.keyPath, ascending: sortDescriptor.ascending)
            }
            if let filter = filter {
                value = value.filter(filter)
            } else if let `where` = `where` {
                value = value.where(`where`)
            }
            setupHasRun = true
        }

        var sortDescriptor: SortDescriptor? {
            didSet {
                didSet()
            }
        }

        var filter: NSPredicate? {
            didSet {
                didSet()
            }
        }
        var `where`: ((Query<ResultType>) -> Query<Bool>)? {
            didSet {
                didSet()
            }
        }
        var configuration: Realm.Configuration? {
            didSet {
                didSet()
            }
        }

        var searchString: String = ""
    }

    @Environment(\.realmConfiguration) var configuration
    @ObservedObject private var storage: Storage
    /// :nodoc:
    fileprivate func searchText<T: ObjectBase>(_ text: String, on keyPath: KeyPath<T, String>) {
        if text.isEmpty {
            if storage.filter != nil {
                storage.filter = nil
            }
        } else if text != storage.searchString {
            storage.filter = Query<T>()[dynamicMember: keyPath].contains(text).predicate
        }
        storage.searchString = text
    }
    /// Stores an NSPredicate used for filtering the Results. This is mutually exclusive
    /// to the `where` parameter.
    @State public var filter: NSPredicate? {
        willSet {
            storage.filter = newValue
        }
    }
#if swift(>=5.5)
    /// Stores a type safe query used for filtering the Results. This is mutually exclusive
    /// to the `filter` parameter.
    @State public var `where`: ((Query<ResultType>) -> Query<Bool>)? {
        // The introduction of this property produces a compiler bug in
        // Xcode 12.5.1. So Swift Queries are supported on Xcode 13 and above
        // when used with SwiftUI.
        willSet {
            storage.where = newValue
        }
    }
#endif
    /// :nodoc:
    @State public var sortDescriptor: SortDescriptor? {
        willSet {
            storage.sortDescriptor = newValue
        }
    }
    /// :nodoc:
    public var wrappedValue: Results<ResultType> {
        if !storage.setupHasRun {
            storage.setupValue()
        }
        return storage.configuration != nil ? storage.value.freeze() : storage.value
    }
    /// :nodoc:
    public var projectedValue: Self {
        return self
    }

    /**
     Initialize a `ObservedResults` struct for a given `Projection` type.
     - parameter type: Observed type
     - parameter configuration: The `Realm.Configuration` used when creating the Realm,
     user's sync configuration for the given partition value will be set as the `syncConfiguration`,
     if empty the configuration is set to the `defaultConfiguration`
     - parameter filter: Observations will be made only for passing objects.
     If no filter given - all objects will be observed
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter sortDescriptor: A sequence of `SortDescriptor`s to sort by
     */
    public init<ObjectType: ObjectBase>(_ type: ResultType.Type,
                                        configuration: Realm.Configuration? = nil,
                                        filter: NSPredicate? = nil,
                                        keyPaths: [String]? = nil,
                                        sortDescriptor: SortDescriptor? = nil) where ResultType: Projection<ObjectType>, ObjectType: ThreadConfined {
        let results = Results<ResultType>(RLMResults<ResultType>.emptyDetached())
        self.storage = Storage(results, keyPaths)
        self.storage.configuration = configuration
        self.filter = filter
        self.sortDescriptor = sortDescriptor
    }
    /**
     Initialize a `ObservedResults` struct for a given `Object` or `EmbeddedObject` type.
     - parameter type: Observed type
     - parameter configuration: The `Realm.Configuration` used when creating the Realm,
     user's sync configuration for the given partition value will be set as the `syncConfiguration`,
     if empty the configuration is set to the `defaultConfiguration`
     - parameter filter: Observations will be made only for passing objects.
     If no filter given - all objects will be observed
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter sortDescriptor: A sequence of `SortDescriptor`s to sort by
     */
    public init(_ type: ResultType.Type,
                configuration: Realm.Configuration? = nil,
                filter: NSPredicate? = nil,
                keyPaths: [String]? = nil,
                sortDescriptor: SortDescriptor? = nil) where ResultType: Object {
        self.storage = Storage(Results(RLMResults<ResultType>.emptyDetached()), keyPaths)
        self.storage.configuration = configuration
        self.filter = filter
        self.sortDescriptor = sortDescriptor
    }
#if swift(>=5.5)
    /**
     Initialize a `ObservedResults` struct for a given `Object` or `EmbeddedObject` type.
     - parameter type: Observed type
     - parameter configuration: The `Realm.Configuration` used when creating the Realm,
     user's sync configuration for the given partition value will be set as the `syncConfiguration`,
     if empty the configuration is set to the `defaultConfiguration`
     - parameter where: Observations will be made only for passing objects.
     If no type safe query is given - all objects will be observed
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter sortDescriptor: A sequence of `SortDescriptor`s to sort by
     */
    public init(_ type: ResultType.Type,
                configuration: Realm.Configuration? = nil,
                where: ((Query<ResultType>) -> Query<Bool>)? = nil,
                keyPaths: [String]? = nil,
                sortDescriptor: SortDescriptor? = nil) where ResultType: Object {
        self.storage = Storage(Results(RLMResults<ResultType>.emptyDetached()), keyPaths)
        self.storage.configuration = configuration
        self.where = `where`
        self.sortDescriptor = sortDescriptor
    }
#endif
    /// :nodoc:
    public init(_ type: ResultType.Type,
                keyPaths: [String]? = nil,
                configuration: Realm.Configuration? = nil,
                sortDescriptor: SortDescriptor? = nil) where ResultType: Object {
        self.storage = Storage(Results(RLMResults<ResultType>.emptyDetached()), keyPaths)
        self.storage.configuration = configuration
        self.sortDescriptor = sortDescriptor
    }

    public mutating func update() {
        // When the view updates, it will inject the @Environment
        // into the propertyWrapper
        if storage.configuration == nil || storage.configuration != configuration {
            storage.configuration = configuration
        }
    }
}

// MARK: ObservedRealmObject

/// A property wrapper type that subscribes to an observable Realm `Object` or `List` and
/// invalidates a view whenever the observable object changes.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper public struct ObservedRealmObject<ObjectType>: DynamicProperty where ObjectType: RealmSubscribable & ThreadConfined & ObservableObject & Equatable {
    /// A wrapper of the underlying observable object that can create bindings to
    /// its properties using dynamic member lookup.
    @dynamicMemberLookup @frozen public struct Wrapper {
        /// :nodoc:
        public var wrappedValue: ObjectType
        /// Returns a binding to the resulting value of a given key path.
        ///
        /// - Parameter keyPath  : A key path to a specific resulting value.
        /// - Returns: A new binding.
        public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>) -> Binding<Subject> {
            createBinding(wrappedValue, forKeyPath: keyPath)
        }
        /// Returns a binding to the resulting equatable value of a given key path.
        ///
        /// This binding's set() will only perform a write if the new value is different from the existing value.
        ///
        /// - Parameter keyPath  : A key path to a specific resulting value.
        /// - Returns: A new binding.
        public subscript<Subject: Equatable>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>) -> Binding<Subject> {
            createEquatableBinding(wrappedValue, forKeyPath: keyPath)
        }
        /// Returns a binding to the resulting collection value of a given key path.
        ///
        /// - Parameter keyPath  : A key path to a specific resulting value.
        /// - Returns: A new binding.
        public subscript<Subject: RLMSwiftCollectionBase & ThreadConfined>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>) -> Binding<Subject> {
            createCollectionBinding(wrappedValue, forKeyPath: keyPath)
        }
    }
    /// The object to observe.
    @ObservedObject private var storage: ObservableStorage<ObjectType>
    /// A default value to avoid invalidated access.
    private let defaultValue: ObjectType

    /// :nodoc:
    public var wrappedValue: ObjectType {
        get {
            if storage.value.realm == nil {
                // if unmanaged return the unmanaged value
                return storage.value
            } else if storage.value.isInvalidated {
                // if invalidated, return the default value
                return defaultValue
            }
            // else return the frozen value. the frozen value
            // will be consumed by SwiftUI, which requires
            // the ability to cache and diff objects and collections
            // during some timeframe. The ObjectType is frozen so that
            // SwiftUI can cache state. other access points will thaw
            // the ObjectType
            return storage.value.freeze()
        }
        set {
            storage.value = newValue
        }
    }
    /// :nodoc:
    public var projectedValue: Wrapper {
        return Wrapper(wrappedValue: storage.value.isInvalidated ? defaultValue : storage.value)
    }
    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The RealmSubscribable value to wrap and observe.
     */
    public init(wrappedValue: ObjectType) where ObjectType: ObjectBase & Identifiable {
        _storage = ObservedObject(wrappedValue: ObservableStorage(wrappedValue))
        defaultValue = ObjectType()
    }
    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The RealmSubscribable value to wrap and observe.
     */
    public init<V>(wrappedValue: ObjectType) where ObjectType == List<V> {
        _storage = ObservedObject(wrappedValue: ObservableStorage(wrappedValue))
        defaultValue = List()
    }
    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The RealmSubscribable value to wrap and observe.
     */
    public init(wrappedValue: ObjectType) where ObjectType: ProjectionObservable {
        _storage = ObservedObject(wrappedValue: ObservableStorage(wrappedValue))
        defaultValue = ObjectType(projecting: ObjectType.Root())
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: ObjectBase & ThreadConfined {
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> where V: _Persistable {
        createBinding(wrappedValue, forKeyPath: member)
    }
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> where V: _Persistable & RLMSwiftCollectionBase & ThreadConfined {
        createCollectionBinding(wrappedValue, forKeyPath: member)
    }
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> where V: _Persistable & Equatable {
        createEquatableBinding(wrappedValue, forKeyPath: member)
    }
}

// MARK: - BoundCollection

/// :nodoc:
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol BoundCollection {
    /// :nodoc:
    associatedtype Value

    /// :nodoc:
    var wrappedValue: Value { get }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundCollection where Value: RealmCollection {
    /// :nodoc:
    typealias Element = Value.Element
    /// :nodoc:
    typealias Index = Value.Index
    /// :nodoc:
    typealias Indices = Value.Indices

    /// :nodoc:
    func remove<V>(at index: Index) where Value == List<V> {
        safeWrite(self.wrappedValue) { list in
            list.remove(at: index)
        }
    }
    /// :nodoc:
    func remove<V>(_ object: V) where Value == Results<V>, V: ObjectBase & ThreadConfined {
        guard let thawed = object.thaw(),
              let index = wrappedValue.thaw()?.index(of: thawed) else {
            return
        }
        safeWrite(self.wrappedValue) { results in
            results.realm?.delete(results[index])
        }
    }
    /// :nodoc:
    func remove<V>(atOffsets offsets: IndexSet) where Value == Results<V>, V: ObjectBase {
        safeWrite(self.wrappedValue) { results in
            results.realm?.delete(Array(offsets.map { results[$0] }))
        }
    }
    /// :nodoc:
    func remove<V>(atOffsets offsets: IndexSet) where Value == List<V> {
        safeWrite(self.wrappedValue) { list in
            list.remove(atOffsets: offsets)
        }
    }
    /// :nodoc:
    func move<V>(fromOffsets offsets: IndexSet, toOffset destination: Int) where Value == List<V> {
        safeWrite(self.wrappedValue) { list in
            list.move(fromOffsets: offsets, toOffset: destination)
        }
    }
    /// :nodoc:
    func append<V>(_ value: Value.Element) where Value == List<V> {
        safeWrite(self.wrappedValue) { list in
            list.append(value)
        }
    }
    /// :nodoc:
    func append<V>(_ value: Value.Element) where Value == List<V>, Value.Element: ObjectBase & ThreadConfined {
        // if the value is unmanaged but the list is managed, we are adding this value to the realm
        if value.realm == nil && self.wrappedValue.realm != nil {
            SwiftUIKVO.observedObjects[value]?.cancel()
        }
        safeWrite(self.wrappedValue) { list in
            list.append(value)
        }
    }
    /// :nodoc:
    func append<V>(_ value: Value.Element) where Value == Results<V>, V: Object {
        if value.realm == nil && self.wrappedValue.realm != nil {
            SwiftUIKVO.observedObjects[value]?.cancel()
        }
        safeWrite(self.wrappedValue) { results in
            results.realm?.add(value)
        }
    }
    /// :nodoc:
    func append<V>(_ value: Value.Element) where Value == Results<V>, V: ProjectionObservable & ThreadConfined, V.Root: Object {
        if value.realm == nil && self.wrappedValue.realm != nil {
            SwiftUIKVO.observedObjects[value.rootObject]?.cancel()
        }
        safeWrite(self.wrappedValue) { results in
            results.realm?.add(value.rootObject)
        }
    }
}
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Binding: BoundCollection where Value: RealmCollection {
}

// MARK: - BoundMap

/// :nodoc:
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol BoundMap {
    /// :nodoc:
    associatedtype Value

    /// :nodoc:
    var wrappedValue: Value { get }
}

/// :nodoc:
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundMap where Value: RealmKeyedCollection {
    /// :nodoc:
    typealias Key = Value.Key
    /// :nodoc:
    typealias Element = Value.Value

    // The compiler will not allow us to assign values by subscript as the binding is a get-only
    // property. To get around this we need an explicit `set` method.
    /// :nodoc:
    subscript( key: Key) -> Element? {
        self.wrappedValue[key]
    }

    /// :nodoc:
    func set<K, V>(object: Element?, for key: Key) where Element: ObjectBase & ThreadConfined, Value == Map<K, V> {
        // If the value is `nil` remove it from the map.
        guard let value = object else {
            safeWrite(self.wrappedValue) { map in
                map.removeObject(for: key)
            }
            return
        }
        // if the value is unmanaged but the map is managed, we are adding this value to the realm
        if value.realm == nil && self.wrappedValue.realm != nil {
            SwiftUIKVO.observedObjects[value]?.cancel()
        }
        safeWrite(self.wrappedValue) { map in
            map[key] = value
        }
    }

    /// :nodoc:
    func set<K, V>(object: Element?, for key: Key) where Value == Map<K, V> {
        // If the value is `nil` remove it from the map.
        guard let value = object else {
            safeWrite(self.wrappedValue) { map in
                map.removeObject(for: key)
            }
            return
        }
        safeWrite(self.wrappedValue) { map in
            map[key] = value
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Binding: BoundMap where Value: RealmKeyedCollection {
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Binding where Value: Object {
    /// :nodoc:
    public func delete() {
        safeWrite(wrappedValue) { object in
            object.realm?.delete(self.wrappedValue)
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Binding where Value: ProjectionObservable, Value.Root: ThreadConfined {
    /// :nodoc:
    public func delete() {
        safeWrite(wrappedValue.rootObject) { object in
            object.realm?.delete(object)
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ThreadConfined where Self: ProjectionObservable {
    /**
     Create a `Binding` for a given property, allowing for
     automatically transacted reads and writes behind the scenes.

     This is a convenience method for SwiftUI views (e.g., TextField, DatePicker)
     that require a `Binding` to be passed in. SwiftUI will automatically read/write
     from the binding.

     - parameter keyPath The key path to the member property.
     - returns A `Binding` to the member property.
     */
    public func bind<V: _Persistable & Equatable>(_ keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V> {
        createEquatableBinding(self, forKeyPath: keyPath)
    }
    /// :nodoc:
    public func bind<V: _Persistable & RLMSwiftCollectionBase & ThreadConfined>(_ keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V> {
        createCollectionBinding(self, forKeyPath: keyPath)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ObservedRealmObject.Wrapper where ObjectType: ObjectBase {
    /// :nodoc:
    public func delete() {
        safeWrite(wrappedValue) { object in
            object.realm?.delete(self.wrappedValue)
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ThreadConfined where Self: ObjectBase {
    /**
     Create a `Binding` for a given property, allowing for
     automatically transacted reads and writes behind the scenes.

     This is a convenience method for SwiftUI views (e.g., TextField, DatePicker)
     that require a `Binding` to be passed in. SwiftUI will automatically read/write
     from the binding.

     - parameter keyPath The key path to the member property.
     - returns A `Binding` to the member property.
     */
    public func bind<V: _Persistable & Equatable>(_ keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V> {
        createEquatableBinding(self, forKeyPath: keyPath)
    }
    /// :nodoc:
    public func bind<V: _Persistable & RLMSwiftCollectionBase & ThreadConfined>(_ keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V> {
        createCollectionBinding(self, forKeyPath: keyPath)
    }
}

private struct RealmEnvironmentKey: EnvironmentKey {
    static let defaultValue = Realm.Configuration.defaultConfiguration
}

private struct PartitionValueEnvironmentKey: EnvironmentKey {
    static let defaultValue: PartitionValue? = nil
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension EnvironmentValues {
    /// The current `Realm.Configuration` that the view should use.
    public var realmConfiguration: Realm.Configuration {
        get {
            return self[RealmEnvironmentKey.self]
        }
        set {
            self[RealmEnvironmentKey.self] = newValue
        }
    }
    /// The current `Realm` that the view should use.
    public var realm: Realm {
        get {
            return try! Realm(configuration: self[RealmEnvironmentKey.self])
        }
        set {
            self[RealmEnvironmentKey.self] = newValue.configuration
        }
    }
    /// The current `PartitionValue` that the view should use.
    public var partitionValue: PartitionValue? {
        get {
            return self[PartitionValueEnvironmentKey.self]
        }
        set {
            self[PartitionValueEnvironmentKey.self] = newValue
        }
    }
}

/**
An enum representing different states from `AsyncOpen` and `AutoOpen` process
*/
public enum AsyncOpenState {
    /// Starting the Realm.asyncOpen process.
    case connecting
    /// Waiting for a user to be logged in before executing Realm.asyncOpen.
    case waitingForUser
    /// The Realm has been opened and is ready for use. For AsyncOpen this means that the Realm has been fully downloaded, but for AutoOpen the existing local file may have been used if the device is offline.
    case open(Realm)
    /// The Realm is currently being downloaded from the server.
    case progress(Progress)
    /// Opening the Realm failed.
    case error(Error)
}

private enum AsyncOpenKind {
    case asyncOpen
    case autoOpen
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private class ObservableAsyncOpenStorage: ObservableObject {
    private var asyncOpenKind: AsyncOpenKind
    private var app: App
    var configuration: Realm.Configuration?
    var partitionValue: AnyBSON

    // Tracks User State for App for Multi-User Support
    enum AppState {
        case loggedIn(User)
        case loggedOut
    }
    private var appState: AppState {
        didSet {
            switch appState {
            case .loggedIn(let user):
                self.asyncOpenForUser(user)
            case .loggedOut:
                asyncOpenState = .waitingForUser
            }
        }
    }

    // Cancellables
    private var appCancellable = [AnyCancellable]()
    private var asyncOpenCancellable = [AnyCancellable]()

    @Published var asyncOpenState: AsyncOpenState = .connecting {
        willSet {
            objectWillChange.send()
        }
    }

    func asyncOpen() {
        if case let .loggedIn(user) = appState {
            asyncOpenForUser(user)
        }
    }

    private func asyncOpenForUser(_ user: User) {
        asyncOpenState = .connecting

        // Use the user configuration by default or set configuration with current user `syncConfiguration`.
        var config = user.configuration(partitionValue: partitionValue, cancelAsyncOpenOnNonFatalErrors: true)
        if var configuration = configuration {
            let userSyncConfig = config.syncConfiguration
            configuration.syncConfiguration = userSyncConfig
            config = configuration
        }

        // Cancel any current subscriptions to asyncOpen if there is one
        cancelAsyncOpen()
        Realm.asyncOpen(configuration: config)
            .onProgressNotification { asyncProgress in
                // Do not change state to progress if the realm file is already opened or there is an error
                switch self.asyncOpenState {
                case .connecting, .waitingForUser, .progress:
                    let progress = Progress(totalUnitCount: Int64(asyncProgress.transferredBytes))
                    progress.completedUnitCount = Int64(asyncProgress.transferredBytes)
                    self.asyncOpenState = .progress(progress)
                default: break
                }
            }
            .sink { completion in
                if case .failure(let error) = completion {
                    switch self.asyncOpenKind {
                    case .asyncOpen:
                        self.asyncOpenState = .error(error)
                    case .autoOpen:
                        if let realm = try? Realm(configuration: config) {
                            self.asyncOpenState = .open(realm)
                        } else {
                            self.asyncOpenState = .error(error)
                        }
                    }
                }
            } receiveValue: { realm in
                self.asyncOpenState = .open(realm)
            }.store(in: &self.asyncOpenCancellable)
    }

    private func cancelAsyncOpen() {
        asyncOpenCancellable.forEach { $0.cancel() }
        asyncOpenCancellable = []
    }

    func cancel() {
        cancelAsyncOpen()
        appCancellable.forEach { $0.cancel() }
        appCancellable = []
    }

    init(asyncOpenKind: AsyncOpenKind, app: App, configuration: Realm.Configuration?, partitionValue: AnyBSON) {
        self.asyncOpenKind = asyncOpenKind
        self.app = app
        self.configuration = configuration
        self.partitionValue = partitionValue

        if let user = app.currentUser {
            appState = .loggedIn(user)
            asyncOpenForUser(user)
        } else {
            appState = .loggedOut
            asyncOpenState = .waitingForUser
        }
        app.objectWillChange.sink { app in
            switch self.appState {
            case .loggedIn(let user):
                if let newUser = app.currentUser,
                    user != newUser {
                    self.appState = .loggedIn(newUser)
                } else if app.currentUser == nil {
                    self.appState = .loggedOut
                }
            case .loggedOut:
                if let user = app.currentUser {
                    self.appState = .loggedIn(user)
                }
            }
        }.store(in: &appCancellable)
    }

    // MARK: - AutoOpen & AsyncOpen Helper

    class func configureApp(appId: String? = nil, withTimeout timeout: UInt? = nil) -> App {
        var app: App
        if let appId = appId {
            app = App(id: appId)
        } else {
            // Check if there is a singular cached app
            let cachedApps = RLMApp.allApps()
            if cachedApps.count > 1 {
                throwRealmException("Cannot AsyncOpen the Realm because more than one appId was found. When using multiple Apps you must explicitly pass an appId to indicate which to use.")
            }
            guard let cachedApp = cachedApps.first else {
                throwRealmException("Cannot AsyncOpen the Realm because no appId was found. You must either explicitly pass an appId or initialize an App before displaying your View.")
            }
            app = cachedApp
        }

        // Setup timeout if needed
        if let timeout = timeout {
            let syncTimeoutOptions = SyncTimeoutOptions()
            syncTimeoutOptions.connectTimeout = timeout
            app.syncManager.timeoutOptions = syncTimeoutOptions
        }
        return app
    }
}

// MARK: - AsyncOpen

/// A property wrapper type that initiates a `Realm.asyncOpen()` for the current user which asynchronously open a Realm,
/// and notifies states for the given process
///
/// Add AsyncOpen to your ``SwiftUI/View`` or ``SwiftUI/App``,  after a user is already logged in,
/// or if a user is going to be logged in
///
///     @AsyncOpen(appId: "app_id", partitionValue: <partition_value>) var asyncOpen
///
/// This will immediately initiates a `Realm.asyncOpen()` operation which will perform all work needed to get the Realm to
/// a usable state. (see Realm.asyncOpen() documentation)
///
/// This property wrapper will publish states of the current `Realm.asyncOpen()` process like progress, errors and an opened realm,
/// which can be used to update the view
///
///     struct AsyncOpenView: View {
///         @AsyncOpen(appId: "app_id", partitionValue: <partition_value>) var asyncOpen
///
///         var body: some View {
///            switch asyncOpen {
///            case .notOpen:
///                ProgressView()
///            case .open(let realm):
///                ListView()
///                   .environment(\.realm, realm)
///            case .error(_):
///                ErrorView()
///            case .progress(let progress):
///                ProgressView(progress)
///            }
///         }
///     }
///
/// This opened `realm` can be later injected to the view as an environment value which will be used by our property wrappers
/// to populate the view with data from the opened realm
///
///     ListView()
///        .environment(\.realm, realm)
///
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper public struct AsyncOpen<Partition>: DynamicProperty where Partition: BSON {
    @Environment(\.realmConfiguration) var configuration
    @Environment(\.partitionValue) var partitionValue
    @ObservedObject private var storage: ObservableAsyncOpenStorage

    /**
     A Publisher for `AsyncOpenState`, emits a state each time the asyncOpen state changes.
     */
    public var projectedValue: Published<AsyncOpenState>.Publisher {
        return storage.$asyncOpenState
    }

    /// :nodoc:
    public var wrappedValue: AsyncOpenState {
        storage.asyncOpenState
    }

    /**
     This will cancel any notification from the property wrapper states
     */
    public func cancel() {
        storage.cancel()
    }

    /**
     Initialize the property wrapper
     - parameter appId: The unique identifier of your Realm app, if empty or `nil` will try to retrieve latest singular cached app.
     - parameter partitionValue: The `BSON` value the Realm is partitioned on.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm,
                 user's sync configuration for the given partition value will be set as the `syncConfiguration`,
                 if empty the user configuration will be used.
     - parameter timeout: The maximum number of milliseconds to allow for a connection to
                 become fully established., if empty or `nil` no connection timeout is set.
     */
    public init(appId: String? = nil,
                partitionValue: Partition,
                configuration: Realm.Configuration? = nil,
                timeout: UInt? = nil) {
        let app = ObservableAsyncOpenStorage.configureApp(appId: appId, withTimeout: timeout)
        // Store property wrapper values on the storage
        storage = ObservableAsyncOpenStorage(asyncOpenKind: .asyncOpen, app: app, configuration: configuration, partitionValue: AnyBSON(partitionValue))
    }

    public mutating func update() {
        if let partitionValue = partitionValue as? Partition {
            let bsonValue = AnyBSON(partitionValue)
            if storage.partitionValue != bsonValue {
                storage.partitionValue = bsonValue
                storage.asyncOpen()
            }
        }

        // We don't want to use the `defaultConfiguration` from the environment, we only want to use this environment value in @AsyncOpen if is not the default one
        if configuration != .defaultConfiguration,
           storage.configuration != configuration {
            if let partitionValue = configuration.syncConfiguration?.partitionValue {
                storage.partitionValue = partitionValue
            }
            storage.configuration = configuration
            storage.asyncOpen()
        }
    }
}

// MARK: - AutoOpen

/// `AutoOpen` will try once to asynchronously open a Realm, but in case of no internet connection will return an opened realm
/// for the given appId and partitionValue which can be used within our view.

/// Add AutoOpen to your ``SwiftUI/View`` or ``SwiftUI/App``,  after a user is already logged in
/// or if a user is going to be logged in
///
///     @AutoOpen(appId: "app_id", partitionValue: <partition_value>, timeout: 4000) var autoOpen
///
/// This will immediately initiates a `Realm.asyncOpen()` operation which will perform all work needed to get the Realm to
/// a usable state. (see Realm.asyncOpen() documentation)
///
/// This property wrapper will publish states of the current `Realm.asyncOpen()` process like progress, errors and an opened realm,
/// which can be used to update the view
///
///     struct AutoOpenView: View {
///         @AutoOpen(appId: "app_id", partitionValue: <partition_value>) var autoOpen
///
///         var body: some View {
///            switch autoOpen {
///            case .notOpen:
///                ProgressView()
///            case .open(let realm):
///                ListView()
///                   .environment(\.realm, realm)
///            case .error(_):
///                ErrorView()
///            case .progress(let progress):
///                ProgressView(progress)
///            }
///         }
///     }
///
/// This opened `realm` can be later injected to the view as an environment value which will be used by our property wrappers
/// to populate the view with data from the opened realm
///
///     ListView()
///        .environment(\.realm, realm)
///
/// This property wrapper behaves similar as `AsyncOpen`, and in terms of declaration and use is completely identical,
/// but with the difference of a offline-first approach.
///
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper public struct AutoOpen<Partition>: DynamicProperty where Partition: BSON {
    @Environment(\.realmConfiguration) var configuration
    @Environment(\.partitionValue) var partitionValue
    @ObservedObject private var storage: ObservableAsyncOpenStorage

    /**
     A Publisher for `AsyncOpenState`, emits a state each time the asyncOpen state changes.
     */
    public var projectedValue: Published<AsyncOpenState>.Publisher {
        return storage.$asyncOpenState
    }

    /// :nodoc:
    public var wrappedValue: AsyncOpenState {
        storage.asyncOpenState
    }

    /**
     This will cancel any notification from the property wrapper states
     */
    public func cancel() {
        storage.cancel()
    }

    /**
     Initialize the property wrapper
     - parameter appId: The unique identifier of your Realm app,  if empty or `nil` will try to retrieve latest singular cached app.
     - parameter partitionValue: The `BSON` value the Realm is partitioned on.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm,
                 user's sync configuration for the given partition value will be set as the `syncConfiguration`,
                 if empty the user configuration will be used.
     - parameter timeout: The maximum number of milliseconds to allow for a connection to
                 become fully established, if empty or `nil` no connection timeout is set.
     */
    public init(appId: String? = nil,
                partitionValue: Partition,
                configuration: Realm.Configuration? = nil,
                timeout: UInt? = nil) {
        let app = ObservableAsyncOpenStorage.configureApp(appId: appId, withTimeout: timeout)
        // Store property wrapper values on the storage
        storage = ObservableAsyncOpenStorage(asyncOpenKind: .autoOpen, app: app, configuration: configuration, partitionValue: AnyBSON(partitionValue))
    }

    public mutating func update() {
        if let partitionValue = partitionValue as? Partition {
            let bsonValue = AnyBSON(partitionValue)
            if storage.partitionValue != bsonValue {
                storage.partitionValue = bsonValue
                storage.asyncOpen()
            }
        }

        // We don't want to use the `defaultConfiguration` from the environment, we only want to use this environment value in @AsyncOpen if is not the default one
        if configuration != .defaultConfiguration,
           storage.configuration != configuration {
            if let partitionValue = configuration.syncConfiguration?.partitionValue {
                storage.partitionValue = partitionValue
            }
            storage.configuration = configuration
            storage.asyncOpen()
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUIKVO {
    @objc(removeObserversFromObject:) static func removeObservers(object: NSObject) -> Bool {
        if let subscription = SwiftUIKVO.observedObjects[object] {
            subscription.removeObservers()
            return true
        } else {
            return false
        }
    }

    @objc(addObserversToObject:) static func addObservers(object: NSObject) {
        if let subscription = SwiftUIKVO.observedObjects[object] {
            subscription.addObservers()
        }
    }
}

// Adding `_Concurrency` flag is the only way to verify
// if the BASE SDK contains latest framework updates
#if swift(>=5.5) && canImport(_Concurrency)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    /// Marks this view as searchable, which configures the display of a search field.
    /// You can provide a collection and a key path to be filtered using the search
    /// field string provided by the searchable component, this will result in the collection
    /// querying for all items containing the search field string for the given key path.
    ///
    ///     @State var searchString: String
    ///     @ObservedResults(Reminder.self) var reminders
    ///
    ///     List {
    ///         ForEach(reminders) { reminder in
    ///             ReminderRowView(reminder: reminder)
    ///         }
    ///     }
    ///     .searchable(text: $searchFilter,
    ///                 collection: $reminders,
    ///                 keyPath: \.name) {
    ///         ForEach(reminders) { remindersFiltered in
    ///             Text(remindersFiltered.name).searchCompletion(remindersFiltered.name)
    ///         }
    ///     }
    ///
    /**
    - Note: See ``SwiftUI/View/searchable(text:placement:prompt)``
            <https://developer.apple.com/documentation/swiftui/form/searchable(text:placement:prompt:)-6royb>
            for more information on searchable view modifier.

    - parameter text: The text to display and edit in the search field.
    - parameter collection: The collection to be filtered.
    - parameter keyPath: The key path to the property which will be used to filter
                the collection, only key paths with `String` type are allowed.
    - parameter placement: The preferred placement of the search field within the
                containing view hierarchy.
    - parameter prompt: A `Text` representing the prompt of the search field
                which provides users with guidance on what to search for.
     */
    public func searchable<T: ObjectBase>(text: Binding<String>, collection: ObservedResults<T>, keyPath: KeyPath<T, String>,
                                          placement: SearchFieldPlacement = .automatic, prompt: Text? = nil) -> some View {
        filterCollection(collection, for: text.wrappedValue, on: keyPath)
        return searchable(text: text, placement: placement, prompt: prompt)
    }

    /// Marks this view as searchable, which configures the display of a search field.
    /// You can provide a collection and a key path to be filtered using the search
    /// field string provided by the searchable component, this will result in the collection
    /// querying for all items containing the search field string for the given key path.
    ///
    ///     @State var searchString: String
    ///     @ObservedResults(Reminder.self) var reminders
    ///
    ///     List {
    ///         ForEach(reminders) { reminder in
    ///             ReminderRowView(reminder: reminder)
    ///         }
    ///     }
    ///     .searchable(text: $searchFilter,
    ///                 collection: $reminders,
    ///                 keyPath: \.name) {
    ///         ForEach(reminders) { remindersFiltered in
    ///             Text(remindersFiltered.name).searchCompletion(remindersFiltered.name)
    ///         }
    ///     }
    ///
    /**
    - Note: See ``SwiftUI/View/searchable(text:placement:prompt)``
            <https://developer.apple.com/documentation/swiftui/form/searchable(text:placement:prompt:)-2ed8t>
            for more information on searchable view modifier.

    - parameter text: The text to display and edit in the search field.
    - parameter collection: The collection to be filtered.
    - parameter keyPath: The key path to the property which will be used to filter
                the collection.
    - parameter placement: The preferred placement of the search field within the
                containing view hierarchy.
    - parameter prompt: The key for the localized prompt of the search field
                which provides users with guidance on what to search for.
     */
    public func searchable<T: ObjectBase>(text: Binding<String>, collection: ObservedResults<T>,
                                          keyPath: KeyPath<T, String>, placement: SearchFieldPlacement = .automatic,
                                          prompt: LocalizedStringKey) -> some View {
        filterCollection(collection, for: text.wrappedValue, on: keyPath)
        return searchable(text: text,
                          placement: placement,
                          prompt: prompt)
    }

    /// Marks this view as searchable, which configures the display of a search field.
    /// You can provide a collection and a key path to be filtered using the search
    /// field string provided by the searchable component, this will result in the collection
    /// querying for all items containing the search field string for the given key path.
    ///
    ///     @State var searchString: String
    ///     @ObservedResults(Reminder.self) var reminders
    ///
    ///     List {
    ///         ForEach(reminders) { reminder in
    ///             ReminderRowView(reminder: reminder)
    ///         }
    ///     }
    ///     .searchable(text: $searchFilter,
    ///                 collection: $reminders,
    ///                 keyPath: \.name) {
    ///         ForEach(reminders) { remindersFiltered in
    ///             Text(remindersFiltered.name).searchCompletion(remindersFiltered.name)
    ///         }
    ///     }
    ///
    /**
    - Note: See ``SwiftUI/View/searchable(text:placement:prompt)``
            <https://developer.apple.com/documentation/swiftui/form/searchable(text:placement:prompt:)-58egp>
            for more information on searchable view modifier.

    - parameter text: The text to display and edit in the search field.
    - parameter collection: The collection to be filtered.
    - parameter keyPath: The key path to the property which will be used to filter
                the collection.
    - parameter placement: The preferred placement of the search field within the
                containing view hierarchy.
    - parameter prompt: A string representing the prompt of the search field
                which provides users with guidance on what to search for.
     */
    public func searchable<T: ObjectBase, S>(text: Binding<String>, collection: ObservedResults<T>, keyPath: KeyPath<T, String>,
                                             placement: SearchFieldPlacement = .automatic, prompt: S) -> some View where S: StringProtocol {
        filterCollection(collection, for: text.wrappedValue, on: keyPath)
        return searchable(text: text, placement: placement, prompt: prompt)
    }

    /// Marks this view as searchable, which configures the display of a search field.
    /// You can provide a collection and a key path to be filtered using the search
    /// field string provided by the searchable component, this will result in the collection
    /// querying for all items containing the search field string for the given key path.
    ///
    ///     @State var searchString: String
    ///     @ObservedResults(Reminder.self) var reminders
    ///
    ///     List {
    ///         ForEach(reminders) { reminder in
    ///             ReminderRowView(reminder: reminder)
    ///         }
    ///     }
    ///     .searchable(text: $searchFilter,
    ///                 collection: $reminders,
    ///                 keyPath: \.name) {
    ///         ForEach(reminders) { remindersFiltered in
    ///             Text(remindersFiltered.name).searchCompletion(remindersFiltered.name)
    ///         }
    ///     }
    ///
    /**
    - Note: See ``SwiftUI/View/searchable(text:placement:prompt:suggestions)``
            <https://developer.apple.com/documentation/swiftui/form/searchable(text:placement:prompt:suggestions:)-94bdu>
            for more information on searchable view modifier.

    - parameter text: The text to display and edit in the search field.
    - parameter collection: The collection to be filtered.
    - parameter keyPath: The key path to the property which will be used to filter
                the collection.
    - parameter placement: The preferred placement of the search field within the
                containing view hierarchy.
    - parameter prompt: A `Text` representing the prompt of the search field
                which provides users with guidance on what to search for.
    - parameter suggestions: A view builder that produces content that
                populates a list of suggestions.
     */
    public func searchable<T: ObjectBase, S>(text: Binding<String>, collection: ObservedResults<T>, keyPath: KeyPath<T, String>,
                                             placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder suggestions: () -> S)
            -> some View where S: View {
        filterCollection(collection, for: text.wrappedValue, on: keyPath)
        return searchable(text: text,
                          placement: placement,
                          prompt: prompt,
                          suggestions: suggestions)
    }

    /// Marks this view as searchable, which configures the display of a search field.
    /// You can provide a collection and a key path to be filtered using the search
    /// field string provided by the searchable component, this will result in the collection
    /// querying for all items containing the search field string for the given key path.
    ///
    ///     @State var searchString: String
    ///     @ObservedResults(Reminder.self) var reminders
    ///
    ///     List {
    ///         ForEach(reminders) { reminder in
    ///             ReminderRowView(reminder: reminder)
    ///         }
    ///     }
    ///     .searchable(text: $searchFilter,
    ///                 collection: $reminders,
    ///                 keyPath: \.name) {
    ///         ForEach(reminders) { remindersFiltered in
    ///             Text(remindersFiltered.name).searchCompletion(remindersFiltered.name)
    ///         }
    ///     }
    ///
    /**
    - Note: See ``SwiftUI/View/searchable(text:placement:prompt:suggestions)``
            <https://developer.apple.com/documentation/swiftui/form/searchable(text:placement:prompt:suggestions:)-1mw1m>
            for more information on searchable view modifier.

    - parameter text: The text to display and edit in the search field.
    - parameter collection: The collection to be filtered.
    - parameter keyPath: The key path to the property which will be used to filter
                the collection.
    - parameter placement: The preferred placement of the search field within the
                containing view hierarchy.
    - parameter prompt: The key for the localized prompt of the search field
                which provides users with guidance on what to search for.
    - parameter suggestions: A view builder that produces content that
                populates a list of suggestions.
     */
    public func searchable<T: ObjectBase, S>(text: Binding<String>, collection: ObservedResults<T>, keyPath: KeyPath<T, String>,
                                             placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder suggestions: () -> S)
            -> some View where S: View {
        filterCollection(collection, for: text.wrappedValue, on: keyPath)
        return searchable(text: text,
                          placement: placement,
                          prompt: prompt,
                          suggestions: suggestions)
    }

    /// Marks this view as searchable, which configures the display of a search field.
    /// You can provide a collection and a key path to be filtered using the search
    /// field string provided by the searchable component, this will result in the collection
    /// querying for all items containing the search field string for the given key path.
    ///
    ///     @State var searchString: String
    ///     @ObservedResults(Reminder.self) var reminders
    ///
    ///     List {
    ///         ForEach(reminders) { reminder in
    ///             ReminderRowView(reminder: reminder)
    ///         }
    ///     }
    ///     .searchable(text: $searchFilter,
    ///                 collection: $reminders,
    ///                 keyPath: \.name) {
    ///         ForEach(reminders) { remindersFiltered in
    ///             Text(remindersFiltered.name).searchCompletion(remindersFiltered.name)
    ///         }
    ///     }
    ///
    /**
    - Note: See ``SwiftUI/View/searchable(text:placement:prompt:suggestions)``
            <https://developer.apple.com/documentation/swiftui/form/searchable(text:placement:prompt:suggestions:)-6h6qo>
            for more information on searchable view modifier.
     
    - parameter text: The text to display and edit in the search field.
    - parameter collection: The collection to be filtered.
    - parameter keyPath: The key path to the property which will be used to filter
                the collection.
    - parameter placement: The preferred placement of the search field within the
                containing view hierarchy.
    - parameter prompt: A string representing the prompt of the search field
                which provides users with guidance on what to search for.
    - parameter suggestions: A view builder that produces content that
                populates a list of suggestions.
     */
    public func searchable<T: ObjectBase, V, S>(text: Binding<String>, collection: ObservedResults<T>, keyPath: KeyPath<T, String>,
                                                placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder suggestions: () -> V)
    -> some View where V: View, S: StringProtocol {
        filterCollection(collection, for: text.wrappedValue, on: keyPath)
        return searchable(text: text,
                          placement: placement,
                          prompt: prompt,
                          suggestions: suggestions)
    }

    private func filterCollection<T: ObjectBase>(_ collection: ObservedResults<T>, for text: String, on keyPath: KeyPath<T, String>) {
        DispatchQueue.main.async {
            collection.searchText(text, on: keyPath)
        }
    }
}
#endif
#else
@objc(RLMSwiftUIKVO) internal final class SwiftUIKVO: NSObject {
    @objc(removeObserversFromObject:) public static func removeObservers(object: NSObject) -> Bool {
        return false
    }

    @objc(addObserversToObject:) public static func addObservers(object: NSObject) {
    }
}
#endif
