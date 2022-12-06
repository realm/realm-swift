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
import Realm

// RealmCollectionImpl implements all of the RealmCollection protocol except for
// description and single-element subscript. description actually varies between
// the collection wrappers, and Sequence infers its associated types from subscript,
// so moving that here requires defining those explicitly in each collection.
//
// The functions don't need to be documented here because Xcode/DocC inherit
// the documentation from the RealmCollection protocol definition, and jazzy
// excludes this file entirely.
internal protocol RealmCollectionImpl: RealmCollection where Index == Int, SubSequence == Slice<Self>, Iterator == RLMIterator<Element> {
    var collection: RLMCollection { get }
    init(collection: RLMCollection)
}
extension RealmCollectionImpl {
    public var realm: Realm? { collection.realm.map(Realm.init) }
    public var isInvalidated: Bool { collection.isInvalidated }
    public var count: Int { Int(collection.count) }

    public subscript(bounds: Range<Self.Index>) -> SubSequence {
        return SubSequence(base: self, bounds: bounds)
    }
    public var first: Element? {
        return collection.firstObject!().map(staticBridgeCast)
    }
    public var last: Element? {
        return collection.lastObject!().map(staticBridgeCast)
    }
    public func objects(at indexes: IndexSet) -> [Element] {
        guard let r = collection.objects!(at: indexes) else {
            throwRealmException("Indexes for collection are out of bounds.")
        }
        return r.map(staticBridgeCast)
    }

    public func index(of object: Element) -> Int? {
        if let indexOf = collection.index(of:) {
            return notFoundToNil(index: indexOf(staticBridgeCast(fromSwift: object) as AnyObject))
        }
        fatalError("Collection does not support index(of:)")
    }
    public func index(matching predicate: NSPredicate) -> Int? {
        if let indexMatching = collection.indexOfObject(with:) {
            return notFoundToNil(index: indexMatching(predicate))
        }
        fatalError("Collection does not support index(matching:)")
    }

    public func filter(_ predicate: NSPredicate) -> Results<Element> {
        return Results<Element>(collection.objects(with: predicate))
    }

    public func sorted<S: Sequence>(by sortDescriptors: S) -> Results<Element>
        where S.Iterator.Element == SortDescriptor {
            return Results<Element>(collection.sortedResults(using: sortDescriptors.map { $0.rlmSortDescriptorValue }))
    }

    public func distinct<S: Sequence>(by keyPaths: S) -> Results<Element>
        where S.Iterator.Element == String {
            return Results<Element>(collection.distinctResults(usingKeyPaths: Array(keyPaths)))
    }

    public func min<T: _HasPersistedType>(ofProperty property: String) -> T? where T.PersistedType: MinMaxType {
        return collection.min(ofProperty: property).map(staticBridgeCast)
    }
    public func max<T: _HasPersistedType>(ofProperty property: String) -> T? where T.PersistedType: MinMaxType {
        return collection.max(ofProperty: property).map(staticBridgeCast)
    }
    public func sum<T: _HasPersistedType>(ofProperty property: String) -> T where T.PersistedType: AddableType {
        return staticBridgeCast(fromObjectiveC: collection.sum(ofProperty: property))
    }
    public func average<T: _HasPersistedType>(ofProperty property: String) -> T? where T.PersistedType: AddableType {
        return collection.average(ofProperty: property).map(staticBridgeCast)
    }

    public func value(forKey key: String) -> Any? {
        return collection.value(forKey: key)
    }
    public func value(forKeyPath keyPath: String) -> Any? {
        return collection.value(forKeyPath: keyPath)
    }
    public func setValue(_ value: Any?, forKey key: String) {
        return collection.setValue(value, forKey: key)
    }

    public func observe(keyPaths: [String]? = nil,
                        on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmCollectionChange<Self>) -> Void) -> NotificationToken {
        return collection.addNotificationBlock(wrapObserveBlock(block), keyPaths: keyPaths, queue: queue)
    }
    public func observe(on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmCollectionChange<Self>) -> Void) -> NotificationToken {
        return collection.addNotificationBlock(wrapObserveBlock(block), keyPaths: nil, queue: queue)
    }
    public func observe<T: ObjectBase>(keyPaths: [PartialKeyPath<T>],
                                       on queue: DispatchQueue? = nil,
                                       _ block: @escaping (RealmCollectionChange<Self>) -> Void) -> NotificationToken {
        return collection.addNotificationBlock(wrapObserveBlock(block), keyPaths: keyPaths.map(_name(for:)), queue: queue)
    }
    // We want to pass the same object instance to the change callback each time.
    // If the callback is being called on the source thread the instance should
    // be `self`, but if it's on a different thread it needs to be a new Swift
    // wrapper for the obj-c type, which we'll construct the first time the
    // callback is called.
    internal typealias ObjcCollectionChange = (RLMCollection?, RLMCollectionChange?, Error?) -> Void
    internal func wrapObserveBlock(_ block: @escaping (RealmCollectionChange<Self>) -> Void) -> ObjcCollectionChange {
        var col: Self?
        return { collection, change, error in
            if col == nil, let collection = collection {
                col = self.collection === collection ? self : Self(collection: collection)
            }
            block(RealmCollectionChange.fromObjc(value: col, change: change, error: error))
        }
    }


    public var isFrozen: Bool {
        return collection.isFrozen
    }
    public func freeze() -> Self {
        return Self(collection: collection.freeze())
    }
    public func thaw() -> Self? {
        return Self(collection: collection.thaw())
    }

    public func sectioned<Key: _Persistable>(sortDescriptors: [SortDescriptor],
                                             _ keyBlock: @escaping ((Element) -> Key)) -> SectionedResults<Key, Element> {
        if sortDescriptors.isEmpty {
            throwRealmException("There must be at least one SortDescriptor when using SectionedResults.")
        }
        let sectionedResults = collection.sectionedResults(using: sortDescriptors.map(ObjectiveCSupport.convert)) { value in
            return keyBlock(Element._rlmFromObjc(value)!)._rlmObjcValue as? RLMValue
        }

        return SectionedResults(rlmSectionedResult: sectionedResults)
    }
}

// A helper protocol which lets us check for Optional in where clauses
public protocol OptionalProtocol {
    associatedtype Wrapped
    func _rlmInferWrappedType() -> Wrapped
}

extension Optional: OptionalProtocol {
    public func _rlmInferWrappedType() -> Wrapped { return self! }
}
