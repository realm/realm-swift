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

class RealmArray<T: RealmObject>: Sequence, Printable {
    var rlmArray: RLMArray
    var count: Int { return rlmArray.count }
    var objectClassName: String { return rlmArray.objectClassName }
    var readOnly: Bool { return rlmArray.readOnly }
    var realm: Realm { return Realm(rlmRealm: rlmArray.realm) }

    var description: String { return rlmArray.description }
    var property: RLMArray { return rlmArray }

    init() {
        rlmArray = RLMArray(objectClassName: RLMSwiftSupport.demangleClassName(NSStringFromClass(T.self)))
    }

    convenience init(rlmArray: RLMArray) {
        self.init()
        self.rlmArray = rlmArray
    }

    subscript(index: UInt) -> T {
        get {
            return rlmArray[Int(index)] as T
        }
        set {
            return rlmArray[Int(index)] = newValue
        }
    }

    func firstObject() -> T? {
        return rlmArray.firstObject() as T?
    }

    func lastObject() -> T? {
        return rlmArray.lastObject() as T?
    }

    func indexOfObject(object: T) -> UInt? {
        let index = rlmArray.indexOfObject(object)
        if index == NSNotFound {
            return nil
        }
        return UInt(index)
    }

    func indexOfObjectWithPredicate(predicate: NSPredicate) -> UInt? {
        let index = rlmArray.indexOfObjectWithPredicate(predicate)
        if index == NSNotFound {
            return nil
        }
        return UInt(index)
    }

    // Swift query convenience functions

    func indexOfObjectWhere(predicateFormat: String, _ args: CVarArg...) -> Int {
        return rlmArray.indexOfObjectWhere(predicateFormat, args: getVaList(args))
    }

    func objectsWhere(predicateFormat: String, _ args: CVarArg...) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: rlmArray.objectsWhere(predicateFormat, args: getVaList(args)))
    }

    func objectsWithPredicate(predicate: NSPredicate) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: rlmArray.objectsWithPredicate(predicate))
    }

    func arraySortedByProperty(property: String, ascending: Bool) -> RealmArray<T> {
        return RealmArray<T>(rlmArray: rlmArray.arraySortedByProperty(property, ascending: ascending))
    }

    func minOfProperty(property: String) -> AnyObject {
        return rlmArray.minOfProperty(property)
    }

    func maxOfProperty(property: String) -> AnyObject {
        return rlmArray.maxOfProperty(property)
    }

    func sumOfProperty(property: String) -> Double {
        return rlmArray.sumOfProperty(property) as Double
    }

    func averageOfProperty(property: String) -> Double {
        return rlmArray.averageOfProperty(property) as Double
    }

    func JSONString() -> String {
        return rlmArray.JSONString()
    }

    func generate() -> GeneratorOf<T> {
        var i  = 0
        return GeneratorOf<T>({
            if (i >= self.rlmArray.count) {
                return .None
            } else {
                return self.rlmArray[i++] as? T
            }
        })
    }

    func addObject(object: T) {
        rlmArray.addObject(object)
    }

    func addObjects(objects: [AnyObject]) {
        rlmArray.addObjectsFromArray(objects)
    }

    func insertObject(object: T, atIndex index: UInt) {
        rlmArray.insertObject(object, atIndex: Int(index))
    }

    func removeObjectAtIndex(index: UInt) {
        rlmArray.removeObjectAtIndex(Int(index))
    }

    func removeLastObject() {
        rlmArray.removeLastObject()
    }

    func removeAllObjects() {
        rlmArray.removeAllObjects()
    }

    func replaceObjectAtIndex(index: UInt, withObject object: T) {
        rlmArray.replaceObjectAtIndex(Int(index), withObject: object)
    }
}
