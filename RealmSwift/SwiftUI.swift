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
        var parent = getter()
        guard !parent.isInvalidated else {
            return lastValue
        }
        if parent.isFrozen {
            parent = try! Realm(configuration: parent.realm!.configuration).thaw(parent)!
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
/**
 A custom binding type that allows us to wrap Objects or Collections when being used with SwiftUI Views.
 */
@dynamicMemberLookup
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@frozen public struct RealmBinding<T: ThreadConfined> {
    /// :nodoc:
    public var wrappedValue: T {
        get {
            get().freeze()
        }
        nonmutating set {
            set(newValue)
        }
    }
    private var get: () -> T
    private var set: (T) -> ()

    init(get: @escaping () -> T, set: @escaping (T) -> ()) {
        self.get = get
        self.set = set
    }
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
        get {
            createBinding(get, forKeyPath: member)
        }
    }
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V?>) -> RealmBinding<V> where T: ListBase, V: ObjectBase {
        get {
            RealmBinding<V>(get: {
                return get()[keyPath: member]!
            },
            set: { newValue in
                let parent = get()
                try! parent.realm!.write {
                    parent[keyPath: member] = newValue
                }
            })
        }
    }
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V?>) -> RealmBinding<V> where V: ObjectBase {
        get {
            RealmBinding<V>(get: {
                return get()[keyPath: member]!
            },
            set: { newValue in
                let object = get()
                try! object.realm!.write {
                    object[keyPath: member] = newValue
                }
            })
        }
    }
    /// :nodoc:
    public subscript<CollectionType>(dynamicMember member: ReferenceWritableKeyPath<T, CollectionType>) -> RealmBinding<CollectionType> where CollectionType: RealmCollection {
        get {
            RealmBinding<CollectionType>(get: {
                return get()[keyPath: member]
            }, set: { newValue in
                try! get().realm!.write { wrappedValue[keyPath: member] = newValue }
            })
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding: RandomAccessCollection, BidirectionalCollection, Collection, Sequence where T: RealmCollection {
    /// :nodoc:
    public typealias Element = T.Element
    /// :nodoc:
    public typealias Index = T.Index
    /// :nodoc:
    public typealias Indices = T.Indices
    /// :nodoc:
    public typealias Iterator = AnyIterator<T.Element>
    /// :nodoc:
    public func makeIterator() -> Iterator {
        fatalError()
    }
    /// :nodoc:
    public var startIndex: Index {
        return get().startIndex
    }
    /// :nodoc:
    public var endIndex: Index {
        return get().endIndex
    }
    /// :nodoc:
    public func index(before i: Index) -> Index {
        return get().index(before: i)
    }
    /// :nodoc:
    public func index(after i: Index) -> Index {
        return get().index(after: i)
    }
    /// :nodoc:
    public var indices: Indices {
        return get().indices
    }
    /// :nodoc:
    public subscript(position: Index) -> Element {
        get {
            if self.get().isFrozen { throwRealmException("Cannot get values from a frozen realm") }
            return self.get()[position]
        }
    }
    /// :nodoc:
    public subscript(position: Index) -> Element where Element: ThreadConfined {
        get {
            let collection = self.get()
            if collection.isFrozen { throwRealmException("Cannot get values from a frozen realm") }
            return collection.realm!.thaw(collection[position])!
        }
    }
    /// :nodoc:
    public func remove<V>(at index: Index) where T == List<V> {
        let collection = get()
        try! collection.realm!.write {
            collection.remove(at: index)
        }
    }
    /// :nodoc:
    public func remove<V>(at index: Index) where T == Results<V>, V: ObjectBase {
        let results = get()
        try! results.realm!.write {
            results.realm!.delete(results[index])
        }
    }
    /// :nodoc:
    public func remove<V>(atOffsets offsets: IndexSet) where T == Results<V>, V: ObjectBase {
        let results = get()
        try! results.realm!.write {
            results.realm!.delete(Array(offsets.map { results[$0] }))
        }
    }
    /// :nodoc:
    public func remove<V>(atOffsets offsets: IndexSet) where T: List<V> {
        let list = get()
        try! list.realm!.write {
            list.remove(atOffsets: offsets)
        }
    }
    /// :nodoc:
    public func move<V>(fromOffsets offsets: IndexSet, toOffset destination: Int) where T: List<V> {
        let list = get()
        try! list.realm!.write {
            list.move(fromOffsets: offsets, toOffset: destination)
        }
    }
    /// :nodoc:
    public func append<V>(_ value: T.Element) where T: List<V> {
        let list = get()
        try! list.realm!.write {
            list.append(value)
        }
    }
    /// :nodoc:
    public func append<V>(_ value: T.Element) where T == Results<V>, V: Object {
        let collection = get()
        try! collection.realm!.write {
            collection.realm!.add(value)
        }
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
                return box.value
            }
            return box.value.freeze()
        }
        nonmutating set {
            box.value = newValue
        }
    }
    /// :nodoc:
    public var projectedValue: RealmBinding<T> {
        RealmBinding(get: {
            box.value
        }, set: { newValue in
            wrappedValue = newValue
        })
    }

    /**
     Initialize a RealmState struct for a given thread confined type.
     - parameter wrappedValue The RealmSubscribable value to wrap and observe.
     */
    public init(wrappedValue: T) {
        _box = StateObject(wrappedValue: Box(wrappedValue))
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
        _box = StateObject(wrappedValue: Box(results))
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
#endif
