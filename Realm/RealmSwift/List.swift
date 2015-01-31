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

import Realm
import Realm.Private

public class ListBase: RLMListBase, Printable {
    // Printable requires a description property defined in Swift (and not obj-c),
    // and it has to be defined as @objc override, which can't be done in a
    // generic class.
    @objc public override var description: String { return _rlmArray.description }
    public var count: Int { return Int(_rlmArray.count) }
}

public final class List<T: Object>: ListBase, SequenceType {
    // MARK: Properties

    public var realm: Realm? {
        if _rlmArray.realm == nil {
            return nil
        }
        return Realm(rlmRealm: _rlmArray.realm)
    }

    // MARK: Initializers

    public override init() {
        super.init(array: RLMArray(objectClassName: T.className()))
    }

    init(_ rlmArray: RLMArray) {
        super.init(array: rlmArray)
    }

    // MARK: Index Retrieval

    public func indexOf(object: T) -> Int? {
        return notFoundToNil(_rlmArray.indexOfObject(unsafeBitCast(object, RLMObject.self)))
    }

    public func indexOf(predicate: NSPredicate) -> Int? {
        return notFoundToNil(_rlmArray.indexOfObjectWithPredicate(predicate))
    }

    public func indexOf(predicateFormat: String, _ args: CVarArgType...) -> Int? {
        return notFoundToNil(_rlmArray.indexOfObjectWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args))))
    }

    // MARK: Object Retrieval

    public subscript(index: Int) -> T {
        get {
            return _rlmArray[UInt(index)] as T
        }
        set {
            return _rlmArray[UInt(index)] = newValue
        }
    }

    public var first: T? { return _rlmArray.firstObject() as T? }

    public var last: T? { return _rlmArray.lastObject() as T? }

    // MARK: Subarray Retrieval

    public func filter(predicateFormat: String, _ args: CVarArgType...) -> Results<T> {
        return Results<T>(_rlmArray.objectsWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args))))
    }

    public func filter(predicate: NSPredicate) -> Results<T> {
        return Results<T>(_rlmArray.objectsWithPredicate(predicate))
    }

    // MARK: Sorting

    public func sorted(property: String, ascending: Bool = true) -> Results<T> {
        return Results<T>(_rlmArray.sortedResultsUsingProperty(property, ascending: ascending))
    }

    // MARK: Sequence Support

    public func generate() -> GeneratorOf<T> {
        var i: UInt = 0
        return GeneratorOf<T>() {
            if (i >= self._rlmArray.count) {
                return .None
            } else {
                return self._rlmArray[i++] as? T
            }
        }
    }

    // MARK: Mutating

    public func append(object: T) {
        _rlmArray.addObject(unsafeBitCast(object, RLMObject.self))
    }

    public func append<S where S: SequenceType>(objects: S) {
        for obj in objects {
            _rlmArray.addObject(unsafeBitCast(obj as T, RLMObject.self))
        }
    }

    public func insert(object: T, atIndex index: Int) {
        _rlmArray.insertObject(unsafeBitCast(object, RLMObject.self), atIndex: UInt(index))
    }

    public func remove(index: Int) {
        _rlmArray.removeObjectAtIndex(UInt(index))
    }

    public func remove(object: T) {
        if let index = indexOf(object) {
            remove(index)
        }
    }

    public func removeLast() {
        _rlmArray.removeLastObject()
    }

    public func removeAll() {
        _rlmArray.removeAllObjects()
    }
    
    public func replace(index: Int, object: T) {
        _rlmArray.replaceObjectAtIndex(UInt(index), withObject: unsafeBitCast(object, RLMObject.self))
    }

    // MARK: Private stuff

    private func notFoundToNil(index: UInt) -> Int? {
        if index == UInt(NSNotFound) {
            return nil
        }
        return Int(index)
    }
}
