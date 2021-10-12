////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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
import Realm
import RealmSwift

// swiftlint:disable identifier_name cyclomatic_complexity

class PrimitiveMapTestsBase<O: ObjectFactory, V: MapValueFactory>: TestCase {
    var realm: Realm?
    var obj: V.MapRoot!
    var obj2: V.MapRoot!
    var map: Map<String, V>!
    var otherMap: Map<String, V>!
    var values: [(key: String, value: V)]!

    class func _defaultTestSuite() -> XCTestSuite {
        return defaultTestSuite
    }

    override func setUp() {
        obj = O.get()
        obj2 = O.get()
        realm = obj.realm
        map = obj[keyPath: V.map]
        otherMap = obj2[keyPath: V.map]
        values = V.values().enumerated().map { (key: "key\($0)", value: $1) }
    }

    override func tearDown() {
        realm?.cancelWrite()
        realm = nil
        map = nil
        otherMap = nil
        obj = nil
        obj2 = nil
    }
}

class PrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> {
    func testInvalidated() {
        XCTAssertFalse(map.isInvalidated)
        if let realm = obj.realm {
            realm.delete(obj)
            XCTAssertTrue(map.isInvalidated)
        }
    }

    func testEnumeration() {
        XCTAssertEqual(0, map.count)
        map.merge(values) { $1 }
        let exp = expectation(description: "did enumerate all keys and values")
        exp.expectedFulfillmentCount = 3
        for element in map {
            if values.filter({ $0.key == element.key }).first!.value == element.value {
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValueForKey() {
        let key = values[0].key
        XCTAssertNil(map.value(forKey: key))
        map.setValue(values[0].value, forKey: key)
        let kvc: AnyObject = map.value(forKey: key)!
        XCTAssertEqual(dynamicBridgeCast(fromObjectiveC: kvc) as V, values[0].value)
    }

    func testInsert() {
        XCTAssertEqual(0, map.count)

        map[values[0].key] = values[0].value
        XCTAssertEqual(1, map.count)
        XCTAssertEqual(1, map.keys.count)
        XCTAssertEqual(1, map.values.count)
        XCTAssertTrue(Set([values[0].key]).isSubset(of: map.keys))
        XCTAssertEqual(map[values[0].key], values[0].value)

        map[values[1].key] = values[1].value
        XCTAssertEqual(2, map.count)
        XCTAssertEqual(2, map.keys.count)
        XCTAssertEqual(2, map.values.count)
        XCTAssertTrue(Set([values[0].key, values[1].key]).isSubset(of: map.keys))
        XCTAssertEqual(map[values[1].key], values[1].value)

        map[values[2].key] = values[2].value
        XCTAssertEqual(3, map.count)
        XCTAssertEqual(3, map.keys.count)
        XCTAssertEqual(3, map.values.count)
        XCTAssertTrue(Set(values.map { $0.key }).isSubset(of: map.keys))
        XCTAssertEqual(map[values[2].key], values[2].value)
    }

    func testUpdate() {
        XCTAssertEqual(0, map.count)

        map[values[0].key] = values[0].value
        XCTAssertEqual(1, map.count)
        XCTAssertEqual(1, map.keys.count)
        XCTAssertEqual(1, map.values.count)
        XCTAssertTrue(Set([values[0].key]).isSubset(of: map.keys))
        XCTAssertEqual(map[values[0].key], values[0].value)

        map.updateValue(values[1].value, forKey: values[0].key)
        XCTAssertEqual(1, map.count)
        XCTAssertEqual(1, map.keys.count)
        XCTAssertEqual(1, map.values.count)
        XCTAssertTrue(Set([values[0].key]).isSubset(of: map.keys))
        XCTAssertEqual(map[values[0].key], values[1].value)
    }

    func testRemove() {
        XCTAssertEqual(0, map.count)
        map.merge(values) { $1 }
        XCTAssertEqual(3, map.count)
        XCTAssertEqual(3, map.keys.count)
        XCTAssertEqual(3, map.values.count)
        XCTAssertTrue(Set(values.map { $0.key }).isSubset(of: map.keys))

        let key = values[0].key
        map.setValue(nil, forKey: key)
        XCTAssertNil(map.value(forKey: key))

        map.removeAll()
        XCTAssertEqual(0, map.count)

        map.merge(values) { $1 }

        map[values[1].key] = nil
        XCTAssertNil(map[values[1].key])
        map.removeObject(for: values[2].key)
        // make sure the key was deleted
        XCTAssertTrue(Set([values[0].key]).isSubset(of: map.keys))
    }

    func testSubscript() {
        // setter
        XCTAssertEqual(0, map.count)
        map[values[0].key] = values[0].value
        map[values[1].key] = values[1].value
        map[values[2].key] = values[2].value
        XCTAssertEqual(3, map.count)
        XCTAssertEqual(3, map.keys.count)
        XCTAssertEqual(3, map.values.count)
        XCTAssertTrue(Set(values.map { $0.key }).isSubset(of: map.keys))
        map[values[0].key] = values[0].value
        map[values[1].key] = nil
        map[values[2].key] = values[2].value
        XCTAssertEqual(2, map.count)
        XCTAssertEqual(2, map.keys.count)
        XCTAssertEqual(2, map.values.count)
        XCTAssertTrue(Set([values[0].key, values[2].key]).isSubset(of: map.keys))
        XCTAssertEqual(2, map.count)
        XCTAssertEqual(2, map.keys.count)
        XCTAssertEqual(2, map.values.count)
        XCTAssertTrue(Set([values[0].key, values[2].key]).isSubset(of: map.keys))
        // getter
        map.removeAll()
        XCTAssertNil(map[values[0].key])
        map[values[0].key] = values[0].value
        XCTAssertEqual(values[0].value, map[values[0].key])
    }

    func testObjectForKey() {
        XCTAssertEqual(0, map.count)
        map[values[0].key] = values[0].value
        XCTAssertEqual(values[0].value, dynamicBridgeCast(fromObjectiveC: map.object(forKey: values[0].key as AnyObject)!) as V)
    }
}

class MinMaxPrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V: MinMaxType {
    func testMin() {
        XCTAssertNil(map.min())
        map.merge(values) { $1 }
        map.merge(values) { $1 }
        XCTAssertEqual(map.min(), values.first?.value)
    }

    func testMax() {
        XCTAssertNil(map.max())
        map.merge(values) { $1 }
        XCTAssertEqual(map.max(), values.last?.value)
    }
}

class OptionalMinMaxPrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.Wrapped: MinMaxType, V.Wrapped: _DefaultConstructible {
    // V and V.Wrapped? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.Wrapped
    var map2: Map<String, V.Wrapped?> {
        return unsafeDowncast(map!, to: Map<String, V.Wrapped?>.self)
    }

    func testMin() {
        XCTAssertNil(map2.min())
        for element in values {
            map2[element.key] = element.value as? V.Wrapped
        }
        let expected = values[1].value as! V.Wrapped
        XCTAssertEqual(map2.min(), expected)
    }

    func testMax() {
        XCTAssertNil(map2.max())
        for element in values {
            map2[element.key] = element.value as? V.Wrapped
        }
        let expected = values[2].value as! V.Wrapped
        XCTAssertEqual(map2.max(), expected)
    }
}

class AddablePrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V: AddableType {
    func testSum() {
        XCTAssertEqual(map.sum(), V())
        map.merge(values) { $1 }

        let expected = ((values.map { $0.value }.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(t: map.sum()), expected, accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(map.average() as V.AverageType?)
        map.merge(values) { $1 }

        let expected = ((values.map { $0.value }.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber)
        XCTAssertEqual(V.doubleValue(map.average()!), expected.doubleValue, accuracy: 0.1)
    }
}

class OptionalAddablePrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.Wrapped: AddableType, V.Wrapped: _DefaultConstructible {
    // V and V.Wrapped? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.Wrapped
    var map2: Map<String, V.Wrapped?> {
        return unsafeDowncast(map!, to: Map<String, V.Wrapped?>.self)
    }

    func testSum() {
        XCTAssertEqual(map2.sum(), V.Wrapped())
        map.merge(values) { $1 }
        var nonNil = values!.map { $0.value }
        nonNil.remove(at: 0)

        // Expressing "can be added and converted to a floating point type" as
        // a protocol requirement is awful, so sidestep it all with obj-c
        let expected = ((nonNil.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(w: map2.sum()), expected, accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(map2.average() as Double?)
        map.merge(values) { $1 }
        var nonNil = values!.map { $0.value }
        nonNil.remove(at: 0)

        let expected = ((nonNil.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(map2.average()!), expected, accuracy: 0.01)
    }
}

class SortablePrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V: Comparable {
    func testSorted() {
        map.merge(values) { $1 }
        XCTAssertEqual(map.count, 3)
        let values2: [V] = values.map { $0.value }

        assertEqual(values2, Array(map.sorted()))
        assertEqual(values2, Array(map.sorted(ascending: true)))
        assertEqual(values2.reversed(), Array(map.sorted(ascending: false)))
    }
}

class OptionalSortablePrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.Wrapped: Comparable, V.Wrapped: _DefaultConstructible {
    func testSorted() {
        map.merge(values) { $1 }
        XCTAssertEqual(map.count, 3)
        var values2: [V.Wrapped?] = []
        values.forEach { values2.append(unsafeBitCast($0.value, to: V.Wrapped?.self)) }
        let mapAscending = unsafeBitCast(map.sorted(), to: Results<V.Wrapped?>.self)

        assertEqual(values2, Array(mapAscending))
        assertEqual(values2, Array(mapAscending.sorted(ascending: true)))
        assertEqual(values2.reversed(), Array(mapAscending.sorted(ascending: false)))
    }
}


func addPrimitiveMapTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    PrimitiveMapTests<OF, Int>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Int8>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Int16>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Int32>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Int64>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Bool>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Float>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Double>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, String>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Data>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Date>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, ObjectId>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Decimal128>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, UUID>._defaultTestSuite().tests.forEach(suite.addTest)

    MinMaxPrimitiveMapTests<OF, Int>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, Int8>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, Int16>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, Int32>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, Int64>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, Float>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, Double>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, Date>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, Decimal128>._defaultTestSuite().tests.forEach(suite.addTest)

    AddablePrimitiveMapTests<OF, Int>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMapTests<OF, Int8>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMapTests<OF, Int16>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMapTests<OF, Int32>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMapTests<OF, Int64>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMapTests<OF, Float>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMapTests<OF, Double>._defaultTestSuite().tests.forEach(suite.addTest)
    AddablePrimitiveMapTests<OF, Decimal128>._defaultTestSuite().tests.forEach(suite.addTest)

    PrimitiveMapTests<OF, Int?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Int8?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Int16?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Int32?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Int64?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Bool?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Float?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Double?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, String?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Data?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Date?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, ObjectId?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, Decimal128?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, UUID?>._defaultTestSuite().tests.forEach(suite.addTest)

    OptionalMinMaxPrimitiveMapTests<OF, Int?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, Int8?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, Int16?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, Int32?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, Int64?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, Float?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, Double?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, Date?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, Decimal128?>._defaultTestSuite().tests.forEach(suite.addTest)

    OptionalAddablePrimitiveMapTests<OF, Int?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMapTests<OF, Int8?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMapTests<OF, Int16?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMapTests<OF, Int32?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMapTests<OF, Int64?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMapTests<OF, Float?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMapTests<OF, Double?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalAddablePrimitiveMapTests<OF, Decimal128?>._defaultTestSuite().tests.forEach(suite.addTest)

    PrimitiveMapTests<OF, EnumInt>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumInt8>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumInt16>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumInt32>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumInt64>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumFloat>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumDouble>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumString>._defaultTestSuite().tests.forEach(suite.addTest)

    MinMaxPrimitiveMapTests<OF, EnumInt>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, EnumInt8>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, EnumInt16>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, EnumInt32>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, EnumInt64>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, EnumFloat>._defaultTestSuite().tests.forEach(suite.addTest)
    MinMaxPrimitiveMapTests<OF, EnumDouble>._defaultTestSuite().tests.forEach(suite.addTest)

    PrimitiveMapTests<OF, EnumInt?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumInt8?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumInt16?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumInt32?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumInt64?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumFloat?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumDouble?>._defaultTestSuite().tests.forEach(suite.addTest)
    PrimitiveMapTests<OF, EnumString?>._defaultTestSuite().tests.forEach(suite.addTest)

    OptionalMinMaxPrimitiveMapTests<OF, EnumInt?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, EnumInt8?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, EnumInt16?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, EnumInt32?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, EnumInt64?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, EnumFloat?>._defaultTestSuite().tests.forEach(suite.addTest)
    OptionalMinMaxPrimitiveMapTests<OF, EnumDouble?>._defaultTestSuite().tests.forEach(suite.addTest)
}

class UnmanagedPrimitiveMapTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged Primitive Maps")
        addPrimitiveMapTests(suite, UnmanagedObjectFactory.self)
        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}

class ManagedPrimitiveMapTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Managed Primitive Maps")
        addPrimitiveMapTests(suite, ManagedObjectFactory.self)

        SortablePrimitiveMapTests<ManagedObjectFactory, Int>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, Int8>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, Int16>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, Int32>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, Int64>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, Float>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, Double>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, String>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, Date>._defaultTestSuite().tests.forEach(suite.addTest)

        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, Int?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, Int8?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, Int16?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, Int32?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, Int64?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, Float?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, Double?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, String?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, Date?>._defaultTestSuite().tests.forEach(suite.addTest)

        SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt8>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt16>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt32>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt64>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, EnumFloat>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, EnumDouble>._defaultTestSuite().tests.forEach(suite.addTest)
        SortablePrimitiveMapTests<ManagedObjectFactory, EnumString>._defaultTestSuite().tests.forEach(suite.addTest)

        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, EnumInt?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, EnumInt8?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, EnumInt16?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, EnumInt32?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, EnumInt64?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, EnumFloat?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, EnumDouble?>._defaultTestSuite().tests.forEach(suite.addTest)
        OptionalSortablePrimitiveMapTests<ManagedObjectFactory, EnumString?>._defaultTestSuite().tests.forEach(suite.addTest)

        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}
