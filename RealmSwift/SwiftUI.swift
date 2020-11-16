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
 A set of types to be used to "bind" Realm types to views.
 Bound types are observed, and write transactions are implicit.
 */

// MARK: Bound Types

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
protocol Bound: ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    associatedtype Value

    var wrappedValue: Value { get }

    init(wrappedValue: Value)

    func observe(binder: inout RealmState<Value>, _ block: @escaping (RealmState<Value>) -> Void) -> NotificationToken
}

@dynamicMemberLookup
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class BoundObject<Value: Object> : Bound {
    public var wrappedValue: Value

    public required init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> {
        get {
            Binding(get: {
                self.wrappedValue[keyPath: member]
            }, set: { newValue in
                try! self.wrappedValue.realm!.write {
                    self.wrappedValue[keyPath: member] = newValue
                }
            })
        }
    }

    // if property is a collection, we want to freeze it before fetching it
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, List<V>>) -> BoundList<V> where V: RealmCollectionValue, V: Identifiable {
        get {
            BoundList(wrappedValue: (self.wrappedValue[keyPath: member]).freeze())
        }
    }

    func observe(binder: inout RealmState<Value>, _ block: @escaping (RealmState<Value>) -> Void) -> NotificationToken {
        return wrappedValue.observe { [binder] _ in
            block(binder)
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public final class BoundList<CollectionValue>: RandomAccessCollection,
                                        Sequence,
                                        Collection,
                                        BidirectionalCollection,
                                        Bound,
                                        ObservableObject where CollectionValue: RealmCollectionValue,
                                                               CollectionValue: Identifiable {
    func observe(binder: inout RealmState<List<CollectionValue>>,
                 _ block: @escaping (RealmState<List<CollectionValue>>) -> Void) -> NotificationToken {
        return wrappedValue.observe { [binder] _ in
            block(binder)
        }
    }

    public typealias Value = List<CollectionValue>
    public var wrappedValue: List<CollectionValue>

    public required init(wrappedValue: List<CollectionValue>) {
        self.wrappedValue = wrappedValue
    }

    public var indices: Indices {
        wrappedValue.indices
    }

    public typealias Element = Binding<CollectionValue>
    public typealias Index = Int

    public typealias SubSequence = Slice<Array<Element>>

    public typealias Indices = Value.Indices

    @frozen public struct BoundIterator: IteratorProtocol {
        private var generatorBase: NSFastEnumerationIterator

        init(collection: RLMCollection) {
            generatorBase = NSFastEnumerationIterator(collection)
        }

        /// Advance to the next element and return it, or `nil` if no next element exists.
        public mutating func next() -> Element? {
            let next = generatorBase.next()
            if next is NSNull {
                return Element(get: {
                    CollectionValue._nilValue()
                }, set: {_ in
                    fatalError()
                })
            }
            if let next = next as? Object? {
                if next == nil {
                    return nil as Element?
                }
                // FIXME: This will always fail
                return unsafeBitCast(next, to: Optional<Element>.self)
            }
            return Element(get: {
                dynamicBridgeCast(fromObjectiveC: next as Any)
            }, set: {_ in
                fatalError()
            })
        }
    }

    public typealias Iterator = BoundIterator

    public func makeIterator() -> BoundIterator {
        return BoundIterator(collection: wrappedValue as! RLMCollection)
    }
    public var startIndex: Index {
        return wrappedValue.startIndex 
    }

    public var endIndex: Index {
        return wrappedValue.endIndex 
    }

    public subscript(position: Index) -> Element {
        get {
            Element(get: {
                let value = self.wrappedValue[position ]
                // if value is an Object, thaw it out as this list has been frozen
                if value.self is Object {
                    return (value as! Object).thaw() as! Value.Element
                } else {
                    return value
                }
            }, set: {
                self.wrappedValue[position] = $0
            })
        }
    }

    // Method that returns the next index when iterating
    public func index(after i: Index) -> Index {
        return wrappedValue.index(after: i ) 
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        let tmp = wrappedValue[Range<Value.Index>.init(uncheckedBounds: (bounds.lowerBound ,
                                                                         bounds.upperBound ))]
        return SubSequence(tmp.map { element in
            Element(get: { element }, set: { _ in fatalError() })
        })
    }

    /// :nodoc:
    public func remove(atOffsets offsets: IndexSet) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            let resolved = realm.resolve(ThreadSafeReference(to: wrappedValue))
            resolved!.remove(atOffsets: offsets)
        }
    }

    /// :nodoc:
    public func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            let resolved = realm.resolve(ThreadSafeReference(to: wrappedValue))
            resolved!.move(fromOffsets: offsets, toOffset: destination)
        }
    }

    public func append(_ value: Value.Element) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            let resolved = realm.resolve(ThreadSafeReference(to: wrappedValue))
            resolved!.append(value)
        }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
