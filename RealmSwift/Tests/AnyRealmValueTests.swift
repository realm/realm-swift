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

class AnyRealmTypeObject: Object {
    var anyValue = AnyRealmValue()
    @objc dynamic var stringObj: SwiftStringObject?
    let anyList = List<AnyRealmValue>()
}

class AnyRealmValueTests: TestCase {

    func testInt() {
        let o = AnyRealmTypeObject()
        o.anyValue.value = .int(123)
        XCTAssertEqual(o.anyValue.value.intValue, 123)
        o.anyValue.value = .int(456)
        XCTAssertEqual(o.anyValue.value.intValue, 456)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.intValue, 456)
        try! realm.write {
            o.anyValue.value = .int(987)
        }
        XCTAssertEqual(o.anyValue.value.intValue, 987)
    }

    func testBool() {
        let o = AnyRealmTypeObject()
        o.anyValue.value = .bool(true)
        XCTAssertEqual(o.anyValue.value.boolValue, true)
        o.anyValue.value = .bool(false)
        XCTAssertEqual(o.anyValue.value.boolValue, false)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.boolValue, false)
        try! realm.write {
            o.anyValue.value = .bool(true)
        }
        XCTAssertEqual(o.anyValue.value.boolValue, true)
    }

    func testFloat() {
        let o = AnyRealmTypeObject()
        o.anyValue.value = .float(123.456)
        XCTAssertEqual(o.anyValue.value.floatValue, 123.456)
        o.anyValue.value = .float(456.678)
        XCTAssertEqual(o.anyValue.value.floatValue, 456.678)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.floatValue, 456.678)
        try! realm.write {
            o.anyValue.value = .float(987.123)
        }
        XCTAssertEqual(o.anyValue.value.floatValue, 987.123)
    }

    func testDouble() {
        let o = AnyRealmTypeObject()
        o.anyValue.value = .double(123.456)
        XCTAssertEqual(o.anyValue.value.doubleValue, 123.456)
        o.anyValue.value = .double(456.678)
        XCTAssertEqual(o.anyValue.value.doubleValue, 456.678)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.doubleValue, 456.678)
        try! realm.write {
            o.anyValue.value = .double(987.123)
        }
        XCTAssertEqual(o.anyValue.value.doubleValue, 987.123)
    }

    func testString() {
        let o = AnyRealmTypeObject()
        o.anyValue.value = .string("good news everyone")
        XCTAssertEqual(o.anyValue.value.stringValue, "good news everyone")
        o.anyValue.value = .string("professor farnsworth")
        XCTAssertEqual(o.anyValue.value.stringValue, "professor farnsworth")
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.stringValue, "professor farnsworth")
        try! realm.write {
            o.anyValue.value = .string("Dr. zoidberg")
        }
        XCTAssertEqual(o.anyValue.value.stringValue, "Dr. zoidberg")
    }

    func testData() {
        let d1 = Data(repeating: 1, count: 64)
        let d2 = Data(repeating: 2, count: 64)
        let d3 = Data(repeating: 3, count: 64)
        let o = AnyRealmTypeObject()
        o.anyValue.value = .data(d1)
        XCTAssertEqual(o.anyValue.value.dataValue, d1)
        o.anyValue.value = .data(d2)
        XCTAssertEqual(o.anyValue.value.dataValue, d2)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.dataValue, d2)
        try! realm.write {
            o.anyValue.value = .data(d3)
        }
        XCTAssertEqual(o.anyValue.value.dataValue, d3)
    }

    func testDate() {
        let d1 = Date(timeIntervalSinceNow: 10000)
        let d2 = Date(timeIntervalSinceNow: 20000)
        let d3 = Date(timeIntervalSinceNow: 30000)
        let o = AnyRealmTypeObject()
        o.anyValue.value = .date(d1)
        XCTAssertEqual(o.anyValue.value.dateValue, d1)
        o.anyValue.value = .date(d2)
        XCTAssertEqual(o.anyValue.value.dateValue, d2)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.dateValue!.timeIntervalSince1970,
                       d2.timeIntervalSince1970, accuracy: 1)
        try! realm.write {
            o.anyValue.value = .date(d3)
        }
        XCTAssertEqual(o.anyValue.value.dateValue!.timeIntervalSince1970,
                       d3.timeIntervalSince1970, accuracy: 1)
    }

    func testObjectId() {
        let o1 = ObjectId.generate()
        let o2 = ObjectId.generate()
        let o3 = ObjectId.generate()
        let o = AnyRealmTypeObject()
        o.anyValue.value = .objectId(o1)
        XCTAssertEqual(o.anyValue.value.objectIdValue, o1)
        o.anyValue.value = .objectId(o2)
        XCTAssertEqual(o.anyValue.value.objectIdValue, o2)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.objectIdValue, o2)
        try! realm.write {
            o.anyValue.value = .objectId(o3)
        }
        XCTAssertEqual(o.anyValue.value.objectIdValue, o3)
    }

    func testDecimal128() {
        let d1 = Decimal128(floatLiteral: 1234.5678)
        let d2 = Decimal128(floatLiteral: 6789.1234)
        let d3 = Decimal128(floatLiteral: 1.0)
        let o = AnyRealmTypeObject()
        o.anyValue.value = .decimal128(d1)
        XCTAssertEqual(o.anyValue.value.decimal128Value, d1)
        o.anyValue.value = .decimal128(d2)
        XCTAssertEqual(o.anyValue.value.decimal128Value, d2)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.decimal128Value, d2)
        try! realm.write {
            o.anyValue.value = .decimal128(d3)
        }
        XCTAssertEqual(o.anyValue.value.decimal128Value, d3)
    }

    func testUuid() {
        let o = AnyRealmTypeObject()
        let u1 = UUID()
        let u2 = UUID()
        let u3 = UUID()

        o.anyValue.value = .uuid(u1)
        XCTAssertEqual(o.anyValue.value.uuidValue, u1)

        o.anyValue.value = .uuid(u2)
        XCTAssertEqual(o.anyValue.value.uuidValue, u2)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.uuidValue, u2)
        try! realm.write {
            o.anyValue.value = .uuid(u3)
        }
        XCTAssertEqual(o.anyValue.value.uuidValue, u3)
    }

    func testObject() {
        let o = AnyRealmTypeObject()
        let so = SwiftStringObject()
        so.stringCol = "hello"
        o.anyValue.value = .object(so)
        XCTAssertEqual(o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol, "hello")
        o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol = "there"
        XCTAssertEqual(o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol, "there")
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol, "there")
        try! realm.write {
            o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol = "bye!"
        }
        XCTAssertEqual(o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol, "bye!")
    }

    func testAssortment() {
        // The purpose of this test is to reuse a mixed container
        // and ensure no issues exist in doing that.
        let o = AnyRealmTypeObject()
        let so = SwiftStringObject()
        so.stringCol = "hello"
        let data = Data(repeating: 1, count: 64)
        let date = Date()
        let objectId = ObjectId.generate()
        let decimal = Decimal128(floatLiteral: 12345.6789)

        let tests: ((Realm?) -> Void) = { (realm: Realm?) in
            self.testVariation(object: o, value: .int(123), keyPath: \.intValue, expected: 123, realm: realm)
            self.testVariation(object: o, value: .float(123.456), keyPath: \.floatValue, expected: 123.456, realm: realm)
            self.testVariation(object: o, value: .string("hello there"), keyPath: \.stringValue, expected: "hello there", realm: realm)
            self.testVariation(object: o, value: .data(data), keyPath: \.dataValue, expected: data, realm: realm)
            self.testVariation(object: o, value: .date(date), keyPath: \.dateValue, expected: date, realm: realm)
            self.testVariation(object: o, value: .objectId(objectId), keyPath: \.objectIdValue, expected: objectId, realm: realm)
            self.testVariation(object: o, value: .decimal128(decimal), keyPath: \.decimal128Value, expected: decimal, realm: realm)
        }

        // unmanaged
        tests(nil)
        o.anyValue.value = .none
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        // managed
        tests(realm)

        try! realm.write {
            o.anyValue.value = .object(so)
        }
        XCTAssertEqual(o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol, "hello")
    }

    private func testVariation<T: Equatable>(object: AnyRealmTypeObject,
                                             value: AnyRealmValue.Value,
                                             keyPath: KeyPath<AnyRealmValue.Value, T?>,
                                             expected: T,
                                             realm: Realm?) {
        if let realm = realm {
            try! realm.write {
                object.anyValue.value = value
            }
        } else {
            object.anyValue.value = value
        }
        XCTAssertEqual(object.anyValue.value[keyPath: keyPath], expected)
    }
}

