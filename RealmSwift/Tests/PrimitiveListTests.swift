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

// swiftlint:disable type_name identifier_name statement_position cyclomatic_complexity

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
    associatedtype T: RealmCollectionValue
    associatedtype W: RealmCollectionValue = T
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

final class FloatFactory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Float> {
        return obj.float
    }

    static func values() -> [Float] {
        return [1.1, 2.2, 3.3]
    }
}

final class DoubleFactory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Double> {
        return obj.double
    }

    static func values() -> [Double] {
        return [1.1, 2.2, 3.3]
    }
}

final class StringFactory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<String> {
        return obj.string
    }

    static func values() -> [String] {
        return ["a", "b", "c"]
    }
}

final class DataFactory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Data> {
        return obj.data
    }

    static func values() -> [Data] {
        return ["a".data(using: .utf8)!, "b".data(using: .utf8)!, "c".data(using: .utf8)!]
    }
}

final class DateFactory: ValueFactory {
    static func array(_ obj: SwiftListObject) -> List<Date> {
        return obj.date
    }

    static func values() -> [Date] {
        return [Date(), Date().addingTimeInterval(10), Date().addingTimeInterval(20)]
    }
}

final class OptionalIntFactory: ValueFactory {
    typealias W = Int

    static func array(_ obj: SwiftListObject) -> List<Int?> {
        return obj.intOpt
    }

    static func values() -> [Int?] {
        return [nil, 1, 3]
    }
}

final class OptionalInt8Factory: ValueFactory {
    typealias W = Int8

    static func array(_ obj: SwiftListObject) -> List<Int8?> {
        return obj.int8Opt
    }

    static func values() -> [Int8?] {
        return [nil, 1, 3]
    }
}

final class OptionalInt16Factory: ValueFactory {
    typealias W = Int16

    static func array(_ obj: SwiftListObject) -> List<Int16?> {
        return obj.int16Opt
    }

    static func values() -> [Int16?] {
        return [nil, 1, 3]
    }
}

final class OptionalInt32Factory: ValueFactory {
    typealias W = Int32

    static func array(_ obj: SwiftListObject) -> List<Int32?> {
        return obj.int32Opt
    }

    static func values() -> [Int32?] {
        return [nil, 1, 3]
    }
}

final class OptionalInt64Factory: ValueFactory {
    typealias W = Int64

    static func array(_ obj: SwiftListObject) -> List<Int64?> {
        return obj.int64Opt
    }

    static func values() -> [Int64?] {
        return [nil, 1, 3]
    }
}

final class OptionalFloatFactory: ValueFactory {
    typealias W = Float

    static func array(_ obj: SwiftListObject) -> List<Float?> {
        return obj.floatOpt
    }

    static func values() -> [Float?] {
        return [nil, 1.1, 3.3]
    }
}

final class OptionalDoubleFactory: ValueFactory {
    typealias W = Double

    static func array(_ obj: SwiftListObject) -> List<Double?> {
        return obj.doubleOpt
    }

    static func values() -> [Double?] {
        return [nil, 1.1, 3.3]
    }
}

final class OptionalStringFactory: ValueFactory {
    typealias W = String

    static func array(_ obj: SwiftListObject) -> List<String?> {
        return obj.stringOpt
    }

    static func values() -> [String?] {
        return [nil, "a", "c"]
    }
}

final class OptionalDataFactory: ValueFactory {
    typealias W = Data

    static func array(_ obj: SwiftListObject) -> List<Data?> {
        return obj.dataOpt
    }

    static func values() -> [Data?] {
        return [nil, "a".data(using: .utf8), "c".data(using: .utf8)]
    }
}

final class OptionalDateFactory: ValueFactory {
    typealias W = Date

    static func array(_ obj: SwiftListObject) -> List<Date?> {
        return obj.dateOpt
    }

    static func values() -> [Date?] {
        return [nil, Date(), Date().addingTimeInterval(20)]
    }
}

