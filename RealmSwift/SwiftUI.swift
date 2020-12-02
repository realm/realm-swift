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
public final class RealmBinding<T>: ObservableObject {
    var value: T
    private var realm: Realm
    var _observe: ((inout RealmState<T>, _ block: @escaping (RealmState<T>) -> Void) -> NotificationToken)? = nil

    public var wrappedValue: T {
        get {
            value
        } set {
            value = newValue
        }
    }

    init(_ value: T, realm: Realm) where T: EmbeddedObject {
        self.value = value
        self._observe = { (binder: inout RealmState<T>, block: @escaping (RealmState<T>) ->Void) -> NotificationToken in
            value.observe(on: nil) { [binder] _ in
                block(binder)
            }
        }
        self.realm = realm
    }

    init(_ value: T, realm: Realm) where T: Object {
        self.value = value
        self._observe = { (binder: inout RealmState<T>, block: @escaping (RealmState<T>) ->Void) -> NotificationToken in
            value.observe(on: nil) { [binder] _ in
                block(binder)
            }
        }
        self.realm = realm
    }

    init(_ value: T, realm: Realm) where T: RealmCollection {
        self.value = value
        self._observe = { (binder: inout RealmState<T>, block: @escaping (RealmState<T>) ->Void) -> NotificationToken in
            value.observe(on: nil) { [binder] _ in
                block(binder)
            }
        }
        self.realm = realm
    }