class BaseAnyRealmValueFactory {
    static func array(_ obj: SwiftListObject) -> List<AnyRealmValue> {
        return obj.any
    }

    static func mutableSet(_ obj: SwiftMutableSetObject) -> MutableSet<AnyRealmValue> {
        return obj.any
    }

    static func value(_ value: AnyRealmValue.Value) -> AnyRealmValue {
        let v = AnyRealmValue()
        v.value = value
        return v
    }
}

class AnyRealmValueIntFactory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        [value(.int(123)), value(.int(456)), value(.int(789))]
    }
}

class AnyRealmValueBoolFactory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        [value(.bool(true)), value(.bool(false)), value(.none)]
    }
}

class AnyRealmValueFloatFactory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        [value(.float(123.456)), value(.float(456.789)), value(.float(789.123456))]
    }
}

class AnyRealmValueDoubleFactory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        [value(.double(123.456)), value(.double(456.789)), value(.double(789.123456))]
    }
}

class AnyRealmValueStringFactory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        [value(.string("Hello There")), value(.string("This is")), value(.string("A test..."))]
    }
}

class AnyRealmValueDataFactory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        func data(_ byte: UInt8) -> AnyRealmValue {
            let v = AnyRealmValue()
            v.value = .data(Data.init(repeating: byte, count: 64))
            return v
        }
        return [data(11), data(22), data(33)]
    }
}

