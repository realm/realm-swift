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
    let anyValue = RealmProperty<AnyRealmValue>()
}

protocol AnyValueFactory: ValueFactory {
    static var anyInitializer: (Self) -> AnyRealmValue { get }
    static func anyValues() -> [AnyRealmValue]
}
extension AnyValueFactory {
    static func anyValues() -> [AnyRealmValue] {
        return values().map(anyInitializer)
    }
}

extension Int: AnyValueFactory {
    static var anyInitializer: (Self) -> AnyRealmValue { AnyRealmValue.int }
}
extension Bool: AnyValueFactory {
    static var anyInitializer: (Self) -> AnyRealmValue { AnyRealmValue.bool }
    static func anyValues() -> [AnyRealmValue] {
        return [.bool(false), .bool(true), .none]
    }
}
extension Float: AnyValueFactory {
    static var anyInitializer: (Self) -> AnyRealmValue { AnyRealmValue.float }
}
extension Double: AnyValueFactory {
    static var anyInitializer: (Self) -> AnyRealmValue { AnyRealmValue.double }
}
extension String: AnyValueFactory {
    static var anyInitializer: (Self) -> AnyRealmValue { AnyRealmValue.string }
}
extension Data: AnyValueFactory {
    static var anyInitializer: (Self) -> AnyRealmValue { AnyRealmValue.data }
}
extension Date: AnyValueFactory {
    static var anyInitializer: (Self) -> AnyRealmValue { AnyRealmValue.date }
}
extension ObjectId: AnyValueFactory {
    static var anyInitializer: (ObjectId) -> AnyRealmValue { AnyRealmValue.objectId }
}
extension Decimal128: AnyValueFactory {
    static var anyInitializer: (Decimal128) -> AnyRealmValue { AnyRealmValue.decimal128 }
}
extension UUID: AnyValueFactory {
    static var anyInitializer: (Self) -> AnyRealmValue { AnyRealmValue.uuid }
}

extension SwiftStringObject: AnyValueFactory {
    static func values() -> [SwiftStringObject] {
        return [SwiftStringObject(value: ["a"]), SwiftStringObject(value: ["b"]), SwiftStringObject(value: ["c"])]
    }
    static func doubleValue(_ value: SwiftStringObject) -> Double { fatalError() }

    static var anyInitializer: (SwiftStringObject) -> AnyRealmValue { AnyRealmValue.object }
}

func doubleValue(_ value: AnyRealmValue) -> Double {
    if case let .double(d) = value {
        return d
    } else if case let .decimal128(d) = value {
        return d.doubleValue
    } else {
        fatalError("Unexpected mixed value: \(value)")
    }
}

class AnyRealmValueTests<T: AnyValueFactory>: TestCase {
    func testAnyRealmValue() {
        let values = T.anyValues()
        let o = AnyRealmTypeObject()
        o.anyValue.value = values[0]
        XCTAssertEqual(o.anyValue.value, values[0])
        o.anyValue.value = values[1]
        XCTAssertEqual(o.anyValue.value, values[1])
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value, values[1])
        try! realm.write {
            o.anyValue.value = values[2]
        }
        XCTAssertEqual(o.anyValue.value, values[2])
    }
}
class AnyRealmValuePrimitiveTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Any Realm Value Tests")
        AnyRealmValueTests<Int>.defaultTestSuite.tests.forEach(suite.addTest)
        AnyRealmValueTests<Bool>.defaultTestSuite.tests.forEach(suite.addTest)
        AnyRealmValueTests<Float>.defaultTestSuite.tests.forEach(suite.addTest)
        AnyRealmValueTests<String>.defaultTestSuite.tests.forEach(suite.addTest)
        AnyRealmValueTests<Data>.defaultTestSuite.tests.forEach(suite.addTest)
        AnyRealmValueTests<Date>.defaultTestSuite.tests.forEach(suite.addTest)
        AnyRealmValueTests<ObjectId>.defaultTestSuite.tests.forEach(suite.addTest)
        AnyRealmValueTests<Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)
        AnyRealmValueTests<UUID>.defaultTestSuite.tests.forEach(suite.addTest)
        return suite
    }
}

