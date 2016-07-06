////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#if swift(>=3.0)

/// :nodoc:
/// Internal class. Do not use directly. Used for reflection and initialization
public class LinkingObjectsBase: NSObject, NSFastEnumeration {
    internal let objectClassName: String
    internal let propertyName: String

    private var cachedRLMResults: RLMResults<RLMObject>?
    private var object: RLMWeakObjectHandle?
    private var property: RLMProperty?

    internal func attachTo(object: RLMObjectBase, property: RLMProperty) {
        self.object = RLMWeakObjectHandle(object: object)
        self.property = property
        self.cachedRLMResults = nil
    }

    internal var rlmResults: RLMResults<RLMObject> {
        if cachedRLMResults == nil {
            if let object = self.object, property = self.property {
                cachedRLMResults = RLMDynamicGet(object.object, property)! as? RLMResults
                self.object = nil
                self.property = nil
            } else {
                cachedRLMResults = RLMResults.emptyDetached()
            }
        }
        return cachedRLMResults!
    }

    init(fromClassName objectClassName: String, property propertyName: String) {
        self.objectClassName = objectClassName
        self.propertyName = propertyName
    }

    // MARK: Fast Enumeration
    public func countByEnumerating(with state: UnsafeMutablePointer<NSFastEnumerationState>,
                                   objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>!,
                                   count len: Int) -> Int {
        return Int(rlmResults.countByEnumerating(with: state,
                                                 objects: buffer,
                                                 count: UInt(len)))
    }
}

/**
 LinkingObjects is an auto-updating container type that represents a collection of objects that
 link to a given object.

 LinkingObjects can be queried with the same predicates as `List<T>` and `Results<T>`.

 LinkingObjects always reflect the current state of the Realm on the current thread,
 including during write transactions on the current thread. The one exception to
 this is when using `for...in` enumeration, which will always enumerate over the
 linking objects when the enumeration is begun, even if some of them are deleted or
 modified to no longer link to the target object during the enumeration.

 LinkingObjects can only be used as a property on `Object` models. The property must
 be declared as `let` and cannot be `dynamic`.
 */
public final class LinkingObjects<T: Object>: LinkingObjectsBase {
    /// Element type contained in this collection.
    public typealias Element = T

    // MARK: Properties

    /// Returns the Realm these linking objects are associated with.
    public var realm: Realm? { return rlmResults.isAttached ? Realm(rlmResults.realm) : nil }

    /// Indicates if the linking objects can no longer be accessed.
    ///
    /// Linking objects can no longer be accessed if `invalidate` is called on the containing `Realm`.
    public var isInvalidated: Bool { return rlmResults.isInvalidated }

    /// Returns the number of objects in these linking objects.
    public var count: Int { return Int(rlmResults.count) }

    // MARK: Initializers

    /**
     Creates a LinkingObjects. This initializer should only be called when
     declaring a property on a Realm model.

     - parameter type:         The originating type linking to this object type.
     - parameter propertyName: The property name of the incoming relationship
                               this LinkingObjects should refer to.
    */
    public init(fromType type: T.Type, property propertyName: String) {
        let className = (T.self as Object.Type).className()
        super.init(fromClassName: className, property: propertyName)
    }

    /// Returns a human-readable description of the objects contained in these linking objects.
    public override var description: String {
        let type = "LinkingObjects<\(rlmResults.objectClassName)>"
        return gsub(pattern: "RLMResults <0x[a-z0-9]+>", template: type, string: rlmResults.description) ?? type
    }

    // MARK: Index Retrieval

    /**
     Returns the index of the given object, or `nil` if the object is not present.

     - parameter object: The object whose index is being queried.

     - returns: The index of the given object, or `nil` if the object is not present.
     */
    public func index(of object: T) -> Int? {
        return notFoundToNil(index: rlmResults.index(of: unsafeBitCast(object, to: RLMObject.self)))
    }

