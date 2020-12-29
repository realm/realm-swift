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

// swiftlint:disable type_name identifier_name cyclomatic_complexity

import XCTest
import RealmSwift

class PrimitiveMutableSetTestsBase<O: ObjectFactory, V: ValueFactory>: TestCase {
    var realm: Realm?
    var obj: SwiftSetObject!
    var mutableSet: MutableSet<V.T>!
    var values: [V.T]!
    var valuesSet: Set<V.T>!

    class func _defaultTestSuite() -> XCTestSuite {
        return defaultTestSuite
    }

    override func setUp() {
        obj = SwiftSetObject()
        if O.isManaged() {
            let config = Realm.Configuration(inMemoryIdentifier: "test", objectTypes: [SwiftListObject.self])
            realm = try! Realm(configuration: config)
            realm!.beginWrite()
            realm!.add(obj)
        }
        mutableSet = V.mutableSet(obj)
        values = V.values()
        valuesSet = Set(values)
    }

    override func tearDown() {
        realm?.cancelWrite()
        realm = nil
        mutableSet = nil
        obj = nil
    }
}

class PrimitiveMutableSetTests<O: ObjectFactory, V: ValueFactory>: PrimitiveMutableSetTestsBase<O, V> {
    func testInvalidated() {
        XCTAssertFalse(mutableSet.isInvalidated)
        if let realm = obj.realm {
            realm.delete(obj)
            XCTAssertTrue(mutableSet.isInvalidated)
        }
    }

//    func testIndexOf() {
//        XCTAssertNil(mutableSet.index(of: values[0]))
//
//        mutableSet.insert(values[0])
//        XCTAssertEqual(0, mutableSet.index(of: values[0]))
//
//        mutableSet.insert(values[1])
//        XCTAssertEqual(0, mutableSet.index(of: values[0]))
//        XCTAssertEqual(1, mutableSet.index(of: values[1]))
//    }

    // FIXME: Not yet implemented
//    func disabled_testIndexMatching() {
//        XCTAssertNil(mutableSet.index(matching: "self = %@", values[0]))
//
//        mutableSet.insert(values[0])
//        XCTAssertEqual(0, mutableSet.index(matching: "self = %@", values[0]))
//
//        mutableSet.insert(values[1])
//        XCTAssertEqual(0, mutableSet.index(matching: "self = %@", values[0]))
//        XCTAssertEqual(1, mutableSet.index(matching: "self = %@", values[1]))
//    }

//    func testSubscript() {
//        mutableSet.insert(objectsIn: values)
//        for i in 0..<values.count {
//            XCTAssertEqual(mutableSet[i], values[i])
//        }
//        assertThrows(mutableSet[values.count], reason: "Index 3 is out of bounds")
//        assertThrows(mutableSet[-1], reason: "negative value")
//    }
//
//    func testFirst() {
//        mutableSet.insert(objectsIn: values)
//        XCTAssertEqual(mutableSet.first, values.first)
//        mutableSet.removeAll()
//        XCTAssertNil(mutableSet.first)
//    }
//
//    func testLast() {
//        mutableSet.insert(objectsIn: values)
//        XCTAssertEqual(mutableSet.last, values.last)
//        mutableSet.removeAll()
//        XCTAssertNil(mutableSet.last)
//
//    }

    func testValueForKey() {
        XCTAssertEqual(mutableSet.value(forKey: "self").count, 0)
        mutableSet.insert(objectsIn: values)

//        XCTAssertTrue( mutableSet.value(forKey: "self").map { /*values!.contains(dynamicBridgeCast(fromObjectiveC: $0) as V.T*/ print($0) ) }! )

        print(mutableSet)
        // two ambiguous value(forKeys)?

//        Set((mutableSet.value(forKey: "self") as [AnyObject])
//        mutableSet.value(forKey: "self").map { /*values!.contains(dynamicBridgeCast(fromObjectiveC: $0) as V.T*/ print($0) }!

        assertThrows(mutableSet.value(forKey: "not self"), named: "NSUnknownKeyException")
    }

    func testSetValueForKey() {
        // does this even make any sense?

    }

    func testFilter() {
        // not implemented

    }