class AnyRealmValueObjectTests: TestCase {
    func testObject() {
        let o = AnyRealmTypeObject()
        let so = SwiftStringObject()
        so.stringCol = "hello"
        o.anyValue.value = .object(so)
        XCTAssertEqual(o.anyValue.value.object(SwiftStringObject.self)!.stringCol, "hello")
        o.anyValue.value.object(SwiftStringObject.self)!.stringCol = "there"
        XCTAssertEqual(o.anyValue.value.object(SwiftStringObject.self)!.stringCol, "there")
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.object(SwiftStringObject.self)!.stringCol, "there")
        try! realm.write {
            o.anyValue.value.object(SwiftStringObject.self)!.stringCol = "bye!"
        }
        XCTAssertEqual(o.anyValue.value.object(SwiftStringObject.self)!.stringCol, "bye!")
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
        XCTAssertEqual(o.anyValue.value.object(SwiftStringObject.self)!.stringCol, "hello")
    }

    func testDynamicObjectAccessor() {
        // The first block knows about SwiftStringObject and will add it as a value to
        // SwiftObject.anyCol
        autoreleasepool {
            let realm = realmWithTestPath(configuration: .init(objectTypes: [SwiftObject.self,
                                                                             SwiftOwnerObject.self,
                                                                             SwiftBoolObject.self,
                                                                             SwiftDogObject.self,
                                                                             SwiftStringObject.self]))
            try! realm.write {
                let dog = SwiftStringObject(value: ["stringCol": "some string..."])
                let parent = SwiftObject(value: ["anyCol": dog])
                realm.add(parent)
            }
            XCTAssertEqual(realm.objects(SwiftStringObject.self).count, 1)
        }

        // The second block omits SwiftStringObject from objectTypes so test that the
        // object can be retrieved dynamically.
        let realm = realmWithTestPath(configuration: .init(objectTypes: [SwiftObject.self,
                                                                         SwiftOwnerObject.self,
                                                                         SwiftBoolObject.self,
                                                                         SwiftDogObject.self]))
        // Ensure that SwiftStringObject does not exist in the schema
        XCTAssertFalse(realm.schema.objectSchema.map { $0.className }.contains("SwiftStringObject"))
        guard let object = realm.objects(SwiftObject.self).first else {
            return XCTFail("SwiftObject does not exist")
        }
        guard let dynamicObject = object.anyCol.value.dynamicObject else {
            return XCTFail("dynamicObject does not exist")
        }
        XCTAssertEqual(dynamicObject.stringCol as! String, "some string...")
    }

    private func testVariation<T: Equatable>(object: AnyRealmTypeObject,
                                             value: AnyRealmValue,
                                             keyPath: KeyPath<AnyRealmValue, T?>,
                                             expected: T,
                                             realm: Realm?) {
        realm?.beginWrite()
        object.anyValue.value = value
        try! realm?.commitWrite()
        if let date = expected as? Date {
            XCTAssertEqual(object.anyValue.value.dateValue!.timeIntervalSince1970,
                           date.timeIntervalSince1970,
                           accuracy: 1.0)
        } else {
            XCTAssertEqual(object.anyValue.value[keyPath: keyPath], expected)
        }
    }
}

// MARK: - List tests

class AnyRealmValueListTestsBase<O: ObjectFactory, V: AnyValueFactory>: TestCase {
    var realm: Realm?
    var obj: ModernAllTypesObject!
    var array: List<AnyRealmValue>!
    var values: [AnyRealmValue]!

    override func setUp() {
        obj = O.get()
        realm = obj.realm
        array = obj.arrayAny
        values = V.anyValues()
    }

    override func tearDown() {
        realm?.cancelWrite()
        array = nil
        obj = nil
    }
}