    /**
     Returns the index of the first object matching the given predicate,
     or `nil` if no objects match.

     - parameter predicate: The predicate to filter the objects.

     - returns: The index of the first matching object, or `nil` if no objects match.
     */
    public func indexOfObject(for predicate: Predicate) -> Int? {
        return notFoundToNil(index: rlmResults.indexOfObject(with: predicate))
    }

    /**
     Returns the index of the first object matching the given predicate,
     or `nil` if no objects match.

     - parameter predicateFormat: The predicate format string which can accept variable arguments.

     - returns: The index of the first matching object, or `nil` if no objects match.
     */
    public func indexOfObject(for predicateFormat: String, _ args: AnyObject...) -> Int? {
        return notFoundToNil(index: rlmResults.indexOfObject(with: Predicate(format: predicateFormat,
                                                                             argumentArray: args)))
    }

    // MARK: Object Retrieval

    /**
     Returns the object at the given `index`.

     - parameter index: The index.

     - returns: The object at the given `index`.
     */
    public subscript(index: Int) -> T {
        get {
            throwForNegativeIndex(index)
            return unsafeBitCast(rlmResults[UInt(index)], to: T.self)
        }
    }

    /// Returns the first object in the collection, or `nil` if empty.
    public var first: T? { return unsafeBitCast(rlmResults.firstObject(), to: Optional<T>.self) }

    /// Returns the last object in the collection, or `nil` if empty.
    public var last: T? { return unsafeBitCast(rlmResults.lastObject(), to: Optional<T>.self) }

    // MARK: KVC

    /**
     Returns an Array containing the results of invoking `valueForKey(_:)` using key on each of the
     collection's objects.

     - parameter key: The name of the property.

     - returns: Array containing the results of invoking `valueForKey(_:)` using key on each of the
       collection's objects.
     */
    public override func value(forKey key: String) -> AnyObject? {
        return value(forKeyPath: key)
    }

    /**
     Returns an Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
     collection's objects.

     - parameter keyPath: The key path to the property.

     - returns: Array containing the results of invoking `valueForKeyPath(_:)` using keyPath on each of the
       collection's objects.
     */
    public override func value(forKeyPath keyPath: String) -> AnyObject? {
        return rlmResults.value(forKeyPath: keyPath)
    }

    /**
     Invokes `setValue(_:forKey:)` on each of the collection's objects using the specified value and key.

     - warning: This method can only be called during a write transaction.

     - parameter value: The object value.
     - parameter key:   The name of the property.
     */
    public override func setValue(_ value: AnyObject?, forKey key: String) {
        return rlmResults.setValue(value, forKeyPath: key)
    }

    // MARK: Filtering

    /**
     Filters the collection to the objects that match the given predicate.

     - parameter predicateFormat: The predicate format string which can accept variable arguments.

     - returns: Results containing objects that match the given predicate.
     */
    public func filter(using predicateFormat: String, _ args: AnyObject...) -> Results<T> {
        return Results<T>(rlmResults.objects(with: Predicate(format: predicateFormat, argumentArray: args)))
    }

    /**
     Filters the collection to the objects that match the given predicate.

     - parameter predicate: The predicate to filter the objects.

     - returns: Results containing objects that match the given predicate.
     */
    public func filter(using predicate: Predicate) -> Results<T> {
        return Results<T>(rlmResults.objects(with: predicate))
    }

    // MARK: Sorting

    /**
     Returns `Results` with elements sorted by the given property name.

     - parameter property:  The property name to sort by.
     - parameter ascending: The direction to sort by.

     - returns: `Results` with elements sorted by the given property name.
     */
    public func sorted(onProperty property: String, ascending: Bool = true) -> Results<T> {
        return sorted(with: [SortDescriptor(property: property, ascending: ascending)])
    }

    /**
     Returns `Results` with elements sorted by the given sort descriptors.

     - parameter sortDescriptors: `SortDescriptor`s to sort by.

     - returns: `Results` with elements sorted by the given sort descriptors.
     */
    public func sorted<S: Sequence where S.Iterator.Element == SortDescriptor>(with sortDescriptors: S) -> Results<T> {
        return Results<T>(rlmResults.sortedResults(using: sortDescriptors.map { $0.rlmSortDescriptorValue }))
    }

