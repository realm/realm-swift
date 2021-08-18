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
    var didStartWrite = false
    if thawed.realm?.isInWriteTransaction == false {
        didStartWrite = true
        thawed.realm?.beginWrite()
    }
    block(thawed)
    if didStartWrite {
        try! thawed.realm?.commitWrite()
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private func createBinding<T: ThreadConfined, V>(_ value: T,
                                                 forKeyPath keyPath: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
    guard let value = value.isFrozen ? value.thaw() : value else {
        throwRealmException("Could not bind value")
    }

    // store last known value outside of the binding so that we can reference it if the parent
    // is invalidated
    var lastValue = value[keyPath: keyPath]
    return Binding(get: {
        guard !value.isInvalidated else {
            return lastValue
        }
        lastValue = value[keyPath: keyPath]
        if let value = lastValue as? RLMSwiftCollectionBase & ThreadConfined, !value.isInvalidated && value.realm != nil {
            return value.freeze() as! V
        }
        return lastValue
    },
    set: { newValue in
        guard !value.isInvalidated else {
            return
        }
        safeWrite(value) { value in
            value[keyPath: keyPath] = newValue
        }
    })
}

// MARK: SwiftUIKVO

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
internal final class SwiftUIKVO: NSObject {
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
            guard SwiftUIKVO.observedObjects.keys.contains(value) else {
                return
            }
            keyPaths.forEach {
                value.removeObserver(observer, forKeyPath: $0)
            }
            SwiftUIKVO.observedObjects.removeValue(forKey: value)
        }
    }
    private let receive: () -> Void

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
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

    private var subscribers = [AnySubscriber<Void, Never>]()
    private let value: ObjectType
    private let keyPaths: [String]?

    init(_ value: ObjectType, _ keyPaths: [String]? = nil) {
        self.value = value
        self.keyPaths = keyPaths
    }

    func send() {
        subscribers.forEach {
            _ = $0.receive()
        }
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subscribers.append(AnySubscriber(subscriber))
        if value.realm != nil && !value.isInvalidated, let value = value.thaw() {
            // if the value is managed
            let token =  value._observe(keyPaths, subscriber)
            subscriber.receive(subscription: ObservationSubscription(token: token))
        } else if let value = value as? ObjectBase, !value.isInvalidated {
            // else if the value is unmanaged
            let schema = ObjectSchema(RLMObjectBaseObjectSchema(value)!)
            let kvo = SwiftUIKVO(subscriber: subscriber)

            var keyPaths = [String]()
            for property in schema.properties {
                keyPaths.append(property.name)
                value.addObserver(kvo, forKeyPath: property.name, options: .initial, context: nil)
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
                objectWillChange.send()
                self.objectWillChange = ObservableStoragePublisher(newValue, self.keyPaths)
            }
        }
    }

    var objectWillChange: ObservableStoragePublisher<ObservedType>
    var keyPaths: [String]?

    init(_ value: ObservedType, _ keyPaths: [String]? = nil) {
        self.value = value.realm != nil && !value.isInvalidated ? value.thaw() ?? value : value
        self.objectWillChange = ObservableStoragePublisher(value, keyPaths)
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
}

// MARK: ObservedResults

