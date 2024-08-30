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

import SwiftUI
import Combine
import Realm
import Realm.Private

private func write<Value>(_ value: Value, _ block: (Value) -> Void) where Value: ThreadConfined {
    let thawed = value.realm == nil ? value : value.thaw() ?? value
    if let realm = thawed.realm, !realm.isInWriteTransaction {
        try! realm.write {
            block(thawed)
        }
    } else {
        block(thawed)
    }
}

private func thawObjectIfFrozen<Value>(_ value: Value) -> Value where Value: ObjectBase & ThreadConfined {
    return value.realm == nil ? value : value.thaw() ?? value
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@MainActor
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
        write(value) { value in
            value[keyPath: keyPath] = newValue
        }
    })
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@MainActor
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
        write(value) { value in
            value[keyPath: keyPath] = newValue
        }
    })
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@MainActor
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
        write(value) { value in
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
    private static let observedObjects = AllocatedUnfairLock([NSObject: Subscription]())

    static func store(_ obj: NSObject, _ subscription: Subscription) {
        SwiftUIKVO.observedObjects.withLock {
            $0[obj] = subscription
        }
    }

    static func cancel(_ obj: NSObject) {
        SwiftUIKVO.observedObjects.withLock {
            if let subscription: Subscription = $0.removeValue(forKey: obj) {
                subscription.removeObservers()
            }
        }
    }

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
            SwiftUIKVO.cancel(value)
        }

        fileprivate func removeObservers() {
            keyPaths.forEach {
                value.removeObserver(observer, forKeyPath: $0)
            }
        }

        fileprivate func addObservers() {
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
    private var value: ObjectType
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

    // Refresh the publisher with a managed object.
    func update(value: ObjectType) {
        self.value = value
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
            SwiftUIKVO.store(value, subscription)
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private class ObservableStorage<ObservedType>: ObservableObject where ObservedType: RealmSubscribable & ThreadConfined & Equatable {
    @Published var value: ObservedType {
        willSet {
            if newValue != value {
                objectWillChange.send()
                objectWillChange.update(value: newValue)
                objectWillChange.subscribers.forEach {
                    $0.receive(subscription: ObservationSubscription(token: newValue._observe(keyPaths, $0)))
                }
            }
        }
    }

    let objectWillChange: ObservableStoragePublisher<ObservedType>
    let keyPaths: [String]?

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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private class ObservableResultsStorage<T>: ObservableStorage<T> where T: RealmSubscribable & ThreadConfined & Equatable {
    private var setupHasRun = false
    func didSet() {
        if setupHasRun {
            updateValue()
        }
    }

    func updateValue() {
        // Implemented in subclasses
        fatalError()
    }

    func setupValue() {
        guard !setupHasRun else { return }
        updateValue()
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
    var configuration: Realm.Configuration? {
        didSet {
            didSet()
        }
    }

    var searchFilter: NSPredicate? {
        didSet {
            didSet()
        }
    }

    private var searchString: String = ""
    fileprivate func searchText<U: ObjectBase>(_ text: String, on keyPath: KeyPath<U, String>) {
        guard text != searchString else { return }
        if text.isEmpty {
            searchFilter = nil
        } else {
            searchFilter = Query<U>()[dynamicMember: keyPath].contains(text).predicate
        }
        searchString = text
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
@MainActor
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
     - parameter wrappedValue The MutableSet reference to wrap and observe.
     */
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public init<Value>(wrappedValue: T) where T == MutableSet<Value> {
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
    public typealias Element = ResultType
    private class Storage: ObservableResultsStorage<Results<ResultType>> {
        override func updateValue() {
            let realm = try! Realm(configuration: configuration ?? Realm.Configuration.defaultConfiguration)
            var value = realm.objects(ResultType.self)
            if let sortDescriptor = sortDescriptor {
                value = value.sorted(byKeyPath: sortDescriptor.keyPath, ascending: sortDescriptor.ascending)
            }

            let filters = [searchFilter, filter].compactMap { $0 }
            if !filters.isEmpty {
                let compoundFilter = NSCompoundPredicate(andPredicateWithSubpredicates: filters)
                value = value.filter(compoundFilter)
            }
            self.value = value
        }
    }

    @Environment(\.realmConfiguration) var configuration
    @ObservedObject private var storage: Storage
    fileprivate func searchText<T: ObjectBase>(_ text: String, on keyPath: KeyPath<T, String>) {
        storage.searchText(text, on: keyPath)
    }

    /// Stores an NSPredicate used for filtering the Results. This is mutually exclusive
    /// to the `where` parameter.
    @State public var filter: NSPredicate? {
        willSet {
            storage.filter = newValue
        }
    }
    /// Stores a type safe query used for filtering the Results. This is mutually exclusive
    /// to the `filter` parameter.
    @State public var `where`: ((Query<ResultType>) -> Query<Bool>)? {
        willSet {
            storage.filter = newValue?(Query()).predicate
        }
    }
    /// :nodoc:
    @State public var sortDescriptor: SortDescriptor? {
        willSet {
            storage.sortDescriptor = newValue
        }
    }
    /// :nodoc:
    public var wrappedValue: Results<ResultType> {
        storage.setupValue()
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
    /// :nodoc:
    public init(_ type: ResultType.Type,
                keyPaths: [String]? = nil,
                configuration: Realm.Configuration? = nil,
                sortDescriptor: SortDescriptor? = nil) where ResultType: Object {
        self.storage = Storage(Results(RLMResults<ResultType>.emptyDetached()), keyPaths)
        self.storage.configuration = configuration
        self.sortDescriptor = sortDescriptor
    }

    nonisolated public func update() {
        MainActor.assumeIsolated {
            // When the view updates, it will inject the @Environment
            // into the propertyWrapper
            if storage.configuration == nil {
                storage.configuration = configuration
            }
        }
    }
}

/// A property wrapper type that represents a sectioned results collection.
///
/// The sectioned results use the realm configuration provided by
/// the environment value `EnvironmentValues/realmConfiguration`
/// if `configuration` is not set in the initializer.
///
///
/// Given `@ObservedSectionedResults var v` in SwiftUI, `$v` refers to a `BoundCollection`.
///
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper public struct ObservedSectionedResults<Key: _Persistable & Hashable, ResultType>: DynamicProperty, BoundCollection where ResultType: _ObservedResultsValue & RealmFetchable & KeypathSortable & Identifiable {
    public typealias Element = ResultType

    private class Storage: ObservableResultsStorage<Results<ResultType>> {
        var sectionedResults: SectionedResults<Key, ResultType>!
        var token: AnyCancellable?

        override func updateValue() {
            let realm = try! Realm(configuration: configuration ?? Realm.Configuration.defaultConfiguration)
            var results = realm.objects(ResultType.self)

            let filters = [searchFilter, filter].compactMap { $0 }
            if !filters.isEmpty {
                let compoundFilter = NSCompoundPredicate(andPredicateWithSubpredicates: filters)
                results = results.filter(compoundFilter)
            }

            if let keyPathString = keyPathString, sortDescriptors.isEmpty {
                sortDescriptors.append(.init(keyPath: keyPathString, ascending: true))
            }

            value = results

            /*
             Observing the sectioned results directly doesn't allow the SwiftUI diff to work
             correctly as the previous state of the sectioned results will have the new values.

             An example of when this is an issue is when an item is deleted in a List containing sectioned results,
             the diff needs a stable state of the previous transaction but due to
             the observation callback calling calculate_sections the collection will be brought up to date.

             The solution around this is to store a frozen copy of the sectioned results and observe the parent `Results` instead.
             Each time the results observation callback is invoked and the SwiftUI View is redrawn the sectioned results will be updated.
             */
            sectionedResults = value.sectioned(sortDescriptors: sortDescriptors, sectionBlock).freeze()
            token = self.objectWillChange.sink { [weak self] _ in
                guard let self = self else { return }
                self.sectionedResults = self.value.sectioned(sortDescriptors: self.sortDescriptors, self.sectionBlock).freeze()
            }
        }

        var sortDescriptors: [SortDescriptor] = [] {
            didSet {
                didSet()
            }
        }
        var sectionBlock: ((ResultType) -> Key)
        var keyPathString: String?

        init(_ value: Results<ResultType>,
             sectionBlock: @escaping ((ResultType) -> Key),
             sortDescriptors: [SortDescriptor],
             keyPathString: String? = nil,
             keyPaths: [String]? = nil) {
            self.sectionBlock = sectionBlock
            self.sortDescriptors = sortDescriptors
            if let keyPathString = keyPathString {
                self.keyPathString = keyPathString
                self.sortDescriptors.append(.init(keyPath: keyPathString, ascending: true))
            }
            if self.sortDescriptors.isEmpty {
                throwRealmException("sortDescriptors must not be empty when sectioning ObservedSectionedResults with `sectionBlock`")
            }
            super.init(value, keyPaths)
        }
    }

    @Environment(\.realmConfiguration) var configuration
    @ObservedObject private var storage: Storage
    /// :nodoc:
    fileprivate func searchText<T: ObjectBase>(_ text: String, on keyPath: KeyPath<T, String>) {
        storage.searchText(text, on: keyPath)
    }
    /// Stores an NSPredicate used for filtering the SectionedResults. This is mutually exclusive
    /// to the `where` parameter.
    @State public var filter: NSPredicate? {
        willSet {
            storage.filter = newValue
        }
    }
    /// Stores a type safe query used for filtering the SectionedResults. This is mutually exclusive
    /// to the `filter` parameter.
    @State public var `where`: ((Query<ResultType>) -> Query<Bool>)? {
        willSet {
            storage.filter = newValue?(Query()).predicate
        }
    }
    /// :nodoc:
    @State public var sortDescriptors: [SortDescriptor] = [] {
        willSet {
            storage.sortDescriptors = newValue
        }
    }
    /// :nodoc:
    public var wrappedValue: SectionedResults<Key, ResultType> {
        storage.setupValue()
        return storage.sectionedResults
    }
    /// :nodoc:
    public var projectedValue: Self {
        return self
    }

    /// Removes items from an `@ObservedSectionedResults` collection
    /// with a given `IndexSet` and `ResultsSection`.
    /// - Parameters:
    ///   - offsets: Index offsets in the section.
    ///   - section: The section containing the items to remove.
    public func remove(atOffsets offsets: IndexSet,
                       section: ResultsSection<Key, ResultType>) where ResultType: ObjectBase & ThreadConfined {
        write(wrappedValue) { collection in
            collection.realm?.delete(offsets.compactMap { section[$0].thaw() ?? nil })
        }
    }

    private init(type: ResultType.Type,
                 sectionBlock: @escaping ((ResultType) -> Key),
                 sortDescriptors: [SortDescriptor] = [],
                 filter: NSPredicate? = nil,
                 where: ((Query<ResultType>) -> Query<Bool>)? = nil,
                 keyPaths: [String]? = nil,
                 keyPathString: String? = nil,
                 configuration: Realm.Configuration? = nil) where ResultType: AnyObject {
        let results = Results<ResultType>(RLMResults<ResultType>.emptyDetached())
        self.storage = Storage(results,
                               sectionBlock: sectionBlock,
                               sortDescriptors: sortDescriptors,
                               keyPathString: keyPathString,
                               keyPaths: keyPaths)
        self.storage.configuration = configuration
        if let filter = filter {
            self.filter = filter
        } else if let `where` = `where` {
            self.where = `where`
        }
        self.sortDescriptors = sortDescriptors
    }

    /**
     Initialize a `ObservedSectionedResults` struct for a given `Projection` type.
     - parameter type: Observed type
     - parameter sectionKeyPath: The keyPath that will produce the key for each section.
     For every unique value retrieved from the keyPath a section key will be generated.
     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     - parameter filter: Observations will be made only for passing objects.
     If no filter given - all objects will be observed
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm.
     If empty the configuration is set to the `defaultConfiguration`

     - note: The primary sort descriptor must be responsible for determining the section key.
     */
    public init<ObjectType: ObjectBase>(_ type: ResultType.Type,
                                        sectionKeyPath: KeyPath<ResultType, Key>,
                                        sortDescriptors: [SortDescriptor] = [],
                                        filter: NSPredicate? = nil,
                                        keyPaths: [String]? = nil,
                                        configuration: Realm.Configuration? = nil) where ResultType: Projection<ObjectType>, ObjectType: ThreadConfined {
        self.init(type: type,
                  sectionBlock: { (obj: ResultType) in obj[keyPath: sectionKeyPath] },
                  sortDescriptors: sortDescriptors,
                  filter: filter,
                  keyPaths: keyPaths,
                  keyPathString: _name(for: sectionKeyPath),
                  configuration: configuration)
    }

    /**
     Initialize a `ObservedSectionedResults` struct for a given `Projection` type.
     - parameter type: Observed type
     - parameter sectionBlock: A callback which returns the section key for each object in the collection.
     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     - parameter filter: Observations will be made only for passing objects.
     If no filter given - all objects will be observed
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm.
     If empty the configuration is set to the `defaultConfiguration`

     - note: The primary sort descriptor must be responsible for determining the section key.
     */
    public init<ObjectType: ObjectBase>(_ type: ResultType.Type,
                                        sectionBlock: @escaping ((ResultType) -> Key),
                                        sortDescriptors: [SortDescriptor] = [],
                                        filter: NSPredicate? = nil,
                                        keyPaths: [String]? = nil,
                                        configuration: Realm.Configuration? = nil) where ResultType: Projection<ObjectType>, ObjectType: ThreadConfined {
        self.init(type: type,
                  sectionBlock: sectionBlock,
                  sortDescriptors: sortDescriptors,
                  filter: filter,
                  keyPaths: keyPaths,
                  configuration: configuration)
    }

    /**
     Initialize a `ObservedSectionedResults` struct for a given `Object` or `EmbeddedObject` type.
     - parameter type: Observed type
     - parameter sectionKeyPath: The keyPath that will produce the key for each section.
     For every unique value retrieved from the keyPath a section key will be generated.
     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     - parameter filter: Observations will be made only for passing objects.
     If no filter given - all objects will be observed
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm.
     If empty the configuration is set to the `defaultConfiguration`

     - note: The primary sort descriptor must be responsible for determining the section key.
     */
    public init(_ type: ResultType.Type,
                sectionKeyPath: KeyPath<ResultType, Key>,
                sortDescriptors: [SortDescriptor] = [],
                filter: NSPredicate? = nil,
                keyPaths: [String]? = nil,
                configuration: Realm.Configuration? = nil) where ResultType: Object {
        self.init(type: type,
                  sectionBlock: { (obj: ResultType) in obj[keyPath: sectionKeyPath] },
                  sortDescriptors: sortDescriptors,
                  filter: filter,
                  keyPaths: keyPaths,
                  keyPathString: _name(for: sectionKeyPath),
                  configuration: configuration)
    }

    /**
     Initialize a `ObservedSectionedResults` struct for a given `Object` or `EmbeddedObject` type.
     - parameter type: Observed type
     - parameter sectionBlock: A callback which returns the section key for each object in the collection.
     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     - parameter filter: Observations will be made only for passing objects.
     If no filter given - all objects will be observed
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm.
     If empty the configuration is set to the `defaultConfiguration`

     - note: The primary sort descriptor must be responsible for determining the section key.
     */
    public init(_ type: ResultType.Type,
                sectionBlock: @escaping ((ResultType) -> Key),
                sortDescriptors: [SortDescriptor] = [],
                filter: NSPredicate? = nil,
                keyPaths: [String]? = nil,
                configuration: Realm.Configuration? = nil) where ResultType: Object {
        self.init(type: type,
                  sectionBlock: sectionBlock,
                  sortDescriptors: sortDescriptors,
                  filter: filter,
                  keyPaths: keyPaths,
                  configuration: configuration)
    }

    /**
     Initialize a `ObservedSectionedResults` struct for a given `Object` or `EmbeddedObject` type.
     - parameter type: Observed type
     - parameter sectionBlock: A callback which returns the section key for each object in the collection.
     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     - parameter where: Observations will be made only for passing objects.
     If no type safe query is given - all objects will be observed.
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm.
     If empty the configuration is set to the `defaultConfiguration`

     - note: The primary sort descriptor must be responsible for determining the section key.
     */
    public init(_ type: ResultType.Type,
                sectionBlock: @escaping ((ResultType) -> Key),
                sortDescriptors: [SortDescriptor] = [],
                where: ((Query<ResultType>) -> Query<Bool>)? = nil,
                keyPaths: [String]? = nil,
                configuration: Realm.Configuration? = nil) where ResultType: Object {
        self.init(type: type,
                  sectionBlock: sectionBlock,
                  sortDescriptors: sortDescriptors,
                  where: `where`,
                  keyPaths: keyPaths,
                  configuration: configuration)
    }

    /**
     Initialize a `ObservedSectionedResults` struct for a given `Object` or `EmbeddedObject` type.
     - parameter type: Observed type
     - parameter sectionKeyPath: The keyPath that will produce the key for each section.
     For every unique value retrieved from the keyPath a section key will be generated.
     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     - parameter where: Observations will be made only for passing objects.
     If no type safe query is given - all objects will be observed.
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm.
     If empty the configuration is set to the `defaultConfiguration`

     - note: The primary sort descriptor must be responsible for determining the section key.
     */
    public init(_ type: ResultType.Type,
                sectionKeyPath: KeyPath<ResultType, Key>,
                sortDescriptors: [SortDescriptor] = [],
                where: ((Query<ResultType>) -> Query<Bool>)? = nil,
                keyPaths: [String]? = nil,
                configuration: Realm.Configuration? = nil) where ResultType: Object {
        self.init(type: type,
                  sectionBlock: { (obj: ResultType) in obj[keyPath: sectionKeyPath] },
                  sortDescriptors: sortDescriptors,
                  where: `where`,
                  keyPaths: keyPaths,
                  keyPathString: _name(for: sectionKeyPath),
                  configuration: configuration)
    }

    /**
     Initialize a `ObservedSectionedResults` struct for a given `Object` or `EmbeddedObject` type.
     - parameter type: Observed type
     - parameter sectionKeyPath: The keyPath that will produce the key for each section.
     For every unique value retrieved from the keyPath a section key will be generated.
     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm.
     If empty the configuration is set to the `defaultConfiguration`

     - note: The primary sort descriptor must be responsible for determining the section key.
     */
    public init(_ type: ResultType.Type,
                sectionKeyPath: KeyPath<ResultType, Key>,
                sortDescriptors: [SortDescriptor] = [],
                keyPaths: [String]? = nil,
                configuration: Realm.Configuration? = nil) where ResultType: Object {
        self.init(type: type,
                  sectionBlock: { (obj: ResultType) in obj[keyPath: sectionKeyPath] },
                  sortDescriptors: sortDescriptors,
                  keyPaths: keyPaths,
                  keyPathString: _name(for: sectionKeyPath),
                  configuration: configuration)
    }

    /**
     Initialize a `ObservedSectionedResults` struct for a given `Object` or `EmbeddedObject` type.
     - parameter type: Observed type
     - parameter sectionBlock: A callback which returns the section key for each object in the collection.
     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     - parameter keyPaths: Only properties contained in the key paths array will be observed.
     If `nil`, notifications will be delivered for any property change on the object.
     String key paths which do not correspond to a valid a property will throw an exception.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm.
     If empty the configuration is set to the `defaultConfiguration`

     - note: The primary sort descriptor must be responsible for determining the section key.
     */
    public init(_ type: ResultType.Type,
                sectionBlock: @escaping ((ResultType) -> Key),
                sortDescriptors: [SortDescriptor],
                keyPaths: [String]? = nil,
                configuration: Realm.Configuration? = nil) where ResultType: Object {
        self.init(type: type,
                  sectionBlock: sectionBlock,
                  sortDescriptors: sortDescriptors,
                  keyPaths: keyPaths,
                  configuration: configuration)
    }

    nonisolated public func update() {
        MainActor.assumeIsolated {
            // When the view updates, it will inject the @Environment
            // into the propertyWrapper
            if storage.configuration == nil {
                storage.configuration = configuration
            }
        }
    }
}


// MARK: ObservedRealmObject

/// A property wrapper type that subscribes to an observable Realm `Object` or `List` and
/// invalidates a view whenever the observable object changes.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@MainActor
@propertyWrapper public struct ObservedRealmObject<ObjectType>: DynamicProperty
where ObjectType: RealmSubscribable & ThreadConfined & ObservableObject & Equatable {
    /// A wrapper of the underlying observable object that can create bindings to
    /// its properties using dynamic member lookup.
    @MainActor
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
    @MainActor
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> where V: _Persistable {
        createBinding(wrappedValue, forKeyPath: member)
    }
    /// :nodoc:
    @MainActor
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> where V: _Persistable & RLMSwiftCollectionBase & ThreadConfined {
        createCollectionBinding(wrappedValue, forKeyPath: member)
    }
    /// :nodoc:
    @MainActor
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> where V: _Persistable & Equatable {
        createEquatableBinding(wrappedValue, forKeyPath: member)
    }
}

// MARK: - BoundCollection

/// :nodoc:
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@preconcurrency @MainActor
public protocol BoundCollection {
    /// :nodoc:
    associatedtype Value
    /// :nodoc:
    associatedtype Element: RealmCollectionValue

    /// :nodoc:
    var wrappedValue: Value { get }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension BoundCollection {
    private func write(_ block: (Value) -> Void) where Value: ThreadConfined {
        RealmSwift.write(wrappedValue, block)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundCollection where Value: RealmCollection {
    /// :nodoc:
    typealias Element = Value.Element
    /// :nodoc:
    typealias Index = Value.Index
    /// :nodoc:
    typealias Indices = Value.Indices
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundCollection where Value == List<Element> {
    /// :nodoc:
    func remove(at index: Index) {
        write { list in
            list.remove(at: index)
        }
    }

    /// :nodoc:
    func remove(atOffsets offsets: IndexSet) {
        write { list in
            list.remove(atOffsets: offsets)
        }
    }

    /// :nodoc:
    func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        write { list in
            list.move(fromOffsets: offsets, toOffset: destination)
        }
    }

    /// :nodoc:
    func append(_ value: Value.Element) {
        write { list in
            list.append(value)
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundCollection where Value == List<Element>, Element: ObjectBase & ThreadConfined {
    /// :nodoc:
    func append(_ value: Value.Element) {
        write { list in
            if value.realm == nil && list.realm != nil {
                SwiftUIKVO.cancel(value)
            }
            list.append(thawObjectIfFrozen(value))
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundCollection where Value == Results<Element>, Element: ObjectBase & ThreadConfined {
    /// :nodoc:
    func remove(_ object: Value.Element) {
        guard let thawed = object.thaw() else { return }
        write { results in
            if results.index(of: thawed) != nil {
                results.realm?.delete(thawed)
            }
        }
    }
    /// :nodoc:
    func remove(atOffsets offsets: IndexSet) {
        write { results in
            results.realm?.delete(Array(offsets.map { results[$0] }))
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundCollection where Value == MutableSet<Element> {
    /// :nodoc:
    func remove(_ element: Value.Element) {
        write { mutableSet in
            mutableSet.remove(element)
        }
    }
    /// :nodoc:
    func insert(_ value: Value.Element) {
        write { mutableSet in
            mutableSet.insert(value)
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundCollection where Value == MutableSet<Element>, Element: ObjectBase & ThreadConfined {
    /// :nodoc:
    func remove(_ object: Value.Element) {
        write { mutableSet in
            mutableSet.remove(thawObjectIfFrozen(object))
        }
    }
    /// :nodoc:
    func insert(_ value: Value.Element) {
        write { mutableSet in
            if value.realm == nil && mutableSet.realm != nil {
                SwiftUIKVO.cancel(value)
            }
            mutableSet.insert(thawObjectIfFrozen(value))
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundCollection where Value == Results<Element>, Element: Object {
    /// :nodoc:
    func append(_ value: Value.Element) {
        write { results in
            if value.realm == nil && results.realm != nil {
                SwiftUIKVO.cancel(value)
            }
            results.realm?.add(thawObjectIfFrozen(value))
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundCollection where Value == Results<Element>, Element: ProjectionObservable & ThreadConfined, Element.Root: Object {
    /// :nodoc:
    func append(_ value: Value.Element) {
        write { results in
            if value.realm == nil && results.realm != nil {
                SwiftUIKVO.cancel(value.rootObject)
            }
            results.realm?.add(thawObjectIfFrozen(value.rootObject))
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Binding: BoundCollection where Value: RealmCollection {
    /// :nodoc:
    public typealias Element = Value.Element
    /// :nodoc:
    public typealias Index = Value.Index
    /// :nodoc:
    public typealias Indices = Value.Indices
}

// MARK: - BoundMap

/// :nodoc:
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol BoundMap {
    /// :nodoc:
    associatedtype Value: RealmKeyedCollection

    /// :nodoc:
    var wrappedValue: Value { get }
}

/// :nodoc:
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundMap {
    // The compiler will not allow us to assign values by subscript as the binding is a get-only
    // property. To get around this we need an explicit `set` method.
    /// :nodoc:
    subscript( key: Value.Key) -> Value.Value? {
        self.wrappedValue[key]
    }

    /// :nodoc:
    func set(object: Value.Value?, for key: Value.Key) {
        write(self.wrappedValue) { map in
            var m = map
            m[key] = object
        }
    }
}

/// :nodoc:
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BoundMap where Value.Value: ObjectBase & ThreadConfined {
    /// :nodoc:
    func set(object: Value.Value?, for key: Value.Key) {
        // If the value is `nil` remove it from the map.
        guard let value = object else {
            write(self.wrappedValue) { map in
                map.removeObject(for: key)
            }
            return
        }
        // if the value is unmanaged but the map is managed, we are adding this value to the realm
        if value.realm == nil && self.wrappedValue.realm != nil {
            SwiftUIKVO.cancel(value)
        }
        write(self.wrappedValue) { map in
            var m = map
            m[key] = thawObjectIfFrozen(value)
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
        write(wrappedValue) { object in
            object.realm?.delete(thawObjectIfFrozen(self.wrappedValue))
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Binding where Value: ProjectionObservable, Value.Root: ThreadConfined {
    /// :nodoc:
    public func delete() {
        write(wrappedValue.rootObject) { object in
            object.realm?.delete(thawObjectIfFrozen(object))
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
    @MainActor
    public func bind<V: _Persistable & Equatable>(_ keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V> {
        createEquatableBinding(self, forKeyPath: keyPath)
    }
    /// :nodoc:
    @MainActor
    public func bind<V: _Persistable & RLMSwiftCollectionBase & ThreadConfined>(_ keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V> {
        createCollectionBinding(self, forKeyPath: keyPath)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ObservedRealmObject.Wrapper where ObjectType: ObjectBase {
    /// :nodoc:
    public func delete() {
        write(wrappedValue) { object in
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
    @MainActor
    public func bind<V: _Persistable & Equatable>(_ keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V> {
        createEquatableBinding(self, forKeyPath: keyPath)
    }
    /// :nodoc:
    @MainActor
    public func bind<V: _Persistable & RLMSwiftCollectionBase & ThreadConfined>(_ keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V> {
        createCollectionBinding(self, forKeyPath: keyPath)
    }
}

private struct RealmEnvironmentKey: EnvironmentKey {
    static let defaultValue = Realm.Configuration.defaultConfiguration
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
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUIKVO {
    @objc(removeObserversFromObject:) static func removeObservers(object: NSObject) -> Bool {
        Self.observedObjects.withLock {
            if let subscription = $0[object] {
                subscription.removeObservers()
                return true
            }
            return false
        }
    }

    @objc(addObserversToObject:) static func addObservers(object: NSObject) {
        Self.observedObjects.withLock {
            $0[object]?.addObservers()
        }
    }
}

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
        MainActor.assumeIsolated {
            collection.searchText(text, on: keyPath)
        }
    }

    /// Marks this view as searchable, which configures the display of a search field.
    /// You can provide a collection and a key path to be filtered using the search
    /// field string provided by the searchable component, this will result in the collection
    /// querying for all items containing the search field string for the given key path.
    ///
    ///     @State var searchString: String
    ///     @ObservedSectionedResults(Reminder.self) var reminders
    ///
    ///     List {
    ///         ForEach(reminders) { reminderSection in
    ///             Section(reminderSection.key) {
    ///                 ForEach(reminderSection) { object in
    ///                     ReminderRowView(reminder: object)
    ///                 }
    ///             }
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
    public func searchable<Key, T: ObjectBase>(text: Binding<String>, collection: ObservedSectionedResults<Key, T>, keyPath: KeyPath<T, String>,
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
    ///         ForEach(reminders) { reminderSection in
    ///             Section(reminderSection.key) {
    ///                 ForEach(reminderSection) { object in
    ///                     ReminderRowView(reminder: object)
    ///                 }
    ///             }
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
    public func searchable<Key, T: ObjectBase>(text: Binding<String>, collection: ObservedSectionedResults<Key, T>,
                                               keyPath: KeyPath<T, String>, placement: SearchFieldPlacement = .automatic,
                                               prompt: LocalizedStringKey) -> some View {
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
    ///         ForEach(reminders) { reminderSection in
    ///             Section(reminderSection.key) {
    ///                 ForEach(reminderSection) { object in
    ///                     ReminderRowView(reminder: object)
    ///                 }
    ///             }
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
    public func searchable<Key, T: ObjectBase, S>(text: Binding<String>, collection: ObservedSectionedResults<Key, T>, keyPath: KeyPath<T, String>,
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
    ///         ForEach(reminders) { reminderSection in
    ///             Section(reminderSection.key) {
    ///                 ForEach(reminderSection) { object in
    ///                     ReminderRowView(reminder: object)
    ///                 }
    ///             }
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
    public func searchable<Key, T: ObjectBase, S>(text: Binding<String>, collection: ObservedSectionedResults<Key, T>, keyPath: KeyPath<T, String>,
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
    ///         ForEach(reminders) { reminderSection in
    ///             Section(reminderSection.key) {
    ///                 ForEach(reminderSection) { object in
    ///                     ReminderRowView(reminder: object)
    ///                 }
    ///             }
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
    public func searchable<Key, T: ObjectBase, S>(text: Binding<String>, collection: ObservedSectionedResults<Key, T>, keyPath: KeyPath<T, String>,
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
    ///         ForEach(reminders) { reminderSection in
    ///             Section(reminderSection.key) {
    ///                 ForEach(reminderSection) { object in
    ///                     ReminderRowView(reminder: object)
    ///                 }
    ///             }
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
    public func searchable<Key, T: ObjectBase, V, S>(text: Binding<String>, collection: ObservedSectionedResults<Key, T>, keyPath: KeyPath<T, String>,
                                                     placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder suggestions: () -> V)
    -> some View where V: View, S: StringProtocol {
        filterCollection(collection, for: text.wrappedValue, on: keyPath)
        return searchable(text: text,
                          placement: placement,
                          prompt: prompt,
                          suggestions: suggestions)
    }

    private func filterCollection<Key, T: ObjectBase>(_ collection: ObservedSectionedResults<Key, T>, for text: String, on keyPath: KeyPath<T, String>) {
        MainActor.assumeIsolated {
            collection.searchText(text, on: keyPath)
        }
    }
}
