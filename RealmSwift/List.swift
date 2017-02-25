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

/// :nodoc:
/// Internal class. Do not use directly.
public class ListBase: RLMListBase {
    // Printable requires a description property defined in Swift (and not obj-c),
    // and it has to be defined as @objc override, which can't be done in a
    // generic class.
    /// Returns a human-readable description of the objects contained in the List.
    @objc public override var description: String {
        return descriptionWithMaxDepth(RLMDescriptionMaxDepth)
    }

    @objc private func descriptionWithMaxDepth(_ depth: UInt) -> String {
        let type = "List<\(_rlmArray.objectClassName)>"
        return gsub(pattern: "RLMArray <0x[a-z0-9]+>", template: type, string: _rlmArray.description(withMaxDepth: depth)) ?? type
    }

    /// Returns the number of objects in this List.
    public var count: Int { return Int(_rlmArray.count) }
}

public protocol RealmManaged {
    static func _rlmArray() -> RLMArray<AnyObject>
}

extension Optional: RealmManaged {
    public static func _rlmArray() -> RLMArray<AnyObject> {
        switch Wrapped.self {
        case is Int.Type, is Int8.Type, is Int16.Type, is Int32.Type, is Int64.Type:
            return RLMArray(objectType: .int, optional: true)
        case is Float.Type:  return RLMArray(objectType: .float,  optional: true)
        case is Double.Type: return RLMArray(objectType: .double, optional: true)
        case is String.Type: return RLMArray(objectType: .string, optional: true)
        case is Data.Type:   return RLMArray(objectType: .data,   optional: true)
        case is Date.Type:   return RLMArray(objectType: .date,   optional: true)
        default: fatalError("unsupported type")
        }
    }
}

extension String: RealmManaged {
    public static func _rlmArray() -> RLMArray<AnyObject> {
        return RLMArray(objectType: .string, optional: false)
    }
}
extension Date: RealmManaged {
    public static func _rlmArray() -> RLMArray<AnyObject> {
        return RLMArray(objectType: .date, optional: false)
    }
}
extension Data: RealmManaged {
    public static func _rlmArray() -> RLMArray<AnyObject> {
        return RLMArray(objectType: .data, optional: false)
    }
}

public final class List<T: RealmManaged>: ListBase {
    public typealias Element = T
    public var realm: Realm? {
        return _rlmArray.realm.map { Realm($0) }
    }

    public var isInvalidated: Bool { return _rlmArray.isInvalidated }

    public override init() {
        super.init(array: T._rlmArray())
    }

    internal init(rlmArray: RLMArray<AnyObject>) {
        super.init(array: rlmArray)
    }

    public func index(of object: T) -> Int? {
        return notFoundToNil(index: _rlmArray.index(of: object as AnyObject))
    }

    public func index(matching predicate: NSPredicate) -> Int? {
        return notFoundToNil(index: _rlmArray.indexOfObject(with: predicate))
    }

    public func index(matching predicateFormat: String, _ args: Any...) -> Int? {
        return index(matching: NSPredicate(format: predicateFormat, argumentArray: args))
    }

    private func cast<U, V>(_ value: U, to: V.Type) -> V {
        if let v = value as? V {
            return v
        }
        return unsafeBitCast(value, to: to)
    }

    public subscript(position: Int) -> T {
        get {
            throwForNegativeIndex(position)
            return cast(_rlmArray.object(at: UInt(position)), to: T.self)
        }
        set {
            throwForNegativeIndex(position)
            _rlmArray.replaceObject(at: UInt(position), with: newValue as AnyObject)
        }
    }

    public var first: T? { return cast(_rlmArray.firstObject(), to: Optional<T>.self) }
    public var last: T? { return cast(_rlmArray.lastObject(), to: Optional<T>.self) }

    public override func value(forKey key: String) -> Any? {
        return value(forKeyPath: key)
    }

    public override func value(forKeyPath keyPath: String) -> Any? {
        return _rlmArray.value(forKeyPath: keyPath)
    }