class AnyRealmValueListTests<O: ObjectFactory, V: AnyValueFactory>: AnyRealmValueListTestsBase<O, V> {
    private func assertEqual(_ obj: AnyRealmValue, _ anotherObj: AnyRealmValue) {
        if case let .object(a) = obj, case let .object(b) = anotherObj {
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
            assertEqual(array[i], values[i])
        }
        assertThrows(array[values.count], reason: "Index 3 is out of bounds")
        assertThrows(array[-1], reason: "negative value")
    }

    func testFirst() {
        array.append(objectsIn: values)
        assertEqual(array.first!, values.first!)
        array.removeAll()
        XCTAssertNil(array.first)
    }

    func testLast() {
        array.append(objectsIn: values)
        assertEqual(array.last!, values.last!)
        array.removeAll()
        XCTAssertNil(array.last)

    }

    func testValueForKey() {
        array.append(objectsIn: values)

        let actual: [AnyRealmValue]  = array.value(forKey: "self").map {
            if $0 is NSNull {
                return .none
            }
            return V.anyInitializer(dynamicBridgeCast(fromObjectiveC: $0) as V)
        }

        for (expected, actual) in zip(values!, actual) {
            assertEqual(expected, actual)
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
        assertEqual(values[0], array[0])

        array.insert(values[1], at: 0)
        XCTAssertEqual(Int(2), array.count)
        assertEqual(values[1], array[0])
        assertEqual(values[0], array[1])

        array.insert(values[2], at: 2)
        XCTAssertEqual(Int(3), array.count)
        assertEqual(values[1], array[0])
        assertEqual(values[0], array[1])
        assertEqual(values[2], array[2])

        assertThrows(array.insert(values[0], at: 4))
        assertThrows(array.insert(values[0], at: -1))
    }

    func testRemove() {
        assertThrows(array.remove(at: 0))
        assertThrows(array.remove(at: -1))

        array.append(objectsIn: values)

        assertThrows(array.remove(at: -1))
        assertEqual(values[0], array[0])
        assertEqual(values[1], array[1])
        assertEqual(values[2], array[2])
        assertThrows(array[3])

        array.remove(at: 0)
        assertEqual(values[1], array[0])
        assertEqual(values[2], array[1])
        assertThrows(array[2])
        assertThrows(array.remove(at: 2))

        array.remove(at: 1)
        assertEqual(values[1], array[0])
        assertThrows(array[1])
    }

    func testRemoveLast() {
        assertThrows(array.removeLast())

        array.append(objectsIn: values)
        array.removeLast()

        XCTAssertEqual(array.count, 2)
        assertEqual(values[0], array[0])
        assertEqual(values[1], array[1])

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
        assertEqual(array[0], values[0])
        assertEqual(array[1], values[0])
        assertEqual(array[2], values[2])

        assertThrows(array.replace(index: 3, object: values[0]),
                     reason: "Index 3 is out of bounds")
        assertThrows(array.replace(index: -1, object: values[0]),
                     reason: "Cannot pass a negative value")
    }

    func testReplaceRange() {
        assertSucceeds { array.replaceSubrange(0..<0, with: []) }

        array.replaceSubrange(0..<0, with: [values[0]])
        XCTAssertEqual(array.count, 1)
        assertEqual(array[0], values[0])

        array.replaceSubrange(0..<1, with: values)
        XCTAssertEqual(array.count, 3)

        array.replaceSubrange(1..<2, with: [])
        XCTAssertEqual(array.count, 2)
        assertEqual(array[0], values[0])
        assertEqual(array[1], values[2])
    }

    func testMove() {
        assertThrows(array.move(from: 1, to: 0), reason: "out of bounds")

        array.append(objectsIn: values)
        array.move(from: 2, to: 0)
        assertEqual(array[0], values[2])
        assertEqual(array[1], values[0])
        assertEqual(array[2], values[1])

        assertThrows(array.move(from: 3, to: 0), reason: "Index 3 is out of bounds")
        assertThrows(array.move(from: 0, to: 3), reason: "Index 3 is out of bounds")
        assertThrows(array.move(from: -1, to: 0), reason: "negative value")
        assertThrows(array.move(from: 0, to: -1), reason: "negative value")
    }

    func testSwap() {
        assertThrows(array.swapAt(0, 1), reason: "out of bounds")

        array.append(objectsIn: values)
        array.swapAt(0, 2)
        assertEqual(array[0], values[2])
        assertEqual(array[1], values[1])
        assertEqual(array[2], values[0])

        assertThrows(array.swapAt(3, 0), reason: "Index 3 is out of bounds")
        assertThrows(array.swapAt(0, 3), reason: "Index 3 is out of bounds")
        assertThrows(array.swapAt(-1, 0), reason: "negative value")
        assertThrows(array.swapAt(0, -1), reason: "negative value")
    }

    func testAssign() {
        XCTAssertEqual(Int(0), array.count)

        array.insert(values[0], at: 0)
        XCTAssertEqual(Int(1), array.count)
        assertEqual(values[0], array[0])

        array[0] = values[1]
        XCTAssertEqual(Int(1), array.count)
        assertEqual(values[1], array[0])
    }
}

class MinMaxAnyRealmValueListTests<O: ObjectFactory, V: AnyValueFactory>: AnyRealmValueListTestsBase<O, V> {
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

class AddableAnyRealmValueListTests<O: ObjectFactory, V: AnyValueFactory>: AnyRealmValueListTestsBase<O, V> where V: NumericValueFactory {
    func testSum() {
        if array.realm != nil {
            XCTAssertEqual(array.sum().intValue, nil)
        } else {
            XCTAssertEqual(array.sum().intValue, 0)
        }
        array.append(objectsIn: values)

        XCTAssertEqual(doubleValue(array.sum()), V.sum(), accuracy: 0.1)
    }