// Older versions of swift only support three version components in top-level
// #if, so this check to be done outside the class...
#if swift(>=3.4) && (swift(>=4.1.50) || !swift(>=4))
class EquatableTestCase: TestCase {
    func assertEqualTo<T: Equatable>(_ expected: T, _ actual: T, fileName: StaticString = #file, lineNumber: UInt = #line) {
        XCTAssertEqual(expected, actual, file: fileName, line: lineNumber)
    }
}
#else
class EquatableTestCase: TestCase {
    // writing value as! Int? gives "cannot downcast from 'T' to a more optional type 'Optional<Int>'"
    // but doing this nonsense works
    func cast<T, U>(_ value: T) -> U {
        return value as! U
    }

    // No conditional conformance means that Optional<T: Equatable> can't
    // itself conform to Equatable
    func assertEqualTo<T>(_ expected: T, _ actual: T, fileName: StaticString = #file, lineNumber: UInt = #line) {
        if T.self is Int.Type {
            XCTAssertEqual(expected as! Int, actual as! Int, file: fileName, line: lineNumber)
        }
        else if T.self is Float.Type {
            XCTAssertEqual(expected as! Float, actual as! Float, file: fileName, line: lineNumber)
        }
        else if T.self is Double.Type {
            XCTAssertEqual(expected as! Double, actual as! Double, file: fileName, line: lineNumber)
        }
        else if T.self is Bool.Type {
            XCTAssertEqual(expected as! Bool, actual as! Bool, file: fileName, line: lineNumber)
        }
        else if T.self is Int8.Type {
            XCTAssertEqual(expected as! Int8, actual as! Int8, file: fileName, line: lineNumber)
        }
        else if T.self is Int16.Type {
            XCTAssertEqual(expected as! Int16, actual as! Int16, file: fileName, line: lineNumber)
        }
        else if T.self is Int32.Type {
            XCTAssertEqual(expected as! Int32, actual as! Int32, file: fileName, line: lineNumber)
        }
        else if T.self is Int64.Type {
            XCTAssertEqual(expected as! Int64, actual as! Int64, file: fileName, line: lineNumber)
        }
        else if T.self is String.Type {
            XCTAssertEqual(expected as! String, actual as! String, file: fileName, line: lineNumber)
        }
        else if T.self is Data.Type {
            XCTAssertEqual(expected as! Data, actual as! Data, file: fileName, line: lineNumber)
        }
        else if T.self is Date.Type {
            XCTAssertEqual(expected as! Date, actual as! Date, file: fileName, line: lineNumber)
        }
        else if T.self is [Int].Type {
            XCTAssertEqual(expected as! [Int], actual as! [Int], file: fileName, line: lineNumber)
        }
        else if T.self is [Float].Type {
            XCTAssertEqual(expected as! [Float], actual as! [Float], file: fileName, line: lineNumber)
        }
        else if T.self is [Double].Type {
            XCTAssertEqual(expected as! [Double], actual as! [Double], file: fileName, line: lineNumber)
        }
        else if T.self is [Bool].Type {
            XCTAssertEqual(expected as! [Bool], actual as! [Bool], file: fileName, line: lineNumber)
        }
        else if T.self is [Int8].Type {
            XCTAssertEqual(expected as! [Int8], actual as! [Int8], file: fileName, line: lineNumber)
        }
        else if T.self is [Int16].Type {
            XCTAssertEqual(expected as! [Int16], actual as! [Int16], file: fileName, line: lineNumber)
        }
        else if T.self is [Int32].Type {
            XCTAssertEqual(expected as! [Int32], actual as! [Int32], file: fileName, line: lineNumber)
        }
        else if T.self is [Int64].Type {
            XCTAssertEqual(expected as! [Int64], actual as! [Int64], file: fileName, line: lineNumber)
        }
        else if T.self is [String].Type {
            XCTAssertEqual(expected as! [String], actual as! [String], file: fileName, line: lineNumber)
        }
        else if T.self is [Data].Type {
            XCTAssertEqual(expected as! [Data], actual as! [Data], file: fileName, line: lineNumber)
        }
        else if T.self is [Date].Type {
            XCTAssertEqual(expected as! [Date], actual as! [Date], file: fileName, line: lineNumber)
        }
        else if T.self is Int?.Type {
            XCTAssertEqual(cast(expected) as Int?, cast(actual) as Int?, file: fileName, line: lineNumber)
        }
        else if T.self is Float?.Type {
            XCTAssertEqual(cast(expected) as Float?, cast(actual) as Float?, file: fileName, line: lineNumber)
        }
        else if T.self is Double?.Type {
            XCTAssertEqual(cast(expected) as Double?, cast(actual) as Double?, file: fileName, line: lineNumber)
        }
        else if T.self is Bool?.Type {
            XCTAssertEqual(cast(expected) as Bool?, cast(actual) as Bool?, file: fileName, line: lineNumber)
        }
        else if T.self is Int8?.Type {
            XCTAssertEqual(cast(expected) as Int8?, cast(actual) as Int8?, file: fileName, line: lineNumber)
        }
        else if T.self is Int16?.Type {
            XCTAssertEqual(cast(expected) as Int16?, cast(actual) as Int16?, file: fileName, line: lineNumber)
        }
        else if T.self is Int32?.Type {
            XCTAssertEqual(cast(expected) as Int32?, cast(actual) as Int32?, file: fileName, line: lineNumber)
        }
        else if T.self is Int64?.Type {
            XCTAssertEqual(cast(expected) as Int64?, cast(actual) as Int64?, file: fileName, line: lineNumber)
        }
        else if T.self is String?.Type {
            XCTAssertEqual(cast(expected) as String?, cast(actual) as String?, file: fileName, line: lineNumber)
        }
        else if T.self is Data?.Type {
            XCTAssertEqual(cast(expected) as Data?, cast(actual) as Data?, file: fileName, line: lineNumber)
        }
        else if T.self is Date?.Type {
            XCTAssertEqual(cast(expected) as Date?, cast(actual) as Date?, file: fileName, line: lineNumber)
        }
        else if T.self is [Int?].Type {
            assertEqual(cast(expected) as [Int?], cast(actual) as [Int?], file: fileName, line: lineNumber)
        }
        else if T.self is [Float?].Type {
            assertEqual(cast(expected) as [Float?], cast(actual) as [Float?], file: fileName, line: lineNumber)
        }
        else if T.self is [Double?].Type {
            assertEqual(cast(expected) as [Double?], cast(actual) as [Double?], file: fileName, line: lineNumber)
        }
        else if T.self is [Bool?].Type {
            assertEqual(cast(expected) as [Bool?], cast(actual) as [Bool?], file: fileName, line: lineNumber)
        }
        else if T.self is [Int8?].Type {
            assertEqual(cast(expected) as [Int8?], cast(actual) as [Int8?], file: fileName, line: lineNumber)
        }
        else if T.self is [Int16?].Type {
            assertEqual(cast(expected) as [Int16?], cast(actual) as [Int16?], file: fileName, line: lineNumber)
        }
        else if T.self is [Int32?].Type {
            assertEqual(cast(expected) as [Int32?], cast(actual) as [Int32?], file: fileName, line: lineNumber)
        }
        else if T.self is [Int64?].Type {
            assertEqual(cast(expected) as [Int64?], cast(actual) as [Int64?], file: fileName, line: lineNumber)
        }
        else if T.self is [String?].Type {
            assertEqual(cast(expected) as [String?], cast(actual) as [String?], file: fileName, line: lineNumber)
        }
        else if T.self is [Data?].Type {
            assertEqual(cast(expected) as [Data?], cast(actual) as [Data?], file: fileName, line: lineNumber)
        }
        else if T.self is [Date?].Type {
            assertEqual(cast(expected) as [Date?], cast(actual) as [Date?], file: fileName, line: lineNumber)
        }
        else {
            XCTFail("unsupported type \(T.self)", file: fileName, line: lineNumber)
            fatalError("unsupported type \(T.self)")
        }
    }