    // MARK: Aggregate Operations

    /**
     Returns the minimum value of the given property.

     - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

     - parameter property: The name of a property conforming to `MinMaxType` to look for a minimum on.

     - returns: The minimum value for the property amongst objects in the collection, or `nil` if the collection
       is empty.
     */
    public func minimumValue<U: MinMaxType>(ofProperty property: String) -> U? {
        return rlmResults.min(ofProperty: property) as! U?
    }

    /**
     Returns the maximum value of the given property.

     - warning: Only names of properties of a type conforming to the `MinMaxType` protocol can be used.

     - parameter property: The name of a property conforming to `MinMaxType` to look for a maximum on.

     - returns: The maximum value for the property amongst objects in the collection, or `nil` if the collection
       is empty.
     */
    public func maximumValue<U: MinMaxType>(ofProperty property: String) -> U? {
        return rlmResults.max(ofProperty: property) as! U?
    }

    /**
     Returns the sum of the given property for objects in the collection.

     - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

     - parameter property: The name of a property conforming to `AddableType` to calculate sum on.

     - returns: The sum of the given property over all objects in the collection.
     */
    public func sum<U: AddableType>(ofProperty property: String) -> U {
        return rlmResults.sum(ofProperty: property) as AnyObject as! U
    }

    /**
     Returns the average of the given property for objects in the collection.

     - warning: Only names of properties of a type conforming to the `AddableType` protocol can be used.

     - parameter property: The name of a property conforming to `AddableType` to calculate average on.

     - returns: The average of the given property over all objects in the collection, or `nil` if the collection
       is empty.
     */
    public func average<U: AddableType>(ofProperty property: String) -> U? {
        return rlmResults.average(ofProperty: property) as! U?
    }

    // MARK: Notifications

    /**
     Register a block to be called each time the LinkingObjects changes.

     The block will be asynchronously called with the initial set of objects, and then
     called again after each write transaction which changes either any of the
     objects in the collection, or which objects are in the collection.

     This version of this method reports which of the objects in the collection were
     added, removed, or modified in each write transaction as indices within the
     collection. See the RealmCollectionChange documentation for more information on
     the change information supplied and an example of how to use it to update
     a UITableView.

     At the time when the block is called, the LinkingObjects object will be fully
     evaluated and up-to-date, and as long as you do not perform a write transaction
     on the same thread or explicitly call realm.refresh(), accessing it will never
     perform blocking work.

     Notifications are delivered via the standard run loop, and so can't be
     delivered while the run loop is blocked by other activity. When
     notifications can't be delivered instantly, multiple notifications may be
     coalesced into a single notification. This can include the notification
     with the initial set of objects. For example, the following code performs a write
     transaction immediately after adding the notification block, so there is no
     opportunity for the initial notification to be delivered first. As a
     result, the initial notification will reflect the state of the Realm after
     the write transaction.

         let dog = realm.objects(Dog).first!
         let owners = dog.owners
         print("owners.count: \(owners.count)") // => 0
         let token = owners.addNotificationBlock { (changes: RealmCollectionChange) in
             switch changes {
                 case .Initial(let owners):
                     // Will print "owners.count: 1"
                     print("owners.count: \(owners.count)")
                     break
                 case .Update:
                     // Will not be hit in this example
                     break
                 case .Error:
                     break
             }
         }
         try! realm.write {
             realm.add(Person.self, value: ["name": "Mark", dogs: [dog]])
         }
         // end of runloop execution context

     You must retain the returned token for as long as you want updates to continue
     to be sent to the block. To stop receiving updates, call stop() on the token.

     - warning: This method cannot be called during a write transaction, or when
     the source realm is read-only.

     - parameter block: The block to be called with the evaluated linking objects and change information.
     - returns: A token which must be held for as long as you want updates to be delivered.
     */
    public func addNotificationBlock(block: ((RealmCollectionChange<LinkingObjects>) -> Void)) -> NotificationToken {
        return rlmResults.addNotificationBlock { results, change, error in
            block(RealmCollectionChange.fromObjc(value: self, change: change, error: error))
        }
    }
}

