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

// swiftlint:disable type_name identifier_name cyclomatic_complexity

protocol MapValueFactory {
    associatedtype T: RealmCollectionValue
    associatedtype W: RealmCollectionValue = T
    associatedtype Key: _MapKey
    associatedtype AverageType: AddableType = Double
    static func map(_ obj: SwiftMapObject) -> Map<Key, T>
    static func values() -> [(key: Key, value: T)]
    static func doubleValue(_ value: AverageType) -> Double
    static func doubleValue(t value: T) -> Double
    static func doubleValue(w value: W) -> Double
}

extension MapValueFactory {
    static func doubleValue(_ value: Double) -> Double {
        return value
    }
    static func doubleValue(t value: T) -> Double {
        return (value as! NSNumber).doubleValue
    }
    static func doubleValue(w value: W) -> Double {
        return (value as! NSNumber).doubleValue
    }
}

class PrimitiveMapTestsBase<O: ObjectFactory, V: MapValueFactory>: TestCase {
    var realm: Realm?
    var obj: SwiftMapObject!
    var obj2: SwiftMapObject!
    var map: Map<V.Key, V.T>!
    var otherMap: Map<V.Key, V.T>!
    var values: [(key: V.Key, value: V.T)]!

    class func _defaultTestSuite() -> XCTestSuite {
        return defaultTestSuite
    }