class AnyRealmValueDateFactory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        func date(_ timestamp: TimeInterval) -> AnyRealmValue {
            let v = AnyRealmValue()
            v.value = .date(Date(timeIntervalSince1970: timestamp))
            return v
        }
        return [date(1614445927), date(1614555927), date(1614665927)]
    }
}

class AnyRealmValueObjectFactory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        func object(_ string: String) -> AnyRealmValue {
            let v = AnyRealmValue()
            let o = SwiftStringObject()
            o.stringCol = string
            v.value = .object(o)
            return v
        }
        return [object("Hello"), object("I am"), object("an object")]
    }
}

class AnyRealmValueObjectIdFactory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        func objectId() -> AnyRealmValue {
            let v = AnyRealmValue()
            v.value = .objectId(.generate())
            return v
        }
        return [objectId(), objectId(), objectId()]
    }
}

class AnyRealmValueDecimal128Factory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        func decima128(_ double: Double) -> AnyRealmValue {
            let v = AnyRealmValue()
            v.value = .decimal128(.init(floatLiteral: double))
            return v
        }
        return [decima128(123.456), decima128(993.456789), decima128(9874546.65456489)]
    }
}

class AnyRealmValueUUIDFactory: BaseAnyRealmValueFactory, ValueFactory {
    static func values() -> [AnyRealmValue] {
        func uuid() -> AnyRealmValue {
            let v = AnyRealmValue()
            v.value = .uuid(.init())
            return v
        }
        return [uuid(), uuid(), uuid()]
    }
}

class AnyRealmValueListTests<O: ObjectFactory, V: ValueFactory>: PrimitiveListTestsBase<O, V> where V.T: AnyRealmValue {