    func assertEqualTo<T>(_ expected: T?, _ actual: T?, fileName: StaticString = #file, lineNumber: UInt = #line) {
        if expected == nil {
            XCTAssertNil(actual, file: fileName, line: lineNumber)
        }
        else if actual == nil {
            XCTFail("nil")
        }
        else {
            assertEqualTo(expected!, actual!, fileName: fileName, lineNumber: lineNumber)
        }
    }

    func assertEqualTo<T>(_ expected: T, _ actual: T?) {
        guard let actual = actual else {
            XCTFail("nil")
            return
        }
        assertEqualTo(expected, actual)
    }
}
#endif

class PrimitiveListTestsBase<O: ObjectFactory, V: ValueFactory>: EquatableTestCase {
    var realm: Realm?
    var obj: SwiftListObject!
    var array: List<V.T>!
    var values: [V.T]!

#if swift(>=4)
    class func _defaultTestSuite() -> XCTestSuite {
        return defaultTestSuite
    }
#else
    class func _defaultTestSuite() -> XCTestSuite {
        return defaultTestSuite()
    }
#endif

    override func setUp() {
        obj = SwiftListObject()
        if O.isManaged() {
            let config = Realm.Configuration(inMemoryIdentifier: "test", objectTypes: [SwiftListObject.self])
            realm = try! Realm(configuration: config)
            realm!.beginWrite()
            realm!.add(obj)
        }
        array = V.array(obj)
        values = V.values()
    }