    override func setUp() {
        obj = SwiftMapObject()
        obj2 = SwiftMapObject()
        if O.isManaged() {
            let config = Realm.Configuration(inMemoryIdentifier: "test",
                                             objectTypes: [SwiftMapObject.self, SwiftStringObject.self])
            realm = try! Realm(configuration: config)
            realm!.beginWrite()
            realm!.add(obj)
            realm!.add(obj2)
        }
        map = V.map(obj)
        otherMap = V.map(obj2)
        values = V.values()
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

struct MapStringIntFactory: MapValueFactory {
    static func values() -> [(key: String, value: Int)] {
        [("key1", 123), ("key2", 456), ("key3", 789)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Int> {
        return obj.int
    }
}

struct MapStringInt8Factory: MapValueFactory {
    static func values() -> [(key: String, value: Int8)] {
        [("key1", 4), ("key2", 8), ("key3", 16)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Int8> {
        return obj.int8
    }
}

struct MapStringInt16Factory: MapValueFactory {
    static func values() -> [(key: String, value: Int16)] {
        [("key1", 4), ("key2", 8), ("key3", 16)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Int16> {
        return obj.int16
    }
}

struct MapStringInt32Factory: MapValueFactory {
    static func values() -> [(key: String, value: Int32)] {
        [("key1", 4), ("key2", 8), ("key3", 16)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Int32> {
        return obj.int32
    }
}

struct MapStringInt64Factory: MapValueFactory {
    static func values() -> [(key: String, value: Int64)] {
        [("key1", 4), ("key2", 8), ("key3", 16)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Int64> {
        return obj.int64
    }
}

struct MapStringBoolFactory: MapValueFactory {
    static func values() -> [(key: String, value: Bool)] {
        [("key1", false), ("key2", true), ("key3", true)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Bool> {
        return obj.bool
    }
}

struct MapStringFloatFactory: MapValueFactory {
    static func values() -> [(key: String, value: Float)] {
        [("key1", 123.456), ("key2", 456.789), ("key3", 789.123456)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Float> {
        return obj.float
    }
}

struct MapStringDoubleFactory: MapValueFactory {
    static func values() -> [(key: String, value: Double)] {
        [("key1", 123.456), ("key2", 456.789), ("key3", 789.123456)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Double> {
        return obj.double
    }
}

struct MapStringStringFactory: MapValueFactory {
    static func values() -> [(key: String, value: String)] {
        [("key1", "AAA"), ("key2", "BBB"), ("key3", "CCC")]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, String> {
        return obj.string
    }
}

struct MapStringDataFactory: MapValueFactory {
    static func values() -> [(key: String, value: Data)] {
        func data(_ byte: UInt8) -> Data {
            Data.init(repeating: byte, count: 64)
        }
        return [("key1", data(11)), ("key2", data(22)), ("key3", data(33))]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Data> {
        return obj.data
    }
}

struct MapStringDateFactory: MapValueFactory {
    static func values() -> [(key: String, value: Date)] {
        func date(_ timestamp: TimeInterval) -> Date {
            Date(timeIntervalSince1970: timestamp)
        }
        return [("key1", date(1614445927)), ("key2", date(1614555927)), ("key3", date(1614665927))]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Date> {
        return obj.date
    }
}

struct MapStringObjectIdFactory: MapValueFactory {
    static func values() -> [(key: String, value: ObjectId)] {
        [("key1", ObjectId.init("6056670f1a2a5b103c9affda")),
         ("key2", ObjectId.init("6056670f1a2a5b103c9affdd")),
         ("key3", ObjectId.init("605667111a2a5b103c9affe1"))]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, ObjectId> {
        return obj.objectId
    }
}

struct MapStringDecimal128Factory: MapValueFactory {
    static func values() -> [(key: String, value: Decimal128)] {
        func decima128(_ double: Double) -> Decimal128 {
            Decimal128.init(floatLiteral: double)
        }
        return [("key1", decima128(123.456)), ("key2", decima128(993.456789)), ("key3", decima128(9874546.65456489))]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Decimal128> {
        return obj.decimal
    }

    static func doubleValue(_ value: Decimal128) -> Double {
        return value.doubleValue
    }
    static func doubleValue(t value: Decimal128) -> Double {
        return value.doubleValue
    }
    static func doubleValue(w value: Decimal128) -> Double {
        return value.doubleValue
    }
}

struct MapStringUUIDFactory: MapValueFactory {
    static func values() -> [(key: String, value: UUID)] {
        [("key1", UUID(uuidString: "7729028A-FB89-4555-81C3-C55F7DDBA5CF")!),
         ("key2", UUID(uuidString: "0F0359D8-8D74-409D-8561-C8EBE3753635")!),
         ("key3", UUID(uuidString: "0F0359D8-8D74-409D-8561-C8EBE3753636")!)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, UUID> {
        return obj.uuid
    }
}

struct OptionalMapStringIntFactory: MapValueFactory {
    typealias W = Int

    static func values() -> [(key: String, value: Int?)] {
        [("key1", nil), ("key2", 123), ("key3", 456)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Int?> {
        return obj.intOpt
    }
}

struct OptionalMapStringInt8Factory: MapValueFactory {
    typealias W = Int8

    static func values() -> [(key: String, value: Int8?)] {
        [("key1", nil), ("key2", 4), ("key3", 8)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Int8?> {
        return obj.int8Opt
    }
}

struct OptionalMapStringInt16Factory: MapValueFactory {
    typealias W = Int16

    static func values() -> [(key: String, value: Int16?)] {
        [("key1", nil), ("key2", 4), ("key3", 8)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Int16?> {
        return obj.int16Opt
    }
}

struct OptionalMapStringInt32Factory: MapValueFactory {
    typealias W = Int32

    static func values() -> [(key: String, value: Int32?)] {
        [("key1", nil), ("key2", 4), ("key3", 8)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Int32?> {
        return obj.int32Opt
    }
}

struct OptionalMapStringInt64Factory: MapValueFactory {
    typealias W = Int64

    static func values() -> [(key: String, value: Int64?)] {
        [("key1", nil), ("key2", 4), ("key3", 8)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Int64?> {
        return obj.int64Opt
    }
}

struct OptionalMapStringBoolFactory: MapValueFactory {
    typealias W = Bool

    static func values() -> [(key: String, value: Bool?)] {
        [("key1", nil), ("key2", false), ("key3", true)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Bool?> {
        return obj.boolOpt
    }
}

struct OptionalMapStringFloatFactory: MapValueFactory {
    typealias W = Float

    static func values() -> [(key: String, value: Float?)] {
        [("key1", nil), ("key2", 123.456), ("key3", 456.789)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Float?> {
        return obj.floatOpt
    }
}

struct OptionalMapStringDoubleFactory: MapValueFactory {
    typealias W = Double

    static func values() -> [(key: String, value: Double?)] {
        [("key1", nil), ("key2", 123.456), ("key3", 456.567)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Double?> {
        return obj.doubleOpt
    }
}

struct OptionalMapStringStringFactory: MapValueFactory {
    typealias W = String

    static func values() -> [(key: String, value: String?)] {
        [("key1", nil), ("key2", "AAA"), ("key3", "BBB")]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, String?> {
        return obj.stringOpt
    }
}

struct OptionalMapStringDataFactory: MapValueFactory {
    typealias W = Data

    static func values() -> [(key: String, value: Data?)] {
        func data(_ byte: UInt8) -> Data {
            Data.init(repeating: byte, count: 64)
        }
        return [("key1", nil), ("key2", data(11)), ("key3", data(22))]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Data?> {
        return obj.dataOpt
    }
}

struct OptionalMapStringDateFactory: MapValueFactory {
    typealias W = Date

    static func values() -> [(key: String, value: Date?)] {
        func date(_ timestamp: TimeInterval) -> Date {
            Date(timeIntervalSince1970: timestamp)
        }
        return [("key1", nil), ("key2", date(1614445927)), ("key3", date(1614555927))]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Date?> {
        return obj.dateOpt
    }
}

struct OptionalMapStringObjectIdFactory: MapValueFactory {
    typealias W = ObjectId

    static func values() -> [(key: String, value: ObjectId?)] {
        [("key1", nil),
         ("key2", ObjectId.init("6056670f1a2a5b103c9affda")),
         ("key3", ObjectId.init("6056670f1a2a5b103c9affdd"))]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, ObjectId?> {
        return obj.objectIdOpt
    }
}

struct OptionalMapStringDecimal128Factory: MapValueFactory {
    typealias W = Decimal128
    typealias AverageType = Decimal128

    static func values() -> [(key: String, value: Decimal128?)] {
        func decima128(_ double: Double) -> Decimal128 {
            Decimal128.init(floatLiteral: double)
        }
        return [("key1", nil), ("key2", decima128(123.456)), ("key3", decima128(993.456789))]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, Decimal128?> {
        return obj.decimalOpt
    }

    static func doubleValue(_ value: Decimal128) -> Double {
        return value.doubleValue
    }
    static func doubleValue(t value: T) -> Double {
        return value!.doubleValue
    }
    static func doubleValue(w value: W) -> Double {
        return value.doubleValue
    }
}

struct OptionalMapStringUUIDFactory: MapValueFactory {
    typealias W = UUID

    static func values() -> [(key: String, value: UUID?)] {
        [("key1", nil),
         ("key2", UUID(uuidString: "7729028A-FB89-4555-81C3-C55F7DDBA5CF")!),
         ("key3", UUID(uuidString: "0F0359D8-8D74-409D-8561-C8EBE3753635")!)]
    }

    static func map(_ obj: SwiftMapObject) -> Map<String, UUID?> {
        return obj.uuidOpt
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
        for element in values {
            map[element.key] = element.value
        }
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
        if let key = values[0].key as? String {
            XCTAssertNil(map.value(forKey: key))
            map.setValue(values[0].value, forKey: key)
            let kvc: AnyObject? = map.value(forKey: key)
            XCTAssertEqual(kvc as! V.T, values[0].value)
        }
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
        for element in values {
            map[element.key] = element.value
        }
        XCTAssertEqual(3, map.count)
        XCTAssertEqual(3, map.keys.count)
        XCTAssertEqual(3, map.values.count)
        XCTAssertTrue(Set(values.map { $0.key }).isSubset(of: map.keys))

        // KVC requires a string for the key
        if V.Key.self is String.Type {
            if let key = values[0].key as? String {
                map.setValue(nil, forKey: key)
                XCTAssertNil(map.value(forKey: key))
            }
        }
        map.removeAll()
        XCTAssertEqual(0, map.count)

        for element in values {
            map[element.key] = element.value
        }

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
        XCTAssertEqual(values[0].value, map.object(forKey: values[0].key as AnyObject) as! V.T)
    }
}

class MinMaxPrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.T: MinMaxType {
    func testMin() {
        XCTAssertNil(map.min())
        for element in values {
            map[element.key] = element.value
        }
        XCTAssertEqual(map.min(), values.first?.value)
    }

    func testMax() {
        XCTAssertNil(map.max())
        for element in values {
            map[element.key] = element.value
        }
        XCTAssertEqual(map.max(), values.last?.value)
    }
}

class OptionalMinMaxPrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.W: MinMaxType, V.W: _DefaultConstructible {
    // V.T and V.W? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.W
    var map2: Map<V.Key, V.W?> {
        return unsafeDowncast(map!, to: Map<V.Key, V.W?>.self)
    }

    func testMin() {
        XCTAssertNil(map2.min())
        for element in values {
            map2[element.key] = element.value as? V.W
        }
        let expected = values[1].value as! V.W
        XCTAssertEqual(map2.min(), expected)
    }

    func testMax() {
        XCTAssertNil(map2.max())
        for element in values {
            map2[element.key] = element.value as? V.W
        }
        let expected = values[2].value as! V.W
        XCTAssertEqual(map2.max(), expected)
    }
}

class AddablePrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.T: AddableType {
    func testSum() {
        XCTAssertEqual(map.sum(), V.T())
        for element in values {
            map[element.key] = element.value
        }

        let expected = ((values.map { $0.value }.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(t: map.sum()), expected, accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(map.average() as V.AverageType?)
        for element in values {
            map[element.key] = element.value
        }

        let expected = ((values.map { $0.value }.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber)
        XCTAssertEqual(V.doubleValue(map.average()!), expected.doubleValue, accuracy: 0.1)
    }
}

class OptionalAddablePrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.W: AddableType, V.W: _DefaultConstructible {
    // V.T and V.W? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.W
    var map2: Map<V.Key, V.W?> {
        return unsafeDowncast(map!, to: Map<V.Key, V.W?>.self)
    }

    func testSum() {
        XCTAssertEqual(map2.sum(), V.W())
        for element in values {
            map[element.key] = element.value
        }
        var nonNil = values!.map { $0.value }
        nonNil.remove(at: 0)

        // Expressing "can be added and converted to a floating point type" as
        // a protocol requirement is awful, so sidestep it all with obj-c
        let expected = ((nonNil.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(w: map2.sum()), expected, accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(map2.average() as Double?)
        for element in values {
            map[element.key] = element.value
        }
        var nonNil = values!.map { $0.value }
        nonNil.remove(at: 0)

        let expected = ((nonNil.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber).doubleValue
        XCTAssertEqual(V.doubleValue(map2.average()!), expected, accuracy: 0.01)
    }
}

class SortablePrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.T: Comparable {
    func testSorted() {
        for element in values {
            map[element.key] = element.value
        }
        XCTAssertEqual(map.count, 3)
        let values2: [V.T] = values.map { $0.value }

        assertEqual(values2, Array(map.sorted()))
        assertEqual(values2, Array(map.sorted(ascending: true)))
        assertEqual(values2.reversed(), Array(map.sorted(ascending: false)))
    }
}

class OptionalSortablePrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.W: Comparable, V.W: _DefaultConstructible {
    func testSorted() {
        for element in values {
            map[element.key] = element.value
        }
        XCTAssertEqual(map.count, 3)
        var values2: [V.W?] = []
        values.forEach { values2.append(unsafeBitCast($0.value, to: V.W?.self)) }
        let mapAscending = unsafeBitCast(map.sorted(), to: Results<V.W?>.self)

        assertEqual(values2, Array(mapAscending))
        assertEqual(values2, Array(mapAscending.sorted(ascending: true)))
        assertEqual(values2.reversed(), Array(mapAscending.sorted(ascending: false)))
    }
}


func addPrimitiveMapTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    _ = PrimitiveMapTests<OF, MapStringIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringBoolFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringStringFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringDataFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringDateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringObjectIdFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, MapStringUUIDFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = MinMaxPrimitiveMapTests<OF, MapStringIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMapTests<OF, MapStringInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMapTests<OF, MapStringInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMapTests<OF, MapStringInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMapTests<OF, MapStringInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMapTests<OF, MapStringFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMapTests<OF, MapStringDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMapTests<OF, MapStringDateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveMapTests<OF, MapStringDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)

    _ = AddablePrimitiveMapTests<OF, MapStringIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMapTests<OF, MapStringInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMapTests<OF, MapStringInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMapTests<OF, MapStringInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMapTests<OF, MapStringInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMapTests<OF, MapStringFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMapTests<OF, MapStringDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveMapTests<OF, MapStringDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)

    _ = PrimitiveMapTests<OF, OptionalMapStringIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringBoolFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringStringFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringDataFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringDateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringObjectIdFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveMapTests<OF, OptionalMapStringUUIDFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = OptionalMinMaxPrimitiveMapTests<OF, OptionalMapStringIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMapTests<OF, OptionalMapStringInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMapTests<OF, OptionalMapStringInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMapTests<OF, OptionalMapStringInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMapTests<OF, OptionalMapStringInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMapTests<OF, OptionalMapStringFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMapTests<OF, OptionalMapStringDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMapTests<OF, OptionalMapStringDateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveMapTests<OF, OptionalMapStringDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)

    _ = OptionalAddablePrimitiveMapTests<OF, OptionalMapStringIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMapTests<OF, OptionalMapStringInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMapTests<OF, OptionalMapStringInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMapTests<OF, OptionalMapStringInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMapTests<OF, OptionalMapStringInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMapTests<OF, OptionalMapStringFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMapTests<OF, OptionalMapStringDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveMapTests<OF, OptionalMapStringDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)
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

        _ = SortablePrimitiveMapTests<ManagedObjectFactory, MapStringIntFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMapTests<ManagedObjectFactory, MapStringInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMapTests<ManagedObjectFactory, MapStringInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMapTests<ManagedObjectFactory, MapStringInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMapTests<ManagedObjectFactory, MapStringInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMapTests<ManagedObjectFactory, MapStringFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMapTests<ManagedObjectFactory, MapStringDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMapTests<ManagedObjectFactory, MapStringStringFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveMapTests<ManagedObjectFactory, MapStringDateFactory>._defaultTestSuite().tests.map(suite.addTest)

        _ = OptionalSortablePrimitiveMapTests<ManagedObjectFactory, OptionalMapStringIntFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMapTests<ManagedObjectFactory, OptionalMapStringInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMapTests<ManagedObjectFactory, OptionalMapStringInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMapTests<ManagedObjectFactory, OptionalMapStringInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMapTests<ManagedObjectFactory, OptionalMapStringInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMapTests<ManagedObjectFactory, OptionalMapStringFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMapTests<ManagedObjectFactory, OptionalMapStringDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMapTests<ManagedObjectFactory, OptionalMapStringStringFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveMapTests<ManagedObjectFactory, OptionalMapStringDateFactory>._defaultTestSuite().tests.map(suite.addTest)

        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}