extension LinkingObjects : RealmCollection {
    // MARK: Sequence Support

    /// Returns a `GeneratorOf<T>` that yields successive elements in the results.
    public func makeIterator() -> RLMIterator<T> {
        return RLMIterator(collection: rlmResults)
    }

    // MARK: Collection Support

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int { return 0 }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    public var endIndex: Int { return count }

    public func index(after: Int) -> Int {
      return after + 1
    }

    public func index(before: Int) -> Int {
      return before - 1
    }

    /// :nodoc:
    public func _addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection<T>>) -> Void) ->
        NotificationToken {
            let anyCollection = AnyRealmCollection(self)
            return rlmResults.addNotificationBlock { _, change, error in
                block(RealmCollectionChange.fromObjc(value: anyCollection, change: change, error: error))
            }
    }
}

// MARK: Unavailable

extension LinkingObjects {
    @available(*, unavailable, renamed:"isInvalidated")
    public var invalidated : Bool { fatalError() }

    @available(*, unavailable, renamed:"indexOfObject(for:)")
    public func index(of predicate: Predicate) -> Int? { fatalError() }

    @available(*, unavailable, renamed:"indexOfObject(for:_:)")
    public func index(of predicateFormat: String, _ args: AnyObject...) -> Int? { fatalError() }

    @available(*, unavailable, renamed:"filter(using:)")
    public func filter(_ predicate: Predicate) -> Results<T> { fatalError() }

    @available(*, unavailable, renamed:"filter(using:_:)")
    public func filter(_ predicateFormat: String, _ args: AnyObject...) -> Results<T> { fatalError() }

    @available(*, unavailable, renamed:"sorted(onProperty:ascending:)")
    public func sorted(_ property: String, ascending: Bool = true) -> Results<T> { fatalError() }

    @available(*, unavailable, renamed:"sorted(with:)")
    public func sorted<S: Sequence where S.Iterator.Element == SortDescriptor>(_ sortDescriptors: S) -> Results<T> {
        fatalError()
    }

    @available(*, unavailable, renamed:"minimumValue(ofProperty:)")
    public func min<U: MinMaxType>(_ property: String) -> U? { fatalError() }

    @available(*, unavailable, renamed:"maximumValue(ofProperty:)")
    public func max<U: MinMaxType>(_ property: String) -> U? { fatalError() }

    @available(*, unavailable, renamed:"sum(ofProperty:)")
    public func sum<U: AddableType>(_ property: String) -> U { fatalError() }

    @available(*, unavailable, renamed:"average(ofProperty:)")
    public func average<U: AddableType>(_ property: String) -> U? { fatalError() }
}

#else

/// :nodoc:
/// Internal class. Do not use directly. Used for reflection and initialization
public class LinkingObjectsBase: NSObject, NSFastEnumeration {
    internal let objectClassName: String
    internal let propertyName: String

    private var cachedRLMResults: RLMResults?
    private var object: RLMWeakObjectHandle?
    private var property: RLMProperty?

    internal func attachTo(object object: RLMObjectBase, property: RLMProperty) {
        self.object = RLMWeakObjectHandle(object: object)
        self.property = property
        self.cachedRLMResults = nil
    }

    internal var rlmResults: RLMResults {
        if cachedRLMResults == nil {
            if let object = self.object, property = self.property {
                cachedRLMResults = RLMDynamicGet(object.object, property)! as? RLMResults
                self.object = nil
                self.property = nil
            } else {
                cachedRLMResults = RLMResults.emptyDetachedResults()
            }
        }
        return cachedRLMResults!
    }

    init(fromClassName objectClassName: String, property propertyName: String) {
        self.objectClassName = objectClassName
        self.propertyName = propertyName
    }

    // MARK: Fast Enumeration
    public func countByEnumeratingWithState(state: UnsafeMutablePointer<NSFastEnumerationState>,
                                            objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>,
                                                    count len: Int) -> Int {
        return Int(rlmResults.countByEnumeratingWithState(state,
            objects: buffer,
            count: UInt(len)))
    }
}

