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

#if canImport(SwiftUI)
import SwiftUI
import Combine
import Realm
import Realm.Private
import Foundation

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private func createBinding<T: ThreadConfined, V>(_ value: T,
                                                 forKeyPath keyPath: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
    if value.isFrozen {
        throwRealmException("Should not bind frozen value")
    }
    // store last known value outside of the binding so that we can reference it if the parent
    // is invalidated
    let lastValue = value[keyPath: keyPath]
    return Binding(get: {
        guard !value.isInvalidated else {
            return lastValue
        }
        let value = value[keyPath: keyPath]
        if let value = value as? ListBase & ThreadConfined, !value.isInvalidated && value.realm != nil {
            return value.freeze() as! V
        }
        return value
    },
    set: { newValue in
        guard !value.isInvalidated else {
            return
        }
        value.realm?.beginWrite()
        value[keyPath: keyPath] = newValue
        try! value.realm?.commitWrite()
    })
}

private final class OptionalNotificationToken: NotificationToken {
    override func invalidate() {
    }
}

// MARK: Optional Conformances

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Optional: RealmSubscribable where Wrapped: RealmSubscribable & ThreadConfined {
    struct WrappedSubscriber: Subscriber {
        typealias Input = Wrapped

        typealias Failure = Error

        var combineIdentifier: CombineIdentifier {
            subscriber.combineIdentifier
        }

        var subscriber: AnySubscriber<Optional<Wrapped>, Error>

        func receive(subscription: Subscription) {
            subscriber.receive(subscription: subscription)
        }

        func receive(_ input: Wrapped) -> Subscribers.Demand {
            subscriber.receive(input)
        }

        func receive(completion: Subscribers.Completion<Error>) {
            subscriber.receive(completion: completion)
        }
    }
    public func _observe<S>(on queue: DispatchQueue?,
                            _ subscriber: S) -> NotificationToken where Self == S.Input, S: Subscriber, S.Failure == Error {
        return self?._observe(on: queue, WrappedSubscriber(subscriber: AnySubscriber(subscriber))) ?? OptionalNotificationToken()
    }
    public func _observe<S>(_ subscriber: S) -> NotificationToken where S: Subscriber, S.Failure == Never, S.Input == Void {
        if self?.realm != nil {
            return self?._observe(subscriber) ?? OptionalNotificationToken()
        } else {
            return OptionalNotificationToken()
        }
    }
}

extension Optional: ThreadConfined where Wrapped: ThreadConfined {
    public var realm: Realm? {
        return self?.realm
    }

    public var isInvalidated: Bool {
        return self.map { $0.isInvalidated } ?? true
    }

    public var isFrozen: Bool {
        return self.map { $0.isFrozen } ?? false
    }

    public func freeze() -> Optional<Wrapped> {
        return self?.freeze()
    }

    public func thaw() -> Optional<Wrapped>? {
        return self?.thaw()
    }
}