    override func tearDown() {
        realm?.cancelWrite()
        realm = nil
        array = nil
        obj = nil
    }
}

class PrimitiveListTests<O: ObjectFactory, V: ValueFactory>: PrimitiveListTestsBase<O, V> {
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
        assertEqualTo(0, array.index(of: values[0]))

        array.append(values[1])
        assertEqualTo(0, array.index(of: values[0]))
        assertEqualTo(1, array.index(of: values[1]))
    }

    // FIXME: Not yet implemented
    func disabled_testIndexMatching() {
        XCTAssertNil(array.index(matching: "self = %@", values[0]))

        array.append(values[0])
        assertEqualTo(0, array.index(matching: "self = %@", values[0]))

        array.append(values[1])
        assertEqualTo(0, array.index(matching: "self = %@", values[0]))
        assertEqualTo(1, array.index(matching: "self = %@", values[1]))
    }

    func testSubscript() {
        array.append(objectsIn: values)
        for i in 0..<values.count {
            assertEqualTo(array[i], values[i])
        }
        assertThrows(self.array[self.values.count], reason: "Index 3 is out of bounds")
        assertThrows(self.array[-1], reason: "negative value")
    }

    func testFirst() {
        array.append(objectsIn: values)
        assertEqualTo(array.first, values.first)
        array.removeAll()
        XCTAssertNil(array.first)
    }

    func testLast() {
        array.append(objectsIn: values)
        assertEqualTo(array.last, values.last)
        array.removeAll()
        XCTAssertNil(array.last)

    }

    func testValueForKey() {
        assertEqualTo(array.value(forKey: "self").count, 0)
        array.append(objectsIn: values)
        assertEqualTo(values!, array.value(forKey: "self").map { dynamicBridgeCast(fromObjectiveC: $0) as V.T })

        assertThrows(self.array.value(forKey: "not self"), named: "NSUnknownKeyException")
    }

    func testSetValueForKey() {
        // does this even make any sense?

    }

    func testFilter() {
        // not implemented

    }

    func testInsert() {
        assertEqualTo(Int(0), array.count)

        array.insert(values[0], at: 0)
        assertEqualTo(Int(1), array.count)
        assertEqualTo(values[0], array[0])

        array.insert(values[1], at: 0)
        assertEqualTo(Int(2), array.count)
        assertEqualTo(values[1], array[0])
        assertEqualTo(values[0], array[1])

        array.insert(values[2], at: 2)
        assertEqualTo(Int(3), array.count)
        assertEqualTo(values[1], array[0])
        assertEqualTo(values[0], array[1])
        assertEqualTo(values[2], array[2])

        assertThrows(_ = self.array.insert(self.values[0], at: 4))
        assertThrows(_ = self.array.insert(self.values[0], at: -1))
    }

    func testRemove() {
        assertThrows(self.array.remove(at: 0))
        assertThrows(self.array.remove(at: -1))

        array.append(objectsIn: values)

        assertThrows(self.array.remove(at: -1))
        assertEqualTo(values[0], array[0])
        assertEqualTo(values[1], array[1])
        assertEqualTo(values[2], array[2])
        assertThrows(self.array[3])

        array.remove(at: 0)
        assertEqualTo(values[1], array[0])
        assertEqualTo(values[2], array[1])
        assertThrows(self.array[2])
        assertThrows(self.array.remove(at: 2))

        array.remove(at: 1)
        assertEqualTo(values[1], array[0])
        assertThrows(self.array[1])
    }

    func testRemoveLast() {
        assertThrows(self.array.removeLast())

        array.append(objectsIn: values)
        array.removeLast()

        assertEqualTo(array.count, 2)
        assertEqualTo(values[0], array[0])
        assertEqualTo(values[1], array[1])

        array.removeLast(2)
        assertEqualTo(array.count, 0)
    }

    func testRemoveAll() {
        array.removeAll()
        array.append(objectsIn: values)
        array.removeAll()
        assertEqualTo(array.count, 0)
    }

    func testReplace() {
        assertThrows(self.array.replace(index: 0, object: self.values[0]),
                     reason: "Index 0 is out of bounds")

        array.append(objectsIn: values)
        array.replace(index: 1, object: values[0])
        assertEqualTo(array[0], values[0])
        assertEqualTo(array[1], values[0])
        assertEqualTo(array[2], values[2])

        assertThrows(self.array.replace(index: 3, object: self.values[0]),
                     reason: "Index 3 is out of bounds")
        assertThrows(self.array.replace(index: -1, object: self.values[0]),
                     reason: "Cannot pass a negative value")
    }

    func testReplaceRange() {
        assertSucceeds { array.replaceSubrange(0..<0, with: []) }

#if false
        // FIXME: The exception thrown here runs afoul of Swift's exclusive access checking.
        assertThrows(self.array.replaceSubrange(0..<1, with: []),
                     reason: "Index 0 is out of bounds")
#endif

        array.replaceSubrange(0..<0, with: [values[0]])
        XCTAssertEqual(array.count, 1)
        assertEqualTo(array[0], values[0])

        array.replaceSubrange(0..<1, with: values)
        XCTAssertEqual(array.count, 3)

        array.replaceSubrange(1..<2, with: [])
        XCTAssertEqual(array.count, 2)
        assertEqualTo(array[0], values[0])
        assertEqualTo(array[1], values[2])
    }

    func testMove() {
        assertThrows(self.array.move(from: 1, to: 0), reason: "out of bounds")

        array.append(objectsIn: values)
        array.move(from: 2, to: 0)
        assertEqualTo(array[0], values[2])
        assertEqualTo(array[1], values[0])
        assertEqualTo(array[2], values[1])

        assertThrows(self.array.move(from: 3, to: 0), reason: "Index 3 is out of bounds")
        assertThrows(self.array.move(from: 0, to: 3), reason: "Index 3 is out of bounds")
        assertThrows(self.array.move(from: -1, to: 0), reason: "negative value")
        assertThrows(self.array.move(from: 0, to: -1), reason: "negative value")
    }

    func testSwap() {
        assertThrows(self.array.swapAt(0, 1), reason: "out of bounds")

        array.append(objectsIn: values)
        array.swapAt(0, 2)
        assertEqualTo(array[0], values[2])
        assertEqualTo(array[1], values[1])
        assertEqualTo(array[2], values[0])

        assertThrows(self.array.swapAt(3, 0), reason: "Index 3 is out of bounds")
        assertThrows(self.array.swapAt(0, 3), reason: "Index 3 is out of bounds")
        assertThrows(self.array.swapAt(-1, 0), reason: "negative value")
        assertThrows(self.array.swapAt(0, -1), reason: "negative value")
    }
}