    private func assertEqual(_ obj: AnyRealmValue.Value, _ anotherObj: AnyRealmValue.Value) {
        if case let .object(a) = obj,
           case let .object(b) = anotherObj {
            XCTAssertEqual((a as! SwiftStringObject).stringCol, (b as! SwiftStringObject).stringCol)
        } else {
            XCTAssertEqual(obj, anotherObj)
        }
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
            assertEqual(array[i].value, values[i].value)
        }
        assertThrows(array[values.count], reason: "Index 3 is out of bounds")
        assertThrows(array[-1], reason: "negative value")
    }

    func testFirst() {
        array.append(objectsIn: values)
        assertEqual(array.first!.value, values.first!.value)
        array.removeAll()
        XCTAssertNil(array.first)
    }

    func testLast() {
        array.append(objectsIn: values)
        assertEqual(array.last!.value, values.last!.value)
        array.removeAll()
        XCTAssertNil(array.last)

    }

    func testValueForKey() {
        XCTAssertEqual(array.value(forKey: "self").count, 0)
        array.append(objectsIn: values)

        for (expected, actual) in zip(values!, array.value(forKey: "self").map { dynamicBridgeCast(fromObjectiveC: $0) as V.T }) {
            assertEqual(expected.value, actual.value)
        }

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
        assertEqual(values[0].value, array[0].value)

        array.insert(values[1], at: 0)
        XCTAssertEqual(Int(2), array.count)
        assertEqual(values[1].value, array[0].value)
        assertEqual(values[0].value, array[1].value)

        array.insert(values[2], at: 2)
        XCTAssertEqual(Int(3), array.count)
        assertEqual(values[1].value, array[0].value)
        assertEqual(values[0].value, array[1].value)
        assertEqual(values[2].value, array[2].value)

        assertThrows(array.insert(values[0], at: 4))
        assertThrows(array.insert(values[0], at: -1))
    }

    func testRemove() {
        assertThrows(array.remove(at: 0))
        assertThrows(array.remove(at: -1))

        array.append(objectsIn: values)

        assertThrows(array.remove(at: -1))
        assertEqual(values[0].value, array[0].value)
        assertEqual(values[1].value, array[1].value)
        assertEqual(values[2].value, array[2].value)
        assertThrows(array[3])

        array.remove(at: 0)
        assertEqual(values[1].value, array[0].value)
        assertEqual(values[2].value, array[1].value)
        assertThrows(array[2])
        assertThrows(array.remove(at: 2))

        array.remove(at: 1)
        assertEqual(values[1].value, array[0].value)
        assertThrows(array[1])
    }

    func testRemoveLast() {
        assertThrows(array.removeLast())

        array.append(objectsIn: values)
        array.removeLast()

        XCTAssertEqual(array.count, 2)
        assertEqual(values[0].value, array[0].value)
        assertEqual(values[1].value, array[1].value)

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
        assertEqual(array[0].value, values[0].value)
        assertEqual(array[1].value, values[0].value)
        assertEqual(array[2].value, values[2].value)

        assertThrows(array.replace(index: 3, object: values[0]),
                     reason: "Index 3 is out of bounds")
        assertThrows(array.replace(index: -1, object: values[0]),
                     reason: "Cannot pass a negative value")
    }

    func testReplaceRange() {
        assertSucceeds { array.replaceSubrange(0..<0, with: []) }

        array.replaceSubrange(0..<0, with: [values[0]])
        XCTAssertEqual(array.count, 1)
        assertEqual(array[0].value, values[0].value)

        array.replaceSubrange(0..<1, with: values)
        XCTAssertEqual(array.count, 3)

        array.replaceSubrange(1..<2, with: [])
        XCTAssertEqual(array.count, 2)
        assertEqual(array[0].value, values[0].value)
        assertEqual(array[1].value, values[2].value)
    }

    func testMove() {
        assertThrows(array.move(from: 1, to: 0), reason: "out of bounds")

        array.append(objectsIn: values)
        array.move(from: 2, to: 0)
        assertEqual(array[0].value, values[2].value)
        assertEqual(array[1].value, values[0].value)
        assertEqual(array[2].value, values[1].value)

        assertThrows(array.move(from: 3, to: 0), reason: "Index 3 is out of bounds")
        assertThrows(array.move(from: 0, to: 3), reason: "Index 3 is out of bounds")
        assertThrows(array.move(from: -1, to: 0), reason: "negative value")
        assertThrows(array.move(from: 0, to: -1), reason: "negative value")
    }

    func testSwap() {
        assertThrows(array.swapAt(0, 1), reason: "out of bounds")

        array.append(objectsIn: values)
        array.swapAt(0, 2)
        assertEqual(array[0].value, values[2].value)
        assertEqual(array[1].value, values[1].value)
        assertEqual(array[2].value, values[0].value)

        assertThrows(array.swapAt(3, 0), reason: "Index 3 is out of bounds")
        assertThrows(array.swapAt(0, 3), reason: "Index 3 is out of bounds")
        assertThrows(array.swapAt(-1, 0), reason: "negative value")
        assertThrows(array.swapAt(0, -1), reason: "negative value")
    }
}

class MinMaxAnyRealmValueListTests<O: ObjectFactory, V: ValueFactory>: PrimitiveListTestsBase<O, V> where V.T: AnyRealmValue {
    func testMin() {
        XCTAssertNil(array.min()?.value)
        array.append(objectsIn: values.reversed())
        XCTAssertEqual(array.min()?.value, values.first?.value)
    }

    func testMax() {
        XCTAssertNil(array.max()?.value)
        array.append(objectsIn: values.reversed())
        XCTAssertEqual(array.max()?.value, values.last?.value)
    }
}

