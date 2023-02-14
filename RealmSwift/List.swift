////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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
import Realm.Private

/**
 `List` is the container type in Realm used to define to-many relationships.

 Like Swift's `Array`, `List` is a generic type that is parameterized on the type it stores. This can be either an `Object`
 subclass or one of the following types: `Bool`, `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `Float`, `Double`,
 `String`, `Data`, `Date`, `Decimal128`, and `ObjectId` (and their optional versions)

 Unlike Swift's native collections, `List`s are reference types, and are only immutable if the Realm that manages them
 is opened as read-only.

 Lists can be filtered and sorted with the same predicates as `Results<Element>`.

 Properties of `List` type defined on `Object` subclasses must be declared as `let` and cannot be `dynamic`.
 */
public final class List<Element: RealmCollectionValue>: RLMSwiftCollectionBase, RealmCollectionImpl {
    internal var lastAccessedNames: NSMutableArray?

    internal var rlmArray: RLMArray<AnyObject> {
        unsafeDowncast(collection, to: RLMArray<AnyObject>.self)
    }
    internal var collection: RLMCollection {
        _rlmCollection
    }

    // MARK: Initializers

    /// Creates a `List` that holds Realm model objects of type `Element`.
    public override init() {
        super.init()
    }
    /// :nodoc:
    public override init(collection: RLMCollection) {
        super.init(collection: collection)
    }

    // MARK: Object Retrieval

    /**
     Returns the object at the given index (get), or replaces the object at the given index (set).

     - warning: You can only set an object during a write transaction.

     - parameter index: The index of the object to retrieve or replace.
     */
    public subscript(position: Int) -> Element {
        get {
            if let lastAccessedNames = lastAccessedNames {
                return elementKeyPathRecorder(for: Element.self, with: lastAccessedNames)
            }
            throwForNegativeIndex(position)
            return staticBridgeCast(fromObjectiveC: _rlmCollection.object(at: UInt(position)))
        }
        set {
            throwForNegativeIndex(position)
            rlmArray.replaceObject(at: UInt(position), with: staticBridgeCast(fromSwift: newValue) as AnyObject)
        }
    }

    // MARK: KVC

    /**
     Returns an `Array` containing the results of invoking `valueForKey(_:)` using `key` on each of the collection's
     objects.
     */
    @nonobjc public func value(forKey key: String) -> [AnyObject] {
        return rlmArray.value(forKeyPath: key)! as! [AnyObject]
    }

    /**
     Returns an `Array` containing the results of invoking `valueForKeyPath(_:)` using `keyPath` on each of the
     collection's objects.

     - parameter keyPath: The key path to the property whose values are desired.
     */
    @nonobjc public func value(forKeyPath keyPath: String) -> [AnyObject] {
        return rlmArray.value(forKeyPath: keyPath) as! [AnyObject]
    }

    // MARK: Mutation

    /**
     Appends the given object to the end of the list.

     If the object is managed by a different Realm than the receiver, a copy is made and added to the Realm managing
     the receiver.

     - warning: This method may only be called during a write transaction.

     - parameter object: An object.
     */
    public func append(_ object: Element) {
        rlmArray.add(staticBridgeCast(fromSwift: object) as AnyObject)
    }

    /**
     Appends the objects in the given sequence to the end of the list.

     - warning: This method may only be called during a write transaction.
    */
    public func append<S: Sequence>(objectsIn objects: S) where S.Iterator.Element == Element {
        for obj in objects {
            rlmArray.add(staticBridgeCast(fromSwift: obj) as AnyObject)
        }
    }

    /**
     Inserts an object at the given index.

     - warning: This method may only be called during a write transaction.

     - warning: This method will throw an exception if called with an invalid index.

     - parameter object: An object.
     - parameter index:  The index at which to insert the object.
     */
    public func insert(_ object: Element, at index: Int) {
        throwForNegativeIndex(index)
        rlmArray.insert(staticBridgeCast(fromSwift: object) as AnyObject, at: UInt(index))
    }

    /**
     Removes an object at the given index. The object is not removed from the Realm that manages it.

     - warning: This method may only be called during a write transaction.

     - warning: This method will throw an exception if called with an invalid index.

     - parameter index: The index at which to remove the object.
     */
    public func remove(at index: Int) {
        throwForNegativeIndex(index)
        rlmArray.removeObject(at: UInt(index))
    }

    /**
     Removes all objects from the list. The objects are not removed from the Realm that manages them.

     - warning: This method may only be called during a write transaction.
     */
    public func removeAll() {
        rlmArray.removeAllObjects()
    }

    /**
     Replaces an object at the given index with a new object.

     - warning: This method may only be called during a write transaction.

     - warning: This method will throw an exception if called with an invalid index.

     - parameter index:  The index of the object to be replaced.
     - parameter object: An object.
     */
    public func replace(index: Int, object: Element) {
        throwForNegativeIndex(index)
        rlmArray.replaceObject(at: UInt(index), with: staticBridgeCast(fromSwift: object) as AnyObject)
    }

    /**
     Moves the object at the given source index to the given destination index.

     - warning: This method may only be called during a write transaction.

     - warning: This method will throw an exception if called with invalid indices.

     - parameter from:  The index of the object to be moved.
     - parameter to:    index to which the object at `from` should be moved.
     */
    public func move(from: Int, to: Int) {
        throwForNegativeIndex(from)
        throwForNegativeIndex(to)
        rlmArray.moveObject(at: UInt(from), to: UInt(to))
    }

