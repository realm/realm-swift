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

import Foundation
import Realm
import Realm.Private

/**
 `MutableSet` is the container type in Realm used to define to-many relationships with distinct values as objects.

 Like Swift's `Set`, `MutableSet` is a generic type that is parameterized on the type it stores. This can be either an `Object`
 subclass or one of the following types: `Bool`, `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `Float`, `Double`,
 `String`, `Data`, `Date`, `Decimal128`, and `ObjectId` (and their optional versions)

 Unlike Swift's native collections, `MutableSet`s are reference types, and are only immutable if the Realm that manages them
 is opened as read-only.

 MutableSet's can be filtered and sorted with the same predicates as `Results<Element>`.

 Properties of `MutableSet` type defined on `Object` subclasses must be declared as `let` and cannot be `dynamic`.
 */
public final class MutableSet<Element: RealmCollectionValue>: RLMSwiftCollectionBase, RealmCollectionImpl {
    internal var lastAccessedNames: NSMutableArray?

    internal var rlmSet: RLMSet<AnyObject> {
        unsafeDowncast(_rlmCollection, to: RLMSet.self)
    }
    internal var collection: RLMCollection {
        _rlmCollection
    }

    // MARK: Initializers

    /// Creates a `MutableSet` that holds Realm model objects of type `Element`.
    public override init() {
        super.init()
    }
    /// :nodoc:
    public override init(collection: RLMCollection) {
        super.init(collection: collection)
    }

    // MARK: KVC

    /**
     Returns an `Array` containing the results of invoking `valueForKey(_:)` using `key` on each of the collection's
     objects.
     */
    @nonobjc public func value(forKey key: String) -> [AnyObject] {
        return (rlmSet.value(forKeyPath: key)! as! NSSet).allObjects as [AnyObject]
    }

    // MARK: Object Retrieval
    /**
     - warning: Ordering is not guaranteed on a MutableSet. Subscripting is implement
                convenience should not be relied on.
     */
    public subscript(position: Int) -> Element {
        if let lastAccessedNames = lastAccessedNames {
            return elementKeyPathRecorder(for: Element.self, with: lastAccessedNames)
        }

        throwForNegativeIndex(position)
        return staticBridgeCast(fromObjectiveC: rlmSet.object(at: UInt(position)))
    }

    // MARK: Filtering

    /**
     Returns a Boolean value indicating whether the Set contains the
     given object.

     - parameter object: The element to find in the MutableSet.
     */
    public func contains(_ object: Element) -> Bool {
        return rlmSet.contains(staticBridgeCast(fromSwift: object) as AnyObject)
    }

    /**
     Returns a Boolean value that indicates whether this set is a subset
     of the given set.

     - Parameter object: Another MutableSet to compare.
     */
    public func isSubset(of possibleSuperset: MutableSet<Element>) -> Bool {
        return rlmSet.isSubset(of: possibleSuperset.rlmSet)
    }

    /**
     Returns a Boolean value that indicates whether this set intersects
     with another given set.

     - Parameter object: Another MutableSet to compare.
     */
    public func intersects(_ otherSet: MutableSet<Element>) -> Bool {
        return rlmSet.intersects(otherSet.rlmSet)
    }

    // MARK: Mutation

    /**
     Inserts an object to the set if not already present.

     - warning: This method may only be called during a write transaction.

     - parameter object: An object.
     */
    public func insert(_ object: Element) {
        rlmSet.add(staticBridgeCast(fromSwift: object) as AnyObject)
    }

    /**
     Inserts the given sequence of objects into the set if not already present.

     - warning: This method may only be called during a write transaction.
    */
    public func insert<S: Sequence>(objectsIn objects: S) where S.Iterator.Element == Element {
        for obj in objects {
            rlmSet.add(staticBridgeCast(fromSwift: obj) as AnyObject)
        }
    }

    /**
     Removes an object in the set if present. The object is not removed from the Realm that manages it.

     - warning: This method may only be called during a write transaction.

     - parameter object: The object to remove.
     */
    public func remove(_ object: Element) {
        rlmSet.remove(staticBridgeCast(fromSwift: object) as AnyObject)
    }

    /**
     Removes all objects from the set. The objects are not removed from the Realm that manages them.

     - warning: This method may only be called during a write transaction.
     */
    public func removeAll() {
        rlmSet.removeAllObjects()
    }

    /**
     Mutates the set in place with the elements that are common to both this set and the given sequence.

     - warning: This method may only be called during a write transaction.

     - parameter other: Another set.
     */
    public func formIntersection(_ other: MutableSet<Element>) {
        rlmSet.intersect(other.rlmSet)
    }

    /**
     Mutates the set in place and removes the elements of the given set from this set.

     - warning: This method may only be called during a write transaction.

     - parameter other: Another set.
     */
    public func subtract(_ other: MutableSet<Element>) {
        rlmSet.minus(other.rlmSet)
    }

    /**
     Inserts the elements of the given sequence into the set.

     - warning: This method may only be called during a write transaction.

     - parameter other: Another set.
     */
    public func formUnion(_ other: MutableSet<Element>) {
        rlmSet.union(other.rlmSet)
    }

    @objc class func _unmanagedCollection() -> RLMSet<AnyObject> {
        if let type = Element.self as? ObjectBase.Type {
            return RLMSet(objectClassName: type.className())
        }
        if let type = Element.self as? _RealmSchemaDiscoverable.Type {
            return RLMSet(objectType: type._rlmType, optional: type._rlmOptional)
        }
        fatalError("Collections of projections must be used with @Projected.")
    }

    /// :nodoc:
    @objc public override class func _backingCollectionType() -> AnyClass {
        return RLMManagedSet.self
    }

    // Printable requires a description property defined in Swift (and not obj-c),
    // and it has to be defined as override, which can't be done in a
    // generic class.
    /// Returns a human-readable description of the objects contained in the MutableSet.
    @objc public override var description: String {
        return descriptionWithMaxDepth(RLMDescriptionMaxDepth)
    }

    @objc private func descriptionWithMaxDepth(_ depth: UInt) -> String {
        return RLMDescriptionWithMaxDepth("MutableSet", rlmSet, depth)
    }

    /// :nodoc:
    public func makeIterator() -> RLMIterator<Element> {
        return RLMIterator(collection: collection)
    }

    /// :nodoc:
    public func index(of object: Element) -> Int? {
        fatalError("index(of:) is not available on MutableSet")
    }

    /// :nodoc:
    public func index(matching predicate: NSPredicate) -> Int? {
        fatalError("index(matching:) is not available on MutableSet")
    }

    /// :nodoc:
    public func index(matching isIncluded: ((Query<Element>) -> Query<Bool>)) -> Int? {
        fatalError("index(matching:) is not available on MutableSet")
    }
}

// MARK: - Codable

extension MutableSet: Decodable where Element: Decodable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            insert(try container.decode(Element.self))
        }
    }
}

extension MutableSet: Encodable where Element: Encodable {}
