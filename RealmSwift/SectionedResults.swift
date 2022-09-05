////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

public struct SectionedResults<Key: _Persistable & Hashable, T: RealmCollectionValue>: RandomAccessCollection, Equatable {
    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int { 0 }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    public var endIndex: Int { count }

    let collection: RLMSectionedResults<AnyObject>
    let sectionBlock: ((T) -> Key)
    let valueProjector: ((Any) -> T)

    internal init(rlmSectionedResults: RLMSectionedResults<AnyObject>,
                  sectionBlock: @escaping ((T) -> Key),
                  valueProjector: @escaping ((Any) -> T)) {
        self.collection = rlmSectionedResults
        self.sectionBlock = sectionBlock
        self.valueProjector = valueProjector
    }

    public subscript(_ index: Int) -> Section<Key, T> {
        return Section<Key, T>(rlmSection: collection[UInt(index)], sectionBlock: sectionBlock)
    }

    public subscript(_ indexPath: IndexPath) -> Element {
        return self[indexPath.section][indexPath.item] as! SectionedResults<Key, T>.Element
    }

    public var count: Int { Int(collection.count) }

    public func observe(on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken {

        return collection.addNotificationBlock(wrapObserveBlock(block))
    }

    public func makeIterator() -> RLMSectionedResultsIterator<Key, T> {
        return RLMSectionedResultsIterator(collection: collection, sectionBlock: sectionBlock)
    }

    internal typealias ObjcSectionedResultsChange = (RLMSectionedResults<AnyObject>?, RLMSectionedResultsChange?, Error?) -> Void
    internal func wrapObserveBlock(_ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> ObjcSectionedResultsChange {
        var col: Self?
        return { collection, change, error in
            if col == nil, let collection = collection {
                col = self.collection === collection ? self : Self(rlmSectionedResults: collection, sectionBlock: sectionBlock, valueProjector: valueProjector)
            }
            block(RealmSectionedResultsChange.fromObjc(value: col, change: change, error: error))
        }
    }

    public static func == (lhs: SectionedResults<Key, T>, rhs: SectionedResults<Key, T>) -> Bool {
        return lhs.collection == rhs.collection
    }

    public var realm: Realm? { collection.realm.map(Realm.init) }
    public var isInvalidated: Bool { collection.isInvalidated }
    public var isFrozen: Bool { collection.isFrozen }
}

public struct Section<Key: _Persistable & Hashable, T: RealmCollectionValue>: RandomAccessCollection, Hashable, Identifiable {
    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int { 0 }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    public var endIndex: Int { count }

    public static func == (lhs: Section<Key, T>, rhs: Section<Key, T>) -> Bool {
        return lhs.collection == rhs.collection
    }


    let collection: RLMSection<AnyObject>
    let sectionBlock: ((T) -> Key)

    public var key: Key {
        return sectionBlock(collection[0] as! Element)
    }

    public var id: Key {
        return key
    }

    internal init(rlmSection: RLMSection<AnyObject>, sectionBlock: @escaping ((T) -> Key)) {
        self.collection = rlmSection
        self.sectionBlock = sectionBlock
    }

    public subscript(_ index: Int) -> T {
        return collection[UInt(index)] as! T
    }

    public var count: Int { Int(collection.count) }

    public func makeIterator() -> RLMSectionIterator<T> {
        return RLMSectionIterator(collection: collection)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    public var realm: Realm? { get {  fatalError() } }
    public var isInvalidated: Bool { get {  fatalError() } }
    public var isFrozen: Bool { get {  fatalError()  } }
    public func freeze() -> Section<Key, Element> { fatalError() }
    public func thaw() -> Self { fatalError() }
}

@frozen public enum RealmSectionedResultsChange<CollectionType> {
   /**
    `.initial` indicates that the initial run of the query has completed (if
    applicable), and the collection can now be used without performing any
    blocking work.
    */
   case initial(CollectionType)

   /**
    `.update` indicates that a write transaction has been committed which
    either changed which objects are in the collection, and/or modified one
    or more of the objects in the collection.

    All three of the change arrays are always sorted in ascending order.

    - parameter deletions:     The indices in the previous version of the collection which were removed from this one.
    - parameter insertions:    The indices in the new collection which were added in this version.
    - parameter modifications: The indices of the objects which were modified in the previous version of this collection.
    */
    case update(CollectionType, deletions: [IndexPath], insertions: [IndexPath], modifications: [IndexPath], sectionsToInsert: IndexSet, sectionsToDelete: IndexSet)

   /**
    If an error occurs, notification blocks are called one time with a `.error`
    result and an `NSError` containing details about the error. This can only
    currently happen if opening the Realm on a background thread to calcuate
    the change set fails. The callback will never be called again after it is
    invoked with a .error value.
    */
   case error(Error)

    static func fromObjc(value: CollectionType?, change: RLMSectionedResultsChange?, error: Error?) -> RealmSectionedResultsChange {
        if let error = error {
            return .error(error)
        }
        if let change = change {
            return .update(value!,
                deletions: change.deletions as [IndexPath],
                insertions: change.insertions as [IndexPath],
                modifications: change.modifications as [IndexPath],
                           sectionsToInsert: change.sectionsToInsert,
                           sectionsToDelete: change.sectionsToRemove)
        }
        return .initial(value!)
    }
}

/**
 An iterator for a `SectionedResults` instance.
 */
@frozen public struct RLMSectionedResultsIterator<Key: _Persistable & Hashable, Element: RealmCollectionValue>: IteratorProtocol {
    private var generatorBase: NSFastEnumerationIterator
    private let sectionBlock: ((Element) -> Key)

    init(collection: RLMSectionedResults<AnyObject>, sectionBlock: @escaping ((Element) -> Key)) {
        generatorBase = NSFastEnumerationIterator(collection)
        self.sectionBlock = sectionBlock
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public mutating func next() -> Section<Key, Element>? {
        guard let next = generatorBase.next() else { return nil }
        return Section<Key, Element>(rlmSection: next as! RLMSection<AnyObject>, sectionBlock: sectionBlock)
    }
}

/**
 An iterator for a `Section` instance.
 */
@frozen public struct RLMSectionIterator<Element: RealmCollectionValue>: IteratorProtocol {
    private var generatorBase: NSFastEnumerationIterator

    init(collection: RLMSection<AnyObject>) {
        generatorBase = NSFastEnumerationIterator(collection)
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public mutating func next() -> Element? {
        guard let next = generatorBase.next() else { return nil }
        return next as? Element
    }
}