class AddableAnyRealmValueListTests<O: ObjectFactory, V: ValueFactory>: PrimitiveListTestsBase<O, V> where V.T: AnyRealmValue {
    func testSum() {
        XCTAssertEqual(array.sum().value.intValue, nil)
        array.append(objectsIn: values)

        let expected = ((values.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber)

        // An unmanaged collection will return a double
        if case let .double(d) = array.sum().value {
            XCTAssertEqual(d, expected.doubleValue)
        } else if case let .decimal128(d) = array.sum().value {
            // A managed collection of AnyRealmValue will return a Decimal128 for `sum()`
            XCTAssertEqual(d.doubleValue, expected.doubleValue, accuracy: 0.1)
        }
    }

    func testAverage() {
        XCTAssertNil(array.average() as V.AverageType?)
        array.append(objectsIn: values)

        let expected = ((values.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber)

        let v: AnyRealmValue? = array.average()
        // An unmanaged collection will return a double
        if case let .double(d) = v?.value {
            XCTAssertEqual(d, expected.doubleValue)
        } else if case let .decimal128(d) = v?.value {
            // A managed collection of AnyRealmValue will return a Decimal128 for `avg()`
            XCTAssertEqual(d.doubleValue, expected.doubleValue, accuracy: 0.1)
        }
    }
}

func addAnyRealmValueTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    _ = AnyRealmValueListTests<OF, AnyRealmValueIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueListTests<OF, AnyRealmValueBoolFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueListTests<OF, AnyRealmValueFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueListTests<OF, AnyRealmValueDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueListTests<OF, AnyRealmValueStringFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueListTests<OF, AnyRealmValueDataFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueListTests<OF, AnyRealmValueDateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueListTests<OF, AnyRealmValueObjectFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueListTests<OF, AnyRealmValueObjectIdFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueListTests<OF, AnyRealmValueDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueListTests<OF, AnyRealmValueUUIDFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = MinMaxAnyRealmValueListTests<OF, AnyRealmValueIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxAnyRealmValueListTests<OF, AnyRealmValueFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxAnyRealmValueListTests<OF, AnyRealmValueDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxAnyRealmValueListTests<OF, AnyRealmValueDateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxAnyRealmValueListTests<OF, AnyRealmValueDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)

    _ = AddableAnyRealmValueListTests<OF, AnyRealmValueIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddableAnyRealmValueListTests<OF, AnyRealmValueFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddableAnyRealmValueListTests<OF, AnyRealmValueDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddableAnyRealmValueListTests<OF, AnyRealmValueDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)
}

class UnmanagedAnyRealmValueListTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged AnyRealmValue Lists")
        addAnyRealmValueTests(suite, UnmanagedObjectFactory.self)
        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}

class ManagedAnyRealmValueListTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Managed AnyRealmValue Lists")
        addAnyRealmValueTests(suite, ManagedObjectFactory.self)
        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}

class AnyRealmValueMutableSetTests<O: ObjectFactory, V: ValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.T: AnyRealmValue {

    private func assertEqual(_ obj: AnyRealmValue.Value, _ anotherObj: AnyRealmValue.Value) {
        if case let .object(a) = obj,
           case let .object(b) = anotherObj {
            XCTAssertEqual((a as! SwiftStringObject).stringCol, (b as! SwiftStringObject).stringCol)
        } else {
            XCTAssertEqual(obj, anotherObj)
        }
    }

    func testInvalidated() {
        XCTAssertFalse(mutableSet.isInvalidated)
        if let realm = obj.realm {
            realm.delete(obj)
            XCTAssertTrue(mutableSet.isInvalidated)
        }
    }