/**
 `LinkingObjects` is an auto-updating container type. It represents a collection of objects that
 link to its parent object.

 `LinkingObjects` can be queried with the same predicates as `List<T>` and `Results<T>`.

 `LinkingObjects` always reflects the current state of the Realm on the current thread,
 including during write transactions on the current thread. The one exception to
 this is when using `for...in` enumeration, which will always enumerate over the
 linking objects that were present when the enumeration is begun, even if some of them
 are deleted or modified to no longer link to the target object during the enumeration.

 `LinkingObjects` can only be used as a property on `Object` models. Properties of this type must
 be declared as `let` and cannot be `dynamic`.
 */
public final class LinkingObjects<T: Object>: LinkingObjectsBase {
    /// The element type contained in this collection.
    public typealias Element = T

    // MARK: Properties

    /// The Realm which manages this linking objects collection, or `nil` if the collection is unmanaged.
    public var realm: Realm? { return rlmResults.attached ? Realm(rlmResults.realm) : nil }

    /// Indicates if the linking objects collection is no longer valid.
    ///
    /// The linking objects collection becomes invalid if `invalidate` is called on the containing `realm`.
    ///
    /// An invalidated linking objects can be accessed, but will always be empty.
    public var invalidated: Bool { return rlmResults.invalidated }

    /// The number of objects in the linking objects.
    public var count: Int { return Int(rlmResults.count) }

    // MARK: Initializers

    /**
     Creates an instance of a `LinkingObjects`. This initializer should only be called when
     declaring a property on a Realm model.

     - parameter type:         The type of the object owning the property this `LinkingObjects` should refer to.
     - parameter propertyName: The property name of the property this `LinkingObjects` should refer to.
    */
    public init(fromType type: T.Type, property propertyName: String) {
        let className = (T.self as Object.Type).className()
        super.init(fromClassName: className, property: propertyName)
    }

    /// Returns a description of the objects contained within the linking objects.
    public override var description: String {
        let type = "LinkingObjects<\(rlmResults.objectClassName)>"
        return gsub("RLMResults <0x[a-z0-9]+>", template: type, string: rlmResults.description) ?? type
    }

    // MARK: Index Retrieval

    /**
     Returns the index of an object in the linking objects collection, or `nil` if the object is not present.

     - parameter object: The object whose index is being queried.
     */
    public func indexOf(object: T) -> Int? {
        return notFoundToNil(rlmResults.indexOfObject(unsafeBitCast(object, RLMObject.self)))
    }

    /**
     Returns the index of the first object matching the given predicate, or `nil` if no objects match.

     - parameter predicate: The predicate with which to filter the objects.
     */
    public func indexOf(predicate: NSPredicate) -> Int? {
        return notFoundToNil(rlmResults.indexOfObjectWithPredicate(predicate))
    }

    /**
     Returns the index of the first object matching the given predicate, or `nil` if no objects match.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.
     */
    public func indexOf(predicateFormat: String, _ args: AnyObject...) -> Int? {
        return notFoundToNil(rlmResults.indexOfObjectWithPredicate(NSPredicate(format: predicateFormat,
            argumentArray: args)))
    }

    // MARK: Object Retrieval

    /**
     Returns the object at the given `index`.

     - parameter index: The index.

     - returns: The object at the given `index`.
     */
    public subscript(index: Int) -> T {
        get {
            throwForNegativeIndex(index)
            return unsafeBitCast(rlmResults[UInt(index)], T.self)
        }
    }

    /// Returns the first object in the linking objects collection, or `nil` if the collection is empty.
    public var first: T? { return unsafeBitCast(rlmResults.firstObject(), Optional<T>.self) }

    /// Returns the last object in the linking objects collection, or `nil` if collection is empty.
    public var last: T? { return unsafeBitCast(rlmResults.lastObject(), Optional<T>.self) }

    // MARK: KVC