    public override func setValue(_ value: Any?, forKey key: String) {
        return _rlmArray.setValue(value, forKeyPath: key)
    }

    public func filter(_ predicateFormat: String, _ args: Any...) -> Results<T> {
        return Results<T>(_rlmArray.objects(with: NSPredicate(format: predicateFormat, argumentArray: args)))
    }

    public func filter(_ predicate: NSPredicate) -> Results<T> {
        return Results<T>(_rlmArray.objects(with: predicate))
    }

    public func sorted(byKeyPath keyPath: String, ascending: Bool = true) -> Results<T> {
        return sorted(by: [SortDescriptor(keyPath: keyPath, ascending: ascending)])
    }

    @available(*, deprecated, renamed: "sorted(byKeyPath:ascending:)")
    public func sorted(byProperty property: String, ascending: Bool = true) -> Results<T> {
        return sorted(byKeyPath: property, ascending: ascending)
    }

    public func sorted<S: Sequence>(by sortDescriptors: S)
            -> Results<T> where S.Iterator.Element == SortDescriptor {
        return Results<T>(_rlmArray.sortedResults(using: sortDescriptors.map { $0.rlmSortDescriptorValue }))
    }

    public func min<U: MinMaxType>(ofProperty property: String) -> U? {
        return _rlmArray.min(ofProperty: property).map(dynamicBridgeCast)
    }

    public func max<U: MinMaxType>(ofProperty property: String) -> U? {
        return _rlmArray.max(ofProperty: property).map(dynamicBridgeCast)
    }

    public func sum<U: AddableType>(ofProperty property: String) -> U {
        return dynamicBridgeCast(fromObjectiveC: _rlmArray.sum(ofProperty: property))
    }

    public func average<U: AddableType>(ofProperty property: String) -> U? {
        return _rlmArray.average(ofProperty: property).map(dynamicBridgeCast)
    }

    public func append(_ object: T) {
        _rlmArray.add(object as AnyObject)
    }

    public func append<S: Sequence>(objectsIn objects: S) where S.Iterator.Element == T {
        for obj in objects {
            _rlmArray.add(obj as AnyObject)
        }
    }

    public func insert(_ object: T, at index: Int) {
        throwForNegativeIndex(index)
        _rlmArray.insert(object as AnyObject, at: UInt(index))
    }

    public func remove(objectAtIndex index: Int) {
        throwForNegativeIndex(index)
        _rlmArray.removeObject(at: UInt(index))
    }

    public func removeLast() {
        _rlmArray.removeLastObject()
    }

    public func removeAll() {
        _rlmArray.removeAllObjects()
    }

    public func replace(index: Int, object: T) {
        throwForNegativeIndex(index)
        _rlmArray.replaceObject(at: UInt(index), with: object as AnyObject)
    }

    public func move(from: Int, to: Int) {
        throwForNegativeIndex(from)
        throwForNegativeIndex(to)
        _rlmArray.moveObject(at: UInt(from), to: UInt(to))
    }

    public func swap(index1: Int, _ index2: Int) {
        throwForNegativeIndex(index1, parameterName: "index1")
        throwForNegativeIndex(index2, parameterName: "index2")
        _rlmArray.exchangeObject(at: UInt(index1), withObjectAt: UInt(index2))
    }

    public func addNotificationBlock(_ block: @escaping (RealmCollectionChange<List>) -> Void) -> NotificationToken {
        return _rlmArray.addNotificationBlock { _, change, error in
            block(RealmCollectionChange.fromObjc(value: self, change: change, error: error))
        }
    }
}

extension List: RealmCollection, RangeReplaceableCollection {
    // MARK: Sequence Support

    /// Returns a `RLMIterator` that yields successive elements in the `List`.
    public func makeIterator() -> RLMIterator<T> {
        return RLMIterator(collection: _rlmArray)
    }

    // MARK: RangeReplaceableCollection Support

#if swift(>=3.1)
    // These should not be necessary, but Swift 3.1's compiler fails to infer the `SubSequence`,
    // and the standard library neglects to provide the default implementation of `subscript`
    /// :nodoc:
    public typealias SubSequence = RangeReplaceableRandomAccessSlice<List>