    func testValueForKey() {
        XCTAssertEqual(mutableSet.value(forKey: "self").count, 0)
        mutableSet.insert(values[0])
        let kvo = (mutableSet.value(forKey: "self") as [AnyObject]).first!
        if let obj = kvo as? SwiftStringObject, case let .object(o) = values[0].value {
            XCTAssertEqual(obj.stringCol, (o as! SwiftStringObject).stringCol)
        } else {
            let v = AnyRealmValue()
            v.rlmValue = kvo as? RLMValue
            XCTAssertEqual(v.value, values[0].value)
        }
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
        assertEqual(mutableSet[0].value, values[0].value)
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
        if values[0].value.objectValue(SwiftStringObject.self) != nil {
            XCTAssertTrue(values.map {
                $0.value.objectValue(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[0].value.objectValue(SwiftStringObject.self)?.stringCol))
            XCTAssertTrue(values.map {
                $0.value.objectValue(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[1].value.objectValue(SwiftStringObject.self)?.stringCol))
            XCTAssertTrue(values.map {
                $0.value.objectValue(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[2].value.objectValue(SwiftStringObject.self)?.stringCol))
        } else {
            XCTAssertTrue(values.map { $0.value }.contains(mutableSet[0].value))
            XCTAssertTrue(values.map { $0.value }.contains(mutableSet[1].value))
            XCTAssertTrue(values.map { $0.value }.contains(mutableSet[2].value))
        }
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
        if values[0].value.objectValue(SwiftStringObject.self) != nil {
            XCTAssertTrue(values.map {
                $0.value.objectValue(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[0].value.objectValue(SwiftStringObject.self)?.stringCol))
            XCTAssertTrue(values.map {
                $0.value.objectValue(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[1].value.objectValue(SwiftStringObject.self)?.stringCol))
            XCTAssertTrue(values.map {
                $0.value.objectValue(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[2].value.objectValue(SwiftStringObject.self)?.stringCol))
        } else {
            XCTAssertTrue(values.map { $0.value }.contains(mutableSet[0].value))
            XCTAssertTrue(values.map { $0.value }.contains(mutableSet[1].value))
            XCTAssertTrue(values.map { $0.value }.contains(mutableSet[2].value))
        }
    }
}

class MinMaxAnyRealmValueMutableSetTests<O: ObjectFactory, V: ValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.T: AnyRealmValue {
    func testMin() {
        XCTAssertNil(mutableSet.min())
        mutableSet.insert(objectsIn: values)
        XCTAssertEqual(mutableSet.min()?.value, values.first?.value)
    }

    func testMax() {
        XCTAssertNil(mutableSet.max())
        mutableSet.insert(objectsIn: values)
        XCTAssertEqual(mutableSet.max()?.value, values.last?.value)
    }
}

class AddableAnyRealmValueMutableSetTests<O: ObjectFactory, V: ValueFactory>: PrimitiveMutableSetTestsBase<O, V> where V.T: AnyRealmValue {
    func testSum() {
        XCTAssertEqual(mutableSet.sum().value.intValue, nil)
        mutableSet.insert(objectsIn: values)

        let expected = ((values.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber)

        // An unmanaged collection will return a double
        if case let .double(d) = mutableSet.sum().value {
            XCTAssertEqual(d, expected.doubleValue)
        } else if case let .decimal128(d) = mutableSet.sum().value {
            // A managed collection of AnyRealmValue will return a Decimal128 for `sum()`
            XCTAssertEqual(d.doubleValue, expected.doubleValue, accuracy: 0.1)
        }
    }

    func testAverage() {
        XCTAssertNil(mutableSet.average() as V.AverageType?)
        mutableSet.insert(objectsIn: values)

        let expected = ((values.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber)

        let v: AnyRealmValue? = mutableSet.average()
        // An unmanaged collection will return a double
        if case let .double(d) = v?.value {
            XCTAssertEqual(d, expected.doubleValue)
        } else if case let .decimal128(d) = v?.value {
            // A managed collection of AnyRealmValue will return a Decimal128 for `avg()`
            XCTAssertEqual(d.doubleValue, expected.doubleValue, accuracy: 0.1)
        }
    }
}

func addAnyRealmValueMutableSetTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueBoolFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueStringFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueDataFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueDateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueObjectFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueObjectIdFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AnyRealmValueMutableSetTests<OF, AnyRealmValueUUIDFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = MinMaxAnyRealmValueMutableSetTests<OF, AnyRealmValueIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxAnyRealmValueMutableSetTests<OF, AnyRealmValueFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxAnyRealmValueMutableSetTests<OF, AnyRealmValueDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxAnyRealmValueMutableSetTests<OF, AnyRealmValueDateFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxAnyRealmValueMutableSetTests<OF, AnyRealmValueDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)

    _ = AddableAnyRealmValueMutableSetTests<OF, AnyRealmValueIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddableAnyRealmValueMutableSetTests<OF, AnyRealmValueFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddableAnyRealmValueMutableSetTests<OF, AnyRealmValueDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddableAnyRealmValueMutableSetTests<OF, AnyRealmValueDecimal128Factory>._defaultTestSuite().tests.map(suite.addTest)
}

class UnmanagedAnyRealmValueMutableSetTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged Primitive Sets")
        addAnyRealmValueMutableSetTests(suite, UnmanagedObjectFactory.self)
        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}

class ManagedAnyRealmValueMutableSetTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Managed Primitive Sets")
        addAnyRealmValueMutableSetTests(suite, ManagedObjectFactory.self)
        return suite
    }

    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
}
