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

private func resolve<T: ThreadConfined>(_ frozen: T) -> (Realm, T)? {
    guard let config = frozen.realm?.configuration,
          let realm = try? Realm(configuration: config),
          let resolved = realm.thaw(frozen) else {
        return nil
    }
    return (realm, resolved)
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
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
        get {
            return Binding(get: {
                guard let (_, resolved) = resolve(wrappedValue) else {
                    return wrappedValue[keyPath: member]
                }
                return resolved[keyPath: member]
            },
            set: { newValue in
                guard let (realm, resolved) = resolve(wrappedValue) else {
                    return
                }
                try! realm.write {
                    resolved[keyPath: member] = newValue
                }
            })
        }
    }
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V?>) -> RealmBinding<V> where T: ListBase, V: ObjectBase {
        get {
            RealmBinding<V>(get: {
                guard let (_, resolved) = resolve(wrappedValue) else {
                    fatalError("Trying to get object that does not exist")
                }
                return resolved[keyPath: member]!
            },
            set: { newValue in
                guard let (realm, resolved) = resolve(wrappedValue) else {
                    return
                }
                try! realm.write {
                    resolved[keyPath: member] = newValue
                }
            })
        }
    }
    /// :nodoc:
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V?>) -> RealmBinding<V> where V: ObjectBase {
        get {
            RealmBinding<V>(get: {
                guard let (_, resolved) = resolve(wrappedValue) else {
                    fatalError("Trying to get object that does not exist")
                }
                return resolved[keyPath: member]!
            },
            set: { newValue in
                guard let (realm, resolved) = resolve(wrappedValue) else {
                    return
                }
                try! realm.write {
                    resolved[keyPath: member] = newValue
                }
            })
        }
    }
    /// :nodoc:
    public subscript<CollectionType>(dynamicMember member: ReferenceWritableKeyPath<T, CollectionType>) -> RealmBinding<CollectionType> where CollectionType: RealmCollection {
        get {
            RealmBinding<CollectionType>(get: {
                guard let (_, resolved) = resolve(wrappedValue) else {
                    return wrappedValue[keyPath: member]
                }
                return resolved[keyPath: member].freeze()
            }, set: { newValue in
                guard let (realm, resolved) = resolve(wrappedValue) else {
                    return
                }
                try? realm.write { resolved[keyPath: member] = newValue }
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
        return wrappedValue.startIndex
    }
    /// :nodoc:
    public var endIndex: Index {
        return wrappedValue.endIndex
    }
    /// :nodoc:
    public func index(before i: Index) -> Index {
        return wrappedValue.index(before: i)
    }
    /// :nodoc:
    public func index(after i: Index) -> Index {
        return wrappedValue.index(after: i)
    }
    /// :nodoc:
    public var indices: Indices {
        return wrappedValue.indices
    }
    /// :nodoc:
    public subscript(position: Index) -> Element {
        get {
            self.wrappedValue[position]
        }
    }
    /// :nodoc:
    public subscript(position: Index) -> Element where Element: ThreadConfined {
        get {
            (self.wrappedValue[position].realm?.thaw(self.wrappedValue[position])!.freeze())!
        }
    }
    /// :nodoc:
    public func remove<V>(atOffsets offsets: IndexSet) where T == Results<V>, V: ObjectBase {
        guard let (realm, resolved) = resolve(wrappedValue) else {
            return
        }
        try! realm.write {
            offsets.forEach { index in
                realm.delete(resolved[index])
            }
        }

        self.wrappedValue = resolved.freeze()
    }
    /// :nodoc:
    public func remove<V>(atOffsets offsets: IndexSet) where T: List<V> {
        guard let (realm, resolved) = resolve(wrappedValue) else {
            return
        }
        try! realm.write {
            resolved.remove(atOffsets: offsets)
        }
    }
    /// :nodoc:
    public func move(fromOffsets offsets: IndexSet, toOffset destination: Int) where T: ListBase {
        guard let (realm, resolved) = resolve(wrappedValue),
              let actual = resolved as? List<T.Element> else {
            return
        }
        try! realm.write {
            actual.move(fromOffsets: offsets, toOffset: destination)
        }
    }
    /// :nodoc:
    public func append<V>(_ value: T.Element) where T: List<V> {
        guard let (realm, resolved) = resolve(wrappedValue) else {
            return
        }

        try! realm.write {
            resolved.append(value)
        }
    }
    /// :nodoc:
    public func append<V>(_ value: T.Element) where T == Results<V>, V: Object {
        guard let (realm, resolved) = resolve(wrappedValue) else {
            return
        }

        try! realm.write {
            realm.add(value)
        }

        self.wrappedValue = resolved.freeze()
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
            guard let resolved = confined.realm?.thaw(confined) else {
                fatalError("Only managed objects can be view bound")
            }
            return resolved[keyPath: memberKeyPath]
        }, set: { newValue in
            guard let (realm, resolved) = resolve(confined) else {
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
        self.token = self.value.realm?.thaw(self.value)?._observe(on: nil, self)
    }

    func receive(subscription: Subscription) {
    }
    func receive(_ input: T) -> Subscribers.Demand {
        self.value = value.realm!.thaw(value)!.freeze()
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
    /// :nodoc:
    public var wrappedValue: T {
        get {
            return box.value
        }
        nonmutating set {
            box.value = newValue
        }
    }

    /// :nodoc:
    public var projectedValue: RealmBinding<T> {
        RealmBinding(get: {
            wrappedValue
        }, set: { newValue in
            wrappedValue = newValue
        })
    }

    /**
     Initialize a RealmState struct for a given thread confined type.
     */
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
