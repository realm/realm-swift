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

import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif

class PrimitiveListTestsBase<O: ObjectFactory, V: ListValueFactory>: RLMTestCaseBase {
    var realm: Realm?
    var obj: V.ListRoot!
    var array: List<V>!
    var values: [V]!

    override func setUp() {
        obj = O.get()
        realm = obj.realm
        array = obj[keyPath: V.array]
        values = V.values()
    }

    override func tearDown() {
        realm?.cancelWrite()
        array = nil
        obj = nil
        realm = nil
    }

    // These test suites run such a large number of very short tests that the
    // setup/teardown overhead from TestCase ends up being a significant portion
    // of the runtime, so bypass that and replicate just the bit we need here.
    override func invokeTest() {
        autoreleasepool { super.invokeTest() }
    }

    func assertThrows<T>(_ block: @autoclosure () -> T, named: String? = RLMExceptionName,
                         _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line) {
        RLMAssertThrowsWithName(self, { _ = block() }, named, message, fileName, lineNumber)
    }

    func assertThrows<T>(_ block: @autoclosure () -> T, reason: String,
                         _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line) {
        RLMAssertThrowsWithReason(self, { _ = block() }, reason, message, fileName, lineNumber)
    }

    func assertThrows<T>(_ block: @autoclosure () -> T, reasonMatching regexString: String,
                         _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line) {
        RLMAssertThrowsWithReasonMatching(self, { _ = block() }, regexString, message, fileName, lineNumber)
    }
}

class PrimitiveListTests<O: ObjectFactory, V: ListValueFactory & _RealmSchemaDiscoverable>: PrimitiveListTestsBase<O, V> {
    func testInvalidated() {
        XCTAssertFalse(array.isInvalidated)
        if let realm = obj.realm {
            realm.delete(obj)
            XCTAssertTrue(array.isInvalidated)
        }
    }

    func testIndexOf() {
        guard V._rlmType != .object else { return }

        XCTAssertNil(array.index(of: values[0]))

        array.append(values[0])
        XCTAssertEqual(0, array.index(of: values[0]))

        array.append(values[1])
        XCTAssertEqual(0, array.index(of: values[0]))
        XCTAssertEqual(1, array.index(of: values[1]))
    }

    // FIXME: Not yet implemented
    func disabled_testIndexMatching() {
        XCTAssertNil(array.index(matching: "self = %@", values[0]))

        array.append(values[0])
        XCTAssertEqual(0, array.index(matching: "self = %@", values[0]))

        array.append(values[1])
        XCTAssertEqual(0, array.index(matching: "self = %@", values[0]))
        XCTAssertEqual(1, array.index(matching: "self = %@", values[1]))
    }

    func testSubscript() {
        array.append(objectsIn: values)
        for i in 0..<values.count {
            XCTAssertEqual(array[i], values[i])
        }
        assertThrows(array[values.count], reason: "Index 3 is out of bounds")
        assertThrows(array[-1], reason: "negative value")
    }

    func testFirst() {
        array.append(objectsIn: values)
        XCTAssertEqual(array.first, values.first)
        array.removeAll()
        XCTAssertNil(array.first)
    }

    func testLast() {
        array.append(objectsIn: values)
        XCTAssertEqual(array.last, values.last)
        array.removeAll()
        XCTAssertNil(array.last)

    }

    func testObjectsAtIndexes() {
        assertThrows(array.objects(at: [1, 2, 3]), reason: "Indexes for collection are out of bounds.")
        array.append(objectsIn: values)
        let objs = array.objects(at: [2, 1])
        XCTAssertEqual(values[1], objs.first) // this is broke
        XCTAssertEqual(values[2], objs.last)
    }

    func testValueForKey() {
        XCTAssertEqual(array.value(forKey: "self").count, 0)
        array.append(objectsIn: values)
        XCTAssertEqual(values!, array.value(forKey: "self").map { dynamicBridgeCast(fromObjectiveC: $0) as V })

        assertThrows(array.value(forKey: "not self"), named: "NSUnknownKeyException")
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

        assertThrows(array.insert(values[0], at: 4))
        assertThrows(array.insert(values[0], at: -1))
    }