    func testAverage() {
        XCTAssertNil(array.average() as V.AverageType?)
        array.append(objectsIn: values)

        let v: AnyRealmValue = array.average()!
        XCTAssertEqual(doubleValue(v), V.average(), accuracy: 0.1)
    }
}

func addAnyRealmValueTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    AnyRealmValueListTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueListTests<OF, Bool>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueListTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueListTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueListTests<OF, String>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueListTests<OF, Data>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueListTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueListTests<OF, SwiftStringObject>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueListTests<OF, ObjectId>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueListTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueListTests<OF, UUID>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxAnyRealmValueListTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueListTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueListTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueListTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueListTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)

    AddableAnyRealmValueListTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    AddableAnyRealmValueListTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    AddableAnyRealmValueListTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    AddableAnyRealmValueListTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)
}

class UnmanagedAnyRealmValueListTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged AnyRealmValue Lists")
        addAnyRealmValueTests(suite, UnmanagedObjectFactory.self)
        return suite
    }
}

class ManagedAnyRealmValueListTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Managed AnyRealmValue Lists")
        addAnyRealmValueTests(suite, ManagedObjectFactory.self)
        return suite
    }
}

// MARK: - Set tests

class AnyRealmValueSetTestsBase<O: ObjectFactory, V: AnyValueFactory>: TestCase {
    var realm: Realm?
    var obj: ModernAllTypesObject!
    var obj2: ModernAllTypesObject!
    var mutableSet: MutableSet<AnyRealmValue>!
    var otherMutableSet: MutableSet<AnyRealmValue>!
    var values: [AnyRealmValue]!

    override func setUp() {
        obj = O.get()
        obj2 = O.get()
        realm = obj.realm
        mutableSet = obj.setAny
        otherMutableSet = obj2.setAny
        values = V.anyValues()
    }

    override func tearDown() {
        realm?.cancelWrite()
        mutableSet = nil
        obj = nil
        realm = nil
    }
}