    func observe(binder: inout RealmState<T>, _ block: @escaping (RealmState<T>) -> Void) -> NotificationToken? {
        _observe?(&binder) { [block] binder in
            block(binder)
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> V {
        get {
            self.value[keyPath: member]
        } set {
            try! self.realm.write {
                self.value[keyPath: member] = newValue
            }
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
        get {
            Binding(get: {
                self.value[keyPath: member]
            },
            set: { newValue in
                try! self.realm.write {
                    self.value[keyPath: member] = newValue
                }
            })
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> RealmBinding<V> where V: EmbeddedObject {
        get {
            RealmBinding<V>(value[keyPath: member], realm: realm)
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> RealmBinding<V> where V: Object {
        get {
            RealmBinding<V>(value[keyPath: member], realm: realm)
        }
    }

    public subscript<CollectionType>(dynamicMember member: ReferenceWritableKeyPath<T, CollectionType>) -> RealmBinding<CollectionType> where CollectionType: RealmCollection {
        get {
            RealmBinding<CollectionType>(self.wrappedValue[keyPath: member].freeze(), realm: realm)
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding where T: RealmCollection {
    public subscript(position: Index) -> Element {
        get {
            let value = self.wrappedValue[position]
            if let value = value as? ThreadConfined {
                return value.thaw() as! T.Element
            } else {
                return value
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding: RandomAccessCollection, BidirectionalCollection, Collection, Sequence where T: RealmCollection {
    public func index(before i: Index) -> Index {
        wrappedValue.index(before: i)
    }

    public func index(after i: Index) -> Index {
        wrappedValue.index(after: i)
    }

    public var indices: Indices {
        wrappedValue.indices
    }

    public typealias Element = T.Element
    public typealias Index = T.Index

    public typealias SubSequence = Slice<RealmBinding<T>>

    public typealias Indices = T.Indices

    @frozen public struct BoundIterator: IteratorProtocol {
        private var generatorBase: NSFastEnumerationIterator
        private let bound: RealmBinding
        init(bound: RealmBinding, collection: RLMCollection) {
            self.bound = bound
            generatorBase = NSFastEnumerationIterator(collection)
        }

        /// Advance to the next element and return it, or `nil` if no next element exists.
        public mutating func next() -> Element? {
            let next = generatorBase.next()
            if next is NSNull {
                return T.Element._nilValue()
            }
            if let next = next as? Object? {
                if next == nil {
                    return nil as Element?
                }
                // FIXME: This will always fail
                return unsafeBitCast(next, to: Optional<Element>.self)
            }

            return dynamicBridgeCast(fromObjectiveC: next as Any)
        }
    }

    public typealias Iterator = BoundIterator

    public func makeIterator() -> BoundIterator {
        return BoundIterator(bound: self, collection: wrappedValue as! RLMCollection)
    }
    public var startIndex: Index {
        return wrappedValue.startIndex
    }

    public var endIndex: Index {
        return wrappedValue.endIndex
    }
}


//extension RealmBinding where T: ResultsBase {
//    public func remove(atOffsets offsets: IndexSet) {
//        // TODO: use thaw function
//        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
//        try! realm.write {
//            let resolved = wrappedValue.thaw() as! List<T.Element>
//            resolved.remove(atOffsets: offsets)
//        }
//    }
//
//    /// :nodoc:
//    public func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
//        // TODO: use thaw function
//        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
//        try! realm.write {
//            let resolved = wrappedValue.thaw() as! List<T.Element>
//            resolved.move(fromOffsets: offsets, toOffset: destination)
//        }
//    }
//}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding where T: ListBase, T: RealmCollection {
    public subscript(position: T.Index) -> Element {
        get {
            let value = self.wrappedValue[position]
            if value.self is ThreadConfined {
                return (value as! ThreadConfined).thaw() as! T.Element
            } else {
                return value
            }
        }
    }

    // Method that returns the next index when iterating
    public func index(after i: Index) -> Index {
        return wrappedValue.index(after: i )
    }

    /// :nodoc:
    public func remove(atOffsets offsets: IndexSet) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            let resolved = wrappedValue.thaw() as! List<T.Element>
            resolved.remove(atOffsets: offsets)
        }
    }

    /// :nodoc:
    public func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            let resolved = wrappedValue.thaw() as! List<T.Element>
            resolved.move(fromOffsets: offsets, toOffset: destination)
        }
    }

    public func append(_ value: T.Element) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            let resolved = wrappedValue.thaw() as! List<T.Element>
            resolved.append(value)
        }
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

    func bind<T, V>(_ object: T, _ memberKeyPath: ReferenceWritableKeyPath<T, V>) -> Binding<V> where T: EmbeddedObject {
        guard let realm = object.realm else {
            fatalError("Only managed objects can be view bound")
        }
        return Binding(get: {
            object[keyPath: memberKeyPath]
        }, set: { newValue in
            try! realm.write {
                object[keyPath: memberKeyPath] = newValue
            }
        })
    }
}

// MARK: RealmState

/**
 RealmState is a property wrapper that abstracts realm unique functionality away from the user,
 to enable simpler realm writes, collection freezes/thaws, and observation.
 */
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct RealmState<T> : DynamicProperty {
    private var _wrappedValue: ObservedObject<RealmBinding<T>>
    private var token: NotificationToken?

    public var wrappedValue: T {
        get {
            _wrappedValue.wrappedValue.wrappedValue
        }
        set {
            _wrappedValue.wrappedValue.wrappedValue = newValue
        }
    }

    public var projectedValue: RealmBinding<T> {
        return _wrappedValue.wrappedValue
    }

    public init(wrappedValue: T) where T: EmbeddedObject {
        _wrappedValue = ObservedObject(wrappedValue: RealmBinding(wrappedValue, realm: wrappedValue.realm!))
        token = projectedValue.observe(binder: &self) {
            $0._wrappedValue.wrappedValue.objectWillChange.send()
        }
    }

    public init(wrappedValue: T) where T: Object {
        _wrappedValue = ObservedObject(wrappedValue: RealmBinding(wrappedValue, realm: wrappedValue.realm!))
        token = projectedValue.observe(binder: &self) {
            $0._wrappedValue.wrappedValue.objectWillChange.send()
        }
    }

    public init(wrappedValue: T) where T: RealmCollection {
        _wrappedValue = ObservedObject(wrappedValue: RealmBinding(wrappedValue.freeze(), realm: wrappedValue.realm!))
        token = RealmBinding(wrappedValue, realm: wrappedValue.realm!).observe(binder: &self) {
            $0._wrappedValue.wrappedValue.objectWillChange.send()
        }
    }

    public init<U: Object>(_ type: U.Type, realm: Realm? = nil) where T == Results<U> {
        if let realm = realm {
            _wrappedValue = ObservedObject(wrappedValue: RealmBinding(realm.objects(U.self), realm: realm))
        } else {
            let realm = Environment(\.realm).wrappedValue
            _wrappedValue = ObservedObject(wrappedValue: RealmBinding(realm.objects(U.self), realm: realm))
        }

        token = projectedValue.observe(binder: &self) {
            $0._wrappedValue.wrappedValue.objectWillChange.send()
        }
    }
}

#endif
