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

public protocol RealmSectionKey: _ObjcBridgeable { }

///  A type which can appear in a Realm collection inside an Optional.
///
/// :nodoc:
public protocol _RealmSectionKeyInsideOptional: RealmSectionKey {}

extension Int: _RealmSectionKeyInsideOptional {}
extension Int8: _RealmSectionKeyInsideOptional {}
extension Int16: _RealmSectionKeyInsideOptional {}
extension Int32: _RealmSectionKeyInsideOptional {}
extension Int64: _RealmSectionKeyInsideOptional {}
extension Float: _RealmSectionKeyInsideOptional {}
extension Double: _RealmSectionKeyInsideOptional {}
extension Bool: _RealmSectionKeyInsideOptional {}
extension String: _RealmSectionKeyInsideOptional {}
extension Date: _RealmSectionKeyInsideOptional {}
extension Decimal128: _RealmSectionKeyInsideOptional {}
extension ObjectId: _RealmSectionKeyInsideOptional {}
extension UUID: _RealmSectionKeyInsideOptional {}
extension AnyRealmValue: _RealmSectionKeyInsideOptional {}
extension Character: _RealmSectionKeyInsideOptional {
    public static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Character? {
        // unused method
        fatalError()
    }

    public var _rlmObjcValue: Any {
        return String(self) as NSString
    }
}

extension Optional: RealmSectionKey where Wrapped: _RealmSectionKeyInsideOptional { }

public struct SectionedResults<Element: RealmCollectionValue, Key>: Sequence {

    let collection: RLMSectionedResults<AnyObject>
    let keyPath: KeyPath<Element, Key>

    internal init(rlmSectionedResults: RLMSectionedResults<AnyObject>, keyPath: KeyPath<Element, Key>) {
        self.collection = rlmSectionedResults
        self.keyPath = keyPath
    }

    public subscript(_ index: Int) -> Section<Element, Key> {
        return Section<Element, Key>(rlmSection: collection[UInt(index)], keyPath: keyPath)
    }

    public subscript(_ indexPath: IndexPath) -> Element {
        return self[indexPath.section][indexPath.item]
    }

    public var count: Int { Int(collection.count) }

    public func observe(on queue: DispatchQueue? = nil,
                        _ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> NotificationToken {

        return collection.addNotificationBlock(wrapObserveBlock(block))
    }

    public func makeIterator() -> RLMSectionedResultsIterator<Element, Key> {
        return RLMSectionedResultsIterator(collection: collection, keyPath: keyPath)
    }



    internal typealias ObjcSectionedResultsChange = (RLMSectionedResults<AnyObject>?, RLMSectionedResultsChange?, Error?) -> Void
    internal func wrapObserveBlock(_ block: @escaping (RealmSectionedResultsChange<Self>) -> Void) -> ObjcSectionedResultsChange {
        var col: Self?
        return { collection, change, error in
            if col == nil, let collection = collection {
                col = self.collection === collection ? self : Self(rlmSectionedResults: collection, keyPath: keyPath)
            }
            block(RealmSectionedResultsChange.fromObjc(value: col, change: change, error: error))
        }
    }
}

public struct Section<Element: RealmCollectionValue, Key>: Sequence {

    let collection: RLMSection<AnyObject>
    let keyPath: KeyPath<Element, Key>

    public var key: Key {
        // There should always be a least one element in a section.
        return (collection[0] as! Element)[keyPath: keyPath]
    }

    internal init(rlmSection: RLMSection<AnyObject>, keyPath: KeyPath<Element, Key>) {
        self.collection = rlmSection
        self.keyPath = keyPath
    }

    public subscript(_ index: Int) -> Element {
        return collection[UInt(index)] as! Element
    }

    public var count: Int { Int(collection.count) }

    public func makeIterator() -> RLMSectionIterator<Element> {
        return RLMSectionIterator(collection: collection)
    }
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
                           sectionsToInsert: IndexSet(change.sectionsToInsert.map { $0 as! Int }),
                           sectionsToDelete: IndexSet(change.sectionsToRemove.map { $0 as! Int }))
        }
        return .initial(value!)
    }
}

/**
 An iterator for a `SectionedResults` instance.
 */
@frozen public struct RLMSectionedResultsIterator<Element: RealmCollectionValue, Key>: IteratorProtocol {
    private var generatorBase: NSFastEnumerationIterator
    private let keyPath: KeyPath<Element, Key>

    init(collection: RLMSectionedResults<AnyObject>, keyPath: KeyPath<Element, Key>) {
        generatorBase = NSFastEnumerationIterator(collection)
        self.keyPath = keyPath
    }

    /// Advance to the next element and return it, or `nil` if no next element exists.
    public mutating func next() -> Section<Element, Key>? {
        guard let next = generatorBase.next() else { return nil }
        return Section<Element, Key>(rlmSection: next as! RLMSection<AnyObject>, keyPath: keyPath)
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