    /// :nodoc:
    public subscript(slice: Range<Int>) -> SubSequence {
        return SubSequence(base: self, bounds: slice)
    }
#endif

    /**
     Replace the given `subRange` of elements with `newElements`.

    - parameter subrange:    The range of elements to be replaced.
    - parameter newElements: The new elements to be inserted into the List.
    */
    public func replaceSubrange<C: Collection>(_ subrange: Range<Int>, with newElements: C)
        where C.Iterator.Element == T {
        for _ in subrange.lowerBound..<subrange.upperBound {
            remove(objectAtIndex: subrange.lowerBound)
        }
        for x in newElements.reversed() {
            insert(x, at: subrange.lowerBound)
        }
    }

    /// The position of the first element in a non-empty collection.
    /// Identical to endIndex in an empty collection.
    public var startIndex: Int { return 0 }

    /// The collection's "past the end" position.
    /// endIndex is not a valid argument to subscript, and is always reachable from startIndex by
    /// zero or more applications of successor().
    public var endIndex: Int { return count }

    public func index(after i: Int) -> Int { return i + 1 }
    public func index(before i: Int) -> Int { return i - 1 }

    /// :nodoc:
    public func _addNotificationBlock(_ block: @escaping (RealmCollectionChange<AnyRealmCollection<T>>) -> Void) ->
        NotificationToken {
        let anyCollection = AnyRealmCollection(self)
        return _rlmArray.addNotificationBlock { _, change, error in
            block(RealmCollectionChange.fromObjc(value: anyCollection, change: change, error: error))
        }
    }
}

// MARK: AssistedObjectiveCBridgeable

extension List: AssistedObjectiveCBridgeable {
    internal static func bridging(from objectiveCValue: Any, with metadata: Any?) -> List {
        guard let objectiveCValue = objectiveCValue as? RLMArray<AnyObject> else { preconditionFailure() }
        return List(rlmArray: objectiveCValue)
    }

    internal var bridged: (objectiveCValue: Any, metadata: Any?) {
        return (objectiveCValue: _rlmArray, metadata: nil)
    }
}

// MARK: Unavailable

extension List where T: Object {
    @available(*, unavailable, renamed: "append(objectsIn:)")
    public func appendContentsOf<S: Sequence>(_ objects: S) where S.Iterator.Element == T { fatalError() }

    @available(*, unavailable, renamed: "remove(objectAtIndex:)")
    public func remove(at index: Int) { fatalError() }

    @available(*, unavailable, renamed: "isInvalidated")
    public var invalidated: Bool { fatalError() }

    @available(*, unavailable, renamed: "index(matching:)")
    public func index(of predicate: NSPredicate) -> Int? { fatalError() }

    @available(*, unavailable, renamed: "index(matching:_:)")
    public func index(of predicateFormat: String, _ args: Any...) -> Int? { fatalError() }

    @available(*, unavailable, renamed: "sorted(byKeyPath:ascending:)")
    public func sorted(_ property: String, ascending: Bool = true) -> Results<T> { fatalError() }

    @available(*, unavailable, renamed: "sorted(by:)")
    public func sorted<S: Sequence>(_ sortDescriptors: S) -> Results<T> where S.Iterator.Element == SortDescriptor {
        fatalError()
    }

    @available(*, unavailable, renamed: "min(ofProperty:)")
    public func min<U: MinMaxType>(_ property: String) -> U? { fatalError() }

    @available(*, unavailable, renamed: "max(ofProperty:)")
    public func max<U: MinMaxType>(_ property: String) -> U? { fatalError() }

    @available(*, unavailable, renamed: "sum(ofProperty:)")
    public func sum<U: AddableType>(_ property: String) -> U { fatalError() }

    @available(*, unavailable, renamed: "average(ofProperty:)")
    public func average<U: AddableType>(_ property: String) -> U? { fatalError() }
}