class AnyRealmValueMutableSetTests<O: ObjectFactory, V: AnyValueFactory>: AnyRealmValueSetTestsBase<O, V> {
    private func assertEqual(_ obj: AnyRealmValue, _ anotherObj: AnyRealmValue) {
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
        let kvc = (mutableSet.value(forKey: "self") as [AnyObject]).first!
        switch values[0] {
        case let .object(o):
            if let obj = kvc as? SwiftStringObject {
                XCTAssertEqual(obj.stringCol, (o as! SwiftStringObject).stringCol)
            } else {
                XCTFail("not an object")
            }
        case let .bool(b):
            XCTAssertEqual(kvc as! Bool, b)
        case let .data(d):
            XCTAssertEqual(kvc as! Data, d)
        case let .date(d):
            XCTAssertEqual(kvc as! Date, d)
        case let .decimal128(d):
            XCTAssertEqual(kvc as! Decimal128, d)
        case let .double(d):
            XCTAssertEqual(kvc as! Double, d)
        case let .float(f):
            XCTAssertEqual(kvc as! Float, f)
        case let .int(i):
            XCTAssertEqual(kvc as! Int, i)
        case .none:
            XCTAssertNil(kvc)
        case let .objectId(o):
            XCTAssertEqual(kvc as! ObjectId, o)
        case let .string(s):
            XCTAssertEqual(kvc as! String, s)
        case let .uuid(u):
            XCTAssertEqual(kvc as! UUID, u)
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
        assertEqual(mutableSet[0], values[0])
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
        if values[0].object(SwiftStringObject.self) != nil {
            XCTAssertTrue(values.map {
                $0.object(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[0].object(SwiftStringObject.self)?.stringCol))
            XCTAssertTrue(values.map {
                $0.object(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[1].object(SwiftStringObject.self)?.stringCol))
            XCTAssertTrue(values.map {
                $0.object(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[2].object(SwiftStringObject.self)?.stringCol))
        } else {
            XCTAssertTrue(values.map { $0 }.contains(mutableSet[0]))
            XCTAssertTrue(values.map { $0 }.contains(mutableSet[1]))
            XCTAssertTrue(values.map { $0 }.contains(mutableSet[2]))
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
        if values[0].object(SwiftStringObject.self) != nil {
            XCTAssertTrue(values.map {
                $0.object(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[0].object(SwiftStringObject.self)?.stringCol))
            XCTAssertTrue(values.map {
                $0.object(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[1].object(SwiftStringObject.self)?.stringCol))
            XCTAssertTrue(values.map {
                $0.object(SwiftStringObject.self)?.stringCol
            }.contains(mutableSet[2].object(SwiftStringObject.self)?.stringCol))
        } else {
            XCTAssertTrue(values.map { $0 }.contains(mutableSet[0]))
            XCTAssertTrue(values.map { $0 }.contains(mutableSet[1]))
            XCTAssertTrue(values.map { $0 }.contains(mutableSet[2]))
        }
    }
}

class MinMaxAnyRealmValueMutableSetTests<O: ObjectFactory, V: AnyValueFactory>: AnyRealmValueSetTestsBase<O, V> {
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

class AddableAnyRealmValueMutableSetTests<O: ObjectFactory, V: AnyValueFactory>: AnyRealmValueSetTestsBase<O, V> where V: NumericValueFactory {
    func testSum() {
        if mutableSet.realm != nil {
            XCTAssertEqual(mutableSet.sum().intValue, nil)
        } else {
            XCTAssertEqual(mutableSet.sum().intValue, 0)
        }
        mutableSet.insert(objectsIn: values)
        XCTAssertEqual(doubleValue(mutableSet.sum()), V.sum(), accuracy: 0.1)
    }

    func testAverage() {
        XCTAssertNil(mutableSet.average() as V.AverageType?)
        mutableSet.insert(objectsIn: values)

        let v: AnyRealmValue = mutableSet.average()!
        XCTAssertEqual(doubleValue(v), V.average(), accuracy: 0.1)
    }
}

func addAnyRealmValueMutableSetTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    AnyRealmValueMutableSetTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMutableSetTests<OF, Bool>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMutableSetTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMutableSetTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMutableSetTests<OF, String>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMutableSetTests<OF, Data>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMutableSetTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMutableSetTests<OF, SwiftStringObject>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMutableSetTests<OF, ObjectId>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMutableSetTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMutableSetTests<OF, UUID>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxAnyRealmValueMutableSetTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueMutableSetTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueMutableSetTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueMutableSetTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueMutableSetTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)

    AddableAnyRealmValueMutableSetTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    AddableAnyRealmValueMutableSetTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    AddableAnyRealmValueMutableSetTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    AddableAnyRealmValueMutableSetTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)
}

class UnmanagedAnyRealmValueMutableSetTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged Primitive Sets")
        addAnyRealmValueMutableSetTests(suite, UnmanagedObjectFactory.self)
        return suite
    }
}

class ManagedAnyRealmValueMutableSetTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Managed Primitive Sets")
        addAnyRealmValueMutableSetTests(suite, ManagedObjectFactory.self)
        return suite
    }
}

// MARK: - Map tests

class AnyRealmValueMapTestsBase<O: ObjectFactory, V: AnyValueFactory>: TestCase {
    var realm: Realm?
    var obj: ModernAllTypesObject!
    var map: Map<String, AnyRealmValue>!
    var values: [(key: String, value: AnyRealmValue)]!