    func testRemove() {
        assertThrows(array.remove(at: 0))
        assertThrows(array.remove(at: -1))

        array.append(objectsIn: values)

        assertThrows(array.remove(at: -1))
        XCTAssertEqual(values[0], array[0])
        XCTAssertEqual(values[1], array[1])
        XCTAssertEqual(values[2], array[2])
        assertThrows(array[3])

        array.remove(at: 0)
        XCTAssertEqual(values[1], array[0])
        XCTAssertEqual(values[2], array[1])
        assertThrows(array[2])
        assertThrows(array.remove(at: 2))

        array.remove(at: 1)
        XCTAssertEqual(values[1], array[0])
        assertThrows(array[1])
    }

    func testRemoveLast() {
        assertThrows(array.removeLast())

        array.append(objectsIn: values)
        array.removeLast()

        XCTAssertEqual(array.count, 2)
        XCTAssertEqual(values[0], array[0])
        XCTAssertEqual(values[1], array[1])

        array.removeLast(2)
        XCTAssertEqual(array.count, 0)
    }

    func testRemoveAll() {
        array.removeAll()
        array.append(objectsIn: values)
        array.removeAll()
        XCTAssertEqual(array.count, 0)
    }

    func testReplace() {
        assertThrows(array.replace(index: 0, object: values[0]),
                     reason: "Index 0 is out of bounds")

        array.append(objectsIn: values)
        array.replace(index: 1, object: values[0])
        XCTAssertEqual(array[0], values[0])
        XCTAssertEqual(array[1], values[0])
        XCTAssertEqual(array[2], values[2])

        assertThrows(array.replace(index: 3, object: values[0]),
                     reason: "Index 3 is out of bounds")
        assertThrows(array.replace(index: -1, object: values[0]),
                     reason: "Cannot pass a negative value")
    }

    func testReplaceRange() {
        assertSucceeds { array.replaceSubrange(0..<0, with: []) }

#if false
        // FIXME: The exception thrown here runs afoul of Swift's exclusive access checking.
        assertThrows(array.replaceSubrange(0..<1, with: []),
                     reason: "Index 0 is out of bounds")
#endif

        array.replaceSubrange(0..<0, with: [values[0]])
        XCTAssertEqual(array.count, 1)
        XCTAssertEqual(array[0], values[0])

        array.replaceSubrange(0..<1, with: values)
        XCTAssertEqual(array.count, 3)

        array.replaceSubrange(1..<2, with: [])
        XCTAssertEqual(array.count, 2)
        XCTAssertEqual(array[0], values[0])
        XCTAssertEqual(array[1], values[2])
    }

    func testMove() {
        assertThrows(array.move(from: 1, to: 0), reason: "out of bounds")

        array.append(objectsIn: values)
        array.move(from: 2, to: 0)
        XCTAssertEqual(array[0], values[2])
        XCTAssertEqual(array[1], values[0])
        XCTAssertEqual(array[2], values[1])

        assertThrows(array.move(from: 3, to: 0), reason: "Index 3 is out of bounds")
        assertThrows(array.move(from: 0, to: 3), reason: "Index 3 is out of bounds")
        assertThrows(array.move(from: -1, to: 0), reason: "negative value")
        assertThrows(array.move(from: 0, to: -1), reason: "negative value")
    }

    func testSwap() {
        assertThrows(array.swapAt(0, 1), reason: "out of bounds")

        array.append(objectsIn: values)
        array.swapAt(0, 2)
        XCTAssertEqual(array[0], values[2])
        XCTAssertEqual(array[1], values[1])
        XCTAssertEqual(array[2], values[0])

        assertThrows(array.swapAt(3, 0), reason: "Index 3 is out of bounds")
        assertThrows(array.swapAt(0, 3), reason: "Index 3 is out of bounds")
        assertThrows(array.swapAt(-1, 0), reason: "negative value")
        assertThrows(array.swapAt(0, -1), reason: "negative value")
    }
}

class MinMaxPrimitiveListTests<O: ObjectFactory, V: ListValueFactory>: PrimitiveListTestsBase<O, V> where V.PersistedType: MinMaxType {
    func testMin() {
        XCTAssertNil(array.min())
        array.append(objectsIn: values.reversed())
        XCTAssertEqual(array.min(), V.min())
    }

    func testMax() {
        XCTAssertNil(array.max())
        array.append(objectsIn: values.reversed())
        XCTAssertEqual(array.max(), V.max())
    }
}