    func testInsert() {
        XCTAssertEqual(Int(0), mutableSet.count)

        mutableSet.insert(values[0])
        XCTAssertEqual(Int(1), mutableSet.count)
        XCTAssertTrue(mutableSet.contains(values[0]))
//
//        mutableSet.insert(values[1])
//        XCTAssertEqual(Int(2), mutableSet.count)
//        XCTAssertEqual(values[1], mutableSet[0])
//        XCTAssertEqual(values[0], mutableSet[1])
//
//        mutableSet.insert(values[2])
//        XCTAssertEqual(Int(3), mutableSet.count)
//        XCTAssertEqual(values[1], mutableSet[0])
//        XCTAssertEqual(values[0], mutableSet[1])
//        XCTAssertEqual(values[2], mutableSet[2])
    }

    func testRemove() {
//        assertThrows(mutableSet.remove(at: 0))
//        assertThrows(mutableSet.remove(at: -1))
//
//        mutableSet.append(objectsIn: values)
//
//        assertThrows(mutableSet.remove(at: -1))
//        XCTAssertEqual(values[0], mutableSet[0])
//        XCTAssertEqual(values[1], mutableSet[1])
//        XCTAssertEqual(values[2], mutableSet[2])
//        assertThrows(mutableSet[3])
//
//        mutableSet.remove(at: 0)
//        XCTAssertEqual(values[1], mutableSet[0])
//        XCTAssertEqual(values[2], mutableSet[1])
//        assertThrows(mutableSet[2])
//        assertThrows(mutableSet.remove(at: 2))
//
//        mutableSet.remove(at: 1)
//        XCTAssertEqual(values[1], mutableSet[0])
//        assertThrows(mutableSet[1])
    }

    func testRemoveAll() {
        mutableSet.removeAll()
        mutableSet.insert(objectsIn: values)
        mutableSet.removeAll()
        XCTAssertEqual(mutableSet.count, 0)
    }
}

class MinMaxPrimitiveMutableSetTests<O: ObjectFactory, V: ValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.T: MinMaxType {
    func testMin() {
        XCTAssertNil(mutableSet.min())
        mutableSet.insert(objectsIn: values.reversed())
        XCTAssertEqual(mutableSet.min(), values.first)
    }

    func testMax() {
        XCTAssertNil(mutableSet.max())
        mutableSet.insert(objectsIn: values.reversed())
        XCTAssertEqual(mutableSet.max(), values.last)
    }
}

class OptionalMinMaxPrimitiveMutableSetTests<O: ObjectFactory, V: ValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.W: MinMaxType {
    // V.T and V.W? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.W
    var mutableSet2: MutableSet<V.W?> {
        return unsafeDowncast(mutableSet!, to: MutableSet<V.W?>.self)
    }

    func testMin() {
        XCTAssertNil(mutableSet2.min())
        mutableSet.insert(objectsIn: values.reversed())
        let expected = values[1] as! V.W
        XCTAssertEqual(mutableSet2.min(), expected)
    }

    func testMax() {
        XCTAssertNil(mutableSet2.max())
        mutableSet.insert(objectsIn: values.reversed())
        let expected = values[2] as! V.W
        XCTAssertEqual(mutableSet2.max(), expected)
    }
}

