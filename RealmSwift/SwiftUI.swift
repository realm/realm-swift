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
    associatedtype T

    var value: T { get }

    init(_ value: T)

    func observe(binder: inout RealmBind<T>, _ block: @escaping (RealmBind<T>) -> Void) -> NotificationToken
}

@dynamicMemberLookup
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class BoundObject<T: Object> : Bound {
    public var value: T

    public required init(_ value: T) {
        self.value = value
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
        get {
            Binding(get: {
                self.value[keyPath: member]
            }, set: { newValue in
                try! self.value.realm!.write {
                    self.value[keyPath: member] = newValue
                }
            })
        }
    }

    // if property is a list, we want to freeze it before fetching it
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> where V: ListBase {
        get {
            Binding(get: {
                self.value[keyPath: member].freeze()
            }, set: {
                self.value[keyPath: member] = $0
            })
        }
    }

    func observe(binder: inout RealmBind<T>, _ block: @escaping (RealmBind<T>) -> Void) -> NotificationToken {
        return value.observe { [binder] _ in
            block(binder)
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class BoundList<Element: RealmCollectionValue>: ObservableObject {
    public typealias T = Binding<List<Element>>
    public var value: Binding<List<Element>>
    public required init(_ value: Binding<List<Element>>) {
        self.value = value
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
        get {
            Binding(get: {
                self.value[keyPath: member]
            }, set: { newValue in
                try! self.value.wrappedValue.realm!.write {
                    self.value[keyPath: member] = newValue
                }
            })
        }
    }

    // if property is a list, we want to freeze it before fetching it
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> where V: ListBase {
        get {
            Binding(get: {
                self.value[keyPath: member].freeze()
            }, set: {
                self.value[keyPath: member] = $0
            })
        }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
final class BoundResults<Element: RealmCollectionValue>: ResultsBase, Bound {
    typealias T = Results<Element>
    typealias Element = Element

    let rlmResults: RLMResults<AnyObject>
    var value: Results<Element>

    init(_ value: Results<Element>) {
        self.value = value
        self.rlmResults = value.rlmResults
    }

    init(_ rlmResults: RLMResults<AnyObject>) {
        self.value = Results(rlmResults)
        self.rlmResults = rlmResults
    }

    init(objc: RLMResults<AnyObject>) {
        self.value = Results(objc)
        self.rlmResults = objc
    }

    func observe(binder: inout RealmBind<Results<Element>>, _ block: @escaping (RealmBind<Results<Element>>) -> Void) -> NotificationToken {
        return value.observe { [binder] _ in
            block(binder)
        }
    }
}

@dynamicMemberLookup
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public final class AnyBound<T>: Bound, ObservableObject {
    public init(_ value: T) {
        self.value = value
    }

    var value: T
    var realm: Realm?
    var _observe: ((inout RealmBind<T>, _ block: @escaping (RealmBind<T>) -> Void) -> NotificationToken)? = nil

    init(_ value: T, realm: Realm?) where T: Object {
        self.value = value
        self._observe = BoundObject(value).observe
        self.realm = realm
    }
    init<Element>(_ value: T, realm: Realm?) where T == Results<Element> {
        self.value = value
        self._observe = BoundResults(value).observe
        self.realm = realm
    }

    func observe(binder: inout RealmBind<T>, _ block: @escaping (RealmBind<T>) -> Void) -> NotificationToken {
        _observe!(&binder) { [block] binder in
            block(binder)
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
        get {
            Binding(get: {
                self.value[keyPath: member]
            }, set: { newValue in
                try! self.realm!.write {
                    self.value[keyPath: member] = newValue
                }
            })
        }
    }

    // if property is a list, we want to freeze it before fetching it
    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> where V: ListBase {
        get {
            Binding(get: {
                self.value[keyPath: member].freeze()
            }, set: {
                self.value[keyPath: member] = $0
            })
        }
    }
}

// MARK: Bindings


@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Binding where Value: Object {
    subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> {
        get {
            Binding<V>(get: {
                self.wrappedValue[keyPath: member]
            }, set: { newValue in
                try! wrappedValue.realm!.write {
                    self.wrappedValue[keyPath: member] = newValue
                }
            })
        }
    }

    subscript<V>(dynamicMember member: ReferenceWritableKeyPath<Value, V>) -> Binding<V> where V: ListBase {
        get {
            Binding<V>(get: {
                self.wrappedValue[keyPath: member].freeze()
            }, set: {
                self.wrappedValue[keyPath: member] = $0
            })
        }
    }
}


// Allows conformance with SwiftUI's `ForEach`
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding: Identifiable where Value: RealmCollectionValue, Value: Identifiable {
    public var id: Value.ID {
        return wrappedValue.id
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Binding: RandomAccessCollection,
                   Sequence,
                   Collection,
                   BidirectionalCollection where Value: RealmCollection,
                                                 Value: MutableCollection,
                                                 Value: RangeReplaceableCollection,
                                                 Value.Element: Identifiable {
    public var indices: Indices {
        wrappedValue.indices as! Binding<Value>.Indices
    }

    public typealias Element = Binding<Value.Element>
    public typealias FakeType = Array<Element>
    public typealias Index = Int

    public typealias SubSequence = Slice<Array<Element>>

    public typealias Indices = FakeType.Indices

    @frozen public struct BoundIterator: IteratorProtocol {
        private var generatorBase: NSFastEnumerationIterator

        init(collection: RLMCollection) {
            generatorBase = NSFastEnumerationIterator(collection)
        }

        /// Advance to the next element and return it, or `nil` if no next element exists.
        public mutating func next() -> Element? {
            let next = generatorBase.next()
            if next is NSNull {
                return Binding<Value.Element>(get: {
                    Value.Element._nilValue()
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
            return Binding<Value.Element>(get: {
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
        return wrappedValue.startIndex as! Binding<Value>.Index
    }

    public var endIndex: Index {
        return wrappedValue.endIndex as! Binding<Value>.Index
    }

    public subscript(position: Index) -> Element {
        get {
            Binding<Value.Element>(get: {
                let value = self.wrappedValue[position as! Value.Index]
                // if value is an Object, thaw it out as this list has been frozen
                if value.self is Object {
                    return (value as! Object).thaw() as! Value.Element
                } else {
                    return value
                }
            }, set: {
                self.wrappedValue[position as! Value.Index] = $0
            })
        }
    }

    // Method that returns the next index when iterating
    public func index(after i: Index) -> Index {
        return wrappedValue.index(after: i as! Value.Index) as! Binding<Value>.Index
    }

    public subscript(bounds: Range<Self.Index>) -> Self.SubSequence {
        let tmp = wrappedValue[Range<Value.Index>.init(uncheckedBounds: (bounds.lowerBound as! Value.Index,
                                                                         bounds.upperBound as! Value.Index))]
        return SubSequence(tmp.map { element in
            Element(get: { element }, set: { _ in fatalError() })
        })
    }

    /// :nodoc:
    public func remove(atOffsets offsets: IndexSet) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            var resolved = realm.resolve(ThreadSafeReference(to: wrappedValue))
            resolved!.remove(atOffsets: offsets)
        }
    }

    /// :nodoc:
    public func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            var resolved = realm.resolve(ThreadSafeReference(to: wrappedValue))
            resolved!.move(fromOffsets: offsets, toOffset: destination)
        }
    }

    public func append(_ value: Value.Element) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            var resolved = realm.resolve(ThreadSafeReference(to: wrappedValue))
            resolved!.append(value)
        }
    }
}

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
public struct RealmBind<T> : DynamicProperty {
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
