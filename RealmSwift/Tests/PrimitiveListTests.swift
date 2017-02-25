////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

import XCTest
import RealmSwift

protocol ObjectFactory {
    static func isManaged() -> Bool
}

final class ManagedObjectFactory: ObjectFactory {
    static func isManaged() -> Bool { return true }
}
final class UnmanagedObjectFactory: ObjectFactory {
    static func isManaged() -> Bool { return false }
}

protocol ValueFactory {
    associatedtype T: RealmManaged, Equatable
    static func array(_ obj: SwiftListObject) -> List<T>
    static func values() -> [T]
}

final class IntFactory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Int> {
        return obj.int
    }

    static func values() -> [Int] {
        return [1, 2, 3]
    }
}

final class Int8Factory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Int8> {
        return obj.int8
    }

    static func values() -> [Int8] {
        return [1, 2, 3]
    }
}

final class Int16Factory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Int16> {
        return obj.int16
    }

    static func values() -> [Int16] {
        return [1, 2, 3]
    }
}

final class Int32Factory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Int32> {
        return obj.int32
    }

    static func values() -> [Int32] {
        return [1, 2, 3]
    }
}

final class Int64Factory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Int64> {
        return obj.int64
    }

    static func values() -> [Int64] {
        return [1, 2, 3]
    }
}

/*
final class OptionalIntFactory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Int?> {
        return obj.intOpt
    }

    static func values() -> [Int?] {
        return [nil, 1, 2, 3]
    }
}

final class OptionalInt8Factory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Int8?> {
        return obj.int8Opt
    }

    static func values() -> [Int8?] {
        return [nil, 1, 2, 3]
    }
}

final class OptionalInt16Factory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Int16?> {
        return obj.int16Opt
    }

    static func values() -> [Int16?] {
        return [nil, 1, 2, 3]
    }
}

final class OptionalInt32Factory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Int32?> {
        return obj.int32Opt
    }

    static func values() -> [Int32?] {
        return [nil, 1, 2, 3]
    }
}

final class OptionalInt64Factory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Int64?> {
        return obj.int64Opt
    }

    static func values() -> [Int64?] {
        return [nil, 1, 2, 3]
    }
}
*/

class PrimitiveListTests<O: ObjectFactory, V: ValueFactory>: TestCase {
    var realm: Realm!
    var obj: SwiftListObject!
    var array: List<V.T>!
    var values: [V.T]!

    override func setUp() {
        realm = try! Realm()
        realm.beginWrite()
        obj = SwiftListObject()
        if O.isManaged() {
            realm.add(obj)
        }
        array = V.array(obj)
        values = V.values()
    }

    override func tearDown() {
        realm.cancelWrite()
        realm = nil
    }

    func testInvalidated() {
        XCTAssertFalse(array.isInvalidated)
        if let realm = obj.realm {
            realm.delete(obj)
            XCTAssertTrue(array.isInvalidated)
        }
    }

    func testIndexOf() {
        XCTAssertNil(array.index(of: values[0]))

        array.append(values[0])
        XCTAssertEqual(0, array.index(of: values[0]))

        array.append(values[1])
        XCTAssertEqual(0, array.index(of: values[0]))
        XCTAssertEqual(1, array.index(of: values[1]))
    }

    func testIndexMatching() {
        XCTAssertNil(array.index(matching: "self = %@", values[0]))

        array.append(values[0])
        XCTAssertEqual(0, array.index(matching: "self = %@", values[0]))

        array.append(values[1])
        XCTAssertEqual(0, array.index(matching: "self = %@", values[0]))
        XCTAssertEqual(1, array.index(matching: "self = %@", values[1]))
    }

    func testSubscript() {

    }

    func testFirst() {

    }

    func testLast() {

    }

    func testValueForKey() {

    }

    func testSetValueForKey() {

    }

    func testFilter() {

    }

    func testSorted() {

    }

    func testMin() {

    }

    func testMax() {

    }

    func testSum() {

    }

    func testAverage() {

    }

    func testInsert() {
        XCTAssertEqual(Int(0), array.count)

        array.insert(values[0], at: 0)
        XCTAssertEqual(Int(1), array.count)
        XCTAssertEqual(values[0], array[0])

        array.insert(values[1], at: 0)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(values[1], array[0])
        XCTAssertEqual(values[0], array[1])

        array.insert(values[2], at: 2)
        XCTAssertEqual(Int(3), array.count)
        XCTAssertEqual(values[1], array[0])
        XCTAssertEqual(values[0], array[1])
        XCTAssertEqual(values[2], array[2])

        assertThrows(_ = array.insert(values[0], at: 4))
        assertThrows(_ = array.insert(values[0], at: -1))
    }

    func testRemove() {

    }

    func testRemoveLast() {

    }

    func testRemoveAll() {

    }

    func testReplace() {

    }

    func testMove() {

    }

    func testSwap() {

    }
}

func addTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    _ = PrimitiveListTests<OF, IntFactory>.defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, Int8Factory>.defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, Int16Factory>.defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, Int32Factory>.defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, Int64Factory>.defaultTestSuite().tests.map(suite.addTest)
}

class UnmanagedPrimitiveListTests: TestCase {
    override class func defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged Primitive Lists")
        addTests(suite, UnmanagedObjectFactory.self)
        return suite
    }
}

class ManagedPrimitiveListTests: TestCase {
    override class func defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Managed Primitive Lists")
        addTests(suite, ManagedObjectFactory.self)
        return suite
    }
}