    /**
     Returns an `Array` containing the results of invoking `valueForKey(_:)` with `key` on each of the linking objects
     collection's objects.

     - parameter key: The name of the property whose values are desired.
     */
    public override func valueForKey(key: String) -> AnyObject? {
        return rlmResults.valueForKey(key)
    }

    /**
     Returns an `Array` containing the results of invoking `valueForKeyPath(_:)` with `keyPath` on each of the linking
     objects collection's objects.

     - parameter keyPath: The key path to the property whose values are desired.
     */
    public override func valueForKeyPath(keyPath: String) -> AnyObject? {
        return rlmResults.valueForKeyPath(keyPath)
    }

    /**
     Invokes `setValue(_:forKey:)` on each of the linking objects collection's objects using the specified `value` and
     `key`.

     - warning: This method may only be called during a write transaction.

     - parameter value: The value to set the property to.
     - parameter key:   The name of the property whose value should be set on each object.
     */
    public override func setValue(value: AnyObject?, forKey key: String) {
        return rlmResults.setValue(value, forKey: key)
    }

    // MARK: Filtering

    /**
     Returns a `Results` containing all objects matching the given predicate in the linking objects collection.

     - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments.
     */
    public func filter(predicateFormat: String, _ args: AnyObject...) -> Results<T> {
        return Results<T>(rlmResults.objectsWithPredicate(NSPredicate(format: predicateFormat, argumentArray: args)))
    }

    /**
     Returns a `Results` containing all objects matching the given predicate in the linking objects collection.

     - parameter predicate: The predicate with which to filter the objects.
     */
    public func filter(predicate: NSPredicate) -> Results<T> {
        return Results<T>(rlmResults.objectsWithPredicate(predicate))
    }

    // MARK: Sorting

    /**
     Returns a `Results` containing the objects in the linking objects collection, but sorted.

     Objects are sorted based on the values of the given property. For example, to sort a collection of `Student`s from
     youngest to oldest based on their `age` property, you might call `students.sorted("age", ascending: true)`.

     - warning: Collections may only be sorted by properties of boolean, `NSDate`, single and double-precision floating
                point, integer, and string types.

     - parameter property:  The name of the property to sort by.
     - parameter ascending: The direction to sort in.
     */
    public func sorted(property: String, ascending: Bool = true) -> Results<T> {
        return sorted([SortDescriptor(property: property, ascending: ascending)])
    }

    /**
     Returns a `Results` containing the objects in the linking objects collection, but sorted.

     - warning: Collections may only be sorted by properties of boolean, `NSDate`, single and double-precision floating
                point, integer, and string types.

     - see: `sorted(_:ascending:)`

     - parameter sortDescriptors: A sequence of `SortDescriptor`s to sort by.
     */
    public func sorted<S: SequenceType where S.Generator.Element == SortDescriptor>(sortDescriptors: S) -> Results<T> {
        return Results<T>(rlmResults.sortedResultsUsingDescriptors(sortDescriptors.map { $0.rlmSortDescriptorValue }))
    }

    // MARK: Aggregate Operations

    /**
     Returns the minimum (lowest) value of the given property among all the objects represented by the linking objects
     collection.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.

     - returns: The minimum value of the property, or `nil` if the collection is empty.
     */
    public func min<U: MinMaxType>(property: String) -> U? {
        return rlmResults.minOfProperty(property) as! U?
    }

    /**
     Returns the maximum (highest) value of the given property among all the objects represented by the linking objects
     collection.

     - warning: Only a property whose type conforms to the `MinMaxType` protocol can be specified.

     - parameter property: The name of a property whose minimum value is desired.

     - returns: The maximum value of the property, or `nil` if the collection is empty.
     */
    public func max<U: MinMaxType>(property: String) -> U? {
        return rlmResults.maxOfProperty(property) as! U?
    }

    /**
     Returns the sum of the values of a given property over all the objects represented by the linking objects
     collection.

     - warning: Only a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose values should be summed.

     - returns: The sum of the given property.
     */
    public func sum<U: AddableType>(property: String) -> U {
        return rlmResults.sumOfProperty(property) as AnyObject as! U
    }