final class BoundResults<Element: RealmCollectionValue>: ResultsBase, Bound {
    var wrappedValue: Results<Element>
    
    typealias T = Results<Element>
    typealias Element = Element

    let rlmResults: RLMResults<AnyObject>

    init(wrappedValue: Results<Element>) {
        self.wrappedValue = wrappedValue
        self.rlmResults = wrappedValue.rlmResults
    }

    init(_ rlmResults: RLMResults<AnyObject>) {
        self.wrappedValue = Results(rlmResults)
        self.rlmResults = rlmResults
    }

    init(objc: RLMResults<AnyObject>) {
        self.wrappedValue = Results(objc)
        self.rlmResults = objc
    }

    func observe(binder: inout RealmState<Results<Element>>, _ block: @escaping (RealmState<Results<Element>>) -> Void) -> NotificationToken {
        return wrappedValue.observe { [binder] _ in
            block(binder)
        }
    }
}

@dynamicMemberLookup
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public final class AnyBound<T>: Bound, ObservableObject {
    public var projectedValue: T {
        return value
    }
    public var wrappedValue: T {
        return value
    }
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var value: T
    var realm: Realm?
    var _observe: ((inout RealmState<T>, _ block: @escaping (RealmState<T>) -> Void) -> NotificationToken)? = nil

    init(_ value: T, realm: Realm?) where T: Object {
        self.value = value
        self._observe = BoundObject(wrappedValue: value).observe
        self.realm = realm
    }
    init<Element>(_ value: T, realm: Realm?) where T == Results<Element> {
        self.value = value
        self._observe = BoundResults(wrappedValue: value).observe
        self.realm = realm
    }

    func observe(binder: inout RealmState<T>, _ block: @escaping (RealmState<T>) -> Void) -> NotificationToken {
        _observe!(&binder) { [block] binder in
            block(binder)
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
        get {
            Binding(get: {
                self.value[keyPath: member]
            },
            set: { newValue in
                try! self.realm!.write {
                    self.value[keyPath: member] = newValue
                }
            })
        }
    }

    // if property is a list, we want to freeze it before fetching it
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, List<V>>) -> BoundList<V> where V: RealmCollectionValue, V: Identifiable {
        get {
            BoundList(wrappedValue: (self.wrappedValue[keyPath: member]).freeze())
        }
    }
}

// MARK: Realm Environment

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
private struct RealmEnvironmentKey: EnvironmentKey {
    static let defaultValue: Realm = try! Realm()
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
public extension EnvironmentValues {
    var realm: Realm {
          get { self[RealmEnvironmentKey.self] }
          set { self[RealmEnvironmentKey.self] = newValue }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
public extension View {
    func realm(_ realm: Realm) -> some View {
        environment(\.realm, realm)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct RealmState<T> : DynamicProperty {
    private var _wrappedValue: ObservedObject<AnyBound<T>>
    private var token: NotificationToken?

    public var wrappedValue: T {
        get {
            _wrappedValue.wrappedValue.value
        }
    }
    /// The property that can be accessed with the `$` syntax and allows access to the `Publisher`
    public var projectedValue: AnyBound<T> {
        return _wrappedValue.wrappedValue
    }

    public init(wrappedValue: T) where T: Object {
        _wrappedValue = ObservedObject(wrappedValue: AnyBound(wrappedValue, realm: wrappedValue.realm))
        token = projectedValue.observe(binder: &self) {
            $0._wrappedValue.wrappedValue.objectWillChange.send()
        }
    }

    public init<U: Object>(_ type: U.Type, realm: Realm? = nil) where T == Results<U> {
        if let realm = realm {
            _wrappedValue = ObservedObject(wrappedValue: AnyBound(realm.objects(U.self), realm: realm))
        } else {
            let realm = Environment(\.realm).wrappedValue
            _wrappedValue = ObservedObject(wrappedValue: AnyBound(realm.objects(U.self), realm: realm))
        }
        token = projectedValue.observe(binder: &self) {
            $0._wrappedValue.wrappedValue.objectWillChange.send()
        }
    }
}

#endif