/*
    func testPrimitive() {
        let obj = SwiftListObject()
        obj.int.append(5)
        XCTAssertEqual(obj.int.first!, 5)
        XCTAssertEqual(obj.int.last!, 5)
        XCTAssertEqual(obj.int[0], 5)
        obj.int.append(objectsIn: [6, 7, 8] as [Int])
        XCTAssertEqual(obj.int.index(of: 6), 1)
        XCTAssertEqual(2, obj.int.index(matching: NSPredicate(format: "self == 7")))
        XCTAssertNil(obj.int.index(matching: NSPredicate(format: "self == 9")))
        XCTAssertEqual(obj.int.max(), 8)
        XCTAssertEqual(obj.int.sum(), 26)

        obj.string.append("str")
        XCTAssertEqual(obj.string.first!, "str")
        XCTAssertEqual(obj.string[0], "str")
    }


//    func testFastEnumerationWithMutation() {
//        guard let array = array, let str1 = str1, let str2 = str2 else {
//            fatalError("Test precondition failure")
//        }
//
//        array.append(objectsIn: [str1, str2, str1, str2, str1, str2, str1, str2, str1,
//            str2, str1, str2, str1, str2, str1, str2, str1, str2, str1, str2])
//        var str = ""
//        for obj in array {
//            str += obj.stringCol
//            array.append(objectsIn: [str1])
//        }
//
//        XCTAssertEqual(str, "12121212121212121212")
//    }

    func testAppendObject() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }
        for str in [str1, str2, str1] {
            array.append(str)
        }
        XCTAssertEqual(Int(3), array.count)
        XCTAssertEqual(str1, array[0])
        XCTAssertEqual(str2, array[1])
        XCTAssertEqual(str1, array[2])
    }

    func testAppendArray() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }
        array.append(objectsIn: [str1, str2, str1])
        XCTAssertEqual(Int(3), array.count)
        XCTAssertEqual(str1, array[0])
        XCTAssertEqual(str2, array[1])
        XCTAssertEqual(str1, array[2])
    }

    func testAppendResults() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }
        array.append(objectsIn: realmWithTestPath().objects(SwiftStringObject.self))
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str1, array[0])
        XCTAssertEqual(str2, array[1])
    }

    func testInsert() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        XCTAssertEqual(Int(0), array.count)

        array.insert(str1, at: 0)
        XCTAssertEqual(Int(1), array.count)
        XCTAssertEqual(str1, array[0])

        array.insert(str2, at: 0)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str1, array[1])

        assertThrows(_ = array.insert(str2, at: 200))
        assertThrows(_ = array.insert(str2, at: -200))
    }

    func testRemoveAtIndex() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        array.append(objectsIn: [str1, str2, str1])

        array.remove(objectAtIndex: 1)
        XCTAssertEqual(str1, array[0])
        XCTAssertEqual(str1, array[1])

        assertThrows(array.remove(objectAtIndex: 200))
        assertThrows(array.remove(objectAtIndex: -200))
    }

    func testRemoveLast() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        array.append(objectsIn: [str1, str2])

        array.removeLast()
        XCTAssertEqual(Int(1), array.count)
        XCTAssertEqual(str1, array[0])

        array.removeLast()
        XCTAssertEqual(Int(0), array.count)

        array.removeLast() // should be a no-op
        XCTAssertEqual(Int(0), array.count)
    }

    func testRemoveAll() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        array.append(objectsIn: [str1, str2])

        array.removeAll()
        XCTAssertEqual(Int(0), array.count)

        array.removeAll() // should be a no-op
        XCTAssertEqual(Int(0), array.count)
    }

    func testReplace() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        array.append(objectsIn: [str1, str1])

        array.replace(index: 0, object: str2)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str1, array[1])

        array.replace(index: 1, object: str2)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str2, array[1])

        assertThrows(array.replace(index: 200, object: str2))
        assertThrows(array.replace(index: -200, object: str2))
    }

    func testMove() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        array.append(objectsIn: [str1, str2])

        array.move(from: 1, to: 0)

        XCTAssertEqual(array[0].stringCol, "2")
        XCTAssertEqual(array[1].stringCol, "1")

        array.move(from: 0, to: 1)

        XCTAssertEqual(array[0].stringCol, "1")
        XCTAssertEqual(array[1].stringCol, "2")

        array.move(from: 0, to: 0)

        XCTAssertEqual(array[0].stringCol, "1")
        XCTAssertEqual(array[1].stringCol, "2")

        assertThrows(array.move(from: 0, to: 2))
        assertThrows(array.move(from: 2, to: 0))
    }

    func testReplaceRange() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        array.append(objectsIn: [str1, str1])

        array.replaceSubrange(0..<1, with: [str2])
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str1, array[1])

        array.replaceSubrange(1..<2, with: [str2])
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str2, array[1])

        array.replaceSubrange(0..<0, with: [str2])
        XCTAssertEqual(Int(3), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str2, array[1])
        XCTAssertEqual(str2, array[2])

        array.replaceSubrange(0..<3, with: [])
        XCTAssertEqual(Int(0), array.count)

        assertThrows(array.replaceSubrange(200..<201, with: [str2]))
        assertThrows(array.replaceSubrange(-200..<200, with: [str2]))
        assertThrows(array.replaceSubrange(0..<200, with: [str2]))
    }

    func testSwap() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        array.append(objectsIn: [str1, str2])

        array.swap(index1: 0, 1)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str1, array[1])

        array.swap(index1: 1, 1)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str1, array[1])

        assertThrows(array.swap(index1: -1, 0))
        assertThrows(array.swap(index1: 0, -1))
        assertThrows(array.swap(index1: 1000, 0))
        assertThrows(array.swap(index1: 0, 1000))
    }

    func testChangesArePersisted() {
        guard let array = array, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }
        if let realm = array.realm {
            array.append(objectsIn: [str1, str2])

            let otherArray = realm.objects(SwiftArrayPropertyObject.self).first!.array
            XCTAssertEqual(Int(2), otherArray.count)
        }
    }
}*/
