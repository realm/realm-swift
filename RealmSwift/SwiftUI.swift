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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private func createBinding<T: ThreadConfined, V>(_ getter: @escaping () -> T,
                                                 forKeyPath keyPath: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
    let lastValue = getter()[keyPath: keyPath]
    return Binding(get: {
        let parent = getter()
        guard !parent.isInvalidated else {
            return lastValue
        }
        if parent.isFrozen {
            guard let config = parent.realm?.configuration,
                  let realm = try? Realm(configuration: config),
                  let parent = realm.thaw(parent) else {
                return lastValue
            }
            return parent[keyPath: keyPath]
        }
        return parent[keyPath: keyPath]
    },
    set: { newValue in
        var parent = getter()
        guard !parent.isInvalidated else { return }
        if parent.isFrozen {
            parent = try! Realm(configuration: parent.realm!.configuration).thaw(parent)!
        }

        parent.realm?.beginWrite()
        parent[keyPath: keyPath] = newValue
        try! parent.realm?.commitWrite()
    })
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: ExpressibleByNilLiteral {
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V?> where Value == Optional<V>, V: ThreadConfined {
        get {
            Binding<V?>(get: {
                return wrappedValue[keyPath: member]
            }, set: { _ in
                fatalError()
            })
//            createBinding({ wrappedValue }, forKeyPath: member)
        }
    }
}
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: ObjectBase & ThreadConfined {
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> where V: _ManagedPropertyType {
        get {
            createBinding({ wrappedValue }, forKeyPath: member)
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: RealmCollection {
    /// :nodoc:
    public typealias Element = Value.Element
    /// :nodoc:
    public typealias Index = Value.Index
    /// :nodoc:
    public typealias Indices = Value.Indices
    /// :nodoc:
    public func remove<V>(at index: Index) where Value == List<V> {
        let collection = self.wrappedValue.thaw()
        try! collection.realm!.write {
            collection.remove(at: index)
        }
    }
    /// :nodoc:
    public func remove<V>(at index: Index) where Value == Results<V>, V: ObjectBase {
        let results = self.wrappedValue.thaw()
        try! results.realm!.write {
            results.realm!.delete(results[index])
        }
    }
    /// :nodoc:
    public func remove<V>(atOffsets offsets: IndexSet) where Value == Results<V>, V: ObjectBase {
        let results = self.wrappedValue.thaw()
        try! results.realm!.write {
            results.realm!.delete(Array(offsets.map { results[$0] }))
        }
    }
    /// :nodoc:
    public func remove<V>(atOffsets offsets: IndexSet) where Value: List<V> {
        let list = self.wrappedValue.thaw()
        try! list.realm!.write {
            list.remove(atOffsets: offsets)
        }
    }
    /// :nodoc:
    public func move<V>(fromOffsets offsets: IndexSet, toOffset destination: Int) where Value: List<V> {
        let list = self.wrappedValue.thaw()
        try! list.realm!.write {
            list.move(fromOffsets: offsets, toOffset: destination)
        }
    }
    /// :nodoc:
    public func append<V>(_ value: Value.Element) where Value: List<V> {
        let list = self.wrappedValue.thaw()
        try! list.realm!.write {
            list.append(value)
        }
    }
    /// :nodoc:
    public func append<V>(_ value: Value.Element) where Value == Results<V>, V: Object {
        let collection = self.wrappedValue.thaw()
        try! collection.realm!.write {
            collection.realm!.add(value)
        }
    }
}
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding where Value: ExpressibleByNilLiteral {
    /// :nodoc:
    public func remove<V>(at index: List<V>.Index) where Value == Optional<List<V>> {
        let collection = self.wrappedValue!.thaw()
        try! collection.realm!.write {
            collection.remove(at: index)
        }
    }
    /// :nodoc:
    public func remove<V>(at index: Results<V>.Index) where Value == Optional<Results<V>>, V: ObjectBase {
        let results = self.wrappedValue!.thaw()
        try! results.realm!.write {
            results.realm!.delete(results[index])
        }
    }
    /// :nodoc:
    public func remove<V>(atOffsets offsets: IndexSet) where Value == Optional<Results<V>>, V: ObjectBase {
        let results = self.wrappedValue!
        try! results.realm!.write {
            results.realm!.delete(Array(offsets.map { results[$0] }))
        }
    }
    /// :nodoc:
    public func remove<V>(atOffsets offsets: IndexSet) where Value == Optional<List<V>> {
        let list = self.wrappedValue!
        try! list.realm!.write {
            list.remove(atOffsets: offsets)
        }
    }
    /// :nodoc:
    public func move<V>(fromOffsets offsets: IndexSet, toOffset destination: Int) where Value == Optional<List<V>> {
        let list = self.wrappedValue!.thaw()
        try! list.realm!.write {
            list.move(fromOffsets: offsets, toOffset: destination)
        }
    }
    /// :nodoc:
    public func append<V>(_ value: Value.Wrapped.Element) where Value == Optional<List<V>> {
        let list = self.wrappedValue!.thaw()
        try! list.realm!.write {
            list.append(value)
        }
    }
    /// :nodoc:
    public func append<V>(_ value: Value.Wrapped.Element) where Value == Optional<Results<V>>, V: Object {
        let collection = self.wrappedValue!.thaw()
        try! collection.realm!.write {
            collection.realm!.add(value)
        }
    }
    /// :nodoc:
    public func index<V>(of value: V) -> Results<V>.Index? where Value == Optional<Results<V>>, V: Object {
        guard let collection = wrappedValue?.thaw() else {
            throwRealmException("Attempting to get index of value \(value) from nil Results")
        }
        return !value.thaw().isInvalidated ? collection.firstIndex(of: value.thaw()!) : nil
    }
}

// MARK: Realm Environment

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
public extension EnvironmentValues {
    /// The preferred Realm for the environment.
    /// If not set, this will be a Realm with the default configuration.
    var realm: Realm {
        get {
            try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        }
        set {
            Realm.Configuration.defaultConfiguration = newValue.configuration
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Optional: RealmSubscribable where Wrapped: RealmSubscribable {
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
                            _ subscriber: S) -> NotificationToken where Self == S.Input, S : Subscriber, S.Failure == Error {
        return self?._observe(on: queue, WrappedSubscriber(subscriber: AnySubscriber(subscriber))) ?? NotificationToken()
    }

    public func _observe<S>(_ subscriber: S) -> NotificationToken where S : Subscriber, S.Failure == Never, S.Input == Void {
        return self?._observe(subscriber) ?? NotificationToken()
    }
}

@available(iOS 9.0, macOS 10.9, tvOS 13.0, watchOS 6.0, *)
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
}

// MARK: RealmState
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private final class Box<T: RealmSubscribable & ThreadConfined>: ObservableObject, Subscriber {
    typealias Input = T
    typealias Failure = Error

    var value: T {
        willSet {
            objectWillChange.send()
        }
    }

    var token: NotificationToken?

    init(_ value: T) {
        self.value = value.isFrozen ? value.realm!.thaw(value)! : value
        self.token = self.value._observe(on: nil, self)
    }

    func receive(subscription: Subscription) {
    }
    func receive(_ input: T) -> Subscribers.Demand {
        self.objectWillChange.send()
        return .unlimited
    }
    func receive(completion: Subscribers.Completion<Error>) {
        token?.invalidate()
    }
}

/**
 RealmState is a property wrapper that abstracts Realm's unique functionality away from the user and SwiftUI
 to enable simpler realm writes, collection freezes/thaws, and observation.

 SwiftUI will update views automatically when a wrapped value changes.

 Example usage:
 
 ```swift
 struct PersonView: View {
     @RealmState(Person.self) var results

     var body: some View {
         return NavigationView {
             List {
                 ForEach(results) { person in
                     NavigationLink(destination: PersonDetailView(person: person)) {
                         Text(person.name)
                     }
                 }
                 .onDelete(perform: $results.remove)
             }
             .navigationBarTitle("People", displayMode: .large)
             .navigationBarItems(trailing: Button("Add") {
                 $results.append(Person())
             })
         }
     }
 }
 ```
 */
@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
@frozen @propertyWrapper public struct RealmState<T: RealmSubscribable & ThreadConfined>: DynamicProperty {
    @StateObject private var box: Box<T>
    /// :nodoc:
    public var wrappedValue: T {
        get {
            if box.value.isInvalidated {
                return defaultValue
            }
            return box.value.freeze()
        }
        nonmutating set {
            box.value = newValue
        }
    }
    /// :nodoc:
    public var projectedValue: Binding<T> {
        Binding(get: {
            if box.value.isInvalidated {
                return defaultValue
            }
            return box.value//.freeze()
        }, set: { newValue in
            try? wrappedValue.realm?.write {
                wrappedValue = newValue
            }
        })
    }
    /**
     An empty, zero initialized value of the object type. We create this on initialization of the
     property wrapper because in certain cases with SwiftUI, the view heirarchy will hold
     onto invalidated references. This acts as a stand in value during those occurences.
     */
    private let defaultValue: T
    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The RealmSubscribable value to wrap and observe.
     */
    public init(wrappedValue: T) where T: ObjectBase {
        let value = try! Realm(configuration: wrappedValue.realm!.configuration).thaw(wrappedValue)!
        self._box = StateObject(wrappedValue: Box(value))
        self.defaultValue = T()
    }

    public init<V>(wrappedValue: T) where T == List<V> {
        let value = try! Realm(configuration: wrappedValue.realm!.configuration).thaw(wrappedValue)!
        self._box = StateObject(wrappedValue: Box(value))
        self.defaultValue = T()
    }
    public init<V>(wrappedValue: T) where T == Results<V> {
        let value = try! Realm(configuration: wrappedValue.realm!.configuration).thaw(wrappedValue)!
        self._box = StateObject(wrappedValue: Box(value))
        self.defaultValue = T(wrappedValue.rlmResults.snapshot())
    }
    /**
     Initialize a RealmState struct for a given Result type.
     - parameter type The Object Type to get results for.
     - parameter filter An optional filter to filter the results on.
     - parameter realm An optional realm to get the results from. If not provided, it will use the default Realm.
     */
    public init<U: Object>(_ type: U.Type, filter: NSPredicate? = nil, realm: Realm? = nil) where T == Results<U> {
        let actualRealm = realm == nil ? try! Realm(configuration: Realm.Configuration.defaultConfiguration) : realm!
        let results = filter == nil ? actualRealm.objects(U.self) : actualRealm.objects(U.self).filter(filter!)
        self._box = StateObject(wrappedValue: Box(results))
        self.defaultValue = T(results.rlmResults.snapshot())
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
extension RealmState where T: ExpressibleByNilLiteral {
    public init() {
        self._box = StateObject(wrappedValue: Box(nil))
        self.defaultValue = nil
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
@frozen @propertyWrapper public struct ObservedRealmObject<ObjectType: RealmSubscribable & ThreadConfined & ObservableObject>: DynamicProperty {
    /// A wrapper of the underlying observable object that can create bindings to
    /// its properties using dynamic member lookup.
    @dynamicMemberLookup @frozen public struct Wrapper {
        fileprivate var wrappedValue: ObjectType
        /// Returns a binding to the resulting value of a given key path.
        ///
        /// - Parameter keyPath  : A key path to a specific resulting value.
        ///
        /// - Returns: A new binding.
        public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>) -> Binding<Subject> {
            Binding(get: {
                self.wrappedValue[keyPath: keyPath]
            }, set: {
                self.wrappedValue[keyPath: keyPath] = $0
            })
        }
    }
    @ObservedObject private var object: ObjectType
    /**
     An empty, zero initialized value of the object type. We create this on initialization of the
     property wrapper because in certain cases with SwiftUI, the view heirarchy will hold
     onto invalidated references. This acts as a stand in value during those occurences.
     */
    private let defaultValue: ObjectType

    /// :nodoc:
    public var wrappedValue: ObjectType {
        get {
            if object.isInvalidated {
                return defaultValue
            }
            return object.freeze()
        }
        set {
            object = newValue
        }
    }
    /// :nodoc:
    public var projectedValue: Wrapper {
        if object.isInvalidated {
            return Wrapper(wrappedValue: defaultValue)
        }
        return Wrapper(wrappedValue: object/*.freeze()*/)
    }

    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The RealmSubscribable value to wrap and observe.
     */
    public init(wrappedValue: ObjectType) where ObjectType: ObjectBase {
        if wrappedValue.isFrozen {
            _object = ObservedObject(wrappedValue: try! Realm(configuration: wrappedValue.realm!.configuration).thaw(wrappedValue)!)
        } else {
            _object = ObservedObject(wrappedValue: wrappedValue)
        }
        defaultValue = ObjectType()
    }
    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The RealmSubscribable value to wrap and observe.
     */
    public init<V>(wrappedValue: ObjectType) where ObjectType == List<V> {
        if wrappedValue.isFrozen {
            _object = ObservedObject(wrappedValue: try! Realm(configuration: wrappedValue.realm!.configuration).thaw(wrappedValue)!)
        } else {
            _object = ObservedObject(wrappedValue: wrappedValue)
        }
        defaultValue = ObjectType()
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
extension ObservedRealmObject where ObjectType: ExpressibleByNilLiteral {
    public init() {
        _object = ObservedObject(wrappedValue: nil)
        defaultValue = nil
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
    public func bind<V: _ManagedPropertyType>(keyPath: ReferenceWritableKeyPath<Self, V>) -> Binding<V>  {
        createBinding({self}, forKeyPath: keyPath)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
extension ObservedRealmObject.Wrapper where ObjectType: RealmCollection {
    public typealias Value = ObjectType
    /// :nodoc:
    public typealias Element = Value.Element
    /// :nodoc:
    public typealias Index = Value.Index
    /// :nodoc:
    public typealias Indices = Value.Indices
    /// :nodoc:
    public func remove<V>(at index: Index) where Value == List<V> {
        let collection = self.wrappedValue.thaw()
        try! collection.realm!.write {
            collection.remove(at: index)
        }
    }
    /// :nodoc:
    public func remove<V>(atOffsets offsets: IndexSet) where Value: List<V> {
        let list = self.wrappedValue.thaw()
        try! list.realm!.write {
            list.remove(atOffsets: offsets)
        }
    }
    /// :nodoc:
    public func move<V>(fromOffsets offsets: IndexSet, toOffset destination: Int) where Value: List<V> {
        let list = self.wrappedValue.thaw()
        try! list.realm!.write {
            list.move(fromOffsets: offsets, toOffset: destination)
        }
    }
    /// :nodoc:
    public func append<V>(_ value: Value.Element) where Value: List<V> {
        let list = self.wrappedValue.thaw()
        try! list.realm!.write {
            list.append(value)
        }
    }
}
#endif
