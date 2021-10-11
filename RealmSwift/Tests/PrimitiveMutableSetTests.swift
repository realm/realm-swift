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

// swiftlint:disable identifier_name

import XCTest
import RealmSwift

class PrimitiveMutableSetTestsBase<O: ObjectFactory, V: SetValueFactory>: TestCase {
    var realm: Realm?
    var obj: V.SetRoot!
    var obj2: V.SetRoot!
    var mutableSet: MutableSet<V>!
    var otherMutableSet: MutableSet<V>!
    var values: [V]!

    class func _defaultTestSuite() -> XCTestSuite {
        return defaultTestSuite
    }

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

class MinMaxPrimitiveMutableSetTests<O: ObjectFactory, V: SetValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V: MinMaxType {
    func testMin() {
        XCTAssertNil(mutableSet.min())
        mutableSet.insert(objectsIn: values)
        XCTAssertEqual(mutableSet.min(), values.first)
    }

    func testMax() {
        XCTAssertNil(mutableSet.max())
        mutableSet.insert(objectsIn: values)
        XCTAssertEqual(mutableSet.max(), values.last)
    }
}

class OptionalMinMaxPrimitiveMutableSetTests<O: ObjectFactory, V: SetValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.Wrapped: MinMaxType, V.Wrapped: _DefaultConstructible {
    // V and V.Wrapped? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.Wrapped
    var mutableSet2: MutableSet<V.Wrapped?> {
        return unsafeDowncast(mutableSet!, to: MutableSet<V.Wrapped?>.self)
    }

    func testMin() {
        XCTAssertNil(mutableSet2.min())
        mutableSet.insert(objectsIn: values)
        let expected = values[1] as! V.Wrapped
        XCTAssertEqual(mutableSet2.min(), expected)
    }

    func testMax() {
        XCTAssertNil(mutableSet2.max())
        mutableSet.insert(objectsIn: values)
        let expected = values[2] as! V.Wrapped
        XCTAssertEqual(mutableSet2.max(), expected)
    }
}

class AddablePrimitiveMutableSetTests<O: ObjectFactory, V: SetValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V: AddableType {
    func testSum() {
        XCTAssertEqual(mutableSet.sum(), V())
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

class OptionalAddablePrimitiveMutableSetTests<O: ObjectFactory, V: SetValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.Wrapped: AddableType, V.Wrapped: _DefaultConstructible {
    // V and V.Wrapped? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.Wrapped
    var mutableSet2: MutableSet<V.Wrapped?> {
        return unsafeDowncast(mutableSet!, to: MutableSet<V.Wrapped?>.self)
    }

    func testSum() {
        XCTAssertEqual(mutableSet2.sum(), V.Wrapped())
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

class SortablePrimitiveMutableSetTests<O: ObjectFactory, V: SetValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V: Comparable {
    func testSorted() {
        var shuffled = values!
        shuffled.removeFirst()
        shuffled.append(values!.first!)
        mutableSet.insert(objectsIn: shuffled)

        assertEqual(Array(mutableSet.sorted(ascending: true)), values)
        assertEqual(Array(mutableSet.sorted(ascending: false)), values.reversed())
    }
}

class OptionalSortablePrimitiveMutableSetTests<O: ObjectFactory, V: SetValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.Wrapped: Comparable, V.Wrapped: _DefaultConstructible {
    func testSorted() {
        var shuffled = values!
        shuffled.removeFirst()
        shuffled.append(values!.first!)
        mutableSet.insert(objectsIn: shuffled)

        let mutableSet2 = unsafeDowncast(mutableSet!, to: MutableSet<V.Wrapped?>.self)
        let values2 = unsafeBitCast(values!, to: Array<V.Wrapped?>.self)
        assertEqual(Array(mutableSet2.sorted(ascending: true)), values2)
        assertEqual(Array(mutableSet2.sorted(ascending: false)), values2.reversed())
    }
}

func addMutableSetTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    PrimitiveMutableSetTests<OF, Int>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int8>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int16>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int32>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int64>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Float>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Double>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, String>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Data>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Date>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Decimal128>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, ObjectId>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, UUID>._defaultTestSuite().tests.forEach(suite.addTest)

    MinMaxPrimitiveMutableSetTests<OF, Int>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int8>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int16>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int32>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Int64>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Float>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Double>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Date>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMutableSetTests<OF, Decimal128>._defaultTestSuite().tests.forEach(suite.addTest)

    AddablePrimitiveMutableSetTests<OF, Int>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int8>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int16>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int32>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Int64>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Float>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Double>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMutableSetTests<OF, Decimal128>._defaultTestSuite().tests.forEach(suite.addTest)

    PrimitiveMutableSetTests<OF, Int?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int8?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int16?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int32?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Int64?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Float?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Double?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, String?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Data?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Date?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, Decimal128?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, ObjectId?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMutableSetTests<OF, UUID?>._defaultTestSuite().tests.forEach(suite.addTest)

    OptionalMinMaxPrimitiveMutableSetTests<OF, Int?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMutableSetTests<OF, Int8?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMutableSetTests<OF, Int16?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMutableSetTests<OF, Int32?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMutableSetTests<OF, Int64?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMutableSetTests<OF, Float?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMutableSetTests<OF, Double?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMutableSetTests<OF, Date?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMutableSetTests<OF, Decimal128?>._defaultTestSuite().tests.forEach(suite.addTest)

    OptionalAddablePrimitiveMutableSetTests<OF, Int?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMutableSetTests<OF, Int8?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMutableSetTests<OF, Int16?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMutableSetTests<OF, Int32?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMutableSetTests<OF, Int64?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMutableSetTests<OF, Float?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMutableSetTests<OF, Double?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMutableSetTests<OF, Decimal128?>._defaultTestSuite().tests.forEach(suite.addTest)
}

class UnmanagedPrimitiveMutableSetTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged Primitive Sets")
        addMutableSetTests(suite, UnmanagedObjectFactory.self)
        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}

class ManagedPrimitiveMutableSetTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Managed Primitive Sets")
        addMutableSetTests(suite, ManagedObjectFactory.self)

        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int8>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int16>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int32>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Int64>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Float>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Double>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, String>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMutableSetTests<ManagedObjectFactory, Date>._defaultTestSuite().tests.forEach(suite.addTest)

        OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, Int?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, Int8?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, Int16?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, Int32?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, Int64?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, Float?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, Double?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, String?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMutableSetTests<ManagedObjectFactory, Date?>._defaultTestSuite().tests.forEach(suite.addTest)

        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}