/// A property wrapper type that retrieves results from a Realm.
///
/// The results use the realm configuration provided by
/// the environment value `EnvironmentValues/realmConfiguration`.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper public struct ObservedResults<ResultType>: DynamicProperty, BoundCollection where ResultType: Object & Identifiable {
    private class Storage: ObservableStorage<Results<ResultType>> {

        var setupHasRun = false

        private func didSet() {
            if setupHasRun {
                setupValue()
            }
        }

        func setupValue() {
            /// A base value to reset the state of the query if a user reassigns the `filter` or `sortDescriptor`
            value = try! Realm(configuration: configuration ?? Realm.Configuration.defaultConfiguration).objects(ResultType.self)

            if let sortDescriptor = sortDescriptor {
                value = value.sorted(byKeyPath: sortDescriptor.keyPath, ascending: sortDescriptor.ascending)
            }
            if let filter = filter {
                value = value.filter(filter)
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

        var configuration: Realm.Configuration? {
            didSet {
                didSet()
            }
        }
    }

    @Environment(\.realmConfiguration) var configuration
    @ObservedObject private var storage: Storage
    /// :nodoc:
    @State public var filter: NSPredicate? {
        willSet {
            storage.filter = newValue
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
        if !storage.setupHasRun {
            storage.setupValue()
        }
        return storage.configuration != nil ? storage.value.freeze() : storage.value
    }
    /// :nodoc:
    public var projectedValue: Self {
        return self
    }
    /// :nodoc:
    public init(_ type: ResultType.Type,
                configuration: Realm.Configuration? = nil,
                filter: NSPredicate? = nil,
                keyPaths: [String]? = nil,
                sortDescriptor: SortDescriptor? = nil) {
        self.storage = Storage(Results(RLMResults.emptyDetached()), keyPaths)
        self.storage.configuration = configuration
        self.filter = filter
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
        ///
        /// - Returns: A new binding.
        public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>) -> Binding<Subject> {
            createBinding(wrappedValue, forKeyPath: keyPath)
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
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: ObjectBase & ThreadConfined {
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> where V: _Persistable {
        createBinding(wrappedValue, forKeyPath: member)
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
extension Binding where Value: Object & Identifiable {
    /// :nodoc:
    public func delete() {
        safeWrite(wrappedValue) { object in
            object.realm?.delete(self.wrappedValue)
        }
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
    public func bind<V: _Persistable>(_ keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V> {
        createBinding(self.realm != nil ? self.thaw() ?? self : self, forKeyPath: keyPath)
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

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private class ObservableAsyncOpenStorage: ObservableObject {
    private var app: App
    var configuration: Realm.Configuration
    var partitionValue: AnyBSON

    var cancellables = [AnyCancellable]()

    @Published var asyncOpenState: AsyncOpenState = .connecting {
        willSet {
            objectWillChange.send()
        }
    }

    func asyncOpen() -> AnyPublisher<RealmPublishers.AsyncOpenPublisher.Output, RealmPublishers.AsyncOpenPublisher.Failure> {
        if let currentUser = app.currentUser,
           currentUser.isLoggedIn {
            return asyncOpenForUser(app.currentUser!, partitionValue: partitionValue, configuration: configuration)
        } else {
            asyncOpenState = .waitingForUser
            return app.objectWillChange
                .compactMap(\.currentUser)
                .flatMap { self.asyncOpenForUser($0, partitionValue: self.partitionValue, configuration: self.configuration) }
                .eraseToAnyPublisher()
        }
    }

    private func asyncOpenForUser(_ user: User, partitionValue: AnyBSON, configuration: Realm.Configuration) -> AnyPublisher<RealmPublishers.AsyncOpenPublisher.Output, RealmPublishers.AsyncOpenPublisher.Failure> {
        let userConfig = user.configuration(partitionValue: partitionValue, cancelAsyncOpenOnNonFatalErrors: true)
        let userSyncConfig = userConfig.syncConfiguration
        var configuration = configuration
        configuration.syncConfiguration = userSyncConfig
        return Realm.asyncOpen(configuration: configuration)
            .onProgressNotification { asyncProgress in
                let progress = Progress(totalUnitCount: Int64(asyncProgress.transferredBytes))
                progress.completedUnitCount = Int64(asyncProgress.transferredBytes)
                self.asyncOpenState = .progress(progress)
            }
            .eraseToAnyPublisher()
    }

    init(app: App, configuration: Realm.Configuration, partitionValue: AnyBSON) {
        self.app = app
        self.configuration = configuration
        self.partitionValue = partitionValue
    }

    // MARK: - AutoOpen & AsyncOpen Helper

    class func configureApp(appId: String? = nil, withTimeout timeout: UInt? = nil) -> App {
        var app: App
        let appsIds = RLMApp.appIds()
        if let appId = appId {
            app = App(id: appId)
        } else if appsIds.count == 1, // Check if there is a singular cached app
            let cachedAppId = appsIds.first as? String {
            app = App(id: cachedAppId)
        } else if appsIds.count > 1 {
            throwRealmException("Cannot AsyncOpen the Realm because more than one appId was found. When using multiple Apps you must explicitly pass an appId to indicate which to use.")
        } else {
            throwRealmException("Cannot AsyncOpen the Realm because no appId was found. You must either explicitly pass an appId or initialize an App before displaying your View.")
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

    private func asyncOpen() {
        storage.asyncOpen()
            .sink { completion in
                if case .failure(let error) = completion {
                    self.storage.asyncOpenState = .error(error)
                }
            } receiveValue: { realm in
                self.storage.asyncOpenState = .open(realm)
            }.store(in: &storage.cancellables)
    }

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
        storage.cancellables.forEach { $0.cancel() }
        storage.cancellables = []
    }

    /**
     Initialize the property wrapper
     - parameter appId: The unique identifier of your Realm app, if empty or `nil` will try to retrieve latest singular cached app.
     - parameter partitionValue: The `BSON` value the Realm is partitioned on.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm,
                 user's sync configuration for the given partition value will be set as the `syncConfiguration`,
                 if empty the configuration is set to the `defaultConfiguration`
     - parameter timeout: The maximum number of milliseconds to allow for a connection to
                 become fully established., if empty or `nil` no connection timeout is set.
     */
    public init(appId: String? = nil,
                partitionValue: Partition,
                configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration,
                timeout: UInt? = nil) {
        let app = ObservableAsyncOpenStorage.configureApp(appId: appId, withTimeout: timeout)
        // Store property wrapper values on the storage
        storage = ObservableAsyncOpenStorage(app: app, configuration: configuration, partitionValue: AnyBSON(partitionValue))
        asyncOpen()
    }

    public mutating func update() {
        if let partitionValue = partitionValue as? Partition {
            let bsonValue = AnyBSON(partitionValue)
            if storage.partitionValue != bsonValue {
                storage.partitionValue = bsonValue
                cancel()
                asyncOpen()
            }
        }

        if storage.configuration != configuration {
            storage.configuration = configuration
            if let partitionValue = configuration.syncConfiguration?.partitionValue {
                storage.partitionValue = partitionValue
            }

            cancel()
            asyncOpen()
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

    private func asyncOpen() {
        storage.asyncOpen()
            .sink { completion in
                if case .failure(let error) = completion {
                    if let error = error as NSError?,
                       error.code == Int(ETIMEDOUT) && error.domain == NSPOSIXErrorDomain,
                       let realm = try? Realm(configuration: configuration) {
                        self.storage.asyncOpenState = .open(realm)
                    } else {
                        self.storage.asyncOpenState = .error(error)
                    }
                }
            } receiveValue: { realm in
                self.storage.asyncOpenState = .open(realm)
            }.store(in: &storage.cancellables)
    }

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
        storage.cancellables.forEach { $0.cancel() }
        storage.cancellables = []
    }

    /**
     Initialize the property wrapper
     - parameter appId: The unique identifier of your Realm app,  if empty or `nil` will try to retrieve latest singular cached app.
     - parameter partitionValue: The `BSON` value the Realm is partitioned on.
     - parameter configuration: The `Realm.Configuration` used when creating the Realm,
                 user's sync configuration for the given partition value will be set as the `syncConfiguration`,
                 if empty the configuration is set to the `defaultConfiguration`.
     - parameter timeout: The maximum number of milliseconds to allow for a connection to
                 become fully established, if empty or `nil` no connection timeout is set.
     */
    public init(appId: String? = nil,
                partitionValue: Partition,
                configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration,
                timeout: UInt? = nil) {
        let app = ObservableAsyncOpenStorage.configureApp(appId: appId, withTimeout: timeout)
        // Store property wrapper values on the storage
        storage = ObservableAsyncOpenStorage(app: app, configuration: configuration, partitionValue: AnyBSON(partitionValue))
        asyncOpen()
    }

    public mutating func update() {
        if let partitionValue = partitionValue as? Partition {
            let bsonValue = AnyBSON(partitionValue)
            if storage.partitionValue != bsonValue {
                storage.partitionValue = bsonValue
                cancel()
                asyncOpen()
            }
        }

        if storage.configuration != configuration {
            if let partitionValue = configuration.syncConfiguration?.partitionValue {
                storage.partitionValue = partitionValue
            }
            storage.configuration = configuration

            cancel()
            asyncOpen()
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUIKVO {
    static func removeObservers(object: NSObject) {
        if let subscription = SwiftUIKVO.observedObjects[object] {
            subscription.cancel()
        }
    }
}
#else
internal final class SwiftUIKVO {
    static func removeObservers(object: NSObject) {
        // noop
    }
}
#endif