    /**
     Exchanges the objects in the list at given indices.

     - warning: This method may only be called during a write transaction.

     - warning: This method will throw an exception if called with invalid indices.

     - parameter index1: The index of the object which should replace the object at index `index2`.
     - parameter index2: The index of the object which should replace the object at index `index1`.
     */
    public func swapAt(_ index1: Int, _ index2: Int) {
        throwForNegativeIndex(index1, parameterName: "index1")
        throwForNegativeIndex(index2, parameterName: "index2")
        rlmArray.exchangeObject(at: UInt(index1), withObjectAt: UInt(index2))
    }

    @objc class func _unmanagedCollection() -> RLMArray<AnyObject> {
        if let type = Element.self as? ObjectBase.Type {
            return RLMArray(objectClassName: type.className())
        }
        if let type = Element.PersistedType.self as? ObjectBase.Type {
            return RLMArray(objectClassName: type.className())
        }
        if let type = Element.PersistedType.self as? _RealmSchemaDiscoverable.Type {
            return RLMArray(objectType: type._rlmType, optional: type._rlmOptional)
        }
        fatalError("Collections of projections must be used with @Projected.")
    }

    /// :nodoc:
    @objc public override class func _backingCollectionType() -> AnyClass {
        return RLMManagedArray.self
    }

    // Printable requires a description property defined in Swift (and not obj-c),
    // and it has to be defined as override, which can't be done in a
    // generic class.
    /// Returns a human-readable description of the objects contained in the List.
    @objc public override var description: String {
        return descriptionWithMaxDepth(RLMDescriptionMaxDepth)
    }

    @objc private func descriptionWithMaxDepth(_ depth: UInt) -> String {
        return RLMDescriptionWithMaxDepth("List", _rlmCollection, depth)
    }
}

extension List {
    /**
     Replace the given `subRange` of elements with `newElements`.

     - parameter subrange:    The range of elements to be replaced.
     - parameter newElements: The new elements to be inserted into the List.
     */
    public func replaceSubrange<C: Collection, R>(_ subrange: R, with newElements: C)
        where C.Iterator.Element == Element, R: RangeExpression, List<Element>.Index == R.Bound {
            let subrange = subrange.relative(to: self)
            for _ in subrange.lowerBound..<subrange.upperBound {
                remove(at: subrange.lowerBound)
            }
            for x in newElements.reversed() {
                insert(x, at: subrange.lowerBound)
            }
    }
}

// MARK: - MutableCollection conformance, range replaceable collection emulation
extension List: MutableCollection {
    public typealias SubSequence = Slice<List>

    /**
     Returns the objects at the given range (get), or replaces the objects at the
     given range with new objects (set).

     - warning: Objects may only be set during a write transaction.

     - parameter index: The index of the object to retrieve or replace.
     */
    public subscript(bounds: Range<Int>) -> SubSequence {
        get {
            return SubSequence(base: self, bounds: bounds)
        }
        set {
            replaceSubrange(bounds.lowerBound..<bounds.upperBound, with: newValue)
        }
    }

    /**
     Removes the specified number of objects from the beginning of the list. The
     objects are not removed from the Realm that manages them.

     - warning: This method may only be called during a write transaction.
     */
    public func removeFirst(_ number: Int = 1) {
        throwForNegativeIndex(number)
        let count = Int(_rlmCollection.count)
        guard number <= count else {
            throwRealmException("It is not possible to remove more objects (\(number)) from a list"
                + " than it already contains (\(count)).")
        }
        for _ in 0..<number {
            rlmArray.removeObject(at: 0)
        }
    }

    /**
     Removes the specified number of objects from the end of the list. The objects
     are not removed from the Realm that manages them.

     - warning: This method may only be called during a write transaction.
     */
    public func removeLast(_ number: Int = 1) {
        throwForNegativeIndex(number)
        let count = Int(_rlmCollection.count)
        guard number <= count else {
            throwRealmException("It is not possible to remove more objects (\(number)) from a list"
                + " than it already contains (\(count)).")
        }
        for _ in 0..<number {
            rlmArray.removeLastObject()
        }
    }

    /**
     Inserts the items in the given collection into the list at the given position.

     - warning: This method may only be called during a write transaction.
     */
    public func insert<C: Collection>(contentsOf newElements: C, at i: Int) where C.Iterator.Element == Element {
        var currentIndex = i
        for item in newElements {
            insert(item, at: currentIndex)
            currentIndex += 1
        }
    }
    /**
     Removes objects from the list at the given range.

     - warning: This method may only be called during a write transaction.
     */
    public func removeSubrange<R>(_ boundsExpression: R) where R: RangeExpression, List<Element>.Index == R.Bound {
        let bounds = boundsExpression.relative(to: self)
        for _ in bounds {
            remove(at: bounds.lowerBound)
        }
    }
    /// :nodoc:
    public func remove(atOffsets offsets: IndexSet) {
        for offset in offsets.reversed() {
            remove(at: offset)
        }
    }
    /// :nodoc:
    public func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        for offset in offsets {
            var d = destination
            if destination > offset {
                d = destination - 1
            }
            move(from: offset, to: d)
        }
    }

    /// :nodoc:
    public func makeIterator() -> RLMIterator<Element> {
        return RLMIterator(collection: collection)
    }
}

// MARK: - Codable

extension List: Decodable where Element: Decodable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            append(try container.decode(Element.self))
        }
    }
}

extension List: Encodable where Element: Encodable {}