    override func setUp() {
        obj = O.get()
        realm = obj.realm
        map = obj.mapAny
        values = V.anyValues().enumerated().map { (key: "key\($0)", value: $1) }
    }

    override func tearDown() {
        realm?.cancelWrite()
        map = nil
        obj = nil
        realm = nil
    }
}

class AnyRealmValueMapTests<O: ObjectFactory, V: AnyValueFactory>: AnyRealmValueMapTestsBase<O, V> {
    func testInvalidated() {
        XCTAssertFalse(map.isInvalidated)
        if let realm = obj.realm {
            realm.delete(obj)
            XCTAssertTrue(map.isInvalidated)
        }
    }

    // KVC requires the key to be a string.
    func testValueForKey() {
        let key = values[0].key
        XCTAssertNil(map.value(forKey: key))
        map[values[0].key] = values[0].value
        let kvc: AnyObject? = map.value(forKey: key)
        switch values[0].value {
        case let .object(o):
            if let obj = kvc as? SwiftStringObject {
                XCTAssertEqual(obj.stringCol, (o as! SwiftStringObject).stringCol)
            } else {
                XCTFail("not an object")
            }
        case let .bool(b):
            XCTAssertEqual(kvc as! Bool, b)
        case let .data(d):
            XCTAssertEqual(kvc as! Data, d)
        case let .date(d):
            XCTAssertEqual(kvc as! Date, d)
        case let .decimal128(d):
            XCTAssertEqual(kvc as! Decimal128, d)
        case let .double(d):
            XCTAssertEqual(kvc as! Double, d)
        case let .float(f):
            XCTAssertEqual(kvc as! Float, f)
        case let .int(i):
            XCTAssertEqual(kvc as! Int, i)
        case .none:
            XCTAssertNil(kvc)
        case let .objectId(o):
            XCTAssertEqual(kvc as! ObjectId, o)
        case let .string(s):
            XCTAssertEqual(kvc as! String, s)
        case let .uuid(u):
            XCTAssertEqual(kvc as! UUID, u)
        }
    }

    func assertValue(_ value: AnyRealmValue, key: String) {
        if case let .object(o) = map[key] {
            XCTAssertTrue(map.contains(where: { key, value in
                return key == key && (value.object(SwiftStringObject.self)!.stringCol == o["stringCol"] as! String)
            }))
        } else {
            XCTAssertTrue(map.contains(where: { k, v in
                return k == key && v == value
            }))
        }
    }