class AddablePrimitiveListTests<O: ObjectFactory, V: ListValueFactory>: PrimitiveListTestsBase<O, V> where V: NumericValueFactory, V.PersistedType: AddableType {
    func testSum() {
        XCTAssertEqual(array.sum(), .zero)
        array.append(objectsIn: values)
        XCTAssertEqual(V.doubleValue(array.sum()), V.sum(), accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(array.average() as V.AverageType?)
        array.append(objectsIn: values)
        XCTAssertEqual(V.doubleValue(array.average()!), V.average(), accuracy: 0.01)
    }
}

private func rotate<T>(_ values: Array<T>) -> Array<T> {
    var shuffled = values
    shuffled.removeFirst()
    shuffled.append(values.first!)
    return shuffled
}

class SortablePrimitiveListTests<O: ObjectFactory, V: ListValueFactory>: PrimitiveListTestsBase<O, V> where V.PersistedType: SortableType {
    func testSorted() {
        array.append(objectsIn: rotate(values!))
        assertEqual(Array(array.sorted(ascending: true)), values)
        assertEqual(Array(array.sorted(ascending: false)), values.reversed())
    }

    func testDistinct() {
        array.append(objectsIn: values!)
        array.append(objectsIn: values!)
        assertEqual(Array(array.distinct()), values!)
    }
}

func addTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    // Plain types
    PrimitiveListTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, String>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Data>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, ObjectId>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, UUID>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxPrimitiveListTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)

    AddablePrimitiveListTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)

    // Optional plain types
    PrimitiveListTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, String?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Data?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Date?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, ObjectId?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, UUID?>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxPrimitiveListTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Date?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)

    AddablePrimitiveListTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)

    // Enum wrappers
    PrimitiveListTests<OF, EnumInt>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt8>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt16>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt32>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt64>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumFloat>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumDouble>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumString>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxPrimitiveListTests<OF, EnumInt>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumInt8>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumInt16>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumInt32>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumInt64>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumFloat>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumDouble>.defaultTestSuite.tests.forEach(suite.addTest)

    // Optional Enum wrappers
    PrimitiveListTests<OF, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumString?>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxPrimitiveListTests<OF, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)

    // Custom persistable wrappers
    PrimitiveListTests<OF, IntWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int8Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int16Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int32Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int64Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, FloatWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, DoubleWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, StringWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, DataWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, DateWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Decimal128Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, ObjectIdWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, UUIDWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EmbeddedObjectWrapper>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxPrimitiveListTests<OF, IntWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int8Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int16Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int32Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int64Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, FloatWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, DoubleWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, DateWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Decimal128Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)

    AddablePrimitiveListTests<OF, IntWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int8Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int16Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int32Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int64Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, FloatWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, DoubleWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Decimal128Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)

    // Optional custom persistable wrappers
    PrimitiveListTests<OF, IntWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int8Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int16Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int32Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Int64Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, FloatWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, DoubleWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, StringWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, DataWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, DateWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, Decimal128Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, ObjectIdWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, UUIDWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxPrimitiveListTests<OF, IntWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int8Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int16Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int32Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Int64Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, FloatWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, DoubleWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, DateWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveListTests<OF, Decimal128Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)

    AddablePrimitiveListTests<OF, IntWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int8Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int16Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int32Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Int64Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, FloatWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, DoubleWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveListTests<OF, Decimal128Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
}

class UnmanagedPrimitiveListTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged Primitive Lists")
        addTests(suite, UnmanagedObjectFactory.self)
        return suite
    }
}

class ManagedPrimitiveListTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Managed Primitive Lists")
        addTests(suite, ManagedObjectFactory.self)

        SortablePrimitiveListTests<ManagedObjectFactory, Int>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Float>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Double>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, String>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Date>.defaultTestSuite.tests.forEach(suite.addTest)

        SortablePrimitiveListTests<ManagedObjectFactory, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, String?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Date?>.defaultTestSuite.tests.forEach(suite.addTest)

        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt8>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt16>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt32>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt64>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumFloat>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumDouble>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumString>.defaultTestSuite.tests.forEach(suite.addTest)

        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumString?>.defaultTestSuite.tests.forEach(suite.addTest)

        SortablePrimitiveListTests<ManagedObjectFactory, IntWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int8Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int16Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int32Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int64Wrapper>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, FloatWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, DoubleWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, StringWrapper>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, DateWrapper>.defaultTestSuite.tests.forEach(suite.addTest)

        SortablePrimitiveListTests<ManagedObjectFactory, IntWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int8Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int16Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int32Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, Int64Wrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, FloatWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, DoubleWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, StringWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, DateWrapper?>.defaultTestSuite.tests.forEach(suite.addTest)

        return suite
    }
}
