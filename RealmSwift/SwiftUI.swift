////////////////////////////////////////////////////////////////////////////
 //
 // Copyright 2020 Realm Inc.
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

/**
 A custom binding type that allows us to wrap Objects or Collections when being used with SwiftUI Views.
 */
@dynamicMemberLookup
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@frozen public struct RealmBinding<T: ThreadConfined> {
    public var wrappedValue: T {
        get {
            get()
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

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> V {
        get {
            return self.wrappedValue[keyPath: member]
        } set {
            try! self.wrappedValue.realm!.write {
                self.wrappedValue[keyPath: member] = newValue
            }
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
        get {
            return Binding(get: {
                self.wrappedValue[keyPath: member]
            },
            set: { newValue in
                try! self.wrappedValue.realm!.write {
                    self.wrappedValue[keyPath: member] = newValue
                }
            })
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> RealmBinding<V> where V: EmbeddedObject {
        get {
            RealmBinding<V>(get: { wrappedValue[keyPath: member] }, set: {
                wrappedValue[keyPath: member] = $0
            })
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> RealmBinding<V> where V: Object {
        get {
            RealmBinding<V>(get: { wrappedValue[keyPath: member] }, set: {
                wrappedValue[keyPath: member] = $0
            })
        }
    }

    public subscript<CollectionType, Element: RealmCollectionValue>(dynamicMember member: ReferenceWritableKeyPath<T, CollectionType>) -> RealmBinding<CollectionType> where CollectionType: List<Element> {
        get {
            RealmBinding<CollectionType>(get: { wrappedValue[keyPath: member].freeze() }, set: {
                wrappedValue[keyPath: member] = $0
            })
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding: MutableCollection where T: RealmCollection {
    public subscript(position: Index) -> Element {
        get {
            self.wrappedValue[position]
        }
        set {
            fatalError("should not set")
        }
    }

    public typealias SubSequence = Slice<RealmBinding<T>>

    public func filter(_ predicateFormat: String, _ args: Any...) -> RealmBinding<Results<T.Element>> {
        var results = self.wrappedValue.filter(predicateFormat, args)
        return RealmBinding<Results<T.Element>>(get: { results.freeze() },
                                                set: { results = $0 })
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding: RandomAccessCollection, BidirectionalCollection, Collection, Sequence where T: RealmCollection {
    public typealias Element = T.Element
    public typealias Index = T.Index
    public typealias Indices = T.Indices
    public typealias Iterator = AnyIterator<T.Element>

    public func makeIterator() -> Iterator {
        fatalError()
    }
    public var startIndex: Index {
        return wrappedValue.startIndex
    }
    public var endIndex: Index {
        return wrappedValue.endIndex
    }
    public func index(before i: Index) -> Index {
        return wrappedValue.index(before: i)
    }
    public func index(after i: Index) -> Index {
        return wrappedValue.index(after: i)
    }
    public var indices: Indices {
        return wrappedValue.indices
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding where T: ListBase, T: RealmCollection {
    /// :nodoc:
    public func remove(atOffsets offsets: IndexSet) {
        guard let config = wrappedValue.realm?.configuration,
              let realm = try? Realm(configuration: config),
              let resolved = wrappedValue.thaw() as? List<T.Element> else {
            return
        }
        try? realm.write {
            resolved.remove(atOffsets: offsets)
        }
    }
    /// :nodoc:
    public func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        guard let config = wrappedValue.realm?.configuration,
              let realm = try? Realm(configuration: config),
              let resolved = wrappedValue.thaw() as? List<T.Element> else {
            return
        }
        try! realm.write {
            resolved.move(fromOffsets: offsets, toOffset: destination)
        }
    }
    /// :nodoc:
    public func append(_ value: T.Element) {
        guard let config = wrappedValue.realm?.configuration,
              let realm = try? Realm(configuration: config),
              let resolved = wrappedValue.thaw() as? List<T.Element> else {
            return
        }
        try? realm.write {
            resolved.append(value)
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding where T: RealmCollection, T.Element : Object {
    /// :nodoc:
    public func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            let resolved = wrappedValue.thaw() as! List<T.Element>
            resolved.move(fromOffsets: offsets, toOffset: destination)
        }
    }

    public func append(_ value: T.Element) where T: ResultsBase, T.Element: Object {
        guard let config = wrappedValue.realm?.configuration,
              let realm = try? Realm(configuration: config),
              let resolved = wrappedValue.thaw() else {
            return
        }
        try? realm.write {
            realm.add(value)
        }
        // results are a special case, since we are not actually appending
        // to the results and the method is strictly for convenience
        self.wrappedValue = resolved.freeze()
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding where T: AnyResultsBase {
    /// :nodoc:
    public func remove(atOffsets offsets: IndexSet) {
        guard let config = wrappedValue.realm?.configuration,
              let realm = try? Realm(configuration: config),
              let resolved = wrappedValue.thaw() as? Results<T.Element> else {
            return
        }
        try! realm.write {
            resolved[offsets].forEach {
                realm.delete($0 as! Object)
            }
        }
        // results are a special case, since we are not actually appending
        // to the results and the method is strictly for convenience
        self.wrappedValue = resolved.freeze() as! T
    }
}
// MARK: Realm Environment

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
private struct RealmEnvironmentKey: EnvironmentKey {
    static let defaultValue = Realm.Configuration()
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
public extension EnvironmentValues {
    /// The preferred Realm for the environment.
    /// If not set, this will be a Realm with the default configuration.
    var realm: Realm {
        get { try! Realm(configuration: self[RealmEnvironmentKey.self]) }
        set { self[RealmEnvironmentKey.self] = newValue.configuration }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
public extension View {
    var realm: Realm {
        return Environment(\.realm).wrappedValue
    }

    func bind<T, V>(_ confined: T,
                    _ memberKeyPath: ReferenceWritableKeyPath<T, V>) -> Binding<V> where T: ThreadConfined {
        return Binding(get: {
            guard let resolved = confined.thaw() else {
                fatalError("Only managed objects can be view bound")
            }
            return resolved[keyPath: memberKeyPath]
        }, set: { newValue in
            guard let config = confined.realm?.configuration,
                  let realm = try? Realm(configuration: config),
                  let resolved = confined.thaw() else {
                fatalError("Only managed objects can be view bound")
            }
            try? realm.write {
                resolved[keyPath: memberKeyPath] = newValue
            }
        })
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
        self.value = value
        self.token = self.value.thaw()?._observe(on: nil, self)
    }

    func receive(subscription: Subscription) {
    }
    func receive(_ input: T) -> Subscribers.Demand {
        self.value = value.thaw()!.freeze()
        return .unlimited
    }
    func receive(completion: Subscribers.Completion<Error>) {
        token?.invalidate()
    }
}

/**
 RealmState is a property wrapper that abstracts realm unique functionality away from the user,
 to enable simpler realm writes, collection freezes/thaws, and observation.
 */
@available(iOS 14.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@frozen @propertyWrapper public struct RealmState<T: RealmSubscribable & ThreadConfined>: DynamicProperty {
    @StateObject private var box: Box<T>

    public var wrappedValue: T {
        get {
            return box.value
        }
        nonmutating set {
            box.value = newValue
        }
    }

    public var projectedValue: RealmBinding<T> {
        RealmBinding(get: {
            wrappedValue
        }, set: { newValue in
            wrappedValue = newValue
        })
    }

    public init(wrappedValue: T) {
        _box = StateObject(wrappedValue: Box(wrappedValue.freeze()))
    }

    /**
     Initialize a RealmState struct for a given Result type.

     */
    public init<U: Object>(_ type: U.Type, filter: NSPredicate? = nil, realm: Realm? = nil) where T == Results<U> {
        if let realm = realm {
            _box = StateObject(wrappedValue: Box(realm.objects(U.self).freeze()))
        } else {
            let realm = Environment(\.realm).wrappedValue
            let results = filter == nil ? realm.objects(U.self) : realm.objects(U.self).filter(filter!)
            _box = StateObject(wrappedValue: Box(results.freeze()))
        }
    }
}

#endif