// MARK: KVO

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private final class KVO: NSObject {
    /// Objects must have observers removed before being added to a realm.
    /// They are stored here so that if they are appended through the Bound Property
    /// system, they can be de-observed before hand.
    fileprivate static var observedObjects = [NSObject: KVO.Subscription]()

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    fileprivate struct Subscription: Combine.Subscription {
        let observer: NSObject
        let value: NSObject
        let keyPaths: [String]

        var combineIdentifier: CombineIdentifier {
            CombineIdentifier(value)
        }

        func request(_ demand: Subscribers.Demand) {
        }

        func cancel() {
            keyPaths.forEach {
                value.removeObserver(observer, forKeyPath: $0)
            }
        }
    }
    private let _receive: () -> Void

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        _receive()
    }

    init<S>(subscriber: S) where S: Subscriber, S.Input == Void {
        _receive = { _ = subscriber.receive() }
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

    init(_ value: ObjectType) {
        self.value = value
    }

    func send() {
        subscribers.forEach {
            _ = $0.receive()
        }
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subscribers.append(AnySubscriber(subscriber))
        if value.realm != nil, let value = value.thaw() {
            // if the value is managed
            let token =  value._observe(subscriber)
            subscriber.receive(subscription: ObservationSubscription(token: token))
        } else if let value = value as? ObjectBase, !value.isInvalidated {
            // else if the value is unmanaged
            var outCount = UInt32(0)
            let propertyList = class_copyPropertyList(ObjectType.self as? AnyClass, &outCount)
            let kvo = KVO(subscriber: subscriber)
            var keyPaths = [String]()
            for index in 0..<outCount {
                let property = class_getProperty(ObjectType.self as? AnyClass,
                                                 property_getName(propertyList!.advanced(by: Int(index)).pointee))
                let name = String(cString: property_getName(property!))
                keyPaths.append(name)
                value.addObserver(kvo, forKeyPath: name, options: .new, context: nil)
            }
            let subscription = KVO.Subscription(observer: kvo, value: value, keyPaths: keyPaths)
            subscriber.receive(subscription: subscription)
            KVO.observedObjects[value] = subscription
            free(propertyList)
        } else {
            // else the value is nil
            subscriber.receive(subscription: ObservationSubscription(token: OptionalNotificationToken()))
        }
    }
}
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private class ObservableStorage<ObservedType>: ObservableObject where ObservedType: RealmSubscribable & ThreadConfined & Equatable {
    @Published var value: ObservedType {
        willSet {
            if newValue != value {
                objectWillChange.send()
                self.objectWillChange = ObservableStoragePublisher(newValue)
            }
        }
    }

    var objectWillChange: ObservableStoragePublisher<ObservedType>

    init(_ value: ObservedType) {
        self.value = value.realm != nil && !value.isInvalidated ? value.thaw() ?? value : value
        self.objectWillChange = ObservableStoragePublisher(value)
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
@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper public struct StateRealmObject<T: RealmSubscribable & ThreadConfined & Equatable>: DynamicProperty {
    @StateObject private var storage: ObservableStorage<T>
    private let defaultValue: T

    /// :nodoc:
    public var wrappedValue: T {
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
        nonmutating set {
            storage.value = newValue
        }
    }
    /// :nodoc:
    public var projectedValue: Binding<T> {
        Binding(get: {
            if storage.value.isInvalidated {
                return defaultValue
            }
            return storage.value
        }, set: { newValue in
            storage.value = newValue
        })
    }
    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The List reference to wrap and observe.
     */
    public init<Value>(wrappedValue: T) where T == List<Value> {
        self._storage = StateObject(wrappedValue: ObservableStorage(wrappedValue))
        defaultValue = T()
    }
    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The ObjectBase reference to wrap and observe.
     */
    public init(wrappedValue: T) where T: ObjectKeyIdentifiable {
        self._storage = StateObject(wrappedValue: ObservableStorage(wrappedValue))
        defaultValue = T()
    }
    /**
     Initialize a StateRealmObject wrapper for a given optional value.
     - parameter wrappedValue The optional value to wrap.
     */
    public init<Wrapped>(wrappedValue: T) where T == Optional<List<Wrapped>> {
        self._storage = StateObject(wrappedValue: ObservableStorage(wrappedValue))
        self.defaultValue = nil
    }
    /**
     Initialize a StateRealmObject wrapper for a given optional value.
     - parameter wrappedValue The optional value to wrap.
     */
    public init<Wrapped>(wrappedValue: T) where T == Optional<Wrapped>, Wrapped: ObjectKeyIdentifiable {
        self._storage = StateObject(wrappedValue: ObservableStorage(wrappedValue))
        self.defaultValue = nil
    }
    /// :nodoc:
    public init<Wrapped>() where T == Optional<Wrapped>, Wrapped: ObjectKeyIdentifiable {
        self._storage = StateObject(wrappedValue: ObservableStorage(nil))
        self.defaultValue = nil
    }
}

// MARK: FetchRealmResults


/// A property wrapper type that retrieves results from a Realm.
///
/// The results use the realm configuration provided by
/// the environment value `EnvironmentValues/realmConfiguration`.
@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper public struct FetchRealmResults<ResultType>: DynamicProperty, BoundCollection where ResultType: Object & ObjectKeyIdentifiable {
    public typealias Value = Results<ResultType>

    private class Storage: ObservableStorage<Results<ResultType>> {
        var sortDescriptor: SortDescriptor? {
            willSet {
                if let sortDescriptor = newValue {
                    value = baseValue.sorted(byKeyPath: sortDescriptor.keyPath, ascending: sortDescriptor.ascending)
                    if let filter = filter {
                        value = value.filter(filter)
                    }
                } else {
                    value = baseValue.sorted(by: [])
                    if let filter = filter {
                        value = value.filter(filter)
                    }
                }
            }
        }
        var filter: NSPredicate? {
            willSet {
                if let filter = newValue {
                    value = baseValue.filter(filter)
                    if let sortDescriptor = sortDescriptor {
                        value = value.sorted(byKeyPath: sortDescriptor.keyPath, ascending: sortDescriptor.ascending)
                    }
                } else {
                    value = baseValue.filter(NSPredicate(format: "TRUEPREDICATE"))
                    if let sortDescriptor = sortDescriptor {
                        value = value.sorted(byKeyPath: sortDescriptor.keyPath, ascending: sortDescriptor.ascending)
                    }
                }
            }
        }

        /// A base value to reset the state of the query if a user reassigns the `filter` or `sortDescriptor`
        private var baseValue: Results<ResultType> {
            if let configuration = configuration {
                return try! Realm(configuration: configuration).objects(ResultType.self)
            } else {
                return Results(RLMResults.emptyDetached())
            }
        }

        var configuration: Realm.Configuration? {
            didSet {
                var value = try! Realm(configuration: configuration!).objects(ResultType.self)
                if let sortDescriptor = sortDescriptor {
                    value = value.sorted(byKeyPath: sortDescriptor.keyPath, ascending: sortDescriptor.ascending)
                }
                if let filter = filter {
                    value = value.filter(filter)
                }
                self.value = value
            }
        }
    }

    @Environment(\.realmConfiguration) var configuration
    @ObservedObject private var storage = Storage(Results(RLMResults.emptyDetached()))
    @State public var filter: NSPredicate? {
        willSet {
            storage.filter = newValue
        }
    }
    @State public var sortDescriptor: SortDescriptor? {
        willSet {
            storage.sortDescriptor = newValue
        }
    }

    public var wrappedValue: Value {
        storage.configuration != nil ? storage.value.freeze() : storage.value
    }

    public var projectedValue: Self {
        return self
    }

    public typealias SortDescriptor = (keyPath: String, ascending: Bool)

    public init(_ type: ResultType.Type,
                configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration,
                filter: NSPredicate? = nil,
                sortDescriptor: SortDescriptor? = nil) {
        self.filter = filter
        self.sortDescriptor = sortDescriptor
        let defaultRealm = try? Realm(configuration: configuration)
        if defaultRealm?.schema.objectSchema.contains(where: { $0.objectClass == type }) ?? false, let configuration = defaultRealm?.configuration {
            storage.configuration = configuration
        }
    }

    public mutating func update() {
        // When the view updates, it will inject the @Environment
        // into the propertyWrapper
        if storage.configuration == nil {
            storage.configuration = configuration
        }
    }
}

// MARK: ObservedRealmObject

/// A property wrapper type that subscribes to an observable Realm `Object` or `List` and
/// invalidates a view whenever the observable object changes.
@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper public struct ObservedRealmObject<ObjectType>: DynamicProperty where ObjectType: RealmSubscribable & ThreadConfined & ObservableObject & Equatable {
    /// A wrapper of the underlying observable object that can create bindings to
    /// its properties using dynamic member lookup.
    @dynamicMemberLookup @frozen public struct Wrapper {
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
    public init(wrappedValue: ObjectType) where ObjectType: ObjectKeyIdentifiable {
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
extension Binding where Value: ExpressibleByNilLiteral {
    /// :nodoc:
    public subscript<V, T>(dynamicMember member: ReferenceWritableKeyPath<V, T>) -> Binding<T> where Value == Optional<V>, V: ThreadConfined {
        createBinding(wrappedValue!, forKeyPath: member)
    }
}
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: ObjectBase & ThreadConfined {
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> where V: _ManagedPropertyType {
        createBinding(wrappedValue, forKeyPath: member)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol BoundCollection {
    associatedtype Value

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
        let list = self.wrappedValue.realm != nil ? self.wrappedValue.thaw() ?? self.wrappedValue : self.wrappedValue
        list.realm?.beginWrite()
        list.remove(at: index)
        try? list.realm?.commitWrite()
    }
    /// :nodoc:
    func remove<V>(_ object: V) where Value == Results<V>, V: ObjectBase & ThreadConfined {
        guard let results = self.wrappedValue.thaw(),
              let thawed = object.thaw(),
              let index = results.index(of: thawed),
              let realm = results.realm else {
            return
        }
        try? realm.write {
            realm.delete(results[index])
        }
    }
    /// :nodoc:
    func remove<V>(atOffsets offsets: IndexSet) where Value == Results<V>, V: ObjectBase {
        guard let results = self.wrappedValue.thaw(), let realm = results.realm else {
            return
        }
        try? realm.write {
            realm.delete(Array(offsets.map { results[$0] }))
        }
    }
    /// :nodoc:
    func remove<V>(atOffsets offsets: IndexSet) where Value: List<V> {
        let list = self.wrappedValue.realm != nil ? self.wrappedValue.thaw() ?? self.wrappedValue : self.wrappedValue
        list.realm?.beginWrite()
        list.remove(atOffsets: offsets)
        try? list.realm?.commitWrite()
    }
    /// :nodoc:
    func move<V>(fromOffsets offsets: IndexSet, toOffset destination: Int) where Value: List<V> {
        let list = self.wrappedValue.realm != nil ? self.wrappedValue.thaw() ?? self.wrappedValue : self.wrappedValue
        list.realm?.beginWrite()
        list.move(fromOffsets: offsets, toOffset: destination)
        try? list.realm?.commitWrite()
    }
    /// :nodoc:
    func append<V>(_ value: Value.Element) where Value: List<V>, Value.Element: RealmCollectionValue {
        let list = self.wrappedValue.realm != nil ? self.wrappedValue.thaw() ?? self.wrappedValue : self.wrappedValue
        list.realm?.beginWrite()
        list.append(value)
        try? list.realm?.commitWrite()
    }
    /// :nodoc:
    func append<V>(_ value: Value.Element) where Value: List<V>, Value.Element: ObjectBase & ThreadConfined {
        let list = self.wrappedValue.realm != nil ? self.wrappedValue.thaw() ?? self.wrappedValue : self.wrappedValue
        // if the value is unmanaged but the list is managed, we are adding this value to the realm
        if value.realm == nil && list.realm != nil {
            KVO.observedObjects[value]?.cancel()
        }
        list.realm?.beginWrite()
        list.append(value)
        try? list.realm?.commitWrite()
    }
    /// :nodoc:
    func append<V>(_ value: Value.Element) where Value == Results<V>, V: Object {
        let results = self.wrappedValue.realm != nil ? self.wrappedValue.thaw() ?? self.wrappedValue : self.wrappedValue
        if value.realm == nil && results.realm != nil {
            KVO.observedObjects[value]?.cancel()
        }
        try! results.realm!.write {
            results.realm!.add(value)
        }
    }
}
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding: BoundCollection where Value: RealmCollection {
}

@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: ObjectKeyIdentifiable & ThreadConfined {
    /// :nodoc:
    public func delete() {
        guard let realm = self.wrappedValue.realm else {
            return
        }
        try? realm.write {
            realm.delete(self.wrappedValue)
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
extension ObservedRealmObject.Wrapper where ObjectType: ObjectBase {
    public func delete() {
        guard let realm = self.wrappedValue.realm else {
            return
        }
        try? realm.write {
            realm.delete(self.wrappedValue)
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
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
    public func bind<V: _ManagedPropertyType>(_ keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V> {
        createBinding(self.realm != nil ? self.thaw() ?? self : self, forKeyPath: keyPath)
    }
}

struct RealmEnvironmentKey: EnvironmentKey {
    static let defaultValue = Realm.Configuration()
}

@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
extension EnvironmentValues {
    /// The current `Realm.Configuration` that the view should use.
    public var realmConfiguration: Realm.Configuration {
        get {
            return self[RealmEnvironmentKey]
        }
        set {
            self[RealmEnvironmentKey] = newValue
        }
    }
    /// The current `Realm` that the view should use.
    public var realm: Realm {
        get {
            return try! Realm(configuration: self[RealmEnvironmentKey])
        }
        set {
            self[RealmEnvironmentKey] = newValue.configuration
        }
    }
}
#endif