class MinMaxPrimitiveListTests<O: ObjectFactory, V: ValueFactory>: PrimitiveListTestsBase<O, V> where V.T: MinMaxType {
    func testMin() {
        XCTAssertNil(array.min())
        array.append(objectsIn: values.reversed())
        assertEqualTo(array.min(), values.first)
    }

    func testMax() {
        XCTAssertNil(array.max())
        array.append(objectsIn: values.reversed())
        assertEqualTo(array.max(), values.last)
    }
}

class OptionalMinMaxPrimitiveListTests<O: ObjectFactory, V: ValueFactory>: PrimitiveListTestsBase<O, V> where V.W: MinMaxType {
    // V.T and V.W? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.W
    var array2: List<V.W?> {
        return unsafeDowncast(array!, to: List<V.W?>.self)
    }

    func testMin() {
        XCTAssertNil(array2.min())
        array.append(objectsIn: values.reversed())
        let expected = values[1] as! V.W
        assertEqualTo(array2.min(), expected)
    }

    func testMax() {
        XCTAssertNil(array2.max())
        array.append(objectsIn: values.reversed())
        let expected = values[2] as! V.W
        assertEqualTo(array2.max(), expected)
    }
}

class AddablePrimitiveListTests<O: ObjectFactory, V: ValueFactory>: PrimitiveListTestsBase<O, V> where V.T: AddableType {
    func testSum() {
        assertEqualTo(array.sum(), V.T())
        array.append(objectsIn: values)

        // Expressing "can be added and converted to a floating point type" as
        // a protocol requirement is awful, so sidestep it all with obj-c
        let expected = ((values.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber).doubleValue
        let actual: V.T = array.sum()
        XCTAssertEqual((dynamicBridgeCast(fromSwift: actual) as! NSNumber).doubleValue, expected, accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(array.average())
        array.append(objectsIn: values)

        let expected = ((values.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber).doubleValue
        XCTAssertEqual(array.average()!, expected, accuracy: 0.01)
    }
}

class OptionalAddablePrimitiveListTests<O: ObjectFactory, V: ValueFactory>: PrimitiveListTestsBase<O, V> where V.W: AddableType {
    // V.T and V.W? are the same thing, but the type system doesn't know that
    // and the protocol constraint is on V.W
    var array2: List<V.W?> {
        return unsafeDowncast(array!, to: List<V.W?>.self)
    }

    func testSum() {
        assertEqualTo(array2.sum(), V.W())
        array.append(objectsIn: values)

        var nonNil = values!
        nonNil.remove(at: 0)

        // Expressing "can be added and converted to a floating point type" as
        // a protocol requirement is awful, so sidestep it all with obj-c
        let expected = ((nonNil.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@sum.self")! as! NSNumber).doubleValue
        let actual: V.W = array2.sum()
        XCTAssertEqual((dynamicBridgeCast(fromSwift: actual) as! NSNumber).doubleValue, expected, accuracy: 0.01)
    }

    func testAverage() {
        XCTAssertNil(array2.average())
        array.append(objectsIn: values)

        var nonNil = values!
        nonNil.remove(at: 0)

        let expected = ((nonNil.map(dynamicBridgeCast) as NSArray).value(forKeyPath: "@avg.self")! as! NSNumber).doubleValue
        XCTAssertEqual(array2.average()!, expected, accuracy: 0.01)
    }
}

class SortablePrimitiveListTests<O: ObjectFactory, V: ValueFactory>: PrimitiveListTestsBase<O, V> where V.T: Comparable {
    func testSorted() {
        var shuffled = values!
        shuffled.removeFirst()
        shuffled.append(values!.first!)
        array.append(objectsIn: shuffled)

        assertEqual(Array(array.sorted(ascending: true)), values)
        assertEqual(Array(array.sorted(ascending: false)), values.reversed())
    }
}

class OptionalSortablePrimitiveListTests<O: ObjectFactory, V: ValueFactory>: PrimitiveListTestsBase<O, V> where V.W: Comparable {
    func testSorted() {
        var shuffled = values!
        shuffled.removeFirst()
        shuffled.append(values!.first!)
        array.append(objectsIn: shuffled)

        let array2 = unsafeDowncast(array!, to: List<V.W?>.self)
        let values2 = unsafeBitCast(values!, to: Array<V.W?>.self)
        assertEqual(Array(array2.sorted(ascending: true)), values2)
        assertEqual(Array(array2.sorted(ascending: false)), values2.reversed())
    }
}

func addTests<OF: ObjectFactory>(_ suite: XCTestSuite, _ type: OF.Type) {
    _ = PrimitiveListTests<OF, IntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, Int8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, Int16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, Int32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, Int64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, FloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, DoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, StringFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, DataFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, DateFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = MinMaxPrimitiveListTests<OF, IntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveListTests<OF, Int8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveListTests<OF, Int16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveListTests<OF, Int32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveListTests<OF, Int64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveListTests<OF, FloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveListTests<OF, DoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = MinMaxPrimitiveListTests<OF, DateFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = AddablePrimitiveListTests<OF, IntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveListTests<OF, Int8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveListTests<OF, Int16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveListTests<OF, Int32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveListTests<OF, Int64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveListTests<OF, FloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = AddablePrimitiveListTests<OF, DoubleFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = PrimitiveListTests<OF, OptionalIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, OptionalInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, OptionalInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, OptionalInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, OptionalInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, OptionalFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, OptionalDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, OptionalStringFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, OptionalDataFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = PrimitiveListTests<OF, OptionalDateFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = OptionalMinMaxPrimitiveListTests<OF, OptionalIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveListTests<OF, OptionalInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveListTests<OF, OptionalInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveListTests<OF, OptionalInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveListTests<OF, OptionalInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveListTests<OF, OptionalFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveListTests<OF, OptionalDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalMinMaxPrimitiveListTests<OF, OptionalDateFactory>._defaultTestSuite().tests.map(suite.addTest)

    _ = OptionalAddablePrimitiveListTests<OF, OptionalIntFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveListTests<OF, OptionalInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveListTests<OF, OptionalInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveListTests<OF, OptionalInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveListTests<OF, OptionalInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveListTests<OF, OptionalFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
    _ = OptionalAddablePrimitiveListTests<OF, OptionalDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
}

class UnmanagedPrimitiveListTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Unmanaged Primitive Lists")
        addTests(suite, UnmanagedObjectFactory.self)
        return suite
    }

#if swift(>=4)
    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
#else
    override class func defaultTestSuite() -> XCTestSuite {
        return _defaultTestSuite()
    }
#endif
}

class ManagedPrimitiveListTests: TestCase {
    class func _defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Managed Primitive Lists")
        addTests(suite, ManagedObjectFactory.self)

        _ = SortablePrimitiveListTests<ManagedObjectFactory, IntFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveListTests<ManagedObjectFactory, Int8Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveListTests<ManagedObjectFactory, Int16Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveListTests<ManagedObjectFactory, Int32Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveListTests<ManagedObjectFactory, Int64Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveListTests<ManagedObjectFactory, FloatFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveListTests<ManagedObjectFactory, DoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveListTests<ManagedObjectFactory, StringFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = SortablePrimitiveListTests<ManagedObjectFactory, DateFactory>._defaultTestSuite().tests.map(suite.addTest)

        _ = OptionalSortablePrimitiveListTests<ManagedObjectFactory, OptionalIntFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveListTests<ManagedObjectFactory, OptionalInt8Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveListTests<ManagedObjectFactory, OptionalInt16Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveListTests<ManagedObjectFactory, OptionalInt32Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveListTests<ManagedObjectFactory, OptionalInt64Factory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveListTests<ManagedObjectFactory, OptionalFloatFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveListTests<ManagedObjectFactory, OptionalDoubleFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveListTests<ManagedObjectFactory, OptionalStringFactory>._defaultTestSuite().tests.map(suite.addTest)
        _ = OptionalSortablePrimitiveListTests<ManagedObjectFactory, OptionalDateFactory>._defaultTestSuite().tests.map(suite.addTest)

        return suite
    }

#if swift(>=4)
    override class var defaultTestSuite: XCTestSuite {
        return _defaultTestSuite()
    }
#else
    override class func defaultTestSuite() -> XCTestSuite {
        return _defaultTestSuite()
    }
#endif
}