    func testInsert() {
        XCTAssertEqual(0, map.count)

        map[values[0].key] = values[0].value
        XCTAssertEqual(1, map.count)
        XCTAssertEqual(1, map.keys.count)
        XCTAssertEqual(1, map.values.count)
        XCTAssertTrue(Set([values[0].key]).isSubset(of: map.keys))
        assertValue(values[0].value, key: values[0].key)

        map[values[1].key] = values[1].value
        XCTAssertEqual(2, map.count)
        XCTAssertEqual(2, map.keys.count)
        XCTAssertEqual(2, map.values.count)
        XCTAssertTrue(Set([values[0].key, values[1].key]).isSubset(of: map.keys))
        assertValue(values[1].value, key: values[1].key)

        map[values[2].key] = values[2].value
        XCTAssertEqual(3, map.count)
        XCTAssertEqual(3, map.keys.count)
        XCTAssertEqual(3, map.values.count)
        XCTAssertTrue(Set(values.map { $0.key }).isSubset(of: map.keys))
        assertValue(values[2].value, key: values[2].key)
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
        map[values[0].key] = AnyRealmValue.none
        XCTAssertEqual(2, map.count)
        XCTAssertEqual(2, map.keys.count)
        XCTAssertEqual(2, map.values.count)
        XCTAssertTrue(Set([values[0].key, values[2].key]).isSubset(of: map.keys))
        // getter
        map.removeAll()
        XCTAssertNil(map[values[0].key])
        map[values[0].key] = values[0].value
        if case let .object(o) = map[values[0].key] {
            XCTAssertEqual(values[0].value.object(SwiftStringObject.self)!.stringCol, (o as! SwiftStringObject).stringCol)
        } else {
            XCTAssertEqual(values[0].value, map[values[0].key])
        }
    }
}

class MinMaxAnyRealmValueMapTests<O: ObjectFactory, V: AnyValueFactory>: AnyRealmValueMapTestsBase<O, V> {
    func testMin() {
        XCTAssertNil(map.min())
        map.merge(values) { $1 }
        XCTAssertEqual(map.min(), values.first?.value)
    }

    func testMax() {
        XCTAssertNil(map.max())
        map.merge(values) { $1 }
        XCTAssertEqual(map.max(), values.last?.value)
    }
}

class AddableAnyRealmValueMapTests<O: ObjectFactory, V: AnyValueFactory>: AnyRealmValueMapTestsBase<O, V> where V: NumericValueFactory {
    func testSum() {
        XCTAssertEqual(map.sum().intValue, 0)
        map.merge(values) { $1 }
        XCTAssertEqual(doubleValue(map.sum()), V.sum(), accuracy: 0.1)
    }

    func testAverage() {
        XCTAssertNil(map.average() as V.AverageType?)
        map.merge(values) { $1 }
        let v: AnyRealmValue = map.average()!
        XCTAssertEqual(doubleValue(v), V.average(), accuracy: 0.1)
    }
}

func addAnyRealmValueMapTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    AnyRealmValueMapTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMapTests<OF, Bool>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMapTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMapTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMapTests<OF, String>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMapTests<OF, Data>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMapTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMapTests<OF, SwiftStringObject>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMapTests<OF, ObjectId>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMapTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)
    AnyRealmValueMapTests<OF, UUID>.defaultTestSuite.tests.forEach(suite.addTest)

    MinMaxAnyRealmValueMapTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueMapTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueMapTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueMapTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    MinMaxAnyRealmValueMapTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)

    AddableAnyRealmValueMapTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    AddableAnyRealmValueMapTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    AddableAnyRealmValueMapTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    AddableAnyRealmValueMapTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)
}

class UnmanagedAnyRealmValueMapTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged AnyRealmValue Maps")
        addAnyRealmValueMapTests(suite, UnmanagedObjectFactory.self)
        return suite
    }
}

class ManagedAnyRealmValueMapTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "Managed AnyRealmValue Maps")
        addAnyRealmValueMapTests(suite, ManagedObjectFactory.self)
        return suite
    }
}
