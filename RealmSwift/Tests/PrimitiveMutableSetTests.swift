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

import XCTest
import RealmSwift

class PrimitiveMutableSetTestsBase<O: ObjectFactory, V: SetValueFactory>: TestCase {
    var realm: Realm?
    var obj: V.SetRoot!
    var obj2: V.SetRoot!
    var mutableSet: MutableSet<V>!
    var otherMutableSet: MutableSet<V>!
    var values: [V]!

    override func setUp() {
        obj = O.get()
        obj2 = O.get()
        realm = obj.realm
        mutableSet = obj[keyPath: V.mutableSet]
        otherMutableSet = obj2[keyPath: V.mutableSet]
        values = V.values()
    }

    override func tearDown() {
        realm?.cancelWrite()
        mutableSet = nil
        otherMutableSet = nil
        obj = nil
        obj2 = nil
        realm = nil
    }
}

class PrimitiveMutableSetTests<O: ObjectFactory, V: SetValueFactory>: PrimitiveMutableSetTestsBase<O, V> {
    func testInvalidated() {
        XCTAssertFalse(mutableSet.isInvalidated)
        if let realm = obj.realm {
            realm.delete(obj)
            XCTAssertTrue(mutableSet.isInvalidated)
        }
    }

    func testValueForKey() {
        XCTAssertEqual(mutableSet.value(forKey: "self").count, 0)
        mutableSet.insert(objectsIn: values)
        let valuesSet = Set(values!)
        let kvoSet = Set(mutableSet.value(forKey: "self").map { dynamicBridgeCast(fromObjectiveC: $0) as V })
        XCTAssertEqual(valuesSet, kvoSet)
        assertThrows(mutableSet.value(forKey: "not self"), named: "NSUnknownKeyException")
    }

    func testInsert() {
        XCTAssertEqual(Int(0), mutableSet.count)

        mutableSet.insert(values[0])
        XCTAssertEqual(Int(1), mutableSet.count)
        XCTAssertTrue(mutableSet.contains(values[0]))

        mutableSet.insert(values[1])
        XCTAssertEqual(Int(2), mutableSet.count)
        XCTAssertTrue(mutableSet.contains(values[0]))
        XCTAssertTrue(mutableSet.contains(values[1]))

        mutableSet.insert(values[2])
        XCTAssertEqual(Int(3), mutableSet.count)
        XCTAssertTrue(mutableSet.contains(values[0]))
        XCTAssertTrue(mutableSet.contains(values[1]))

        mutableSet.insert(values[2])
        XCTAssertEqual(Int(3), mutableSet.count)
        XCTAssertTrue(mutableSet.contains(values[0]))
        XCTAssertTrue(mutableSet.contains(values[1]))
        XCTAssertTrue(mutableSet.contains(values[2]))
        // Insert duplicate
        mutableSet.insert(values[2])
        XCTAssertEqual(Int(3), mutableSet.count)
        XCTAssertTrue(mutableSet.contains(values[0]))
        XCTAssertTrue(mutableSet.contains(values[1]))
        XCTAssertTrue(mutableSet.contains(values[2]))
    }

    func testRemove() {
        mutableSet.removeAll()
        XCTAssertEqual(mutableSet.count, 0)
        mutableSet.insert(objectsIn: values)
        mutableSet.remove(values[0])
        XCTAssertFalse(mutableSet.contains(values[0]))
        XCTAssertTrue(mutableSet.contains(values[1]))
        XCTAssertTrue(mutableSet.contains(values[2]))
    }

    func testRemoveAll() {
        mutableSet.removeAll()
        mutableSet.insert(objectsIn: values)
        mutableSet.removeAll()
        XCTAssertEqual(mutableSet.count, 0)
    }

    func testIsSubset() {
        XCTAssertEqual(Int(0), mutableSet.count)
        XCTAssertEqual(Int(0), otherMutableSet.count)
        mutableSet.insert(objectsIn: values)
        otherMutableSet.insert(values[0])
        // Both sets contain values[0]
        XCTAssertTrue(otherMutableSet.isSubset(of: mutableSet))
        otherMutableSet.remove(values[0])
        XCTAssertFalse(mutableSet.isSubset(of: otherMutableSet))
    }

    func testContains() {
        XCTAssertEqual(Int(0), mutableSet.count)
        XCTAssertEqual(Int(0), otherMutableSet.count)
        mutableSet.insert(objectsIn: values)
        XCTAssertEqual(values.count, mutableSet.count)
        values.forEach {
            XCTAssertTrue(mutableSet.contains($0))
        }
    }

    func testIntersects() {
        XCTAssertEqual(Int(0), mutableSet.count)
        XCTAssertEqual(Int(0), otherMutableSet.count)
        mutableSet.insert(objectsIn: values)
        otherMutableSet.insert(values[0])
        // Both sets contain values[0]
        XCTAssertTrue(otherMutableSet.intersects(mutableSet))
        otherMutableSet.remove(values[0])
        XCTAssertFalse(mutableSet.intersects(otherMutableSet))
    }

