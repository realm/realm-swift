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

class PrimitiveListTestsBase<O: ObjectFactory, V: ListValueFactory>: TestCase {
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
}

class PrimitiveListTests<O: ObjectFactory, V: ListValueFactory>: PrimitiveListTestsBase<O, V> {
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

    func testSetValueForKey() {
        // does this even make any sense?

    }

    func testFilter() {
        // not implemented
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

class MinMaxPrimitiveListTests<O: ObjectFactory, V: ListValueFactory>: PrimitiveListTestsBase<O, V> where V: MinMaxType {
    func testMin() {
        XCTAssertNil(array.min())
        array.append(objectsIn: values.reversed())
        XCTAssertEqual(array.min(), values.first)
    }

    func testMax() {
        XCTAssertNil(array.max())
        array.append(objectsIn: values.reversed())
        XCTAssertEqual(array.max(), values.last)
    }
}

class OptionalMinMaxPrimitiveListTests<O: ObjectFactory, V: ListValueFactory>: PrimitiveListTestsBase<O, V> where V.Wrapped: MinMaxType, V.Wrapped: _DefaultConstructible {
    // V and V.Wrapped? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.Wrapped
    var array2: List<V.Wrapped?> {
        return unsafeDowncast(array!, to: List<V.Wrapped?>.self)
    }

    func testMin() {
        XCTAssertNil(array2.min())
        array.append(objectsIn: values.reversed())
        let expected = values[1] as! V.Wrapped
        XCTAssertEqual(array2.min(), expected)
    }

    func testMax() {
        XCTAssertNil(array2.max())
        array.append(objectsIn: values.reversed())
        let expected = values[2] as! V.Wrapped
        XCTAssertEqual(array2.max(), expected)
    }
}

class AddablePrimitiveListTests<O: ObjectFactory, V: ListValueFactory>: PrimitiveListTestsBase<O, V> where V: AddableType {
    func testSum() {
        XCTAssertEqual(array.sum(), V())
        array.append(objectsIn: values)

        // Expressing "can be added and converted to a floating point type" as
        // a protocol requirement is awful, so sidestep it all with obj-c
        let expected = ((values.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(t: array.sum()), expected, accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(array.average() as V.AverageType?)
        array.append(objectsIn: values)

        let expected = ((values.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(array.average()!), expected, accuracy: 0.01)
    }
}

class OptionalAddablePrimitiveListTests<O: ObjectFactory, V: ListValueFactory>: PrimitiveListTestsBase<O, V> where V.Wrapped: AddableType, V.Wrapped: _DefaultConstructible {
    // V.T and V.Wrapped? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.Wrapped
    var array2: List<V.Wrapped?> {
        return unsafeDowncast(array!, to: List<V.Wrapped?>.self)
    }

    func testSum() {
        XCTAssertEqual(array2.sum(), V.Wrapped())
        array.append(objectsIn: values)

        var nonNil = values!
        nonNil.remove(at: 0)

        // Expressing "can be added and converted to a floating point type" as
        // a protocol requirement is awful, so sidestep it all with obj-c
        let expected = ((nonNil.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(w: array2.sum()), expected, accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(array2.average() as Double?)
        array.append(objectsIn: values)

        var nonNil = values!
        nonNil.remove(at: 0)

        let expected = ((nonNil.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(array2.average()!), expected, accuracy: 0.01)
    }
}

private func rotate<T>(_ values: Array<T>) -> Array<T> {
    var shuffled = values
    shuffled.removeFirst()
    shuffled.append(values.first!)
    return shuffled
}

class SortablePrimitiveListTests<O: ObjectFactory, V: ListValueFactory>: PrimitiveListTestsBase<O, V> where V: Comparable {
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

class OptionalSortablePrimitiveListTests<O: ObjectFactory, V: ListValueFactory>: PrimitiveListTestsBase<O, V> where V.Wrapped: Comparable, V.Wrapped: _DefaultConstructible {
    func testSorted() {
        array.append(objectsIn: rotate(values!))
        let array2 = unsafeDowncast(array!, to: List<V.Wrapped?>.self)
        let values2 = unsafeBitCast(values!, to: Array<V.Wrapped?>.self)
        assertEqual(Array(array2.sorted(ascending: true)), values2)
        assertEqual(Array(array2.sorted(ascending: false)), values2.reversed())
    }

    func testDistinct() {
        array.append(objectsIn: values!)
        array.append(objectsIn: values!)
        let array2 = unsafeDowncast(array!, to: List<V.Wrapped?>.self)
        let values2 = unsafeBitCast(values!, to: Array<V.Wrapped?>.self)
        assertEqual(Array(array2.distinct()), values2)
    }
}

func addTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
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

    OptionalMinMaxPrimitiveListTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, Date?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)

    OptionalAddablePrimitiveListTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalAddablePrimitiveListTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalAddablePrimitiveListTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalAddablePrimitiveListTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalAddablePrimitiveListTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalAddablePrimitiveListTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalAddablePrimitiveListTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalAddablePrimitiveListTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)

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

    PrimitiveListTests<OF, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveListTests<OF, EnumString?>.defaultTestSuite.tests.forEach(suite.addTest)

    OptionalMinMaxPrimitiveListTests<OF, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveListTests<OF, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
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

        OptionalSortablePrimitiveListTests<ManagedObjectFactory, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, String?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, Date?>.defaultTestSuite.tests.forEach(suite.addTest)

        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt8>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt16>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt32>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumInt64>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumFloat>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumDouble>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveListTests<ManagedObjectFactory, EnumString>.defaultTestSuite.tests.forEach(suite.addTest)

        OptionalSortablePrimitiveListTests<ManagedObjectFactory, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
        OptionalSortablePrimitiveListTests<ManagedObjectFactory, EnumString?>.defaultTestSuite.tests.forEach(suite.addTest)

        return suite
    }
}
