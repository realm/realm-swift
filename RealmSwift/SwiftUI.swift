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
public class RealmBinding<T>: ObservableObject {
    public var realm: Realm!
    var token: NotificationToken?

    fileprivate var _wrappedValue: T!
    public var wrappedValue: T {
        get {
            print("WRAPPED VALUE FETCHED")
            return _wrappedValue
        }
        set {
            _wrappedValue = newValue
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> V {
        get {
            print(#function)
            return self.wrappedValue[keyPath: member]
        } set {
            try! self.realm.write {
                self.wrappedValue[keyPath: member] = newValue
            }
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> Binding<V> {
        get {
            print(#function)
            return Binding(get: {
                self.wrappedValue[keyPath: member]
            },
            set: { newValue in
                try! self.realm.write {
                    self.wrappedValue[keyPath: member] = newValue
                }
            })
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> RealmBinding<V> where V: EmbeddedObject {
        get {
            EmbeddedObjectBinding<V>(wrappedValue[keyPath: member], realm: realm)
        }
    }

    public subscript<V>(dynamicMember member: ReferenceWritableKeyPath<T, V>) -> RealmBinding<V> where V: Object {
        get {
            ObjectBinding<V>(wrappedValue[keyPath: member], realm: realm)
        }
    }

    public subscript<CollectionType, Element: RealmCollectionValue>(dynamicMember member: ReferenceWritableKeyPath<T, CollectionType>) -> RealmBinding<CollectionType> where CollectionType: List<Element> {
        get {
            CollectionBinding<CollectionType>(self.wrappedValue[keyPath: member].freeze(), realm: realm)
        }
    }

    public subscript<Res: AnyResultsBase>(dynamicMember member: ReferenceWritableKeyPath<T, Res>) -> ResultsBinding<Res.Element> {
        get {
            ResultsBinding<Res.Element>((self.wrappedValue[keyPath: member] as! Results<Res.Element>).freeze(), realm: realm)
        }
    }

    var outOfSyncCount = 0
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public class CollectionBinding<CollectionType: RealmCollection>: RealmBinding<CollectionType> {
    init(_ value: CollectionType, realm: Realm) {
        super.init()
        self._wrappedValue = value
        self.realm = realm
        if !value.isFrozen {
            self.token = value.observe(on: nil) { _ in self.objectWillChange.send() }
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public class EmbeddedObjectBinding<T: EmbeddedObject>: RealmBinding<T> {
    init(_ value: T, realm: Realm) {
        super.init()
        self._wrappedValue = value
        self.realm = realm
        if !value.isFrozen {
            self.token = value.observe { _ in self.objectWillChange.send() }
        }
    }
}

@dynamicMemberLookup
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public class ObjectBinding<T: Object>: RealmBinding<T> {
    init(_ value: T, realm: Realm) where T: Object {
        super.init()
        self.realm = realm
        if !value.isFrozen {
            self.token = value.observe { _ in
                self.objectWillChange.send()
                guard let thawed = self._wrappedValue.thaw() else {
                    return
                }
                self._wrappedValue = thawed.freeze()
            }
        }
        self._wrappedValue = value.freeze()
    }
}

// MARK: ResultsBinding
@dynamicMemberLookup
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public class ResultsBinding<Element: RealmCollectionValue>: RealmBinding<Results<Element>> {
    /// :nodoc:
    public func remove(atOffsets offsets: IndexSet) {
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        let resolved = wrappedValue.thaw()
        try! realm.write {
            resolved![offsets].forEach {
                realm.delete($0 as! EmbeddedObject)
            }
//            realm.delete(resolved[offsets])
        }
//        self.objectWillChange.send()
    }

    var lastSnapshot: Results<Element>?
    var isStaleVersionRequested = false

    public override var wrappedValue: Results<Element> {
        get {
            _wrappedValue
        }
        set {
            _wrappedValue = newValue
        }
    }

    init(_ value: Results<Element>, realm: Realm) {
        super.init()
        self._wrappedValue = value.freeze()
        self.realm = realm
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding: MutableCollection where T: RealmCollection {
    public func swapAt(_ i: T.Index, _ j: T.Index) {
        fatalError()
    }
    public func partition(by belongsInSecondPartition: (T.Element) throws -> Bool) rethrows -> T.Index {
        fatalError()
    }
    public subscript<R>(r: R) -> SubSequence where R : RangeExpression, Index == R.Bound {
fatalError()
    }

    public subscript(x: (UnboundedRange_) -> ()) -> SubSequence {
        fatalError()
    }
    public func distance(from start: T.Index, to end: T.Index) -> Int {
        print("DISTANCE")
        print(end)
        print(self.endIndex)
        if end > self.endIndex {
            (self as! ResultsBinding<T.Element>).isStaleVersionRequested = true
        }
        return (end as! Int) - (start as! Int)
    }
//    public static func == (lhs: RealmBinding<T>, rhs: RealmBinding<T>) -> Bool {
//        print(#function)
//
//        var equals = lhs.wrappedValue.thaw()!.count == rhs.wrappedValue.count
//        equals = equals && lhs.wrappedValue.count == rhs.wrappedValue.thaw()!.count
//        if lhs.wrappedValue.count != (lhs as! ResultsBinding<T.Element>).lastSnapshot?.count {
//            print("🚨 EQUALITY Failed 🚨")
////            if lhs.outOfSyncCount > 7 {
////                rhs.wrappedValue = lhs.wrappedValue.thaw()!
////                lhs.outOfSyncCount = 0
////            }
////            lhs.outOfSyncCount += 1
////            print("outOfSync: \(lhs.outOfSyncCount) actual count: \(lhs.count)")
//        }
//
//
//        return equals
//    }

    public subscript(position: Index) -> Element {
        get {
            print(#function)
            print("SUBSCRIPT ACTIVATED FOR IDX: \(position) with size \(self.count)")
            var wrapped = self.wrappedValue

            if (self as! ResultsBinding<T.Element>).isStaleVersionRequested, let snapShot = (self as! ResultsBinding<T.Element>).lastSnapshot {
                wrapped = snapShot as! T
            }
//            if position >= endIndex {
//                let snap = (self as! ResultsBinding<T.Element>).lastSnapshot!
//                return snap[snap.index(before: position as! Int)]
////                return self.wrappedValue[index(before: position)]
//            }
            let value = wrapped[position]
            if let value = (value as? ThreadConfined)?.thaw() {
                return value as! T.Element
            } else {
                return value as! RealmBinding<T>.Element
            }
        }
        set {
            fatalError("should not set")
        }
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        fatalError()
    }

    public typealias SubSequence = Slice<RealmBinding<T>>
//    public subscript(bounds: Range<RealmBinding.Index>) -> SubSequence {
//        get {
//            fatalError()
//        }
//        set {
//            fatalError()
//        }
//    }
    public func filter(_ predicateFormat: String, _ args: Any...) -> ResultsBinding<T.Element> {
        return ResultsBinding<T.Element>(self.wrappedValue.filter(predicateFormat, args).freeze(), realm: realm)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding: RandomAccessCollection, BidirectionalCollection, Collection, Sequence where T: RealmCollection {
    public func index(before i: Index) -> Index {
        return wrappedValue.index(before: i)
    }

    public func index(after i: Index) -> Index {
        return wrappedValue.index(after: i)
    }

    public var indices: Indices {
        return wrappedValue.indices
    }

    public typealias Element = T.Element
    public typealias Index = T.Index

//    public typealias SubSequence = Slice<RealmBinding<T>>

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
        return wrappedValue.thaw()!.startIndex
    }
    public var endIndex: Index {
        return wrappedValue.endIndex
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding where T: ListBase, T: RealmCollection {
    /// :nodoc:
    public func remove(atOffsets offsets: IndexSet) {
        // TODO: use thaw function
        print(#function)
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
        // TODO: use thaw function
        let realm = try! Realm(configuration: wrappedValue.realm!.configuration)
        try! realm.write {
            realm.add(value)
        }
        self.objectWillChange.send()
        self.wrappedValue = wrappedValue.thaw()!.freeze()
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmBinding where T: AnyResultsBase {
    /// :nodoc:
    public func remove(atOffsets offsets: IndexSet) {
        print ("REMOVE CALLED")
        // TODO: use thaw function
        let value = wrappedValue as! Results<T.Element>
        let realm = try! Realm(configuration: value.realm!.configuration)
        let resolved = value.thaw()
        try! realm.write {
            resolved![offsets].forEach {
                realm.delete($0 as! Object)
            }
//            realm.delete(resolved[offsets])
        }

        self.objectWillChange.send()

        (self as! ResultsBinding<T.Element>).lastSnapshot = value
        self.wrappedValue = resolved!.freeze() as! T
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
        _wrappedValue = ObservedObject(wrappedValue: EmbeddedObjectBinding(wrappedValue, realm: wrappedValue.realm!))
    }

    public init(wrappedValue: T) where T: Object {
        _wrappedValue = ObservedObject(wrappedValue: ObjectBinding(wrappedValue, realm: wrappedValue.realm!))
    }

    public init(wrappedValue: T) where T: RealmCollection {
        _wrappedValue = ObservedObject(wrappedValue: CollectionBinding(wrappedValue.freeze(), realm: wrappedValue.realm!))
    }

    public init<U: Object>(_ type: U.Type, filter: NSPredicate? = nil, realm: Realm? = nil) where T == Results<U> {
        if let realm = realm {
            _wrappedValue = ObservedObject(wrappedValue: ResultsBinding(realm.objects(U.self), realm: realm))
        } else {
            let realm = Environment(\.realm).wrappedValue
            let results = filter == nil ? realm.objects(U.self) : realm.objects(U.self).filter(filter!)
            _wrappedValue = ObservedObject(wrappedValue: ResultsBinding(results, realm: realm))
        }
    }

    public mutating func update() {
        print(#function)
    }

    public static subscript<EnclosingSelf>(
          _enclosingInstance observed: EnclosingSelf,
          wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
          storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>) -> T {
          get {
            return observed[keyPath: storageKeyPath].wrappedValue
          }
          set {
            observed[keyPath: storageKeyPath].wrappedValue = newValue
          }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealmState where T: AnyResultsBase, T.Element: Object {
    public var wrappedValue: T {
        print("\(#function) IN REALM RESULTS BINDING")
        return Environment(\.realm).wrappedValue.objects(T.Element.self) as! T
    }

    public var projectedValue: ResultsBinding<T.Element> {
        _wrappedValue.wrappedValue as! ResultsBinding<T.Element>
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension DynamicViewContent where Data: AnyResultsBase {
//    public func onDelete(perform action: ((IndexSet) -> Void)?) -> some DynamicViewContent {
////        action!(<#IndexSet#>)
//        return self
//    }
}
#endif