    /**
     Returns the average value of a given property over all the objects represented by the linking objects collection.

     - warning: Only the name of a property whose type conforms to the `AddableType` protocol can be specified.

     - parameter property: The name of a property whose average value should be calculated.

     - returns: The average value of the given property, or `nil` if the collection is empty.
     */
    public func average<U: AddableType>(property: String) -> U? {
        return rlmResults.averageOfProperty(property) as! U?
    }

    // MARK: Notifications

    /**
     Registers a block to be called each time the linking objects collection changes.

     The block will be asynchronously called with the initial linking objects collection,
     and then called again after each write transaction which changes either any
     of the objects in the collection, or which objects are in the collection.

     The `change` parameter that is passed to the block reports, in the form of indices within the
     collection, which of the objects were added, removed, or modified during each write transaction. See the
     `RealmCollectionChange` documentation for more information on the change information supplied and an example of how
     to use it to update a `UITableView`.

     At the time when the block is called, the linking objects collection will be fully
     evaluated and up-to-date, and as long as you do not perform a write transaction
     on the same thread or explicitly call `realm.refresh()`, accessing it will never
     perform blocking work.

     Notifications are delivered via the standard run loop, and so can't be
     delivered while the run loop is blocked by other activity. When
     notifications can't be delivered instantly, multiple notifications may be
     coalesced into a single notification. This can include the notification
     with the initial set of objects. For example, the following code performs a write
     transaction immediately after adding the notification block, so there is no
     opportunity for the initial notification to be delivered first. As a
     result, the initial notification will reflect the state of the Realm after
     the write transaction.

     ```swift
     let dog = realm.objects(Dog.self).first!
     let owners = dog.owners
     print("owners.count: \(owners.count)") // => 0
     let token = owners.addNotificationBlock { changes in
         switch changes {
             case .Initial(let owners):
                 // Will print "owners.count: 1"
                 print("owners.count: \(owners.count)")
                 break
             case .Update:
                 // Will not be hit in this example
                 break
             case .Error:
                 break
         }
     }
     try! realm.write {
         realm.add(Person.self, value: ["name": "Mark", dogs: [dog]])
     }
     // end of runloop execution context
     ```

     You must retain the returned token for as long as you want updates to be sent to the block. To stop receiving
     updates, call `stop()` on the token.

     - warning: This method cannot be called during a write transaction, or when
     the containing Realm is read-only.

     - parameter block: The block to be called whenever a change occurs.
     - returns: A token which must be retained for as long as you want updates to be delivered.
     */
    @warn_unused_result(message="You must hold on to the NotificationToken returned from addNotificationBlock")
    public func addNotificationBlock(block: (RealmCollectionChange<LinkingObjects> -> Void)) -> NotificationToken {
        return rlmResults.addNotificationBlock { results, change, error in
            block(RealmCollectionChange.fromObjc(self, change: change, error: error))
        }
    }
}

extension LinkingObjects: RealmCollectionType {
    // MARK: Sequence Support

    /// Returns an `RLMGenerator` that yields successive elements in the results.
    public func generate() -> RLMGenerator<T> {
        return RLMGenerator(collection: rlmResults)
    }

    // MARK: Collection Support

    /// The position of the first element in a non-empty collection.
    /// Identical to `endIndex` in an empty collection.
    public var startIndex: Int { return 0 }

    /// The collection's "past the end" position.
    /// `endIndex` is not a valid argument to subscript, and is always reachable from `startIndex` by
    /// zero or more applications of `successor()`.
    public var endIndex: Int { return count }

    /// :nodoc:
    public func _addNotificationBlock(block: (RealmCollectionChange<AnyRealmCollection<T>>) -> Void) ->
        NotificationToken {
            let anyCollection = AnyRealmCollection(self)
            return rlmResults.addNotificationBlock { _, change, error in
                block(RealmCollectionChange.fromObjc(anyCollection, change: change, error: error))
            }
    }
}

#endif