    func testFormIntersection() {
        XCTAssertEqual(Int(0), mutableSet.count)
        XCTAssertEqual(Int(0), otherMutableSet.count)
        mutableSet.insert(objectsIn: values)
        otherMutableSet.insert(values[0])
        // Both sets contain values[0]
        mutableSet.formIntersection(otherMutableSet)
        XCTAssertEqual(Int(1), mutableSet.count)
        assertSetContains(mutableSet, keyPath: \.self, items: [values[0]])
    }

    func testFormUnion() {
        XCTAssertEqual(Int(0), mutableSet.count)
        XCTAssertEqual(Int(0), otherMutableSet.count)
        mutableSet.insert(values[0])
        mutableSet.insert(values[1])
        otherMutableSet.insert(values[0])
        otherMutableSet.insert(values[2])
        mutableSet.formUnion(otherMutableSet)
        XCTAssertEqual(Int(3), mutableSet.count)
        assertSetContains(mutableSet, keyPath: \.self, items: [values[0], values[1], values[2]])
    }

    func testSubtract() {
        XCTAssertEqual(Int(0), mutableSet.count)
        XCTAssertEqual(Int(0), otherMutableSet.count)
        mutableSet.insert(values[0])
        mutableSet.insert(values[1])
        otherMutableSet.insert(values[0])
        otherMutableSet.insert(values[2])
        mutableSet.subtract(otherMutableSet)
        XCTAssertEqual(Int(1), mutableSet.count)
        XCTAssertFalse(mutableSet.contains(values[0]))
        XCTAssertTrue(mutableSet.contains(values[1]))
    }

    func testSubscript() {
        mutableSet.insert(objectsIn: values)
        XCTAssertTrue(values.contains(mutableSet[0]))
        XCTAssertTrue(values.contains(mutableSet[1]))
        XCTAssertTrue(values.contains(mutableSet[2]))
    }
}

class MinMaxPrimitiveMutableSetTests<O: ObjectFactory, V: SetValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.PersistedType: MinMaxType {
    func testMin() {
        XCTAssertNil(mutableSet.min())
        mutableSet.insert(objectsIn: values)
        XCTAssertEqual(mutableSet.min(), V.min())
    }

    func testMax() {
        XCTAssertNil(mutableSet.max())
        mutableSet.insert(objectsIn: values)
        XCTAssertEqual(mutableSet.max(), V.max())
    }
}

class AddablePrimitiveMutableSetTests<O: ObjectFactory, V: SetValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V: NumericValueFactory, V.PersistedType: AddableType {
    func testSum() {
        XCTAssertEqual(mutableSet.sum(), .zero)
        mutableSet.insert(objectsIn: values)
        XCTAssertEqual(V.doubleValue(mutableSet.sum()), V.sum(), accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(mutableSet.average() as V.AverageType?)
        mutableSet.insert(objectsIn: values)
        XCTAssertEqual(V.doubleValue(mutableSet.average()!), V.average(), accuracy: 0.01)
    }
}

class SortablePrimitiveMutableSetTests<O: ObjectFactory, V: SetValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.PersistedType: SortableType {
    func testSorted() {
        var shuffled = values!
        shuffled.removeFirst()
        shuffled.append(values!.first!)
        mutableSet.insert(objectsIn: shuffled)

        assertEqual(Array(mutableSet.sorted(ascending: true)), values)
        assertEqual(Array(mutableSet.sorted(ascending: false)), values.reversed())
    }
}

func addMutableSetTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    PrimitiveMutableSetTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, String>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Data>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, ObjectId>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, UUID>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxPrimitiveMutableSetTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)

    AddablePrimitiveMutableSetTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)

    PrimitiveMutableSetTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, String?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Data?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Date?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, ObjectId?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, UUID?>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxPrimitiveMutableSetTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Date?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)

    AddablePrimitiveMutableSetTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)

    PrimitiveMutableSetTests<OF, EnumInt>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumInt8>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumInt16>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumInt32>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumInt64>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumFloat>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumDouble>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumString>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxPrimitiveMutableSetTests<OF, EnumInt>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumInt8>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumInt16>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumInt32>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumInt64>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumFloat>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumDouble>.defaultTestSuite.tests.forEach(suite.addTest)

    PrimitiveMutableSetTests<OF, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, EnumString?>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxPrimitiveMutableSetTests<OF, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
}

class UnmanagedPrimitiveMutableSetTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged Primitive Sets")
        addMutableSetTests(suite, UnmanagedObjectFactory.self)
        return suite
    }
}

class ManagedPrimitiveMutableSetTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Managed Primitive Sets")
        addMutableSetTests(suite, ManagedObjectFactory.self)

        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Float>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Double>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, String>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Date>.defaultTestSuite.tests.forEach(suite.addTest)

        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, String?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Date?>.defaultTestSuite.tests.forEach(suite.addTest)

        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumInt>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumInt8>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumInt16>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumInt32>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumInt64>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumFloat>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumDouble>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumString>.defaultTestSuite.tests.forEach(suite.addTest)

        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, EnumString?>.defaultTestSuite.tests.forEach(suite.addTest)

        return suite
    }
}
