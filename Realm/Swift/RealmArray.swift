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

public class RealmArray<T: RealmObject>: Sequence, Printable {
    public var rlmArray: RLMArray
    public var count: UInt { return rlmArray.count }
    public var objectClassName: String { return rlmArray.objectClassName }
    public var readOnly: Bool { return rlmArray.readOnly }
    public var realm: Realm { return Realm(rlmRealm: rlmArray.realm) }

    public var description: String { return rlmArray.description }
    public var property: RLMArray { return rlmArray }

    public init() {
        rlmArray = RLMArray(objectClassName: RLMSwiftSupport.demangleClassName(NSStringFromClass(T.self)))
    }

    public convenience init(rlmArray: RLMArray) {
        self.init()
        self.rlmArray = rlmArray
    }

    public subscript(index: UInt) -> T {
        get {
            return rlmArray[index] as T
        }
        set {
            return rlmArray[index] = newValue
        }
    }

    public func firstObject() -> T? {
        return rlmArray.firstObject() as T?
    }

    public func lastObject() -> T? {
        return rlmArray.lastObject() as T?
    }

    public func indexOfObject(object: T) -> UInt? {
        return rlmArray.indexOfObject(object)
    }

    public func indexOfObjectWithPredicate(predicate: NSPredicate) -> UInt? {
        return rlmArray.indexOfObjectWithPredicate(predicate)
    }

    // Swift query convenience functions

    public func indexOfObjectWhere(predicateFormat: String, _ args: CVarArg...) -> UInt {
        return rlmArray.indexOfObjectWhere(predicateFormat, args: getVaList(args))
    }

    public func objectsWhere(predicateFormat: String, _ args: CVarArg...) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: rlmArray.objectsWhere(predicateFormat, args: getVaList(args)))
    }

    public func objectsWithPredicate(predicate: NSPredicate) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: rlmArray.objectsWithPredicate(predicate))
    }

    public func arraySortedByProperty(property: String, ascending: Bool) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: rlmArray.arraySortedByProperty(property, ascending: ascending))
    }

    public func minOfProperty(property: String) -> AnyObject {
        return rlmArray.minOfProperty(property)
    }

    public func maxOfProperty(property: String) -> AnyObject {
        return rlmArray.maxOfProperty(property)
    }

    public func sumOfProperty(property: String) -> Double {
        return rlmArray.sumOfProperty(property) as Double
    }

    public func averageOfProperty(property: String) -> Double {
        return rlmArray.averageOfProperty(property) as Double
    }

    public func JSONString() -> String {
        return rlmArray.JSONString()
    }

    public func generate() -> GeneratorOf<T> {
        var i: UInt = 0
        return GeneratorOf<T>({
            if (i >= self.rlmArray.count) {
                return .None
            } else {
                return self.rlmArray[i++] as? T
            }
        })
    }

    public func addObject(object: T) {
        rlmArray.addObject(object)
    }

    public func addObjects(objects: [AnyObject]) {
        rlmArray.addObjectsFromArray(objects)
    }

    public func insertObject(object: T, atIndex index: UInt) {
        rlmArray.insertObject(object, atIndex: index)
    }

    public func removeObjectAtIndex(index: UInt) {
        rlmArray.removeObjectAtIndex(index)
    }

    public func removeLastObject() {
        rlmArray.removeLastObject()
    }

    public func removeAllObjects() {
        rlmArray.removeAllObjects()
    }

    public func replaceObjectAtIndex(index: UInt, withObject object: T) {
        rlmArray.replaceObjectAtIndex(index, withObject: object)
    }
}
