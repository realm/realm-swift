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

    override func setUp() {
        let realm = realmWithTestPath()
        try! realm.write {
            let object = ModernAllTypesObject()

            object.boolCol = true
            object.intCol = 5
            object.int8Col = 8
            object.int16Col = 16
            object.int32Col = 32
            object.int64Col = 64
            object.floatCol = 5.55444333
            object.doubleCol = 5.55444333
            object.stringCol = "Foo"
            object.binaryCol = Data(count: 64)
            object.dateCol = Date(timeIntervalSince1970: 1000000)
            object.decimalCol = Decimal128(123.456)
            object.objectIdCol = ObjectId("61184062c1d8f096a3695046")
            object.intEnumCol = .value1
            object.stringEnumCol = .value1
            object.uuidCol = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
            object.optBoolCol = true
            object.optIntCol = 5
            object.optInt8Col = 8
            object.optInt16Col = 16
            object.optInt32Col = 32
            object.optInt64Col = 64
            object.optFloatCol = 5.55444333
            object.optDoubleCol = 5.55444333
            object.optStringCol = "Foo"
            object.optBinaryCol = Data(count: 64)
            object.optDateCol = Date(timeIntervalSince1970: 1000000)
            object.optDecimalCol = Decimal128(123.456)
            object.optObjectIdCol = ObjectId("61184062c1d8f096a3695046")
            object.optIntEnumCol = .value1
            object.optStringEnumCol = .value1
            object.optUuidCol = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!


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

    func testEquals() {
        var query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>)

        // boolCol

        let boolColResults = objects().query { obj in
            obj.boolCol == true
        }
        XCTAssertEqual(boolColResults.count, 1)

        query = {
            $0.boolCol == true
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "boolCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Bool,
                       true)
        // intCol

        let intColResults = objects().query { obj in
            obj.intCol == 5
        }
        XCTAssertEqual(intColResults.count, 1)

        query = {
            $0.intCol == 5
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "intCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int,
                       5)
        // int8Col

        let int8ColResults = objects().query { obj in
            obj.int8Col == 8
        }
        XCTAssertEqual(int8ColResults.count, 1)

        query = {
            $0.int8Col == 8
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "int8Col == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int8,
                       8)
        // int16Col

        let int16ColResults = objects().query { obj in
            obj.int16Col == 16
        }
        XCTAssertEqual(int16ColResults.count, 1)

        query = {
            $0.int16Col == 16
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "int16Col == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int16,
                       16)
        // int32Col

        let int32ColResults = objects().query { obj in
            obj.int32Col == 32
        }
        XCTAssertEqual(int32ColResults.count, 1)

        query = {
            $0.int32Col == 32
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "int32Col == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int32,
                       32)
        // int64Col

        let int64ColResults = objects().query { obj in
            obj.int64Col == 64
        }
        XCTAssertEqual(int64ColResults.count, 1)

        query = {
            $0.int64Col == 64
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "int64Col == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int64,
                       64)
        // floatCol

        let floatColResults = objects().query { obj in
            obj.floatCol == 5.55444333
        }
        XCTAssertEqual(floatColResults.count, 1)

        query = {
            $0.floatCol == 5.55444333
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "floatCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Float,
                       5.55444333)
        // doubleCol

        let doubleColResults = objects().query { obj in
            obj.doubleCol == 5.55444333
        }
        XCTAssertEqual(doubleColResults.count, 1)

        query = {
            $0.doubleCol == 5.55444333
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "doubleCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Double,
                       5.55444333)
        // stringCol

        let stringColResults = objects().query { obj in
            obj.stringCol == "Foo"
        }
        XCTAssertEqual(stringColResults.count, 1)

        query = {
            $0.stringCol == "Foo"
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "stringCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! String,
                       "Foo")
        // binaryCol

        let binaryColResults = objects().query { obj in
            obj.binaryCol == Data(count: 64)
        }
        XCTAssertEqual(binaryColResults.count, 1)

        query = {
            $0.binaryCol == Data(count: 64)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "binaryCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Data,
                       Data(count: 64))
        // dateCol

        let dateColResults = objects().query { obj in
            obj.dateCol == Date(timeIntervalSince1970: 1000000)
        }
        XCTAssertEqual(dateColResults.count, 1)

        query = {
            $0.dateCol == Date(timeIntervalSince1970: 1000000)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "dateCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Date,
                       Date(timeIntervalSince1970: 1000000))
        // decimalCol

        let decimalColResults = objects().query { obj in
            obj.decimalCol == Decimal128(123.456)
        }
        XCTAssertEqual(decimalColResults.count, 1)

        query = {
            $0.decimalCol == Decimal128(123.456)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "decimalCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Decimal128,
                       Decimal128(123.456))
        // objectIdCol

        let objectIdColResults = objects().query { obj in
            obj.objectIdCol == ObjectId("61184062c1d8f096a3695046")
        }
        XCTAssertEqual(objectIdColResults.count, 1)

        query = {
            $0.objectIdCol == ObjectId("61184062c1d8f096a3695046")
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "objectIdCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! ObjectId,
                       ObjectId("61184062c1d8f096a3695046"))
        // intEnumCol

        let intEnumColResults = objects().query { obj in
            obj.intEnumCol == .value1
        }
        XCTAssertEqual(intEnumColResults.count, 1)

        query = {
            $0.intEnumCol == .value1
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "intEnumCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int,
                       ModernIntEnum.value1.rawValue)
        // stringEnumCol

        let stringEnumColResults = objects().query { obj in
            obj.stringEnumCol == .value1
        }
        XCTAssertEqual(stringEnumColResults.count, 1)

        query = {
            $0.stringEnumCol == .value1
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "stringEnumCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! String,
                       ModernStringEnum.value1.rawValue)
        // uuidCol

        let uuidColResults = objects().query { obj in
            obj.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        XCTAssertEqual(uuidColResults.count, 1)

        query = {
            $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "uuidCol == %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! UUID,
                       UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
    }

    func testEqualsOptional() {
        var query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>)

        // Optional

        // optBoolCol

        let optBoolColResults = objects().query { obj in
            obj.optBoolCol == true
        }
        XCTAssertEqual(optBoolColResults.count, 1)

        query = {
            $0.optBoolCol == true
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optBoolCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Bool?,
                       true)
        // optIntCol

        let optIntColResults = objects().query { obj in
            obj.optIntCol == 5
        }
        XCTAssertEqual(optIntColResults.count, 1)

        query = {
            $0.optIntCol == 5
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optIntCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int?,
                       5)
        // optInt8Col

        let optInt8ColResults = objects().query { obj in
            obj.optInt8Col == 8
        }
        XCTAssertEqual(optInt8ColResults.count, 1)

        query = {
            $0.optInt8Col == 8
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt8Col == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int8?,
                       8)
        // optInt16Col

        let optInt16ColResults = objects().query { obj in
            obj.optInt16Col == 16
        }
        XCTAssertEqual(optInt16ColResults.count, 1)

        query = {
            $0.optInt16Col == 16
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt16Col == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int16?,
                       16)
        // optInt32Col

        let optInt32ColResults = objects().query { obj in
            obj.optInt32Col == 32
        }
        XCTAssertEqual(optInt32ColResults.count, 1)

        query = {
            $0.optInt32Col == 32
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt32Col == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int32?,
                       32)
        // optInt64Col

        let optInt64ColResults = objects().query { obj in
            obj.optInt64Col == 64
        }
        XCTAssertEqual(optInt64ColResults.count, 1)

        query = {
            $0.optInt64Col == 64
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt64Col == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int64?,
                       64)
        // optFloatCol

        let optFloatColResults = objects().query { obj in
            obj.optFloatCol == 5.55444333
        }
        XCTAssertEqual(optFloatColResults.count, 1)

        query = {
            $0.optFloatCol == 5.55444333
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optFloatCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Float?,
                       5.55444333)
        // optDoubleCol

        let optDoubleColResults = objects().query { obj in
            obj.optDoubleCol == 5.55444333
        }
        XCTAssertEqual(optDoubleColResults.count, 1)

        query = {
            $0.optDoubleCol == 5.55444333
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDoubleCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Double?,
                       5.55444333)
        // optStringCol

        let optStringColResults = objects().query { obj in
            obj.optStringCol == "Foo"
        }
        XCTAssertEqual(optStringColResults.count, 1)

        query = {
            $0.optStringCol == "Foo"
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optStringCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! String?,
                       "Foo")
        // optBinaryCol

        let optBinaryColResults = objects().query { obj in
            obj.optBinaryCol == Data(count: 64)
        }
        XCTAssertEqual(optBinaryColResults.count, 1)

        query = {
            $0.optBinaryCol == Data(count: 64)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optBinaryCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Data?,
                       Data(count: 64))
        // optDateCol

        let optDateColResults = objects().query { obj in
            obj.optDateCol == Date(timeIntervalSince1970: 1000000)
        }
        XCTAssertEqual(optDateColResults.count, 1)

        query = {
            $0.optDateCol == Date(timeIntervalSince1970: 1000000)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDateCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Date?,
                       Date(timeIntervalSince1970: 1000000))
        // optDecimalCol

        let optDecimalColResults = objects().query { obj in
            obj.optDecimalCol == Decimal128(123.456)
        }
        XCTAssertEqual(optDecimalColResults.count, 1)

        query = {
            $0.optDecimalCol == Decimal128(123.456)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDecimalCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Decimal128?,
                       Decimal128(123.456))
        // optObjectIdCol

        let optObjectIdColResults = objects().query { obj in
            obj.optObjectIdCol == ObjectId("61184062c1d8f096a3695046")
        }
        XCTAssertEqual(optObjectIdColResults.count, 1)

        query = {
            $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695046")
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optObjectIdCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! ObjectId?,
                       ObjectId("61184062c1d8f096a3695046"))
        // optIntEnumCol

        let optIntEnumColResults = objects().query { obj in
            obj.optIntEnumCol == .value1
        }
        XCTAssertEqual(optIntEnumColResults.count, 1)

        query = {
            $0.optIntEnumCol == .value1
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optIntEnumCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int?,
                       ModernIntEnum.value1.rawValue)
        // optStringEnumCol

        let optStringEnumColResults = objects().query { obj in
            obj.optStringEnumCol == .value1
        }
        XCTAssertEqual(optStringEnumColResults.count, 1)

        query = {
            $0.optStringEnumCol == .value1
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optStringEnumCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! String?,
                       ModernStringEnum.value1.rawValue)
        // optUuidCol

        let optUuidColResults = objects().query { obj in
            obj.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        XCTAssertEqual(optUuidColResults.count, 1)

        query = {
            $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optUuidCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! UUID?,
                       UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)

        // Test for `nil`

        // `nil` optBoolCol

        let optBoolColOptResults = objects().query { obj in
            obj.optBoolCol == nil
        }
        XCTAssertEqual(optBoolColOptResults.count, 0)

        query = {
            $0.optBoolCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optBoolCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optIntCol

        let optIntColOptResults = objects().query { obj in
            obj.optIntCol == nil
        }
        XCTAssertEqual(optIntColOptResults.count, 0)

        query = {
            $0.optIntCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optIntCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optInt8Col

        let optInt8ColOptResults = objects().query { obj in
            obj.optInt8Col == nil
        }
        XCTAssertEqual(optInt8ColOptResults.count, 0)

        query = {
            $0.optInt8Col == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt8Col == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optInt16Col

        let optInt16ColOptResults = objects().query { obj in
            obj.optInt16Col == nil
        }
        XCTAssertEqual(optInt16ColOptResults.count, 0)

        query = {
            $0.optInt16Col == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt16Col == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optInt32Col

        let optInt32ColOptResults = objects().query { obj in
            obj.optInt32Col == nil
        }
        XCTAssertEqual(optInt32ColOptResults.count, 0)

        query = {
            $0.optInt32Col == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt32Col == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optInt64Col

        let optInt64ColOptResults = objects().query { obj in
            obj.optInt64Col == nil
        }
        XCTAssertEqual(optInt64ColOptResults.count, 0)

        query = {
            $0.optInt64Col == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt64Col == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optFloatCol

        let optFloatColOptResults = objects().query { obj in
            obj.optFloatCol == nil
        }
        XCTAssertEqual(optFloatColOptResults.count, 0)

        query = {
            $0.optFloatCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optFloatCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optDoubleCol

        let optDoubleColOptResults = objects().query { obj in
            obj.optDoubleCol == nil
        }
        XCTAssertEqual(optDoubleColOptResults.count, 0)

        query = {
            $0.optDoubleCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDoubleCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optStringCol

        let optStringColOptResults = objects().query { obj in
            obj.optStringCol == nil
        }
        XCTAssertEqual(optStringColOptResults.count, 0)

        query = {
            $0.optStringCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optStringCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optBinaryCol

        let optBinaryColOptResults = objects().query { obj in
            obj.optBinaryCol == nil
        }
        XCTAssertEqual(optBinaryColOptResults.count, 0)

        query = {
            $0.optBinaryCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optBinaryCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optDateCol

        let optDateColOptResults = objects().query { obj in
            obj.optDateCol == nil
        }
        XCTAssertEqual(optDateColOptResults.count, 0)

        query = {
            $0.optDateCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDateCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optDecimalCol

        let optDecimalColOptResults = objects().query { obj in
            obj.optDecimalCol == nil
        }
        XCTAssertEqual(optDecimalColOptResults.count, 0)

        query = {
            $0.optDecimalCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDecimalCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optObjectIdCol

        let optObjectIdColOptResults = objects().query { obj in
            obj.optObjectIdCol == nil
        }
        XCTAssertEqual(optObjectIdColOptResults.count, 0)

        query = {
            $0.optObjectIdCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optObjectIdCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optIntEnumCol

        let optIntEnumColOptResults = objects().query { obj in
            obj.optIntEnumCol == nil
        }
        XCTAssertEqual(optIntEnumColOptResults.count, 0)

        query = {
            $0.optIntEnumCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optIntEnumCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optStringEnumCol

        let optStringEnumColOptResults = objects().query { obj in
            obj.optStringEnumCol == nil
        }
        XCTAssertEqual(optStringEnumColOptResults.count, 0)

        query = {
            $0.optStringEnumCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optStringEnumCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optUuidCol

        let optUuidColOptResults = objects().query { obj in
            obj.optUuidCol == nil
        }
        XCTAssertEqual(optUuidColOptResults.count, 0)

        query = {
            $0.optUuidCol == nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optUuidCol == %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())
    }

    func testNotEquals() {
        var query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>)

        // boolCol

        let boolColResults = objects().query { obj in
            obj.boolCol != true
        }
        XCTAssertEqual(boolColResults.count, 0)

        query = {
            $0.boolCol != true
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "boolCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Bool,
                       true)
        // intCol

        let intColResults = objects().query { obj in
            obj.intCol != 5
        }
        XCTAssertEqual(intColResults.count, 0)

        query = {
            $0.intCol != 5
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "intCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int,
                       5)
        // int8Col

        let int8ColResults = objects().query { obj in
            obj.int8Col != 8
        }
        XCTAssertEqual(int8ColResults.count, 0)

        query = {
            $0.int8Col != 8
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "int8Col != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int8,
                       8)
        // int16Col

        let int16ColResults = objects().query { obj in
            obj.int16Col != 16
        }
        XCTAssertEqual(int16ColResults.count, 0)

        query = {
            $0.int16Col != 16
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "int16Col != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int16,
                       16)
        // int32Col

        let int32ColResults = objects().query { obj in
            obj.int32Col != 32
        }
        XCTAssertEqual(int32ColResults.count, 0)

        query = {
            $0.int32Col != 32
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "int32Col != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int32,
                       32)
        // int64Col

        let int64ColResults = objects().query { obj in
            obj.int64Col != 64
        }
        XCTAssertEqual(int64ColResults.count, 0)

        query = {
            $0.int64Col != 64
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "int64Col != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int64,
                       64)
        // floatCol

        let floatColResults = objects().query { obj in
            obj.floatCol != 5.55444333
        }
        XCTAssertEqual(floatColResults.count, 0)

        query = {
            $0.floatCol != 5.55444333
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "floatCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Float,
                       5.55444333)
        // doubleCol

        let doubleColResults = objects().query { obj in
            obj.doubleCol != 5.55444333
        }
        XCTAssertEqual(doubleColResults.count, 0)

        query = {
            $0.doubleCol != 5.55444333
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "doubleCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Double,
                       5.55444333)
        // stringCol

        let stringColResults = objects().query { obj in
            obj.stringCol != "Foo"
        }
        XCTAssertEqual(stringColResults.count, 0)

        query = {
            $0.stringCol != "Foo"
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "stringCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! String,
                       "Foo")
        // binaryCol

        let binaryColResults = objects().query { obj in
            obj.binaryCol != Data(count: 64)
        }
        XCTAssertEqual(binaryColResults.count, 0)

        query = {
            $0.binaryCol != Data(count: 64)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "binaryCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Data,
                       Data(count: 64))
        // dateCol

        let dateColResults = objects().query { obj in
            obj.dateCol != Date(timeIntervalSince1970: 1000000)
        }
        XCTAssertEqual(dateColResults.count, 0)

        query = {
            $0.dateCol != Date(timeIntervalSince1970: 1000000)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "dateCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Date,
                       Date(timeIntervalSince1970: 1000000))
        // decimalCol

        let decimalColResults = objects().query { obj in
            obj.decimalCol != Decimal128(123.456)
        }
        XCTAssertEqual(decimalColResults.count, 0)

        query = {
            $0.decimalCol != Decimal128(123.456)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "decimalCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Decimal128,
                       Decimal128(123.456))
        // objectIdCol

        let objectIdColResults = objects().query { obj in
            obj.objectIdCol != ObjectId("61184062c1d8f096a3695046")
        }
        XCTAssertEqual(objectIdColResults.count, 0)

        query = {
            $0.objectIdCol != ObjectId("61184062c1d8f096a3695046")
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "objectIdCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! ObjectId,
                       ObjectId("61184062c1d8f096a3695046"))
        // intEnumCol

        let intEnumColResults = objects().query { obj in
            obj.intEnumCol != .value1
        }
        XCTAssertEqual(intEnumColResults.count, 0)

        query = {
            $0.intEnumCol != .value1
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "intEnumCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int,
                       ModernIntEnum.value1.rawValue)
        // stringEnumCol

        let stringEnumColResults = objects().query { obj in
            obj.stringEnumCol != .value1
        }
        XCTAssertEqual(stringEnumColResults.count, 0)

        query = {
            $0.stringEnumCol != .value1
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "stringEnumCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! String,
                       ModernStringEnum.value1.rawValue)
        // uuidCol

        let uuidColResults = objects().query { obj in
            obj.uuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        XCTAssertEqual(uuidColResults.count, 0)

        query = {
            $0.uuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "uuidCol != %@")

        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! UUID,
                       UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
    }

    func testNotEqualsOptional() {
        var query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>)

        // Optional

        // optBoolCol

        let optBoolColResults = objects().query { obj in
            obj.optBoolCol != true
        }
        XCTAssertEqual(optBoolColResults.count, 0)

        query = {
            $0.optBoolCol != true
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optBoolCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Bool?,
                       true)
        // optIntCol

        let optIntColResults = objects().query { obj in
            obj.optIntCol != 5
        }
        XCTAssertEqual(optIntColResults.count, 0)

        query = {
            $0.optIntCol != 5
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optIntCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int?,
                       5)
        // optInt8Col

        let optInt8ColResults = objects().query { obj in
            obj.optInt8Col != 8
        }
        XCTAssertEqual(optInt8ColResults.count, 0)

        query = {
            $0.optInt8Col != 8
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt8Col != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int8?,
                       8)
        // optInt16Col

        let optInt16ColResults = objects().query { obj in
            obj.optInt16Col != 16
        }
        XCTAssertEqual(optInt16ColResults.count, 0)

        query = {
            $0.optInt16Col != 16
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt16Col != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int16?,
                       16)
        // optInt32Col

        let optInt32ColResults = objects().query { obj in
            obj.optInt32Col != 32
        }
        XCTAssertEqual(optInt32ColResults.count, 0)

        query = {
            $0.optInt32Col != 32
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt32Col != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int32?,
                       32)
        // optInt64Col

        let optInt64ColResults = objects().query { obj in
            obj.optInt64Col != 64
        }
        XCTAssertEqual(optInt64ColResults.count, 0)

        query = {
            $0.optInt64Col != 64
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt64Col != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int64?,
                       64)
        // optFloatCol

        let optFloatColResults = objects().query { obj in
            obj.optFloatCol != 5.55444333
        }
        XCTAssertEqual(optFloatColResults.count, 0)

        query = {
            $0.optFloatCol != 5.55444333
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optFloatCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Float?,
                       5.55444333)
        // optDoubleCol

        let optDoubleColResults = objects().query { obj in
            obj.optDoubleCol != 5.55444333
        }
        XCTAssertEqual(optDoubleColResults.count, 0)

        query = {
            $0.optDoubleCol != 5.55444333
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDoubleCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Double?,
                       5.55444333)
        // optStringCol

        let optStringColResults = objects().query { obj in
            obj.optStringCol != "Foo"
        }
        XCTAssertEqual(optStringColResults.count, 0)

        query = {
            $0.optStringCol != "Foo"
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optStringCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! String?,
                       "Foo")
        // optBinaryCol

        let optBinaryColResults = objects().query { obj in
            obj.optBinaryCol != Data(count: 64)
        }
        XCTAssertEqual(optBinaryColResults.count, 0)

        query = {
            $0.optBinaryCol != Data(count: 64)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optBinaryCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Data?,
                       Data(count: 64))
        // optDateCol

        let optDateColResults = objects().query { obj in
            obj.optDateCol != Date(timeIntervalSince1970: 1000000)
        }
        XCTAssertEqual(optDateColResults.count, 0)

        query = {
            $0.optDateCol != Date(timeIntervalSince1970: 1000000)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDateCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Date?,
                       Date(timeIntervalSince1970: 1000000))
        // optDecimalCol

        let optDecimalColResults = objects().query { obj in
            obj.optDecimalCol != Decimal128(123.456)
        }
        XCTAssertEqual(optDecimalColResults.count, 0)

        query = {
            $0.optDecimalCol != Decimal128(123.456)
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDecimalCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Decimal128?,
                       Decimal128(123.456))
        // optObjectIdCol

        let optObjectIdColResults = objects().query { obj in
            obj.optObjectIdCol != ObjectId("61184062c1d8f096a3695046")
        }
        XCTAssertEqual(optObjectIdColResults.count, 0)

        query = {
            $0.optObjectIdCol != ObjectId("61184062c1d8f096a3695046")
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optObjectIdCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! ObjectId?,
                       ObjectId("61184062c1d8f096a3695046"))
        // optIntEnumCol

        let optIntEnumColResults = objects().query { obj in
            obj.optIntEnumCol != .value1
        }
        XCTAssertEqual(optIntEnumColResults.count, 0)

        query = {
            $0.optIntEnumCol != .value1
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optIntEnumCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! Int?,
                       ModernIntEnum.value1.rawValue)
        // optStringEnumCol

        let optStringEnumColResults = objects().query { obj in
            obj.optStringEnumCol != .value1
        }
        XCTAssertEqual(optStringEnumColResults.count, 0)

        query = {
            $0.optStringEnumCol != .value1
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optStringEnumCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! String?,
                       ModernStringEnum.value1.rawValue)
        // optUuidCol

        let optUuidColResults = objects().query { obj in
            obj.optUuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        XCTAssertEqual(optUuidColResults.count, 0)

        query = {
            $0.optUuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optUuidCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! UUID?,
                       UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)

        // Test for `nil`

        // `nil` optBoolCol

        let optBoolColOptResults = objects().query { obj in
            obj.optBoolCol != nil
        }
        XCTAssertEqual(optBoolColOptResults.count, 1)

        query = {
            $0.optBoolCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optBoolCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optIntCol

        let optIntColOptResults = objects().query { obj in
            obj.optIntCol != nil
        }
        XCTAssertEqual(optIntColOptResults.count, 1)

        query = {
            $0.optIntCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optIntCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optInt8Col

        let optInt8ColOptResults = objects().query { obj in
            obj.optInt8Col != nil
        }
        XCTAssertEqual(optInt8ColOptResults.count, 1)

        query = {
            $0.optInt8Col != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt8Col != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optInt16Col

        let optInt16ColOptResults = objects().query { obj in
            obj.optInt16Col != nil
        }
        XCTAssertEqual(optInt16ColOptResults.count, 1)

        query = {
            $0.optInt16Col != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt16Col != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optInt32Col

        let optInt32ColOptResults = objects().query { obj in
            obj.optInt32Col != nil
        }
        XCTAssertEqual(optInt32ColOptResults.count, 1)

        query = {
            $0.optInt32Col != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt32Col != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optInt64Col

        let optInt64ColOptResults = objects().query { obj in
            obj.optInt64Col != nil
        }
        XCTAssertEqual(optInt64ColOptResults.count, 1)

        query = {
            $0.optInt64Col != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optInt64Col != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optFloatCol

        let optFloatColOptResults = objects().query { obj in
            obj.optFloatCol != nil
        }
        XCTAssertEqual(optFloatColOptResults.count, 1)

        query = {
            $0.optFloatCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optFloatCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optDoubleCol

        let optDoubleColOptResults = objects().query { obj in
            obj.optDoubleCol != nil
        }
        XCTAssertEqual(optDoubleColOptResults.count, 1)

        query = {
            $0.optDoubleCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDoubleCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optStringCol

        let optStringColOptResults = objects().query { obj in
            obj.optStringCol != nil
        }
        XCTAssertEqual(optStringColOptResults.count, 1)

        query = {
            $0.optStringCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optStringCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optBinaryCol

        let optBinaryColOptResults = objects().query { obj in
            obj.optBinaryCol != nil
        }
        XCTAssertEqual(optBinaryColOptResults.count, 1)

        query = {
            $0.optBinaryCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optBinaryCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optDateCol

        let optDateColOptResults = objects().query { obj in
            obj.optDateCol != nil
        }
        XCTAssertEqual(optDateColOptResults.count, 1)

        query = {
            $0.optDateCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDateCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optDecimalCol

        let optDecimalColOptResults = objects().query { obj in
            obj.optDecimalCol != nil
        }
        XCTAssertEqual(optDecimalColOptResults.count, 1)

        query = {
            $0.optDecimalCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optDecimalCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optObjectIdCol

        let optObjectIdColOptResults = objects().query { obj in
            obj.optObjectIdCol != nil
        }
        XCTAssertEqual(optObjectIdColOptResults.count, 1)

        query = {
            $0.optObjectIdCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optObjectIdCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optIntEnumCol

        let optIntEnumColOptResults = objects().query { obj in
            obj.optIntEnumCol != nil
        }
        XCTAssertEqual(optIntEnumColOptResults.count, 1)

        query = {
            $0.optIntEnumCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optIntEnumCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optStringEnumCol

        let optStringEnumColOptResults = objects().query { obj in
            obj.optStringEnumCol != nil
        }
        XCTAssertEqual(optStringEnumColOptResults.count, 1)

        query = {
            $0.optStringEnumCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optStringEnumCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())

        // `nil` optUuidCol

        let optUuidColOptResults = objects().query { obj in
            obj.optUuidCol != nil
        }
        XCTAssertEqual(optUuidColOptResults.count, 1)

        query = {
            $0.optUuidCol != nil
        }
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().0,
                       "optUuidCol != %@")
        XCTAssertEqual(query(Query<ModernAllTypesObject>()).constructPredicate().1[0] as! NSNull,
                       NSNull())
    }


}
