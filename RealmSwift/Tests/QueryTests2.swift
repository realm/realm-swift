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
@testable import RealmSwift

/// This file is generated from a template. Do not edit directly.
class QueryTests_: TestCase {

    private func objects() -> Results<ModernAllTypesObject> {
        realmWithTestPath().objects(ModernAllTypesObject.self)
    }

    private func setAnyRealmValueCol(with value: AnyRealmValue, object: ModernAllTypesObject) {
        let realm = realmWithTestPath()
        try! realm.write {
            object.anyCol = value
        }
    }

    private var circleObject: ModernCircleObject {
        let realm = realmWithTestPath()
        if let object = realm.objects(ModernCircleObject.self).first {
            return object
        } else {
            let object = ModernCircleObject()
            try! realm.write {
                realm.add(object)
            }
            return object
        }
    }

    override func setUp() {
        let realm = realmWithTestPath()
        try! realm.write {
            let object = ModernAllTypesObject()

            object.boolCol = false
            object.intCol = 6
            object.int8Col = Int8(9)
            object.int16Col = Int16(17)
            object.int32Col = Int32(33)
            object.int64Col = Int64(65)
            object.floatCol = Float(6.55444333)
            object.doubleCol = 6.55444333
            object.binaryCol = Data(count: 128)
            object.dateCol = Date(timeIntervalSince1970: 2000000)
            object.decimalCol = Decimal128(234.456)
            object.objectIdCol = ObjectId("61184062c1d8f096a3695045")
            object.intEnumCol = .value2
            object.stringEnumCol = .value2
            object.uuidCol = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
            object.optBoolCol = false
            object.optIntCol = 6
            object.optInt8Col = Int8(9)
            object.optInt16Col = Int16(17)
            object.optInt32Col = Int32(33)
            object.optInt64Col = Int64(65)
            object.optFloatCol = Float(6.55444333)
            object.optDoubleCol = 6.55444333
            object.optBinaryCol = Data(count: 128)
            object.optDateCol = Date(timeIntervalSince1970: 2000000)
            object.optDecimalCol = Decimal128(234.456)
            object.optObjectIdCol = ObjectId("61184062c1d8f096a3695045")
            object.optIntEnumCol = .value2
            object.optStringEnumCol = .value2
            object.optUuidCol = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!

            object.arrayBool.append(objectsIn: [true, true, false])
            object.arrayInt.append(objectsIn: [1, 2, 3])
            object.arrayInt8.append(objectsIn: [1, 2, 3])
            object.arrayInt16.append(objectsIn: [1, 2, 3])
            object.arrayInt32.append(objectsIn: [1, 2, 3])
            object.arrayInt64.append(objectsIn: [1, 2, 3])
            object.arrayFloat.append(objectsIn: [123.456, 234.456, 345.567])
            object.arrayDouble.append(objectsIn: [123.456, 234.456, 345.567])
            object.arrayString.append(objectsIn: ["Foo", "Bar", "Baz"])
            object.arrayBinary.append(objectsIn: [Data(count: 64), Data(count: 128), Data(count: 256)])
            object.arrayDate.append(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 1000000)])
            object.arrayDecimal.append(objectsIn: [Decimal128(123.456), Decimal128(456.789), Decimal128(963.852)])
            object.arrayObjectId.append(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045"), ObjectId("61184062c1d8f096a3695044")])
            object.arrayAny.append(objectsIn: [.objectId(ObjectId("61184062c1d8f096a3695046")), .string("Hello"), .int(123)])

            realm.add(object)
        }
    }

    private func assertQuery<T: Equatable>(predicate: String,
                                           values: [T],
                                           expectedCount: Int,
                                           _ query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>)) {
        let results = objects().query(query)
        XCTAssertEqual(results.count, expectedCount)

        let constructedPredicate = query(Query<ModernAllTypesObject>()).constructPredicate()
        XCTAssertEqual(constructedPredicate.0,
                       predicate)

        for (e1, e2) in zip(constructedPredicate.1, values) {
            if let e1 = e1 as? Object, let e2 = e2 as? Object {
                assertEqual(e1, e2)
            } else {
                XCTAssertEqual(e1 as! T, e2)
            }
        }
    }

    func testEquals() {

        // boolCol
        assertQuery(predicate: "boolCol == %@", values: [false], expectedCount: 1) {
            $0.boolCol == false
        }

        // intCol
        assertQuery(predicate: "intCol == %@", values: [6], expectedCount: 1) {
            $0.intCol == 6
        }

        // int8Col
        assertQuery(predicate: "int8Col == %@", values: [Int8(9)], expectedCount: 1) {
            $0.int8Col == Int8(9)
        }

        // int16Col
        assertQuery(predicate: "int16Col == %@", values: [Int16(17)], expectedCount: 1) {
            $0.int16Col == Int16(17)
        }

        // int32Col
        assertQuery(predicate: "int32Col == %@", values: [Int32(33)], expectedCount: 1) {
            $0.int32Col == Int32(33)
        }

        // int64Col
        assertQuery(predicate: "int64Col == %@", values: [Int64(65)], expectedCount: 1) {
            $0.int64Col == Int64(65)
        }

        // floatCol
        assertQuery(predicate: "floatCol == %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.floatCol == Float(6.55444333)
        }

        // doubleCol
        assertQuery(predicate: "doubleCol == %@", values: [6.55444333], expectedCount: 1) {
            $0.doubleCol == 6.55444333
        }

        // binaryCol
        assertQuery(predicate: "binaryCol == %@", values: [Data(count: 128)], expectedCount: 1) {
            $0.binaryCol == Data(count: 128)
        }

        // dateCol
        assertQuery(predicate: "dateCol == %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.dateCol == Date(timeIntervalSince1970: 2000000)
        }

        // decimalCol
        assertQuery(predicate: "decimalCol == %@", values: [Decimal128(234.456)], expectedCount: 1) {
            $0.decimalCol == Decimal128(234.456)
        }

        // objectIdCol
        assertQuery(predicate: "objectIdCol == %@", values: [ObjectId("61184062c1d8f096a3695045")], expectedCount: 1) {
            $0.objectIdCol == ObjectId("61184062c1d8f096a3695045")
        }

        // intEnumCol
        assertQuery(predicate: "intEnumCol == %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 1) {
            $0.intEnumCol == .value2
        }

        // stringEnumCol
        assertQuery(predicate: "stringEnumCol == %@", values: [ModernStringEnum.value2.rawValue], expectedCount: 1) {
            $0.stringEnumCol == .value2
        }

        // uuidCol
        assertQuery(predicate: "uuidCol == %@", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], expectedCount: 1) {
            $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
    }


    func testEqualsOptional() {
        // optBoolCol

        assertQuery(predicate: "optBoolCol == %@", values: [false], expectedCount: 1) {
            $0.optBoolCol == false
        }
        // optIntCol

        assertQuery(predicate: "optIntCol == %@", values: [6], expectedCount: 1) {
            $0.optIntCol == 6
        }
        // optInt8Col

        assertQuery(predicate: "optInt8Col == %@", values: [Int8(9)], expectedCount: 1) {
            $0.optInt8Col == Int8(9)
        }
        // optInt16Col

        assertQuery(predicate: "optInt16Col == %@", values: [Int16(17)], expectedCount: 1) {
            $0.optInt16Col == Int16(17)
        }
        // optInt32Col

        assertQuery(predicate: "optInt32Col == %@", values: [Int32(33)], expectedCount: 1) {
            $0.optInt32Col == Int32(33)
        }
        // optInt64Col

        assertQuery(predicate: "optInt64Col == %@", values: [Int64(65)], expectedCount: 1) {
            $0.optInt64Col == Int64(65)
        }
        // optFloatCol

        assertQuery(predicate: "optFloatCol == %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.optFloatCol == Float(6.55444333)
        }
        // optDoubleCol

        assertQuery(predicate: "optDoubleCol == %@", values: [6.55444333], expectedCount: 1) {
            $0.optDoubleCol == 6.55444333
        }
        // optBinaryCol

        assertQuery(predicate: "optBinaryCol == %@", values: [Data(count: 128)], expectedCount: 1) {
            $0.optBinaryCol == Data(count: 128)
        }
        // optDateCol

        assertQuery(predicate: "optDateCol == %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.optDateCol == Date(timeIntervalSince1970: 2000000)
        }
        // optDecimalCol

        assertQuery(predicate: "optDecimalCol == %@", values: [Decimal128(234.456)], expectedCount: 1) {
            $0.optDecimalCol == Decimal128(234.456)
        }
        // optObjectIdCol

        assertQuery(predicate: "optObjectIdCol == %@", values: [ObjectId("61184062c1d8f096a3695045")], expectedCount: 1) {
            $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        // optIntEnumCol

        assertQuery(predicate: "optIntEnumCol == %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 1) {
            $0.optIntEnumCol == .value2
        }
        // optStringEnumCol

        assertQuery(predicate: "optStringEnumCol == %@", values: [ModernStringEnum.value2.rawValue], expectedCount: 1) {
            $0.optStringEnumCol == .value2
        }
        // optUuidCol

        assertQuery(predicate: "optUuidCol == %@", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], expectedCount: 1) {
            $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }

        // Test for `nil`

        // optBoolCol
        assertQuery(predicate: "optBoolCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optBoolCol == nil
        }

        // optIntCol
        assertQuery(predicate: "optIntCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optIntCol == nil
        }

        // optInt8Col
        assertQuery(predicate: "optInt8Col == %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt8Col == nil
        }

        // optInt16Col
        assertQuery(predicate: "optInt16Col == %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt16Col == nil
        }

        // optInt32Col
        assertQuery(predicate: "optInt32Col == %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt32Col == nil
        }

        // optInt64Col
        assertQuery(predicate: "optInt64Col == %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt64Col == nil
        }

        // optFloatCol
        assertQuery(predicate: "optFloatCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optFloatCol == nil
        }

        // optDoubleCol
        assertQuery(predicate: "optDoubleCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optDoubleCol == nil
        }

        // optBinaryCol
        assertQuery(predicate: "optBinaryCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optBinaryCol == nil
        }

        // optDateCol
        assertQuery(predicate: "optDateCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optDateCol == nil
        }

        // optDecimalCol
        assertQuery(predicate: "optDecimalCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optDecimalCol == nil
        }

        // optObjectIdCol
        assertQuery(predicate: "optObjectIdCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optObjectIdCol == nil
        }

        // optIntEnumCol
        assertQuery(predicate: "optIntEnumCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optIntEnumCol == nil
        }

        // optStringEnumCol
        assertQuery(predicate: "optStringEnumCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optStringEnumCol == nil
        }

        // optUuidCol
        assertQuery(predicate: "optUuidCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optUuidCol == nil
        }
    }

    func testEqualAnyRealmValue() {

        setAnyRealmValueCol(with: AnyRealmValue.none, object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [NSNull()], expectedCount: 1) {
            $0.anyCol == .none
        }

        setAnyRealmValueCol(with: AnyRealmValue.int(123), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [123], expectedCount: 1) {
            $0.anyCol == .int(123)
        }

        setAnyRealmValueCol(with: AnyRealmValue.bool(true), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [true], expectedCount: 1) {
            $0.anyCol == .bool(true)
        }

        setAnyRealmValueCol(with: AnyRealmValue.float(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [Float(123.456)], expectedCount: 1) {
            $0.anyCol == .float(123.456)
        }

        setAnyRealmValueCol(with: AnyRealmValue.double(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [123.456], expectedCount: 1) {
            $0.anyCol == .double(123.456)
        }

        setAnyRealmValueCol(with: AnyRealmValue.string("FooBar"), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: ["FooBar"], expectedCount: 1) {
            $0.anyCol == .string("FooBar")
        }

        setAnyRealmValueCol(with: AnyRealmValue.data(Data(count: 64)), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [Data(count: 64)], expectedCount: 1) {
            $0.anyCol == .data(Data(count: 64))
        }

        setAnyRealmValueCol(with: AnyRealmValue.date(Date(timeIntervalSince1970: 1000000)), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.anyCol == .date(Date(timeIntervalSince1970: 1000000))
        }

        setAnyRealmValueCol(with: AnyRealmValue.object(circleObject), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [circleObject], expectedCount: 1) {
            $0.anyCol == .object(circleObject)
        }

        setAnyRealmValueCol(with: AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.anyCol == .objectId(ObjectId("61184062c1d8f096a3695046"))
        }

        setAnyRealmValueCol(with: AnyRealmValue.decimal128(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.anyCol == .decimal128(123.456)
        }

        setAnyRealmValueCol(with: AnyRealmValue.uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), object: objects()[0])
        assertQuery(predicate: "anyCol == %@", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.anyCol == .uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
    }

    func testEqualObject() {
        let nestedObject = ModernAllTypesObject()
        let object = objects().first!
        let realm = realmWithTestPath()
        try! realm.write {
            object.objectCol = nestedObject
        }
        assertQuery(predicate: "objectCol == %@", values: [nestedObject], expectedCount: 1) {
            $0.objectCol == nestedObject
        }
    }

    func testEqualEmbeddedObject() {
        let object = ModernEmbeddedParentObject()
        let nestedObject = ModernEmbeddedTreeObject1()
        nestedObject.value = 123
        object.object = nestedObject
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(object)
        }

        let result1 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object == nestedObject
        }
        XCTAssertEqual(result1.count, 1)

        let nestedObject2 = ModernEmbeddedTreeObject1()
        nestedObject2.value = 123
        let result2 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object == nestedObject2
        }
        XCTAssertEqual(result2.count, 0)
    }

    func testNotEquals() {
        // boolCol

        assertQuery(predicate: "boolCol != %@", values: [false], expectedCount: 0) {
            $0.boolCol != false
        }
        // intCol

        assertQuery(predicate: "intCol != %@", values: [6], expectedCount: 0) {
            $0.intCol != 6
        }
        // int8Col

        assertQuery(predicate: "int8Col != %@", values: [Int8(9)], expectedCount: 0) {
            $0.int8Col != Int8(9)
        }
        // int16Col

        assertQuery(predicate: "int16Col != %@", values: [Int16(17)], expectedCount: 0) {
            $0.int16Col != Int16(17)
        }
        // int32Col

        assertQuery(predicate: "int32Col != %@", values: [Int32(33)], expectedCount: 0) {
            $0.int32Col != Int32(33)
        }
        // int64Col

        assertQuery(predicate: "int64Col != %@", values: [Int64(65)], expectedCount: 0) {
            $0.int64Col != Int64(65)
        }
        // floatCol

        assertQuery(predicate: "floatCol != %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.floatCol != Float(6.55444333)
        }
        // doubleCol

        assertQuery(predicate: "doubleCol != %@", values: [6.55444333], expectedCount: 0) {
            $0.doubleCol != 6.55444333
        }
        // binaryCol

        assertQuery(predicate: "binaryCol != %@", values: [Data(count: 128)], expectedCount: 0) {
            $0.binaryCol != Data(count: 128)
        }
        // dateCol

        assertQuery(predicate: "dateCol != %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.dateCol != Date(timeIntervalSince1970: 2000000)
        }
        // decimalCol

        assertQuery(predicate: "decimalCol != %@", values: [Decimal128(234.456)], expectedCount: 0) {
            $0.decimalCol != Decimal128(234.456)
        }
        // objectIdCol

        assertQuery(predicate: "objectIdCol != %@", values: [ObjectId("61184062c1d8f096a3695045")], expectedCount: 0) {
            $0.objectIdCol != ObjectId("61184062c1d8f096a3695045")
        }
        // intEnumCol

        assertQuery(predicate: "intEnumCol != %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 0) {
            $0.intEnumCol != .value2
        }
        // stringEnumCol

        assertQuery(predicate: "stringEnumCol != %@", values: [ModernStringEnum.value2.rawValue], expectedCount: 0) {
            $0.stringEnumCol != .value2
        }
        // uuidCol

        assertQuery(predicate: "uuidCol != %@", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], expectedCount: 0) {
            $0.uuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
    }

    func testNotEqualsOptional() {
        // optBoolCol

        assertQuery(predicate: "optBoolCol != %@", values: [false], expectedCount: 0) {
            $0.optBoolCol != false
        }
        // optIntCol

        assertQuery(predicate: "optIntCol != %@", values: [6], expectedCount: 0) {
            $0.optIntCol != 6
        }
        // optInt8Col

        assertQuery(predicate: "optInt8Col != %@", values: [Int8(9)], expectedCount: 0) {
            $0.optInt8Col != Int8(9)
        }
        // optInt16Col

        assertQuery(predicate: "optInt16Col != %@", values: [Int16(17)], expectedCount: 0) {
            $0.optInt16Col != Int16(17)
        }
        // optInt32Col

        assertQuery(predicate: "optInt32Col != %@", values: [Int32(33)], expectedCount: 0) {
            $0.optInt32Col != Int32(33)
        }
        // optInt64Col

        assertQuery(predicate: "optInt64Col != %@", values: [Int64(65)], expectedCount: 0) {
            $0.optInt64Col != Int64(65)
        }
        // optFloatCol

        assertQuery(predicate: "optFloatCol != %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.optFloatCol != Float(6.55444333)
        }
        // optDoubleCol

        assertQuery(predicate: "optDoubleCol != %@", values: [6.55444333], expectedCount: 0) {
            $0.optDoubleCol != 6.55444333
        }
        // optBinaryCol

        assertQuery(predicate: "optBinaryCol != %@", values: [Data(count: 128)], expectedCount: 0) {
            $0.optBinaryCol != Data(count: 128)
        }
        // optDateCol

        assertQuery(predicate: "optDateCol != %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.optDateCol != Date(timeIntervalSince1970: 2000000)
        }
        // optDecimalCol

        assertQuery(predicate: "optDecimalCol != %@", values: [Decimal128(234.456)], expectedCount: 0) {
            $0.optDecimalCol != Decimal128(234.456)
        }
        // optObjectIdCol

        assertQuery(predicate: "optObjectIdCol != %@", values: [ObjectId("61184062c1d8f096a3695045")], expectedCount: 0) {
            $0.optObjectIdCol != ObjectId("61184062c1d8f096a3695045")
        }
        // optIntEnumCol

        assertQuery(predicate: "optIntEnumCol != %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 0) {
            $0.optIntEnumCol != .value2
        }
        // optStringEnumCol

        assertQuery(predicate: "optStringEnumCol != %@", values: [ModernStringEnum.value2.rawValue], expectedCount: 0) {
            $0.optStringEnumCol != .value2
        }
        // optUuidCol

        assertQuery(predicate: "optUuidCol != %@", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], expectedCount: 0) {
            $0.optUuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }

        // Test for `nil`

        // optBoolCol
        assertQuery(predicate: "optBoolCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optBoolCol != nil
        }

        // optIntCol
        assertQuery(predicate: "optIntCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optIntCol != nil
        }

        // optInt8Col
        assertQuery(predicate: "optInt8Col != %@", values: [NSNull()], expectedCount: 1) {
            $0.optInt8Col != nil
        }

        // optInt16Col
        assertQuery(predicate: "optInt16Col != %@", values: [NSNull()], expectedCount: 1) {
            $0.optInt16Col != nil
        }

        // optInt32Col
        assertQuery(predicate: "optInt32Col != %@", values: [NSNull()], expectedCount: 1) {
            $0.optInt32Col != nil
        }

        // optInt64Col
        assertQuery(predicate: "optInt64Col != %@", values: [NSNull()], expectedCount: 1) {
            $0.optInt64Col != nil
        }

        // optFloatCol
        assertQuery(predicate: "optFloatCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optFloatCol != nil
        }

        // optDoubleCol
        assertQuery(predicate: "optDoubleCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optDoubleCol != nil
        }

        // optBinaryCol
        assertQuery(predicate: "optBinaryCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optBinaryCol != nil
        }

        // optDateCol
        assertQuery(predicate: "optDateCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optDateCol != nil
        }

        // optDecimalCol
        assertQuery(predicate: "optDecimalCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optDecimalCol != nil
        }

        // optObjectIdCol
        assertQuery(predicate: "optObjectIdCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optObjectIdCol != nil
        }

        // optIntEnumCol
        assertQuery(predicate: "optIntEnumCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optIntEnumCol != nil
        }

        // optStringEnumCol
        assertQuery(predicate: "optStringEnumCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optStringEnumCol != nil
        }

        // optUuidCol
        assertQuery(predicate: "optUuidCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optUuidCol != nil
        }
    }

    func testNotEqualAnyRealmValue() {
        setAnyRealmValueCol(with: AnyRealmValue.none, object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [NSNull()], expectedCount: 0) {
            $0.anyCol != .none
        }
        setAnyRealmValueCol(with: AnyRealmValue.int(123), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [123], expectedCount: 0) {
            $0.anyCol != .int(123)
        }
        setAnyRealmValueCol(with: AnyRealmValue.bool(true), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [true], expectedCount: 0) {
            $0.anyCol != .bool(true)
        }
        setAnyRealmValueCol(with: AnyRealmValue.float(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [Float(123.456)], expectedCount: 0) {
            $0.anyCol != .float(123.456)
        }
        setAnyRealmValueCol(with: AnyRealmValue.double(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [123.456], expectedCount: 0) {
            $0.anyCol != .double(123.456)
        }
        setAnyRealmValueCol(with: AnyRealmValue.string("FooBar"), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: ["FooBar"], expectedCount: 0) {
            $0.anyCol != .string("FooBar")
        }
        setAnyRealmValueCol(with: AnyRealmValue.data(Data(count: 64)), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [Data(count: 64)], expectedCount: 0) {
            $0.anyCol != .data(Data(count: 64))
        }
        setAnyRealmValueCol(with: AnyRealmValue.date(Date(timeIntervalSince1970: 1000000)), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.anyCol != .date(Date(timeIntervalSince1970: 1000000))
        }
        setAnyRealmValueCol(with: AnyRealmValue.object(circleObject), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [circleObject], expectedCount: 0) {
            $0.anyCol != .object(circleObject)
        }
        setAnyRealmValueCol(with: AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 0) {
            $0.anyCol != .objectId(ObjectId("61184062c1d8f096a3695046"))
        }
        setAnyRealmValueCol(with: AnyRealmValue.decimal128(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [Decimal128(123.456)], expectedCount: 0) {
            $0.anyCol != .decimal128(123.456)
        }
        setAnyRealmValueCol(with: AnyRealmValue.uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!), object: objects()[0])
        assertQuery(predicate: "anyCol != %@", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 0) {
            $0.anyCol != .uuid(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
    }

    func testNotEqualObject() {
        let nestedObject = ModernAllTypesObject()
        let object = objects().first!
        let realm = realmWithTestPath()
        try! realm.write {
            object.objectCol = nestedObject
        }
        // Count will be one because nestedObject.objectCol will be nil
        assertQuery(predicate: "objectCol != %@", values: [nestedObject], expectedCount: 1) {
            $0.objectCol != nestedObject
        }
    }

    func testNotEqualEmbeddedObject() {
        let object = ModernEmbeddedParentObject()
        let nestedObject = ModernEmbeddedTreeObject1()
        nestedObject.value = 123
        object.object = nestedObject
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(object)
        }

        let result1 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object != nestedObject
        }
        XCTAssertEqual(result1.count, 0)

        let nestedObject2 = ModernEmbeddedTreeObject1()
        nestedObject2.value = 123
        let result2 = realm.objects(ModernEmbeddedParentObject.self).query {
            $0.object != nestedObject2
        }
        XCTAssertEqual(result2.count, 1)
    }

    func testGreaterThan() {
        // intCol
        assertQuery(predicate: "intCol > %@", values: [6], expectedCount: 0) {
            $0.intCol > 6
        }
        assertQuery(predicate: "intCol >= %@", values: [6], expectedCount: 1) {
            $0.intCol >= 6
        }
        // int8Col
        assertQuery(predicate: "int8Col > %@", values: [Int8(9)], expectedCount: 0) {
            $0.int8Col > Int8(9)
        }
        assertQuery(predicate: "int8Col >= %@", values: [Int8(9)], expectedCount: 1) {
            $0.int8Col >= Int8(9)
        }
        // int16Col
        assertQuery(predicate: "int16Col > %@", values: [Int16(17)], expectedCount: 0) {
            $0.int16Col > Int16(17)
        }
        assertQuery(predicate: "int16Col >= %@", values: [Int16(17)], expectedCount: 1) {
            $0.int16Col >= Int16(17)
        }
        // int32Col
        assertQuery(predicate: "int32Col > %@", values: [Int32(33)], expectedCount: 0) {
            $0.int32Col > Int32(33)
        }
        assertQuery(predicate: "int32Col >= %@", values: [Int32(33)], expectedCount: 1) {
            $0.int32Col >= Int32(33)
        }
        // int64Col
        assertQuery(predicate: "int64Col > %@", values: [Int64(65)], expectedCount: 0) {
            $0.int64Col > Int64(65)
        }
        assertQuery(predicate: "int64Col >= %@", values: [Int64(65)], expectedCount: 1) {
            $0.int64Col >= Int64(65)
        }
        // floatCol
        assertQuery(predicate: "floatCol > %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.floatCol > Float(6.55444333)
        }
        assertQuery(predicate: "floatCol >= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.floatCol >= Float(6.55444333)
        }
        // doubleCol
        assertQuery(predicate: "doubleCol > %@", values: [6.55444333], expectedCount: 0) {
            $0.doubleCol > 6.55444333
        }
        assertQuery(predicate: "doubleCol >= %@", values: [6.55444333], expectedCount: 1) {
            $0.doubleCol >= 6.55444333
        }
        // dateCol
        assertQuery(predicate: "dateCol > %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.dateCol > Date(timeIntervalSince1970: 2000000)
        }
        assertQuery(predicate: "dateCol >= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.dateCol >= Date(timeIntervalSince1970: 2000000)
        }
        // decimalCol
        assertQuery(predicate: "decimalCol > %@", values: [Decimal128(234.456)], expectedCount: 0) {
            $0.decimalCol > Decimal128(234.456)
        }
        assertQuery(predicate: "decimalCol >= %@", values: [Decimal128(234.456)], expectedCount: 1) {
            $0.decimalCol >= Decimal128(234.456)
        }
        // intEnumCol
        assertQuery(predicate: "intEnumCol > %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 0) {
            $0.intEnumCol > .value2
        }
        assertQuery(predicate: "intEnumCol >= %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 1) {
            $0.intEnumCol >= .value2
        }
    }

    func testGreaterThanOptional() {
        // optIntCol
        assertQuery(predicate: "optIntCol > %@", values: [6], expectedCount: 0) {
            $0.optIntCol > 6
        }
        assertQuery(predicate: "optIntCol >= %@", values: [6], expectedCount: 1) {
            $0.optIntCol >= 6
        }
        // optInt8Col
        assertQuery(predicate: "optInt8Col > %@", values: [Int8(9)], expectedCount: 0) {
            $0.optInt8Col > Int8(9)
        }
        assertQuery(predicate: "optInt8Col >= %@", values: [Int8(9)], expectedCount: 1) {
            $0.optInt8Col >= Int8(9)
        }
        // optInt16Col
        assertQuery(predicate: "optInt16Col > %@", values: [Int16(17)], expectedCount: 0) {
            $0.optInt16Col > Int16(17)
        }
        assertQuery(predicate: "optInt16Col >= %@", values: [Int16(17)], expectedCount: 1) {
            $0.optInt16Col >= Int16(17)
        }
        // optInt32Col
        assertQuery(predicate: "optInt32Col > %@", values: [Int32(33)], expectedCount: 0) {
            $0.optInt32Col > Int32(33)
        }
        assertQuery(predicate: "optInt32Col >= %@", values: [Int32(33)], expectedCount: 1) {
            $0.optInt32Col >= Int32(33)
        }
        // optInt64Col
        assertQuery(predicate: "optInt64Col > %@", values: [Int64(65)], expectedCount: 0) {
            $0.optInt64Col > Int64(65)
        }
        assertQuery(predicate: "optInt64Col >= %@", values: [Int64(65)], expectedCount: 1) {
            $0.optInt64Col >= Int64(65)
        }
        // optFloatCol
        assertQuery(predicate: "optFloatCol > %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.optFloatCol > Float(6.55444333)
        }
        assertQuery(predicate: "optFloatCol >= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.optFloatCol >= Float(6.55444333)
        }
        // optDoubleCol
        assertQuery(predicate: "optDoubleCol > %@", values: [6.55444333], expectedCount: 0) {
            $0.optDoubleCol > 6.55444333
        }
        assertQuery(predicate: "optDoubleCol >= %@", values: [6.55444333], expectedCount: 1) {
            $0.optDoubleCol >= 6.55444333
        }
        // optDateCol
        assertQuery(predicate: "optDateCol > %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.optDateCol > Date(timeIntervalSince1970: 2000000)
        }
        assertQuery(predicate: "optDateCol >= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.optDateCol >= Date(timeIntervalSince1970: 2000000)
        }
        // optDecimalCol
        assertQuery(predicate: "optDecimalCol > %@", values: [Decimal128(234.456)], expectedCount: 0) {
            $0.optDecimalCol > Decimal128(234.456)
        }
        assertQuery(predicate: "optDecimalCol >= %@", values: [Decimal128(234.456)], expectedCount: 1) {
            $0.optDecimalCol >= Decimal128(234.456)
        }
        // optIntEnumCol
        assertQuery(predicate: "optIntEnumCol > %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 0) {
            $0.optIntEnumCol > .value2
        }
        assertQuery(predicate: "optIntEnumCol >= %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 1) {
            $0.optIntEnumCol >= .value2
        }

        // Test for `nil`
        // optIntCol
        assertQuery(predicate: "optIntCol > %@", values: [NSNull()], expectedCount: 0) {
            $0.optIntCol > nil
        }
        assertQuery(predicate: "optIntCol >= %@", values: [NSNull()], expectedCount: 0) {
            $0.optIntCol >= nil
        }
        // optInt8Col
        assertQuery(predicate: "optInt8Col > %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt8Col > nil
        }
        assertQuery(predicate: "optInt8Col >= %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt8Col >= nil
        }
        // optInt16Col
        assertQuery(predicate: "optInt16Col > %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt16Col > nil
        }
        assertQuery(predicate: "optInt16Col >= %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt16Col >= nil
        }
        // optInt32Col
        assertQuery(predicate: "optInt32Col > %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt32Col > nil
        }
        assertQuery(predicate: "optInt32Col >= %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt32Col >= nil
        }
        // optInt64Col
        assertQuery(predicate: "optInt64Col > %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt64Col > nil
        }
        assertQuery(predicate: "optInt64Col >= %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt64Col >= nil
        }
        // optFloatCol
        assertQuery(predicate: "optFloatCol > %@", values: [NSNull()], expectedCount: 0) {
            $0.optFloatCol > nil
        }
        assertQuery(predicate: "optFloatCol >= %@", values: [NSNull()], expectedCount: 0) {
            $0.optFloatCol >= nil
        }
        // optDoubleCol
        assertQuery(predicate: "optDoubleCol > %@", values: [NSNull()], expectedCount: 0) {
            $0.optDoubleCol > nil
        }
        assertQuery(predicate: "optDoubleCol >= %@", values: [NSNull()], expectedCount: 0) {
            $0.optDoubleCol >= nil
        }
        // optDateCol
        assertQuery(predicate: "optDateCol > %@", values: [NSNull()], expectedCount: 0) {
            $0.optDateCol > nil
        }
        assertQuery(predicate: "optDateCol >= %@", values: [NSNull()], expectedCount: 0) {
            $0.optDateCol >= nil
        }
        // optDecimalCol
        assertQuery(predicate: "optDecimalCol > %@", values: [NSNull()], expectedCount: 0) {
            $0.optDecimalCol > nil
        }
        assertQuery(predicate: "optDecimalCol >= %@", values: [NSNull()], expectedCount: 0) {
            $0.optDecimalCol >= nil
        }
        // optIntEnumCol
        assertQuery(predicate: "optIntEnumCol > %@", values: [NSNull()], expectedCount: 0) {
            $0.optIntEnumCol > nil
        }
        assertQuery(predicate: "optIntEnumCol >= %@", values: [NSNull()], expectedCount: 0) {
            $0.optIntEnumCol >= nil
        }
    }

    func testGreaterThanAnyRealmValue() {
        setAnyRealmValueCol(with: AnyRealmValue.int(123), object: objects()[0])
        assertQuery(predicate: "anyCol > %@", values: [123], expectedCount: 0) {
            $0.anyCol > .int(123)
        }
        assertQuery(predicate: "anyCol >= %@", values: [123], expectedCount: 1) {
            $0.anyCol >= .int(123)
        }
        setAnyRealmValueCol(with: AnyRealmValue.float(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol > %@", values: [Float(123.456)], expectedCount: 0) {
            $0.anyCol > .float(123.456)
        }
        assertQuery(predicate: "anyCol >= %@", values: [Float(123.456)], expectedCount: 1) {
            $0.anyCol >= .float(123.456)
        }
        setAnyRealmValueCol(with: AnyRealmValue.double(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol > %@", values: [123.456], expectedCount: 0) {
            $0.anyCol > .double(123.456)
        }
        assertQuery(predicate: "anyCol >= %@", values: [123.456], expectedCount: 1) {
            $0.anyCol >= .double(123.456)
        }
        setAnyRealmValueCol(with: AnyRealmValue.date(Date(timeIntervalSince1970: 1000000)), object: objects()[0])
        assertQuery(predicate: "anyCol > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.anyCol > .date(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(predicate: "anyCol >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.anyCol >= .date(Date(timeIntervalSince1970: 1000000))
        }
        setAnyRealmValueCol(with: AnyRealmValue.decimal128(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol > %@", values: [Decimal128(123.456)], expectedCount: 0) {
            $0.anyCol > .decimal128(123.456)
        }
        assertQuery(predicate: "anyCol >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.anyCol >= .decimal128(123.456)
        }
    }

    func testLessThan() {
        // intCol
        assertQuery(predicate: "intCol < %@", values: [6], expectedCount: 0) {
            $0.intCol < 6
        }
        assertQuery(predicate: "intCol <= %@", values: [6], expectedCount: 1) {
            $0.intCol <= 6
        }
        // int8Col
        assertQuery(predicate: "int8Col < %@", values: [Int8(9)], expectedCount: 0) {
            $0.int8Col < Int8(9)
        }
        assertQuery(predicate: "int8Col <= %@", values: [Int8(9)], expectedCount: 1) {
            $0.int8Col <= Int8(9)
        }
        // int16Col
        assertQuery(predicate: "int16Col < %@", values: [Int16(17)], expectedCount: 0) {
            $0.int16Col < Int16(17)
        }
        assertQuery(predicate: "int16Col <= %@", values: [Int16(17)], expectedCount: 1) {
            $0.int16Col <= Int16(17)
        }
        // int32Col
        assertQuery(predicate: "int32Col < %@", values: [Int32(33)], expectedCount: 0) {
            $0.int32Col < Int32(33)
        }
        assertQuery(predicate: "int32Col <= %@", values: [Int32(33)], expectedCount: 1) {
            $0.int32Col <= Int32(33)
        }
        // int64Col
        assertQuery(predicate: "int64Col < %@", values: [Int64(65)], expectedCount: 0) {
            $0.int64Col < Int64(65)
        }
        assertQuery(predicate: "int64Col <= %@", values: [Int64(65)], expectedCount: 1) {
            $0.int64Col <= Int64(65)
        }
        // floatCol
        assertQuery(predicate: "floatCol < %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.floatCol < Float(6.55444333)
        }
        assertQuery(predicate: "floatCol <= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.floatCol <= Float(6.55444333)
        }
        // doubleCol
        assertQuery(predicate: "doubleCol < %@", values: [6.55444333], expectedCount: 0) {
            $0.doubleCol < 6.55444333
        }
        assertQuery(predicate: "doubleCol <= %@", values: [6.55444333], expectedCount: 1) {
            $0.doubleCol <= 6.55444333
        }
        // dateCol
        assertQuery(predicate: "dateCol < %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.dateCol < Date(timeIntervalSince1970: 2000000)
        }
        assertQuery(predicate: "dateCol <= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.dateCol <= Date(timeIntervalSince1970: 2000000)
        }
        // decimalCol
        assertQuery(predicate: "decimalCol < %@", values: [Decimal128(234.456)], expectedCount: 0) {
            $0.decimalCol < Decimal128(234.456)
        }
        assertQuery(predicate: "decimalCol <= %@", values: [Decimal128(234.456)], expectedCount: 1) {
            $0.decimalCol <= Decimal128(234.456)
        }
        // intEnumCol
        assertQuery(predicate: "intEnumCol < %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 0) {
            $0.intEnumCol < .value2
        }
        assertQuery(predicate: "intEnumCol <= %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 1) {
            $0.intEnumCol <= .value2
        }
    }

    func testLessThanOptional() {
        // optIntCol
        assertQuery(predicate: "optIntCol < %@", values: [6], expectedCount: 0) {
            $0.optIntCol < 6
        }
        assertQuery(predicate: "optIntCol <= %@", values: [6], expectedCount: 1) {
            $0.optIntCol <= 6
        }
        // optInt8Col
        assertQuery(predicate: "optInt8Col < %@", values: [Int8(9)], expectedCount: 0) {
            $0.optInt8Col < Int8(9)
        }
        assertQuery(predicate: "optInt8Col <= %@", values: [Int8(9)], expectedCount: 1) {
            $0.optInt8Col <= Int8(9)
        }
        // optInt16Col
        assertQuery(predicate: "optInt16Col < %@", values: [Int16(17)], expectedCount: 0) {
            $0.optInt16Col < Int16(17)
        }
        assertQuery(predicate: "optInt16Col <= %@", values: [Int16(17)], expectedCount: 1) {
            $0.optInt16Col <= Int16(17)
        }
        // optInt32Col
        assertQuery(predicate: "optInt32Col < %@", values: [Int32(33)], expectedCount: 0) {
            $0.optInt32Col < Int32(33)
        }
        assertQuery(predicate: "optInt32Col <= %@", values: [Int32(33)], expectedCount: 1) {
            $0.optInt32Col <= Int32(33)
        }
        // optInt64Col
        assertQuery(predicate: "optInt64Col < %@", values: [Int64(65)], expectedCount: 0) {
            $0.optInt64Col < Int64(65)
        }
        assertQuery(predicate: "optInt64Col <= %@", values: [Int64(65)], expectedCount: 1) {
            $0.optInt64Col <= Int64(65)
        }
        // optFloatCol
        assertQuery(predicate: "optFloatCol < %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.optFloatCol < Float(6.55444333)
        }
        assertQuery(predicate: "optFloatCol <= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.optFloatCol <= Float(6.55444333)
        }
        // optDoubleCol
        assertQuery(predicate: "optDoubleCol < %@", values: [6.55444333], expectedCount: 0) {
            $0.optDoubleCol < 6.55444333
        }
        assertQuery(predicate: "optDoubleCol <= %@", values: [6.55444333], expectedCount: 1) {
            $0.optDoubleCol <= 6.55444333
        }
        // optDateCol
        assertQuery(predicate: "optDateCol < %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.optDateCol < Date(timeIntervalSince1970: 2000000)
        }
        assertQuery(predicate: "optDateCol <= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.optDateCol <= Date(timeIntervalSince1970: 2000000)
        }
        // optDecimalCol
        assertQuery(predicate: "optDecimalCol < %@", values: [Decimal128(234.456)], expectedCount: 0) {
            $0.optDecimalCol < Decimal128(234.456)
        }
        assertQuery(predicate: "optDecimalCol <= %@", values: [Decimal128(234.456)], expectedCount: 1) {
            $0.optDecimalCol <= Decimal128(234.456)
        }
        // optIntEnumCol
        assertQuery(predicate: "optIntEnumCol < %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 0) {
            $0.optIntEnumCol < .value2
        }
        assertQuery(predicate: "optIntEnumCol <= %@", values: [ModernIntEnum.value2.rawValue], expectedCount: 1) {
            $0.optIntEnumCol <= .value2
        }

        // Test for `nil`
        // optIntCol
        assertQuery(predicate: "optIntCol < %@", values: [NSNull()], expectedCount: 0) {
            $0.optIntCol < nil
        }
        assertQuery(predicate: "optIntCol <= %@", values: [NSNull()], expectedCount: 0) {
            $0.optIntCol <= nil
        }
        // optInt8Col
        assertQuery(predicate: "optInt8Col < %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt8Col < nil
        }
        assertQuery(predicate: "optInt8Col <= %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt8Col <= nil
        }
        // optInt16Col
        assertQuery(predicate: "optInt16Col < %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt16Col < nil
        }
        assertQuery(predicate: "optInt16Col <= %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt16Col <= nil
        }
        // optInt32Col
        assertQuery(predicate: "optInt32Col < %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt32Col < nil
        }
        assertQuery(predicate: "optInt32Col <= %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt32Col <= nil
        }
        // optInt64Col
        assertQuery(predicate: "optInt64Col < %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt64Col < nil
        }
        assertQuery(predicate: "optInt64Col <= %@", values: [NSNull()], expectedCount: 0) {
            $0.optInt64Col <= nil
        }
        // optFloatCol
        assertQuery(predicate: "optFloatCol < %@", values: [NSNull()], expectedCount: 0) {
            $0.optFloatCol < nil
        }
        assertQuery(predicate: "optFloatCol <= %@", values: [NSNull()], expectedCount: 0) {
            $0.optFloatCol <= nil
        }
        // optDoubleCol
        assertQuery(predicate: "optDoubleCol < %@", values: [NSNull()], expectedCount: 0) {
            $0.optDoubleCol < nil
        }
        assertQuery(predicate: "optDoubleCol <= %@", values: [NSNull()], expectedCount: 0) {
            $0.optDoubleCol <= nil
        }
        // optDateCol
        assertQuery(predicate: "optDateCol < %@", values: [NSNull()], expectedCount: 0) {
            $0.optDateCol < nil
        }
        assertQuery(predicate: "optDateCol <= %@", values: [NSNull()], expectedCount: 0) {
            $0.optDateCol <= nil
        }
        // optDecimalCol
        assertQuery(predicate: "optDecimalCol < %@", values: [NSNull()], expectedCount: 0) {
            $0.optDecimalCol < nil
        }
        assertQuery(predicate: "optDecimalCol <= %@", values: [NSNull()], expectedCount: 0) {
            $0.optDecimalCol <= nil
        }
        // optIntEnumCol
        assertQuery(predicate: "optIntEnumCol < %@", values: [NSNull()], expectedCount: 0) {
            $0.optIntEnumCol < nil
        }
        assertQuery(predicate: "optIntEnumCol <= %@", values: [NSNull()], expectedCount: 0) {
            $0.optIntEnumCol <= nil
        }
    }

    func testLessThanAnyRealmValue() {
        setAnyRealmValueCol(with: AnyRealmValue.int(123), object: objects()[0])
        assertQuery(predicate: "anyCol < %@", values: [123], expectedCount: 0) {
            $0.anyCol < .int(123)
        }
        assertQuery(predicate: "anyCol <= %@", values: [123], expectedCount: 1) {
            $0.anyCol <= .int(123)
        }
        setAnyRealmValueCol(with: AnyRealmValue.float(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol < %@", values: [Float(123.456)], expectedCount: 0) {
            $0.anyCol < .float(123.456)
        }
        assertQuery(predicate: "anyCol <= %@", values: [Float(123.456)], expectedCount: 1) {
            $0.anyCol <= .float(123.456)
        }
        setAnyRealmValueCol(with: AnyRealmValue.double(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol < %@", values: [123.456], expectedCount: 0) {
            $0.anyCol < .double(123.456)
        }
        assertQuery(predicate: "anyCol <= %@", values: [123.456], expectedCount: 1) {
            $0.anyCol <= .double(123.456)
        }
        setAnyRealmValueCol(with: AnyRealmValue.date(Date(timeIntervalSince1970: 1000000)), object: objects()[0])
        assertQuery(predicate: "anyCol < %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.anyCol < .date(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(predicate: "anyCol <= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.anyCol <= .date(Date(timeIntervalSince1970: 1000000))
        }
        setAnyRealmValueCol(with: AnyRealmValue.decimal128(123.456), object: objects()[0])
        assertQuery(predicate: "anyCol < %@", values: [Decimal128(123.456)], expectedCount: 0) {
            $0.anyCol < .decimal128(123.456)
        }
        assertQuery(predicate: "anyCol <= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.anyCol <= .decimal128(123.456)
        }
    }

    func testNumericContains() {
        assertQuery(predicate: "intCol >= %@ && intCol < %@", values: [5, 7], expectedCount: 1) {
            $0.intCol.contains(5..<7)
        }

        assertQuery(predicate: "intCol >= %@ && intCol < %@", values: [5, 6], expectedCount: 0) {
            $0.intCol.contains(5..<6)
        }

        assertQuery(predicate: "intCol BETWEEN {%@, %@}", values: [5, 7], expectedCount: 1) {
            $0.intCol.contains(5...7)
        }

        assertQuery(predicate: "intCol BETWEEN {%@, %@}", values: [5, 6], expectedCount: 1) {
            $0.intCol.contains(5...6)
        }

        assertQuery(predicate: "int8Col >= %@ && int8Col < %@", values: [Int8(8), Int8(10)], expectedCount: 1) {
            $0.int8Col.contains(Int8(8)..<Int8(10))
        }

        assertQuery(predicate: "int8Col >= %@ && int8Col < %@", values: [Int8(8), Int8(9)], expectedCount: 0) {
            $0.int8Col.contains(Int8(8)..<Int8(9))
        }

        assertQuery(predicate: "int8Col BETWEEN {%@, %@}", values: [Int8(8), Int8(10)], expectedCount: 1) {
            $0.int8Col.contains(Int8(8)...Int8(10))
        }

        assertQuery(predicate: "int8Col BETWEEN {%@, %@}", values: [Int8(8), Int8(9)], expectedCount: 1) {
            $0.int8Col.contains(Int8(8)...Int8(9))
        }

        assertQuery(predicate: "int16Col >= %@ && int16Col < %@", values: [Int16(16), Int16(18)], expectedCount: 1) {
            $0.int16Col.contains(Int16(16)..<Int16(18))
        }

        assertQuery(predicate: "int16Col >= %@ && int16Col < %@", values: [Int16(16), Int16(17)], expectedCount: 0) {
            $0.int16Col.contains(Int16(16)..<Int16(17))
        }

        assertQuery(predicate: "int16Col BETWEEN {%@, %@}", values: [Int16(16), Int16(18)], expectedCount: 1) {
            $0.int16Col.contains(Int16(16)...Int16(18))
        }

        assertQuery(predicate: "int16Col BETWEEN {%@, %@}", values: [Int16(16), Int16(17)], expectedCount: 1) {
            $0.int16Col.contains(Int16(16)...Int16(17))
        }

        assertQuery(predicate: "int32Col >= %@ && int32Col < %@", values: [Int32(32), Int32(34)], expectedCount: 1) {
            $0.int32Col.contains(Int32(32)..<Int32(34))
        }

        assertQuery(predicate: "int32Col >= %@ && int32Col < %@", values: [Int32(32), Int32(33)], expectedCount: 0) {
            $0.int32Col.contains(Int32(32)..<Int32(33))
        }

        assertQuery(predicate: "int32Col BETWEEN {%@, %@}", values: [Int32(32), Int32(34)], expectedCount: 1) {
            $0.int32Col.contains(Int32(32)...Int32(34))
        }

        assertQuery(predicate: "int32Col BETWEEN {%@, %@}", values: [Int32(32), Int32(33)], expectedCount: 1) {
            $0.int32Col.contains(Int32(32)...Int32(33))
        }

        assertQuery(predicate: "int64Col >= %@ && int64Col < %@", values: [Int64(64), Int64(66)], expectedCount: 1) {
            $0.int64Col.contains(Int64(64)..<Int64(66))
        }

        assertQuery(predicate: "int64Col >= %@ && int64Col < %@", values: [Int64(64), Int64(65)], expectedCount: 0) {
            $0.int64Col.contains(Int64(64)..<Int64(65))
        }

        assertQuery(predicate: "int64Col BETWEEN {%@, %@}", values: [Int64(64), Int64(66)], expectedCount: 1) {
            $0.int64Col.contains(Int64(64)...Int64(66))
        }

        assertQuery(predicate: "int64Col BETWEEN {%@, %@}", values: [Int64(64), Int64(65)], expectedCount: 1) {
            $0.int64Col.contains(Int64(64)...Int64(65))
        }

        assertQuery(predicate: "floatCol >= %@ && floatCol < %@", values: [Float(5.55444333), Float(7.55444333)], expectedCount: 1) {
            $0.floatCol.contains(Float(5.55444333)..<Float(7.55444333))
        }

        assertQuery(predicate: "floatCol >= %@ && floatCol < %@", values: [Float(5.55444333), Float(6.55444333)], expectedCount: 0) {
            $0.floatCol.contains(Float(5.55444333)..<Float(6.55444333))
        }

        assertQuery(predicate: "floatCol BETWEEN {%@, %@}", values: [Float(5.55444333), Float(7.55444333)], expectedCount: 1) {
            $0.floatCol.contains(Float(5.55444333)...Float(7.55444333))
        }

        assertQuery(predicate: "floatCol BETWEEN {%@, %@}", values: [Float(5.55444333), Float(6.55444333)], expectedCount: 1) {
            $0.floatCol.contains(Float(5.55444333)...Float(6.55444333))
        }

        assertQuery(predicate: "doubleCol >= %@ && doubleCol < %@", values: [5.55444333, 7.55444333], expectedCount: 1) {
            $0.doubleCol.contains(5.55444333..<7.55444333)
        }

        assertQuery(predicate: "doubleCol >= %@ && doubleCol < %@", values: [5.55444333, 6.55444333], expectedCount: 0) {
            $0.doubleCol.contains(5.55444333..<6.55444333)
        }

        assertQuery(predicate: "doubleCol BETWEEN {%@, %@}", values: [5.55444333, 7.55444333], expectedCount: 1) {
            $0.doubleCol.contains(5.55444333...7.55444333)
        }

        assertQuery(predicate: "doubleCol BETWEEN {%@, %@}", values: [5.55444333, 6.55444333], expectedCount: 1) {
            $0.doubleCol.contains(5.55444333...6.55444333)
        }

        assertQuery(predicate: "dateCol >= %@ && dateCol < %@", values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.dateCol.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "dateCol >= %@ && dateCol < %@", values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.dateCol.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "dateCol BETWEEN {%@, %@}", values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.dateCol.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "dateCol BETWEEN {%@, %@}", values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.dateCol.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "decimalCol >= %@ && decimalCol < %@", values: [Decimal128(123.456), Decimal128(345.456)], expectedCount: 1) {
            $0.decimalCol.contains(Decimal128(123.456)..<Decimal128(345.456))
        }

        assertQuery(predicate: "decimalCol >= %@ && decimalCol < %@", values: [Decimal128(123.456), Decimal128(234.456)], expectedCount: 0) {
            $0.decimalCol.contains(Decimal128(123.456)..<Decimal128(234.456))
        }

        assertQuery(predicate: "decimalCol BETWEEN {%@, %@}", values: [Decimal128(123.456), Decimal128(345.456)], expectedCount: 1) {
            $0.decimalCol.contains(Decimal128(123.456)...Decimal128(345.456))
        }

        assertQuery(predicate: "decimalCol BETWEEN {%@, %@}", values: [Decimal128(123.456), Decimal128(234.456)], expectedCount: 1) {
            $0.decimalCol.contains(Decimal128(123.456)...Decimal128(234.456))
        }

        assertQuery(predicate: "optIntCol >= %@ && optIntCol < %@", values: [5, 7], expectedCount: 1) {
            $0.optIntCol.contains(5..<7)
        }

        assertQuery(predicate: "optIntCol >= %@ && optIntCol < %@", values: [5, 6], expectedCount: 0) {
            $0.optIntCol.contains(5..<6)
        }

        assertQuery(predicate: "optIntCol BETWEEN {%@, %@}", values: [5, 7], expectedCount: 1) {
            $0.optIntCol.contains(5...7)
        }

        assertQuery(predicate: "optIntCol BETWEEN {%@, %@}", values: [5, 6], expectedCount: 1) {
            $0.optIntCol.contains(5...6)
        }

        assertQuery(predicate: "optInt8Col >= %@ && optInt8Col < %@", values: [Int8(8), Int8(10)], expectedCount: 1) {
            $0.optInt8Col.contains(Int8(8)..<Int8(10))
        }

        assertQuery(predicate: "optInt8Col >= %@ && optInt8Col < %@", values: [Int8(8), Int8(9)], expectedCount: 0) {
            $0.optInt8Col.contains(Int8(8)..<Int8(9))
        }

        assertQuery(predicate: "optInt8Col BETWEEN {%@, %@}", values: [Int8(8), Int8(10)], expectedCount: 1) {
            $0.optInt8Col.contains(Int8(8)...Int8(10))
        }

        assertQuery(predicate: "optInt8Col BETWEEN {%@, %@}", values: [Int8(8), Int8(9)], expectedCount: 1) {
            $0.optInt8Col.contains(Int8(8)...Int8(9))
        }

        assertQuery(predicate: "optInt16Col >= %@ && optInt16Col < %@", values: [Int16(16), Int16(18)], expectedCount: 1) {
            $0.optInt16Col.contains(Int16(16)..<Int16(18))
        }

        assertQuery(predicate: "optInt16Col >= %@ && optInt16Col < %@", values: [Int16(16), Int16(17)], expectedCount: 0) {
            $0.optInt16Col.contains(Int16(16)..<Int16(17))
        }

        assertQuery(predicate: "optInt16Col BETWEEN {%@, %@}", values: [Int16(16), Int16(18)], expectedCount: 1) {
            $0.optInt16Col.contains(Int16(16)...Int16(18))
        }

        assertQuery(predicate: "optInt16Col BETWEEN {%@, %@}", values: [Int16(16), Int16(17)], expectedCount: 1) {
            $0.optInt16Col.contains(Int16(16)...Int16(17))
        }

        assertQuery(predicate: "optInt32Col >= %@ && optInt32Col < %@", values: [Int32(32), Int32(34)], expectedCount: 1) {
            $0.optInt32Col.contains(Int32(32)..<Int32(34))
        }

        assertQuery(predicate: "optInt32Col >= %@ && optInt32Col < %@", values: [Int32(32), Int32(33)], expectedCount: 0) {
            $0.optInt32Col.contains(Int32(32)..<Int32(33))
        }

        assertQuery(predicate: "optInt32Col BETWEEN {%@, %@}", values: [Int32(32), Int32(34)], expectedCount: 1) {
            $0.optInt32Col.contains(Int32(32)...Int32(34))
        }

        assertQuery(predicate: "optInt32Col BETWEEN {%@, %@}", values: [Int32(32), Int32(33)], expectedCount: 1) {
            $0.optInt32Col.contains(Int32(32)...Int32(33))
        }

        assertQuery(predicate: "optInt64Col >= %@ && optInt64Col < %@", values: [Int64(64), Int64(66)], expectedCount: 1) {
            $0.optInt64Col.contains(Int64(64)..<Int64(66))
        }

        assertQuery(predicate: "optInt64Col >= %@ && optInt64Col < %@", values: [Int64(64), Int64(65)], expectedCount: 0) {
            $0.optInt64Col.contains(Int64(64)..<Int64(65))
        }

        assertQuery(predicate: "optInt64Col BETWEEN {%@, %@}", values: [Int64(64), Int64(66)], expectedCount: 1) {
            $0.optInt64Col.contains(Int64(64)...Int64(66))
        }

        assertQuery(predicate: "optInt64Col BETWEEN {%@, %@}", values: [Int64(64), Int64(65)], expectedCount: 1) {
            $0.optInt64Col.contains(Int64(64)...Int64(65))
        }

        assertQuery(predicate: "optFloatCol >= %@ && optFloatCol < %@", values: [Float(5.55444333), Float(7.55444333)], expectedCount: 1) {
            $0.optFloatCol.contains(Float(5.55444333)..<Float(7.55444333))
        }

        assertQuery(predicate: "optFloatCol >= %@ && optFloatCol < %@", values: [Float(5.55444333), Float(6.55444333)], expectedCount: 0) {
            $0.optFloatCol.contains(Float(5.55444333)..<Float(6.55444333))
        }

        assertQuery(predicate: "optFloatCol BETWEEN {%@, %@}", values: [Float(5.55444333), Float(7.55444333)], expectedCount: 1) {
            $0.optFloatCol.contains(Float(5.55444333)...Float(7.55444333))
        }

        assertQuery(predicate: "optFloatCol BETWEEN {%@, %@}", values: [Float(5.55444333), Float(6.55444333)], expectedCount: 1) {
            $0.optFloatCol.contains(Float(5.55444333)...Float(6.55444333))
        }

        assertQuery(predicate: "optDoubleCol >= %@ && optDoubleCol < %@", values: [5.55444333, 7.55444333], expectedCount: 1) {
            $0.optDoubleCol.contains(5.55444333..<7.55444333)
        }

        assertQuery(predicate: "optDoubleCol >= %@ && optDoubleCol < %@", values: [5.55444333, 6.55444333], expectedCount: 0) {
            $0.optDoubleCol.contains(5.55444333..<6.55444333)
        }

        assertQuery(predicate: "optDoubleCol BETWEEN {%@, %@}", values: [5.55444333, 7.55444333], expectedCount: 1) {
            $0.optDoubleCol.contains(5.55444333...7.55444333)
        }

        assertQuery(predicate: "optDoubleCol BETWEEN {%@, %@}", values: [5.55444333, 6.55444333], expectedCount: 1) {
            $0.optDoubleCol.contains(5.55444333...6.55444333)
        }

        assertQuery(predicate: "optDateCol >= %@ && optDateCol < %@", values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.optDateCol.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "optDateCol >= %@ && optDateCol < %@", values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.optDateCol.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "optDateCol BETWEEN {%@, %@}", values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.optDateCol.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "optDateCol BETWEEN {%@, %@}", values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.optDateCol.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "optDecimalCol >= %@ && optDecimalCol < %@", values: [Decimal128(123.456), Decimal128(345.456)], expectedCount: 1) {
            $0.optDecimalCol.contains(Decimal128(123.456)..<Decimal128(345.456))
        }

        assertQuery(predicate: "optDecimalCol >= %@ && optDecimalCol < %@", values: [Decimal128(123.456), Decimal128(234.456)], expectedCount: 0) {
            $0.optDecimalCol.contains(Decimal128(123.456)..<Decimal128(234.456))
        }

        assertQuery(predicate: "optDecimalCol BETWEEN {%@, %@}", values: [Decimal128(123.456), Decimal128(345.456)], expectedCount: 1) {
            $0.optDecimalCol.contains(Decimal128(123.456)...Decimal128(345.456))
        }

        assertQuery(predicate: "optDecimalCol BETWEEN {%@, %@}", values: [Decimal128(123.456), Decimal128(234.456)], expectedCount: 1) {
            $0.optDecimalCol.contains(Decimal128(123.456)...Decimal128(234.456))
        }

    }
}