class AddablePrimitiveMutableSetTests<O: ObjectFactory, V: ValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.T: AddableType {
    func testSum() {
        XCTAssertEqual(mutableSet.sum(), V.T())
        mutableSet.insert(objectsIn: values)

        // Expressing "can be added and converted to a floating point type" as
        // a protocol requirement is awful, so sidestep it all with obj-c
        let expected = ((values.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(t: mutableSet.sum()), expected, accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(mutableSet.average() as V.AverageType?)
        mutableSet.insert(objectsIn: values)

        let expected = ((values.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(mutableSet.average()!), expected, accuracy: 0.01)
    }
}

class OptionalAddablePrimitiveMutableSetTests<O: ObjectFactory, V: ValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.W: AddableType {
    // V.T and V.W? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.W
    var mutableSet2: MutableSet<V.W?> {
        return unsafeDowncast(mutableSet!, to: MutableSet<V.W?>.self)
    }

    func testSum() {
        XCTAssertEqual(mutableSet2.sum(), V.W())
        mutableSet.insert(objectsIn: values)

        var nonNil = values!
        nonNil.remove(at: 0)

        // Expressing "can be added and converted to a floating point type" as
        // a protocol requirement is awful, so sidestep it all with obj-c
        let expected = ((nonNil.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(w: mutableSet2.sum()), expected, accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(mutableSet2.average() as Double?)
        mutableSet.insert(objectsIn: values)

        var nonNil = values!
        nonNil.remove(at: 0)

        let expected = ((nonNil.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(mutableSet2.average()!), expected, accuracy: 0.01)
    }
}

class SortablePrimitiveMutableSetTests<O: ObjectFactory, V: ValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.T: Comparable {
    func testSorted() {
        var shuffled = values!
        shuffled.removeFirst()
        shuffled.append(values!.first!)
        mutableSet.insert(objectsIn: shuffled)

//        assertEqual(mutableSet(mutableSet.sorted(ascending: true)), values)
//        assertEqual(mutableSet(mutableSet.sorted(ascending: false)), values.reversed())
    }
}

class OptionalSortablePrimitiveMutableSetTests<O: ObjectFactory, V: ValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.W: Comparable {
    func testSorted() {
        var shuffled = values!
        shuffled.removeFirst()
        shuffled.append(values!.first!)
        mutableSet.insert(objectsIn: shuffled)

        let mutableSet2 = unsafeDowncast(mutableSet!, to: List<V.W?>.self)
        let values2 = unsafeBitCast(values!, to: MutableSet<V.W?>.self)
//        assertEqual(mutableSet(mutableSet2.sorted(ascending: true)), values2)
//        assertEqual(mutableSet(mutableSet2.sorted(ascending: false)), values2.reversed())
    }
}

func addMutableSetTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    _ = PrimitiveMutableSetTests<OF, IntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, Int8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, Int16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, Int32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, Int64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, FloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, DoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, StringFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, DataFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, DateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, DecimalFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, ObjectIdFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = MinMaxPrimitiveMutableSetTests<OF, IntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMutableSetTests<OF, Int8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMutableSetTests<OF, Int16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMutableSetTests<OF, Int32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMutableSetTests<OF, Int64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMutableSetTests<OF, FloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMutableSetTests<OF, DoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMutableSetTests<OF, DateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMutableSetTests<OF, DecimalFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = AddablePrimitiveMutableSetTests<OF, IntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMutableSetTests<OF, Int8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMutableSetTests<OF, Int16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMutableSetTests<OF, Int32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMutableSetTests<OF, Int64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMutableSetTests<OF, FloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMutableSetTests<OF, DoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMutableSetTests<OF, DecimalFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = PrimitiveMutableSetTests<OF, OptionalIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalStringFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalDataFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalDateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalDecimalFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMutableSetTests<OF, OptionalObjectIdFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = OptionalMinMaxPrimitiveMutableSetTests<OF, OptionalIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMutableSetTests<OF, OptionalInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMutableSetTests<OF, OptionalInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMutableSetTests<OF, OptionalInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMutableSetTests<OF, OptionalInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMutableSetTests<OF, OptionalFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMutableSetTests<OF, OptionalDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMutableSetTests<OF, OptionalDateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMutableSetTests<OF, OptionalDecimalFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = OptionalAddablePrimitiveMutableSetTests<OF, OptionalIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMutableSetTests<OF, OptionalInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMutableSetTests<OF, OptionalInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMutableSetTests<OF, OptionalInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMutableSetTests<OF, OptionalInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMutableSetTests<OF, OptionalFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMutableSetTests<OF, OptionalDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMutableSetTests<OF, OptionalDecimalFactory>._defaultTestSuite().tests.map(suite.addTest)
}

class UnmanagedPrimitiveMutableSetTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged Primitive Lists")
        addMutableSetTests(suite, UnmanagedObjectFactory.self)
        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}

class ManagedPrimitiveMutableSetTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Managed Primitive Lists")
        addMutableSetTests(suite, ManagedObjectFactory.self)

        _ = SortablePrimitiveMutableSetTests<ManagedObjectFactory, IntFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int8Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int16Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int32Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int64Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMutableSetTests<ManagedObjectFactory, FloatFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMutableSetTests<ManagedObjectFactory, DoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMutableSetTests<ManagedObjectFactory, StringFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMutableSetTests<ManagedObjectFactory, DateFactory>._defaultTestSuite().tests.map(suite.addTest)

        _ = OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, OptionalIntFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, OptionalInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, OptionalInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, OptionalInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, OptionalInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, OptionalFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, OptionalDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, OptionalStringFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, OptionalDateFactory>._defaultTestSuite().tests.map(suite.addTest)

        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}
