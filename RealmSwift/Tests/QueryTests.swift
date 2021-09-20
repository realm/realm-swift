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
import RealmSwift
/// This file is generated from a template. Do not edit directly.
class QueryTests: TestCase {

    private func objects() -> Results<ModernAllTypesObject> {
        realmWithTestPath().objects(ModernAllTypesObject.self)
    }

    private func collectionObject() -> ModernCollectionObject {
        let realm = realmWithTestPath()
        if let object = realm.objects(ModernCollectionObject.self).first {
            return object
        } else {
            let object = ModernCollectionObject()
            try! realm.write {
                realm.add(object)
            }
            return object
        }
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
            object.doubleCol = 234.567
            object.stringCol = "Foó"
            object.binaryCol = Data(count: 128)
            object.dateCol = Date(timeIntervalSince1970: 2000000)
            object.decimalCol = Decimal128(234.567)
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
            object.optDoubleCol = 234.567
            object.optStringCol = "Foó"
            object.optBinaryCol = Data(count: 128)
            object.optDateCol = Date(timeIntervalSince1970: 2000000)
            object.optDecimalCol = Decimal128(234.567)
            object.optObjectIdCol = ObjectId("61184062c1d8f096a3695045")
            object.optIntEnumCol = .value2
            object.optStringEnumCol = .value2
            object.optUuidCol = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!

            object.arrayBool.append(objectsIn: [true, true])
            object.arrayInt.append(objectsIn: [1, 2])
            object.arrayInt8.append(objectsIn: [Int8(8), Int8(9)])
            object.arrayInt16.append(objectsIn: [Int16(16), Int16(17)])
            object.arrayInt32.append(objectsIn: [Int32(32), Int32(33)])
            object.arrayInt64.append(objectsIn: [Int64(64), Int64(65)])
            object.arrayFloat.append(objectsIn: [Float(5.55444333), Float(6.55444333)])
            object.arrayDouble.append(objectsIn: [123.456, 234.567])
            object.arrayString.append(objectsIn: ["Foo", "Bar"])
            object.arrayBinary.append(objectsIn: [Data(count: 64), Data(count: 128)])
            object.arrayDate.append(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            object.arrayDecimal.append(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            object.arrayObjectId.append(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
            object.arrayUuid.append(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
            object.arrayAny.append(objectsIn: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
            object.arrayOptBool.append(objectsIn: [true, true])
            object.arrayOptInt.append(objectsIn: [1, 2])
            object.arrayOptInt8.append(objectsIn: [Int8(8), Int8(9)])
            object.arrayOptInt16.append(objectsIn: [Int16(16), Int16(17)])
            object.arrayOptInt32.append(objectsIn: [Int32(32), Int32(33)])
            object.arrayOptInt64.append(objectsIn: [Int64(64), Int64(65)])
            object.arrayOptFloat.append(objectsIn: [Float(5.55444333), Float(6.55444333)])
            object.arrayOptDouble.append(objectsIn: [123.456, 234.567])
            object.arrayOptString.append(objectsIn: ["Foo", "Bar"])
            object.arrayOptBinary.append(objectsIn: [Data(count: 64), Data(count: 128)])
            object.arrayOptDate.append(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            object.arrayOptDecimal.append(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            object.arrayOptUuid.append(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
            object.arrayOptObjectId.append(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])

            object.setBool.insert(objectsIn: [true, true])
            object.setInt.insert(objectsIn: [1, 2])
            object.setInt8.insert(objectsIn: [Int8(8), Int8(9)])
            object.setInt16.insert(objectsIn: [Int16(16), Int16(17)])
            object.setInt32.insert(objectsIn: [Int32(32), Int32(33)])
            object.setInt64.insert(objectsIn: [Int64(64), Int64(65)])
            object.setFloat.insert(objectsIn: [Float(5.55444333), Float(6.55444333)])
            object.setDouble.insert(objectsIn: [123.456, 234.567])
            object.setString.insert(objectsIn: ["Foo", "Bar"])
            object.setBinary.insert(objectsIn: [Data(count: 64), Data(count: 128)])
            object.setDate.insert(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            object.setDecimal.insert(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            object.setObjectId.insert(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
            object.setUuid.insert(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
            object.setAny.insert(objectsIn: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
            object.setOptBool.insert(objectsIn: [true, true])
            object.setOptInt.insert(objectsIn: [1, 2])
            object.setOptInt8.insert(objectsIn: [Int8(8), Int8(9)])
            object.setOptInt16.insert(objectsIn: [Int16(16), Int16(17)])
            object.setOptInt32.insert(objectsIn: [Int32(32), Int32(33)])
            object.setOptInt64.insert(objectsIn: [Int64(64), Int64(65)])
            object.setOptFloat.insert(objectsIn: [Float(5.55444333), Float(6.55444333)])
            object.setOptDouble.insert(objectsIn: [123.456, 234.567])
            object.setOptString.insert(objectsIn: ["Foo", "Bar"])
            object.setOptBinary.insert(objectsIn: [Data(count: 64), Data(count: 128)])
            object.setOptDate.insert(objectsIn: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
            object.setOptDecimal.insert(objectsIn: [Decimal128(123.456), Decimal128(234.567)])
            object.setOptUuid.insert(objectsIn: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
            object.setOptObjectId.insert(objectsIn: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])

            object.mapBool["foo"] = true
            object.mapBool["bar"] = true
            object.mapInt["foo"] = 1
            object.mapInt["bar"] = 2
            object.mapInt8["foo"] = Int8(8)
            object.mapInt8["bar"] = Int8(9)
            object.mapInt16["foo"] = Int16(16)
            object.mapInt16["bar"] = Int16(17)
            object.mapInt32["foo"] = Int32(32)
            object.mapInt32["bar"] = Int32(33)
            object.mapInt64["foo"] = Int64(64)
            object.mapInt64["bar"] = Int64(65)
            object.mapFloat["foo"] = Float(5.55444333)
            object.mapFloat["bar"] = Float(6.55444333)
            object.mapDouble["foo"] = 123.456
            object.mapDouble["bar"] = 234.456
            object.mapString["foo"] = "Foo"
            object.mapString["bar"] = "Bar"
            object.mapBinary["foo"] = Data(count: 64)
            object.mapBinary["bar"] = Data(count: 128)
            object.mapDate["foo"] = Date(timeIntervalSince1970: 1000000)
            object.mapDate["bar"] = Date(timeIntervalSince1970: 2000000)
            object.mapDecimal["foo"] = Decimal128(123.456)
            object.mapDecimal["bar"] = Decimal128(456.789)
            object.mapObjectId["foo"] = ObjectId("61184062c1d8f096a3695046")
            object.mapObjectId["bar"] = ObjectId("61184062c1d8f096a3695045")
            object.mapUuid["foo"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
            object.mapUuid["bar"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
            object.mapAny["foo"] = AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
            object.mapAny["bar"] = AnyRealmValue.string("Hello")
            object.mapOptBool["foo"] = true
            object.mapOptBool["bar"] = true
            object.mapOptInt["foo"] = 1
            object.mapOptInt["bar"] = 2
            object.mapOptInt8["foo"] = Int8(8)
            object.mapOptInt8["bar"] = Int8(9)
            object.mapOptInt16["foo"] = Int16(16)
            object.mapOptInt16["bar"] = Int16(17)
            object.mapOptInt32["foo"] = Int32(32)
            object.mapOptInt32["bar"] = Int32(33)
            object.mapOptInt64["foo"] = Int64(64)
            object.mapOptInt64["bar"] = Int64(65)
            object.mapOptFloat["foo"] = Float(5.55444333)
            object.mapOptFloat["bar"] = Float(6.55444333)
            object.mapOptDouble["foo"] = 123.456
            object.mapOptDouble["bar"] = 234.456
            object.mapOptString["foo"] = "Foo"
            object.mapOptString["bar"] = "Bar"
            object.mapOptBinary["foo"] = Data(count: 64)
            object.mapOptBinary["bar"] = Data(count: 128)
            object.mapOptDate["foo"] = Date(timeIntervalSince1970: 1000000)
            object.mapOptDate["bar"] = Date(timeIntervalSince1970: 2000000)
            object.mapOptDecimal["foo"] = Decimal128(123.456)
            object.mapOptDecimal["bar"] = Decimal128(456.789)
            object.mapOptUuid["foo"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
            object.mapOptUuid["bar"] = UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
            object.mapOptObjectId["foo"] = ObjectId("61184062c1d8f096a3695046")
            object.mapOptObjectId["bar"] = ObjectId("61184062c1d8f096a3695045")

            realm.add(object)
        }
    }

    private func assertQuery(predicate: String,
                             values: [AnyHashable],
                             expectedCount: Int,
                             _ query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>)) {
        let results = objects().query(query)
        XCTAssertEqual(results.count, expectedCount)

        let constructedPredicate = query(Query<ModernAllTypesObject>())._constructPredicate()
        XCTAssertEqual(constructedPredicate.0,
                       predicate)

        for (e1, e2) in zip(constructedPredicate.1, values) {
            if let e1 = e1 as? Object, let e2 = e2 as? Object {
                assertEqual(e1, e2)
            } else {
                XCTAssertEqual(e1 as! AnyHashable, e2)
            }
        }
    }

    private func assertCollectionObjectQuery(predicate: String,
                                             values: [AnyHashable],
                                             expectedCount: Int,
                                             _ query: ((Query<ModernCollectionObject>) -> Query<ModernCollectionObject>)) {
        let results = realmWithTestPath().objects(ModernCollectionObject.self).query(query)
        XCTAssertEqual(results.count, expectedCount)

        let constructedPredicate = query(Query<ModernCollectionObject>())._constructPredicate()
        XCTAssertEqual(constructedPredicate.0,
                       predicate)

        for (e1, e2) in zip(constructedPredicate.1, values) {
            if let e1 = e1 as? Object, let e2 = e2 as? Object {
                assertEqual(e1, e2)
            } else {
                XCTAssertEqual(e1 as! AnyHashable, e2)
            }
        }
    }

    private func assertCollectionQuery<T: _RealmSchemaDiscoverable>(on keyPath: KeyPath<ModernAllTypesObject, T>,
                                                                    isList: Bool,
                                                                    predicate: String,
                                                                    values: [AnyHashable],
                                                                    expectedCount: Int,
                                                                    query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>)) {
        let colObj = realmWithTestPath().objects(ModernCollectionObject.self).first!
        var results: Results<ModernAllTypesObject>!
        if isList {
            results = colObj.list.query(query)
        } else {
            results = colObj.set.query(query)
        }
        XCTAssertEqual(results.count, expectedCount)

        let constructedPredicate = query(Query<ModernAllTypesObject>())._constructPredicate()
        XCTAssertEqual(constructedPredicate.0,
                       predicate)

        for (e1, e2) in zip(constructedPredicate.1, values) {
            XCTAssertEqual(e1 as! AnyHashable, e2)
        }
    }

    private func assertMapQuery<T: _RealmSchemaDiscoverable>(on keyPath: KeyPath<ModernAllTypesObject, T>,
                                                             predicate: String,
                                                             values: [AnyHashable],
                                                             expectedCount: Int,
                                                             query: ((Query<ModernAllTypesObject?>) -> Query<ModernAllTypesObject?>)) {
        let colObj = realmWithTestPath().objects(ModernCollectionObject.self).first!
        var results: Results<ModernAllTypesObject?>!
        results = colObj.map.query(query)
        XCTAssertEqual(results.count, expectedCount)

        let constructedPredicate = query(Query<ModernAllTypesObject?>())._constructPredicate()
        XCTAssertEqual(constructedPredicate.0,
                       predicate)

        for (e1, e2) in zip(constructedPredicate.1, values) {
            XCTAssertEqual(e1 as! AnyHashable, e2)
        }
    }

    // MARK: - Basic Comparison

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
        assertQuery(predicate: "doubleCol == %@", values: [234.567], expectedCount: 1) {
            $0.doubleCol == 234.567
        }

        // stringCol
        assertQuery(predicate: "stringCol == %@", values: ["Foó"], expectedCount: 1) {
            $0.stringCol == "Foó"
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
        assertQuery(predicate: "decimalCol == %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.decimalCol == Decimal128(234.567)
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

        assertQuery(predicate: "optDoubleCol == %@", values: [234.567], expectedCount: 1) {
            $0.optDoubleCol == 234.567
        }
        // optStringCol

        assertQuery(predicate: "optStringCol == %@", values: ["Foó"], expectedCount: 1) {
            $0.optStringCol == "Foó"
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

        assertQuery(predicate: "optDecimalCol == %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.optDecimalCol == Decimal128(234.567)
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

        // optStringCol
        assertQuery(predicate: "optStringCol == %@", values: [NSNull()], expectedCount: 0) {
            $0.optStringCol == nil
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

        assertQuery(predicate: "doubleCol != %@", values: [234.567], expectedCount: 0) {
            $0.doubleCol != 234.567
        }
        // stringCol

        assertQuery(predicate: "stringCol != %@", values: ["Foó"], expectedCount: 0) {
            $0.stringCol != "Foó"
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

        assertQuery(predicate: "decimalCol != %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.decimalCol != Decimal128(234.567)
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

        assertQuery(predicate: "optDoubleCol != %@", values: [234.567], expectedCount: 0) {
            $0.optDoubleCol != 234.567
        }
        // optStringCol

        assertQuery(predicate: "optStringCol != %@", values: ["Foó"], expectedCount: 0) {
            $0.optStringCol != "Foó"
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

        assertQuery(predicate: "optDecimalCol != %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.optDecimalCol != Decimal128(234.567)
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

        // optStringCol
        assertQuery(predicate: "optStringCol != %@", values: [NSNull()], expectedCount: 1) {
            $0.optStringCol != nil
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
        assertQuery(predicate: "doubleCol > %@", values: [234.567], expectedCount: 0) {
            $0.doubleCol > 234.567
        }
        assertQuery(predicate: "doubleCol >= %@", values: [234.567], expectedCount: 1) {
            $0.doubleCol >= 234.567
        }
        // dateCol
        assertQuery(predicate: "dateCol > %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.dateCol > Date(timeIntervalSince1970: 2000000)
        }
        assertQuery(predicate: "dateCol >= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.dateCol >= Date(timeIntervalSince1970: 2000000)
        }
        // decimalCol
        assertQuery(predicate: "decimalCol > %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.decimalCol > Decimal128(234.567)
        }
        assertQuery(predicate: "decimalCol >= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.decimalCol >= Decimal128(234.567)
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
        assertQuery(predicate: "optDoubleCol > %@", values: [234.567], expectedCount: 0) {
            $0.optDoubleCol > 234.567
        }
        assertQuery(predicate: "optDoubleCol >= %@", values: [234.567], expectedCount: 1) {
            $0.optDoubleCol >= 234.567
        }
        // optDateCol
        assertQuery(predicate: "optDateCol > %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.optDateCol > Date(timeIntervalSince1970: 2000000)
        }
        assertQuery(predicate: "optDateCol >= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.optDateCol >= Date(timeIntervalSince1970: 2000000)
        }
        // optDecimalCol
        assertQuery(predicate: "optDecimalCol > %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.optDecimalCol > Decimal128(234.567)
        }
        assertQuery(predicate: "optDecimalCol >= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.optDecimalCol >= Decimal128(234.567)
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
        assertQuery(predicate: "doubleCol < %@", values: [234.567], expectedCount: 0) {
            $0.doubleCol < 234.567
        }
        assertQuery(predicate: "doubleCol <= %@", values: [234.567], expectedCount: 1) {
            $0.doubleCol <= 234.567
        }
        // dateCol
        assertQuery(predicate: "dateCol < %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.dateCol < Date(timeIntervalSince1970: 2000000)
        }
        assertQuery(predicate: "dateCol <= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.dateCol <= Date(timeIntervalSince1970: 2000000)
        }
        // decimalCol
        assertQuery(predicate: "decimalCol < %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.decimalCol < Decimal128(234.567)
        }
        assertQuery(predicate: "decimalCol <= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.decimalCol <= Decimal128(234.567)
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
        assertQuery(predicate: "optDoubleCol < %@", values: [234.567], expectedCount: 0) {
            $0.optDoubleCol < 234.567
        }
        assertQuery(predicate: "optDoubleCol <= %@", values: [234.567], expectedCount: 1) {
            $0.optDoubleCol <= 234.567
        }
        // optDateCol
        assertQuery(predicate: "optDateCol < %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.optDateCol < Date(timeIntervalSince1970: 2000000)
        }
        assertQuery(predicate: "optDateCol <= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.optDateCol <= Date(timeIntervalSince1970: 2000000)
        }
        // optDecimalCol
        assertQuery(predicate: "optDecimalCol < %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.optDecimalCol < Decimal128(234.567)
        }
        assertQuery(predicate: "optDecimalCol <= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.optDecimalCol <= Decimal128(234.567)
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
        assertQuery(predicate: "intCol >= %@ && intCol < %@",
                    values: [5, 7], expectedCount: 1) {
            $0.intCol.contains(5..<7)
        }

        assertQuery(predicate: "intCol >= %@ && intCol < %@",
                    values: [5, 6], expectedCount: 0) {
            $0.intCol.contains(5..<6)
        }

        assertQuery(predicate: "intCol BETWEEN {%@, %@}",
                    values: [5, 7], expectedCount: 1) {
            $0.intCol.contains(5...7)
        }

        assertQuery(predicate: "intCol BETWEEN {%@, %@}",
                    values: [5, 6], expectedCount: 1) {
            $0.intCol.contains(5...6)
        }

        assertQuery(predicate: "int8Col >= %@ && int8Col < %@",
                    values: [Int8(8), Int8(10)], expectedCount: 1) {
            $0.int8Col.contains(Int8(8)..<Int8(10))
        }

        assertQuery(predicate: "int8Col >= %@ && int8Col < %@",
                    values: [Int8(8), Int8(9)], expectedCount: 0) {
            $0.int8Col.contains(Int8(8)..<Int8(9))
        }

        assertQuery(predicate: "int8Col BETWEEN {%@, %@}",
                    values: [Int8(8), Int8(10)], expectedCount: 1) {
            $0.int8Col.contains(Int8(8)...Int8(10))
        }

        assertQuery(predicate: "int8Col BETWEEN {%@, %@}",
                    values: [Int8(8), Int8(9)], expectedCount: 1) {
            $0.int8Col.contains(Int8(8)...Int8(9))
        }

        assertQuery(predicate: "int16Col >= %@ && int16Col < %@",
                    values: [Int16(16), Int16(18)], expectedCount: 1) {
            $0.int16Col.contains(Int16(16)..<Int16(18))
        }

        assertQuery(predicate: "int16Col >= %@ && int16Col < %@",
                    values: [Int16(16), Int16(17)], expectedCount: 0) {
            $0.int16Col.contains(Int16(16)..<Int16(17))
        }

        assertQuery(predicate: "int16Col BETWEEN {%@, %@}",
                    values: [Int16(16), Int16(18)], expectedCount: 1) {
            $0.int16Col.contains(Int16(16)...Int16(18))
        }

        assertQuery(predicate: "int16Col BETWEEN {%@, %@}",
                    values: [Int16(16), Int16(17)], expectedCount: 1) {
            $0.int16Col.contains(Int16(16)...Int16(17))
        }

        assertQuery(predicate: "int32Col >= %@ && int32Col < %@",
                    values: [Int32(32), Int32(34)], expectedCount: 1) {
            $0.int32Col.contains(Int32(32)..<Int32(34))
        }

        assertQuery(predicate: "int32Col >= %@ && int32Col < %@",
                    values: [Int32(32), Int32(33)], expectedCount: 0) {
            $0.int32Col.contains(Int32(32)..<Int32(33))
        }

        assertQuery(predicate: "int32Col BETWEEN {%@, %@}",
                    values: [Int32(32), Int32(34)], expectedCount: 1) {
            $0.int32Col.contains(Int32(32)...Int32(34))
        }

        assertQuery(predicate: "int32Col BETWEEN {%@, %@}",
                    values: [Int32(32), Int32(33)], expectedCount: 1) {
            $0.int32Col.contains(Int32(32)...Int32(33))
        }

        assertQuery(predicate: "int64Col >= %@ && int64Col < %@",
                    values: [Int64(64), Int64(66)], expectedCount: 1) {
            $0.int64Col.contains(Int64(64)..<Int64(66))
        }

        assertQuery(predicate: "int64Col >= %@ && int64Col < %@",
                    values: [Int64(64), Int64(65)], expectedCount: 0) {
            $0.int64Col.contains(Int64(64)..<Int64(65))
        }

        assertQuery(predicate: "int64Col BETWEEN {%@, %@}",
                    values: [Int64(64), Int64(66)], expectedCount: 1) {
            $0.int64Col.contains(Int64(64)...Int64(66))
        }

        assertQuery(predicate: "int64Col BETWEEN {%@, %@}",
                    values: [Int64(64), Int64(65)], expectedCount: 1) {
            $0.int64Col.contains(Int64(64)...Int64(65))
        }

        assertQuery(predicate: "floatCol >= %@ && floatCol < %@",
                    values: [Float(5.55444333), Float(7.55444333)], expectedCount: 1) {
            $0.floatCol.contains(Float(5.55444333)..<Float(7.55444333))
        }

        assertQuery(predicate: "floatCol >= %@ && floatCol < %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 0) {
            $0.floatCol.contains(Float(5.55444333)..<Float(6.55444333))
        }

        assertQuery(predicate: "floatCol BETWEEN {%@, %@}",
                    values: [Float(5.55444333), Float(7.55444333)], expectedCount: 1) {
            $0.floatCol.contains(Float(5.55444333)...Float(7.55444333))
        }

        assertQuery(predicate: "floatCol BETWEEN {%@, %@}",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 1) {
            $0.floatCol.contains(Float(5.55444333)...Float(6.55444333))
        }

        assertQuery(predicate: "doubleCol >= %@ && doubleCol < %@",
                    values: [123.456, 345.678], expectedCount: 1) {
            $0.doubleCol.contains(123.456..<345.678)
        }

        assertQuery(predicate: "doubleCol >= %@ && doubleCol < %@",
                    values: [123.456, 234.567], expectedCount: 0) {
            $0.doubleCol.contains(123.456..<234.567)
        }

        assertQuery(predicate: "doubleCol BETWEEN {%@, %@}",
                    values: [123.456, 345.678], expectedCount: 1) {
            $0.doubleCol.contains(123.456...345.678)
        }

        assertQuery(predicate: "doubleCol BETWEEN {%@, %@}",
                    values: [123.456, 234.567], expectedCount: 1) {
            $0.doubleCol.contains(123.456...234.567)
        }

        assertQuery(predicate: "dateCol >= %@ && dateCol < %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.dateCol.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "dateCol >= %@ && dateCol < %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.dateCol.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "dateCol BETWEEN {%@, %@}",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.dateCol.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "dateCol BETWEEN {%@, %@}",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.dateCol.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "decimalCol >= %@ && decimalCol < %@",
                    values: [Decimal128(123.456), Decimal128(345.678)], expectedCount: 1) {
            $0.decimalCol.contains(Decimal128(123.456)..<Decimal128(345.678))
        }

        assertQuery(predicate: "decimalCol >= %@ && decimalCol < %@",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 0) {
            $0.decimalCol.contains(Decimal128(123.456)..<Decimal128(234.567))
        }

        assertQuery(predicate: "decimalCol BETWEEN {%@, %@}",
                    values: [Decimal128(123.456), Decimal128(345.678)], expectedCount: 1) {
            $0.decimalCol.contains(Decimal128(123.456)...Decimal128(345.678))
        }

        assertQuery(predicate: "decimalCol BETWEEN {%@, %@}",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 1) {
            $0.decimalCol.contains(Decimal128(123.456)...Decimal128(234.567))
        }

        assertQuery(predicate: "optIntCol >= %@ && optIntCol < %@",
                    values: [5, 7], expectedCount: 1) {
            $0.optIntCol.contains(5..<7)
        }

        assertQuery(predicate: "optIntCol >= %@ && optIntCol < %@",
                    values: [5, 6], expectedCount: 0) {
            $0.optIntCol.contains(5..<6)
        }

        assertQuery(predicate: "optIntCol BETWEEN {%@, %@}",
                    values: [5, 7], expectedCount: 1) {
            $0.optIntCol.contains(5...7)
        }

        assertQuery(predicate: "optIntCol BETWEEN {%@, %@}",
                    values: [5, 6], expectedCount: 1) {
            $0.optIntCol.contains(5...6)
        }

        assertQuery(predicate: "optInt8Col >= %@ && optInt8Col < %@",
                    values: [Int8(8), Int8(10)], expectedCount: 1) {
            $0.optInt8Col.contains(Int8(8)..<Int8(10))
        }

        assertQuery(predicate: "optInt8Col >= %@ && optInt8Col < %@",
                    values: [Int8(8), Int8(9)], expectedCount: 0) {
            $0.optInt8Col.contains(Int8(8)..<Int8(9))
        }

        assertQuery(predicate: "optInt8Col BETWEEN {%@, %@}",
                    values: [Int8(8), Int8(10)], expectedCount: 1) {
            $0.optInt8Col.contains(Int8(8)...Int8(10))
        }

        assertQuery(predicate: "optInt8Col BETWEEN {%@, %@}",
                    values: [Int8(8), Int8(9)], expectedCount: 1) {
            $0.optInt8Col.contains(Int8(8)...Int8(9))
        }

        assertQuery(predicate: "optInt16Col >= %@ && optInt16Col < %@",
                    values: [Int16(16), Int16(18)], expectedCount: 1) {
            $0.optInt16Col.contains(Int16(16)..<Int16(18))
        }

        assertQuery(predicate: "optInt16Col >= %@ && optInt16Col < %@",
                    values: [Int16(16), Int16(17)], expectedCount: 0) {
            $0.optInt16Col.contains(Int16(16)..<Int16(17))
        }

        assertQuery(predicate: "optInt16Col BETWEEN {%@, %@}",
                    values: [Int16(16), Int16(18)], expectedCount: 1) {
            $0.optInt16Col.contains(Int16(16)...Int16(18))
        }

        assertQuery(predicate: "optInt16Col BETWEEN {%@, %@}",
                    values: [Int16(16), Int16(17)], expectedCount: 1) {
            $0.optInt16Col.contains(Int16(16)...Int16(17))
        }

        assertQuery(predicate: "optInt32Col >= %@ && optInt32Col < %@",
                    values: [Int32(32), Int32(34)], expectedCount: 1) {
            $0.optInt32Col.contains(Int32(32)..<Int32(34))
        }

        assertQuery(predicate: "optInt32Col >= %@ && optInt32Col < %@",
                    values: [Int32(32), Int32(33)], expectedCount: 0) {
            $0.optInt32Col.contains(Int32(32)..<Int32(33))
        }

        assertQuery(predicate: "optInt32Col BETWEEN {%@, %@}",
                    values: [Int32(32), Int32(34)], expectedCount: 1) {
            $0.optInt32Col.contains(Int32(32)...Int32(34))
        }

        assertQuery(predicate: "optInt32Col BETWEEN {%@, %@}",
                    values: [Int32(32), Int32(33)], expectedCount: 1) {
            $0.optInt32Col.contains(Int32(32)...Int32(33))
        }

        assertQuery(predicate: "optInt64Col >= %@ && optInt64Col < %@",
                    values: [Int64(64), Int64(66)], expectedCount: 1) {
            $0.optInt64Col.contains(Int64(64)..<Int64(66))
        }

        assertQuery(predicate: "optInt64Col >= %@ && optInt64Col < %@",
                    values: [Int64(64), Int64(65)], expectedCount: 0) {
            $0.optInt64Col.contains(Int64(64)..<Int64(65))
        }

        assertQuery(predicate: "optInt64Col BETWEEN {%@, %@}",
                    values: [Int64(64), Int64(66)], expectedCount: 1) {
            $0.optInt64Col.contains(Int64(64)...Int64(66))
        }

        assertQuery(predicate: "optInt64Col BETWEEN {%@, %@}",
                    values: [Int64(64), Int64(65)], expectedCount: 1) {
            $0.optInt64Col.contains(Int64(64)...Int64(65))
        }

        assertQuery(predicate: "optFloatCol >= %@ && optFloatCol < %@",
                    values: [Float(5.55444333), Float(7.55444333)], expectedCount: 1) {
            $0.optFloatCol.contains(Float(5.55444333)..<Float(7.55444333))
        }

        assertQuery(predicate: "optFloatCol >= %@ && optFloatCol < %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 0) {
            $0.optFloatCol.contains(Float(5.55444333)..<Float(6.55444333))
        }

        assertQuery(predicate: "optFloatCol BETWEEN {%@, %@}",
                    values: [Float(5.55444333), Float(7.55444333)], expectedCount: 1) {
            $0.optFloatCol.contains(Float(5.55444333)...Float(7.55444333))
        }

        assertQuery(predicate: "optFloatCol BETWEEN {%@, %@}",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 1) {
            $0.optFloatCol.contains(Float(5.55444333)...Float(6.55444333))
        }

        assertQuery(predicate: "optDoubleCol >= %@ && optDoubleCol < %@",
                    values: [123.456, 345.678], expectedCount: 1) {
            $0.optDoubleCol.contains(123.456..<345.678)
        }

        assertQuery(predicate: "optDoubleCol >= %@ && optDoubleCol < %@",
                    values: [123.456, 234.567], expectedCount: 0) {
            $0.optDoubleCol.contains(123.456..<234.567)
        }

        assertQuery(predicate: "optDoubleCol BETWEEN {%@, %@}",
                    values: [123.456, 345.678], expectedCount: 1) {
            $0.optDoubleCol.contains(123.456...345.678)
        }

        assertQuery(predicate: "optDoubleCol BETWEEN {%@, %@}",
                    values: [123.456, 234.567], expectedCount: 1) {
            $0.optDoubleCol.contains(123.456...234.567)
        }

        assertQuery(predicate: "optDateCol >= %@ && optDateCol < %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.optDateCol.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "optDateCol >= %@ && optDateCol < %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.optDateCol.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "optDateCol BETWEEN {%@, %@}",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.optDateCol.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "optDateCol BETWEEN {%@, %@}",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.optDateCol.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "optDecimalCol >= %@ && optDecimalCol < %@",
                    values: [Decimal128(123.456), Decimal128(345.678)], expectedCount: 1) {
            $0.optDecimalCol.contains(Decimal128(123.456)..<Decimal128(345.678))
        }

        assertQuery(predicate: "optDecimalCol >= %@ && optDecimalCol < %@",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 0) {
            $0.optDecimalCol.contains(Decimal128(123.456)..<Decimal128(234.567))
        }

        assertQuery(predicate: "optDecimalCol BETWEEN {%@, %@}",
                    values: [Decimal128(123.456), Decimal128(345.678)], expectedCount: 1) {
            $0.optDecimalCol.contains(Decimal128(123.456)...Decimal128(345.678))
        }

        assertQuery(predicate: "optDecimalCol BETWEEN {%@, %@}",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 1) {
            $0.optDecimalCol.contains(Decimal128(123.456)...Decimal128(234.567))
        }

    }

    // MARK: - Strings

    func testStringStartsWith() {
        assertQuery(predicate: "stringCol BEGINSWITH %@",
                    values: ["fo"], expectedCount: 0) {
            $0.stringCol.starts(with: "fo")
        }

        assertQuery(predicate: "stringCol BEGINSWITH %@",
                    values: ["fo"], expectedCount: 0) {
            $0.stringCol.starts(with: "fo", options: [])
        }

        assertQuery(predicate: "stringCol BEGINSWITH[c] %@",
                    values: ["fo"], expectedCount: 1) {
            $0.stringCol.starts(with: "fo", options: [.caseInsensitive])
        }

        assertQuery(predicate: "stringCol BEGINSWITH[d] %@",
                    values: ["fo"], expectedCount: 0) {
            $0.stringCol.starts(with: "fo", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "stringCol BEGINSWITH[cd] %@",
                    values: ["fo"], expectedCount: 1) {
            $0.stringCol.starts(with: "fo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT stringCol BEGINSWITH[cd] %@",
                    values: ["fo"], expectedCount: 0) {
            !$0.stringCol.starts(with: "fo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "optStringCol BEGINSWITH %@",
                    values: ["fo"], expectedCount: 0) {
            $0.optStringCol.starts(with: "fo")
        }

        assertQuery(predicate: "optStringCol BEGINSWITH %@",
                    values: ["fo"], expectedCount: 0) {
            $0.optStringCol.starts(with: "fo", options: [])
        }

        assertQuery(predicate: "optStringCol BEGINSWITH[c] %@",
                    values: ["fo"], expectedCount: 1) {
            $0.optStringCol.starts(with: "fo", options: [.caseInsensitive])
        }

        assertQuery(predicate: "optStringCol BEGINSWITH[d] %@",
                    values: ["fo"], expectedCount: 0) {
            $0.optStringCol.starts(with: "fo", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "optStringCol BEGINSWITH[cd] %@",
                    values: ["fo"], expectedCount: 1) {
            $0.optStringCol.starts(with: "fo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol BEGINSWITH[cd] %@",
                    values: ["fo"], expectedCount: 0) {
            !$0.optStringCol.starts(with: "fo", options: [.caseInsensitive, .diacriticInsensitive])
        }

    }

    func testStringEndsWith() {
        assertQuery(predicate: "stringCol ENDSWITH %@",
                    values: ["oo"], expectedCount: 0) {
            $0.stringCol.ends(with: "oo")
        }

        assertQuery(predicate: "stringCol ENDSWITH %@",
                    values: ["oo"], expectedCount: 0) {
            $0.stringCol.ends(with: "oo", options: [])
        }

        assertQuery(predicate: "stringCol ENDSWITH[c] %@",
                    values: ["oo"], expectedCount: 0) {
            $0.stringCol.ends(with: "oo", options: [.caseInsensitive])
        }

        assertQuery(predicate: "stringCol ENDSWITH[d] %@",
                    values: ["oo"], expectedCount: 1) {
            $0.stringCol.ends(with: "oo", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "stringCol ENDSWITH[cd] %@",
                    values: ["oo"], expectedCount: 1) {
            $0.stringCol.ends(with: "oo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT stringCol ENDSWITH[cd] %@",
                    values: ["oo"], expectedCount: 0) {
            !$0.stringCol.ends(with: "oo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "optStringCol ENDSWITH %@",
                    values: ["oo"], expectedCount: 0) {
            $0.optStringCol.ends(with: "oo")
        }

        assertQuery(predicate: "optStringCol ENDSWITH %@",
                    values: ["oo"], expectedCount: 0) {
            $0.optStringCol.ends(with: "oo", options: [])
        }

        assertQuery(predicate: "optStringCol ENDSWITH[c] %@",
                    values: ["oo"], expectedCount: 0) {
            $0.optStringCol.ends(with: "oo", options: [.caseInsensitive])
        }

        assertQuery(predicate: "optStringCol ENDSWITH[d] %@",
                    values: ["oo"], expectedCount: 1) {
            $0.optStringCol.ends(with: "oo", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "optStringCol ENDSWITH[cd] %@",
                    values: ["oo"], expectedCount: 1) {
            $0.optStringCol.ends(with: "oo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol ENDSWITH[cd] %@",
                    values: ["oo"], expectedCount: 0) {
            !$0.optStringCol.ends(with: "oo", options: [.caseInsensitive, .diacriticInsensitive])
        }

    }

    func testStringLike() {
        assertQuery(predicate: "stringCol LIKE %@",
                                values: ["Foó"], expectedCount: 1) {
            $0.stringCol.like("Foó")
        }

        assertQuery(predicate: "stringCol LIKE[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.like("Foó", caseInsensitive: true)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.like("Foó", caseInsensitive: false)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["f*"], expectedCount: 0) {
            $0.stringCol.like("f*")
        }

        assertQuery(predicate: "stringCol LIKE[c] %@",
                    values: ["f*"], expectedCount: 1) {
            $0.stringCol.like("f*", caseInsensitive: true)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["f*"], expectedCount: 0) {
            $0.stringCol.like("f*", caseInsensitive: false)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["*ó"], expectedCount: 1) {
            $0.stringCol.like("*ó")
        }

        assertQuery(predicate: "stringCol LIKE[c] %@",
                    values: ["*ó"], expectedCount: 1) {
            $0.stringCol.like("*ó", caseInsensitive: true)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["*ó"], expectedCount: 1) {
            $0.stringCol.like("*ó", caseInsensitive: false)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["f?ó"], expectedCount: 0) {
            $0.stringCol.like("f?ó")
        }

        assertQuery(predicate: "stringCol LIKE[c] %@",
                    values: ["f?ó"], expectedCount: 1) {
            $0.stringCol.like("f?ó", caseInsensitive: true)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["f?ó"], expectedCount: 0) {
            $0.stringCol.like("f?ó", caseInsensitive: false)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["f*ó"], expectedCount: 0) {
            $0.stringCol.like("f*ó")
        }

        assertQuery(predicate: "stringCol LIKE[c] %@",
                    values: ["f*ó"], expectedCount: 1) {
            $0.stringCol.like("f*ó", caseInsensitive: true)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["f*ó"], expectedCount: 0) {
            $0.stringCol.like("f*ó", caseInsensitive: false)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["f??ó"], expectedCount: 0) {
            $0.stringCol.like("f??ó")
        }

        assertQuery(predicate: "stringCol LIKE[c] %@",
                    values: ["f??ó"], expectedCount: 0) {
            $0.stringCol.like("f??ó", caseInsensitive: true)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["f??ó"], expectedCount: 0) {
            $0.stringCol.like("f??ó", caseInsensitive: false)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["*o*"], expectedCount: 1) {
            $0.stringCol.like("*o*")
        }

        assertQuery(predicate: "stringCol LIKE[c] %@",
                    values: ["*O*"], expectedCount: 1) {
            $0.stringCol.like("*O*", caseInsensitive: true)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["*O*"], expectedCount: 0) {
            $0.stringCol.like("*O*", caseInsensitive: false)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["?o?"], expectedCount: 1) {
            $0.stringCol.like("?o?")
        }

        assertQuery(predicate: "stringCol LIKE[c] %@",
                    values: ["?O?"], expectedCount: 1) {
            $0.stringCol.like("?O?", caseInsensitive: true)
        }

        assertQuery(predicate: "stringCol LIKE %@",
                    values: ["?O?"], expectedCount: 0) {
            $0.stringCol.like("?O?", caseInsensitive: false)
        }

        assertQuery(predicate: "NOT stringCol LIKE %@",
                    values: ["?O?"], expectedCount: 1) {
            !$0.stringCol.like("?O?", caseInsensitive: false)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                                values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.like("Foó")
        }

        assertQuery(predicate: "optStringCol LIKE[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.like("Foó", caseInsensitive: true)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.like("Foó", caseInsensitive: false)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["f*"], expectedCount: 0) {
            $0.optStringCol.like("f*")
        }

        assertQuery(predicate: "optStringCol LIKE[c] %@",
                    values: ["f*"], expectedCount: 1) {
            $0.optStringCol.like("f*", caseInsensitive: true)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["f*"], expectedCount: 0) {
            $0.optStringCol.like("f*", caseInsensitive: false)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["*ó"], expectedCount: 1) {
            $0.optStringCol.like("*ó")
        }

        assertQuery(predicate: "optStringCol LIKE[c] %@",
                    values: ["*ó"], expectedCount: 1) {
            $0.optStringCol.like("*ó", caseInsensitive: true)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["*ó"], expectedCount: 1) {
            $0.optStringCol.like("*ó", caseInsensitive: false)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["f?ó"], expectedCount: 0) {
            $0.optStringCol.like("f?ó")
        }

        assertQuery(predicate: "optStringCol LIKE[c] %@",
                    values: ["f?ó"], expectedCount: 1) {
            $0.optStringCol.like("f?ó", caseInsensitive: true)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["f?ó"], expectedCount: 0) {
            $0.optStringCol.like("f?ó", caseInsensitive: false)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["f*ó"], expectedCount: 0) {
            $0.optStringCol.like("f*ó")
        }

        assertQuery(predicate: "optStringCol LIKE[c] %@",
                    values: ["f*ó"], expectedCount: 1) {
            $0.optStringCol.like("f*ó", caseInsensitive: true)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["f*ó"], expectedCount: 0) {
            $0.optStringCol.like("f*ó", caseInsensitive: false)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["f??ó"], expectedCount: 0) {
            $0.optStringCol.like("f??ó")
        }

        assertQuery(predicate: "optStringCol LIKE[c] %@",
                    values: ["f??ó"], expectedCount: 0) {
            $0.optStringCol.like("f??ó", caseInsensitive: true)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["f??ó"], expectedCount: 0) {
            $0.optStringCol.like("f??ó", caseInsensitive: false)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["*o*"], expectedCount: 1) {
            $0.optStringCol.like("*o*")
        }

        assertQuery(predicate: "optStringCol LIKE[c] %@",
                    values: ["*O*"], expectedCount: 1) {
            $0.optStringCol.like("*O*", caseInsensitive: true)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["*O*"], expectedCount: 0) {
            $0.optStringCol.like("*O*", caseInsensitive: false)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["?o?"], expectedCount: 1) {
            $0.optStringCol.like("?o?")
        }

        assertQuery(predicate: "optStringCol LIKE[c] %@",
                    values: ["?O?"], expectedCount: 1) {
            $0.optStringCol.like("?O?", caseInsensitive: true)
        }

        assertQuery(predicate: "optStringCol LIKE %@",
                    values: ["?O?"], expectedCount: 0) {
            $0.optStringCol.like("?O?", caseInsensitive: false)
        }

        assertQuery(predicate: "NOT optStringCol LIKE %@",
                    values: ["?O?"], expectedCount: 1) {
            !$0.optStringCol.like("?O?", caseInsensitive: false)
        }

    }

    func testStringContains() {
        assertQuery(predicate: "stringCol CONTAINS %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.contains("Foó")
        }

        assertQuery(predicate: "stringCol CONTAINS %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.contains("Foó", options: [])
        }

        assertQuery(predicate: "stringCol CONTAINS[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.contains("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "stringCol CONTAINS[d] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.contains("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "stringCol CONTAINS[cd] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.contains("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "optStringCol CONTAINS %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.contains("Foó")
        }

        assertQuery(predicate: "optStringCol CONTAINS %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.contains("Foó", options: [])
        }

        assertQuery(predicate: "optStringCol CONTAINS[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.contains("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "optStringCol CONTAINS[d] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.contains("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "optStringCol CONTAINS[cd] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.contains("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

    }

    func testStringNotContains() {
        assertQuery(predicate: "NOT stringCol CONTAINS %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.stringCol.contains("Foó")
        }

        assertQuery(predicate: "NOT stringCol CONTAINS %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.stringCol.contains("Foó", options: [])
        }

        assertQuery(predicate: "NOT stringCol CONTAINS[c] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.stringCol.contains("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "NOT stringCol CONTAINS[d] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.stringCol.contains("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "NOT stringCol CONTAINS[cd] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.stringCol.contains("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol CONTAINS %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.optStringCol.contains("Foó")
        }

        assertQuery(predicate: "NOT optStringCol CONTAINS %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.optStringCol.contains("Foó", options: [])
        }

        assertQuery(predicate: "NOT optStringCol CONTAINS[c] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.optStringCol.contains("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol CONTAINS[d] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.optStringCol.contains("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol CONTAINS[cd] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.optStringCol.contains("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

    }

    func testStringEquals() {
        assertQuery(predicate: "stringCol == %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.equals("Foó")
        }

        assertQuery(predicate: "stringCol == %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.equals("Foó", options: [])
        }

        assertQuery(predicate: "stringCol ==[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.equals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "stringCol ==[d] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.equals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "stringCol ==[cd] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.stringCol.equals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT stringCol == %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.stringCol.equals("Foó")
        }

        assertQuery(predicate: "NOT stringCol == %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.stringCol.equals("Foó", options: [])
        }

        assertQuery(predicate: "NOT stringCol ==[c] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.stringCol.equals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "NOT stringCol ==[d] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.stringCol.equals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "NOT stringCol ==[cd] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.stringCol.equals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "optStringCol == %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.equals("Foó")
        }

        assertQuery(predicate: "optStringCol == %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.equals("Foó", options: [])
        }

        assertQuery(predicate: "optStringCol ==[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.equals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "optStringCol ==[d] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.equals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "optStringCol ==[cd] %@",
                    values: ["Foó"], expectedCount: 1) {
            $0.optStringCol.equals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol == %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.optStringCol.equals("Foó")
        }

        assertQuery(predicate: "NOT optStringCol == %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.optStringCol.equals("Foó", options: [])
        }

        assertQuery(predicate: "NOT optStringCol ==[c] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.optStringCol.equals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol ==[d] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.optStringCol.equals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol ==[cd] %@",
                    values: ["Foó"], expectedCount: 0) {
            !$0.optStringCol.equals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

    }

    func testStringNotEquals() {
        assertQuery(predicate: "stringCol != %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.stringCol.notEquals("Foó")
        }

        assertQuery(predicate: "stringCol != %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.stringCol.notEquals("Foó", options: [])
        }

        assertQuery(predicate: "stringCol !=[c] %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.stringCol.notEquals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "stringCol !=[d] %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.stringCol.notEquals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "stringCol !=[cd] %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.stringCol.notEquals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT stringCol != %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.stringCol.notEquals("Foó")
        }

        assertQuery(predicate: "NOT stringCol != %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.stringCol.notEquals("Foó", options: [])
        }

        assertQuery(predicate: "NOT stringCol !=[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.stringCol.notEquals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "NOT stringCol !=[d] %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.stringCol.notEquals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "NOT stringCol !=[cd] %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.stringCol.notEquals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "optStringCol != %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.optStringCol.notEquals("Foó")
        }

        assertQuery(predicate: "optStringCol != %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.optStringCol.notEquals("Foó", options: [])
        }

        assertQuery(predicate: "optStringCol !=[c] %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.optStringCol.notEquals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "optStringCol !=[d] %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.optStringCol.notEquals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "optStringCol !=[cd] %@",
                    values: ["Foó"], expectedCount: 0) {
            $0.optStringCol.notEquals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol != %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.optStringCol.notEquals("Foó")
        }

        assertQuery(predicate: "NOT optStringCol != %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.optStringCol.notEquals("Foó", options: [])
        }

        assertQuery(predicate: "NOT optStringCol !=[c] %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.optStringCol.notEquals("Foó", options: [.caseInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol !=[d] %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.optStringCol.notEquals("Foó", options: [.diacriticInsensitive])
        }

        assertQuery(predicate: "NOT optStringCol !=[cd] %@",
                    values: ["Foó"], expectedCount: 1) {
            !$0.optStringCol.notEquals("Foó", options: [.caseInsensitive, .diacriticInsensitive])
        }

    }

    // MARK: - Data

    func testBinarySearchQueries() {
        assertQuery(predicate: "binaryCol BEGINSWITH %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.binaryCol.starts(with: Data(count: 28))
        }

        assertQuery(predicate: "NOT binaryCol BEGINSWITH %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            !$0.binaryCol.starts(with: Data(count: 28))
        }

        assertQuery(predicate: "binaryCol ENDSWITH %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.binaryCol.ends(with: Data(count: 28))
        }

        assertQuery(predicate: "NOT binaryCol ENDSWITH %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            !$0.binaryCol.ends(with: Data(count: 28))
        }

        assertQuery(predicate: "binaryCol CONTAINS %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.binaryCol.contains(Data(count: 28))
        }

        assertQuery(predicate: "NOT binaryCol CONTAINS %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            !$0.binaryCol.contains(Data(count: 28))
        }

        assertQuery(predicate: "binaryCol == %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            $0.binaryCol.equals(Data(count: 28))
        }

        assertQuery(predicate: "NOT binaryCol == %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            !$0.binaryCol.equals(Data(count: 28))
        }

        assertQuery(predicate: "binaryCol != %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.binaryCol.notEquals(Data(count: 28))
        }

        assertQuery(predicate: "NOT binaryCol != %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            !$0.binaryCol.notEquals(Data(count: 28))
        }

        assertQuery(predicate: "binaryCol BEGINSWITH %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.binaryCol.starts(with: Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "binaryCol ENDSWITH %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.binaryCol.ends(with: Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "binaryCol CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.binaryCol.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT binaryCol CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            !$0.binaryCol.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "binaryCol CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.binaryCol.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT binaryCol CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            !$0.binaryCol.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "binaryCol == %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.binaryCol.equals(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT binaryCol == %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            !$0.binaryCol.equals(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "binaryCol != %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            $0.binaryCol.notEquals(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT binaryCol != %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            !$0.binaryCol.notEquals(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "optBinaryCol BEGINSWITH %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.optBinaryCol.starts(with: Data(count: 28))
        }

        assertQuery(predicate: "NOT optBinaryCol BEGINSWITH %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            !$0.optBinaryCol.starts(with: Data(count: 28))
        }

        assertQuery(predicate: "optBinaryCol ENDSWITH %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.optBinaryCol.ends(with: Data(count: 28))
        }

        assertQuery(predicate: "NOT optBinaryCol ENDSWITH %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            !$0.optBinaryCol.ends(with: Data(count: 28))
        }

        assertQuery(predicate: "optBinaryCol CONTAINS %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.optBinaryCol.contains(Data(count: 28))
        }

        assertQuery(predicate: "NOT optBinaryCol CONTAINS %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            !$0.optBinaryCol.contains(Data(count: 28))
        }

        assertQuery(predicate: "optBinaryCol == %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            $0.optBinaryCol.equals(Data(count: 28))
        }

        assertQuery(predicate: "NOT optBinaryCol == %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            !$0.optBinaryCol.equals(Data(count: 28))
        }

        assertQuery(predicate: "optBinaryCol != %@",
                    values: [Data(count: 28)], expectedCount: 1) {
            $0.optBinaryCol.notEquals(Data(count: 28))
        }

        assertQuery(predicate: "NOT optBinaryCol != %@",
                    values: [Data(count: 28)], expectedCount: 0) {
            !$0.optBinaryCol.notEquals(Data(count: 28))
        }

        assertQuery(predicate: "optBinaryCol BEGINSWITH %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.optBinaryCol.starts(with: Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "optBinaryCol ENDSWITH %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.optBinaryCol.ends(with: Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "optBinaryCol CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.optBinaryCol.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT optBinaryCol CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            !$0.optBinaryCol.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "optBinaryCol CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.optBinaryCol.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT optBinaryCol CONTAINS %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            !$0.optBinaryCol.contains(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "optBinaryCol == %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            $0.optBinaryCol.equals(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT optBinaryCol == %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            !$0.optBinaryCol.equals(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "optBinaryCol != %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 1) {
            $0.optBinaryCol.notEquals(Data(repeating: 1, count: 28))
        }

        assertQuery(predicate: "NOT optBinaryCol != %@",
                    values: [Data(repeating: 1, count: 28)], expectedCount: 0) {
            !$0.optBinaryCol.notEquals(Data(repeating: 1, count: 28))
        }

    }

    // MARK: - Array/Set

    func testListContainsElement() {
        assertQuery(predicate: "%@ IN arrayBool", values: [true], expectedCount: 1) {
            $0.arrayBool.contains(true)
        }
        assertQuery(predicate: "%@ IN arrayBool", values: [false], expectedCount: 0) {
            $0.arrayBool.contains(false)
        }

        assertQuery(predicate: "%@ IN arrayInt", values: [1], expectedCount: 1) {
            $0.arrayInt.contains(1)
        }
        assertQuery(predicate: "%@ IN arrayInt", values: [3], expectedCount: 0) {
            $0.arrayInt.contains(3)
        }

        assertQuery(predicate: "%@ IN arrayInt8", values: [Int8(8)], expectedCount: 1) {
            $0.arrayInt8.contains(Int8(8))
        }
        assertQuery(predicate: "%@ IN arrayInt8", values: [Int8(10)], expectedCount: 0) {
            $0.arrayInt8.contains(Int8(10))
        }

        assertQuery(predicate: "%@ IN arrayInt16", values: [Int16(16)], expectedCount: 1) {
            $0.arrayInt16.contains(Int16(16))
        }
        assertQuery(predicate: "%@ IN arrayInt16", values: [Int16(18)], expectedCount: 0) {
            $0.arrayInt16.contains(Int16(18))
        }

        assertQuery(predicate: "%@ IN arrayInt32", values: [Int32(32)], expectedCount: 1) {
            $0.arrayInt32.contains(Int32(32))
        }
        assertQuery(predicate: "%@ IN arrayInt32", values: [Int32(34)], expectedCount: 0) {
            $0.arrayInt32.contains(Int32(34))
        }

        assertQuery(predicate: "%@ IN arrayInt64", values: [Int64(64)], expectedCount: 1) {
            $0.arrayInt64.contains(Int64(64))
        }
        assertQuery(predicate: "%@ IN arrayInt64", values: [Int64(66)], expectedCount: 0) {
            $0.arrayInt64.contains(Int64(66))
        }

        assertQuery(predicate: "%@ IN arrayFloat", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayFloat.contains(Float(5.55444333))
        }
        assertQuery(predicate: "%@ IN arrayFloat", values: [Float(7.55444333)], expectedCount: 0) {
            $0.arrayFloat.contains(Float(7.55444333))
        }

        assertQuery(predicate: "%@ IN arrayDouble", values: [123.456], expectedCount: 1) {
            $0.arrayDouble.contains(123.456)
        }
        assertQuery(predicate: "%@ IN arrayDouble", values: [345.678], expectedCount: 0) {
            $0.arrayDouble.contains(345.678)
        }

        assertQuery(predicate: "%@ IN arrayString", values: ["Foo"], expectedCount: 1) {
            $0.arrayString.contains("Foo")
        }
        assertQuery(predicate: "%@ IN arrayString", values: ["Baz"], expectedCount: 0) {
            $0.arrayString.contains("Baz")
        }

        assertQuery(predicate: "%@ IN arrayBinary", values: [Data(count: 64)], expectedCount: 1) {
            $0.arrayBinary.contains(Data(count: 64))
        }
        assertQuery(predicate: "%@ IN arrayBinary", values: [Data(count: 256)], expectedCount: 0) {
            $0.arrayBinary.contains(Data(count: 256))
        }

        assertQuery(predicate: "%@ IN arrayDate", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayDate.contains(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(predicate: "%@ IN arrayDate", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 0) {
            $0.arrayDate.contains(Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "%@ IN arrayDecimal", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayDecimal.contains(Decimal128(123.456))
        }
        assertQuery(predicate: "%@ IN arrayDecimal", values: [Decimal128(345.678)], expectedCount: 0) {
            $0.arrayDecimal.contains(Decimal128(345.678))
        }

        assertQuery(predicate: "%@ IN arrayObjectId", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.arrayObjectId.contains(ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(predicate: "%@ IN arrayObjectId", values: [ObjectId("61184062c1d8f096a3695044")], expectedCount: 0) {
            $0.arrayObjectId.contains(ObjectId("61184062c1d8f096a3695044"))
        }

        assertQuery(predicate: "%@ IN arrayUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.arrayUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(predicate: "%@ IN arrayUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!], expectedCount: 0) {
            $0.arrayUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!)
        }

        assertQuery(predicate: "%@ IN arrayAny", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.arrayAny.contains(AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")))
        }
        assertQuery(predicate: "%@ IN arrayAny", values: [123], expectedCount: 0) {
            $0.arrayAny.contains(AnyRealmValue.int(123))
        }

        assertQuery(predicate: "%@ IN arrayOptBool", values: [true], expectedCount: 1) {
            $0.arrayOptBool.contains(true)
        }
        assertQuery(predicate: "%@ IN arrayOptBool", values: [false], expectedCount: 0) {
            $0.arrayOptBool.contains(false)
        }

        assertQuery(predicate: "%@ IN arrayOptInt", values: [1], expectedCount: 1) {
            $0.arrayOptInt.contains(1)
        }
        assertQuery(predicate: "%@ IN arrayOptInt", values: [3], expectedCount: 0) {
            $0.arrayOptInt.contains(3)
        }

        assertQuery(predicate: "%@ IN arrayOptInt8", values: [Int8(8)], expectedCount: 1) {
            $0.arrayOptInt8.contains(Int8(8))
        }
        assertQuery(predicate: "%@ IN arrayOptInt8", values: [Int8(10)], expectedCount: 0) {
            $0.arrayOptInt8.contains(Int8(10))
        }

        assertQuery(predicate: "%@ IN arrayOptInt16", values: [Int16(16)], expectedCount: 1) {
            $0.arrayOptInt16.contains(Int16(16))
        }
        assertQuery(predicate: "%@ IN arrayOptInt16", values: [Int16(18)], expectedCount: 0) {
            $0.arrayOptInt16.contains(Int16(18))
        }

        assertQuery(predicate: "%@ IN arrayOptInt32", values: [Int32(32)], expectedCount: 1) {
            $0.arrayOptInt32.contains(Int32(32))
        }
        assertQuery(predicate: "%@ IN arrayOptInt32", values: [Int32(34)], expectedCount: 0) {
            $0.arrayOptInt32.contains(Int32(34))
        }

        assertQuery(predicate: "%@ IN arrayOptInt64", values: [Int64(64)], expectedCount: 1) {
            $0.arrayOptInt64.contains(Int64(64))
        }
        assertQuery(predicate: "%@ IN arrayOptInt64", values: [Int64(66)], expectedCount: 0) {
            $0.arrayOptInt64.contains(Int64(66))
        }

        assertQuery(predicate: "%@ IN arrayOptFloat", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayOptFloat.contains(Float(5.55444333))
        }
        assertQuery(predicate: "%@ IN arrayOptFloat", values: [Float(7.55444333)], expectedCount: 0) {
            $0.arrayOptFloat.contains(Float(7.55444333))
        }

        assertQuery(predicate: "%@ IN arrayOptDouble", values: [123.456], expectedCount: 1) {
            $0.arrayOptDouble.contains(123.456)
        }
        assertQuery(predicate: "%@ IN arrayOptDouble", values: [345.678], expectedCount: 0) {
            $0.arrayOptDouble.contains(345.678)
        }

        assertQuery(predicate: "%@ IN arrayOptString", values: ["Foo"], expectedCount: 1) {
            $0.arrayOptString.contains("Foo")
        }
        assertQuery(predicate: "%@ IN arrayOptString", values: ["Baz"], expectedCount: 0) {
            $0.arrayOptString.contains("Baz")
        }

        assertQuery(predicate: "%@ IN arrayOptBinary", values: [Data(count: 64)], expectedCount: 1) {
            $0.arrayOptBinary.contains(Data(count: 64))
        }
        assertQuery(predicate: "%@ IN arrayOptBinary", values: [Data(count: 256)], expectedCount: 0) {
            $0.arrayOptBinary.contains(Data(count: 256))
        }

        assertQuery(predicate: "%@ IN arrayOptDate", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayOptDate.contains(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(predicate: "%@ IN arrayOptDate", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 0) {
            $0.arrayOptDate.contains(Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "%@ IN arrayOptDecimal", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayOptDecimal.contains(Decimal128(123.456))
        }
        assertQuery(predicate: "%@ IN arrayOptDecimal", values: [Decimal128(345.678)], expectedCount: 0) {
            $0.arrayOptDecimal.contains(Decimal128(345.678))
        }

        assertQuery(predicate: "%@ IN arrayOptUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.arrayOptUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(predicate: "%@ IN arrayOptUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!], expectedCount: 0) {
            $0.arrayOptUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!)
        }

        assertQuery(predicate: "%@ IN arrayOptObjectId", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.arrayOptObjectId.contains(ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(predicate: "%@ IN arrayOptObjectId", values: [ObjectId("61184062c1d8f096a3695044")], expectedCount: 0) {
            $0.arrayOptObjectId.contains(ObjectId("61184062c1d8f096a3695044"))
        }

        assertQuery(predicate: "%@ IN arrayOptBool", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptBool.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptInt", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptInt.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptInt8", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptInt8.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptInt16", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptInt16.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptInt32", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptInt32.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptInt64", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptInt64.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptFloat", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptFloat.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptDouble", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptDouble.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptString", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptString.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptBinary", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptBinary.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptDate", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptDate.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptDecimal", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptDecimal.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptUuid", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptUuid.contains(nil)
        }

        assertQuery(predicate: "%@ IN arrayOptObjectId", values: [NSNull()], expectedCount: 0) {
            $0.arrayOptObjectId.contains(nil)
        }

    }

    func testListNotContainsElement() {
        assertQuery(predicate: "NOT %@ IN arrayBool", values: [true], expectedCount: 0) {
            !$0.arrayBool.contains(true)
        }
        assertQuery(predicate: "NOT %@ IN arrayBool", values: [false], expectedCount: 1) {
            !$0.arrayBool.contains(false)
        }

        assertQuery(predicate: "NOT %@ IN arrayInt", values: [1], expectedCount: 0) {
            !$0.arrayInt.contains(1)
        }
        assertQuery(predicate: "NOT %@ IN arrayInt", values: [3], expectedCount: 1) {
            !$0.arrayInt.contains(3)
        }

        assertQuery(predicate: "NOT %@ IN arrayInt8", values: [Int8(8)], expectedCount: 0) {
            !$0.arrayInt8.contains(Int8(8))
        }
        assertQuery(predicate: "NOT %@ IN arrayInt8", values: [Int8(10)], expectedCount: 1) {
            !$0.arrayInt8.contains(Int8(10))
        }

        assertQuery(predicate: "NOT %@ IN arrayInt16", values: [Int16(16)], expectedCount: 0) {
            !$0.arrayInt16.contains(Int16(16))
        }
        assertQuery(predicate: "NOT %@ IN arrayInt16", values: [Int16(18)], expectedCount: 1) {
            !$0.arrayInt16.contains(Int16(18))
        }

        assertQuery(predicate: "NOT %@ IN arrayInt32", values: [Int32(32)], expectedCount: 0) {
            !$0.arrayInt32.contains(Int32(32))
        }
        assertQuery(predicate: "NOT %@ IN arrayInt32", values: [Int32(34)], expectedCount: 1) {
            !$0.arrayInt32.contains(Int32(34))
        }

        assertQuery(predicate: "NOT %@ IN arrayInt64", values: [Int64(64)], expectedCount: 0) {
            !$0.arrayInt64.contains(Int64(64))
        }
        assertQuery(predicate: "NOT %@ IN arrayInt64", values: [Int64(66)], expectedCount: 1) {
            !$0.arrayInt64.contains(Int64(66))
        }

        assertQuery(predicate: "NOT %@ IN arrayFloat", values: [Float(5.55444333)], expectedCount: 0) {
            !$0.arrayFloat.contains(Float(5.55444333))
        }
        assertQuery(predicate: "NOT %@ IN arrayFloat", values: [Float(7.55444333)], expectedCount: 1) {
            !$0.arrayFloat.contains(Float(7.55444333))
        }

        assertQuery(predicate: "NOT %@ IN arrayDouble", values: [123.456], expectedCount: 0) {
            !$0.arrayDouble.contains(123.456)
        }
        assertQuery(predicate: "NOT %@ IN arrayDouble", values: [345.678], expectedCount: 1) {
            !$0.arrayDouble.contains(345.678)
        }

        assertQuery(predicate: "NOT %@ IN arrayString", values: ["Foo"], expectedCount: 0) {
            !$0.arrayString.contains("Foo")
        }
        assertQuery(predicate: "NOT %@ IN arrayString", values: ["Baz"], expectedCount: 1) {
            !$0.arrayString.contains("Baz")
        }

        assertQuery(predicate: "NOT %@ IN arrayBinary", values: [Data(count: 64)], expectedCount: 0) {
            !$0.arrayBinary.contains(Data(count: 64))
        }
        assertQuery(predicate: "NOT %@ IN arrayBinary", values: [Data(count: 256)], expectedCount: 1) {
            !$0.arrayBinary.contains(Data(count: 256))
        }

        assertQuery(predicate: "NOT %@ IN arrayDate", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            !$0.arrayDate.contains(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(predicate: "NOT %@ IN arrayDate", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            !$0.arrayDate.contains(Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "NOT %@ IN arrayDecimal", values: [Decimal128(123.456)], expectedCount: 0) {
            !$0.arrayDecimal.contains(Decimal128(123.456))
        }
        assertQuery(predicate: "NOT %@ IN arrayDecimal", values: [Decimal128(345.678)], expectedCount: 1) {
            !$0.arrayDecimal.contains(Decimal128(345.678))
        }

        assertQuery(predicate: "NOT %@ IN arrayObjectId", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 0) {
            !$0.arrayObjectId.contains(ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(predicate: "NOT %@ IN arrayObjectId", values: [ObjectId("61184062c1d8f096a3695044")], expectedCount: 1) {
            !$0.arrayObjectId.contains(ObjectId("61184062c1d8f096a3695044"))
        }

        assertQuery(predicate: "NOT %@ IN arrayUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 0) {
            !$0.arrayUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(predicate: "NOT %@ IN arrayUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!], expectedCount: 1) {
            !$0.arrayUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!)
        }

        assertQuery(predicate: "NOT %@ IN arrayAny", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 0) {
            !$0.arrayAny.contains(AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")))
        }
        assertQuery(predicate: "NOT %@ IN arrayAny", values: [123], expectedCount: 1) {
            !$0.arrayAny.contains(AnyRealmValue.int(123))
        }

        assertQuery(predicate: "NOT %@ IN arrayOptBool", values: [true], expectedCount: 0) {
            !$0.arrayOptBool.contains(true)
        }
        assertQuery(predicate: "NOT %@ IN arrayOptBool", values: [false], expectedCount: 1) {
            !$0.arrayOptBool.contains(false)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptInt", values: [1], expectedCount: 0) {
            !$0.arrayOptInt.contains(1)
        }
        assertQuery(predicate: "NOT %@ IN arrayOptInt", values: [3], expectedCount: 1) {
            !$0.arrayOptInt.contains(3)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptInt8", values: [Int8(8)], expectedCount: 0) {
            !$0.arrayOptInt8.contains(Int8(8))
        }
        assertQuery(predicate: "NOT %@ IN arrayOptInt8", values: [Int8(10)], expectedCount: 1) {
            !$0.arrayOptInt8.contains(Int8(10))
        }

        assertQuery(predicate: "NOT %@ IN arrayOptInt16", values: [Int16(16)], expectedCount: 0) {
            !$0.arrayOptInt16.contains(Int16(16))
        }
        assertQuery(predicate: "NOT %@ IN arrayOptInt16", values: [Int16(18)], expectedCount: 1) {
            !$0.arrayOptInt16.contains(Int16(18))
        }

        assertQuery(predicate: "NOT %@ IN arrayOptInt32", values: [Int32(32)], expectedCount: 0) {
            !$0.arrayOptInt32.contains(Int32(32))
        }
        assertQuery(predicate: "NOT %@ IN arrayOptInt32", values: [Int32(34)], expectedCount: 1) {
            !$0.arrayOptInt32.contains(Int32(34))
        }

        assertQuery(predicate: "NOT %@ IN arrayOptInt64", values: [Int64(64)], expectedCount: 0) {
            !$0.arrayOptInt64.contains(Int64(64))
        }
        assertQuery(predicate: "NOT %@ IN arrayOptInt64", values: [Int64(66)], expectedCount: 1) {
            !$0.arrayOptInt64.contains(Int64(66))
        }

        assertQuery(predicate: "NOT %@ IN arrayOptFloat", values: [Float(5.55444333)], expectedCount: 0) {
            !$0.arrayOptFloat.contains(Float(5.55444333))
        }
        assertQuery(predicate: "NOT %@ IN arrayOptFloat", values: [Float(7.55444333)], expectedCount: 1) {
            !$0.arrayOptFloat.contains(Float(7.55444333))
        }

        assertQuery(predicate: "NOT %@ IN arrayOptDouble", values: [123.456], expectedCount: 0) {
            !$0.arrayOptDouble.contains(123.456)
        }
        assertQuery(predicate: "NOT %@ IN arrayOptDouble", values: [345.678], expectedCount: 1) {
            !$0.arrayOptDouble.contains(345.678)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptString", values: ["Foo"], expectedCount: 0) {
            !$0.arrayOptString.contains("Foo")
        }
        assertQuery(predicate: "NOT %@ IN arrayOptString", values: ["Baz"], expectedCount: 1) {
            !$0.arrayOptString.contains("Baz")
        }

        assertQuery(predicate: "NOT %@ IN arrayOptBinary", values: [Data(count: 64)], expectedCount: 0) {
            !$0.arrayOptBinary.contains(Data(count: 64))
        }
        assertQuery(predicate: "NOT %@ IN arrayOptBinary", values: [Data(count: 256)], expectedCount: 1) {
            !$0.arrayOptBinary.contains(Data(count: 256))
        }

        assertQuery(predicate: "NOT %@ IN arrayOptDate", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            !$0.arrayOptDate.contains(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(predicate: "NOT %@ IN arrayOptDate", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            !$0.arrayOptDate.contains(Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "NOT %@ IN arrayOptDecimal", values: [Decimal128(123.456)], expectedCount: 0) {
            !$0.arrayOptDecimal.contains(Decimal128(123.456))
        }
        assertQuery(predicate: "NOT %@ IN arrayOptDecimal", values: [Decimal128(345.678)], expectedCount: 1) {
            !$0.arrayOptDecimal.contains(Decimal128(345.678))
        }

        assertQuery(predicate: "NOT %@ IN arrayOptUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 0) {
            !$0.arrayOptUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(predicate: "NOT %@ IN arrayOptUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!], expectedCount: 1) {
            !$0.arrayOptUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptObjectId", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 0) {
            !$0.arrayOptObjectId.contains(ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(predicate: "NOT %@ IN arrayOptObjectId", values: [ObjectId("61184062c1d8f096a3695044")], expectedCount: 1) {
            !$0.arrayOptObjectId.contains(ObjectId("61184062c1d8f096a3695044"))
        }

        assertQuery(predicate: "NOT %@ IN arrayOptBool", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptBool.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptInt", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptInt.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptInt8", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptInt8.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptInt16", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptInt16.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptInt32", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptInt32.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptInt64", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptInt64.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptFloat", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptFloat.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptDouble", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptDouble.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptString", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptString.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptBinary", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptBinary.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptDate", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptDate.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptDecimal", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptDecimal.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptUuid", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptUuid.contains(nil)
        }

        assertQuery(predicate: "NOT %@ IN arrayOptObjectId", values: [NSNull()], expectedCount: 1) {
            !$0.arrayOptObjectId.contains(nil)
        }

    }

    func testListContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let realm = realmWithTestPath()
        let result1 = realm.objects(ModernCollectionObject.self).query {
            $0.list.contains(obj)
        }
        XCTAssertEqual(result1.count, 0)
        try! realm.write {
            colObj.list.append(obj)
        }
        let result2 = realm.objects(ModernCollectionObject.self).query {
            $0.list.contains(obj)
        }
        XCTAssertEqual(result2.count, 1)
    }

    func testListContainsRange() {
        assertQuery(predicate: "arrayInt.@min >= %@ && arrayInt.@max <= %@",
                    values: [1, 2], expectedCount: 1) {
            $0.arrayInt.contains(1...2)
        }
        assertQuery(predicate: "arrayInt.@min >= %@ && arrayInt.@max < %@",
                    values: [1, 2], expectedCount: 0) {
            $0.arrayInt.contains(1..<2)
        }

        assertQuery(predicate: "arrayInt8.@min >= %@ && arrayInt8.@max <= %@",
                    values: [Int8(8), Int8(9)], expectedCount: 1) {
            $0.arrayInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(predicate: "arrayInt8.@min >= %@ && arrayInt8.@max < %@",
                    values: [Int8(8), Int8(9)], expectedCount: 0) {
            $0.arrayInt8.contains(Int8(8)..<Int8(9))
        }

        assertQuery(predicate: "arrayInt16.@min >= %@ && arrayInt16.@max <= %@",
                    values: [Int16(16), Int16(17)], expectedCount: 1) {
            $0.arrayInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(predicate: "arrayInt16.@min >= %@ && arrayInt16.@max < %@",
                    values: [Int16(16), Int16(17)], expectedCount: 0) {
            $0.arrayInt16.contains(Int16(16)..<Int16(17))
        }

        assertQuery(predicate: "arrayInt32.@min >= %@ && arrayInt32.@max <= %@",
                    values: [Int32(32), Int32(33)], expectedCount: 1) {
            $0.arrayInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(predicate: "arrayInt32.@min >= %@ && arrayInt32.@max < %@",
                    values: [Int32(32), Int32(33)], expectedCount: 0) {
            $0.arrayInt32.contains(Int32(32)..<Int32(33))
        }

        assertQuery(predicate: "arrayInt64.@min >= %@ && arrayInt64.@max <= %@",
                    values: [Int64(64), Int64(65)], expectedCount: 1) {
            $0.arrayInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(predicate: "arrayInt64.@min >= %@ && arrayInt64.@max < %@",
                    values: [Int64(64), Int64(65)], expectedCount: 0) {
            $0.arrayInt64.contains(Int64(64)..<Int64(65))
        }

        assertQuery(predicate: "arrayFloat.@min >= %@ && arrayFloat.@max <= %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 1) {
            $0.arrayFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(predicate: "arrayFloat.@min >= %@ && arrayFloat.@max < %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 0) {
            $0.arrayFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }

        assertQuery(predicate: "arrayDouble.@min >= %@ && arrayDouble.@max <= %@",
                    values: [123.456, 234.567], expectedCount: 1) {
            $0.arrayDouble.contains(123.456...234.567)
        }
        assertQuery(predicate: "arrayDouble.@min >= %@ && arrayDouble.@max < %@",
                    values: [123.456, 234.567], expectedCount: 0) {
            $0.arrayDouble.contains(123.456..<234.567)
        }

        assertQuery(predicate: "arrayDate.@min >= %@ && arrayDate.@max <= %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.arrayDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(predicate: "arrayDate.@min >= %@ && arrayDate.@max < %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.arrayDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "arrayDecimal.@min >= %@ && arrayDecimal.@max <= %@",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 1) {
            $0.arrayDecimal.contains(Decimal128(123.456)...Decimal128(234.567))
        }
        assertQuery(predicate: "arrayDecimal.@min >= %@ && arrayDecimal.@max < %@",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 0) {
            $0.arrayDecimal.contains(Decimal128(123.456)..<Decimal128(234.567))
        }

        assertQuery(predicate: "arrayOptInt.@min >= %@ && arrayOptInt.@max <= %@",
                    values: [1, 2], expectedCount: 1) {
            $0.arrayOptInt.contains(1...2)
        }
        assertQuery(predicate: "arrayOptInt.@min >= %@ && arrayOptInt.@max < %@",
                    values: [1, 2], expectedCount: 0) {
            $0.arrayOptInt.contains(1..<2)
        }

        assertQuery(predicate: "arrayOptInt8.@min >= %@ && arrayOptInt8.@max <= %@",
                    values: [Int8(8), Int8(9)], expectedCount: 1) {
            $0.arrayOptInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(predicate: "arrayOptInt8.@min >= %@ && arrayOptInt8.@max < %@",
                    values: [Int8(8), Int8(9)], expectedCount: 0) {
            $0.arrayOptInt8.contains(Int8(8)..<Int8(9))
        }

        assertQuery(predicate: "arrayOptInt16.@min >= %@ && arrayOptInt16.@max <= %@",
                    values: [Int16(16), Int16(17)], expectedCount: 1) {
            $0.arrayOptInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(predicate: "arrayOptInt16.@min >= %@ && arrayOptInt16.@max < %@",
                    values: [Int16(16), Int16(17)], expectedCount: 0) {
            $0.arrayOptInt16.contains(Int16(16)..<Int16(17))
        }

        assertQuery(predicate: "arrayOptInt32.@min >= %@ && arrayOptInt32.@max <= %@",
                    values: [Int32(32), Int32(33)], expectedCount: 1) {
            $0.arrayOptInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(predicate: "arrayOptInt32.@min >= %@ && arrayOptInt32.@max < %@",
                    values: [Int32(32), Int32(33)], expectedCount: 0) {
            $0.arrayOptInt32.contains(Int32(32)..<Int32(33))
        }

        assertQuery(predicate: "arrayOptInt64.@min >= %@ && arrayOptInt64.@max <= %@",
                    values: [Int64(64), Int64(65)], expectedCount: 1) {
            $0.arrayOptInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(predicate: "arrayOptInt64.@min >= %@ && arrayOptInt64.@max < %@",
                    values: [Int64(64), Int64(65)], expectedCount: 0) {
            $0.arrayOptInt64.contains(Int64(64)..<Int64(65))
        }

        assertQuery(predicate: "arrayOptFloat.@min >= %@ && arrayOptFloat.@max <= %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 1) {
            $0.arrayOptFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(predicate: "arrayOptFloat.@min >= %@ && arrayOptFloat.@max < %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 0) {
            $0.arrayOptFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }

        assertQuery(predicate: "arrayOptDouble.@min >= %@ && arrayOptDouble.@max <= %@",
                    values: [123.456, 234.567], expectedCount: 1) {
            $0.arrayOptDouble.contains(123.456...234.567)
        }
        assertQuery(predicate: "arrayOptDouble.@min >= %@ && arrayOptDouble.@max < %@",
                    values: [123.456, 234.567], expectedCount: 0) {
            $0.arrayOptDouble.contains(123.456..<234.567)
        }

        assertQuery(predicate: "arrayOptDate.@min >= %@ && arrayOptDate.@max <= %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.arrayOptDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(predicate: "arrayOptDate.@min >= %@ && arrayOptDate.@max < %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.arrayOptDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "arrayOptDecimal.@min >= %@ && arrayOptDecimal.@max <= %@",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 1) {
            $0.arrayOptDecimal.contains(Decimal128(123.456)...Decimal128(234.567))
        }
        assertQuery(predicate: "arrayOptDecimal.@min >= %@ && arrayOptDecimal.@max < %@",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 0) {
            $0.arrayOptDecimal.contains(Decimal128(123.456)..<Decimal128(234.567))
        }

    }

    func testListContainsAnyInObject() {
        assertQuery(predicate: "ANY arrayBool IN %@",
                    values: [NSArray(array: [true, true])], expectedCount: 1) {
            $0.arrayBool.containsAny(in: [true, true])
        }
        assertQuery(predicate: "ANY arrayInt IN %@",
                    values: [NSArray(array: [1, 2])], expectedCount: 1) {
            $0.arrayInt.containsAny(in: [1, 2])
        }
        assertQuery(predicate: "ANY arrayInt8 IN %@",
                    values: [NSArray(array: [Int8(8), Int8(9)])], expectedCount: 1) {
            $0.arrayInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(predicate: "ANY arrayInt16 IN %@",
                    values: [NSArray(array: [Int16(16), Int16(17)])], expectedCount: 1) {
            $0.arrayInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(predicate: "ANY arrayInt32 IN %@",
                    values: [NSArray(array: [Int32(32), Int32(33)])], expectedCount: 1) {
            $0.arrayInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(predicate: "ANY arrayInt64 IN %@",
                    values: [NSArray(array: [Int64(64), Int64(65)])], expectedCount: 1) {
            $0.arrayInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(predicate: "ANY arrayFloat IN %@",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], expectedCount: 1) {
            $0.arrayFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(predicate: "ANY arrayDouble IN %@",
                    values: [NSArray(array: [123.456, 234.567])], expectedCount: 1) {
            $0.arrayDouble.containsAny(in: [123.456, 234.567])
        }
        assertQuery(predicate: "ANY arrayString IN %@",
                    values: [NSArray(array: ["Foo", "Bar"])], expectedCount: 1) {
            $0.arrayString.containsAny(in: ["Foo", "Bar"])
        }
        assertQuery(predicate: "ANY arrayBinary IN %@",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], expectedCount: 1) {
            $0.arrayBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(predicate: "ANY arrayDate IN %@",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], expectedCount: 1) {
            $0.arrayDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(predicate: "ANY arrayDecimal IN %@",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], expectedCount: 1) {
            $0.arrayDecimal.containsAny(in: [Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(predicate: "ANY arrayObjectId IN %@",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], expectedCount: 1) {
            $0.arrayObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(predicate: "ANY arrayUuid IN %@",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], expectedCount: 1) {
            $0.arrayUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(predicate: "ANY arrayAny IN %@",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), "Hello"])], expectedCount: 1) {
            $0.arrayAny.containsAny(in: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
        }
        assertQuery(predicate: "ANY arrayOptBool IN %@",
                    values: [NSArray(array: [true, true])], expectedCount: 1) {
            $0.arrayOptBool.containsAny(in: [true, true])
        }
        assertQuery(predicate: "ANY arrayOptInt IN %@",
                    values: [NSArray(array: [1, 2])], expectedCount: 1) {
            $0.arrayOptInt.containsAny(in: [1, 2])
        }
        assertQuery(predicate: "ANY arrayOptInt8 IN %@",
                    values: [NSArray(array: [Int8(8), Int8(9)])], expectedCount: 1) {
            $0.arrayOptInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(predicate: "ANY arrayOptInt16 IN %@",
                    values: [NSArray(array: [Int16(16), Int16(17)])], expectedCount: 1) {
            $0.arrayOptInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(predicate: "ANY arrayOptInt32 IN %@",
                    values: [NSArray(array: [Int32(32), Int32(33)])], expectedCount: 1) {
            $0.arrayOptInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(predicate: "ANY arrayOptInt64 IN %@",
                    values: [NSArray(array: [Int64(64), Int64(65)])], expectedCount: 1) {
            $0.arrayOptInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(predicate: "ANY arrayOptFloat IN %@",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], expectedCount: 1) {
            $0.arrayOptFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(predicate: "ANY arrayOptDouble IN %@",
                    values: [NSArray(array: [123.456, 234.567])], expectedCount: 1) {
            $0.arrayOptDouble.containsAny(in: [123.456, 234.567])
        }
        assertQuery(predicate: "ANY arrayOptString IN %@",
                    values: [NSArray(array: ["Foo", "Bar"])], expectedCount: 1) {
            $0.arrayOptString.containsAny(in: ["Foo", "Bar"])
        }
        assertQuery(predicate: "ANY arrayOptBinary IN %@",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], expectedCount: 1) {
            $0.arrayOptBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(predicate: "ANY arrayOptDate IN %@",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], expectedCount: 1) {
            $0.arrayOptDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(predicate: "ANY arrayOptDecimal IN %@",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], expectedCount: 1) {
            $0.arrayOptDecimal.containsAny(in: [Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(predicate: "ANY arrayOptUuid IN %@",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], expectedCount: 1) {
            $0.arrayOptUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(predicate: "ANY arrayOptObjectId IN %@",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], expectedCount: 1) {
            $0.arrayOptObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }

        let realm = realmWithTestPath()
        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.list.append(obj)
        try! realm.write {
            realm.add(colObj)
        }

        assertCollectionObjectQuery(predicate: "ANY list IN %@", values: [NSArray(array: [obj])], expectedCount: 1) {
            $0.list.containsAny(in: [obj])
        }
    }

    func testListFromProperty() {
        let realm = realmWithTestPath()
        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.list.append(obj)
        try! realm.write {
            realm.add(colObj)
        }

        assertCollectionQuery(on: \.boolCol,
                              isList: true,
                              predicate: "boolCol == %@",
                              values: [false],
                              expectedCount: 1) {
            $0.boolCol == false
        }
        assertCollectionQuery(on: \.intCol,
                              isList: true,
                              predicate: "intCol == %@",
                              values: [6],
                              expectedCount: 1) {
            $0.intCol == 6
        }
        assertCollectionQuery(on: \.int8Col,
                              isList: true,
                              predicate: "int8Col == %@",
                              values: [Int8(9)],
                              expectedCount: 1) {
            $0.int8Col == Int8(9)
        }
        assertCollectionQuery(on: \.int16Col,
                              isList: true,
                              predicate: "int16Col == %@",
                              values: [Int16(17)],
                              expectedCount: 1) {
            $0.int16Col == Int16(17)
        }
        assertCollectionQuery(on: \.int32Col,
                              isList: true,
                              predicate: "int32Col == %@",
                              values: [Int32(33)],
                              expectedCount: 1) {
            $0.int32Col == Int32(33)
        }
        assertCollectionQuery(on: \.int64Col,
                              isList: true,
                              predicate: "int64Col == %@",
                              values: [Int64(65)],
                              expectedCount: 1) {
            $0.int64Col == Int64(65)
        }
        assertCollectionQuery(on: \.floatCol,
                              isList: true,
                              predicate: "floatCol == %@",
                              values: [Float(6.55444333)],
                              expectedCount: 1) {
            $0.floatCol == Float(6.55444333)
        }
        assertCollectionQuery(on: \.doubleCol,
                              isList: true,
                              predicate: "doubleCol == %@",
                              values: [234.567],
                              expectedCount: 1) {
            $0.doubleCol == 234.567
        }
        assertCollectionQuery(on: \.stringCol,
                              isList: true,
                              predicate: "stringCol == %@",
                              values: ["Foó"],
                              expectedCount: 1) {
            $0.stringCol == "Foó"
        }
        assertCollectionQuery(on: \.binaryCol,
                              isList: true,
                              predicate: "binaryCol == %@",
                              values: [Data(count: 128)],
                              expectedCount: 1) {
            $0.binaryCol == Data(count: 128)
        }
        assertCollectionQuery(on: \.dateCol,
                              isList: true,
                              predicate: "dateCol == %@",
                              values: [Date(timeIntervalSince1970: 2000000)],
                              expectedCount: 1) {
            $0.dateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertCollectionQuery(on: \.decimalCol,
                              isList: true,
                              predicate: "decimalCol == %@",
                              values: [Decimal128(234.567)],
                              expectedCount: 1) {
            $0.decimalCol == Decimal128(234.567)
        }
        assertCollectionQuery(on: \.objectIdCol,
                              isList: true,
                              predicate: "objectIdCol == %@",
                              values: [ObjectId("61184062c1d8f096a3695045")],
                              expectedCount: 1) {
            $0.objectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertCollectionQuery(on: \.intEnumCol,
                              isList: true,
                              predicate: "intEnumCol == %@",
                              values: [ModernIntEnum.value2.rawValue],
                              expectedCount: 1) {
            $0.intEnumCol == .value2
        }
        assertCollectionQuery(on: \.stringEnumCol,
                              isList: true,
                              predicate: "stringEnumCol == %@",
                              values: [ModernStringEnum.value2.rawValue],
                              expectedCount: 1) {
            $0.stringEnumCol == .value2
        }
        assertCollectionQuery(on: \.uuidCol,
                              isList: true,
                              predicate: "uuidCol == %@",
                              values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!],
                              expectedCount: 1) {
            $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
        assertCollectionQuery(on: \.optBoolCol,
                              isList: true,
                              predicate: "optBoolCol == %@",
                              values: [false],
                              expectedCount: 1) {
            $0.optBoolCol == false
        }
        assertCollectionQuery(on: \.optIntCol,
                              isList: true,
                              predicate: "optIntCol == %@",
                              values: [6],
                              expectedCount: 1) {
            $0.optIntCol == 6
        }
        assertCollectionQuery(on: \.optInt8Col,
                              isList: true,
                              predicate: "optInt8Col == %@",
                              values: [Int8(9)],
                              expectedCount: 1) {
            $0.optInt8Col == Int8(9)
        }
        assertCollectionQuery(on: \.optInt16Col,
                              isList: true,
                              predicate: "optInt16Col == %@",
                              values: [Int16(17)],
                              expectedCount: 1) {
            $0.optInt16Col == Int16(17)
        }
        assertCollectionQuery(on: \.optInt32Col,
                              isList: true,
                              predicate: "optInt32Col == %@",
                              values: [Int32(33)],
                              expectedCount: 1) {
            $0.optInt32Col == Int32(33)
        }
        assertCollectionQuery(on: \.optInt64Col,
                              isList: true,
                              predicate: "optInt64Col == %@",
                              values: [Int64(65)],
                              expectedCount: 1) {
            $0.optInt64Col == Int64(65)
        }
        assertCollectionQuery(on: \.optFloatCol,
                              isList: true,
                              predicate: "optFloatCol == %@",
                              values: [Float(6.55444333)],
                              expectedCount: 1) {
            $0.optFloatCol == Float(6.55444333)
        }
        assertCollectionQuery(on: \.optDoubleCol,
                              isList: true,
                              predicate: "optDoubleCol == %@",
                              values: [234.567],
                              expectedCount: 1) {
            $0.optDoubleCol == 234.567
        }
        assertCollectionQuery(on: \.optStringCol,
                              isList: true,
                              predicate: "optStringCol == %@",
                              values: ["Foó"],
                              expectedCount: 1) {
            $0.optStringCol == "Foó"
        }
        assertCollectionQuery(on: \.optBinaryCol,
                              isList: true,
                              predicate: "optBinaryCol == %@",
                              values: [Data(count: 128)],
                              expectedCount: 1) {
            $0.optBinaryCol == Data(count: 128)
        }
        assertCollectionQuery(on: \.optDateCol,
                              isList: true,
                              predicate: "optDateCol == %@",
                              values: [Date(timeIntervalSince1970: 2000000)],
                              expectedCount: 1) {
            $0.optDateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertCollectionQuery(on: \.optDecimalCol,
                              isList: true,
                              predicate: "optDecimalCol == %@",
                              values: [Decimal128(234.567)],
                              expectedCount: 1) {
            $0.optDecimalCol == Decimal128(234.567)
        }
        assertCollectionQuery(on: \.optObjectIdCol,
                              isList: true,
                              predicate: "optObjectIdCol == %@",
                              values: [ObjectId("61184062c1d8f096a3695045")],
                              expectedCount: 1) {
            $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertCollectionQuery(on: \.optIntEnumCol,
                              isList: true,
                              predicate: "optIntEnumCol == %@",
                              values: [ModernIntEnum.value2.rawValue],
                              expectedCount: 1) {
            $0.optIntEnumCol == .value2
        }
        assertCollectionQuery(on: \.optStringEnumCol,
                              isList: true,
                              predicate: "optStringEnumCol == %@",
                              values: [ModernStringEnum.value2.rawValue],
                              expectedCount: 1) {
            $0.optStringEnumCol == .value2
        }
        assertCollectionQuery(on: \.optUuidCol,
                              isList: true,
                              predicate: "optUuidCol == %@",
                              values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!],
                              expectedCount: 1) {
            $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
    }

    func testSetContainsElement() {
        assertQuery(predicate: "%@ IN setBool", values: [true], expectedCount: 1) {
            $0.setBool.contains(true)
        }
        assertQuery(predicate: "%@ IN setBool", values: [false], expectedCount: 0) {
            $0.setBool.contains(false)
        }

        assertQuery(predicate: "%@ IN setInt", values: [1], expectedCount: 1) {
            $0.setInt.contains(1)
        }
        assertQuery(predicate: "%@ IN setInt", values: [3], expectedCount: 0) {
            $0.setInt.contains(3)
        }

        assertQuery(predicate: "%@ IN setInt8", values: [Int8(8)], expectedCount: 1) {
            $0.setInt8.contains(Int8(8))
        }
        assertQuery(predicate: "%@ IN setInt8", values: [Int8(10)], expectedCount: 0) {
            $0.setInt8.contains(Int8(10))
        }

        assertQuery(predicate: "%@ IN setInt16", values: [Int16(16)], expectedCount: 1) {
            $0.setInt16.contains(Int16(16))
        }
        assertQuery(predicate: "%@ IN setInt16", values: [Int16(18)], expectedCount: 0) {
            $0.setInt16.contains(Int16(18))
        }

        assertQuery(predicate: "%@ IN setInt32", values: [Int32(32)], expectedCount: 1) {
            $0.setInt32.contains(Int32(32))
        }
        assertQuery(predicate: "%@ IN setInt32", values: [Int32(34)], expectedCount: 0) {
            $0.setInt32.contains(Int32(34))
        }

        assertQuery(predicate: "%@ IN setInt64", values: [Int64(64)], expectedCount: 1) {
            $0.setInt64.contains(Int64(64))
        }
        assertQuery(predicate: "%@ IN setInt64", values: [Int64(66)], expectedCount: 0) {
            $0.setInt64.contains(Int64(66))
        }

        assertQuery(predicate: "%@ IN setFloat", values: [Float(5.55444333)], expectedCount: 1) {
            $0.setFloat.contains(Float(5.55444333))
        }
        assertQuery(predicate: "%@ IN setFloat", values: [Float(7.55444333)], expectedCount: 0) {
            $0.setFloat.contains(Float(7.55444333))
        }

        assertQuery(predicate: "%@ IN setDouble", values: [123.456], expectedCount: 1) {
            $0.setDouble.contains(123.456)
        }
        assertQuery(predicate: "%@ IN setDouble", values: [345.678], expectedCount: 0) {
            $0.setDouble.contains(345.678)
        }

        assertQuery(predicate: "%@ IN setString", values: ["Foo"], expectedCount: 1) {
            $0.setString.contains("Foo")
        }
        assertQuery(predicate: "%@ IN setString", values: ["Baz"], expectedCount: 0) {
            $0.setString.contains("Baz")
        }

        assertQuery(predicate: "%@ IN setBinary", values: [Data(count: 64)], expectedCount: 1) {
            $0.setBinary.contains(Data(count: 64))
        }
        assertQuery(predicate: "%@ IN setBinary", values: [Data(count: 256)], expectedCount: 0) {
            $0.setBinary.contains(Data(count: 256))
        }

        assertQuery(predicate: "%@ IN setDate", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.setDate.contains(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(predicate: "%@ IN setDate", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 0) {
            $0.setDate.contains(Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "%@ IN setDecimal", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.setDecimal.contains(Decimal128(123.456))
        }
        assertQuery(predicate: "%@ IN setDecimal", values: [Decimal128(345.678)], expectedCount: 0) {
            $0.setDecimal.contains(Decimal128(345.678))
        }

        assertQuery(predicate: "%@ IN setObjectId", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.setObjectId.contains(ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(predicate: "%@ IN setObjectId", values: [ObjectId("61184062c1d8f096a3695044")], expectedCount: 0) {
            $0.setObjectId.contains(ObjectId("61184062c1d8f096a3695044"))
        }

        assertQuery(predicate: "%@ IN setUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.setUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(predicate: "%@ IN setUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!], expectedCount: 0) {
            $0.setUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!)
        }

        assertQuery(predicate: "%@ IN setAny", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.setAny.contains(AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")))
        }
        assertQuery(predicate: "%@ IN setAny", values: [123], expectedCount: 0) {
            $0.setAny.contains(AnyRealmValue.int(123))
        }

        assertQuery(predicate: "%@ IN setOptBool", values: [true], expectedCount: 1) {
            $0.setOptBool.contains(true)
        }
        assertQuery(predicate: "%@ IN setOptBool", values: [false], expectedCount: 0) {
            $0.setOptBool.contains(false)
        }
        assertQuery(predicate: "%@ IN setOptBool", values: [NSNull()], expectedCount: 0) {
            $0.setOptBool.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptInt", values: [1], expectedCount: 1) {
            $0.setOptInt.contains(1)
        }
        assertQuery(predicate: "%@ IN setOptInt", values: [3], expectedCount: 0) {
            $0.setOptInt.contains(3)
        }
        assertQuery(predicate: "%@ IN setOptInt", values: [NSNull()], expectedCount: 0) {
            $0.setOptInt.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptInt8", values: [Int8(8)], expectedCount: 1) {
            $0.setOptInt8.contains(Int8(8))
        }
        assertQuery(predicate: "%@ IN setOptInt8", values: [Int8(10)], expectedCount: 0) {
            $0.setOptInt8.contains(Int8(10))
        }
        assertQuery(predicate: "%@ IN setOptInt8", values: [NSNull()], expectedCount: 0) {
            $0.setOptInt8.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptInt16", values: [Int16(16)], expectedCount: 1) {
            $0.setOptInt16.contains(Int16(16))
        }
        assertQuery(predicate: "%@ IN setOptInt16", values: [Int16(18)], expectedCount: 0) {
            $0.setOptInt16.contains(Int16(18))
        }
        assertQuery(predicate: "%@ IN setOptInt16", values: [NSNull()], expectedCount: 0) {
            $0.setOptInt16.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptInt32", values: [Int32(32)], expectedCount: 1) {
            $0.setOptInt32.contains(Int32(32))
        }
        assertQuery(predicate: "%@ IN setOptInt32", values: [Int32(34)], expectedCount: 0) {
            $0.setOptInt32.contains(Int32(34))
        }
        assertQuery(predicate: "%@ IN setOptInt32", values: [NSNull()], expectedCount: 0) {
            $0.setOptInt32.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptInt64", values: [Int64(64)], expectedCount: 1) {
            $0.setOptInt64.contains(Int64(64))
        }
        assertQuery(predicate: "%@ IN setOptInt64", values: [Int64(66)], expectedCount: 0) {
            $0.setOptInt64.contains(Int64(66))
        }
        assertQuery(predicate: "%@ IN setOptInt64", values: [NSNull()], expectedCount: 0) {
            $0.setOptInt64.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptFloat", values: [Float(5.55444333)], expectedCount: 1) {
            $0.setOptFloat.contains(Float(5.55444333))
        }
        assertQuery(predicate: "%@ IN setOptFloat", values: [Float(7.55444333)], expectedCount: 0) {
            $0.setOptFloat.contains(Float(7.55444333))
        }
        assertQuery(predicate: "%@ IN setOptFloat", values: [NSNull()], expectedCount: 0) {
            $0.setOptFloat.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptDouble", values: [123.456], expectedCount: 1) {
            $0.setOptDouble.contains(123.456)
        }
        assertQuery(predicate: "%@ IN setOptDouble", values: [345.678], expectedCount: 0) {
            $0.setOptDouble.contains(345.678)
        }
        assertQuery(predicate: "%@ IN setOptDouble", values: [NSNull()], expectedCount: 0) {
            $0.setOptDouble.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptString", values: ["Foo"], expectedCount: 1) {
            $0.setOptString.contains("Foo")
        }
        assertQuery(predicate: "%@ IN setOptString", values: ["Baz"], expectedCount: 0) {
            $0.setOptString.contains("Baz")
        }
        assertQuery(predicate: "%@ IN setOptString", values: [NSNull()], expectedCount: 0) {
            $0.setOptString.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptBinary", values: [Data(count: 64)], expectedCount: 1) {
            $0.setOptBinary.contains(Data(count: 64))
        }
        assertQuery(predicate: "%@ IN setOptBinary", values: [Data(count: 256)], expectedCount: 0) {
            $0.setOptBinary.contains(Data(count: 256))
        }
        assertQuery(predicate: "%@ IN setOptBinary", values: [NSNull()], expectedCount: 0) {
            $0.setOptBinary.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptDate", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.setOptDate.contains(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(predicate: "%@ IN setOptDate", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 0) {
            $0.setOptDate.contains(Date(timeIntervalSince1970: 3000000))
        }
        assertQuery(predicate: "%@ IN setOptDate", values: [NSNull()], expectedCount: 0) {
            $0.setOptDate.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptDecimal", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.setOptDecimal.contains(Decimal128(123.456))
        }
        assertQuery(predicate: "%@ IN setOptDecimal", values: [Decimal128(345.678)], expectedCount: 0) {
            $0.setOptDecimal.contains(Decimal128(345.678))
        }
        assertQuery(predicate: "%@ IN setOptDecimal", values: [NSNull()], expectedCount: 0) {
            $0.setOptDecimal.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.setOptUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(predicate: "%@ IN setOptUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!], expectedCount: 0) {
            $0.setOptUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!)
        }
        assertQuery(predicate: "%@ IN setOptUuid", values: [NSNull()], expectedCount: 0) {
            $0.setOptUuid.contains(nil)
        }

        assertQuery(predicate: "%@ IN setOptObjectId", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.setOptObjectId.contains(ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(predicate: "%@ IN setOptObjectId", values: [ObjectId("61184062c1d8f096a3695044")], expectedCount: 0) {
            $0.setOptObjectId.contains(ObjectId("61184062c1d8f096a3695044"))
        }
        assertQuery(predicate: "%@ IN setOptObjectId", values: [NSNull()], expectedCount: 0) {
            $0.setOptObjectId.contains(nil)
        }

    }

    func testSetContainsRange() {
        assertQuery(predicate: "setInt.@min >= %@ && setInt.@max <= %@",
                    values: [1, 2], expectedCount: 1) {
            $0.setInt.contains(1...2)
        }
        assertQuery(predicate: "setInt.@min >= %@ && setInt.@max < %@",
                    values: [1, 2], expectedCount: 0) {
            $0.setInt.contains(1..<2)
        }

        assertQuery(predicate: "setInt8.@min >= %@ && setInt8.@max <= %@",
                    values: [Int8(8), Int8(9)], expectedCount: 1) {
            $0.setInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(predicate: "setInt8.@min >= %@ && setInt8.@max < %@",
                    values: [Int8(8), Int8(9)], expectedCount: 0) {
            $0.setInt8.contains(Int8(8)..<Int8(9))
        }

        assertQuery(predicate: "setInt16.@min >= %@ && setInt16.@max <= %@",
                    values: [Int16(16), Int16(17)], expectedCount: 1) {
            $0.setInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(predicate: "setInt16.@min >= %@ && setInt16.@max < %@",
                    values: [Int16(16), Int16(17)], expectedCount: 0) {
            $0.setInt16.contains(Int16(16)..<Int16(17))
        }

        assertQuery(predicate: "setInt32.@min >= %@ && setInt32.@max <= %@",
                    values: [Int32(32), Int32(33)], expectedCount: 1) {
            $0.setInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(predicate: "setInt32.@min >= %@ && setInt32.@max < %@",
                    values: [Int32(32), Int32(33)], expectedCount: 0) {
            $0.setInt32.contains(Int32(32)..<Int32(33))
        }

        assertQuery(predicate: "setInt64.@min >= %@ && setInt64.@max <= %@",
                    values: [Int64(64), Int64(65)], expectedCount: 1) {
            $0.setInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(predicate: "setInt64.@min >= %@ && setInt64.@max < %@",
                    values: [Int64(64), Int64(65)], expectedCount: 0) {
            $0.setInt64.contains(Int64(64)..<Int64(65))
        }

        assertQuery(predicate: "setFloat.@min >= %@ && setFloat.@max <= %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 1) {
            $0.setFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(predicate: "setFloat.@min >= %@ && setFloat.@max < %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 0) {
            $0.setFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }

        assertQuery(predicate: "setDouble.@min >= %@ && setDouble.@max <= %@",
                    values: [123.456, 234.567], expectedCount: 1) {
            $0.setDouble.contains(123.456...234.567)
        }
        assertQuery(predicate: "setDouble.@min >= %@ && setDouble.@max < %@",
                    values: [123.456, 234.567], expectedCount: 0) {
            $0.setDouble.contains(123.456..<234.567)
        }

        assertQuery(predicate: "setDate.@min >= %@ && setDate.@max <= %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.setDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(predicate: "setDate.@min >= %@ && setDate.@max < %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.setDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "setDecimal.@min >= %@ && setDecimal.@max <= %@",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 1) {
            $0.setDecimal.contains(Decimal128(123.456)...Decimal128(234.567))
        }
        assertQuery(predicate: "setDecimal.@min >= %@ && setDecimal.@max < %@",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 0) {
            $0.setDecimal.contains(Decimal128(123.456)..<Decimal128(234.567))
        }

        assertQuery(predicate: "setOptInt.@min >= %@ && setOptInt.@max <= %@",
                    values: [1, 2], expectedCount: 1) {
            $0.setOptInt.contains(1...2)
        }
        assertQuery(predicate: "setOptInt.@min >= %@ && setOptInt.@max < %@",
                    values: [1, 2], expectedCount: 0) {
            $0.setOptInt.contains(1..<2)
        }

        assertQuery(predicate: "setOptInt8.@min >= %@ && setOptInt8.@max <= %@",
                    values: [Int8(8), Int8(9)], expectedCount: 1) {
            $0.setOptInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(predicate: "setOptInt8.@min >= %@ && setOptInt8.@max < %@",
                    values: [Int8(8), Int8(9)], expectedCount: 0) {
            $0.setOptInt8.contains(Int8(8)..<Int8(9))
        }

        assertQuery(predicate: "setOptInt16.@min >= %@ && setOptInt16.@max <= %@",
                    values: [Int16(16), Int16(17)], expectedCount: 1) {
            $0.setOptInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(predicate: "setOptInt16.@min >= %@ && setOptInt16.@max < %@",
                    values: [Int16(16), Int16(17)], expectedCount: 0) {
            $0.setOptInt16.contains(Int16(16)..<Int16(17))
        }

        assertQuery(predicate: "setOptInt32.@min >= %@ && setOptInt32.@max <= %@",
                    values: [Int32(32), Int32(33)], expectedCount: 1) {
            $0.setOptInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(predicate: "setOptInt32.@min >= %@ && setOptInt32.@max < %@",
                    values: [Int32(32), Int32(33)], expectedCount: 0) {
            $0.setOptInt32.contains(Int32(32)..<Int32(33))
        }

        assertQuery(predicate: "setOptInt64.@min >= %@ && setOptInt64.@max <= %@",
                    values: [Int64(64), Int64(65)], expectedCount: 1) {
            $0.setOptInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(predicate: "setOptInt64.@min >= %@ && setOptInt64.@max < %@",
                    values: [Int64(64), Int64(65)], expectedCount: 0) {
            $0.setOptInt64.contains(Int64(64)..<Int64(65))
        }

        assertQuery(predicate: "setOptFloat.@min >= %@ && setOptFloat.@max <= %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 1) {
            $0.setOptFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(predicate: "setOptFloat.@min >= %@ && setOptFloat.@max < %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 0) {
            $0.setOptFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }

        assertQuery(predicate: "setOptDouble.@min >= %@ && setOptDouble.@max <= %@",
                    values: [123.456, 234.567], expectedCount: 1) {
            $0.setOptDouble.contains(123.456...234.567)
        }
        assertQuery(predicate: "setOptDouble.@min >= %@ && setOptDouble.@max < %@",
                    values: [123.456, 234.567], expectedCount: 0) {
            $0.setOptDouble.contains(123.456..<234.567)
        }

        assertQuery(predicate: "setOptDate.@min >= %@ && setOptDate.@max <= %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.setOptDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(predicate: "setOptDate.@min >= %@ && setOptDate.@max < %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.setOptDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "setOptDecimal.@min >= %@ && setOptDecimal.@max <= %@",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 1) {
            $0.setOptDecimal.contains(Decimal128(123.456)...Decimal128(234.567))
        }
        assertQuery(predicate: "setOptDecimal.@min >= %@ && setOptDecimal.@max < %@",
                    values: [Decimal128(123.456), Decimal128(234.567)], expectedCount: 0) {
            $0.setOptDecimal.contains(Decimal128(123.456)..<Decimal128(234.567))
        }

    }

    func testSetContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let realm = realmWithTestPath()
        let result1 = realm.objects(ModernCollectionObject.self).query {
            $0.set.contains(obj)
        }
        XCTAssertEqual(result1.count, 0)
        try! realm.write {
            colObj.set.insert(obj)
        }
        let result2 = realm.objects(ModernCollectionObject.self).query {
            $0.set.contains(obj)
        }
        XCTAssertEqual(result2.count, 1)
    }

    func testSetContainsAnyInObject() {
        assertQuery(predicate: "ANY setBool IN %@",
                    values: [NSArray(array: [true, true])], expectedCount: 1) {
            $0.setBool.containsAny(in: [true, true])
        }
        assertQuery(predicate: "ANY setInt IN %@",
                    values: [NSArray(array: [1, 2])], expectedCount: 1) {
            $0.setInt.containsAny(in: [1, 2])
        }
        assertQuery(predicate: "ANY setInt8 IN %@",
                    values: [NSArray(array: [Int8(8), Int8(9)])], expectedCount: 1) {
            $0.setInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(predicate: "ANY setInt16 IN %@",
                    values: [NSArray(array: [Int16(16), Int16(17)])], expectedCount: 1) {
            $0.setInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(predicate: "ANY setInt32 IN %@",
                    values: [NSArray(array: [Int32(32), Int32(33)])], expectedCount: 1) {
            $0.setInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(predicate: "ANY setInt64 IN %@",
                    values: [NSArray(array: [Int64(64), Int64(65)])], expectedCount: 1) {
            $0.setInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(predicate: "ANY setFloat IN %@",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], expectedCount: 1) {
            $0.setFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(predicate: "ANY setDouble IN %@",
                    values: [NSArray(array: [123.456, 234.567])], expectedCount: 1) {
            $0.setDouble.containsAny(in: [123.456, 234.567])
        }
        assertQuery(predicate: "ANY setString IN %@",
                    values: [NSArray(array: ["Foo", "Bar"])], expectedCount: 1) {
            $0.setString.containsAny(in: ["Foo", "Bar"])
        }
        assertQuery(predicate: "ANY setBinary IN %@",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], expectedCount: 1) {
            $0.setBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(predicate: "ANY setDate IN %@",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], expectedCount: 1) {
            $0.setDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(predicate: "ANY setDecimal IN %@",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], expectedCount: 1) {
            $0.setDecimal.containsAny(in: [Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(predicate: "ANY setObjectId IN %@",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], expectedCount: 1) {
            $0.setObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(predicate: "ANY setUuid IN %@",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], expectedCount: 1) {
            $0.setUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(predicate: "ANY setAny IN %@",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), "Hello"])], expectedCount: 1) {
            $0.setAny.containsAny(in: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
        }
        assertQuery(predicate: "ANY setOptBool IN %@",
                    values: [NSArray(array: [true, true])], expectedCount: 1) {
            $0.setOptBool.containsAny(in: [true, true])
        }
        assertQuery(predicate: "ANY setOptInt IN %@",
                    values: [NSArray(array: [1, 2])], expectedCount: 1) {
            $0.setOptInt.containsAny(in: [1, 2])
        }
        assertQuery(predicate: "ANY setOptInt8 IN %@",
                    values: [NSArray(array: [Int8(8), Int8(9)])], expectedCount: 1) {
            $0.setOptInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(predicate: "ANY setOptInt16 IN %@",
                    values: [NSArray(array: [Int16(16), Int16(17)])], expectedCount: 1) {
            $0.setOptInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(predicate: "ANY setOptInt32 IN %@",
                    values: [NSArray(array: [Int32(32), Int32(33)])], expectedCount: 1) {
            $0.setOptInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(predicate: "ANY setOptInt64 IN %@",
                    values: [NSArray(array: [Int64(64), Int64(65)])], expectedCount: 1) {
            $0.setOptInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(predicate: "ANY setOptFloat IN %@",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], expectedCount: 1) {
            $0.setOptFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(predicate: "ANY setOptDouble IN %@",
                    values: [NSArray(array: [123.456, 234.567])], expectedCount: 1) {
            $0.setOptDouble.containsAny(in: [123.456, 234.567])
        }
        assertQuery(predicate: "ANY setOptString IN %@",
                    values: [NSArray(array: ["Foo", "Bar"])], expectedCount: 1) {
            $0.setOptString.containsAny(in: ["Foo", "Bar"])
        }
        assertQuery(predicate: "ANY setOptBinary IN %@",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], expectedCount: 1) {
            $0.setOptBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(predicate: "ANY setOptDate IN %@",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], expectedCount: 1) {
            $0.setOptDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(predicate: "ANY setOptDecimal IN %@",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(234.567)])], expectedCount: 1) {
            $0.setOptDecimal.containsAny(in: [Decimal128(123.456), Decimal128(234.567)])
        }
        assertQuery(predicate: "ANY setOptUuid IN %@",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], expectedCount: 1) {
            $0.setOptUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(predicate: "ANY setOptObjectId IN %@",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], expectedCount: 1) {
            $0.setOptObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }

        let realm = realmWithTestPath()
        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.set.insert(obj)
        try! realm.write {
            realm.add(colObj)
        }

        assertCollectionObjectQuery(predicate: "ANY set IN %@", values: [NSArray(array: [obj])], expectedCount: 1) {
            $0.set.containsAny(in: [obj])
        }
    }

    func testSetFromProperty() {
        let realm = realmWithTestPath()
        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.set.insert(obj)
        try! realm.write {
            realm.add(colObj)
        }

        assertCollectionQuery(on: \.boolCol,
                              isList: false,
                              predicate: "boolCol == %@",
                              values: [false],
                              expectedCount: 1) {
            $0.boolCol == false
        }
        assertCollectionQuery(on: \.intCol,
                              isList: false,
                              predicate: "intCol == %@",
                              values: [6],
                              expectedCount: 1) {
            $0.intCol == 6
        }
        assertCollectionQuery(on: \.int8Col,
                              isList: false,
                              predicate: "int8Col == %@",
                              values: [Int8(9)],
                              expectedCount: 1) {
            $0.int8Col == Int8(9)
        }
        assertCollectionQuery(on: \.int16Col,
                              isList: false,
                              predicate: "int16Col == %@",
                              values: [Int16(17)],
                              expectedCount: 1) {
            $0.int16Col == Int16(17)
        }
        assertCollectionQuery(on: \.int32Col,
                              isList: false,
                              predicate: "int32Col == %@",
                              values: [Int32(33)],
                              expectedCount: 1) {
            $0.int32Col == Int32(33)
        }
        assertCollectionQuery(on: \.int64Col,
                              isList: false,
                              predicate: "int64Col == %@",
                              values: [Int64(65)],
                              expectedCount: 1) {
            $0.int64Col == Int64(65)
        }
        assertCollectionQuery(on: \.floatCol,
                              isList: false,
                              predicate: "floatCol == %@",
                              values: [Float(6.55444333)],
                              expectedCount: 1) {
            $0.floatCol == Float(6.55444333)
        }
        assertCollectionQuery(on: \.doubleCol,
                              isList: false,
                              predicate: "doubleCol == %@",
                              values: [234.567],
                              expectedCount: 1) {
            $0.doubleCol == 234.567
        }
        assertCollectionQuery(on: \.stringCol,
                              isList: false,
                              predicate: "stringCol == %@",
                              values: ["Foó"],
                              expectedCount: 1) {
            $0.stringCol == "Foó"
        }
        assertCollectionQuery(on: \.binaryCol,
                              isList: false,
                              predicate: "binaryCol == %@",
                              values: [Data(count: 128)],
                              expectedCount: 1) {
            $0.binaryCol == Data(count: 128)
        }
        assertCollectionQuery(on: \.dateCol,
                              isList: false,
                              predicate: "dateCol == %@",
                              values: [Date(timeIntervalSince1970: 2000000)],
                              expectedCount: 1) {
            $0.dateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertCollectionQuery(on: \.decimalCol,
                              isList: false,
                              predicate: "decimalCol == %@",
                              values: [Decimal128(234.567)],
                              expectedCount: 1) {
            $0.decimalCol == Decimal128(234.567)
        }
        assertCollectionQuery(on: \.objectIdCol,
                              isList: false,
                              predicate: "objectIdCol == %@",
                              values: [ObjectId("61184062c1d8f096a3695045")],
                              expectedCount: 1) {
            $0.objectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertCollectionQuery(on: \.intEnumCol,
                              isList: false,
                              predicate: "intEnumCol == %@",
                              values: [ModernIntEnum.value2.rawValue],
                              expectedCount: 1) {
            $0.intEnumCol == .value2
        }
        assertCollectionQuery(on: \.stringEnumCol,
                              isList: false,
                              predicate: "stringEnumCol == %@",
                              values: [ModernStringEnum.value2.rawValue],
                              expectedCount: 1) {
            $0.stringEnumCol == .value2
        }
        assertCollectionQuery(on: \.uuidCol,
                              isList: false,
                              predicate: "uuidCol == %@",
                              values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!],
                              expectedCount: 1) {
            $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
        assertCollectionQuery(on: \.optBoolCol,
                              isList: false,
                              predicate: "optBoolCol == %@",
                              values: [false],
                              expectedCount: 1) {
            $0.optBoolCol == false
        }
        assertCollectionQuery(on: \.optIntCol,
                              isList: false,
                              predicate: "optIntCol == %@",
                              values: [6],
                              expectedCount: 1) {
            $0.optIntCol == 6
        }
        assertCollectionQuery(on: \.optInt8Col,
                              isList: false,
                              predicate: "optInt8Col == %@",
                              values: [Int8(9)],
                              expectedCount: 1) {
            $0.optInt8Col == Int8(9)
        }
        assertCollectionQuery(on: \.optInt16Col,
                              isList: false,
                              predicate: "optInt16Col == %@",
                              values: [Int16(17)],
                              expectedCount: 1) {
            $0.optInt16Col == Int16(17)
        }
        assertCollectionQuery(on: \.optInt32Col,
                              isList: false,
                              predicate: "optInt32Col == %@",
                              values: [Int32(33)],
                              expectedCount: 1) {
            $0.optInt32Col == Int32(33)
        }
        assertCollectionQuery(on: \.optInt64Col,
                              isList: false,
                              predicate: "optInt64Col == %@",
                              values: [Int64(65)],
                              expectedCount: 1) {
            $0.optInt64Col == Int64(65)
        }
        assertCollectionQuery(on: \.optFloatCol,
                              isList: false,
                              predicate: "optFloatCol == %@",
                              values: [Float(6.55444333)],
                              expectedCount: 1) {
            $0.optFloatCol == Float(6.55444333)
        }
        assertCollectionQuery(on: \.optDoubleCol,
                              isList: false,
                              predicate: "optDoubleCol == %@",
                              values: [234.567],
                              expectedCount: 1) {
            $0.optDoubleCol == 234.567
        }
        assertCollectionQuery(on: \.optStringCol,
                              isList: false,
                              predicate: "optStringCol == %@",
                              values: ["Foó"],
                              expectedCount: 1) {
            $0.optStringCol == "Foó"
        }
        assertCollectionQuery(on: \.optBinaryCol,
                              isList: false,
                              predicate: "optBinaryCol == %@",
                              values: [Data(count: 128)],
                              expectedCount: 1) {
            $0.optBinaryCol == Data(count: 128)
        }
        assertCollectionQuery(on: \.optDateCol,
                              isList: false,
                              predicate: "optDateCol == %@",
                              values: [Date(timeIntervalSince1970: 2000000)],
                              expectedCount: 1) {
            $0.optDateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertCollectionQuery(on: \.optDecimalCol,
                              isList: false,
                              predicate: "optDecimalCol == %@",
                              values: [Decimal128(234.567)],
                              expectedCount: 1) {
            $0.optDecimalCol == Decimal128(234.567)
        }
        assertCollectionQuery(on: \.optObjectIdCol,
                              isList: false,
                              predicate: "optObjectIdCol == %@",
                              values: [ObjectId("61184062c1d8f096a3695045")],
                              expectedCount: 1) {
            $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertCollectionQuery(on: \.optIntEnumCol,
                              isList: false,
                              predicate: "optIntEnumCol == %@",
                              values: [ModernIntEnum.value2.rawValue],
                              expectedCount: 1) {
            $0.optIntEnumCol == .value2
        }
        assertCollectionQuery(on: \.optStringEnumCol,
                              isList: false,
                              predicate: "optStringEnumCol == %@",
                              values: [ModernStringEnum.value2.rawValue],
                              expectedCount: 1) {
            $0.optStringEnumCol == .value2
        }
        assertCollectionQuery(on: \.optUuidCol,
                              isList: false,
                              predicate: "optUuidCol == %@",
                              values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!],
                              expectedCount: 1) {
            $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
    }

    // MARK: - Map

    func testMapContainsElement() {
        assertQuery(predicate: "%@ IN mapBool", values: [true], expectedCount: 1) {
            $0.mapBool.contains(true)
        }
        assertQuery(predicate: "%@ IN mapBool", values: [false], expectedCount: 0) {
            $0.mapBool.contains(false)
        }

        assertQuery(predicate: "%@ IN mapInt", values: [1], expectedCount: 1) {
            $0.mapInt.contains(1)
        }
        assertQuery(predicate: "%@ IN mapInt", values: [3], expectedCount: 0) {
            $0.mapInt.contains(3)
        }

        assertQuery(predicate: "%@ IN mapInt8", values: [Int8(8)], expectedCount: 1) {
            $0.mapInt8.contains(Int8(8))
        }
        assertQuery(predicate: "%@ IN mapInt8", values: [Int8(10)], expectedCount: 0) {
            $0.mapInt8.contains(Int8(10))
        }

        assertQuery(predicate: "%@ IN mapInt16", values: [Int16(16)], expectedCount: 1) {
            $0.mapInt16.contains(Int16(16))
        }
        assertQuery(predicate: "%@ IN mapInt16", values: [Int16(18)], expectedCount: 0) {
            $0.mapInt16.contains(Int16(18))
        }

        assertQuery(predicate: "%@ IN mapInt32", values: [Int32(32)], expectedCount: 1) {
            $0.mapInt32.contains(Int32(32))
        }
        assertQuery(predicate: "%@ IN mapInt32", values: [Int32(34)], expectedCount: 0) {
            $0.mapInt32.contains(Int32(34))
        }

        assertQuery(predicate: "%@ IN mapInt64", values: [Int64(64)], expectedCount: 1) {
            $0.mapInt64.contains(Int64(64))
        }
        assertQuery(predicate: "%@ IN mapInt64", values: [Int64(66)], expectedCount: 0) {
            $0.mapInt64.contains(Int64(66))
        }

        assertQuery(predicate: "%@ IN mapFloat", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat.contains(Float(5.55444333))
        }
        assertQuery(predicate: "%@ IN mapFloat", values: [Float(7.55444333)], expectedCount: 0) {
            $0.mapFloat.contains(Float(7.55444333))
        }

        assertQuery(predicate: "%@ IN mapDouble", values: [123.456], expectedCount: 1) {
            $0.mapDouble.contains(123.456)
        }
        assertQuery(predicate: "%@ IN mapDouble", values: [345.567], expectedCount: 0) {
            $0.mapDouble.contains(345.567)
        }

        assertQuery(predicate: "%@ IN mapString", values: ["Foo"], expectedCount: 1) {
            $0.mapString.contains("Foo")
        }
        assertQuery(predicate: "%@ IN mapString", values: ["Baz"], expectedCount: 0) {
            $0.mapString.contains("Baz")
        }

        assertQuery(predicate: "%@ IN mapBinary", values: [Data(count: 64)], expectedCount: 1) {
            $0.mapBinary.contains(Data(count: 64))
        }
        assertQuery(predicate: "%@ IN mapBinary", values: [Data(count: 256)], expectedCount: 0) {
            $0.mapBinary.contains(Data(count: 256))
        }

        assertQuery(predicate: "%@ IN mapDate", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate.contains(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(predicate: "%@ IN mapDate", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 0) {
            $0.mapDate.contains(Date(timeIntervalSince1970: 3000000))
        }

        assertQuery(predicate: "%@ IN mapDecimal", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal.contains(Decimal128(123.456))
        }
        assertQuery(predicate: "%@ IN mapDecimal", values: [Decimal128(963.852)], expectedCount: 0) {
            $0.mapDecimal.contains(Decimal128(963.852))
        }

        assertQuery(predicate: "%@ IN mapObjectId", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapObjectId.contains(ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(predicate: "%@ IN mapObjectId", values: [ObjectId("61184062c1d8f096a3695044")], expectedCount: 0) {
            $0.mapObjectId.contains(ObjectId("61184062c1d8f096a3695044"))
        }

        assertQuery(predicate: "%@ IN mapUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.mapUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(predicate: "%@ IN mapUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!], expectedCount: 0) {
            $0.mapUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!)
        }

        assertQuery(predicate: "%@ IN mapAny", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapAny.contains(AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")))
        }
        assertQuery(predicate: "%@ IN mapAny", values: [123], expectedCount: 0) {
            $0.mapAny.contains(AnyRealmValue.int(123))
        }

        assertQuery(predicate: "%@ IN mapOptBool", values: [true], expectedCount: 1) {
            $0.mapOptBool.contains(true)
        }
        assertQuery(predicate: "%@ IN mapOptBool", values: [false], expectedCount: 0) {
            $0.mapOptBool.contains(false)
        }
        assertQuery(predicate: "%@ IN mapOptBool", values: [NSNull()], expectedCount: 0) {
            $0.mapOptBool.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptInt", values: [1], expectedCount: 1) {
            $0.mapOptInt.contains(1)
        }
        assertQuery(predicate: "%@ IN mapOptInt", values: [3], expectedCount: 0) {
            $0.mapOptInt.contains(3)
        }
        assertQuery(predicate: "%@ IN mapOptInt", values: [NSNull()], expectedCount: 0) {
            $0.mapOptInt.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptInt8", values: [Int8(8)], expectedCount: 1) {
            $0.mapOptInt8.contains(Int8(8))
        }
        assertQuery(predicate: "%@ IN mapOptInt8", values: [Int8(10)], expectedCount: 0) {
            $0.mapOptInt8.contains(Int8(10))
        }
        assertQuery(predicate: "%@ IN mapOptInt8", values: [NSNull()], expectedCount: 0) {
            $0.mapOptInt8.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptInt16", values: [Int16(16)], expectedCount: 1) {
            $0.mapOptInt16.contains(Int16(16))
        }
        assertQuery(predicate: "%@ IN mapOptInt16", values: [Int16(18)], expectedCount: 0) {
            $0.mapOptInt16.contains(Int16(18))
        }
        assertQuery(predicate: "%@ IN mapOptInt16", values: [NSNull()], expectedCount: 0) {
            $0.mapOptInt16.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptInt32", values: [Int32(32)], expectedCount: 1) {
            $0.mapOptInt32.contains(Int32(32))
        }
        assertQuery(predicate: "%@ IN mapOptInt32", values: [Int32(34)], expectedCount: 0) {
            $0.mapOptInt32.contains(Int32(34))
        }
        assertQuery(predicate: "%@ IN mapOptInt32", values: [NSNull()], expectedCount: 0) {
            $0.mapOptInt32.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptInt64", values: [Int64(64)], expectedCount: 1) {
            $0.mapOptInt64.contains(Int64(64))
        }
        assertQuery(predicate: "%@ IN mapOptInt64", values: [Int64(66)], expectedCount: 0) {
            $0.mapOptInt64.contains(Int64(66))
        }
        assertQuery(predicate: "%@ IN mapOptInt64", values: [NSNull()], expectedCount: 0) {
            $0.mapOptInt64.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptFloat", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat.contains(Float(5.55444333))
        }
        assertQuery(predicate: "%@ IN mapOptFloat", values: [Float(7.55444333)], expectedCount: 0) {
            $0.mapOptFloat.contains(Float(7.55444333))
        }
        assertQuery(predicate: "%@ IN mapOptFloat", values: [NSNull()], expectedCount: 0) {
            $0.mapOptFloat.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptDouble", values: [123.456], expectedCount: 1) {
            $0.mapOptDouble.contains(123.456)
        }
        assertQuery(predicate: "%@ IN mapOptDouble", values: [345.567], expectedCount: 0) {
            $0.mapOptDouble.contains(345.567)
        }
        assertQuery(predicate: "%@ IN mapOptDouble", values: [NSNull()], expectedCount: 0) {
            $0.mapOptDouble.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptString", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.contains("Foo")
        }
        assertQuery(predicate: "%@ IN mapOptString", values: ["Baz"], expectedCount: 0) {
            $0.mapOptString.contains("Baz")
        }
        assertQuery(predicate: "%@ IN mapOptString", values: [NSNull()], expectedCount: 0) {
            $0.mapOptString.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptBinary", values: [Data(count: 64)], expectedCount: 1) {
            $0.mapOptBinary.contains(Data(count: 64))
        }
        assertQuery(predicate: "%@ IN mapOptBinary", values: [Data(count: 256)], expectedCount: 0) {
            $0.mapOptBinary.contains(Data(count: 256))
        }
        assertQuery(predicate: "%@ IN mapOptBinary", values: [NSNull()], expectedCount: 0) {
            $0.mapOptBinary.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptDate", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate.contains(Date(timeIntervalSince1970: 1000000))
        }
        assertQuery(predicate: "%@ IN mapOptDate", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 0) {
            $0.mapOptDate.contains(Date(timeIntervalSince1970: 3000000))
        }
        assertQuery(predicate: "%@ IN mapOptDate", values: [NSNull()], expectedCount: 0) {
            $0.mapOptDate.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptDecimal", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal.contains(Decimal128(123.456))
        }
        assertQuery(predicate: "%@ IN mapOptDecimal", values: [Decimal128(963.852)], expectedCount: 0) {
            $0.mapOptDecimal.contains(Decimal128(963.852))
        }
        assertQuery(predicate: "%@ IN mapOptDecimal", values: [NSNull()], expectedCount: 0) {
            $0.mapOptDecimal.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.mapOptUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!)
        }
        assertQuery(predicate: "%@ IN mapOptUuid", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!], expectedCount: 0) {
            $0.mapOptUuid.contains(UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d08e")!)
        }
        assertQuery(predicate: "%@ IN mapOptUuid", values: [NSNull()], expectedCount: 0) {
            $0.mapOptUuid.contains(nil)
        }

        assertQuery(predicate: "%@ IN mapOptObjectId", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapOptObjectId.contains(ObjectId("61184062c1d8f096a3695046"))
        }
        assertQuery(predicate: "%@ IN mapOptObjectId", values: [ObjectId("61184062c1d8f096a3695044")], expectedCount: 0) {
            $0.mapOptObjectId.contains(ObjectId("61184062c1d8f096a3695044"))
        }
        assertQuery(predicate: "%@ IN mapOptObjectId", values: [NSNull()], expectedCount: 0) {
            $0.mapOptObjectId.contains(nil)
        }

    }

    func testMapAllKeys() {
        assertQuery(predicate: "mapBool.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapBool.keys == "foo"
        }

        assertQuery(predicate: "mapBool.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapBool.keys != "foo"
        }

        assertQuery(predicate: "mapBool.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapBool.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapBool.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapBool.keys.contains("foo")
        }

        assertQuery(predicate: "mapBool.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapBool.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapBool.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapBool.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapBool.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapBool.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapBool.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapBool.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapBool.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapBool.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapBool.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapBool.keys.like("foo")
        }

        assertQuery(predicate: "mapInt.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt.keys == "foo"
        }

        assertQuery(predicate: "mapInt.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt.keys != "foo"
        }

        assertQuery(predicate: "mapInt.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt.keys.contains("foo")
        }

        assertQuery(predicate: "mapInt.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapInt.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapInt.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapInt.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt.keys.like("foo")
        }

        assertQuery(predicate: "mapInt8.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt8.keys == "foo"
        }

        assertQuery(predicate: "mapInt8.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt8.keys != "foo"
        }

        assertQuery(predicate: "mapInt8.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt8.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt8.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt8.keys.contains("foo")
        }

        assertQuery(predicate: "mapInt8.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt8.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt8.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt8.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapInt8.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt8.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt8.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt8.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapInt8.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt8.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapInt8.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt8.keys.like("foo")
        }

        assertQuery(predicate: "mapInt16.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt16.keys == "foo"
        }

        assertQuery(predicate: "mapInt16.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt16.keys != "foo"
        }

        assertQuery(predicate: "mapInt16.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt16.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt16.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt16.keys.contains("foo")
        }

        assertQuery(predicate: "mapInt16.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt16.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt16.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt16.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapInt16.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt16.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt16.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt16.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapInt16.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt16.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapInt16.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt16.keys.like("foo")
        }

        assertQuery(predicate: "mapInt32.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt32.keys == "foo"
        }

        assertQuery(predicate: "mapInt32.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt32.keys != "foo"
        }

        assertQuery(predicate: "mapInt32.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt32.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt32.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt32.keys.contains("foo")
        }

        assertQuery(predicate: "mapInt32.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt32.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt32.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt32.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapInt32.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt32.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt32.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt32.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapInt32.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt32.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapInt32.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt32.keys.like("foo")
        }

        assertQuery(predicate: "mapInt64.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt64.keys == "foo"
        }

        assertQuery(predicate: "mapInt64.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt64.keys != "foo"
        }

        assertQuery(predicate: "mapInt64.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt64.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt64.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt64.keys.contains("foo")
        }

        assertQuery(predicate: "mapInt64.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt64.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt64.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt64.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapInt64.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt64.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapInt64.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt64.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapInt64.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt64.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapInt64.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapInt64.keys.like("foo")
        }

        assertQuery(predicate: "mapFloat.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapFloat.keys == "foo"
        }

        assertQuery(predicate: "mapFloat.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapFloat.keys != "foo"
        }

        assertQuery(predicate: "mapFloat.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapFloat.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapFloat.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapFloat.keys.contains("foo")
        }

        assertQuery(predicate: "mapFloat.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapFloat.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapFloat.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapFloat.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapFloat.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapFloat.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapFloat.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapFloat.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapFloat.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapFloat.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapFloat.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapFloat.keys.like("foo")
        }

        assertQuery(predicate: "mapDouble.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapDouble.keys == "foo"
        }

        assertQuery(predicate: "mapDouble.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapDouble.keys != "foo"
        }

        assertQuery(predicate: "mapDouble.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDouble.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapDouble.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapDouble.keys.contains("foo")
        }

        assertQuery(predicate: "mapDouble.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDouble.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapDouble.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapDouble.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapDouble.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDouble.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapDouble.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapDouble.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapDouble.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDouble.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapDouble.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapDouble.keys.like("foo")
        }

        assertQuery(predicate: "mapString.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapString.keys == "foo"
        }

        assertQuery(predicate: "mapString.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapString.keys != "foo"
        }

        assertQuery(predicate: "mapString.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapString.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapString.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapString.keys.contains("foo")
        }

        assertQuery(predicate: "mapString.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapString.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapString.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapString.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapString.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapString.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapString.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapString.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapString.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapString.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapString.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapString.keys.like("foo")
        }

        assertQuery(predicate: "mapBinary.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapBinary.keys == "foo"
        }

        assertQuery(predicate: "mapBinary.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapBinary.keys != "foo"
        }

        assertQuery(predicate: "mapBinary.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapBinary.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapBinary.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapBinary.keys.contains("foo")
        }

        assertQuery(predicate: "mapBinary.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapBinary.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapBinary.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapBinary.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapBinary.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapBinary.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapBinary.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapBinary.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapBinary.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapBinary.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapBinary.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapBinary.keys.like("foo")
        }

        assertQuery(predicate: "mapDate.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapDate.keys == "foo"
        }

        assertQuery(predicate: "mapDate.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapDate.keys != "foo"
        }

        assertQuery(predicate: "mapDate.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDate.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapDate.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapDate.keys.contains("foo")
        }

        assertQuery(predicate: "mapDate.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDate.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapDate.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapDate.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapDate.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDate.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapDate.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapDate.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapDate.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDate.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapDate.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapDate.keys.like("foo")
        }

        assertQuery(predicate: "mapDecimal.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapDecimal.keys == "foo"
        }

        assertQuery(predicate: "mapDecimal.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapDecimal.keys != "foo"
        }

        assertQuery(predicate: "mapDecimal.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDecimal.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapDecimal.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapDecimal.keys.contains("foo")
        }

        assertQuery(predicate: "mapDecimal.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDecimal.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapDecimal.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapDecimal.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapDecimal.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDecimal.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapDecimal.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapDecimal.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapDecimal.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapDecimal.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapDecimal.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapDecimal.keys.like("foo")
        }

        assertQuery(predicate: "mapObjectId.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapObjectId.keys == "foo"
        }

        assertQuery(predicate: "mapObjectId.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapObjectId.keys != "foo"
        }

        assertQuery(predicate: "mapObjectId.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapObjectId.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapObjectId.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapObjectId.keys.contains("foo")
        }

        assertQuery(predicate: "mapObjectId.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapObjectId.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapObjectId.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapObjectId.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapObjectId.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapObjectId.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapObjectId.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapObjectId.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapObjectId.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapObjectId.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapObjectId.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapObjectId.keys.like("foo")
        }

        assertQuery(predicate: "mapUuid.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapUuid.keys == "foo"
        }

        assertQuery(predicate: "mapUuid.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapUuid.keys != "foo"
        }

        assertQuery(predicate: "mapUuid.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapUuid.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapUuid.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapUuid.keys.contains("foo")
        }

        assertQuery(predicate: "mapUuid.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapUuid.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapUuid.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapUuid.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapUuid.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapUuid.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapUuid.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapUuid.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapUuid.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapUuid.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapUuid.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapUuid.keys.like("foo")
        }

        assertQuery(predicate: "mapAny.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapAny.keys == "foo"
        }

        assertQuery(predicate: "mapAny.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapAny.keys != "foo"
        }

        assertQuery(predicate: "mapAny.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapAny.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapAny.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapAny.keys.contains("foo")
        }

        assertQuery(predicate: "mapAny.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapAny.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapAny.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapAny.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapAny.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapAny.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapAny.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapAny.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapAny.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapAny.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapAny.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapAny.keys.like("foo")
        }

        assertQuery(predicate: "mapOptBool.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBool.keys == "foo"
        }

        assertQuery(predicate: "mapOptBool.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBool.keys != "foo"
        }

        assertQuery(predicate: "mapOptBool.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBool.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptBool.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBool.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptBool.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBool.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptBool.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBool.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptBool.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBool.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptBool.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBool.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptBool.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBool.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptBool.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBool.keys.like("foo")
        }

        assertQuery(predicate: "mapOptInt.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt.keys == "foo"
        }

        assertQuery(predicate: "mapOptInt.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt.keys != "foo"
        }

        assertQuery(predicate: "mapOptInt.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptInt.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptInt.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptInt.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptInt.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt.keys.like("foo")
        }

        assertQuery(predicate: "mapOptInt8.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt8.keys == "foo"
        }

        assertQuery(predicate: "mapOptInt8.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt8.keys != "foo"
        }

        assertQuery(predicate: "mapOptInt8.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt8.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt8.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt8.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptInt8.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt8.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt8.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt8.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptInt8.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt8.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt8.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt8.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptInt8.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt8.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptInt8.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt8.keys.like("foo")
        }

        assertQuery(predicate: "mapOptInt16.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt16.keys == "foo"
        }

        assertQuery(predicate: "mapOptInt16.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt16.keys != "foo"
        }

        assertQuery(predicate: "mapOptInt16.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt16.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt16.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt16.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptInt16.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt16.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt16.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt16.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptInt16.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt16.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt16.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt16.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptInt16.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt16.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptInt16.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt16.keys.like("foo")
        }

        assertQuery(predicate: "mapOptInt32.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt32.keys == "foo"
        }

        assertQuery(predicate: "mapOptInt32.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt32.keys != "foo"
        }

        assertQuery(predicate: "mapOptInt32.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt32.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt32.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt32.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptInt32.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt32.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt32.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt32.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptInt32.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt32.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt32.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt32.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptInt32.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt32.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptInt32.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt32.keys.like("foo")
        }

        assertQuery(predicate: "mapOptInt64.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt64.keys == "foo"
        }

        assertQuery(predicate: "mapOptInt64.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt64.keys != "foo"
        }

        assertQuery(predicate: "mapOptInt64.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt64.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt64.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt64.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptInt64.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt64.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt64.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt64.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptInt64.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt64.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptInt64.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt64.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptInt64.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt64.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptInt64.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptInt64.keys.like("foo")
        }

        assertQuery(predicate: "mapOptFloat.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptFloat.keys == "foo"
        }

        assertQuery(predicate: "mapOptFloat.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptFloat.keys != "foo"
        }

        assertQuery(predicate: "mapOptFloat.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptFloat.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptFloat.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptFloat.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptFloat.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptFloat.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptFloat.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptFloat.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptFloat.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptFloat.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptFloat.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptFloat.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptFloat.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptFloat.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptFloat.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptFloat.keys.like("foo")
        }

        assertQuery(predicate: "mapOptDouble.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDouble.keys == "foo"
        }

        assertQuery(predicate: "mapOptDouble.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDouble.keys != "foo"
        }

        assertQuery(predicate: "mapOptDouble.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDouble.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptDouble.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDouble.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptDouble.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDouble.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptDouble.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDouble.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptDouble.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDouble.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptDouble.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDouble.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptDouble.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDouble.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptDouble.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDouble.keys.like("foo")
        }

        assertQuery(predicate: "mapOptString.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptString.keys == "foo"
        }

        assertQuery(predicate: "mapOptString.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptString.keys != "foo"
        }

        assertQuery(predicate: "mapOptString.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptString.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptString.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptString.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptString.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptString.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptString.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptString.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptString.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptString.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptString.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptString.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptString.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptString.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptString.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptString.keys.like("foo")
        }

        assertQuery(predicate: "mapOptBinary.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBinary.keys == "foo"
        }

        assertQuery(predicate: "mapOptBinary.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBinary.keys != "foo"
        }

        assertQuery(predicate: "mapOptBinary.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBinary.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptBinary.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBinary.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptBinary.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBinary.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptBinary.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBinary.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptBinary.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBinary.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptBinary.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBinary.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptBinary.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBinary.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptBinary.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptBinary.keys.like("foo")
        }

        assertQuery(predicate: "mapOptDate.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDate.keys == "foo"
        }

        assertQuery(predicate: "mapOptDate.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDate.keys != "foo"
        }

        assertQuery(predicate: "mapOptDate.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDate.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptDate.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDate.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptDate.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDate.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptDate.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDate.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptDate.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDate.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptDate.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDate.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptDate.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDate.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptDate.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDate.keys.like("foo")
        }

        assertQuery(predicate: "mapOptDecimal.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDecimal.keys == "foo"
        }

        assertQuery(predicate: "mapOptDecimal.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDecimal.keys != "foo"
        }

        assertQuery(predicate: "mapOptDecimal.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDecimal.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptDecimal.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDecimal.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptDecimal.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDecimal.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptDecimal.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDecimal.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptDecimal.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDecimal.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptDecimal.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDecimal.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptDecimal.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDecimal.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptDecimal.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptDecimal.keys.like("foo")
        }

        assertQuery(predicate: "mapOptUuid.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptUuid.keys == "foo"
        }

        assertQuery(predicate: "mapOptUuid.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptUuid.keys != "foo"
        }

        assertQuery(predicate: "mapOptUuid.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptUuid.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptUuid.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptUuid.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptUuid.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptUuid.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptUuid.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptUuid.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptUuid.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptUuid.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptUuid.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptUuid.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptUuid.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptUuid.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptUuid.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptUuid.keys.like("foo")
        }

        assertQuery(predicate: "mapOptObjectId.@allKeys == %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptObjectId.keys == "foo"
        }

        assertQuery(predicate: "mapOptObjectId.@allKeys != %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptObjectId.keys != "foo"
        }

        assertQuery(predicate: "mapOptObjectId.@allKeys CONTAINS[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptObjectId.keys.contains("foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptObjectId.@allKeys CONTAINS %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptObjectId.keys.contains("foo")
        }

        assertQuery(predicate: "mapOptObjectId.@allKeys BEGINSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptObjectId.keys.starts(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptObjectId.@allKeys BEGINSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptObjectId.keys.starts(with: "foo")
        }

        assertQuery(predicate: "mapOptObjectId.@allKeys ENDSWITH[cd] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptObjectId.keys.ends(with: "foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptObjectId.@allKeys ENDSWITH %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptObjectId.keys.ends(with: "foo")
        }

        assertQuery(predicate: "mapOptObjectId.@allKeys LIKE[c] %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptObjectId.keys.like("foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptObjectId.@allKeys LIKE %@", values: ["foo"], expectedCount: 1) {
            $0.mapOptObjectId.keys.like("foo")
        }

    }

    func testMapAllValues() {
        assertQuery(predicate: "mapBool.@allValues == %@", values: [true], expectedCount: 1) {
            $0.mapBool.values == true
        }

        assertQuery(predicate: "mapBool.@allValues != %@", values: [true], expectedCount: 0) {
            $0.mapBool.values != true
        }

        assertQuery(predicate: "mapInt.@allValues == %@", values: [1], expectedCount: 1) {
            $0.mapInt.values == 1
        }

        assertQuery(predicate: "mapInt.@allValues != %@", values: [1], expectedCount: 1) {
            $0.mapInt.values != 1
        }
        assertQuery(predicate: "mapInt.@allValues > %@", values: [1], expectedCount: 1) {
            $0.mapInt.values > 1
        }

        assertQuery(predicate: "mapInt.@allValues >= %@", values: [1], expectedCount: 1) {
            $0.mapInt.values >= 1
        }
        assertQuery(predicate: "mapInt.@allValues < %@", values: [1], expectedCount: 0) {
            $0.mapInt.values < 1
        }

        assertQuery(predicate: "mapInt.@allValues <= %@", values: [1], expectedCount: 1) {
            $0.mapInt.values <= 1
        }

        assertQuery(predicate: "mapInt8.@allValues == %@", values: [Int8(8)], expectedCount: 1) {
            $0.mapInt8.values == Int8(8)
        }

        assertQuery(predicate: "mapInt8.@allValues != %@", values: [Int8(8)], expectedCount: 1) {
            $0.mapInt8.values != Int8(8)
        }
        assertQuery(predicate: "mapInt8.@allValues > %@", values: [Int8(8)], expectedCount: 1) {
            $0.mapInt8.values > Int8(8)
        }

        assertQuery(predicate: "mapInt8.@allValues >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.mapInt8.values >= Int8(8)
        }
        assertQuery(predicate: "mapInt8.@allValues < %@", values: [Int8(8)], expectedCount: 0) {
            $0.mapInt8.values < Int8(8)
        }

        assertQuery(predicate: "mapInt8.@allValues <= %@", values: [Int8(8)], expectedCount: 1) {
            $0.mapInt8.values <= Int8(8)
        }

        assertQuery(predicate: "mapInt16.@allValues == %@", values: [Int16(16)], expectedCount: 1) {
            $0.mapInt16.values == Int16(16)
        }

        assertQuery(predicate: "mapInt16.@allValues != %@", values: [Int16(16)], expectedCount: 1) {
            $0.mapInt16.values != Int16(16)
        }
        assertQuery(predicate: "mapInt16.@allValues > %@", values: [Int16(16)], expectedCount: 1) {
            $0.mapInt16.values > Int16(16)
        }

        assertQuery(predicate: "mapInt16.@allValues >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.mapInt16.values >= Int16(16)
        }
        assertQuery(predicate: "mapInt16.@allValues < %@", values: [Int16(16)], expectedCount: 0) {
            $0.mapInt16.values < Int16(16)
        }

        assertQuery(predicate: "mapInt16.@allValues <= %@", values: [Int16(16)], expectedCount: 1) {
            $0.mapInt16.values <= Int16(16)
        }

        assertQuery(predicate: "mapInt32.@allValues == %@", values: [Int32(32)], expectedCount: 1) {
            $0.mapInt32.values == Int32(32)
        }

        assertQuery(predicate: "mapInt32.@allValues != %@", values: [Int32(32)], expectedCount: 1) {
            $0.mapInt32.values != Int32(32)
        }
        assertQuery(predicate: "mapInt32.@allValues > %@", values: [Int32(32)], expectedCount: 1) {
            $0.mapInt32.values > Int32(32)
        }

        assertQuery(predicate: "mapInt32.@allValues >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.mapInt32.values >= Int32(32)
        }
        assertQuery(predicate: "mapInt32.@allValues < %@", values: [Int32(32)], expectedCount: 0) {
            $0.mapInt32.values < Int32(32)
        }

        assertQuery(predicate: "mapInt32.@allValues <= %@", values: [Int32(32)], expectedCount: 1) {
            $0.mapInt32.values <= Int32(32)
        }

        assertQuery(predicate: "mapInt64.@allValues == %@", values: [Int64(64)], expectedCount: 1) {
            $0.mapInt64.values == Int64(64)
        }

        assertQuery(predicate: "mapInt64.@allValues != %@", values: [Int64(64)], expectedCount: 1) {
            $0.mapInt64.values != Int64(64)
        }
        assertQuery(predicate: "mapInt64.@allValues > %@", values: [Int64(64)], expectedCount: 1) {
            $0.mapInt64.values > Int64(64)
        }

        assertQuery(predicate: "mapInt64.@allValues >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.mapInt64.values >= Int64(64)
        }
        assertQuery(predicate: "mapInt64.@allValues < %@", values: [Int64(64)], expectedCount: 0) {
            $0.mapInt64.values < Int64(64)
        }

        assertQuery(predicate: "mapInt64.@allValues <= %@", values: [Int64(64)], expectedCount: 1) {
            $0.mapInt64.values <= Int64(64)
        }

        assertQuery(predicate: "mapFloat.@allValues == %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat.values == Float(5.55444333)
        }

        assertQuery(predicate: "mapFloat.@allValues != %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat.values != Float(5.55444333)
        }
        assertQuery(predicate: "mapFloat.@allValues > %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat.values > Float(5.55444333)
        }

        assertQuery(predicate: "mapFloat.@allValues >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat.values >= Float(5.55444333)
        }
        assertQuery(predicate: "mapFloat.@allValues < %@", values: [Float(5.55444333)], expectedCount: 0) {
            $0.mapFloat.values < Float(5.55444333)
        }

        assertQuery(predicate: "mapFloat.@allValues <= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat.values <= Float(5.55444333)
        }

        assertQuery(predicate: "mapDouble.@allValues == %@", values: [123.456], expectedCount: 1) {
            $0.mapDouble.values == 123.456
        }

        assertQuery(predicate: "mapDouble.@allValues != %@", values: [123.456], expectedCount: 1) {
            $0.mapDouble.values != 123.456
        }
        assertQuery(predicate: "mapDouble.@allValues > %@", values: [123.456], expectedCount: 1) {
            $0.mapDouble.values > 123.456
        }

        assertQuery(predicate: "mapDouble.@allValues >= %@", values: [123.456], expectedCount: 1) {
            $0.mapDouble.values >= 123.456
        }
        assertQuery(predicate: "mapDouble.@allValues < %@", values: [123.456], expectedCount: 0) {
            $0.mapDouble.values < 123.456
        }

        assertQuery(predicate: "mapDouble.@allValues <= %@", values: [123.456], expectedCount: 1) {
            $0.mapDouble.values <= 123.456
        }

        assertQuery(predicate: "mapString.@allValues == %@", values: ["Foo"], expectedCount: 1) {
            $0.mapString.values == "Foo"
        }

        assertQuery(predicate: "mapString.@allValues != %@", values: ["Foo"], expectedCount: 1) {
            $0.mapString.values != "Foo"
        }

        assertQuery(predicate: "mapString.@allValues CONTAINS[cd] %@", values: ["Foo"], expectedCount: 1) {
            $0.mapString.values.contains("Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapString.@allValues CONTAINS %@", values: ["Foo"], expectedCount: 1) {
            $0.mapString.values.contains("Foo")
        }

        assertQuery(predicate: "mapString.@allValues BEGINSWITH[cd] %@", values: ["Foo"], expectedCount: 1) {
            $0.mapString.values.starts(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapString.@allValues BEGINSWITH %@", values: ["Foo"], expectedCount: 1) {
            $0.mapString.values.starts(with: "Foo")
        }

        assertQuery(predicate: "mapString.@allValues ENDSWITH[cd] %@", values: ["Foo"], expectedCount: 1) {
            $0.mapString.values.ends(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapString.@allValues ENDSWITH %@", values: ["Foo"], expectedCount: 1) {
            $0.mapString.values.ends(with: "Foo")
        }

        assertQuery(predicate: "mapString.@allValues LIKE[c] %@", values: ["Foo"], expectedCount: 1) {
            $0.mapString.values.like("Foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapString.@allValues LIKE %@", values: ["Foo"], expectedCount: 1) {
            $0.mapString.values.like("Foo")
        }
        assertQuery(predicate: "mapBinary.@allValues == %@", values: [Data(count: 64)], expectedCount: 1) {
            $0.mapBinary.values == Data(count: 64)
        }

        assertQuery(predicate: "mapBinary.@allValues != %@", values: [Data(count: 64)], expectedCount: 1) {
            $0.mapBinary.values != Data(count: 64)
        }

        assertQuery(predicate: "mapDate.@allValues == %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate.values == Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "mapDate.@allValues != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate.values != Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(predicate: "mapDate.@allValues > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate.values > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "mapDate.@allValues >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate.values >= Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(predicate: "mapDate.@allValues < %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.mapDate.values < Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "mapDate.@allValues <= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate.values <= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "mapDecimal.@allValues == %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal.values == Decimal128(123.456)
        }

        assertQuery(predicate: "mapDecimal.@allValues != %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal.values != Decimal128(123.456)
        }
        assertQuery(predicate: "mapDecimal.@allValues > %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal.values > Decimal128(123.456)
        }

        assertQuery(predicate: "mapDecimal.@allValues >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal.values >= Decimal128(123.456)
        }
        assertQuery(predicate: "mapDecimal.@allValues < %@", values: [Decimal128(123.456)], expectedCount: 0) {
            $0.mapDecimal.values < Decimal128(123.456)
        }

        assertQuery(predicate: "mapDecimal.@allValues <= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal.values <= Decimal128(123.456)
        }

        assertQuery(predicate: "mapObjectId.@allValues == %@", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapObjectId.values == ObjectId("61184062c1d8f096a3695046")
        }

        assertQuery(predicate: "mapObjectId.@allValues != %@", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapObjectId.values != ObjectId("61184062c1d8f096a3695046")
        }

        assertQuery(predicate: "mapUuid.@allValues == %@", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.mapUuid.values == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(predicate: "mapUuid.@allValues != %@", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.mapUuid.values != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(predicate: "mapAny.@allValues == %@", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapAny.values == AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
        }

        assertQuery(predicate: "mapAny.@allValues != %@", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapAny.values != AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
        }

        assertQuery(predicate: "mapOptBool.@allValues == %@", values: [true], expectedCount: 1) {
            $0.mapOptBool.values == true
        }

        assertQuery(predicate: "mapOptBool.@allValues != %@", values: [true], expectedCount: 0) {
            $0.mapOptBool.values != true
        }

        assertQuery(predicate: "mapOptInt.@allValues == %@", values: [1], expectedCount: 1) {
            $0.mapOptInt.values == 1
        }

        assertQuery(predicate: "mapOptInt.@allValues != %@", values: [1], expectedCount: 1) {
            $0.mapOptInt.values != 1
        }
        assertQuery(predicate: "mapOptInt.@allValues > %@", values: [1], expectedCount: 1) {
            $0.mapOptInt.values > 1
        }

        assertQuery(predicate: "mapOptInt.@allValues >= %@", values: [1], expectedCount: 1) {
            $0.mapOptInt.values >= 1
        }
        assertQuery(predicate: "mapOptInt.@allValues < %@", values: [1], expectedCount: 0) {
            $0.mapOptInt.values < 1
        }

        assertQuery(predicate: "mapOptInt.@allValues <= %@", values: [1], expectedCount: 1) {
            $0.mapOptInt.values <= 1
        }

        assertQuery(predicate: "mapOptInt8.@allValues == %@", values: [Int8(8)], expectedCount: 1) {
            $0.mapOptInt8.values == Int8(8)
        }

        assertQuery(predicate: "mapOptInt8.@allValues != %@", values: [Int8(8)], expectedCount: 1) {
            $0.mapOptInt8.values != Int8(8)
        }
        assertQuery(predicate: "mapOptInt8.@allValues > %@", values: [Int8(8)], expectedCount: 1) {
            $0.mapOptInt8.values > Int8(8)
        }

        assertQuery(predicate: "mapOptInt8.@allValues >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.mapOptInt8.values >= Int8(8)
        }
        assertQuery(predicate: "mapOptInt8.@allValues < %@", values: [Int8(8)], expectedCount: 0) {
            $0.mapOptInt8.values < Int8(8)
        }

        assertQuery(predicate: "mapOptInt8.@allValues <= %@", values: [Int8(8)], expectedCount: 1) {
            $0.mapOptInt8.values <= Int8(8)
        }

        assertQuery(predicate: "mapOptInt16.@allValues == %@", values: [Int16(16)], expectedCount: 1) {
            $0.mapOptInt16.values == Int16(16)
        }

        assertQuery(predicate: "mapOptInt16.@allValues != %@", values: [Int16(16)], expectedCount: 1) {
            $0.mapOptInt16.values != Int16(16)
        }
        assertQuery(predicate: "mapOptInt16.@allValues > %@", values: [Int16(16)], expectedCount: 1) {
            $0.mapOptInt16.values > Int16(16)
        }

        assertQuery(predicate: "mapOptInt16.@allValues >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.mapOptInt16.values >= Int16(16)
        }
        assertQuery(predicate: "mapOptInt16.@allValues < %@", values: [Int16(16)], expectedCount: 0) {
            $0.mapOptInt16.values < Int16(16)
        }

        assertQuery(predicate: "mapOptInt16.@allValues <= %@", values: [Int16(16)], expectedCount: 1) {
            $0.mapOptInt16.values <= Int16(16)
        }

        assertQuery(predicate: "mapOptInt32.@allValues == %@", values: [Int32(32)], expectedCount: 1) {
            $0.mapOptInt32.values == Int32(32)
        }

        assertQuery(predicate: "mapOptInt32.@allValues != %@", values: [Int32(32)], expectedCount: 1) {
            $0.mapOptInt32.values != Int32(32)
        }
        assertQuery(predicate: "mapOptInt32.@allValues > %@", values: [Int32(32)], expectedCount: 1) {
            $0.mapOptInt32.values > Int32(32)
        }

        assertQuery(predicate: "mapOptInt32.@allValues >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.mapOptInt32.values >= Int32(32)
        }
        assertQuery(predicate: "mapOptInt32.@allValues < %@", values: [Int32(32)], expectedCount: 0) {
            $0.mapOptInt32.values < Int32(32)
        }

        assertQuery(predicate: "mapOptInt32.@allValues <= %@", values: [Int32(32)], expectedCount: 1) {
            $0.mapOptInt32.values <= Int32(32)
        }

        assertQuery(predicate: "mapOptInt64.@allValues == %@", values: [Int64(64)], expectedCount: 1) {
            $0.mapOptInt64.values == Int64(64)
        }

        assertQuery(predicate: "mapOptInt64.@allValues != %@", values: [Int64(64)], expectedCount: 1) {
            $0.mapOptInt64.values != Int64(64)
        }
        assertQuery(predicate: "mapOptInt64.@allValues > %@", values: [Int64(64)], expectedCount: 1) {
            $0.mapOptInt64.values > Int64(64)
        }

        assertQuery(predicate: "mapOptInt64.@allValues >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.mapOptInt64.values >= Int64(64)
        }
        assertQuery(predicate: "mapOptInt64.@allValues < %@", values: [Int64(64)], expectedCount: 0) {
            $0.mapOptInt64.values < Int64(64)
        }

        assertQuery(predicate: "mapOptInt64.@allValues <= %@", values: [Int64(64)], expectedCount: 1) {
            $0.mapOptInt64.values <= Int64(64)
        }

        assertQuery(predicate: "mapOptFloat.@allValues == %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat.values == Float(5.55444333)
        }

        assertQuery(predicate: "mapOptFloat.@allValues != %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat.values != Float(5.55444333)
        }
        assertQuery(predicate: "mapOptFloat.@allValues > %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat.values > Float(5.55444333)
        }

        assertQuery(predicate: "mapOptFloat.@allValues >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat.values >= Float(5.55444333)
        }
        assertQuery(predicate: "mapOptFloat.@allValues < %@", values: [Float(5.55444333)], expectedCount: 0) {
            $0.mapOptFloat.values < Float(5.55444333)
        }

        assertQuery(predicate: "mapOptFloat.@allValues <= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat.values <= Float(5.55444333)
        }

        assertQuery(predicate: "mapOptDouble.@allValues == %@", values: [123.456], expectedCount: 1) {
            $0.mapOptDouble.values == 123.456
        }

        assertQuery(predicate: "mapOptDouble.@allValues != %@", values: [123.456], expectedCount: 1) {
            $0.mapOptDouble.values != 123.456
        }
        assertQuery(predicate: "mapOptDouble.@allValues > %@", values: [123.456], expectedCount: 1) {
            $0.mapOptDouble.values > 123.456
        }

        assertQuery(predicate: "mapOptDouble.@allValues >= %@", values: [123.456], expectedCount: 1) {
            $0.mapOptDouble.values >= 123.456
        }
        assertQuery(predicate: "mapOptDouble.@allValues < %@", values: [123.456], expectedCount: 0) {
            $0.mapOptDouble.values < 123.456
        }

        assertQuery(predicate: "mapOptDouble.@allValues <= %@", values: [123.456], expectedCount: 1) {
            $0.mapOptDouble.values <= 123.456
        }

        assertQuery(predicate: "mapOptString.@allValues == %@", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.values == "Foo"
        }

        assertQuery(predicate: "mapOptString.@allValues != %@", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.values != "Foo"
        }

        assertQuery(predicate: "mapOptString.@allValues CONTAINS[cd] %@", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.values.contains("Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptString.@allValues CONTAINS %@", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.values.contains("Foo")
        }

        assertQuery(predicate: "mapOptString.@allValues BEGINSWITH[cd] %@", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.values.starts(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptString.@allValues BEGINSWITH %@", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.values.starts(with: "Foo")
        }

        assertQuery(predicate: "mapOptString.@allValues ENDSWITH[cd] %@", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.values.ends(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "mapOptString.@allValues ENDSWITH %@", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.values.ends(with: "Foo")
        }

        assertQuery(predicate: "mapOptString.@allValues LIKE[c] %@", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.values.like("Foo", caseInsensitive: true)
        }

        assertQuery(predicate: "mapOptString.@allValues LIKE %@", values: ["Foo"], expectedCount: 1) {
            $0.mapOptString.values.like("Foo")
        }
        assertQuery(predicate: "mapOptBinary.@allValues == %@", values: [Data(count: 64)], expectedCount: 1) {
            $0.mapOptBinary.values == Data(count: 64)
        }

        assertQuery(predicate: "mapOptBinary.@allValues != %@", values: [Data(count: 64)], expectedCount: 1) {
            $0.mapOptBinary.values != Data(count: 64)
        }

        assertQuery(predicate: "mapOptDate.@allValues == %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate.values == Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "mapOptDate.@allValues != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate.values != Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(predicate: "mapOptDate.@allValues > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate.values > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "mapOptDate.@allValues >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate.values >= Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(predicate: "mapOptDate.@allValues < %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.mapOptDate.values < Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "mapOptDate.@allValues <= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate.values <= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "mapOptDecimal.@allValues == %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal.values == Decimal128(123.456)
        }

        assertQuery(predicate: "mapOptDecimal.@allValues != %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal.values != Decimal128(123.456)
        }
        assertQuery(predicate: "mapOptDecimal.@allValues > %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal.values > Decimal128(123.456)
        }

        assertQuery(predicate: "mapOptDecimal.@allValues >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal.values >= Decimal128(123.456)
        }
        assertQuery(predicate: "mapOptDecimal.@allValues < %@", values: [Decimal128(123.456)], expectedCount: 0) {
            $0.mapOptDecimal.values < Decimal128(123.456)
        }

        assertQuery(predicate: "mapOptDecimal.@allValues <= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal.values <= Decimal128(123.456)
        }

        assertQuery(predicate: "mapOptUuid.@allValues == %@", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.mapOptUuid.values == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(predicate: "mapOptUuid.@allValues != %@", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.mapOptUuid.values != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(predicate: "mapOptObjectId.@allValues == %@", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapOptObjectId.values == ObjectId("61184062c1d8f096a3695046")
        }

        assertQuery(predicate: "mapOptObjectId.@allValues != %@", values: [ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapOptObjectId.values != ObjectId("61184062c1d8f096a3695046")
        }

    }

    func testMapContainsRange() {
        assertQuery(predicate: "mapInt.@min >= %@ && mapInt.@max <= %@",
                    values: [1, 2], expectedCount: 1) {
            $0.mapInt.contains(1...2)
        }
        assertQuery(predicate: "mapInt.@min >= %@ && mapInt.@max < %@",
                    values: [1, 2], expectedCount: 0) {
            $0.mapInt.contains(1..<2)
        }

        assertQuery(predicate: "mapInt8.@min >= %@ && mapInt8.@max <= %@",
                    values: [Int8(8), Int8(9)], expectedCount: 1) {
            $0.mapInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(predicate: "mapInt8.@min >= %@ && mapInt8.@max < %@",
                    values: [Int8(8), Int8(9)], expectedCount: 0) {
            $0.mapInt8.contains(Int8(8)..<Int8(9))
        }

        assertQuery(predicate: "mapInt16.@min >= %@ && mapInt16.@max <= %@",
                    values: [Int16(16), Int16(17)], expectedCount: 1) {
            $0.mapInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(predicate: "mapInt16.@min >= %@ && mapInt16.@max < %@",
                    values: [Int16(16), Int16(17)], expectedCount: 0) {
            $0.mapInt16.contains(Int16(16)..<Int16(17))
        }

        assertQuery(predicate: "mapInt32.@min >= %@ && mapInt32.@max <= %@",
                    values: [Int32(32), Int32(33)], expectedCount: 1) {
            $0.mapInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(predicate: "mapInt32.@min >= %@ && mapInt32.@max < %@",
                    values: [Int32(32), Int32(33)], expectedCount: 0) {
            $0.mapInt32.contains(Int32(32)..<Int32(33))
        }

        assertQuery(predicate: "mapInt64.@min >= %@ && mapInt64.@max <= %@",
                    values: [Int64(64), Int64(65)], expectedCount: 1) {
            $0.mapInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(predicate: "mapInt64.@min >= %@ && mapInt64.@max < %@",
                    values: [Int64(64), Int64(65)], expectedCount: 0) {
            $0.mapInt64.contains(Int64(64)..<Int64(65))
        }

        assertQuery(predicate: "mapFloat.@min >= %@ && mapFloat.@max <= %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 1) {
            $0.mapFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(predicate: "mapFloat.@min >= %@ && mapFloat.@max < %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 0) {
            $0.mapFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }

        assertQuery(predicate: "mapDouble.@min >= %@ && mapDouble.@max <= %@",
                    values: [123.456, 234.456], expectedCount: 1) {
            $0.mapDouble.contains(123.456...234.456)
        }
        assertQuery(predicate: "mapDouble.@min >= %@ && mapDouble.@max < %@",
                    values: [123.456, 234.456], expectedCount: 0) {
            $0.mapDouble.contains(123.456..<234.456)
        }

        assertQuery(predicate: "mapDate.@min >= %@ && mapDate.@max <= %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.mapDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(predicate: "mapDate.@min >= %@ && mapDate.@max < %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.mapDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "mapDecimal.@min >= %@ && mapDecimal.@max <= %@",
                    values: [Decimal128(123.456), Decimal128(456.789)], expectedCount: 1) {
            $0.mapDecimal.contains(Decimal128(123.456)...Decimal128(456.789))
        }
        assertQuery(predicate: "mapDecimal.@min >= %@ && mapDecimal.@max < %@",
                    values: [Decimal128(123.456), Decimal128(456.789)], expectedCount: 0) {
            $0.mapDecimal.contains(Decimal128(123.456)..<Decimal128(456.789))
        }

        assertQuery(predicate: "mapOptInt.@min >= %@ && mapOptInt.@max <= %@",
                    values: [1, 2], expectedCount: 1) {
            $0.mapOptInt.contains(1...2)
        }
        assertQuery(predicate: "mapOptInt.@min >= %@ && mapOptInt.@max < %@",
                    values: [1, 2], expectedCount: 0) {
            $0.mapOptInt.contains(1..<2)
        }

        assertQuery(predicate: "mapOptInt8.@min >= %@ && mapOptInt8.@max <= %@",
                    values: [Int8(8), Int8(9)], expectedCount: 1) {
            $0.mapOptInt8.contains(Int8(8)...Int8(9))
        }
        assertQuery(predicate: "mapOptInt8.@min >= %@ && mapOptInt8.@max < %@",
                    values: [Int8(8), Int8(9)], expectedCount: 0) {
            $0.mapOptInt8.contains(Int8(8)..<Int8(9))
        }

        assertQuery(predicate: "mapOptInt16.@min >= %@ && mapOptInt16.@max <= %@",
                    values: [Int16(16), Int16(17)], expectedCount: 1) {
            $0.mapOptInt16.contains(Int16(16)...Int16(17))
        }
        assertQuery(predicate: "mapOptInt16.@min >= %@ && mapOptInt16.@max < %@",
                    values: [Int16(16), Int16(17)], expectedCount: 0) {
            $0.mapOptInt16.contains(Int16(16)..<Int16(17))
        }

        assertQuery(predicate: "mapOptInt32.@min >= %@ && mapOptInt32.@max <= %@",
                    values: [Int32(32), Int32(33)], expectedCount: 1) {
            $0.mapOptInt32.contains(Int32(32)...Int32(33))
        }
        assertQuery(predicate: "mapOptInt32.@min >= %@ && mapOptInt32.@max < %@",
                    values: [Int32(32), Int32(33)], expectedCount: 0) {
            $0.mapOptInt32.contains(Int32(32)..<Int32(33))
        }

        assertQuery(predicate: "mapOptInt64.@min >= %@ && mapOptInt64.@max <= %@",
                    values: [Int64(64), Int64(65)], expectedCount: 1) {
            $0.mapOptInt64.contains(Int64(64)...Int64(65))
        }
        assertQuery(predicate: "mapOptInt64.@min >= %@ && mapOptInt64.@max < %@",
                    values: [Int64(64), Int64(65)], expectedCount: 0) {
            $0.mapOptInt64.contains(Int64(64)..<Int64(65))
        }

        assertQuery(predicate: "mapOptFloat.@min >= %@ && mapOptFloat.@max <= %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 1) {
            $0.mapOptFloat.contains(Float(5.55444333)...Float(6.55444333))
        }
        assertQuery(predicate: "mapOptFloat.@min >= %@ && mapOptFloat.@max < %@",
                    values: [Float(5.55444333), Float(6.55444333)], expectedCount: 0) {
            $0.mapOptFloat.contains(Float(5.55444333)..<Float(6.55444333))
        }

        assertQuery(predicate: "mapOptDouble.@min >= %@ && mapOptDouble.@max <= %@",
                    values: [123.456, 234.456], expectedCount: 1) {
            $0.mapOptDouble.contains(123.456...234.456)
        }
        assertQuery(predicate: "mapOptDouble.@min >= %@ && mapOptDouble.@max < %@",
                    values: [123.456, 234.456], expectedCount: 0) {
            $0.mapOptDouble.contains(123.456..<234.456)
        }

        assertQuery(predicate: "mapOptDate.@min >= %@ && mapOptDate.@max <= %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            $0.mapOptDate.contains(Date(timeIntervalSince1970: 1000000)...Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(predicate: "mapOptDate.@min >= %@ && mapOptDate.@max < %@",
                    values: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.mapOptDate.contains(Date(timeIntervalSince1970: 1000000)..<Date(timeIntervalSince1970: 2000000))
        }

        assertQuery(predicate: "mapOptDecimal.@min >= %@ && mapOptDecimal.@max <= %@",
                    values: [Decimal128(123.456), Decimal128(456.789)], expectedCount: 1) {
            $0.mapOptDecimal.contains(Decimal128(123.456)...Decimal128(456.789))
        }
        assertQuery(predicate: "mapOptDecimal.@min >= %@ && mapOptDecimal.@max < %@",
                    values: [Decimal128(123.456), Decimal128(456.789)], expectedCount: 0) {
            $0.mapOptDecimal.contains(Decimal128(123.456)..<Decimal128(456.789))
        }

    }

    func testMapContainsObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let realm = realmWithTestPath()
        let result1 = realm.objects(ModernCollectionObject.self).query {
            $0.map.contains(obj)
        }
        XCTAssertEqual(result1.count, 0)
        try! realm.write {
            colObj.map["foo"] = obj
        }
        let result2 = realm.objects(ModernCollectionObject.self).query {
            $0.map.contains(obj)
        }
        XCTAssertEqual(result2.count, 1)
    }

    func testMapAllKeysAllValuesSubscript() {
        assertQuery(predicate: "(mapBool.@allKeys == %@ && mapBool == %@)", values: ["foo", true], expectedCount: 1) {
            $0.mapBool["foo"] == true
        }

        assertQuery(predicate: "(mapBool.@allKeys == %@ && mapBool != %@)", values: ["foo", true], expectedCount: 0) {
            $0.mapBool["foo"] != true
        }

        assertQuery(predicate: "(mapInt.@allKeys == %@ && mapInt == %@)", values: ["foo", 1], expectedCount: 1) {
            $0.mapInt["foo"] == 1
        }

        assertQuery(predicate: "(mapInt.@allKeys == %@ && mapInt != %@)", values: ["foo", 1], expectedCount: 1) {
            $0.mapInt["foo"] != 1
        }
        assertQuery(predicate: "(mapInt.@allKeys == %@ && mapInt > %@)", values: ["foo", 1], expectedCount: 1) {
            $0.mapInt["foo"] > 1
        }

        assertQuery(predicate: "(mapInt.@allKeys == %@ && mapInt >= %@)", values: ["foo", 1], expectedCount: 1) {
            $0.mapInt["foo"] >= 1
        }
        assertQuery(predicate: "(mapInt.@allKeys == %@ && mapInt < %@)", values: ["foo", 1], expectedCount: 0) {
            $0.mapInt["foo"] < 1
        }

        assertQuery(predicate: "(mapInt.@allKeys == %@ && mapInt <= %@)", values: ["foo", 1], expectedCount: 1) {
            $0.mapInt["foo"] <= 1
        }

        assertQuery(predicate: "(mapInt8.@allKeys == %@ && mapInt8 == %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.mapInt8["foo"] == Int8(8)
        }

        assertQuery(predicate: "(mapInt8.@allKeys == %@ && mapInt8 != %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.mapInt8["foo"] != Int8(8)
        }
        assertQuery(predicate: "(mapInt8.@allKeys == %@ && mapInt8 > %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.mapInt8["foo"] > Int8(8)
        }

        assertQuery(predicate: "(mapInt8.@allKeys == %@ && mapInt8 >= %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.mapInt8["foo"] >= Int8(8)
        }
        assertQuery(predicate: "(mapInt8.@allKeys == %@ && mapInt8 < %@)", values: ["foo", Int8(8)], expectedCount: 0) {
            $0.mapInt8["foo"] < Int8(8)
        }

        assertQuery(predicate: "(mapInt8.@allKeys == %@ && mapInt8 <= %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.mapInt8["foo"] <= Int8(8)
        }

        assertQuery(predicate: "(mapInt16.@allKeys == %@ && mapInt16 == %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.mapInt16["foo"] == Int16(16)
        }

        assertQuery(predicate: "(mapInt16.@allKeys == %@ && mapInt16 != %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.mapInt16["foo"] != Int16(16)
        }
        assertQuery(predicate: "(mapInt16.@allKeys == %@ && mapInt16 > %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.mapInt16["foo"] > Int16(16)
        }

        assertQuery(predicate: "(mapInt16.@allKeys == %@ && mapInt16 >= %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.mapInt16["foo"] >= Int16(16)
        }
        assertQuery(predicate: "(mapInt16.@allKeys == %@ && mapInt16 < %@)", values: ["foo", Int16(16)], expectedCount: 0) {
            $0.mapInt16["foo"] < Int16(16)
        }

        assertQuery(predicate: "(mapInt16.@allKeys == %@ && mapInt16 <= %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.mapInt16["foo"] <= Int16(16)
        }

        assertQuery(predicate: "(mapInt32.@allKeys == %@ && mapInt32 == %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.mapInt32["foo"] == Int32(32)
        }

        assertQuery(predicate: "(mapInt32.@allKeys == %@ && mapInt32 != %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.mapInt32["foo"] != Int32(32)
        }
        assertQuery(predicate: "(mapInt32.@allKeys == %@ && mapInt32 > %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.mapInt32["foo"] > Int32(32)
        }

        assertQuery(predicate: "(mapInt32.@allKeys == %@ && mapInt32 >= %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.mapInt32["foo"] >= Int32(32)
        }
        assertQuery(predicate: "(mapInt32.@allKeys == %@ && mapInt32 < %@)", values: ["foo", Int32(32)], expectedCount: 0) {
            $0.mapInt32["foo"] < Int32(32)
        }

        assertQuery(predicate: "(mapInt32.@allKeys == %@ && mapInt32 <= %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.mapInt32["foo"] <= Int32(32)
        }

        assertQuery(predicate: "(mapInt64.@allKeys == %@ && mapInt64 == %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.mapInt64["foo"] == Int64(64)
        }

        assertQuery(predicate: "(mapInt64.@allKeys == %@ && mapInt64 != %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.mapInt64["foo"] != Int64(64)
        }
        assertQuery(predicate: "(mapInt64.@allKeys == %@ && mapInt64 > %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.mapInt64["foo"] > Int64(64)
        }

        assertQuery(predicate: "(mapInt64.@allKeys == %@ && mapInt64 >= %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.mapInt64["foo"] >= Int64(64)
        }
        assertQuery(predicate: "(mapInt64.@allKeys == %@ && mapInt64 < %@)", values: ["foo", Int64(64)], expectedCount: 0) {
            $0.mapInt64["foo"] < Int64(64)
        }

        assertQuery(predicate: "(mapInt64.@allKeys == %@ && mapInt64 <= %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.mapInt64["foo"] <= Int64(64)
        }

        assertQuery(predicate: "(mapFloat.@allKeys == %@ && mapFloat == %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat["foo"] == Float(5.55444333)
        }

        assertQuery(predicate: "(mapFloat.@allKeys == %@ && mapFloat != %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat["foo"] != Float(5.55444333)
        }
        assertQuery(predicate: "(mapFloat.@allKeys == %@ && mapFloat > %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat["foo"] > Float(5.55444333)
        }

        assertQuery(predicate: "(mapFloat.@allKeys == %@ && mapFloat >= %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat["foo"] >= Float(5.55444333)
        }
        assertQuery(predicate: "(mapFloat.@allKeys == %@ && mapFloat < %@)", values: ["foo", Float(5.55444333)], expectedCount: 0) {
            $0.mapFloat["foo"] < Float(5.55444333)
        }

        assertQuery(predicate: "(mapFloat.@allKeys == %@ && mapFloat <= %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.mapFloat["foo"] <= Float(5.55444333)
        }

        assertQuery(predicate: "(mapDouble.@allKeys == %@ && mapDouble == %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.mapDouble["foo"] == 123.456
        }

        assertQuery(predicate: "(mapDouble.@allKeys == %@ && mapDouble != %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.mapDouble["foo"] != 123.456
        }
        assertQuery(predicate: "(mapDouble.@allKeys == %@ && mapDouble > %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.mapDouble["foo"] > 123.456
        }

        assertQuery(predicate: "(mapDouble.@allKeys == %@ && mapDouble >= %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.mapDouble["foo"] >= 123.456
        }
        assertQuery(predicate: "(mapDouble.@allKeys == %@ && mapDouble < %@)", values: ["foo", 123.456], expectedCount: 0) {
            $0.mapDouble["foo"] < 123.456
        }

        assertQuery(predicate: "(mapDouble.@allKeys == %@ && mapDouble <= %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.mapDouble["foo"] <= 123.456
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && mapString == %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapString["foo"] == "Foo"
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && mapString != %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapString["foo"] != "Foo"
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && mapString CONTAINS[cd] %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapString["foo"].contains("Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && mapString CONTAINS %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapString["foo"].contains("Foo")
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && NOT mapString CONTAINS %@)", values: ["foo", "Foo"], expectedCount: 0) {
            !$0.mapString["foo"].contains("Foo")
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && mapString BEGINSWITH[cd] %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapString["foo"].starts(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && mapString BEGINSWITH %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapString["foo"].starts(with: "Foo")
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && mapString ENDSWITH[cd] %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapString["foo"].ends(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && mapString ENDSWITH %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapString["foo"].ends(with: "Foo")
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && mapString LIKE[c] %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapString["foo"].like("Foo", caseInsensitive: true)
        }

        assertQuery(predicate: "(mapString.@allKeys == %@ && mapString LIKE %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapString["foo"].like("Foo")
        }
        assertQuery(predicate: "(mapBinary.@allKeys == %@ && mapBinary == %@)", values: ["foo", Data(count: 64)], expectedCount: 1) {
            $0.mapBinary["foo"] == Data(count: 64)
        }

        assertQuery(predicate: "(mapBinary.@allKeys == %@ && mapBinary != %@)", values: ["foo", Data(count: 64)], expectedCount: 1) {
            $0.mapBinary["foo"] != Data(count: 64)
        }

        assertQuery(predicate: "(mapDate.@allKeys == %@ && mapDate == %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate["foo"] == Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "(mapDate.@allKeys == %@ && mapDate != %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate["foo"] != Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(predicate: "(mapDate.@allKeys == %@ && mapDate > %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate["foo"] > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "(mapDate.@allKeys == %@ && mapDate >= %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate["foo"] >= Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(predicate: "(mapDate.@allKeys == %@ && mapDate < %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.mapDate["foo"] < Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "(mapDate.@allKeys == %@ && mapDate <= %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapDate["foo"] <= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "(mapDecimal.@allKeys == %@ && mapDecimal == %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal["foo"] == Decimal128(123.456)
        }

        assertQuery(predicate: "(mapDecimal.@allKeys == %@ && mapDecimal != %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal["foo"] != Decimal128(123.456)
        }
        assertQuery(predicate: "(mapDecimal.@allKeys == %@ && mapDecimal > %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal["foo"] > Decimal128(123.456)
        }

        assertQuery(predicate: "(mapDecimal.@allKeys == %@ && mapDecimal >= %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal["foo"] >= Decimal128(123.456)
        }
        assertQuery(predicate: "(mapDecimal.@allKeys == %@ && mapDecimal < %@)", values: ["foo", Decimal128(123.456)], expectedCount: 0) {
            $0.mapDecimal["foo"] < Decimal128(123.456)
        }

        assertQuery(predicate: "(mapDecimal.@allKeys == %@ && mapDecimal <= %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.mapDecimal["foo"] <= Decimal128(123.456)
        }

        assertQuery(predicate: "(mapObjectId.@allKeys == %@ && mapObjectId == %@)", values: ["foo", ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapObjectId["foo"] == ObjectId("61184062c1d8f096a3695046")
        }

        assertQuery(predicate: "(mapObjectId.@allKeys == %@ && mapObjectId != %@)", values: ["foo", ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapObjectId["foo"] != ObjectId("61184062c1d8f096a3695046")
        }

        assertQuery(predicate: "(mapUuid.@allKeys == %@ && mapUuid == %@)", values: ["foo", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.mapUuid["foo"] == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(predicate: "(mapUuid.@allKeys == %@ && mapUuid != %@)", values: ["foo", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.mapUuid["foo"] != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(predicate: "(mapAny.@allKeys == %@ && mapAny == %@)", values: ["foo", ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapAny["foo"] == AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
        }

        assertQuery(predicate: "(mapAny.@allKeys == %@ && mapAny != %@)", values: ["foo", ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapAny["foo"] != AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046"))
        }

        assertQuery(predicate: "(mapOptBool.@allKeys == %@ && mapOptBool == %@)", values: ["foo", true], expectedCount: 1) {
            $0.mapOptBool["foo"] == true
        }

        assertQuery(predicate: "(mapOptBool.@allKeys == %@ && mapOptBool != %@)", values: ["foo", true], expectedCount: 0) {
            $0.mapOptBool["foo"] != true
        }

        assertQuery(predicate: "(mapOptInt.@allKeys == %@ && mapOptInt == %@)", values: ["foo", 1], expectedCount: 1) {
            $0.mapOptInt["foo"] == 1
        }

        assertQuery(predicate: "(mapOptInt.@allKeys == %@ && mapOptInt != %@)", values: ["foo", 1], expectedCount: 1) {
            $0.mapOptInt["foo"] != 1
        }
        assertQuery(predicate: "(mapOptInt.@allKeys == %@ && mapOptInt > %@)", values: ["foo", 1], expectedCount: 1) {
            $0.mapOptInt["foo"] > 1
        }

        assertQuery(predicate: "(mapOptInt.@allKeys == %@ && mapOptInt >= %@)", values: ["foo", 1], expectedCount: 1) {
            $0.mapOptInt["foo"] >= 1
        }
        assertQuery(predicate: "(mapOptInt.@allKeys == %@ && mapOptInt < %@)", values: ["foo", 1], expectedCount: 0) {
            $0.mapOptInt["foo"] < 1
        }

        assertQuery(predicate: "(mapOptInt.@allKeys == %@ && mapOptInt <= %@)", values: ["foo", 1], expectedCount: 1) {
            $0.mapOptInt["foo"] <= 1
        }

        assertQuery(predicate: "(mapOptInt8.@allKeys == %@ && mapOptInt8 == %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.mapOptInt8["foo"] == Int8(8)
        }

        assertQuery(predicate: "(mapOptInt8.@allKeys == %@ && mapOptInt8 != %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.mapOptInt8["foo"] != Int8(8)
        }
        assertQuery(predicate: "(mapOptInt8.@allKeys == %@ && mapOptInt8 > %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.mapOptInt8["foo"] > Int8(8)
        }

        assertQuery(predicate: "(mapOptInt8.@allKeys == %@ && mapOptInt8 >= %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.mapOptInt8["foo"] >= Int8(8)
        }
        assertQuery(predicate: "(mapOptInt8.@allKeys == %@ && mapOptInt8 < %@)", values: ["foo", Int8(8)], expectedCount: 0) {
            $0.mapOptInt8["foo"] < Int8(8)
        }

        assertQuery(predicate: "(mapOptInt8.@allKeys == %@ && mapOptInt8 <= %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.mapOptInt8["foo"] <= Int8(8)
        }

        assertQuery(predicate: "(mapOptInt16.@allKeys == %@ && mapOptInt16 == %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.mapOptInt16["foo"] == Int16(16)
        }

        assertQuery(predicate: "(mapOptInt16.@allKeys == %@ && mapOptInt16 != %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.mapOptInt16["foo"] != Int16(16)
        }
        assertQuery(predicate: "(mapOptInt16.@allKeys == %@ && mapOptInt16 > %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.mapOptInt16["foo"] > Int16(16)
        }

        assertQuery(predicate: "(mapOptInt16.@allKeys == %@ && mapOptInt16 >= %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.mapOptInt16["foo"] >= Int16(16)
        }
        assertQuery(predicate: "(mapOptInt16.@allKeys == %@ && mapOptInt16 < %@)", values: ["foo", Int16(16)], expectedCount: 0) {
            $0.mapOptInt16["foo"] < Int16(16)
        }

        assertQuery(predicate: "(mapOptInt16.@allKeys == %@ && mapOptInt16 <= %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.mapOptInt16["foo"] <= Int16(16)
        }

        assertQuery(predicate: "(mapOptInt32.@allKeys == %@ && mapOptInt32 == %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.mapOptInt32["foo"] == Int32(32)
        }

        assertQuery(predicate: "(mapOptInt32.@allKeys == %@ && mapOptInt32 != %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.mapOptInt32["foo"] != Int32(32)
        }
        assertQuery(predicate: "(mapOptInt32.@allKeys == %@ && mapOptInt32 > %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.mapOptInt32["foo"] > Int32(32)
        }

        assertQuery(predicate: "(mapOptInt32.@allKeys == %@ && mapOptInt32 >= %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.mapOptInt32["foo"] >= Int32(32)
        }
        assertQuery(predicate: "(mapOptInt32.@allKeys == %@ && mapOptInt32 < %@)", values: ["foo", Int32(32)], expectedCount: 0) {
            $0.mapOptInt32["foo"] < Int32(32)
        }

        assertQuery(predicate: "(mapOptInt32.@allKeys == %@ && mapOptInt32 <= %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.mapOptInt32["foo"] <= Int32(32)
        }

        assertQuery(predicate: "(mapOptInt64.@allKeys == %@ && mapOptInt64 == %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.mapOptInt64["foo"] == Int64(64)
        }

        assertQuery(predicate: "(mapOptInt64.@allKeys == %@ && mapOptInt64 != %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.mapOptInt64["foo"] != Int64(64)
        }
        assertQuery(predicate: "(mapOptInt64.@allKeys == %@ && mapOptInt64 > %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.mapOptInt64["foo"] > Int64(64)
        }

        assertQuery(predicate: "(mapOptInt64.@allKeys == %@ && mapOptInt64 >= %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.mapOptInt64["foo"] >= Int64(64)
        }
        assertQuery(predicate: "(mapOptInt64.@allKeys == %@ && mapOptInt64 < %@)", values: ["foo", Int64(64)], expectedCount: 0) {
            $0.mapOptInt64["foo"] < Int64(64)
        }

        assertQuery(predicate: "(mapOptInt64.@allKeys == %@ && mapOptInt64 <= %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.mapOptInt64["foo"] <= Int64(64)
        }

        assertQuery(predicate: "(mapOptFloat.@allKeys == %@ && mapOptFloat == %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat["foo"] == Float(5.55444333)
        }

        assertQuery(predicate: "(mapOptFloat.@allKeys == %@ && mapOptFloat != %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat["foo"] != Float(5.55444333)
        }
        assertQuery(predicate: "(mapOptFloat.@allKeys == %@ && mapOptFloat > %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat["foo"] > Float(5.55444333)
        }

        assertQuery(predicate: "(mapOptFloat.@allKeys == %@ && mapOptFloat >= %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat["foo"] >= Float(5.55444333)
        }
        assertQuery(predicate: "(mapOptFloat.@allKeys == %@ && mapOptFloat < %@)", values: ["foo", Float(5.55444333)], expectedCount: 0) {
            $0.mapOptFloat["foo"] < Float(5.55444333)
        }

        assertQuery(predicate: "(mapOptFloat.@allKeys == %@ && mapOptFloat <= %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.mapOptFloat["foo"] <= Float(5.55444333)
        }

        assertQuery(predicate: "(mapOptDouble.@allKeys == %@ && mapOptDouble == %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.mapOptDouble["foo"] == 123.456
        }

        assertQuery(predicate: "(mapOptDouble.@allKeys == %@ && mapOptDouble != %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.mapOptDouble["foo"] != 123.456
        }
        assertQuery(predicate: "(mapOptDouble.@allKeys == %@ && mapOptDouble > %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.mapOptDouble["foo"] > 123.456
        }

        assertQuery(predicate: "(mapOptDouble.@allKeys == %@ && mapOptDouble >= %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.mapOptDouble["foo"] >= 123.456
        }
        assertQuery(predicate: "(mapOptDouble.@allKeys == %@ && mapOptDouble < %@)", values: ["foo", 123.456], expectedCount: 0) {
            $0.mapOptDouble["foo"] < 123.456
        }

        assertQuery(predicate: "(mapOptDouble.@allKeys == %@ && mapOptDouble <= %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.mapOptDouble["foo"] <= 123.456
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && mapOptString == %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapOptString["foo"] == "Foo"
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && mapOptString != %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapOptString["foo"] != "Foo"
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && mapOptString CONTAINS[cd] %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapOptString["foo"].contains("Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && mapOptString CONTAINS %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapOptString["foo"].contains("Foo")
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && NOT mapOptString CONTAINS %@)", values: ["foo", "Foo"], expectedCount: 0) {
            !$0.mapOptString["foo"].contains("Foo")
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && mapOptString BEGINSWITH[cd] %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapOptString["foo"].starts(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && mapOptString BEGINSWITH %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapOptString["foo"].starts(with: "Foo")
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && mapOptString ENDSWITH[cd] %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapOptString["foo"].ends(with: "Foo", options: [.caseInsensitive, .diacriticInsensitive])
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && mapOptString ENDSWITH %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapOptString["foo"].ends(with: "Foo")
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && mapOptString LIKE[c] %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapOptString["foo"].like("Foo", caseInsensitive: true)
        }

        assertQuery(predicate: "(mapOptString.@allKeys == %@ && mapOptString LIKE %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.mapOptString["foo"].like("Foo")
        }
        assertQuery(predicate: "(mapOptBinary.@allKeys == %@ && mapOptBinary == %@)", values: ["foo", Data(count: 64)], expectedCount: 1) {
            $0.mapOptBinary["foo"] == Data(count: 64)
        }

        assertQuery(predicate: "(mapOptBinary.@allKeys == %@ && mapOptBinary != %@)", values: ["foo", Data(count: 64)], expectedCount: 1) {
            $0.mapOptBinary["foo"] != Data(count: 64)
        }

        assertQuery(predicate: "(mapOptDate.@allKeys == %@ && mapOptDate == %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate["foo"] == Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "(mapOptDate.@allKeys == %@ && mapOptDate != %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate["foo"] != Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(predicate: "(mapOptDate.@allKeys == %@ && mapOptDate > %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate["foo"] > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "(mapOptDate.@allKeys == %@ && mapOptDate >= %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate["foo"] >= Date(timeIntervalSince1970: 1000000)
        }
        assertQuery(predicate: "(mapOptDate.@allKeys == %@ && mapOptDate < %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.mapOptDate["foo"] < Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "(mapOptDate.@allKeys == %@ && mapOptDate <= %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.mapOptDate["foo"] <= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "(mapOptDecimal.@allKeys == %@ && mapOptDecimal == %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal["foo"] == Decimal128(123.456)
        }

        assertQuery(predicate: "(mapOptDecimal.@allKeys == %@ && mapOptDecimal != %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal["foo"] != Decimal128(123.456)
        }
        assertQuery(predicate: "(mapOptDecimal.@allKeys == %@ && mapOptDecimal > %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal["foo"] > Decimal128(123.456)
        }

        assertQuery(predicate: "(mapOptDecimal.@allKeys == %@ && mapOptDecimal >= %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal["foo"] >= Decimal128(123.456)
        }
        assertQuery(predicate: "(mapOptDecimal.@allKeys == %@ && mapOptDecimal < %@)", values: ["foo", Decimal128(123.456)], expectedCount: 0) {
            $0.mapOptDecimal["foo"] < Decimal128(123.456)
        }

        assertQuery(predicate: "(mapOptDecimal.@allKeys == %@ && mapOptDecimal <= %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.mapOptDecimal["foo"] <= Decimal128(123.456)
        }

        assertQuery(predicate: "(mapOptUuid.@allKeys == %@ && mapOptUuid == %@)", values: ["foo", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.mapOptUuid["foo"] == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(predicate: "(mapOptUuid.@allKeys == %@ && mapOptUuid != %@)", values: ["foo", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.mapOptUuid["foo"] != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }

        assertQuery(predicate: "(mapOptObjectId.@allKeys == %@ && mapOptObjectId == %@)", values: ["foo", ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapOptObjectId["foo"] == ObjectId("61184062c1d8f096a3695046")
        }

        assertQuery(predicate: "(mapOptObjectId.@allKeys == %@ && mapOptObjectId != %@)", values: ["foo", ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.mapOptObjectId["foo"] != ObjectId("61184062c1d8f096a3695046")
        }

    }

    func testMapSubscriptObject() {
        let obj = objects().first!
        let colObj = collectionObject()
        let realm = realmWithTestPath()
        try! realm.write {
            colObj.map["foo"] = obj
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.boolCol == %@)", values: ["foo", true], expectedCount: 0) {
            $0.map["foo"].boolCol == true
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.boolCol != %@)", values: ["foo", true], expectedCount: 1) {
            $0.map["foo"].boolCol != true
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.intCol == %@)", values: ["foo", 5], expectedCount: 0) {
            $0.map["foo"].intCol == 5
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.intCol != %@)", values: ["foo", 5], expectedCount: 1) {
            $0.map["foo"].intCol != 5
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.int8Col == %@)", values: ["foo", Int8(8)], expectedCount: 0) {
            $0.map["foo"].int8Col == Int8(8)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.int8Col != %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.map["foo"].int8Col != Int8(8)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.int16Col == %@)", values: ["foo", Int16(16)], expectedCount: 0) {
            $0.map["foo"].int16Col == Int16(16)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.int16Col != %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.map["foo"].int16Col != Int16(16)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.int32Col == %@)", values: ["foo", Int32(32)], expectedCount: 0) {
            $0.map["foo"].int32Col == Int32(32)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.int32Col != %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.map["foo"].int32Col != Int32(32)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.int64Col == %@)", values: ["foo", Int64(64)], expectedCount: 0) {
            $0.map["foo"].int64Col == Int64(64)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.int64Col != %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.map["foo"].int64Col != Int64(64)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.floatCol == %@)", values: ["foo", Float(5.55444333)], expectedCount: 0) {
            $0.map["foo"].floatCol == Float(5.55444333)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.floatCol != %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.map["foo"].floatCol != Float(5.55444333)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.doubleCol == %@)", values: ["foo", 123.456], expectedCount: 0) {
            $0.map["foo"].doubleCol == 123.456
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.doubleCol != %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.map["foo"].doubleCol != 123.456
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.stringCol == %@)", values: ["foo", "Foo"], expectedCount: 0) {
            $0.map["foo"].stringCol == "Foo"
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.stringCol != %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.map["foo"].stringCol != "Foo"
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.binaryCol == %@)", values: ["foo", Data(count: 64)], expectedCount: 0) {
            $0.map["foo"].binaryCol == Data(count: 64)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.binaryCol != %@)", values: ["foo", Data(count: 64)], expectedCount: 1) {
            $0.map["foo"].binaryCol != Data(count: 64)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.dateCol == %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.map["foo"].dateCol == Date(timeIntervalSince1970: 1000000)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.dateCol != %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.map["foo"].dateCol != Date(timeIntervalSince1970: 1000000)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.decimalCol == %@)", values: ["foo", Decimal128(123.456)], expectedCount: 0) {
            $0.map["foo"].decimalCol == Decimal128(123.456)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.decimalCol != %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.map["foo"].decimalCol != Decimal128(123.456)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.objectIdCol == %@)", values: ["foo", ObjectId("61184062c1d8f096a3695046")], expectedCount: 0) {
            $0.map["foo"].objectIdCol == ObjectId("61184062c1d8f096a3695046")
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.objectIdCol != %@)", values: ["foo", ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.map["foo"].objectIdCol != ObjectId("61184062c1d8f096a3695046")
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.intEnumCol == %@)", values: ["foo", ModernIntEnum.value2.rawValue], expectedCount: 1) {
            $0.map["foo"].intEnumCol == .value2
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.intEnumCol != %@)", values: ["foo", ModernIntEnum.value2.rawValue], expectedCount: 0) {
            $0.map["foo"].intEnumCol != .value2
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.stringEnumCol == %@)", values: ["foo", ModernStringEnum.value2.rawValue], expectedCount: 1) {
            $0.map["foo"].stringEnumCol == .value2
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.stringEnumCol != %@)", values: ["foo", ModernStringEnum.value2.rawValue], expectedCount: 0) {
            $0.map["foo"].stringEnumCol != .value2
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.uuidCol == %@)", values: ["foo", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 0) {
            $0.map["foo"].uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.uuidCol != %@)", values: ["foo", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.map["foo"].uuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optBoolCol == %@)", values: ["foo", true], expectedCount: 0) {
            $0.map["foo"].optBoolCol == true
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optBoolCol != %@)", values: ["foo", true], expectedCount: 1) {
            $0.map["foo"].optBoolCol != true
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optIntCol == %@)", values: ["foo", 5], expectedCount: 0) {
            $0.map["foo"].optIntCol == 5
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optIntCol != %@)", values: ["foo", 5], expectedCount: 1) {
            $0.map["foo"].optIntCol != 5
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optInt8Col == %@)", values: ["foo", Int8(8)], expectedCount: 0) {
            $0.map["foo"].optInt8Col == Int8(8)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optInt8Col != %@)", values: ["foo", Int8(8)], expectedCount: 1) {
            $0.map["foo"].optInt8Col != Int8(8)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optInt16Col == %@)", values: ["foo", Int16(16)], expectedCount: 0) {
            $0.map["foo"].optInt16Col == Int16(16)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optInt16Col != %@)", values: ["foo", Int16(16)], expectedCount: 1) {
            $0.map["foo"].optInt16Col != Int16(16)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optInt32Col == %@)", values: ["foo", Int32(32)], expectedCount: 0) {
            $0.map["foo"].optInt32Col == Int32(32)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optInt32Col != %@)", values: ["foo", Int32(32)], expectedCount: 1) {
            $0.map["foo"].optInt32Col != Int32(32)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optInt64Col == %@)", values: ["foo", Int64(64)], expectedCount: 0) {
            $0.map["foo"].optInt64Col == Int64(64)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optInt64Col != %@)", values: ["foo", Int64(64)], expectedCount: 1) {
            $0.map["foo"].optInt64Col != Int64(64)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optFloatCol == %@)", values: ["foo", Float(5.55444333)], expectedCount: 0) {
            $0.map["foo"].optFloatCol == Float(5.55444333)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optFloatCol != %@)", values: ["foo", Float(5.55444333)], expectedCount: 1) {
            $0.map["foo"].optFloatCol != Float(5.55444333)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optDoubleCol == %@)", values: ["foo", 123.456], expectedCount: 0) {
            $0.map["foo"].optDoubleCol == 123.456
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optDoubleCol != %@)", values: ["foo", 123.456], expectedCount: 1) {
            $0.map["foo"].optDoubleCol != 123.456
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optStringCol == %@)", values: ["foo", "Foo"], expectedCount: 0) {
            $0.map["foo"].optStringCol == "Foo"
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optStringCol != %@)", values: ["foo", "Foo"], expectedCount: 1) {
            $0.map["foo"].optStringCol != "Foo"
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optBinaryCol == %@)", values: ["foo", Data(count: 64)], expectedCount: 0) {
            $0.map["foo"].optBinaryCol == Data(count: 64)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optBinaryCol != %@)", values: ["foo", Data(count: 64)], expectedCount: 1) {
            $0.map["foo"].optBinaryCol != Data(count: 64)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optDateCol == %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.map["foo"].optDateCol == Date(timeIntervalSince1970: 1000000)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optDateCol != %@)", values: ["foo", Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.map["foo"].optDateCol != Date(timeIntervalSince1970: 1000000)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optDecimalCol == %@)", values: ["foo", Decimal128(123.456)], expectedCount: 0) {
            $0.map["foo"].optDecimalCol == Decimal128(123.456)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optDecimalCol != %@)", values: ["foo", Decimal128(123.456)], expectedCount: 1) {
            $0.map["foo"].optDecimalCol != Decimal128(123.456)
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optObjectIdCol == %@)", values: ["foo", ObjectId("61184062c1d8f096a3695046")], expectedCount: 0) {
            $0.map["foo"].optObjectIdCol == ObjectId("61184062c1d8f096a3695046")
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optObjectIdCol != %@)", values: ["foo", ObjectId("61184062c1d8f096a3695046")], expectedCount: 1) {
            $0.map["foo"].optObjectIdCol != ObjectId("61184062c1d8f096a3695046")
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optIntEnumCol == %@)", values: ["foo", ModernIntEnum.value2.rawValue], expectedCount: 1) {
            $0.map["foo"].optIntEnumCol == .value2
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optIntEnumCol != %@)", values: ["foo", ModernIntEnum.value2.rawValue], expectedCount: 0) {
            $0.map["foo"].optIntEnumCol != .value2
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optStringEnumCol == %@)", values: ["foo", ModernStringEnum.value2.rawValue], expectedCount: 1) {
            $0.map["foo"].optStringEnumCol == .value2
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optStringEnumCol != %@)", values: ["foo", ModernStringEnum.value2.rawValue], expectedCount: 0) {
            $0.map["foo"].optStringEnumCol != .value2
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optUuidCol == %@)", values: ["foo", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 0) {
            $0.map["foo"].optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.optUuidCol != %@)", values: ["foo", UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!], expectedCount: 1) {
            $0.map["foo"].optUuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!
        }
        try! realm.write {
            colObj.map["foo"]??.objectCol = obj
        }
        assertCollectionObjectQuery(predicate: "(map.@allKeys == %@ && map.objectCol.intCol == %@)", values: ["foo", 6], expectedCount: 1) {
            $0.map["foo"].objectCol.intCol == 6
        }
    }

    func testMapContainsAnyInObject() {
        assertQuery(predicate: "ANY mapBool IN %@",
                    values: [NSArray(array: [true, true])], expectedCount: 1) {
            $0.mapBool.containsAny(in: [true, true])
        }
        assertQuery(predicate: "ANY mapInt IN %@",
                    values: [NSArray(array: [1, 2])], expectedCount: 1) {
            $0.mapInt.containsAny(in: [1, 2])
        }
        assertQuery(predicate: "ANY mapInt8 IN %@",
                    values: [NSArray(array: [Int8(8), Int8(9)])], expectedCount: 1) {
            $0.mapInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(predicate: "ANY mapInt16 IN %@",
                    values: [NSArray(array: [Int16(16), Int16(17)])], expectedCount: 1) {
            $0.mapInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(predicate: "ANY mapInt32 IN %@",
                    values: [NSArray(array: [Int32(32), Int32(33)])], expectedCount: 1) {
            $0.mapInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(predicate: "ANY mapInt64 IN %@",
                    values: [NSArray(array: [Int64(64), Int64(65)])], expectedCount: 1) {
            $0.mapInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(predicate: "ANY mapFloat IN %@",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], expectedCount: 1) {
            $0.mapFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(predicate: "ANY mapDouble IN %@",
                    values: [NSArray(array: [123.456, 234.456])], expectedCount: 1) {
            $0.mapDouble.containsAny(in: [123.456, 234.456])
        }
        assertQuery(predicate: "ANY mapString IN %@",
                    values: [NSArray(array: ["Foo", "Bar"])], expectedCount: 1) {
            $0.mapString.containsAny(in: ["Foo", "Bar"])
        }
        assertQuery(predicate: "ANY mapBinary IN %@",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], expectedCount: 1) {
            $0.mapBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(predicate: "ANY mapDate IN %@",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], expectedCount: 1) {
            $0.mapDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(predicate: "ANY mapDecimal IN %@",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(456.789)])], expectedCount: 1) {
            $0.mapDecimal.containsAny(in: [Decimal128(123.456), Decimal128(456.789)])
        }
        assertQuery(predicate: "ANY mapObjectId IN %@",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], expectedCount: 1) {
            $0.mapObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }
        assertQuery(predicate: "ANY mapUuid IN %@",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], expectedCount: 1) {
            $0.mapUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(predicate: "ANY mapAny IN %@",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), "Hello"])], expectedCount: 1) {
            $0.mapAny.containsAny(in: [AnyRealmValue.objectId(ObjectId("61184062c1d8f096a3695046")), AnyRealmValue.string("Hello")])
        }
        assertQuery(predicate: "ANY mapOptBool IN %@",
                    values: [NSArray(array: [true, true])], expectedCount: 1) {
            $0.mapOptBool.containsAny(in: [true, true])
        }
        assertQuery(predicate: "ANY mapOptInt IN %@",
                    values: [NSArray(array: [1, 2])], expectedCount: 1) {
            $0.mapOptInt.containsAny(in: [1, 2])
        }
        assertQuery(predicate: "ANY mapOptInt8 IN %@",
                    values: [NSArray(array: [Int8(8), Int8(9)])], expectedCount: 1) {
            $0.mapOptInt8.containsAny(in: [Int8(8), Int8(9)])
        }
        assertQuery(predicate: "ANY mapOptInt16 IN %@",
                    values: [NSArray(array: [Int16(16), Int16(17)])], expectedCount: 1) {
            $0.mapOptInt16.containsAny(in: [Int16(16), Int16(17)])
        }
        assertQuery(predicate: "ANY mapOptInt32 IN %@",
                    values: [NSArray(array: [Int32(32), Int32(33)])], expectedCount: 1) {
            $0.mapOptInt32.containsAny(in: [Int32(32), Int32(33)])
        }
        assertQuery(predicate: "ANY mapOptInt64 IN %@",
                    values: [NSArray(array: [Int64(64), Int64(65)])], expectedCount: 1) {
            $0.mapOptInt64.containsAny(in: [Int64(64), Int64(65)])
        }
        assertQuery(predicate: "ANY mapOptFloat IN %@",
                    values: [NSArray(array: [Float(5.55444333), Float(6.55444333)])], expectedCount: 1) {
            $0.mapOptFloat.containsAny(in: [Float(5.55444333), Float(6.55444333)])
        }
        assertQuery(predicate: "ANY mapOptDouble IN %@",
                    values: [NSArray(array: [123.456, 234.456])], expectedCount: 1) {
            $0.mapOptDouble.containsAny(in: [123.456, 234.456])
        }
        assertQuery(predicate: "ANY mapOptString IN %@",
                    values: [NSArray(array: ["Foo", "Bar"])], expectedCount: 1) {
            $0.mapOptString.containsAny(in: ["Foo", "Bar"])
        }
        assertQuery(predicate: "ANY mapOptBinary IN %@",
                    values: [NSArray(array: [Data(count: 64), Data(count: 128)])], expectedCount: 1) {
            $0.mapOptBinary.containsAny(in: [Data(count: 64), Data(count: 128)])
        }
        assertQuery(predicate: "ANY mapOptDate IN %@",
                    values: [NSArray(array: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])], expectedCount: 1) {
            $0.mapOptDate.containsAny(in: [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000)])
        }
        assertQuery(predicate: "ANY mapOptDecimal IN %@",
                    values: [NSArray(array: [Decimal128(123.456), Decimal128(456.789)])], expectedCount: 1) {
            $0.mapOptDecimal.containsAny(in: [Decimal128(123.456), Decimal128(456.789)])
        }
        assertQuery(predicate: "ANY mapOptUuid IN %@",
                    values: [NSArray(array: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])], expectedCount: 1) {
            $0.mapOptUuid.containsAny(in: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09e")!, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!])
        }
        assertQuery(predicate: "ANY mapOptObjectId IN %@",
                    values: [NSArray(array: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])], expectedCount: 1) {
            $0.mapOptObjectId.containsAny(in: [ObjectId("61184062c1d8f096a3695046"), ObjectId("61184062c1d8f096a3695045")])
        }

        let realm = realmWithTestPath()
        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.map["foo"] = obj
        try! realm.write {
            realm.add(colObj)
        }

        assertCollectionObjectQuery(predicate: "ANY map IN %@", values: [NSArray(array: [obj])], expectedCount: 1) {
            $0.map.containsAny(in: [obj])
        }
    }

    func testMapFromProperty() {
        let realm = realmWithTestPath()
        let colObj = ModernCollectionObject()
        let obj = objects().first!
        colObj.map["foo"] = obj
        try! realm.write {
            realm.add(colObj)
        }

        assertMapQuery(on: \.boolCol,
                       predicate: "boolCol == %@",
                       values: [false],
                       expectedCount: 1) {
            $0.boolCol == false
        }
        assertMapQuery(on: \.intCol,
                       predicate: "intCol == %@",
                       values: [6],
                       expectedCount: 1) {
            $0.intCol == 6
        }
        assertMapQuery(on: \.int8Col,
                       predicate: "int8Col == %@",
                       values: [Int8(9)],
                       expectedCount: 1) {
            $0.int8Col == Int8(9)
        }
        assertMapQuery(on: \.int16Col,
                       predicate: "int16Col == %@",
                       values: [Int16(17)],
                       expectedCount: 1) {
            $0.int16Col == Int16(17)
        }
        assertMapQuery(on: \.int32Col,
                       predicate: "int32Col == %@",
                       values: [Int32(33)],
                       expectedCount: 1) {
            $0.int32Col == Int32(33)
        }
        assertMapQuery(on: \.int64Col,
                       predicate: "int64Col == %@",
                       values: [Int64(65)],
                       expectedCount: 1) {
            $0.int64Col == Int64(65)
        }
        assertMapQuery(on: \.floatCol,
                       predicate: "floatCol == %@",
                       values: [Float(6.55444333)],
                       expectedCount: 1) {
            $0.floatCol == Float(6.55444333)
        }
        assertMapQuery(on: \.doubleCol,
                       predicate: "doubleCol == %@",
                       values: [234.567],
                       expectedCount: 1) {
            $0.doubleCol == 234.567
        }
        assertMapQuery(on: \.stringCol,
                       predicate: "stringCol == %@",
                       values: ["Foó"],
                       expectedCount: 1) {
            $0.stringCol == "Foó"
        }
        assertMapQuery(on: \.binaryCol,
                       predicate: "binaryCol == %@",
                       values: [Data(count: 128)],
                       expectedCount: 1) {
            $0.binaryCol == Data(count: 128)
        }
        assertMapQuery(on: \.dateCol,
                       predicate: "dateCol == %@",
                       values: [Date(timeIntervalSince1970: 2000000)],
                       expectedCount: 1) {
            $0.dateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertMapQuery(on: \.decimalCol,
                       predicate: "decimalCol == %@",
                       values: [Decimal128(234.567)],
                       expectedCount: 1) {
            $0.decimalCol == Decimal128(234.567)
        }
        assertMapQuery(on: \.objectIdCol,
                       predicate: "objectIdCol == %@",
                       values: [ObjectId("61184062c1d8f096a3695045")],
                       expectedCount: 1) {
            $0.objectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertMapQuery(on: \.intEnumCol,
                       predicate: "intEnumCol == %@",
                       values: [ModernIntEnum.value2.rawValue],
                       expectedCount: 1) {
            $0.intEnumCol == .value2
        }
        assertMapQuery(on: \.stringEnumCol,
                       predicate: "stringEnumCol == %@",
                       values: [ModernStringEnum.value2.rawValue],
                       expectedCount: 1) {
            $0.stringEnumCol == .value2
        }
        assertMapQuery(on: \.uuidCol,
                       predicate: "uuidCol == %@",
                       values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!],
                       expectedCount: 1) {
            $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
        assertMapQuery(on: \.optBoolCol,
                       predicate: "optBoolCol == %@",
                       values: [false],
                       expectedCount: 1) {
            $0.optBoolCol == false
        }
        assertMapQuery(on: \.optIntCol,
                       predicate: "optIntCol == %@",
                       values: [6],
                       expectedCount: 1) {
            $0.optIntCol == 6
        }
        assertMapQuery(on: \.optInt8Col,
                       predicate: "optInt8Col == %@",
                       values: [Int8(9)],
                       expectedCount: 1) {
            $0.optInt8Col == Int8(9)
        }
        assertMapQuery(on: \.optInt16Col,
                       predicate: "optInt16Col == %@",
                       values: [Int16(17)],
                       expectedCount: 1) {
            $0.optInt16Col == Int16(17)
        }
        assertMapQuery(on: \.optInt32Col,
                       predicate: "optInt32Col == %@",
                       values: [Int32(33)],
                       expectedCount: 1) {
            $0.optInt32Col == Int32(33)
        }
        assertMapQuery(on: \.optInt64Col,
                       predicate: "optInt64Col == %@",
                       values: [Int64(65)],
                       expectedCount: 1) {
            $0.optInt64Col == Int64(65)
        }
        assertMapQuery(on: \.optFloatCol,
                       predicate: "optFloatCol == %@",
                       values: [Float(6.55444333)],
                       expectedCount: 1) {
            $0.optFloatCol == Float(6.55444333)
        }
        assertMapQuery(on: \.optDoubleCol,
                       predicate: "optDoubleCol == %@",
                       values: [234.567],
                       expectedCount: 1) {
            $0.optDoubleCol == 234.567
        }
        assertMapQuery(on: \.optStringCol,
                       predicate: "optStringCol == %@",
                       values: ["Foó"],
                       expectedCount: 1) {
            $0.optStringCol == "Foó"
        }
        assertMapQuery(on: \.optBinaryCol,
                       predicate: "optBinaryCol == %@",
                       values: [Data(count: 128)],
                       expectedCount: 1) {
            $0.optBinaryCol == Data(count: 128)
        }
        assertMapQuery(on: \.optDateCol,
                       predicate: "optDateCol == %@",
                       values: [Date(timeIntervalSince1970: 2000000)],
                       expectedCount: 1) {
            $0.optDateCol == Date(timeIntervalSince1970: 2000000)
        }
        assertMapQuery(on: \.optDecimalCol,
                       predicate: "optDecimalCol == %@",
                       values: [Decimal128(234.567)],
                       expectedCount: 1) {
            $0.optDecimalCol == Decimal128(234.567)
        }
        assertMapQuery(on: \.optObjectIdCol,
                       predicate: "optObjectIdCol == %@",
                       values: [ObjectId("61184062c1d8f096a3695045")],
                       expectedCount: 1) {
            $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")
        }
        assertMapQuery(on: \.optIntEnumCol,
                       predicate: "optIntEnumCol == %@",
                       values: [ModernIntEnum.value2.rawValue],
                       expectedCount: 1) {
            $0.optIntEnumCol == .value2
        }
        assertMapQuery(on: \.optStringEnumCol,
                       predicate: "optStringEnumCol == %@",
                       values: [ModernStringEnum.value2.rawValue],
                       expectedCount: 1) {
            $0.optStringEnumCol == .value2
        }
        assertMapQuery(on: \.optUuidCol,
                       predicate: "optUuidCol == %@",
                       values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!],
                       expectedCount: 1) {
            $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!
        }
    }

    // MARK: Linking Objects

    func testLinkingObjects() {
        assertQuery(predicate: "%@ IN linkingObjects", values: [objects().first!], expectedCount: 0) {
            $0.linkingObjects.contains(objects().first!)
        }

        assertQuery(predicate: "ANY linkingObjects IN %@", values: [NSArray(array: objects().map { $0 })], expectedCount: 0) {
            $0.linkingObjects.containsAny(in: objects())
        }

        assertQuery(predicate: "NOT %@ IN linkingObjects", values: [objects().first!], expectedCount: 1) {
            !$0.linkingObjects.contains(objects().first!)
        }

        assertQuery(predicate: "NOT ANY linkingObjects IN %@", values: [NSArray(array: objects().map { $0 })], expectedCount: 1) {
            !$0.linkingObjects.containsAny(in: objects())
        }
    }

    // MARK: Compound

    func testCompoundAnd() {
        assertQuery(predicate: "(boolCol == %@ && optBoolCol == %@)", values: [false, false], expectedCount: 1) {
            $0.boolCol == false && $0.optBoolCol == false
        }
        assertQuery(predicate: "(boolCol == %@ && optBoolCol == %@)", values: [false, false], expectedCount: 1) {
            ($0.boolCol == false) && ($0.optBoolCol == false)
        }

        // List

        assertQuery(predicate: "(boolCol == %@ && %@ IN arrayBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false && $0.arrayBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ && %@ IN arrayBool)", values: [true, true], expectedCount: 1) {
            $0.boolCol != true && $0.arrayBool.contains(true)
        }
        assertQuery(predicate: "(boolCol == %@ && %@ IN arrayOptBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false && $0.arrayOptBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ && %@ IN arrayOptBool)", values: [true, true], expectedCount: 1) {
            $0.boolCol != true && $0.arrayOptBool.contains(true)
        }

        // Set

        assertQuery(predicate: "(boolCol == %@ && %@ IN setBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false && $0.setBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ && %@ IN setBool)", values: [true, true], expectedCount: 1) {
            $0.boolCol != true && $0.setBool.contains(true)
        }
        assertQuery(predicate: "(boolCol == %@ && %@ IN setOptBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false && $0.setOptBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ && %@ IN setOptBool)", values: [true, true], expectedCount: 1) {
            $0.boolCol != true && $0.setOptBool.contains(true)
        }

        // Map

        assertQuery(predicate: "(boolCol == %@ && %@ IN mapBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false && $0.mapBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ && (mapBool.@allKeys == %@ && mapBool == %@))",
                    values: [true, "foo", true], expectedCount: 1) {
            ($0.boolCol != true) && ($0.mapBool["foo"] == true)
        }
        assertQuery(predicate: "((boolCol != %@ && (mapBool.@allKeys == %@ && mapBool == %@)) && (mapBool.@allKeys == %@ && mapBool == %@))",
                    values: [true, "foo", true, "bar", true], expectedCount: 1) {
            ($0.boolCol != true) &&
            ($0.mapBool["foo"] == true) &&
            ($0.mapBool["bar"] == true)
        }
        assertQuery(predicate: "(boolCol == %@ && %@ IN mapOptBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false && $0.mapOptBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ && (mapOptBool.@allKeys == %@ && mapOptBool == %@))",
                    values: [true, "foo", true], expectedCount: 1) {
            ($0.boolCol != true) && ($0.mapOptBool["foo"] == true)
        }
        assertQuery(predicate: "((boolCol != %@ && (mapOptBool.@allKeys == %@ && mapOptBool == %@)) && (mapOptBool.@allKeys == %@ && mapOptBool == %@))",
                    values: [true, "foo", true, "bar", true], expectedCount: 1) {
            ($0.boolCol != true) &&
            ($0.mapOptBool["foo"] == true) &&
            ($0.mapOptBool["bar"] == true)
        }

        // Aggregates

        let sumarrayInt = 1 + 2
        assertQuery(predicate: "(((((arrayInt.@min <= %@ && arrayInt.@max >= %@) && arrayInt.@sum == %@) && arrayInt.@count != %@) && arrayInt.@avg > %@) && arrayInt.@avg < %@)",
                    values: [1, 2, sumarrayInt, 0, 1, 2], expectedCount: 1) {
            $0.arrayInt.min <= 1 &&
            $0.arrayInt.max >= 2 &&
            $0.arrayInt.sum == sumarrayInt &&
            $0.arrayInt.count != 0 &&
            $0.arrayInt.avg > 1 &&
            $0.arrayInt.avg < 2
        }
        let sumarrayOptInt = 1 + 2
        assertQuery(predicate: "(((((arrayOptInt.@min <= %@ && arrayOptInt.@max >= %@) && arrayOptInt.@sum == %@) && arrayOptInt.@count != %@) && arrayOptInt.@avg > %@) && arrayOptInt.@avg < %@)",
                    values: [1, 2, sumarrayOptInt, 0, 1, 2], expectedCount: 1) {
            $0.arrayOptInt.min <= 1 &&
            $0.arrayOptInt.max >= 2 &&
            $0.arrayOptInt.sum == sumarrayOptInt &&
            $0.arrayOptInt.count != 0 &&
            $0.arrayOptInt.avg > 1 &&
            $0.arrayOptInt.avg < 2
        }

        // Keypath Collection Aggregates

        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["doubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["doubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["doubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        let sumdoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(predicate: "(((((arrayCol.@min.doubleCol <= %@ && arrayCol.@max.doubleCol >= %@) && arrayCol.@sum.doubleCol == %@) && arrayCol.@min.doubleCol != %@) && arrayCol.@avg.doubleCol > %@) && arrayCol.@avg.doubleCol < %@)",
                    values: [123.456, 345.678, sumdoubleCol, 234.567, 123.456, 345.678], expectedCount: 1) {
            $0.arrayCol.doubleCol.min <= 123.456 &&
            $0.arrayCol.doubleCol.max >= 345.678 &&
            $0.arrayCol.doubleCol.sum == sumdoubleCol &&
            $0.arrayCol.doubleCol.min != 234.567 &&
            $0.arrayCol.doubleCol.avg > 123.456 &&
            $0.arrayCol.doubleCol.avg < 345.678
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDoubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["optDoubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["optDoubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        let sumoptDoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(predicate: "(((((arrayCol.@min.optDoubleCol <= %@ && arrayCol.@max.optDoubleCol >= %@) && arrayCol.@sum.optDoubleCol == %@) && arrayCol.@min.optDoubleCol != %@) && arrayCol.@avg.optDoubleCol > %@) && arrayCol.@avg.optDoubleCol < %@)",
                    values: [123.456, 345.678, sumoptDoubleCol, 234.567, 123.456, 345.678], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.min <= 123.456 &&
            $0.arrayCol.optDoubleCol.max >= 345.678 &&
            $0.arrayCol.optDoubleCol.sum == sumoptDoubleCol &&
            $0.arrayCol.optDoubleCol.min != 234.567 &&
            $0.arrayCol.optDoubleCol.avg > 123.456 &&
            $0.arrayCol.optDoubleCol.avg < 345.678
        }
    }

    func testCompoundOr() {
        assertQuery(predicate: "(boolCol == %@ || optBoolCol == %@)", values: [false, false], expectedCount: 1) {
            $0.boolCol == false || $0.optBoolCol == false
        }
        assertQuery(predicate: "(boolCol == %@ || optBoolCol == %@)", values: [false, false], expectedCount: 1) {
            ($0.boolCol == false) || ($0.optBoolCol == false)
        }

        // List

        assertQuery(predicate: "(boolCol == %@ || %@ IN arrayBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false || $0.arrayBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ || %@ IN arrayBool)", values: [true, true], expectedCount: 1) {
            $0.boolCol != true || $0.arrayBool.contains(true)
        }
        assertQuery(predicate: "(boolCol == %@ || %@ IN arrayOptBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false || $0.arrayOptBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ || %@ IN arrayOptBool)", values: [true, true], expectedCount: 1) {
            $0.boolCol != true || $0.arrayOptBool.contains(true)
        }

        // Set

        assertQuery(predicate: "(boolCol == %@ || %@ IN setBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false || $0.setBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ || %@ IN setBool)", values: [true, true], expectedCount: 1) {
            $0.boolCol != true || $0.setBool.contains(true)
        }
        assertQuery(predicate: "(boolCol == %@ || %@ IN setOptBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false || $0.setOptBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ || %@ IN setOptBool)", values: [true, true], expectedCount: 1) {
            $0.boolCol != true || $0.setOptBool.contains(true)
        }

        // Map

        assertQuery(predicate: "(boolCol == %@ || %@ IN mapBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false || $0.mapBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ || (mapBool.@allKeys == %@ && mapBool == %@))",
                    values: [true, "foo", true], expectedCount: 1) {
            ($0.boolCol != true) || ($0.mapBool["foo"] == true)
        }
        assertQuery(predicate: "((boolCol != %@ || (mapBool.@allKeys == %@ && mapBool == %@)) || (mapBool.@allKeys == %@ && mapBool == %@))",
                    values: [true, "foo", true, "bar", true], expectedCount: 1) {
            ($0.boolCol != true) ||
            ($0.mapBool["foo"] == true) ||
            ($0.mapBool["bar"] == true)
        }
        assertQuery(predicate: "(boolCol == %@ || %@ IN mapOptBool)", values: [false, true], expectedCount: 1) {
            $0.boolCol == false || $0.mapOptBool.contains(true)
        }
        assertQuery(predicate: "(boolCol != %@ || (mapOptBool.@allKeys == %@ && mapOptBool == %@))",
                    values: [true, "foo", true], expectedCount: 1) {
            ($0.boolCol != true) || ($0.mapOptBool["foo"] == true)
        }
        assertQuery(predicate: "((boolCol != %@ || (mapOptBool.@allKeys == %@ && mapOptBool == %@)) || (mapOptBool.@allKeys == %@ && mapOptBool == %@))",
                    values: [true, "foo", true, "bar", true], expectedCount: 1) {
            ($0.boolCol != true) ||
            ($0.mapOptBool["foo"] == true) ||
            ($0.mapOptBool["bar"] == true)
        }

        // Aggregates

        let sumarrayInt = 1 + 2
        assertQuery(predicate: "(((((arrayInt.@min <= %@ || arrayInt.@max >= %@) || arrayInt.@sum != %@) || arrayInt.@count == %@) || arrayInt.@avg > %@) || arrayInt.@avg < %@)",
                    values: [1, 3, sumarrayInt, 0, 2, 1], expectedCount: 1) {
            $0.arrayInt.min <= 1 ||
            $0.arrayInt.max >= 3 ||
            $0.arrayInt.sum != sumarrayInt ||
            $0.arrayInt.count() == 0 ||
            $0.arrayInt.avg > 2 ||
            $0.arrayInt.avg < 1
        }
        let sumarrayOptInt = 1 + 2
        assertQuery(predicate: "(((((arrayOptInt.@min <= %@ || arrayOptInt.@max >= %@) || arrayOptInt.@sum != %@) || arrayOptInt.@count == %@) || arrayOptInt.@avg > %@) || arrayOptInt.@avg < %@)",
                    values: [1, 3, sumarrayOptInt, 0, 2, 1], expectedCount: 1) {
            $0.arrayOptInt.min <= 1 ||
            $0.arrayOptInt.max >= 3 ||
            $0.arrayOptInt.sum != sumarrayOptInt ||
            $0.arrayOptInt.count() == 0 ||
            $0.arrayOptInt.avg > 2 ||
            $0.arrayOptInt.avg < 1
        }

        // Keypath Collection Aggregates

        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["doubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["doubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["doubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        let sumdoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(predicate: "(((((arrayCol.@min.doubleCol < %@ || arrayCol.@max.doubleCol > %@) || arrayCol.@sum.doubleCol != %@) || arrayCol.@min.doubleCol == %@) || arrayCol.@avg.doubleCol >= %@) || arrayCol.@avg.doubleCol <= %@)", values: [123.456, 345.678, sumdoubleCol, 0, 345.678, 123.456], expectedCount: 3) {
            $0.arrayCol.doubleCol.min < 123.456 ||
            $0.arrayCol.doubleCol.max > 345.678 ||
            $0.arrayCol.doubleCol.sum != sumdoubleCol ||
            $0.arrayCol.doubleCol.min == 0 ||
            $0.arrayCol.doubleCol.avg >= 345.678 ||
            $0.arrayCol.doubleCol.avg <= 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDoubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["optDoubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["optDoubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        let sumoptDoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(predicate: "(((((arrayCol.@min.optDoubleCol < %@ || arrayCol.@max.optDoubleCol > %@) || arrayCol.@sum.optDoubleCol != %@) || arrayCol.@min.optDoubleCol == %@) || arrayCol.@avg.optDoubleCol >= %@) || arrayCol.@avg.optDoubleCol <= %@)", values: [123.456, 345.678, sumoptDoubleCol, 0, 345.678, 123.456], expectedCount: 3) {
            $0.arrayCol.optDoubleCol.min < 123.456 ||
            $0.arrayCol.optDoubleCol.max > 345.678 ||
            $0.arrayCol.optDoubleCol.sum != sumoptDoubleCol ||
            $0.arrayCol.optDoubleCol.min == 0 ||
            $0.arrayCol.optDoubleCol.avg >= 345.678 ||
            $0.arrayCol.optDoubleCol.avg <= 123.456
        }
    }

    func testCompoundMixed() {
        assertQuery(predicate: "((boolCol == %@ || intCol == %@) && (boolCol != %@ || intCol != %@))",
                    values: [false, 6, false, 6], expectedCount: 0) {
            ($0.boolCol == false || $0.intCol == 6) &&
            ($0.boolCol != false || $0.intCol != 6)
        }
        assertQuery(predicate: "(boolCol == %@ || intCol == %@)", values: [false, 6], expectedCount: 1) {
            ($0.boolCol == false) || ($0.intCol == 6)
        }
        assertQuery(predicate: "((intCol == %@ || int8Col == %@) && (intCol != %@ || int8Col != %@))",
                    values: [6, Int8(9), 6, Int8(9)], expectedCount: 0) {
            ($0.intCol == 6 || $0.int8Col == Int8(9)) &&
            ($0.intCol != 6 || $0.int8Col != Int8(9))
        }
        assertQuery(predicate: "(intCol == %@ || int8Col == %@)", values: [6, Int8(9)], expectedCount: 1) {
            ($0.intCol == 6) || ($0.int8Col == Int8(9))
        }
        assertQuery(predicate: "((int8Col == %@ || int16Col == %@) && (int8Col != %@ || int16Col != %@))",
                    values: [Int8(9), Int16(17), Int8(9), Int16(17)], expectedCount: 0) {
            ($0.int8Col == Int8(9) || $0.int16Col == Int16(17)) &&
            ($0.int8Col != Int8(9) || $0.int16Col != Int16(17))
        }
        assertQuery(predicate: "(int8Col == %@ || int16Col == %@)", values: [Int8(9), Int16(17)], expectedCount: 1) {
            ($0.int8Col == Int8(9)) || ($0.int16Col == Int16(17))
        }
        assertQuery(predicate: "((int16Col == %@ || int32Col == %@) && (int16Col != %@ || int32Col != %@))",
                    values: [Int16(17), Int32(33), Int16(17), Int32(33)], expectedCount: 0) {
            ($0.int16Col == Int16(17) || $0.int32Col == Int32(33)) &&
            ($0.int16Col != Int16(17) || $0.int32Col != Int32(33))
        }
        assertQuery(predicate: "(int16Col == %@ || int32Col == %@)", values: [Int16(17), Int32(33)], expectedCount: 1) {
            ($0.int16Col == Int16(17)) || ($0.int32Col == Int32(33))
        }
        assertQuery(predicate: "((int32Col == %@ || int64Col == %@) && (int32Col != %@ || int64Col != %@))",
                    values: [Int32(33), Int64(65), Int32(33), Int64(65)], expectedCount: 0) {
            ($0.int32Col == Int32(33) || $0.int64Col == Int64(65)) &&
            ($0.int32Col != Int32(33) || $0.int64Col != Int64(65))
        }
        assertQuery(predicate: "(int32Col == %@ || int64Col == %@)", values: [Int32(33), Int64(65)], expectedCount: 1) {
            ($0.int32Col == Int32(33)) || ($0.int64Col == Int64(65))
        }
        assertQuery(predicate: "((int64Col == %@ || floatCol == %@) && (int64Col != %@ || floatCol != %@))",
                    values: [Int64(65), Float(6.55444333), Int64(65), Float(6.55444333)], expectedCount: 0) {
            ($0.int64Col == Int64(65) || $0.floatCol == Float(6.55444333)) &&
            ($0.int64Col != Int64(65) || $0.floatCol != Float(6.55444333))
        }
        assertQuery(predicate: "(int64Col == %@ || floatCol == %@)", values: [Int64(65), Float(6.55444333)], expectedCount: 1) {
            ($0.int64Col == Int64(65)) || ($0.floatCol == Float(6.55444333))
        }
        assertQuery(predicate: "((floatCol == %@ || doubleCol == %@) && (floatCol != %@ || doubleCol != %@))",
                    values: [Float(6.55444333), 234.567, Float(6.55444333), 234.567], expectedCount: 0) {
            ($0.floatCol == Float(6.55444333) || $0.doubleCol == 234.567) &&
            ($0.floatCol != Float(6.55444333) || $0.doubleCol != 234.567)
        }
        assertQuery(predicate: "(floatCol == %@ || doubleCol == %@)", values: [Float(6.55444333), 234.567], expectedCount: 1) {
            ($0.floatCol == Float(6.55444333)) || ($0.doubleCol == 234.567)
        }
        assertQuery(predicate: "((doubleCol == %@ || stringCol == %@) && (doubleCol != %@ || stringCol != %@))",
                    values: [234.567, "Foó", 234.567, "Foó"], expectedCount: 0) {
            ($0.doubleCol == 234.567 || $0.stringCol == "Foó") &&
            ($0.doubleCol != 234.567 || $0.stringCol != "Foó")
        }
        assertQuery(predicate: "(doubleCol == %@ || stringCol == %@)", values: [234.567, "Foó"], expectedCount: 1) {
            ($0.doubleCol == 234.567) || ($0.stringCol == "Foó")
        }
        assertQuery(predicate: "(NOT (doubleCol == %@ || stringCol CONTAINS %@) && stringCol == %@)",
                    values: [234.567, "Foó", "Foó"], expectedCount: 0) {
            !($0.doubleCol == 234.567 || $0.stringCol.contains("Foó")) &&
            ($0.stringCol == "Foó")
        }
        assertQuery(predicate: "((stringCol == %@ || binaryCol == %@) && (stringCol != %@ || binaryCol != %@))",
                    values: ["Foó", Data(count: 128), "Foó", Data(count: 128)], expectedCount: 0) {
            ($0.stringCol == "Foó" || $0.binaryCol == Data(count: 128)) &&
            ($0.stringCol != "Foó" || $0.binaryCol != Data(count: 128))
        }
        assertQuery(predicate: "(stringCol == %@ || binaryCol == %@)", values: ["Foó", Data(count: 128)], expectedCount: 1) {
            ($0.stringCol == "Foó") || ($0.binaryCol == Data(count: 128))
        }
        assertQuery(predicate: "((binaryCol == %@ || dateCol == %@) && (binaryCol != %@ || dateCol != %@))",
                    values: [Data(count: 128), Date(timeIntervalSince1970: 2000000), Data(count: 128), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            ($0.binaryCol == Data(count: 128) || $0.dateCol == Date(timeIntervalSince1970: 2000000)) &&
            ($0.binaryCol != Data(count: 128) || $0.dateCol != Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(predicate: "(binaryCol == %@ || dateCol == %@)", values: [Data(count: 128), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            ($0.binaryCol == Data(count: 128)) || ($0.dateCol == Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(predicate: "((dateCol == %@ || decimalCol == %@) && (dateCol != %@ || decimalCol != %@))",
                    values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567), Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], expectedCount: 0) {
            ($0.dateCol == Date(timeIntervalSince1970: 2000000) || $0.decimalCol == Decimal128(234.567)) &&
            ($0.dateCol != Date(timeIntervalSince1970: 2000000) || $0.decimalCol != Decimal128(234.567))
        }
        assertQuery(predicate: "(dateCol == %@ || decimalCol == %@)", values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], expectedCount: 1) {
            ($0.dateCol == Date(timeIntervalSince1970: 2000000)) || ($0.decimalCol == Decimal128(234.567))
        }
        assertQuery(predicate: "((decimalCol == %@ || objectIdCol == %@) && (decimalCol != %@ || objectIdCol != %@))",
                    values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045"), Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], expectedCount: 0) {
            ($0.decimalCol == Decimal128(234.567) || $0.objectIdCol == ObjectId("61184062c1d8f096a3695045")) &&
            ($0.decimalCol != Decimal128(234.567) || $0.objectIdCol != ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery(predicate: "(decimalCol == %@ || objectIdCol == %@)", values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], expectedCount: 1) {
            ($0.decimalCol == Decimal128(234.567)) || ($0.objectIdCol == ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery(predicate: "((objectIdCol == %@ || intEnumCol == %@) && (objectIdCol != %@ || intEnumCol != %@))",
                    values: [ObjectId("61184062c1d8f096a3695045"), ModernIntEnum.value2.rawValue, ObjectId("61184062c1d8f096a3695045"), ModernIntEnum.value2.rawValue], expectedCount: 0) {
            ($0.objectIdCol == ObjectId("61184062c1d8f096a3695045") || $0.intEnumCol == .value2) &&
            ($0.objectIdCol != ObjectId("61184062c1d8f096a3695045") || $0.intEnumCol != .value2)
        }
        assertQuery(predicate: "(objectIdCol == %@ || intEnumCol == %@)", values: [ObjectId("61184062c1d8f096a3695045"), ModernIntEnum.value2.rawValue], expectedCount: 1) {
            ($0.objectIdCol == ObjectId("61184062c1d8f096a3695045")) || ($0.intEnumCol == .value2)
        }
        assertQuery(predicate: "((intEnumCol == %@ || stringEnumCol == %@) && (intEnumCol != %@ || stringEnumCol != %@))",
                    values: [ModernIntEnum.value2.rawValue, ModernStringEnum.value2.rawValue, ModernIntEnum.value2.rawValue, ModernStringEnum.value2.rawValue], expectedCount: 0) {
            ($0.intEnumCol == .value2 || $0.stringEnumCol == .value2) &&
            ($0.intEnumCol != .value2 || $0.stringEnumCol != .value2)
        }
        assertQuery(predicate: "(intEnumCol == %@ || stringEnumCol == %@)", values: [ModernIntEnum.value2.rawValue, ModernStringEnum.value2.rawValue], expectedCount: 1) {
            ($0.intEnumCol == .value2) || ($0.stringEnumCol == .value2)
        }
        assertQuery(predicate: "((stringEnumCol == %@ || uuidCol == %@) && (stringEnumCol != %@ || uuidCol != %@))",
                    values: [ModernStringEnum.value2.rawValue, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernStringEnum.value2.rawValue, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], expectedCount: 0) {
            ($0.stringEnumCol == .value2 || $0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) &&
            ($0.stringEnumCol != .value2 || $0.uuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery(predicate: "(stringEnumCol == %@ || uuidCol == %@)", values: [ModernStringEnum.value2.rawValue, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], expectedCount: 1) {
            ($0.stringEnumCol == .value2) || ($0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery(predicate: "((uuidCol == %@ || optBoolCol == %@) && (uuidCol != %@ || optBoolCol != %@))",
                    values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, false, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, false], expectedCount: 0) {
            ($0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! || $0.optBoolCol == false) &&
            ($0.uuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")! || $0.optBoolCol != false)
        }
        assertQuery(predicate: "(uuidCol == %@ || optBoolCol == %@)", values: [UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, false], expectedCount: 1) {
            ($0.uuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) || ($0.optBoolCol == false)
        }
        assertQuery(predicate: "((optBoolCol == %@ || optIntCol == %@) && (optBoolCol != %@ || optIntCol != %@))",
                    values: [false, 6, false, 6], expectedCount: 0) {
            ($0.optBoolCol == false || $0.optIntCol == 6) &&
            ($0.optBoolCol != false || $0.optIntCol != 6)
        }
        assertQuery(predicate: "(optBoolCol == %@ || optIntCol == %@)", values: [false, 6], expectedCount: 1) {
            ($0.optBoolCol == false) || ($0.optIntCol == 6)
        }
        assertQuery(predicate: "((optIntCol == %@ || optInt8Col == %@) && (optIntCol != %@ || optInt8Col != %@))",
                    values: [6, Int8(9), 6, Int8(9)], expectedCount: 0) {
            ($0.optIntCol == 6 || $0.optInt8Col == Int8(9)) &&
            ($0.optIntCol != 6 || $0.optInt8Col != Int8(9))
        }
        assertQuery(predicate: "(optIntCol == %@ || optInt8Col == %@)", values: [6, Int8(9)], expectedCount: 1) {
            ($0.optIntCol == 6) || ($0.optInt8Col == Int8(9))
        }
        assertQuery(predicate: "((optInt8Col == %@ || optInt16Col == %@) && (optInt8Col != %@ || optInt16Col != %@))",
                    values: [Int8(9), Int16(17), Int8(9), Int16(17)], expectedCount: 0) {
            ($0.optInt8Col == Int8(9) || $0.optInt16Col == Int16(17)) &&
            ($0.optInt8Col != Int8(9) || $0.optInt16Col != Int16(17))
        }
        assertQuery(predicate: "(optInt8Col == %@ || optInt16Col == %@)", values: [Int8(9), Int16(17)], expectedCount: 1) {
            ($0.optInt8Col == Int8(9)) || ($0.optInt16Col == Int16(17))
        }
        assertQuery(predicate: "((optInt16Col == %@ || optInt32Col == %@) && (optInt16Col != %@ || optInt32Col != %@))",
                    values: [Int16(17), Int32(33), Int16(17), Int32(33)], expectedCount: 0) {
            ($0.optInt16Col == Int16(17) || $0.optInt32Col == Int32(33)) &&
            ($0.optInt16Col != Int16(17) || $0.optInt32Col != Int32(33))
        }
        assertQuery(predicate: "(optInt16Col == %@ || optInt32Col == %@)", values: [Int16(17), Int32(33)], expectedCount: 1) {
            ($0.optInt16Col == Int16(17)) || ($0.optInt32Col == Int32(33))
        }
        assertQuery(predicate: "((optInt32Col == %@ || optInt64Col == %@) && (optInt32Col != %@ || optInt64Col != %@))",
                    values: [Int32(33), Int64(65), Int32(33), Int64(65)], expectedCount: 0) {
            ($0.optInt32Col == Int32(33) || $0.optInt64Col == Int64(65)) &&
            ($0.optInt32Col != Int32(33) || $0.optInt64Col != Int64(65))
        }
        assertQuery(predicate: "(optInt32Col == %@ || optInt64Col == %@)", values: [Int32(33), Int64(65)], expectedCount: 1) {
            ($0.optInt32Col == Int32(33)) || ($0.optInt64Col == Int64(65))
        }
        assertQuery(predicate: "((optInt64Col == %@ || optFloatCol == %@) && (optInt64Col != %@ || optFloatCol != %@))",
                    values: [Int64(65), Float(6.55444333), Int64(65), Float(6.55444333)], expectedCount: 0) {
            ($0.optInt64Col == Int64(65) || $0.optFloatCol == Float(6.55444333)) &&
            ($0.optInt64Col != Int64(65) || $0.optFloatCol != Float(6.55444333))
        }
        assertQuery(predicate: "(optInt64Col == %@ || optFloatCol == %@)", values: [Int64(65), Float(6.55444333)], expectedCount: 1) {
            ($0.optInt64Col == Int64(65)) || ($0.optFloatCol == Float(6.55444333))
        }
        assertQuery(predicate: "((optFloatCol == %@ || optDoubleCol == %@) && (optFloatCol != %@ || optDoubleCol != %@))",
                    values: [Float(6.55444333), 234.567, Float(6.55444333), 234.567], expectedCount: 0) {
            ($0.optFloatCol == Float(6.55444333) || $0.optDoubleCol == 234.567) &&
            ($0.optFloatCol != Float(6.55444333) || $0.optDoubleCol != 234.567)
        }
        assertQuery(predicate: "(optFloatCol == %@ || optDoubleCol == %@)", values: [Float(6.55444333), 234.567], expectedCount: 1) {
            ($0.optFloatCol == Float(6.55444333)) || ($0.optDoubleCol == 234.567)
        }
        assertQuery(predicate: "((optDoubleCol == %@ || optStringCol == %@) && (optDoubleCol != %@ || optStringCol != %@))",
                    values: [234.567, "Foó", 234.567, "Foó"], expectedCount: 0) {
            ($0.optDoubleCol == 234.567 || $0.optStringCol == "Foó") &&
            ($0.optDoubleCol != 234.567 || $0.optStringCol != "Foó")
        }
        assertQuery(predicate: "(optDoubleCol == %@ || optStringCol == %@)", values: [234.567, "Foó"], expectedCount: 1) {
            ($0.optDoubleCol == 234.567) || ($0.optStringCol == "Foó")
        }
        assertQuery(predicate: "(NOT (optDoubleCol == %@ || optStringCol CONTAINS %@) && optStringCol == %@)",
                    values: [234.567, "Foó", "Foó"], expectedCount: 0) {
            !($0.optDoubleCol == 234.567 || $0.optStringCol.contains("Foó")) &&
            ($0.optStringCol == "Foó")
        }
        assertQuery(predicate: "((optStringCol == %@ || optBinaryCol == %@) && (optStringCol != %@ || optBinaryCol != %@))",
                    values: ["Foó", Data(count: 128), "Foó", Data(count: 128)], expectedCount: 0) {
            ($0.optStringCol == "Foó" || $0.optBinaryCol == Data(count: 128)) &&
            ($0.optStringCol != "Foó" || $0.optBinaryCol != Data(count: 128))
        }
        assertQuery(predicate: "(optStringCol == %@ || optBinaryCol == %@)", values: ["Foó", Data(count: 128)], expectedCount: 1) {
            ($0.optStringCol == "Foó") || ($0.optBinaryCol == Data(count: 128))
        }
        assertQuery(predicate: "((optBinaryCol == %@ || optDateCol == %@) && (optBinaryCol != %@ || optDateCol != %@))",
                    values: [Data(count: 128), Date(timeIntervalSince1970: 2000000), Data(count: 128), Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            ($0.optBinaryCol == Data(count: 128) || $0.optDateCol == Date(timeIntervalSince1970: 2000000)) &&
            ($0.optBinaryCol != Data(count: 128) || $0.optDateCol != Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(predicate: "(optBinaryCol == %@ || optDateCol == %@)", values: [Data(count: 128), Date(timeIntervalSince1970: 2000000)], expectedCount: 1) {
            ($0.optBinaryCol == Data(count: 128)) || ($0.optDateCol == Date(timeIntervalSince1970: 2000000))
        }
        assertQuery(predicate: "((optDateCol == %@ || optDecimalCol == %@) && (optDateCol != %@ || optDecimalCol != %@))",
                    values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567), Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], expectedCount: 0) {
            ($0.optDateCol == Date(timeIntervalSince1970: 2000000) || $0.optDecimalCol == Decimal128(234.567)) &&
            ($0.optDateCol != Date(timeIntervalSince1970: 2000000) || $0.optDecimalCol != Decimal128(234.567))
        }
        assertQuery(predicate: "(optDateCol == %@ || optDecimalCol == %@)", values: [Date(timeIntervalSince1970: 2000000), Decimal128(234.567)], expectedCount: 1) {
            ($0.optDateCol == Date(timeIntervalSince1970: 2000000)) || ($0.optDecimalCol == Decimal128(234.567))
        }
        assertQuery(predicate: "((optDecimalCol == %@ || optObjectIdCol == %@) && (optDecimalCol != %@ || optObjectIdCol != %@))",
                    values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045"), Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], expectedCount: 0) {
            ($0.optDecimalCol == Decimal128(234.567) || $0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")) &&
            ($0.optDecimalCol != Decimal128(234.567) || $0.optObjectIdCol != ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery(predicate: "(optDecimalCol == %@ || optObjectIdCol == %@)", values: [Decimal128(234.567), ObjectId("61184062c1d8f096a3695045")], expectedCount: 1) {
            ($0.optDecimalCol == Decimal128(234.567)) || ($0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045"))
        }
        assertQuery(predicate: "((optObjectIdCol == %@ || optIntEnumCol == %@) && (optObjectIdCol != %@ || optIntEnumCol != %@))",
                    values: [ObjectId("61184062c1d8f096a3695045"), ModernIntEnum.value2.rawValue, ObjectId("61184062c1d8f096a3695045"), ModernIntEnum.value2.rawValue], expectedCount: 0) {
            ($0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045") || $0.optIntEnumCol == .value2) &&
            ($0.optObjectIdCol != ObjectId("61184062c1d8f096a3695045") || $0.optIntEnumCol != .value2)
        }
        assertQuery(predicate: "(optObjectIdCol == %@ || optIntEnumCol == %@)", values: [ObjectId("61184062c1d8f096a3695045"), ModernIntEnum.value2.rawValue], expectedCount: 1) {
            ($0.optObjectIdCol == ObjectId("61184062c1d8f096a3695045")) || ($0.optIntEnumCol == .value2)
        }
        assertQuery(predicate: "((optIntEnumCol == %@ || optStringEnumCol == %@) && (optIntEnumCol != %@ || optStringEnumCol != %@))",
                    values: [ModernIntEnum.value2.rawValue, ModernStringEnum.value2.rawValue, ModernIntEnum.value2.rawValue, ModernStringEnum.value2.rawValue], expectedCount: 0) {
            ($0.optIntEnumCol == .value2 || $0.optStringEnumCol == .value2) &&
            ($0.optIntEnumCol != .value2 || $0.optStringEnumCol != .value2)
        }
        assertQuery(predicate: "(optIntEnumCol == %@ || optStringEnumCol == %@)", values: [ModernIntEnum.value2.rawValue, ModernStringEnum.value2.rawValue], expectedCount: 1) {
            ($0.optIntEnumCol == .value2) || ($0.optStringEnumCol == .value2)
        }
        assertQuery(predicate: "((optStringEnumCol == %@ || optUuidCol == %@) && (optStringEnumCol != %@ || optUuidCol != %@))",
                    values: [ModernStringEnum.value2.rawValue, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!, ModernStringEnum.value2.rawValue, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], expectedCount: 0) {
            ($0.optStringEnumCol == .value2 || $0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!) &&
            ($0.optStringEnumCol != .value2 || $0.optUuidCol != UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }
        assertQuery(predicate: "(optStringEnumCol == %@ || optUuidCol == %@)", values: [ModernStringEnum.value2.rawValue, UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!], expectedCount: 1) {
            ($0.optStringEnumCol == .value2) || ($0.optUuidCol == UUID(uuidString: "33041937-05b2-464a-98ad-3910cbe0d09f")!)
        }

        // Aggregates

        let sumarrayInt = 1 + 2
        assertQuery(predicate: "((((arrayInt.@min <= %@ || arrayInt.@max >= %@) && arrayInt.@sum == %@) && arrayInt.@count != %@) && (arrayInt.@avg > %@ && arrayInt.@avg < %@))",
                    values: [1, 3, sumarrayInt, 0, 1, 3], expectedCount: 1) {
            ($0.arrayInt.min <= 1 || $0.arrayInt.max >= 3) &&
            $0.arrayInt.sum == sumarrayInt &&
            $0.arrayInt.count() != 0 &&
            ($0.arrayInt.avg > 1 && $0.arrayInt.avg < 3)
        }
        let sumarrayOptInt = 1 + 2
        assertQuery(predicate: "((((arrayOptInt.@min <= %@ || arrayOptInt.@max >= %@) && arrayOptInt.@sum == %@) && arrayOptInt.@count != %@) && (arrayOptInt.@avg > %@ && arrayOptInt.@avg < %@))",
                    values: [1, 3, sumarrayOptInt, 0, 1, 3], expectedCount: 1) {
            ($0.arrayOptInt.min <= 1 || $0.arrayOptInt.max >= 3) &&
            $0.arrayOptInt.sum == sumarrayOptInt &&
            $0.arrayOptInt.count() != 0 &&
            ($0.arrayOptInt.avg > 1 && $0.arrayOptInt.avg < 3)
        }

        // Keypath Collection Aggregates

        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["doubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["doubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["doubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        let sumdoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(predicate: "((((arrayCol.@min.doubleCol <= %@ || arrayCol.@max.doubleCol >= %@) && arrayCol.@sum.doubleCol == %@) && arrayCol.@sum.doubleCol != %@) && (arrayCol.@avg.doubleCol > %@ && arrayCol.@avg.doubleCol < %@))", values: [123.456, 345.678, sumdoubleCol, 0, 123.456, 345.678], expectedCount: 1) {
            ($0.arrayCol.doubleCol.min <= 123.456 || $0.arrayCol.doubleCol.max >= 345.678) &&
            $0.arrayCol.doubleCol.sum == sumdoubleCol &&
            $0.arrayCol.doubleCol.sum != 0 &&
            ($0.arrayCol.doubleCol.avg > 123.456 && $0.arrayCol.doubleCol.avg < 345.678)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDoubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["optDoubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["optDoubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        let sumoptDoubleCol = 123.456 + 234.567 + 345.678
        assertQuery(predicate: "((((arrayCol.@min.optDoubleCol <= %@ || arrayCol.@max.optDoubleCol >= %@) && arrayCol.@sum.optDoubleCol == %@) && arrayCol.@sum.optDoubleCol != %@) && (arrayCol.@avg.optDoubleCol > %@ && arrayCol.@avg.optDoubleCol < %@))", values: [123.456, 345.678, sumoptDoubleCol, 0, 123.456, 345.678], expectedCount: 1) {
            ($0.arrayCol.optDoubleCol.min <= 123.456 || $0.arrayCol.optDoubleCol.max >= 345.678) &&
            $0.arrayCol.optDoubleCol.sum == sumoptDoubleCol &&
            $0.arrayCol.optDoubleCol.sum != 0 &&
            ($0.arrayCol.optDoubleCol.avg > 123.456 && $0.arrayCol.optDoubleCol.avg < 345.678)
        }
    }

    func testSubquery() {
        // List

        // Count of results will be 0 because there are no `ModernAllTypesObject`s in the list.
        assertQuery(predicate: "SUBQUERY(arrayCol, $obj, $obj.intCol != %@).@count > %@", values: [123, 0], expectedCount: 0) {
            ($0.arrayCol.intCol != 123).count > 0
        }

        assertQuery(predicate: "(((intCol == %@ && %@ IN arrayInt) && SUBQUERY(arrayCol, $obj, ($obj.intCol == %@ && $obj.stringCol == %@)).@count == %@) && SUBQUERY(arrayCol, $obj, $obj.stringCol == %@).@count == %@)", values: [5, 1, 5, "Foo", 3, "Bar", 0], expectedCount: 0) {
            $0.intCol == 5 &&
            $0.arrayInt.contains(1) &&
            ($0.arrayCol.intCol == 5 && $0.arrayCol.stringCol == "Foo").count == 3 &&
            ($0.arrayCol.stringCol == "Bar").count == 0
        }

        // Set

        // Will be 0 results because there are no `ModernAllTypesObject`s in the set.
        assertQuery(predicate: "SUBQUERY(arrayCol, $obj, $obj.intCol != %@).@count > %@", values: [123, 0], expectedCount: 0) {
            ($0.arrayCol.intCol != 123).count > 0
        }

        assertQuery(predicate: "(((intCol == %@ && %@ IN setInt) && SUBQUERY(setCol, $obj, ($obj.intCol == %@ && $obj.stringCol == %@)).@count == %@) && SUBQUERY(setCol, $obj, $obj.stringCol == %@).@count == %@)", values: [5, 1, 5, "Foo", 3, "Bar", 0], expectedCount: 0) {
            $0.intCol == 5 &&
            $0.setInt.contains(1) &&
            ($0.setCol.intCol == 5 && $0.setCol.stringCol == "Foo").count == 3 &&
            ($0.setCol.stringCol == "Bar").count == 0
        }

        let realm = realmWithTestPath()
        let object = objects().first!
        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["intCol": 5, "stringCol": "Foo"])
            object.arrayCol.append(modernObj)
            object.setCol.insert(modernObj)
        }

        // Results count should now be 1

        assertQuery(predicate: "SUBQUERY(arrayCol, $obj, $obj.intCol != %@).@count > %@", values: [123, 0], expectedCount: 1) {
            ($0.arrayCol.intCol != 123).count > 0
        }

        assertQuery(predicate: "SUBQUERY(arrayCol, $obj, ($obj.intCol > %@ && $obj.intCol <= %@)).@count > %@", values: [0, 5, 0], expectedCount: 1) {
            ($0.arrayCol.intCol > 0 && $0.arrayCol.intCol <= 5 ).count > 0
        }

        assertQuery(predicate: "(((intCol == %@ && arrayInt.@count == %@) && SUBQUERY(arrayCol, $obj, $obj.intCol == %@).@count == %@) && SUBQUERY(arrayCol, $obj, $obj.stringCol == %@).@count == %@)", values: [6, 2, 5, 1, "Bar", 0], expectedCount: 1) {
            ($0.intCol == 6) &&
            ($0.arrayInt.count == 2) &&
            ($0.arrayCol.intCol == 5).count == 1 &&
            ($0.arrayCol.stringCol == "Bar").count == 0
        }

        // Set

        // Will be 0 results because there are no `ModernAllTypesObject`s in the set.
        assertQuery(predicate: "SUBQUERY(arrayCol, $obj, $obj.intCol != %@).@count > %@", values: [123, 0], expectedCount: 1) {
            ($0.arrayCol.intCol != 123).count > 0
        }

        assertQuery(predicate: "(((intCol == %@ && setInt.@count == %@) && SUBQUERY(setCol, $obj, $obj.intCol == %@).@count == %@) && SUBQUERY(setCol, $obj, $obj.stringCol == %@).@count == %@)", values: [6, 2, 5, 1, "Bar", 0], expectedCount: 1) {
            ($0.intCol == 6) &&
            ($0.setInt.count == 2) &&
            ($0.setCol.intCol == 5).count == 1 &&
            ($0.setCol.stringCol == "Bar").count == 0
        }

        assertQuery(predicate: "(((intCol == %@ && setInt.@count == %@) && SUBQUERY(setCol, $obj, ($obj.intCol == %@ && $obj.stringCol != %@)).@count == %@) && SUBQUERY(setCol, $obj, $obj.stringCol == %@).@count == %@)", values: [6, 2, 5, "Blah", 1, "Bar", 0], expectedCount: 1) {
            ($0.intCol == 6) &&
            ($0.setInt.count == 2) &&
            (((($0.setCol.intCol == 5) && ($0.setCol.stringCol != "Blah"))).count == 1) &&
            (($0.setCol.stringCol == "Bar").count == 0)
        }

        let query: ((Query<ModernAllTypesObject>) -> Query<ModernAllTypesObject>) = {
            ($0.setCol.intCol == 1 && $0.arrayCol.intCol == 1).count > 0
        }
        assertThrows(query(Query<ModernAllTypesObject>())._constructPredicate(), reason: "Subquery predicates will only work on one collection at a time.")
    }

    // MARK: Collection Aggregations

    func testCollectionAggregatesAvg() {
        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt": [1, 2, 3]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayInt.@avg > %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayInt.avg > 1
        }

        assertQuery(predicate: "objectCol.arrayInt.@avg < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.avg < 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@avg == %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt.avg == 2
        }

        assertQuery(predicate: "objectCol.arrayInt.@avg >= %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayInt.avg >= 1
        }

        assertQuery(predicate: "objectCol.arrayInt.@avg >= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt.avg >= 2
        }

        assertQuery(predicate: "objectCol.arrayInt.@avg <= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.avg <= 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@avg <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt.avg <= 2
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt.@avg != %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt.avg != 2
        }

        assertQuery(predicate: "objectCol.arrayInt.@avg != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayInt.avg != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt8": [Int8(8), Int8(9), Int8(10)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayInt8.@avg > %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayInt8.avg > Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@avg < %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.avg < Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@avg == %@", values: [Int8(9)], expectedCount: 1) {
            $0.objectCol.arrayInt8.avg == Int8(9)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@avg >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayInt8.avg >= Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@avg >= %@", values: [Int8(9)], expectedCount: 1) {
            $0.objectCol.arrayInt8.avg >= Int8(9)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@avg <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.avg <= Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@avg <= %@", values: [Int8(9)], expectedCount: 1) {
            $0.objectCol.arrayInt8.avg <= Int8(9)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt8.@avg != %@", values: [Int8(9)], expectedCount: 1) {
            $0.objectCol.arrayInt8.avg != Int8(9)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@avg != %@", values: [Int8(8)], expectedCount: 2) {
            $0.objectCol.arrayInt8.avg != Int8(8)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt16": [Int16(16), Int16(17), Int16(18)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayInt16.@avg > %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayInt16.avg > Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@avg < %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.avg < Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@avg == %@", values: [Int16(17)], expectedCount: 1) {
            $0.objectCol.arrayInt16.avg == Int16(17)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@avg >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayInt16.avg >= Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@avg >= %@", values: [Int16(17)], expectedCount: 1) {
            $0.objectCol.arrayInt16.avg >= Int16(17)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@avg <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.avg <= Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@avg <= %@", values: [Int16(17)], expectedCount: 1) {
            $0.objectCol.arrayInt16.avg <= Int16(17)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt16.@avg != %@", values: [Int16(17)], expectedCount: 1) {
            $0.objectCol.arrayInt16.avg != Int16(17)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@avg != %@", values: [Int16(16)], expectedCount: 2) {
            $0.objectCol.arrayInt16.avg != Int16(16)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt32": [Int32(32), Int32(33), Int32(34)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayInt32.@avg > %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayInt32.avg > Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@avg < %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.avg < Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@avg == %@", values: [Int32(33)], expectedCount: 1) {
            $0.objectCol.arrayInt32.avg == Int32(33)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@avg >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayInt32.avg >= Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@avg >= %@", values: [Int32(33)], expectedCount: 1) {
            $0.objectCol.arrayInt32.avg >= Int32(33)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@avg <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.avg <= Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@avg <= %@", values: [Int32(33)], expectedCount: 1) {
            $0.objectCol.arrayInt32.avg <= Int32(33)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt32.@avg != %@", values: [Int32(33)], expectedCount: 1) {
            $0.objectCol.arrayInt32.avg != Int32(33)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@avg != %@", values: [Int32(32)], expectedCount: 2) {
            $0.objectCol.arrayInt32.avg != Int32(32)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt64": [Int64(64), Int64(65), Int64(66)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayInt64.@avg > %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayInt64.avg > Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@avg < %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.avg < Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@avg == %@", values: [Int64(65)], expectedCount: 1) {
            $0.objectCol.arrayInt64.avg == Int64(65)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@avg >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayInt64.avg >= Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@avg >= %@", values: [Int64(65)], expectedCount: 1) {
            $0.objectCol.arrayInt64.avg >= Int64(65)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@avg <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.avg <= Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@avg <= %@", values: [Int64(65)], expectedCount: 1) {
            $0.objectCol.arrayInt64.avg <= Int64(65)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt64.@avg != %@", values: [Int64(65)], expectedCount: 1) {
            $0.objectCol.arrayInt64.avg != Int64(65)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@avg != %@", values: [Int64(64)], expectedCount: 2) {
            $0.objectCol.arrayInt64.avg != Int64(64)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayFloat": [Float(5.55444333), Float(6.55444333), Float(7.55444333)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayFloat.@avg > %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.avg > Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@avg < %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.avg < Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@avg == %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.avg == Float(6.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@avg >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.avg >= Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@avg >= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.avg >= Float(6.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@avg <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.avg <= Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@avg <= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.avg <= Float(6.55444333)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayFloat.@avg != %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.avg != Float(6.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@avg != %@", values: [Float(5.55444333)], expectedCount: 2) {
            $0.objectCol.arrayFloat.avg != Float(5.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDouble": [123.456, 234.567, 345.678]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayDouble.@avg > %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayDouble.avg > 123.456
        }

        assertQuery(predicate: "objectCol.arrayDouble.@avg < %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.avg < 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@avg == %@", values: [234.567], expectedCount: 1) {
            $0.objectCol.arrayDouble.avg == 234.567
        }

        assertQuery(predicate: "objectCol.arrayDouble.@avg >= %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayDouble.avg >= 123.456
        }

        assertQuery(predicate: "objectCol.arrayDouble.@avg >= %@", values: [234.567], expectedCount: 1) {
            $0.objectCol.arrayDouble.avg >= 234.567
        }

        assertQuery(predicate: "objectCol.arrayDouble.@avg <= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.avg <= 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@avg <= %@", values: [234.567], expectedCount: 1) {
            $0.objectCol.arrayDouble.avg <= 234.567
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayDouble.@avg != %@", values: [234.567], expectedCount: 1) {
            $0.objectCol.arrayDouble.avg != 234.567
        }

        assertQuery(predicate: "objectCol.arrayDouble.@avg != %@", values: [123.456], expectedCount: 2) {
            $0.objectCol.arrayDouble.avg != 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDecimal": [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@avg > %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.avg > Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@avg < %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.avg < Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@avg == %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.avg == Decimal128(234.567)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@avg >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.avg >= Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@avg >= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.avg >= Decimal128(234.567)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@avg <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.avg <= Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@avg <= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.avg <= Decimal128(234.567)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayDecimal.@avg != %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.avg != Decimal128(234.567)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@avg != %@", values: [Decimal128(123.456)], expectedCount: 2) {
            $0.objectCol.arrayDecimal.avg != Decimal128(123.456)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt": [1, 2, 3]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@avg > %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayOptInt.avg > 1
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@avg < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.avg < 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@avg == %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt.avg == 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@avg >= %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayOptInt.avg >= 1
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@avg >= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt.avg >= 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@avg <= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.avg <= 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@avg <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt.avg <= 2
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt.@avg != %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt.avg != 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@avg != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptInt.avg != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt8": [Int8(8), Int8(9), Int8(10)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@avg > %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.avg > Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@avg < %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.avg < Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@avg == %@", values: [Int8(9)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.avg == Int8(9)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@avg >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.avg >= Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@avg >= %@", values: [Int8(9)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.avg >= Int8(9)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@avg <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.avg <= Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@avg <= %@", values: [Int8(9)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.avg <= Int8(9)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt8.@avg != %@", values: [Int8(9)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.avg != Int8(9)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@avg != %@", values: [Int8(8)], expectedCount: 2) {
            $0.objectCol.arrayOptInt8.avg != Int8(8)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt16": [Int16(16), Int16(17), Int16(18)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@avg > %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.avg > Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@avg < %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.avg < Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@avg == %@", values: [Int16(17)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.avg == Int16(17)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@avg >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.avg >= Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@avg >= %@", values: [Int16(17)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.avg >= Int16(17)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@avg <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.avg <= Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@avg <= %@", values: [Int16(17)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.avg <= Int16(17)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt16.@avg != %@", values: [Int16(17)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.avg != Int16(17)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@avg != %@", values: [Int16(16)], expectedCount: 2) {
            $0.objectCol.arrayOptInt16.avg != Int16(16)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt32": [Int32(32), Int32(33), Int32(34)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@avg > %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.avg > Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@avg < %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.avg < Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@avg == %@", values: [Int32(33)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.avg == Int32(33)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@avg >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.avg >= Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@avg >= %@", values: [Int32(33)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.avg >= Int32(33)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@avg <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.avg <= Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@avg <= %@", values: [Int32(33)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.avg <= Int32(33)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt32.@avg != %@", values: [Int32(33)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.avg != Int32(33)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@avg != %@", values: [Int32(32)], expectedCount: 2) {
            $0.objectCol.arrayOptInt32.avg != Int32(32)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt64": [Int64(64), Int64(65), Int64(66)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@avg > %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.avg > Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@avg < %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.avg < Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@avg == %@", values: [Int64(65)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.avg == Int64(65)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@avg >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.avg >= Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@avg >= %@", values: [Int64(65)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.avg >= Int64(65)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@avg <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.avg <= Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@avg <= %@", values: [Int64(65)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.avg <= Int64(65)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt64.@avg != %@", values: [Int64(65)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.avg != Int64(65)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@avg != %@", values: [Int64(64)], expectedCount: 2) {
            $0.objectCol.arrayOptInt64.avg != Int64(64)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptFloat": [Float(5.55444333), Float(6.55444333), Float(7.55444333)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@avg > %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.avg > Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@avg < %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.avg < Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@avg == %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.avg == Float(6.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@avg >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.avg >= Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@avg >= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.avg >= Float(6.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@avg <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.avg <= Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@avg <= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.avg <= Float(6.55444333)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptFloat.@avg != %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.avg != Float(6.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@avg != %@", values: [Float(5.55444333)], expectedCount: 2) {
            $0.objectCol.arrayOptFloat.avg != Float(5.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDouble": [123.456, 234.567, 345.678]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@avg > %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.avg > 123.456
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@avg < %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.avg < 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@avg == %@", values: [234.567], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.avg == 234.567
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@avg >= %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.avg >= 123.456
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@avg >= %@", values: [234.567], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.avg >= 234.567
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@avg <= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.avg <= 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@avg <= %@", values: [234.567], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.avg <= 234.567
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptDouble.@avg != %@", values: [234.567], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.avg != 234.567
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@avg != %@", values: [123.456], expectedCount: 2) {
            $0.objectCol.arrayOptDouble.avg != 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDecimal": [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@avg > %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.avg > Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@avg < %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.avg < Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@avg == %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.avg == Decimal128(234.567)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@avg >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.avg >= Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@avg >= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.avg >= Decimal128(234.567)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@avg <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.avg <= Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@avg <= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.avg <= Decimal128(234.567)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptDecimal.@avg != %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.avg != Decimal128(234.567)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@avg != %@", values: [Decimal128(123.456)], expectedCount: 2) {
            $0.objectCol.arrayOptDecimal.avg != Decimal128(123.456)
        }
    }

    func testCollectionAggregatesMin() {
        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt": [1, 2, 3]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayInt.@min > %@", values: [1], expectedCount: 0) {
            $0.objectCol.arrayInt.min > 1
        }

        assertQuery(predicate: "objectCol.arrayInt.@min < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.min < 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@min == %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayInt.min == 1
        }

        assertQuery(predicate: "objectCol.arrayInt.@min >= %@", values: [2], expectedCount: 0) {
            $0.objectCol.arrayInt.min >= 2
        }

        assertQuery(predicate: "objectCol.arrayInt.@min >= %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayInt.min >= 1
        }

        assertQuery(predicate: "objectCol.arrayInt.@min <= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.min <= 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@min <= %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayInt.min <= 1
        }

        assertQuery(predicate: "objectCol.arrayInt.@min != %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayInt.min != 1
        }

        assertQuery(predicate: "objectCol.arrayInt.@min != %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayInt.min != 3
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt8": [Int8(8), Int8(9), Int8(10)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayInt8.@min > %@", values: [Int8(8)], expectedCount: 0) {
            $0.objectCol.arrayInt8.min > Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@min < %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.min < Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@min == %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayInt8.min == Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@min >= %@", values: [Int8(9)], expectedCount: 0) {
            $0.objectCol.arrayInt8.min >= Int8(9)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@min >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayInt8.min >= Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@min <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.min <= Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@min <= %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayInt8.min <= Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@min != %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayInt8.min != Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@min != %@", values: [Int8(10)], expectedCount: 2) {
            $0.objectCol.arrayInt8.min != Int8(10)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt16": [Int16(16), Int16(17), Int16(18)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayInt16.@min > %@", values: [Int16(16)], expectedCount: 0) {
            $0.objectCol.arrayInt16.min > Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@min < %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.min < Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@min == %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayInt16.min == Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@min >= %@", values: [Int16(17)], expectedCount: 0) {
            $0.objectCol.arrayInt16.min >= Int16(17)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@min >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayInt16.min >= Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@min <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.min <= Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@min <= %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayInt16.min <= Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@min != %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayInt16.min != Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@min != %@", values: [Int16(18)], expectedCount: 2) {
            $0.objectCol.arrayInt16.min != Int16(18)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt32": [Int32(32), Int32(33), Int32(34)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayInt32.@min > %@", values: [Int32(32)], expectedCount: 0) {
            $0.objectCol.arrayInt32.min > Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@min < %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.min < Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@min == %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayInt32.min == Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@min >= %@", values: [Int32(33)], expectedCount: 0) {
            $0.objectCol.arrayInt32.min >= Int32(33)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@min >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayInt32.min >= Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@min <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.min <= Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@min <= %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayInt32.min <= Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@min != %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayInt32.min != Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@min != %@", values: [Int32(34)], expectedCount: 2) {
            $0.objectCol.arrayInt32.min != Int32(34)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt64": [Int64(64), Int64(65), Int64(66)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayInt64.@min > %@", values: [Int64(64)], expectedCount: 0) {
            $0.objectCol.arrayInt64.min > Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@min < %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.min < Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@min == %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayInt64.min == Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@min >= %@", values: [Int64(65)], expectedCount: 0) {
            $0.objectCol.arrayInt64.min >= Int64(65)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@min >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayInt64.min >= Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@min <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.min <= Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@min <= %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayInt64.min <= Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@min != %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayInt64.min != Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@min != %@", values: [Int64(66)], expectedCount: 2) {
            $0.objectCol.arrayInt64.min != Int64(66)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayFloat": [Float(5.55444333), Float(6.55444333), Float(7.55444333)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayFloat.@min > %@", values: [Float(5.55444333)], expectedCount: 0) {
            $0.objectCol.arrayFloat.min > Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@min < %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.min < Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@min == %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.min == Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@min >= %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.objectCol.arrayFloat.min >= Float(6.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@min >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.min >= Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@min <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.min <= Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@min <= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.min <= Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@min != %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.min != Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@min != %@", values: [Float(7.55444333)], expectedCount: 2) {
            $0.objectCol.arrayFloat.min != Float(7.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDouble": [123.456, 234.567, 345.678]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayDouble.@min > %@", values: [123.456], expectedCount: 0) {
            $0.objectCol.arrayDouble.min > 123.456
        }

        assertQuery(predicate: "objectCol.arrayDouble.@min < %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.min < 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@min == %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayDouble.min == 123.456
        }

        assertQuery(predicate: "objectCol.arrayDouble.@min >= %@", values: [234.567], expectedCount: 0) {
            $0.objectCol.arrayDouble.min >= 234.567
        }

        assertQuery(predicate: "objectCol.arrayDouble.@min >= %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayDouble.min >= 123.456
        }

        assertQuery(predicate: "objectCol.arrayDouble.@min <= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.min <= 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@min <= %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayDouble.min <= 123.456
        }

        assertQuery(predicate: "objectCol.arrayDouble.@min != %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayDouble.min != 123.456
        }

        assertQuery(predicate: "objectCol.arrayDouble.@min != %@", values: [345.678], expectedCount: 2) {
            $0.objectCol.arrayDouble.min != 345.678
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDate": [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000), Date(timeIntervalSince1970: 3000000)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayDate.@min > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.objectCol.arrayDate.min > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@min < %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.min < Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@min == %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.min == Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@min >= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.objectCol.arrayDate.min >= Date(timeIntervalSince1970: 2000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@min >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.min >= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@min <= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.min <= Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@min <= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.min <= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@min != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.min != Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@min != %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 2) {
            $0.objectCol.arrayDate.min != Date(timeIntervalSince1970: 3000000)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDecimal": [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayDecimal.@min > %@", values: [Decimal128(123.456)], expectedCount: 0) {
            $0.objectCol.arrayDecimal.min > Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@min < %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.min < Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@min == %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.min == Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@min >= %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.objectCol.arrayDecimal.min >= Decimal128(234.567)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@min >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.min >= Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@min <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.min <= Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@min <= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.min <= Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@min != %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.min != Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@min != %@", values: [Decimal128(345.678)], expectedCount: 2) {
            $0.objectCol.arrayDecimal.min != Decimal128(345.678)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt": [1, 2, 3]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptInt.@min > %@", values: [1], expectedCount: 0) {
            $0.objectCol.arrayOptInt.min > 1
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@min < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.min < 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@min == %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayOptInt.min == 1
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@min >= %@", values: [2], expectedCount: 0) {
            $0.objectCol.arrayOptInt.min >= 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@min >= %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayOptInt.min >= 1
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@min <= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.min <= 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@min <= %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayOptInt.min <= 1
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@min != %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayOptInt.min != 1
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@min != %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayOptInt.min != 3
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt8": [Int8(8), Int8(9), Int8(10)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptInt8.@min > %@", values: [Int8(8)], expectedCount: 0) {
            $0.objectCol.arrayOptInt8.min > Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@min < %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.min < Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@min == %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.min == Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@min >= %@", values: [Int8(9)], expectedCount: 0) {
            $0.objectCol.arrayOptInt8.min >= Int8(9)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@min >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.min >= Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@min <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.min <= Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@min <= %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.min <= Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@min != %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.min != Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@min != %@", values: [Int8(10)], expectedCount: 2) {
            $0.objectCol.arrayOptInt8.min != Int8(10)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt16": [Int16(16), Int16(17), Int16(18)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptInt16.@min > %@", values: [Int16(16)], expectedCount: 0) {
            $0.objectCol.arrayOptInt16.min > Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@min < %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.min < Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@min == %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.min == Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@min >= %@", values: [Int16(17)], expectedCount: 0) {
            $0.objectCol.arrayOptInt16.min >= Int16(17)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@min >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.min >= Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@min <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.min <= Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@min <= %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.min <= Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@min != %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.min != Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@min != %@", values: [Int16(18)], expectedCount: 2) {
            $0.objectCol.arrayOptInt16.min != Int16(18)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt32": [Int32(32), Int32(33), Int32(34)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptInt32.@min > %@", values: [Int32(32)], expectedCount: 0) {
            $0.objectCol.arrayOptInt32.min > Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@min < %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.min < Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@min == %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.min == Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@min >= %@", values: [Int32(33)], expectedCount: 0) {
            $0.objectCol.arrayOptInt32.min >= Int32(33)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@min >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.min >= Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@min <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.min <= Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@min <= %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.min <= Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@min != %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.min != Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@min != %@", values: [Int32(34)], expectedCount: 2) {
            $0.objectCol.arrayOptInt32.min != Int32(34)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt64": [Int64(64), Int64(65), Int64(66)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptInt64.@min > %@", values: [Int64(64)], expectedCount: 0) {
            $0.objectCol.arrayOptInt64.min > Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@min < %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.min < Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@min == %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.min == Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@min >= %@", values: [Int64(65)], expectedCount: 0) {
            $0.objectCol.arrayOptInt64.min >= Int64(65)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@min >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.min >= Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@min <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.min <= Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@min <= %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.min <= Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@min != %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.min != Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@min != %@", values: [Int64(66)], expectedCount: 2) {
            $0.objectCol.arrayOptInt64.min != Int64(66)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptFloat": [Float(5.55444333), Float(6.55444333), Float(7.55444333)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptFloat.@min > %@", values: [Float(5.55444333)], expectedCount: 0) {
            $0.objectCol.arrayOptFloat.min > Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@min < %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.min < Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@min == %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.min == Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@min >= %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.objectCol.arrayOptFloat.min >= Float(6.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@min >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.min >= Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@min <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.min <= Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@min <= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.min <= Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@min != %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.min != Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@min != %@", values: [Float(7.55444333)], expectedCount: 2) {
            $0.objectCol.arrayOptFloat.min != Float(7.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDouble": [123.456, 234.567, 345.678]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptDouble.@min > %@", values: [123.456], expectedCount: 0) {
            $0.objectCol.arrayOptDouble.min > 123.456
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@min < %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.min < 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@min == %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.min == 123.456
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@min >= %@", values: [234.567], expectedCount: 0) {
            $0.objectCol.arrayOptDouble.min >= 234.567
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@min >= %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.min >= 123.456
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@min <= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.min <= 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@min <= %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.min <= 123.456
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@min != %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.min != 123.456
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@min != %@", values: [345.678], expectedCount: 2) {
            $0.objectCol.arrayOptDouble.min != 345.678
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDate": [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000), Date(timeIntervalSince1970: 3000000)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptDate.@min > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.objectCol.arrayOptDate.min > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@min < %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.min < Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@min == %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.min == Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@min >= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.objectCol.arrayOptDate.min >= Date(timeIntervalSince1970: 2000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@min >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.min >= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@min <= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.min <= Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@min <= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.min <= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@min != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.min != Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@min != %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 2) {
            $0.objectCol.arrayOptDate.min != Date(timeIntervalSince1970: 3000000)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDecimal": [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptDecimal.@min > %@", values: [Decimal128(123.456)], expectedCount: 0) {
            $0.objectCol.arrayOptDecimal.min > Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@min < %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.min < Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@min == %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.min == Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@min >= %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.objectCol.arrayOptDecimal.min >= Decimal128(234.567)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@min >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.min >= Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@min <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.min <= Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@min <= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.min <= Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@min != %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.min != Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@min != %@", values: [Decimal128(345.678)], expectedCount: 2) {
            $0.objectCol.arrayOptDecimal.min != Decimal128(345.678)
        }
    }

    func testCollectionAggregatesMax() {
        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt": [1, 2, 3]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayInt.@max > %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayInt.max > 1
        }

        assertQuery(predicate: "objectCol.arrayInt.@max < %@", values: [3], expectedCount: 0) {
            $0.objectCol.arrayInt.max < 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@max == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.max == 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@max >= %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayInt.max >= 1
        }

        assertQuery(predicate: "objectCol.arrayInt.@max >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.max >= 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@max <= %@", values: [2], expectedCount: 0) {
            $0.objectCol.arrayInt.max <= 2
        }

        assertQuery(predicate: "objectCol.arrayInt.@max <= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.max <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt.@max != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.max != 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@max != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayInt.max != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt8": [Int8(8), Int8(9), Int8(10)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayInt8.@max > %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayInt8.max > Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@max < %@", values: [Int8(10)], expectedCount: 0) {
            $0.objectCol.arrayInt8.max < Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@max == %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.max == Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@max >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayInt8.max >= Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@max >= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.max >= Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@max <= %@", values: [Int8(9)], expectedCount: 0) {
            $0.objectCol.arrayInt8.max <= Int8(9)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@max <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.max <= Int8(10)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt8.@max != %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.max != Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@max != %@", values: [Int8(8)], expectedCount: 2) {
            $0.objectCol.arrayInt8.max != Int8(8)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt16": [Int16(16), Int16(17), Int16(18)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayInt16.@max > %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayInt16.max > Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@max < %@", values: [Int16(18)], expectedCount: 0) {
            $0.objectCol.arrayInt16.max < Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@max == %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.max == Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@max >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayInt16.max >= Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@max >= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.max >= Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@max <= %@", values: [Int16(17)], expectedCount: 0) {
            $0.objectCol.arrayInt16.max <= Int16(17)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@max <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.max <= Int16(18)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt16.@max != %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.max != Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@max != %@", values: [Int16(16)], expectedCount: 2) {
            $0.objectCol.arrayInt16.max != Int16(16)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt32": [Int32(32), Int32(33), Int32(34)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayInt32.@max > %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayInt32.max > Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@max < %@", values: [Int32(34)], expectedCount: 0) {
            $0.objectCol.arrayInt32.max < Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@max == %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.max == Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@max >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayInt32.max >= Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@max >= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.max >= Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@max <= %@", values: [Int32(33)], expectedCount: 0) {
            $0.objectCol.arrayInt32.max <= Int32(33)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@max <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.max <= Int32(34)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt32.@max != %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.max != Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@max != %@", values: [Int32(32)], expectedCount: 2) {
            $0.objectCol.arrayInt32.max != Int32(32)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt64": [Int64(64), Int64(65), Int64(66)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayInt64.@max > %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayInt64.max > Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@max < %@", values: [Int64(66)], expectedCount: 0) {
            $0.objectCol.arrayInt64.max < Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@max == %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.max == Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@max >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayInt64.max >= Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@max >= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.max >= Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@max <= %@", values: [Int64(65)], expectedCount: 0) {
            $0.objectCol.arrayInt64.max <= Int64(65)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@max <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.max <= Int64(66)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt64.@max != %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.max != Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@max != %@", values: [Int64(64)], expectedCount: 2) {
            $0.objectCol.arrayInt64.max != Int64(64)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayFloat": [Float(5.55444333), Float(6.55444333), Float(7.55444333)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayFloat.@max > %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.max > Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@max < %@", values: [Float(7.55444333)], expectedCount: 0) {
            $0.objectCol.arrayFloat.max < Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@max == %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.max == Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@max >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.max >= Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@max >= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.max >= Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@max <= %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.objectCol.arrayFloat.max <= Float(6.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@max <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.max <= Float(7.55444333)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayFloat.@max != %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.max != Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@max != %@", values: [Float(5.55444333)], expectedCount: 2) {
            $0.objectCol.arrayFloat.max != Float(5.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDouble": [123.456, 234.567, 345.678]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayDouble.@max > %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayDouble.max > 123.456
        }

        assertQuery(predicate: "objectCol.arrayDouble.@max < %@", values: [345.678], expectedCount: 0) {
            $0.objectCol.arrayDouble.max < 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@max == %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.max == 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@max >= %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayDouble.max >= 123.456
        }

        assertQuery(predicate: "objectCol.arrayDouble.@max >= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.max >= 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@max <= %@", values: [234.567], expectedCount: 0) {
            $0.objectCol.arrayDouble.max <= 234.567
        }

        assertQuery(predicate: "objectCol.arrayDouble.@max <= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.max <= 345.678
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayDouble.@max != %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.max != 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@max != %@", values: [123.456], expectedCount: 2) {
            $0.objectCol.arrayDouble.max != 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDate": [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000), Date(timeIntervalSince1970: 3000000)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayDate.@max > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.max > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@max < %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 0) {
            $0.objectCol.arrayDate.max < Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@max == %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.max == Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@max >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.max >= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@max >= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.max >= Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@max <= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.objectCol.arrayDate.max <= Date(timeIntervalSince1970: 2000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@max <= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.max <= Date(timeIntervalSince1970: 3000000)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayDate.@max != %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayDate.max != Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayDate.@max != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 2) {
            $0.objectCol.arrayDate.max != Date(timeIntervalSince1970: 1000000)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDecimal": [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayDecimal.@max > %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.max > Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@max < %@", values: [Decimal128(345.678)], expectedCount: 0) {
            $0.objectCol.arrayDecimal.max < Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@max == %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.max == Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@max >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.max >= Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@max >= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.max >= Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@max <= %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.objectCol.arrayDecimal.max <= Decimal128(234.567)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@max <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.max <= Decimal128(345.678)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayDecimal.@max != %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.max != Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@max != %@", values: [Decimal128(123.456)], expectedCount: 2) {
            $0.objectCol.arrayDecimal.max != Decimal128(123.456)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt": [1, 2, 3]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptInt.@max > %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayOptInt.max > 1
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@max < %@", values: [3], expectedCount: 0) {
            $0.objectCol.arrayOptInt.max < 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@max == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.max == 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@max >= %@", values: [1], expectedCount: 1) {
            $0.objectCol.arrayOptInt.max >= 1
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@max >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.max >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@max <= %@", values: [2], expectedCount: 0) {
            $0.objectCol.arrayOptInt.max <= 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@max <= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.max <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt.@max != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.max != 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@max != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptInt.max != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt8": [Int8(8), Int8(9), Int8(10)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptInt8.@max > %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.max > Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@max < %@", values: [Int8(10)], expectedCount: 0) {
            $0.objectCol.arrayOptInt8.max < Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@max == %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.max == Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@max >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.max >= Int8(8)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@max >= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.max >= Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@max <= %@", values: [Int8(9)], expectedCount: 0) {
            $0.objectCol.arrayOptInt8.max <= Int8(9)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@max <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.max <= Int8(10)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt8.@max != %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.max != Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@max != %@", values: [Int8(8)], expectedCount: 2) {
            $0.objectCol.arrayOptInt8.max != Int8(8)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt16": [Int16(16), Int16(17), Int16(18)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptInt16.@max > %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.max > Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@max < %@", values: [Int16(18)], expectedCount: 0) {
            $0.objectCol.arrayOptInt16.max < Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@max == %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.max == Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@max >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.max >= Int16(16)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@max >= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.max >= Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@max <= %@", values: [Int16(17)], expectedCount: 0) {
            $0.objectCol.arrayOptInt16.max <= Int16(17)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@max <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.max <= Int16(18)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt16.@max != %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.max != Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@max != %@", values: [Int16(16)], expectedCount: 2) {
            $0.objectCol.arrayOptInt16.max != Int16(16)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt32": [Int32(32), Int32(33), Int32(34)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptInt32.@max > %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.max > Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@max < %@", values: [Int32(34)], expectedCount: 0) {
            $0.objectCol.arrayOptInt32.max < Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@max == %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.max == Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@max >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.max >= Int32(32)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@max >= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.max >= Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@max <= %@", values: [Int32(33)], expectedCount: 0) {
            $0.objectCol.arrayOptInt32.max <= Int32(33)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@max <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.max <= Int32(34)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt32.@max != %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.max != Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@max != %@", values: [Int32(32)], expectedCount: 2) {
            $0.objectCol.arrayOptInt32.max != Int32(32)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt64": [Int64(64), Int64(65), Int64(66)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptInt64.@max > %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.max > Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@max < %@", values: [Int64(66)], expectedCount: 0) {
            $0.objectCol.arrayOptInt64.max < Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@max == %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.max == Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@max >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.max >= Int64(64)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@max >= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.max >= Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@max <= %@", values: [Int64(65)], expectedCount: 0) {
            $0.objectCol.arrayOptInt64.max <= Int64(65)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@max <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.max <= Int64(66)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt64.@max != %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.max != Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@max != %@", values: [Int64(64)], expectedCount: 2) {
            $0.objectCol.arrayOptInt64.max != Int64(64)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptFloat": [Float(5.55444333), Float(6.55444333), Float(7.55444333)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptFloat.@max > %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.max > Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@max < %@", values: [Float(7.55444333)], expectedCount: 0) {
            $0.objectCol.arrayOptFloat.max < Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@max == %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.max == Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@max >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.max >= Float(5.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@max >= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.max >= Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@max <= %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.objectCol.arrayOptFloat.max <= Float(6.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@max <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.max <= Float(7.55444333)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptFloat.@max != %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.max != Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@max != %@", values: [Float(5.55444333)], expectedCount: 2) {
            $0.objectCol.arrayOptFloat.max != Float(5.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDouble": [123.456, 234.567, 345.678]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptDouble.@max > %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.max > 123.456
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@max < %@", values: [345.678], expectedCount: 0) {
            $0.objectCol.arrayOptDouble.max < 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@max == %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.max == 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@max >= %@", values: [123.456], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.max >= 123.456
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@max >= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.max >= 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@max <= %@", values: [234.567], expectedCount: 0) {
            $0.objectCol.arrayOptDouble.max <= 234.567
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@max <= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.max <= 345.678
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptDouble.@max != %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.max != 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@max != %@", values: [123.456], expectedCount: 2) {
            $0.objectCol.arrayOptDouble.max != 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDate": [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000), Date(timeIntervalSince1970: 3000000)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptDate.@max > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.max > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@max < %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 0) {
            $0.objectCol.arrayOptDate.max < Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@max == %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.max == Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@max >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.max >= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@max >= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.max >= Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@max <= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.objectCol.arrayOptDate.max <= Date(timeIntervalSince1970: 2000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@max <= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.max <= Date(timeIntervalSince1970: 3000000)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptDate.@max != %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.objectCol.arrayOptDate.max != Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@max != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 2) {
            $0.objectCol.arrayOptDate.max != Date(timeIntervalSince1970: 1000000)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDecimal": [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }
        assertQuery(predicate: "objectCol.arrayOptDecimal.@max > %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.max > Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@max < %@", values: [Decimal128(345.678)], expectedCount: 0) {
            $0.objectCol.arrayOptDecimal.max < Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@max == %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.max == Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@max >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.max >= Decimal128(123.456)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@max >= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.max >= Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@max <= %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.objectCol.arrayOptDecimal.max <= Decimal128(234.567)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@max <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.max <= Decimal128(345.678)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptDecimal.@max != %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.max != Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@max != %@", values: [Decimal128(123.456)], expectedCount: 2) {
            $0.objectCol.arrayOptDecimal.max != Decimal128(123.456)
        }
    }

    func testCollectionAggregatesSum() {
        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt": [1, 2, 3]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayInt = 1 + 2 + 3
        assertQuery(predicate: "objectCol.arrayInt.@sum > %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.sum > 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@sum < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.sum < 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@sum == %@", values: [3], expectedCount: 0) {
            $0.objectCol.arrayInt.sum == 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@sum == %@", values: [sumarrayInt], expectedCount: 1) {
            $0.objectCol.arrayInt.sum == sumarrayInt
        }

        assertQuery(predicate: "objectCol.arrayInt.@sum >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.sum >= 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@sum >= %@", values: [sumarrayInt], expectedCount: 1) {
            $0.objectCol.arrayInt.sum >= sumarrayInt
        }

        assertQuery(predicate: "objectCol.arrayInt.@sum <= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.sum <= 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@sum <= %@", values: [sumarrayInt], expectedCount: 2) {
            $0.objectCol.arrayInt.sum <= sumarrayInt
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt.@sum != %@", values: [sumarrayInt], expectedCount: 1) {
            $0.objectCol.arrayInt.sum != sumarrayInt
        }

        assertQuery(predicate: "objectCol.arrayInt.@sum != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayInt.sum != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt8": [Int8(8), Int8(9), Int8(10)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayInt8 = Int8(8) + Int8(9) + Int8(10)
        assertQuery(predicate: "objectCol.arrayInt8.@sum > %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.sum > Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@sum < %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.sum < Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@sum == %@", values: [Int8(10)], expectedCount: 0) {
            $0.objectCol.arrayInt8.sum == Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@sum == %@", values: [sumarrayInt8], expectedCount: 1) {
            $0.objectCol.arrayInt8.sum == sumarrayInt8
        }

        assertQuery(predicate: "objectCol.arrayInt8.@sum >= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.sum >= Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@sum >= %@", values: [sumarrayInt8], expectedCount: 1) {
            $0.objectCol.arrayInt8.sum >= sumarrayInt8
        }

        assertQuery(predicate: "objectCol.arrayInt8.@sum <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayInt8.sum <= Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayInt8.@sum <= %@", values: [sumarrayInt8], expectedCount: 2) {
            $0.objectCol.arrayInt8.sum <= sumarrayInt8
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt8.@sum != %@", values: [sumarrayInt8], expectedCount: 1) {
            $0.objectCol.arrayInt8.sum != sumarrayInt8
        }

        assertQuery(predicate: "objectCol.arrayInt8.@sum != %@", values: [Int8(8)], expectedCount: 2) {
            $0.objectCol.arrayInt8.sum != Int8(8)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt16": [Int16(16), Int16(17), Int16(18)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayInt16 = Int16(16) + Int16(17) + Int16(18)
        assertQuery(predicate: "objectCol.arrayInt16.@sum > %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.sum > Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@sum < %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.sum < Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@sum == %@", values: [Int16(18)], expectedCount: 0) {
            $0.objectCol.arrayInt16.sum == Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@sum == %@", values: [sumarrayInt16], expectedCount: 1) {
            $0.objectCol.arrayInt16.sum == sumarrayInt16
        }

        assertQuery(predicate: "objectCol.arrayInt16.@sum >= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.sum >= Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@sum >= %@", values: [sumarrayInt16], expectedCount: 1) {
            $0.objectCol.arrayInt16.sum >= sumarrayInt16
        }

        assertQuery(predicate: "objectCol.arrayInt16.@sum <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayInt16.sum <= Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayInt16.@sum <= %@", values: [sumarrayInt16], expectedCount: 2) {
            $0.objectCol.arrayInt16.sum <= sumarrayInt16
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt16.@sum != %@", values: [sumarrayInt16], expectedCount: 1) {
            $0.objectCol.arrayInt16.sum != sumarrayInt16
        }

        assertQuery(predicate: "objectCol.arrayInt16.@sum != %@", values: [Int16(16)], expectedCount: 2) {
            $0.objectCol.arrayInt16.sum != Int16(16)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt32": [Int32(32), Int32(33), Int32(34)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayInt32 = Int32(32) + Int32(33) + Int32(34)
        assertQuery(predicate: "objectCol.arrayInt32.@sum > %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.sum > Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@sum < %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.sum < Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@sum == %@", values: [Int32(34)], expectedCount: 0) {
            $0.objectCol.arrayInt32.sum == Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@sum == %@", values: [sumarrayInt32], expectedCount: 1) {
            $0.objectCol.arrayInt32.sum == sumarrayInt32
        }

        assertQuery(predicate: "objectCol.arrayInt32.@sum >= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.sum >= Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@sum >= %@", values: [sumarrayInt32], expectedCount: 1) {
            $0.objectCol.arrayInt32.sum >= sumarrayInt32
        }

        assertQuery(predicate: "objectCol.arrayInt32.@sum <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayInt32.sum <= Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayInt32.@sum <= %@", values: [sumarrayInt32], expectedCount: 2) {
            $0.objectCol.arrayInt32.sum <= sumarrayInt32
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt32.@sum != %@", values: [sumarrayInt32], expectedCount: 1) {
            $0.objectCol.arrayInt32.sum != sumarrayInt32
        }

        assertQuery(predicate: "objectCol.arrayInt32.@sum != %@", values: [Int32(32)], expectedCount: 2) {
            $0.objectCol.arrayInt32.sum != Int32(32)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt64": [Int64(64), Int64(65), Int64(66)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayInt64 = Int64(64) + Int64(65) + Int64(66)
        assertQuery(predicate: "objectCol.arrayInt64.@sum > %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.sum > Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@sum < %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.sum < Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@sum == %@", values: [Int64(66)], expectedCount: 0) {
            $0.objectCol.arrayInt64.sum == Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@sum == %@", values: [sumarrayInt64], expectedCount: 1) {
            $0.objectCol.arrayInt64.sum == sumarrayInt64
        }

        assertQuery(predicate: "objectCol.arrayInt64.@sum >= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.sum >= Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@sum >= %@", values: [sumarrayInt64], expectedCount: 1) {
            $0.objectCol.arrayInt64.sum >= sumarrayInt64
        }

        assertQuery(predicate: "objectCol.arrayInt64.@sum <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayInt64.sum <= Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayInt64.@sum <= %@", values: [sumarrayInt64], expectedCount: 2) {
            $0.objectCol.arrayInt64.sum <= sumarrayInt64
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt64.@sum != %@", values: [sumarrayInt64], expectedCount: 1) {
            $0.objectCol.arrayInt64.sum != sumarrayInt64
        }

        assertQuery(predicate: "objectCol.arrayInt64.@sum != %@", values: [Int64(64)], expectedCount: 2) {
            $0.objectCol.arrayInt64.sum != Int64(64)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayFloat": [Float(5.55444333), Float(6.55444333), Float(7.55444333)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayFloat = Float(5.55444333) + Float(6.55444333) + Float(7.55444333)
        assertQuery(predicate: "objectCol.arrayFloat.@sum > %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.sum > Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@sum < %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.sum < Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@sum == %@", values: [Float(7.55444333)], expectedCount: 0) {
            $0.objectCol.arrayFloat.sum == Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@sum == %@", values: [sumarrayFloat], expectedCount: 1) {
            $0.objectCol.arrayFloat.sum == sumarrayFloat
        }

        assertQuery(predicate: "objectCol.arrayFloat.@sum >= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.sum >= Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@sum >= %@", values: [sumarrayFloat], expectedCount: 1) {
            $0.objectCol.arrayFloat.sum >= sumarrayFloat
        }

        assertQuery(predicate: "objectCol.arrayFloat.@sum <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayFloat.sum <= Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayFloat.@sum <= %@", values: [sumarrayFloat], expectedCount: 2) {
            $0.objectCol.arrayFloat.sum <= sumarrayFloat
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayFloat.@sum != %@", values: [sumarrayFloat], expectedCount: 1) {
            $0.objectCol.arrayFloat.sum != sumarrayFloat
        }

        assertQuery(predicate: "objectCol.arrayFloat.@sum != %@", values: [Float(5.55444333)], expectedCount: 2) {
            $0.objectCol.arrayFloat.sum != Float(5.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDouble": [123.456, 234.567, 345.678]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayDouble = 123.456 + 234.567 + 345.678
        assertQuery(predicate: "objectCol.arrayDouble.@sum > %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.sum > 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@sum < %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.sum < 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@sum == %@", values: [345.678], expectedCount: 0) {
            $0.objectCol.arrayDouble.sum == 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@sum == %@", values: [sumarrayDouble], expectedCount: 1) {
            $0.objectCol.arrayDouble.sum == sumarrayDouble
        }

        assertQuery(predicate: "objectCol.arrayDouble.@sum >= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.sum >= 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@sum >= %@", values: [sumarrayDouble], expectedCount: 1) {
            $0.objectCol.arrayDouble.sum >= sumarrayDouble
        }

        assertQuery(predicate: "objectCol.arrayDouble.@sum <= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayDouble.sum <= 345.678
        }

        assertQuery(predicate: "objectCol.arrayDouble.@sum <= %@", values: [sumarrayDouble], expectedCount: 2) {
            $0.objectCol.arrayDouble.sum <= sumarrayDouble
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayDouble.@sum != %@", values: [sumarrayDouble], expectedCount: 1) {
            $0.objectCol.arrayDouble.sum != sumarrayDouble
        }

        assertQuery(predicate: "objectCol.arrayDouble.@sum != %@", values: [123.456], expectedCount: 2) {
            $0.objectCol.arrayDouble.sum != 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDecimal": [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayDecimal = Decimal128(123.456) + Decimal128(234.567) + Decimal128(345.678)
        assertQuery(predicate: "objectCol.arrayDecimal.@sum > %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.sum > Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@sum < %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.sum < Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@sum == %@", values: [Decimal128(345.678)], expectedCount: 0) {
            $0.objectCol.arrayDecimal.sum == Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@sum == %@", values: [sumarrayDecimal], expectedCount: 1) {
            $0.objectCol.arrayDecimal.sum == sumarrayDecimal
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@sum >= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.sum >= Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@sum >= %@", values: [sumarrayDecimal], expectedCount: 1) {
            $0.objectCol.arrayDecimal.sum >= sumarrayDecimal
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@sum <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayDecimal.sum <= Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@sum <= %@", values: [sumarrayDecimal], expectedCount: 2) {
            $0.objectCol.arrayDecimal.sum <= sumarrayDecimal
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayDecimal.@sum != %@", values: [sumarrayDecimal], expectedCount: 1) {
            $0.objectCol.arrayDecimal.sum != sumarrayDecimal
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@sum != %@", values: [Decimal128(123.456)], expectedCount: 2) {
            $0.objectCol.arrayDecimal.sum != Decimal128(123.456)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt": [1, 2, 3]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayOptInt = 1 + 2 + 3
        assertQuery(predicate: "objectCol.arrayOptInt.@sum > %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.sum > 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@sum < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.sum < 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@sum == %@", values: [3], expectedCount: 0) {
            $0.objectCol.arrayOptInt.sum == 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@sum == %@", values: [sumarrayOptInt], expectedCount: 1) {
            $0.objectCol.arrayOptInt.sum == sumarrayOptInt
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@sum >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.sum >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@sum >= %@", values: [sumarrayOptInt], expectedCount: 1) {
            $0.objectCol.arrayOptInt.sum >= sumarrayOptInt
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@sum <= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.sum <= 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@sum <= %@", values: [sumarrayOptInt], expectedCount: 2) {
            $0.objectCol.arrayOptInt.sum <= sumarrayOptInt
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt.@sum != %@", values: [sumarrayOptInt], expectedCount: 1) {
            $0.objectCol.arrayOptInt.sum != sumarrayOptInt
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@sum != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptInt.sum != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt8": [Int8(8), Int8(9), Int8(10)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayOptInt8 = Int8(8) + Int8(9) + Int8(10)
        assertQuery(predicate: "objectCol.arrayOptInt8.@sum > %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.sum > Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@sum < %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.sum < Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@sum == %@", values: [Int8(10)], expectedCount: 0) {
            $0.objectCol.arrayOptInt8.sum == Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@sum == %@", values: [sumarrayOptInt8], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.sum == sumarrayOptInt8
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@sum >= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.sum >= Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@sum >= %@", values: [sumarrayOptInt8], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.sum >= sumarrayOptInt8
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@sum <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.sum <= Int8(10)
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@sum <= %@", values: [sumarrayOptInt8], expectedCount: 2) {
            $0.objectCol.arrayOptInt8.sum <= sumarrayOptInt8
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt8.@sum != %@", values: [sumarrayOptInt8], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.sum != sumarrayOptInt8
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@sum != %@", values: [Int8(8)], expectedCount: 2) {
            $0.objectCol.arrayOptInt8.sum != Int8(8)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt16": [Int16(16), Int16(17), Int16(18)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayOptInt16 = Int16(16) + Int16(17) + Int16(18)
        assertQuery(predicate: "objectCol.arrayOptInt16.@sum > %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.sum > Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@sum < %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.sum < Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@sum == %@", values: [Int16(18)], expectedCount: 0) {
            $0.objectCol.arrayOptInt16.sum == Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@sum == %@", values: [sumarrayOptInt16], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.sum == sumarrayOptInt16
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@sum >= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.sum >= Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@sum >= %@", values: [sumarrayOptInt16], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.sum >= sumarrayOptInt16
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@sum <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.sum <= Int16(18)
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@sum <= %@", values: [sumarrayOptInt16], expectedCount: 2) {
            $0.objectCol.arrayOptInt16.sum <= sumarrayOptInt16
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt16.@sum != %@", values: [sumarrayOptInt16], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.sum != sumarrayOptInt16
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@sum != %@", values: [Int16(16)], expectedCount: 2) {
            $0.objectCol.arrayOptInt16.sum != Int16(16)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt32": [Int32(32), Int32(33), Int32(34)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayOptInt32 = Int32(32) + Int32(33) + Int32(34)
        assertQuery(predicate: "objectCol.arrayOptInt32.@sum > %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.sum > Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@sum < %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.sum < Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@sum == %@", values: [Int32(34)], expectedCount: 0) {
            $0.objectCol.arrayOptInt32.sum == Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@sum == %@", values: [sumarrayOptInt32], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.sum == sumarrayOptInt32
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@sum >= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.sum >= Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@sum >= %@", values: [sumarrayOptInt32], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.sum >= sumarrayOptInt32
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@sum <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.sum <= Int32(34)
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@sum <= %@", values: [sumarrayOptInt32], expectedCount: 2) {
            $0.objectCol.arrayOptInt32.sum <= sumarrayOptInt32
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt32.@sum != %@", values: [sumarrayOptInt32], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.sum != sumarrayOptInt32
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@sum != %@", values: [Int32(32)], expectedCount: 2) {
            $0.objectCol.arrayOptInt32.sum != Int32(32)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt64": [Int64(64), Int64(65), Int64(66)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayOptInt64 = Int64(64) + Int64(65) + Int64(66)
        assertQuery(predicate: "objectCol.arrayOptInt64.@sum > %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.sum > Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@sum < %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.sum < Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@sum == %@", values: [Int64(66)], expectedCount: 0) {
            $0.objectCol.arrayOptInt64.sum == Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@sum == %@", values: [sumarrayOptInt64], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.sum == sumarrayOptInt64
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@sum >= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.sum >= Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@sum >= %@", values: [sumarrayOptInt64], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.sum >= sumarrayOptInt64
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@sum <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.sum <= Int64(66)
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@sum <= %@", values: [sumarrayOptInt64], expectedCount: 2) {
            $0.objectCol.arrayOptInt64.sum <= sumarrayOptInt64
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt64.@sum != %@", values: [sumarrayOptInt64], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.sum != sumarrayOptInt64
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@sum != %@", values: [Int64(64)], expectedCount: 2) {
            $0.objectCol.arrayOptInt64.sum != Int64(64)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptFloat": [Float(5.55444333), Float(6.55444333), Float(7.55444333)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayOptFloat = Float(5.55444333) + Float(6.55444333) + Float(7.55444333)
        assertQuery(predicate: "objectCol.arrayOptFloat.@sum > %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.sum > Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@sum < %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.sum < Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@sum == %@", values: [Float(7.55444333)], expectedCount: 0) {
            $0.objectCol.arrayOptFloat.sum == Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@sum == %@", values: [sumarrayOptFloat], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.sum == sumarrayOptFloat
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@sum >= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.sum >= Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@sum >= %@", values: [sumarrayOptFloat], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.sum >= sumarrayOptFloat
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@sum <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.sum <= Float(7.55444333)
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@sum <= %@", values: [sumarrayOptFloat], expectedCount: 2) {
            $0.objectCol.arrayOptFloat.sum <= sumarrayOptFloat
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptFloat.@sum != %@", values: [sumarrayOptFloat], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.sum != sumarrayOptFloat
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@sum != %@", values: [Float(5.55444333)], expectedCount: 2) {
            $0.objectCol.arrayOptFloat.sum != Float(5.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDouble": [123.456, 234.567, 345.678]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayOptDouble = 123.456 + 234.567 + 345.678
        assertQuery(predicate: "objectCol.arrayOptDouble.@sum > %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.sum > 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@sum < %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.sum < 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@sum == %@", values: [345.678], expectedCount: 0) {
            $0.objectCol.arrayOptDouble.sum == 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@sum == %@", values: [sumarrayOptDouble], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.sum == sumarrayOptDouble
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@sum >= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.sum >= 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@sum >= %@", values: [sumarrayOptDouble], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.sum >= sumarrayOptDouble
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@sum <= %@", values: [345.678], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.sum <= 345.678
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@sum <= %@", values: [sumarrayOptDouble], expectedCount: 2) {
            $0.objectCol.arrayOptDouble.sum <= sumarrayOptDouble
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptDouble.@sum != %@", values: [sumarrayOptDouble], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.sum != sumarrayOptDouble
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@sum != %@", values: [123.456], expectedCount: 2) {
            $0.objectCol.arrayOptDouble.sum != 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDecimal": [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        let sumarrayOptDecimal = Decimal128(123.456) + Decimal128(234.567) + Decimal128(345.678)
        assertQuery(predicate: "objectCol.arrayOptDecimal.@sum > %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.sum > Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@sum < %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.sum < Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@sum == %@", values: [Decimal128(345.678)], expectedCount: 0) {
            $0.objectCol.arrayOptDecimal.sum == Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@sum == %@", values: [sumarrayOptDecimal], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.sum == sumarrayOptDecimal
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@sum >= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.sum >= Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@sum >= %@", values: [sumarrayOptDecimal], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.sum >= sumarrayOptDecimal
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@sum <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.sum <= Decimal128(345.678)
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@sum <= %@", values: [sumarrayOptDecimal], expectedCount: 2) {
            $0.objectCol.arrayOptDecimal.sum <= sumarrayOptDecimal
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptDecimal.@sum != %@", values: [sumarrayOptDecimal], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.sum != sumarrayOptDecimal
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@sum != %@", values: [Decimal128(123.456)], expectedCount: 2) {
            $0.objectCol.arrayOptDecimal.sum != Decimal128(123.456)
        }
    }

    func testCollectionAggregatesCount() {
        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt": [1, 2, 3]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayInt.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt.count > 2
        }

        assertQuery(predicate: "objectCol.arrayInt.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.count < 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.count == 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayInt.count == 0
        }

        assertQuery(predicate: "objectCol.arrayInt.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayInt.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayInt.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayInt.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayInt.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt.count != 3
        }

        assertQuery(predicate: "objectCol.arrayInt.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayInt.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt8": [Int8(8), Int8(9), Int8(10)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayInt8.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt8.count > 2
        }

        assertQuery(predicate: "objectCol.arrayInt8.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt8.count < 3
        }

        assertQuery(predicate: "objectCol.arrayInt8.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt8.count == 3
        }

        assertQuery(predicate: "objectCol.arrayInt8.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayInt8.count == 0
        }

        assertQuery(predicate: "objectCol.arrayInt8.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayInt8.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayInt8.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt8.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayInt8.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt8.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayInt8.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayInt8.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt8.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt8.count != 3
        }

        assertQuery(predicate: "objectCol.arrayInt8.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayInt8.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt16": [Int16(16), Int16(17), Int16(18)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayInt16.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt16.count > 2
        }

        assertQuery(predicate: "objectCol.arrayInt16.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt16.count < 3
        }

        assertQuery(predicate: "objectCol.arrayInt16.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt16.count == 3
        }

        assertQuery(predicate: "objectCol.arrayInt16.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayInt16.count == 0
        }

        assertQuery(predicate: "objectCol.arrayInt16.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayInt16.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayInt16.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt16.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayInt16.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt16.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayInt16.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayInt16.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt16.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt16.count != 3
        }

        assertQuery(predicate: "objectCol.arrayInt16.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayInt16.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt32": [Int32(32), Int32(33), Int32(34)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayInt32.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt32.count > 2
        }

        assertQuery(predicate: "objectCol.arrayInt32.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt32.count < 3
        }

        assertQuery(predicate: "objectCol.arrayInt32.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt32.count == 3
        }

        assertQuery(predicate: "objectCol.arrayInt32.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayInt32.count == 0
        }

        assertQuery(predicate: "objectCol.arrayInt32.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayInt32.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayInt32.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt32.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayInt32.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt32.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayInt32.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayInt32.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt32.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt32.count != 3
        }

        assertQuery(predicate: "objectCol.arrayInt32.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayInt32.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayInt64": [Int64(64), Int64(65), Int64(66)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayInt64.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt64.count > 2
        }

        assertQuery(predicate: "objectCol.arrayInt64.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt64.count < 3
        }

        assertQuery(predicate: "objectCol.arrayInt64.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt64.count == 3
        }

        assertQuery(predicate: "objectCol.arrayInt64.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayInt64.count == 0
        }

        assertQuery(predicate: "objectCol.arrayInt64.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayInt64.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayInt64.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt64.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayInt64.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayInt64.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayInt64.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayInt64.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayInt64.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayInt64.count != 3
        }

        assertQuery(predicate: "objectCol.arrayInt64.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayInt64.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayFloat": [Float(5.55444333), Float(6.55444333), Float(7.55444333)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayFloat.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayFloat.count > 2
        }

        assertQuery(predicate: "objectCol.arrayFloat.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayFloat.count < 3
        }

        assertQuery(predicate: "objectCol.arrayFloat.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayFloat.count == 3
        }

        assertQuery(predicate: "objectCol.arrayFloat.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayFloat.count == 0
        }

        assertQuery(predicate: "objectCol.arrayFloat.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayFloat.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayFloat.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayFloat.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayFloat.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayFloat.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayFloat.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayFloat.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayFloat.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayFloat.count != 3
        }

        assertQuery(predicate: "objectCol.arrayFloat.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayFloat.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDouble": [123.456, 234.567, 345.678]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayDouble.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayDouble.count > 2
        }

        assertQuery(predicate: "objectCol.arrayDouble.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDouble.count < 3
        }

        assertQuery(predicate: "objectCol.arrayDouble.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDouble.count == 3
        }

        assertQuery(predicate: "objectCol.arrayDouble.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayDouble.count == 0
        }

        assertQuery(predicate: "objectCol.arrayDouble.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayDouble.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayDouble.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDouble.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayDouble.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayDouble.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayDouble.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayDouble.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayDouble.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDouble.count != 3
        }

        assertQuery(predicate: "objectCol.arrayDouble.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayDouble.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDate": [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000), Date(timeIntervalSince1970: 3000000)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayDate.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayDate.count > 2
        }

        assertQuery(predicate: "objectCol.arrayDate.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDate.count < 3
        }

        assertQuery(predicate: "objectCol.arrayDate.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDate.count == 3
        }

        assertQuery(predicate: "objectCol.arrayDate.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayDate.count == 0
        }

        assertQuery(predicate: "objectCol.arrayDate.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayDate.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayDate.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDate.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayDate.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayDate.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayDate.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayDate.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayDate.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDate.count != 3
        }

        assertQuery(predicate: "objectCol.arrayDate.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayDate.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayDecimal": [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayDecimal.count > 2
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDecimal.count < 3
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDecimal.count == 3
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayDecimal.count == 0
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayDecimal.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDecimal.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayDecimal.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayDecimal.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayDecimal.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayDecimal.count != 3
        }

        assertQuery(predicate: "objectCol.arrayDecimal.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayDecimal.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt": [1, 2, 3]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt.count > 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.count < 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.count == 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayOptInt.count == 0
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayOptInt.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayOptInt.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt.count != 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptInt.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt8": [Int8(8), Int8(9), Int8(10)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.count > 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.count < 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.count == 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.count == 0
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayOptInt8.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayOptInt8.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt8.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt8.count != 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt8.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptInt8.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt16": [Int16(16), Int16(17), Int16(18)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.count > 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.count < 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.count == 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.count == 0
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayOptInt16.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayOptInt16.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt16.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt16.count != 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt16.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptInt16.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt32": [Int32(32), Int32(33), Int32(34)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.count > 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.count < 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.count == 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.count == 0
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayOptInt32.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayOptInt32.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt32.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt32.count != 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt32.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptInt32.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptInt64": [Int64(64), Int64(65), Int64(66)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.count > 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.count < 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.count == 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.count == 0
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayOptInt64.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayOptInt64.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptInt64.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptInt64.count != 3
        }

        assertQuery(predicate: "objectCol.arrayOptInt64.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptInt64.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptFloat": [Float(5.55444333), Float(6.55444333), Float(7.55444333)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.count > 2
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.count < 3
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.count == 3
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.count == 0
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayOptFloat.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayOptFloat.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptFloat.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptFloat.count != 3
        }

        assertQuery(predicate: "objectCol.arrayOptFloat.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptFloat.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDouble": [123.456, 234.567, 345.678]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.count > 2
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.count < 3
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.count == 3
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.count == 0
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayOptDouble.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayOptDouble.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptDouble.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDouble.count != 3
        }

        assertQuery(predicate: "objectCol.arrayOptDouble.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptDouble.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDate": [Date(timeIntervalSince1970: 1000000), Date(timeIntervalSince1970: 2000000), Date(timeIntervalSince1970: 3000000)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptDate.count > 2
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDate.count < 3
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDate.count == 3
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayOptDate.count == 0
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayOptDate.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDate.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptDate.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayOptDate.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptDate.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDate.count != 3
        }

        assertQuery(predicate: "objectCol.arrayOptDate.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptDate.count != 1
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["arrayOptDecimal": [Decimal128(123.456), Decimal128(234.567), Decimal128(345.678)]])
            if let oldObject = object.objectCol {
                realm.delete(oldObject)
            }
            object.objectCol = modernObj
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@count > %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.count > 2
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@count < %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.count < 3
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@count == %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.count == 3
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@count == %@", values: [0], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.count == 0
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@count >= %@", values: [4], expectedCount: 0) {
            $0.objectCol.arrayOptDecimal.count >= 4
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@count >= %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.count >= 3
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@count <= %@", values: [2], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.count <= 2
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@count <= %@", values: [3], expectedCount: 2) {
            $0.objectCol.arrayOptDecimal.count <= 3
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "objectCol.arrayOptDecimal.@count != %@", values: [3], expectedCount: 1) {
            $0.objectCol.arrayOptDecimal.count != 3
        }

        assertQuery(predicate: "objectCol.arrayOptDecimal.@count != %@", values: [1], expectedCount: 2) {
            $0.objectCol.arrayOptDecimal.count != 1
        }
    }

    // MARK: Keypath Collection Aggregations

    func testKeypathCollectionAggregatesAvg() {
        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["intCol": 5])
            let modernObj1 = ModernAllTypesObject(value: ["intCol": 6])
            let modernObj2 = ModernAllTypesObject(value: ["intCol": 7])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.intCol > %@", values: [5], expectedCount: 1) {
            $0.arrayCol.intCol.avg > 5
        }

        assertQuery(predicate: "arrayCol.@avg.intCol < %@", values: [7], expectedCount: 1) {
            $0.arrayCol.intCol.avg < 7
        }

        assertQuery(predicate: "arrayCol.@avg.intCol == %@", values: [6], expectedCount: 1) {
            $0.arrayCol.intCol.avg == 6
        }

        assertQuery(predicate: "arrayCol.@avg.intCol >= %@", values: [5], expectedCount: 1) {
            $0.arrayCol.intCol.avg >= 5
        }

        assertQuery(predicate: "arrayCol.@avg.intCol >= %@", values: [6], expectedCount: 1) {
            $0.arrayCol.intCol.avg >= 6
        }

        assertQuery(predicate: "arrayCol.@avg.intCol <= %@", values: [7], expectedCount: 1) {
            $0.arrayCol.intCol.avg <= 7
        }

        assertQuery(predicate: "arrayCol.@avg.intCol <= %@", values: [6], expectedCount: 1) {
            $0.arrayCol.intCol.avg <= 6
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.intCol != %@", values: [6], expectedCount: 3) {
            $0.arrayCol.intCol.avg != 6
        }

        assertQuery(predicate: "arrayCol.@avg.intCol != %@", values: [5], expectedCount: 4) {
            $0.arrayCol.intCol.avg != 5
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int8Col": Int8(8)])
            let modernObj1 = ModernAllTypesObject(value: ["int8Col": Int8(9)])
            let modernObj2 = ModernAllTypesObject(value: ["int8Col": Int8(10)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.int8Col > %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.int8Col.avg > Int8(8)
        }

        assertQuery(predicate: "arrayCol.@avg.int8Col < %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.int8Col.avg < Int8(10)
        }

        assertQuery(predicate: "arrayCol.@avg.int8Col == %@", values: [Int8(9)], expectedCount: 1) {
            $0.arrayCol.int8Col.avg == Int8(9)
        }

        assertQuery(predicate: "arrayCol.@avg.int8Col >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.int8Col.avg >= Int8(8)
        }

        assertQuery(predicate: "arrayCol.@avg.int8Col >= %@", values: [Int8(9)], expectedCount: 1) {
            $0.arrayCol.int8Col.avg >= Int8(9)
        }

        assertQuery(predicate: "arrayCol.@avg.int8Col <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.int8Col.avg <= Int8(10)
        }

        assertQuery(predicate: "arrayCol.@avg.int8Col <= %@", values: [Int8(9)], expectedCount: 1) {
            $0.arrayCol.int8Col.avg <= Int8(9)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.int8Col != %@", values: [Int8(9)], expectedCount: 3) {
            $0.arrayCol.int8Col.avg != Int8(9)
        }

        assertQuery(predicate: "arrayCol.@avg.int8Col != %@", values: [Int8(8)], expectedCount: 4) {
            $0.arrayCol.int8Col.avg != Int8(8)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int16Col": Int16(16)])
            let modernObj1 = ModernAllTypesObject(value: ["int16Col": Int16(17)])
            let modernObj2 = ModernAllTypesObject(value: ["int16Col": Int16(18)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.int16Col > %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.int16Col.avg > Int16(16)
        }

        assertQuery(predicate: "arrayCol.@avg.int16Col < %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.int16Col.avg < Int16(18)
        }

        assertQuery(predicate: "arrayCol.@avg.int16Col == %@", values: [Int16(17)], expectedCount: 1) {
            $0.arrayCol.int16Col.avg == Int16(17)
        }

        assertQuery(predicate: "arrayCol.@avg.int16Col >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.int16Col.avg >= Int16(16)
        }

        assertQuery(predicate: "arrayCol.@avg.int16Col >= %@", values: [Int16(17)], expectedCount: 1) {
            $0.arrayCol.int16Col.avg >= Int16(17)
        }

        assertQuery(predicate: "arrayCol.@avg.int16Col <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.int16Col.avg <= Int16(18)
        }

        assertQuery(predicate: "arrayCol.@avg.int16Col <= %@", values: [Int16(17)], expectedCount: 1) {
            $0.arrayCol.int16Col.avg <= Int16(17)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.int16Col != %@", values: [Int16(17)], expectedCount: 3) {
            $0.arrayCol.int16Col.avg != Int16(17)
        }

        assertQuery(predicate: "arrayCol.@avg.int16Col != %@", values: [Int16(16)], expectedCount: 4) {
            $0.arrayCol.int16Col.avg != Int16(16)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int32Col": Int32(32)])
            let modernObj1 = ModernAllTypesObject(value: ["int32Col": Int32(33)])
            let modernObj2 = ModernAllTypesObject(value: ["int32Col": Int32(34)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.int32Col > %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.int32Col.avg > Int32(32)
        }

        assertQuery(predicate: "arrayCol.@avg.int32Col < %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.int32Col.avg < Int32(34)
        }

        assertQuery(predicate: "arrayCol.@avg.int32Col == %@", values: [Int32(33)], expectedCount: 1) {
            $0.arrayCol.int32Col.avg == Int32(33)
        }

        assertQuery(predicate: "arrayCol.@avg.int32Col >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.int32Col.avg >= Int32(32)
        }

        assertQuery(predicate: "arrayCol.@avg.int32Col >= %@", values: [Int32(33)], expectedCount: 1) {
            $0.arrayCol.int32Col.avg >= Int32(33)
        }

        assertQuery(predicate: "arrayCol.@avg.int32Col <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.int32Col.avg <= Int32(34)
        }

        assertQuery(predicate: "arrayCol.@avg.int32Col <= %@", values: [Int32(33)], expectedCount: 1) {
            $0.arrayCol.int32Col.avg <= Int32(33)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.int32Col != %@", values: [Int32(33)], expectedCount: 3) {
            $0.arrayCol.int32Col.avg != Int32(33)
        }

        assertQuery(predicate: "arrayCol.@avg.int32Col != %@", values: [Int32(32)], expectedCount: 4) {
            $0.arrayCol.int32Col.avg != Int32(32)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int64Col": Int64(64)])
            let modernObj1 = ModernAllTypesObject(value: ["int64Col": Int64(65)])
            let modernObj2 = ModernAllTypesObject(value: ["int64Col": Int64(66)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.int64Col > %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.int64Col.avg > Int64(64)
        }

        assertQuery(predicate: "arrayCol.@avg.int64Col < %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.int64Col.avg < Int64(66)
        }

        assertQuery(predicate: "arrayCol.@avg.int64Col == %@", values: [Int64(65)], expectedCount: 1) {
            $0.arrayCol.int64Col.avg == Int64(65)
        }

        assertQuery(predicate: "arrayCol.@avg.int64Col >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.int64Col.avg >= Int64(64)
        }

        assertQuery(predicate: "arrayCol.@avg.int64Col >= %@", values: [Int64(65)], expectedCount: 1) {
            $0.arrayCol.int64Col.avg >= Int64(65)
        }

        assertQuery(predicate: "arrayCol.@avg.int64Col <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.int64Col.avg <= Int64(66)
        }

        assertQuery(predicate: "arrayCol.@avg.int64Col <= %@", values: [Int64(65)], expectedCount: 1) {
            $0.arrayCol.int64Col.avg <= Int64(65)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.int64Col != %@", values: [Int64(65)], expectedCount: 3) {
            $0.arrayCol.int64Col.avg != Int64(65)
        }

        assertQuery(predicate: "arrayCol.@avg.int64Col != %@", values: [Int64(64)], expectedCount: 4) {
            $0.arrayCol.int64Col.avg != Int64(64)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["floatCol": Float(5.55444333)])
            let modernObj1 = ModernAllTypesObject(value: ["floatCol": Float(6.55444333)])
            let modernObj2 = ModernAllTypesObject(value: ["floatCol": Float(7.55444333)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.floatCol > %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.avg > Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.floatCol < %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.avg < Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.floatCol == %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.avg == Float(6.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.floatCol >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.avg >= Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.floatCol >= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.avg >= Float(6.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.floatCol <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.avg <= Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.floatCol <= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.avg <= Float(6.55444333)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.floatCol != %@", values: [Float(6.55444333)], expectedCount: 3) {
            $0.arrayCol.floatCol.avg != Float(6.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.floatCol != %@", values: [Float(5.55444333)], expectedCount: 4) {
            $0.arrayCol.floatCol.avg != Float(5.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["doubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["doubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["doubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.doubleCol > %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.doubleCol.avg > 123.456
        }

        assertQuery(predicate: "arrayCol.@avg.doubleCol < %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.doubleCol.avg < 345.678
        }

        assertQuery(predicate: "arrayCol.@avg.doubleCol == %@", values: [234.567], expectedCount: 1) {
            $0.arrayCol.doubleCol.avg == 234.567
        }

        assertQuery(predicate: "arrayCol.@avg.doubleCol >= %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.doubleCol.avg >= 123.456
        }

        assertQuery(predicate: "arrayCol.@avg.doubleCol >= %@", values: [234.567], expectedCount: 1) {
            $0.arrayCol.doubleCol.avg >= 234.567
        }

        assertQuery(predicate: "arrayCol.@avg.doubleCol <= %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.doubleCol.avg <= 345.678
        }

        assertQuery(predicate: "arrayCol.@avg.doubleCol <= %@", values: [234.567], expectedCount: 1) {
            $0.arrayCol.doubleCol.avg <= 234.567
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.doubleCol != %@", values: [234.567], expectedCount: 3) {
            $0.arrayCol.doubleCol.avg != 234.567
        }

        assertQuery(predicate: "arrayCol.@avg.doubleCol != %@", values: [123.456], expectedCount: 4) {
            $0.arrayCol.doubleCol.avg != 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["decimalCol": Decimal128(123.456)])
            let modernObj1 = ModernAllTypesObject(value: ["decimalCol": Decimal128(234.567)])
            let modernObj2 = ModernAllTypesObject(value: ["decimalCol": Decimal128(345.678)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.decimalCol > %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.decimalCol.avg > Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@avg.decimalCol < %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.decimalCol.avg < Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@avg.decimalCol == %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.arrayCol.decimalCol.avg == Decimal128(234.567)
        }

        assertQuery(predicate: "arrayCol.@avg.decimalCol >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.decimalCol.avg >= Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@avg.decimalCol >= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.arrayCol.decimalCol.avg >= Decimal128(234.567)
        }

        assertQuery(predicate: "arrayCol.@avg.decimalCol <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.decimalCol.avg <= Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@avg.decimalCol <= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.arrayCol.decimalCol.avg <= Decimal128(234.567)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.decimalCol != %@", values: [Decimal128(234.567)], expectedCount: 3) {
            $0.arrayCol.decimalCol.avg != Decimal128(234.567)
        }

        assertQuery(predicate: "arrayCol.@avg.decimalCol != %@", values: [Decimal128(123.456)], expectedCount: 4) {
            $0.arrayCol.decimalCol.avg != Decimal128(123.456)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optIntCol": 5])
            let modernObj1 = ModernAllTypesObject(value: ["optIntCol": 6])
            let modernObj2 = ModernAllTypesObject(value: ["optIntCol": 7])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.optIntCol > %@", values: [5], expectedCount: 1) {
            $0.arrayCol.optIntCol.avg > 5
        }

        assertQuery(predicate: "arrayCol.@avg.optIntCol < %@", values: [7], expectedCount: 1) {
            $0.arrayCol.optIntCol.avg < 7
        }

        assertQuery(predicate: "arrayCol.@avg.optIntCol == %@", values: [6], expectedCount: 1) {
            $0.arrayCol.optIntCol.avg == 6
        }

        assertQuery(predicate: "arrayCol.@avg.optIntCol >= %@", values: [5], expectedCount: 1) {
            $0.arrayCol.optIntCol.avg >= 5
        }

        assertQuery(predicate: "arrayCol.@avg.optIntCol >= %@", values: [6], expectedCount: 1) {
            $0.arrayCol.optIntCol.avg >= 6
        }

        assertQuery(predicate: "arrayCol.@avg.optIntCol <= %@", values: [7], expectedCount: 1) {
            $0.arrayCol.optIntCol.avg <= 7
        }

        assertQuery(predicate: "arrayCol.@avg.optIntCol <= %@", values: [6], expectedCount: 1) {
            $0.arrayCol.optIntCol.avg <= 6
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.optIntCol != %@", values: [6], expectedCount: 3) {
            $0.arrayCol.optIntCol.avg != 6
        }

        assertQuery(predicate: "arrayCol.@avg.optIntCol != %@", values: [5], expectedCount: 4) {
            $0.arrayCol.optIntCol.avg != 5
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt8Col": Int8(8)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt8Col": Int8(9)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt8Col": Int8(10)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.optInt8Col > %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.avg > Int8(8)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt8Col < %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.avg < Int8(10)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt8Col == %@", values: [Int8(9)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.avg == Int8(9)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt8Col >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.avg >= Int8(8)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt8Col >= %@", values: [Int8(9)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.avg >= Int8(9)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt8Col <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.avg <= Int8(10)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt8Col <= %@", values: [Int8(9)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.avg <= Int8(9)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.optInt8Col != %@", values: [Int8(9)], expectedCount: 3) {
            $0.arrayCol.optInt8Col.avg != Int8(9)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt8Col != %@", values: [Int8(8)], expectedCount: 4) {
            $0.arrayCol.optInt8Col.avg != Int8(8)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt16Col": Int16(16)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt16Col": Int16(17)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt16Col": Int16(18)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.optInt16Col > %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.avg > Int16(16)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt16Col < %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.avg < Int16(18)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt16Col == %@", values: [Int16(17)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.avg == Int16(17)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt16Col >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.avg >= Int16(16)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt16Col >= %@", values: [Int16(17)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.avg >= Int16(17)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt16Col <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.avg <= Int16(18)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt16Col <= %@", values: [Int16(17)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.avg <= Int16(17)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.optInt16Col != %@", values: [Int16(17)], expectedCount: 3) {
            $0.arrayCol.optInt16Col.avg != Int16(17)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt16Col != %@", values: [Int16(16)], expectedCount: 4) {
            $0.arrayCol.optInt16Col.avg != Int16(16)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt32Col": Int32(32)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt32Col": Int32(33)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt32Col": Int32(34)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.optInt32Col > %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.avg > Int32(32)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt32Col < %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.avg < Int32(34)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt32Col == %@", values: [Int32(33)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.avg == Int32(33)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt32Col >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.avg >= Int32(32)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt32Col >= %@", values: [Int32(33)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.avg >= Int32(33)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt32Col <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.avg <= Int32(34)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt32Col <= %@", values: [Int32(33)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.avg <= Int32(33)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.optInt32Col != %@", values: [Int32(33)], expectedCount: 3) {
            $0.arrayCol.optInt32Col.avg != Int32(33)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt32Col != %@", values: [Int32(32)], expectedCount: 4) {
            $0.arrayCol.optInt32Col.avg != Int32(32)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt64Col": Int64(64)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt64Col": Int64(65)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt64Col": Int64(66)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.optInt64Col > %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.avg > Int64(64)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt64Col < %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.avg < Int64(66)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt64Col == %@", values: [Int64(65)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.avg == Int64(65)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt64Col >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.avg >= Int64(64)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt64Col >= %@", values: [Int64(65)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.avg >= Int64(65)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt64Col <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.avg <= Int64(66)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt64Col <= %@", values: [Int64(65)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.avg <= Int64(65)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.optInt64Col != %@", values: [Int64(65)], expectedCount: 3) {
            $0.arrayCol.optInt64Col.avg != Int64(65)
        }

        assertQuery(predicate: "arrayCol.@avg.optInt64Col != %@", values: [Int64(64)], expectedCount: 4) {
            $0.arrayCol.optInt64Col.avg != Int64(64)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optFloatCol": Float(5.55444333)])
            let modernObj1 = ModernAllTypesObject(value: ["optFloatCol": Float(6.55444333)])
            let modernObj2 = ModernAllTypesObject(value: ["optFloatCol": Float(7.55444333)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.optFloatCol > %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.avg > Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.optFloatCol < %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.avg < Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.optFloatCol == %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.avg == Float(6.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.optFloatCol >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.avg >= Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.optFloatCol >= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.avg >= Float(6.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.optFloatCol <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.avg <= Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.optFloatCol <= %@", values: [Float(6.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.avg <= Float(6.55444333)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.optFloatCol != %@", values: [Float(6.55444333)], expectedCount: 3) {
            $0.arrayCol.optFloatCol.avg != Float(6.55444333)
        }

        assertQuery(predicate: "arrayCol.@avg.optFloatCol != %@", values: [Float(5.55444333)], expectedCount: 4) {
            $0.arrayCol.optFloatCol.avg != Float(5.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDoubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["optDoubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["optDoubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.optDoubleCol > %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.avg > 123.456
        }

        assertQuery(predicate: "arrayCol.@avg.optDoubleCol < %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.avg < 345.678
        }

        assertQuery(predicate: "arrayCol.@avg.optDoubleCol == %@", values: [234.567], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.avg == 234.567
        }

        assertQuery(predicate: "arrayCol.@avg.optDoubleCol >= %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.avg >= 123.456
        }

        assertQuery(predicate: "arrayCol.@avg.optDoubleCol >= %@", values: [234.567], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.avg >= 234.567
        }

        assertQuery(predicate: "arrayCol.@avg.optDoubleCol <= %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.avg <= 345.678
        }

        assertQuery(predicate: "arrayCol.@avg.optDoubleCol <= %@", values: [234.567], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.avg <= 234.567
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.optDoubleCol != %@", values: [234.567], expectedCount: 3) {
            $0.arrayCol.optDoubleCol.avg != 234.567
        }

        assertQuery(predicate: "arrayCol.@avg.optDoubleCol != %@", values: [123.456], expectedCount: 4) {
            $0.arrayCol.optDoubleCol.avg != 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDecimalCol": Decimal128(123.456)])
            let modernObj1 = ModernAllTypesObject(value: ["optDecimalCol": Decimal128(234.567)])
            let modernObj2 = ModernAllTypesObject(value: ["optDecimalCol": Decimal128(345.678)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }

        assertQuery(predicate: "arrayCol.@avg.optDecimalCol > %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.avg > Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@avg.optDecimalCol < %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.avg < Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@avg.optDecimalCol == %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.avg == Decimal128(234.567)
        }

        assertQuery(predicate: "arrayCol.@avg.optDecimalCol >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.avg >= Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@avg.optDecimalCol >= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.avg >= Decimal128(234.567)
        }

        assertQuery(predicate: "arrayCol.@avg.optDecimalCol <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.avg <= Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@avg.optDecimalCol <= %@", values: [Decimal128(234.567)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.avg <= Decimal128(234.567)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@avg.optDecimalCol != %@", values: [Decimal128(234.567)], expectedCount: 3) {
            $0.arrayCol.optDecimalCol.avg != Decimal128(234.567)
        }

        assertQuery(predicate: "arrayCol.@avg.optDecimalCol != %@", values: [Decimal128(123.456)], expectedCount: 4) {
            $0.arrayCol.optDecimalCol.avg != Decimal128(123.456)
        }
    }

    func testKeypathCollectionAggregatesMin() {
        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["intCol": 5])
            let modernObj1 = ModernAllTypesObject(value: ["intCol": 6])
            let modernObj2 = ModernAllTypesObject(value: ["intCol": 7])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.intCol > %@", values: [5], expectedCount: 0) {
            $0.arrayCol.intCol.min > 5
        }

        assertQuery(predicate: "arrayCol.@min.intCol < %@", values: [7], expectedCount: 1) {
            $0.arrayCol.intCol.min < 7
        }

        assertQuery(predicate: "arrayCol.@min.intCol == %@", values: [5], expectedCount: 1) {
            $0.arrayCol.intCol.min == 5
        }

        assertQuery(predicate: "arrayCol.@min.intCol >= %@", values: [6], expectedCount: 0) {
            $0.arrayCol.intCol.min >= 6
        }

        assertQuery(predicate: "arrayCol.@min.intCol >= %@", values: [5], expectedCount: 1) {
            $0.arrayCol.intCol.min >= 5
        }

        assertQuery(predicate: "arrayCol.@min.intCol <= %@", values: [7], expectedCount: 1) {
            $0.arrayCol.intCol.min <= 7
        }

        assertQuery(predicate: "arrayCol.@min.intCol <= %@", values: [5], expectedCount: 1) {
            $0.arrayCol.intCol.min <= 5
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.intCol != %@", values: [5], expectedCount: 3) {
            $0.arrayCol.intCol.min != 5
        }

        assertQuery(predicate: "arrayCol.@min.intCol != %@", values: [7], expectedCount: 4) {
            $0.arrayCol.intCol.min != 7
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int8Col": Int8(8)])
            let modernObj1 = ModernAllTypesObject(value: ["int8Col": Int8(9)])
            let modernObj2 = ModernAllTypesObject(value: ["int8Col": Int8(10)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.int8Col > %@", values: [Int8(8)], expectedCount: 0) {
            $0.arrayCol.int8Col.min > Int8(8)
        }

        assertQuery(predicate: "arrayCol.@min.int8Col < %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.int8Col.min < Int8(10)
        }

        assertQuery(predicate: "arrayCol.@min.int8Col == %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.int8Col.min == Int8(8)
        }

        assertQuery(predicate: "arrayCol.@min.int8Col >= %@", values: [Int8(9)], expectedCount: 0) {
            $0.arrayCol.int8Col.min >= Int8(9)
        }

        assertQuery(predicate: "arrayCol.@min.int8Col >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.int8Col.min >= Int8(8)
        }

        assertQuery(predicate: "arrayCol.@min.int8Col <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.int8Col.min <= Int8(10)
        }

        assertQuery(predicate: "arrayCol.@min.int8Col <= %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.int8Col.min <= Int8(8)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.int8Col != %@", values: [Int8(8)], expectedCount: 3) {
            $0.arrayCol.int8Col.min != Int8(8)
        }

        assertQuery(predicate: "arrayCol.@min.int8Col != %@", values: [Int8(10)], expectedCount: 4) {
            $0.arrayCol.int8Col.min != Int8(10)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int16Col": Int16(16)])
            let modernObj1 = ModernAllTypesObject(value: ["int16Col": Int16(17)])
            let modernObj2 = ModernAllTypesObject(value: ["int16Col": Int16(18)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.int16Col > %@", values: [Int16(16)], expectedCount: 0) {
            $0.arrayCol.int16Col.min > Int16(16)
        }

        assertQuery(predicate: "arrayCol.@min.int16Col < %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.int16Col.min < Int16(18)
        }

        assertQuery(predicate: "arrayCol.@min.int16Col == %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.int16Col.min == Int16(16)
        }

        assertQuery(predicate: "arrayCol.@min.int16Col >= %@", values: [Int16(17)], expectedCount: 0) {
            $0.arrayCol.int16Col.min >= Int16(17)
        }

        assertQuery(predicate: "arrayCol.@min.int16Col >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.int16Col.min >= Int16(16)
        }

        assertQuery(predicate: "arrayCol.@min.int16Col <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.int16Col.min <= Int16(18)
        }

        assertQuery(predicate: "arrayCol.@min.int16Col <= %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.int16Col.min <= Int16(16)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.int16Col != %@", values: [Int16(16)], expectedCount: 3) {
            $0.arrayCol.int16Col.min != Int16(16)
        }

        assertQuery(predicate: "arrayCol.@min.int16Col != %@", values: [Int16(18)], expectedCount: 4) {
            $0.arrayCol.int16Col.min != Int16(18)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int32Col": Int32(32)])
            let modernObj1 = ModernAllTypesObject(value: ["int32Col": Int32(33)])
            let modernObj2 = ModernAllTypesObject(value: ["int32Col": Int32(34)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.int32Col > %@", values: [Int32(32)], expectedCount: 0) {
            $0.arrayCol.int32Col.min > Int32(32)
        }

        assertQuery(predicate: "arrayCol.@min.int32Col < %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.int32Col.min < Int32(34)
        }

        assertQuery(predicate: "arrayCol.@min.int32Col == %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.int32Col.min == Int32(32)
        }

        assertQuery(predicate: "arrayCol.@min.int32Col >= %@", values: [Int32(33)], expectedCount: 0) {
            $0.arrayCol.int32Col.min >= Int32(33)
        }

        assertQuery(predicate: "arrayCol.@min.int32Col >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.int32Col.min >= Int32(32)
        }

        assertQuery(predicate: "arrayCol.@min.int32Col <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.int32Col.min <= Int32(34)
        }

        assertQuery(predicate: "arrayCol.@min.int32Col <= %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.int32Col.min <= Int32(32)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.int32Col != %@", values: [Int32(32)], expectedCount: 3) {
            $0.arrayCol.int32Col.min != Int32(32)
        }

        assertQuery(predicate: "arrayCol.@min.int32Col != %@", values: [Int32(34)], expectedCount: 4) {
            $0.arrayCol.int32Col.min != Int32(34)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int64Col": Int64(64)])
            let modernObj1 = ModernAllTypesObject(value: ["int64Col": Int64(65)])
            let modernObj2 = ModernAllTypesObject(value: ["int64Col": Int64(66)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.int64Col > %@", values: [Int64(64)], expectedCount: 0) {
            $0.arrayCol.int64Col.min > Int64(64)
        }

        assertQuery(predicate: "arrayCol.@min.int64Col < %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.int64Col.min < Int64(66)
        }

        assertQuery(predicate: "arrayCol.@min.int64Col == %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.int64Col.min == Int64(64)
        }

        assertQuery(predicate: "arrayCol.@min.int64Col >= %@", values: [Int64(65)], expectedCount: 0) {
            $0.arrayCol.int64Col.min >= Int64(65)
        }

        assertQuery(predicate: "arrayCol.@min.int64Col >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.int64Col.min >= Int64(64)
        }

        assertQuery(predicate: "arrayCol.@min.int64Col <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.int64Col.min <= Int64(66)
        }

        assertQuery(predicate: "arrayCol.@min.int64Col <= %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.int64Col.min <= Int64(64)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.int64Col != %@", values: [Int64(64)], expectedCount: 3) {
            $0.arrayCol.int64Col.min != Int64(64)
        }

        assertQuery(predicate: "arrayCol.@min.int64Col != %@", values: [Int64(66)], expectedCount: 4) {
            $0.arrayCol.int64Col.min != Int64(66)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["floatCol": Float(5.55444333)])
            let modernObj1 = ModernAllTypesObject(value: ["floatCol": Float(6.55444333)])
            let modernObj2 = ModernAllTypesObject(value: ["floatCol": Float(7.55444333)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.floatCol > %@", values: [Float(5.55444333)], expectedCount: 0) {
            $0.arrayCol.floatCol.min > Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.floatCol < %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.min < Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.floatCol == %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.min == Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.floatCol >= %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.arrayCol.floatCol.min >= Float(6.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.floatCol >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.min >= Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.floatCol <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.min <= Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.floatCol <= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.min <= Float(5.55444333)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.floatCol != %@", values: [Float(5.55444333)], expectedCount: 3) {
            $0.arrayCol.floatCol.min != Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.floatCol != %@", values: [Float(7.55444333)], expectedCount: 4) {
            $0.arrayCol.floatCol.min != Float(7.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["doubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["doubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["doubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.doubleCol > %@", values: [123.456], expectedCount: 0) {
            $0.arrayCol.doubleCol.min > 123.456
        }

        assertQuery(predicate: "arrayCol.@min.doubleCol < %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.doubleCol.min < 345.678
        }

        assertQuery(predicate: "arrayCol.@min.doubleCol == %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.doubleCol.min == 123.456
        }

        assertQuery(predicate: "arrayCol.@min.doubleCol >= %@", values: [234.567], expectedCount: 0) {
            $0.arrayCol.doubleCol.min >= 234.567
        }

        assertQuery(predicate: "arrayCol.@min.doubleCol >= %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.doubleCol.min >= 123.456
        }

        assertQuery(predicate: "arrayCol.@min.doubleCol <= %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.doubleCol.min <= 345.678
        }

        assertQuery(predicate: "arrayCol.@min.doubleCol <= %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.doubleCol.min <= 123.456
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.doubleCol != %@", values: [123.456], expectedCount: 3) {
            $0.arrayCol.doubleCol.min != 123.456
        }

        assertQuery(predicate: "arrayCol.@min.doubleCol != %@", values: [345.678], expectedCount: 4) {
            $0.arrayCol.doubleCol.min != 345.678
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["dateCol": Date(timeIntervalSince1970: 1000000)])
            let modernObj1 = ModernAllTypesObject(value: ["dateCol": Date(timeIntervalSince1970: 2000000)])
            let modernObj2 = ModernAllTypesObject(value: ["dateCol": Date(timeIntervalSince1970: 3000000)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.dateCol > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.arrayCol.dateCol.min > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@min.dateCol < %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.arrayCol.dateCol.min < Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@min.dateCol == %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayCol.dateCol.min == Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@min.dateCol >= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.arrayCol.dateCol.min >= Date(timeIntervalSince1970: 2000000)
        }

        assertQuery(predicate: "arrayCol.@min.dateCol >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayCol.dateCol.min >= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@min.dateCol <= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.arrayCol.dateCol.min <= Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@min.dateCol <= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayCol.dateCol.min <= Date(timeIntervalSince1970: 1000000)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.dateCol != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 3) {
            $0.arrayCol.dateCol.min != Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@min.dateCol != %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 4) {
            $0.arrayCol.dateCol.min != Date(timeIntervalSince1970: 3000000)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["decimalCol": Decimal128(123.456)])
            let modernObj1 = ModernAllTypesObject(value: ["decimalCol": Decimal128(234.567)])
            let modernObj2 = ModernAllTypesObject(value: ["decimalCol": Decimal128(345.678)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.decimalCol > %@", values: [Decimal128(123.456)], expectedCount: 0) {
            $0.arrayCol.decimalCol.min > Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@min.decimalCol < %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.decimalCol.min < Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@min.decimalCol == %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.decimalCol.min == Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@min.decimalCol >= %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.arrayCol.decimalCol.min >= Decimal128(234.567)
        }

        assertQuery(predicate: "arrayCol.@min.decimalCol >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.decimalCol.min >= Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@min.decimalCol <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.decimalCol.min <= Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@min.decimalCol <= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.decimalCol.min <= Decimal128(123.456)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.decimalCol != %@", values: [Decimal128(123.456)], expectedCount: 3) {
            $0.arrayCol.decimalCol.min != Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@min.decimalCol != %@", values: [Decimal128(345.678)], expectedCount: 4) {
            $0.arrayCol.decimalCol.min != Decimal128(345.678)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optIntCol": 5])
            let modernObj1 = ModernAllTypesObject(value: ["optIntCol": 6])
            let modernObj2 = ModernAllTypesObject(value: ["optIntCol": 7])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.optIntCol > %@", values: [5], expectedCount: 0) {
            $0.arrayCol.optIntCol.min > 5
        }

        assertQuery(predicate: "arrayCol.@min.optIntCol < %@", values: [7], expectedCount: 1) {
            $0.arrayCol.optIntCol.min < 7
        }

        assertQuery(predicate: "arrayCol.@min.optIntCol == %@", values: [5], expectedCount: 1) {
            $0.arrayCol.optIntCol.min == 5
        }

        assertQuery(predicate: "arrayCol.@min.optIntCol >= %@", values: [6], expectedCount: 0) {
            $0.arrayCol.optIntCol.min >= 6
        }

        assertQuery(predicate: "arrayCol.@min.optIntCol >= %@", values: [5], expectedCount: 1) {
            $0.arrayCol.optIntCol.min >= 5
        }

        assertQuery(predicate: "arrayCol.@min.optIntCol <= %@", values: [7], expectedCount: 1) {
            $0.arrayCol.optIntCol.min <= 7
        }

        assertQuery(predicate: "arrayCol.@min.optIntCol <= %@", values: [5], expectedCount: 1) {
            $0.arrayCol.optIntCol.min <= 5
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.optIntCol != %@", values: [5], expectedCount: 3) {
            $0.arrayCol.optIntCol.min != 5
        }

        assertQuery(predicate: "arrayCol.@min.optIntCol != %@", values: [7], expectedCount: 4) {
            $0.arrayCol.optIntCol.min != 7
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt8Col": Int8(8)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt8Col": Int8(9)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt8Col": Int8(10)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.optInt8Col > %@", values: [Int8(8)], expectedCount: 0) {
            $0.arrayCol.optInt8Col.min > Int8(8)
        }

        assertQuery(predicate: "arrayCol.@min.optInt8Col < %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.min < Int8(10)
        }

        assertQuery(predicate: "arrayCol.@min.optInt8Col == %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.min == Int8(8)
        }

        assertQuery(predicate: "arrayCol.@min.optInt8Col >= %@", values: [Int8(9)], expectedCount: 0) {
            $0.arrayCol.optInt8Col.min >= Int8(9)
        }

        assertQuery(predicate: "arrayCol.@min.optInt8Col >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.min >= Int8(8)
        }

        assertQuery(predicate: "arrayCol.@min.optInt8Col <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.min <= Int8(10)
        }

        assertQuery(predicate: "arrayCol.@min.optInt8Col <= %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.min <= Int8(8)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.optInt8Col != %@", values: [Int8(8)], expectedCount: 3) {
            $0.arrayCol.optInt8Col.min != Int8(8)
        }

        assertQuery(predicate: "arrayCol.@min.optInt8Col != %@", values: [Int8(10)], expectedCount: 4) {
            $0.arrayCol.optInt8Col.min != Int8(10)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt16Col": Int16(16)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt16Col": Int16(17)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt16Col": Int16(18)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.optInt16Col > %@", values: [Int16(16)], expectedCount: 0) {
            $0.arrayCol.optInt16Col.min > Int16(16)
        }

        assertQuery(predicate: "arrayCol.@min.optInt16Col < %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.min < Int16(18)
        }

        assertQuery(predicate: "arrayCol.@min.optInt16Col == %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.min == Int16(16)
        }

        assertQuery(predicate: "arrayCol.@min.optInt16Col >= %@", values: [Int16(17)], expectedCount: 0) {
            $0.arrayCol.optInt16Col.min >= Int16(17)
        }

        assertQuery(predicate: "arrayCol.@min.optInt16Col >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.min >= Int16(16)
        }

        assertQuery(predicate: "arrayCol.@min.optInt16Col <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.min <= Int16(18)
        }

        assertQuery(predicate: "arrayCol.@min.optInt16Col <= %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.min <= Int16(16)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.optInt16Col != %@", values: [Int16(16)], expectedCount: 3) {
            $0.arrayCol.optInt16Col.min != Int16(16)
        }

        assertQuery(predicate: "arrayCol.@min.optInt16Col != %@", values: [Int16(18)], expectedCount: 4) {
            $0.arrayCol.optInt16Col.min != Int16(18)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt32Col": Int32(32)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt32Col": Int32(33)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt32Col": Int32(34)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.optInt32Col > %@", values: [Int32(32)], expectedCount: 0) {
            $0.arrayCol.optInt32Col.min > Int32(32)
        }

        assertQuery(predicate: "arrayCol.@min.optInt32Col < %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.min < Int32(34)
        }

        assertQuery(predicate: "arrayCol.@min.optInt32Col == %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.min == Int32(32)
        }

        assertQuery(predicate: "arrayCol.@min.optInt32Col >= %@", values: [Int32(33)], expectedCount: 0) {
            $0.arrayCol.optInt32Col.min >= Int32(33)
        }

        assertQuery(predicate: "arrayCol.@min.optInt32Col >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.min >= Int32(32)
        }

        assertQuery(predicate: "arrayCol.@min.optInt32Col <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.min <= Int32(34)
        }

        assertQuery(predicate: "arrayCol.@min.optInt32Col <= %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.min <= Int32(32)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.optInt32Col != %@", values: [Int32(32)], expectedCount: 3) {
            $0.arrayCol.optInt32Col.min != Int32(32)
        }

        assertQuery(predicate: "arrayCol.@min.optInt32Col != %@", values: [Int32(34)], expectedCount: 4) {
            $0.arrayCol.optInt32Col.min != Int32(34)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt64Col": Int64(64)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt64Col": Int64(65)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt64Col": Int64(66)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.optInt64Col > %@", values: [Int64(64)], expectedCount: 0) {
            $0.arrayCol.optInt64Col.min > Int64(64)
        }

        assertQuery(predicate: "arrayCol.@min.optInt64Col < %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.min < Int64(66)
        }

        assertQuery(predicate: "arrayCol.@min.optInt64Col == %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.min == Int64(64)
        }

        assertQuery(predicate: "arrayCol.@min.optInt64Col >= %@", values: [Int64(65)], expectedCount: 0) {
            $0.arrayCol.optInt64Col.min >= Int64(65)
        }

        assertQuery(predicate: "arrayCol.@min.optInt64Col >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.min >= Int64(64)
        }

        assertQuery(predicate: "arrayCol.@min.optInt64Col <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.min <= Int64(66)
        }

        assertQuery(predicate: "arrayCol.@min.optInt64Col <= %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.min <= Int64(64)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.optInt64Col != %@", values: [Int64(64)], expectedCount: 3) {
            $0.arrayCol.optInt64Col.min != Int64(64)
        }

        assertQuery(predicate: "arrayCol.@min.optInt64Col != %@", values: [Int64(66)], expectedCount: 4) {
            $0.arrayCol.optInt64Col.min != Int64(66)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optFloatCol": Float(5.55444333)])
            let modernObj1 = ModernAllTypesObject(value: ["optFloatCol": Float(6.55444333)])
            let modernObj2 = ModernAllTypesObject(value: ["optFloatCol": Float(7.55444333)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.optFloatCol > %@", values: [Float(5.55444333)], expectedCount: 0) {
            $0.arrayCol.optFloatCol.min > Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.optFloatCol < %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.min < Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.optFloatCol == %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.min == Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.optFloatCol >= %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.arrayCol.optFloatCol.min >= Float(6.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.optFloatCol >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.min >= Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.optFloatCol <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.min <= Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.optFloatCol <= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.min <= Float(5.55444333)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.optFloatCol != %@", values: [Float(5.55444333)], expectedCount: 3) {
            $0.arrayCol.optFloatCol.min != Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@min.optFloatCol != %@", values: [Float(7.55444333)], expectedCount: 4) {
            $0.arrayCol.optFloatCol.min != Float(7.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDoubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["optDoubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["optDoubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.optDoubleCol > %@", values: [123.456], expectedCount: 0) {
            $0.arrayCol.optDoubleCol.min > 123.456
        }

        assertQuery(predicate: "arrayCol.@min.optDoubleCol < %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.min < 345.678
        }

        assertQuery(predicate: "arrayCol.@min.optDoubleCol == %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.min == 123.456
        }

        assertQuery(predicate: "arrayCol.@min.optDoubleCol >= %@", values: [234.567], expectedCount: 0) {
            $0.arrayCol.optDoubleCol.min >= 234.567
        }

        assertQuery(predicate: "arrayCol.@min.optDoubleCol >= %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.min >= 123.456
        }

        assertQuery(predicate: "arrayCol.@min.optDoubleCol <= %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.min <= 345.678
        }

        assertQuery(predicate: "arrayCol.@min.optDoubleCol <= %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.min <= 123.456
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.optDoubleCol != %@", values: [123.456], expectedCount: 3) {
            $0.arrayCol.optDoubleCol.min != 123.456
        }

        assertQuery(predicate: "arrayCol.@min.optDoubleCol != %@", values: [345.678], expectedCount: 4) {
            $0.arrayCol.optDoubleCol.min != 345.678
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDateCol": Date(timeIntervalSince1970: 1000000)])
            let modernObj1 = ModernAllTypesObject(value: ["optDateCol": Date(timeIntervalSince1970: 2000000)])
            let modernObj2 = ModernAllTypesObject(value: ["optDateCol": Date(timeIntervalSince1970: 3000000)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.optDateCol > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 0) {
            $0.arrayCol.optDateCol.min > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@min.optDateCol < %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.arrayCol.optDateCol.min < Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@min.optDateCol == %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayCol.optDateCol.min == Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@min.optDateCol >= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.arrayCol.optDateCol.min >= Date(timeIntervalSince1970: 2000000)
        }

        assertQuery(predicate: "arrayCol.@min.optDateCol >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayCol.optDateCol.min >= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@min.optDateCol <= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.arrayCol.optDateCol.min <= Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@min.optDateCol <= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayCol.optDateCol.min <= Date(timeIntervalSince1970: 1000000)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.optDateCol != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 3) {
            $0.arrayCol.optDateCol.min != Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@min.optDateCol != %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 4) {
            $0.arrayCol.optDateCol.min != Date(timeIntervalSince1970: 3000000)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDecimalCol": Decimal128(123.456)])
            let modernObj1 = ModernAllTypesObject(value: ["optDecimalCol": Decimal128(234.567)])
            let modernObj2 = ModernAllTypesObject(value: ["optDecimalCol": Decimal128(345.678)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@min.optDecimalCol > %@", values: [Decimal128(123.456)], expectedCount: 0) {
            $0.arrayCol.optDecimalCol.min > Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@min.optDecimalCol < %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.min < Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@min.optDecimalCol == %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.min == Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@min.optDecimalCol >= %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.arrayCol.optDecimalCol.min >= Decimal128(234.567)
        }

        assertQuery(predicate: "arrayCol.@min.optDecimalCol >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.min >= Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@min.optDecimalCol <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.min <= Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@min.optDecimalCol <= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.min <= Decimal128(123.456)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@min.optDecimalCol != %@", values: [Decimal128(123.456)], expectedCount: 3) {
            $0.arrayCol.optDecimalCol.min != Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@min.optDecimalCol != %@", values: [Decimal128(345.678)], expectedCount: 4) {
            $0.arrayCol.optDecimalCol.min != Decimal128(345.678)
        }
    }

    func testKeypathCollectionAggregatesMax() {
        let realm = realmWithTestPath()
        let object = objects().first!

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["intCol": 5])
            let modernObj1 = ModernAllTypesObject(value: ["intCol": 6])
            let modernObj2 = ModernAllTypesObject(value: ["intCol": 7])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.intCol > %@", values: [5], expectedCount: 1) {
            $0.arrayCol.intCol.max > 5
        }

        assertQuery(predicate: "arrayCol.@max.intCol < %@", values: [7], expectedCount: 0) {
            $0.arrayCol.intCol.max < 7
        }

        assertQuery(predicate: "arrayCol.@max.intCol == %@", values: [7], expectedCount: 1) {
            $0.arrayCol.intCol.max == 7
        }

        assertQuery(predicate: "arrayCol.@max.intCol >= %@", values: [5], expectedCount: 1) {
            $0.arrayCol.intCol.max >= 5
        }

        assertQuery(predicate: "arrayCol.@max.intCol >= %@", values: [7], expectedCount: 1) {
            $0.arrayCol.intCol.max >= 7
        }

        assertQuery(predicate: "arrayCol.@max.intCol <= %@", values: [6], expectedCount: 0) {
            $0.arrayCol.intCol.max <= 6
        }

        assertQuery(predicate: "arrayCol.@max.intCol <= %@", values: [7], expectedCount: 1) {
            $0.arrayCol.intCol.max <= 7
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.intCol != %@", values: [7], expectedCount: 3) {
            $0.arrayCol.intCol.max != 7
        }

        assertQuery(predicate: "arrayCol.@max.intCol != %@", values: [5], expectedCount: 4) {
            $0.arrayCol.intCol.max != 5
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int8Col": Int8(8)])
            let modernObj1 = ModernAllTypesObject(value: ["int8Col": Int8(9)])
            let modernObj2 = ModernAllTypesObject(value: ["int8Col": Int8(10)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.int8Col > %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.int8Col.max > Int8(8)
        }

        assertQuery(predicate: "arrayCol.@max.int8Col < %@", values: [Int8(10)], expectedCount: 0) {
            $0.arrayCol.int8Col.max < Int8(10)
        }

        assertQuery(predicate: "arrayCol.@max.int8Col == %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.int8Col.max == Int8(10)
        }

        assertQuery(predicate: "arrayCol.@max.int8Col >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.int8Col.max >= Int8(8)
        }

        assertQuery(predicate: "arrayCol.@max.int8Col >= %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.int8Col.max >= Int8(10)
        }

        assertQuery(predicate: "arrayCol.@max.int8Col <= %@", values: [Int8(9)], expectedCount: 0) {
            $0.arrayCol.int8Col.max <= Int8(9)
        }

        assertQuery(predicate: "arrayCol.@max.int8Col <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.int8Col.max <= Int8(10)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.int8Col != %@", values: [Int8(10)], expectedCount: 3) {
            $0.arrayCol.int8Col.max != Int8(10)
        }

        assertQuery(predicate: "arrayCol.@max.int8Col != %@", values: [Int8(8)], expectedCount: 4) {
            $0.arrayCol.int8Col.max != Int8(8)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int16Col": Int16(16)])
            let modernObj1 = ModernAllTypesObject(value: ["int16Col": Int16(17)])
            let modernObj2 = ModernAllTypesObject(value: ["int16Col": Int16(18)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.int16Col > %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.int16Col.max > Int16(16)
        }

        assertQuery(predicate: "arrayCol.@max.int16Col < %@", values: [Int16(18)], expectedCount: 0) {
            $0.arrayCol.int16Col.max < Int16(18)
        }

        assertQuery(predicate: "arrayCol.@max.int16Col == %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.int16Col.max == Int16(18)
        }

        assertQuery(predicate: "arrayCol.@max.int16Col >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.int16Col.max >= Int16(16)
        }

        assertQuery(predicate: "arrayCol.@max.int16Col >= %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.int16Col.max >= Int16(18)
        }

        assertQuery(predicate: "arrayCol.@max.int16Col <= %@", values: [Int16(17)], expectedCount: 0) {
            $0.arrayCol.int16Col.max <= Int16(17)
        }

        assertQuery(predicate: "arrayCol.@max.int16Col <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.int16Col.max <= Int16(18)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.int16Col != %@", values: [Int16(18)], expectedCount: 3) {
            $0.arrayCol.int16Col.max != Int16(18)
        }

        assertQuery(predicate: "arrayCol.@max.int16Col != %@", values: [Int16(16)], expectedCount: 4) {
            $0.arrayCol.int16Col.max != Int16(16)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int32Col": Int32(32)])
            let modernObj1 = ModernAllTypesObject(value: ["int32Col": Int32(33)])
            let modernObj2 = ModernAllTypesObject(value: ["int32Col": Int32(34)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.int32Col > %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.int32Col.max > Int32(32)
        }

        assertQuery(predicate: "arrayCol.@max.int32Col < %@", values: [Int32(34)], expectedCount: 0) {
            $0.arrayCol.int32Col.max < Int32(34)
        }

        assertQuery(predicate: "arrayCol.@max.int32Col == %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.int32Col.max == Int32(34)
        }

        assertQuery(predicate: "arrayCol.@max.int32Col >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.int32Col.max >= Int32(32)
        }

        assertQuery(predicate: "arrayCol.@max.int32Col >= %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.int32Col.max >= Int32(34)
        }

        assertQuery(predicate: "arrayCol.@max.int32Col <= %@", values: [Int32(33)], expectedCount: 0) {
            $0.arrayCol.int32Col.max <= Int32(33)
        }

        assertQuery(predicate: "arrayCol.@max.int32Col <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.int32Col.max <= Int32(34)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.int32Col != %@", values: [Int32(34)], expectedCount: 3) {
            $0.arrayCol.int32Col.max != Int32(34)
        }

        assertQuery(predicate: "arrayCol.@max.int32Col != %@", values: [Int32(32)], expectedCount: 4) {
            $0.arrayCol.int32Col.max != Int32(32)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["int64Col": Int64(64)])
            let modernObj1 = ModernAllTypesObject(value: ["int64Col": Int64(65)])
            let modernObj2 = ModernAllTypesObject(value: ["int64Col": Int64(66)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.int64Col > %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.int64Col.max > Int64(64)
        }

        assertQuery(predicate: "arrayCol.@max.int64Col < %@", values: [Int64(66)], expectedCount: 0) {
            $0.arrayCol.int64Col.max < Int64(66)
        }

        assertQuery(predicate: "arrayCol.@max.int64Col == %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.int64Col.max == Int64(66)
        }

        assertQuery(predicate: "arrayCol.@max.int64Col >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.int64Col.max >= Int64(64)
        }

        assertQuery(predicate: "arrayCol.@max.int64Col >= %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.int64Col.max >= Int64(66)
        }

        assertQuery(predicate: "arrayCol.@max.int64Col <= %@", values: [Int64(65)], expectedCount: 0) {
            $0.arrayCol.int64Col.max <= Int64(65)
        }

        assertQuery(predicate: "arrayCol.@max.int64Col <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.int64Col.max <= Int64(66)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.int64Col != %@", values: [Int64(66)], expectedCount: 3) {
            $0.arrayCol.int64Col.max != Int64(66)
        }

        assertQuery(predicate: "arrayCol.@max.int64Col != %@", values: [Int64(64)], expectedCount: 4) {
            $0.arrayCol.int64Col.max != Int64(64)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["floatCol": Float(5.55444333)])
            let modernObj1 = ModernAllTypesObject(value: ["floatCol": Float(6.55444333)])
            let modernObj2 = ModernAllTypesObject(value: ["floatCol": Float(7.55444333)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.floatCol > %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.max > Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.floatCol < %@", values: [Float(7.55444333)], expectedCount: 0) {
            $0.arrayCol.floatCol.max < Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.floatCol == %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.max == Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.floatCol >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.max >= Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.floatCol >= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.max >= Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.floatCol <= %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.arrayCol.floatCol.max <= Float(6.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.floatCol <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.floatCol.max <= Float(7.55444333)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.floatCol != %@", values: [Float(7.55444333)], expectedCount: 3) {
            $0.arrayCol.floatCol.max != Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.floatCol != %@", values: [Float(5.55444333)], expectedCount: 4) {
            $0.arrayCol.floatCol.max != Float(5.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["doubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["doubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["doubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.doubleCol > %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.doubleCol.max > 123.456
        }

        assertQuery(predicate: "arrayCol.@max.doubleCol < %@", values: [345.678], expectedCount: 0) {
            $0.arrayCol.doubleCol.max < 345.678
        }

        assertQuery(predicate: "arrayCol.@max.doubleCol == %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.doubleCol.max == 345.678
        }

        assertQuery(predicate: "arrayCol.@max.doubleCol >= %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.doubleCol.max >= 123.456
        }

        assertQuery(predicate: "arrayCol.@max.doubleCol >= %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.doubleCol.max >= 345.678
        }

        assertQuery(predicate: "arrayCol.@max.doubleCol <= %@", values: [234.567], expectedCount: 0) {
            $0.arrayCol.doubleCol.max <= 234.567
        }

        assertQuery(predicate: "arrayCol.@max.doubleCol <= %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.doubleCol.max <= 345.678
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.doubleCol != %@", values: [345.678], expectedCount: 3) {
            $0.arrayCol.doubleCol.max != 345.678
        }

        assertQuery(predicate: "arrayCol.@max.doubleCol != %@", values: [123.456], expectedCount: 4) {
            $0.arrayCol.doubleCol.max != 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["dateCol": Date(timeIntervalSince1970: 1000000)])
            let modernObj1 = ModernAllTypesObject(value: ["dateCol": Date(timeIntervalSince1970: 2000000)])
            let modernObj2 = ModernAllTypesObject(value: ["dateCol": Date(timeIntervalSince1970: 3000000)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.dateCol > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayCol.dateCol.max > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@max.dateCol < %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 0) {
            $0.arrayCol.dateCol.max < Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@max.dateCol == %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.arrayCol.dateCol.max == Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@max.dateCol >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayCol.dateCol.max >= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@max.dateCol >= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.arrayCol.dateCol.max >= Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@max.dateCol <= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.arrayCol.dateCol.max <= Date(timeIntervalSince1970: 2000000)
        }

        assertQuery(predicate: "arrayCol.@max.dateCol <= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.arrayCol.dateCol.max <= Date(timeIntervalSince1970: 3000000)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.dateCol != %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 3) {
            $0.arrayCol.dateCol.max != Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@max.dateCol != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 4) {
            $0.arrayCol.dateCol.max != Date(timeIntervalSince1970: 1000000)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["decimalCol": Decimal128(123.456)])
            let modernObj1 = ModernAllTypesObject(value: ["decimalCol": Decimal128(234.567)])
            let modernObj2 = ModernAllTypesObject(value: ["decimalCol": Decimal128(345.678)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.decimalCol > %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.decimalCol.max > Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@max.decimalCol < %@", values: [Decimal128(345.678)], expectedCount: 0) {
            $0.arrayCol.decimalCol.max < Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@max.decimalCol == %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.decimalCol.max == Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@max.decimalCol >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.decimalCol.max >= Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@max.decimalCol >= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.decimalCol.max >= Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@max.decimalCol <= %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.arrayCol.decimalCol.max <= Decimal128(234.567)
        }

        assertQuery(predicate: "arrayCol.@max.decimalCol <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.decimalCol.max <= Decimal128(345.678)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.decimalCol != %@", values: [Decimal128(345.678)], expectedCount: 3) {
            $0.arrayCol.decimalCol.max != Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@max.decimalCol != %@", values: [Decimal128(123.456)], expectedCount: 4) {
            $0.arrayCol.decimalCol.max != Decimal128(123.456)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optIntCol": 5])
            let modernObj1 = ModernAllTypesObject(value: ["optIntCol": 6])
            let modernObj2 = ModernAllTypesObject(value: ["optIntCol": 7])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.optIntCol > %@", values: [5], expectedCount: 1) {
            $0.arrayCol.optIntCol.max > 5
        }

        assertQuery(predicate: "arrayCol.@max.optIntCol < %@", values: [7], expectedCount: 0) {
            $0.arrayCol.optIntCol.max < 7
        }

        assertQuery(predicate: "arrayCol.@max.optIntCol == %@", values: [7], expectedCount: 1) {
            $0.arrayCol.optIntCol.max == 7
        }

        assertQuery(predicate: "arrayCol.@max.optIntCol >= %@", values: [5], expectedCount: 1) {
            $0.arrayCol.optIntCol.max >= 5
        }

        assertQuery(predicate: "arrayCol.@max.optIntCol >= %@", values: [7], expectedCount: 1) {
            $0.arrayCol.optIntCol.max >= 7
        }

        assertQuery(predicate: "arrayCol.@max.optIntCol <= %@", values: [6], expectedCount: 0) {
            $0.arrayCol.optIntCol.max <= 6
        }

        assertQuery(predicate: "arrayCol.@max.optIntCol <= %@", values: [7], expectedCount: 1) {
            $0.arrayCol.optIntCol.max <= 7
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.optIntCol != %@", values: [7], expectedCount: 3) {
            $0.arrayCol.optIntCol.max != 7
        }

        assertQuery(predicate: "arrayCol.@max.optIntCol != %@", values: [5], expectedCount: 4) {
            $0.arrayCol.optIntCol.max != 5
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt8Col": Int8(8)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt8Col": Int8(9)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt8Col": Int8(10)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.optInt8Col > %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.max > Int8(8)
        }

        assertQuery(predicate: "arrayCol.@max.optInt8Col < %@", values: [Int8(10)], expectedCount: 0) {
            $0.arrayCol.optInt8Col.max < Int8(10)
        }

        assertQuery(predicate: "arrayCol.@max.optInt8Col == %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.max == Int8(10)
        }

        assertQuery(predicate: "arrayCol.@max.optInt8Col >= %@", values: [Int8(8)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.max >= Int8(8)
        }

        assertQuery(predicate: "arrayCol.@max.optInt8Col >= %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.max >= Int8(10)
        }

        assertQuery(predicate: "arrayCol.@max.optInt8Col <= %@", values: [Int8(9)], expectedCount: 0) {
            $0.arrayCol.optInt8Col.max <= Int8(9)
        }

        assertQuery(predicate: "arrayCol.@max.optInt8Col <= %@", values: [Int8(10)], expectedCount: 1) {
            $0.arrayCol.optInt8Col.max <= Int8(10)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.optInt8Col != %@", values: [Int8(10)], expectedCount: 3) {
            $0.arrayCol.optInt8Col.max != Int8(10)
        }

        assertQuery(predicate: "arrayCol.@max.optInt8Col != %@", values: [Int8(8)], expectedCount: 4) {
            $0.arrayCol.optInt8Col.max != Int8(8)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt16Col": Int16(16)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt16Col": Int16(17)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt16Col": Int16(18)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.optInt16Col > %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.max > Int16(16)
        }

        assertQuery(predicate: "arrayCol.@max.optInt16Col < %@", values: [Int16(18)], expectedCount: 0) {
            $0.arrayCol.optInt16Col.max < Int16(18)
        }

        assertQuery(predicate: "arrayCol.@max.optInt16Col == %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.max == Int16(18)
        }

        assertQuery(predicate: "arrayCol.@max.optInt16Col >= %@", values: [Int16(16)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.max >= Int16(16)
        }

        assertQuery(predicate: "arrayCol.@max.optInt16Col >= %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.max >= Int16(18)
        }

        assertQuery(predicate: "arrayCol.@max.optInt16Col <= %@", values: [Int16(17)], expectedCount: 0) {
            $0.arrayCol.optInt16Col.max <= Int16(17)
        }

        assertQuery(predicate: "arrayCol.@max.optInt16Col <= %@", values: [Int16(18)], expectedCount: 1) {
            $0.arrayCol.optInt16Col.max <= Int16(18)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.optInt16Col != %@", values: [Int16(18)], expectedCount: 3) {
            $0.arrayCol.optInt16Col.max != Int16(18)
        }

        assertQuery(predicate: "arrayCol.@max.optInt16Col != %@", values: [Int16(16)], expectedCount: 4) {
            $0.arrayCol.optInt16Col.max != Int16(16)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt32Col": Int32(32)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt32Col": Int32(33)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt32Col": Int32(34)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.optInt32Col > %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.max > Int32(32)
        }

        assertQuery(predicate: "arrayCol.@max.optInt32Col < %@", values: [Int32(34)], expectedCount: 0) {
            $0.arrayCol.optInt32Col.max < Int32(34)
        }

        assertQuery(predicate: "arrayCol.@max.optInt32Col == %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.max == Int32(34)
        }

        assertQuery(predicate: "arrayCol.@max.optInt32Col >= %@", values: [Int32(32)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.max >= Int32(32)
        }

        assertQuery(predicate: "arrayCol.@max.optInt32Col >= %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.max >= Int32(34)
        }

        assertQuery(predicate: "arrayCol.@max.optInt32Col <= %@", values: [Int32(33)], expectedCount: 0) {
            $0.arrayCol.optInt32Col.max <= Int32(33)
        }

        assertQuery(predicate: "arrayCol.@max.optInt32Col <= %@", values: [Int32(34)], expectedCount: 1) {
            $0.arrayCol.optInt32Col.max <= Int32(34)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.optInt32Col != %@", values: [Int32(34)], expectedCount: 3) {
            $0.arrayCol.optInt32Col.max != Int32(34)
        }

        assertQuery(predicate: "arrayCol.@max.optInt32Col != %@", values: [Int32(32)], expectedCount: 4) {
            $0.arrayCol.optInt32Col.max != Int32(32)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optInt64Col": Int64(64)])
            let modernObj1 = ModernAllTypesObject(value: ["optInt64Col": Int64(65)])
            let modernObj2 = ModernAllTypesObject(value: ["optInt64Col": Int64(66)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.optInt64Col > %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.max > Int64(64)
        }

        assertQuery(predicate: "arrayCol.@max.optInt64Col < %@", values: [Int64(66)], expectedCount: 0) {
            $0.arrayCol.optInt64Col.max < Int64(66)
        }

        assertQuery(predicate: "arrayCol.@max.optInt64Col == %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.max == Int64(66)
        }

        assertQuery(predicate: "arrayCol.@max.optInt64Col >= %@", values: [Int64(64)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.max >= Int64(64)
        }

        assertQuery(predicate: "arrayCol.@max.optInt64Col >= %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.max >= Int64(66)
        }

        assertQuery(predicate: "arrayCol.@max.optInt64Col <= %@", values: [Int64(65)], expectedCount: 0) {
            $0.arrayCol.optInt64Col.max <= Int64(65)
        }

        assertQuery(predicate: "arrayCol.@max.optInt64Col <= %@", values: [Int64(66)], expectedCount: 1) {
            $0.arrayCol.optInt64Col.max <= Int64(66)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.optInt64Col != %@", values: [Int64(66)], expectedCount: 3) {
            $0.arrayCol.optInt64Col.max != Int64(66)
        }

        assertQuery(predicate: "arrayCol.@max.optInt64Col != %@", values: [Int64(64)], expectedCount: 4) {
            $0.arrayCol.optInt64Col.max != Int64(64)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optFloatCol": Float(5.55444333)])
            let modernObj1 = ModernAllTypesObject(value: ["optFloatCol": Float(6.55444333)])
            let modernObj2 = ModernAllTypesObject(value: ["optFloatCol": Float(7.55444333)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.optFloatCol > %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.max > Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.optFloatCol < %@", values: [Float(7.55444333)], expectedCount: 0) {
            $0.arrayCol.optFloatCol.max < Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.optFloatCol == %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.max == Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.optFloatCol >= %@", values: [Float(5.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.max >= Float(5.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.optFloatCol >= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.max >= Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.optFloatCol <= %@", values: [Float(6.55444333)], expectedCount: 0) {
            $0.arrayCol.optFloatCol.max <= Float(6.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.optFloatCol <= %@", values: [Float(7.55444333)], expectedCount: 1) {
            $0.arrayCol.optFloatCol.max <= Float(7.55444333)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.optFloatCol != %@", values: [Float(7.55444333)], expectedCount: 3) {
            $0.arrayCol.optFloatCol.max != Float(7.55444333)
        }

        assertQuery(predicate: "arrayCol.@max.optFloatCol != %@", values: [Float(5.55444333)], expectedCount: 4) {
            $0.arrayCol.optFloatCol.max != Float(5.55444333)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDoubleCol": 123.456])
            let modernObj1 = ModernAllTypesObject(value: ["optDoubleCol": 234.567])
            let modernObj2 = ModernAllTypesObject(value: ["optDoubleCol": 345.678])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.optDoubleCol > %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.max > 123.456
        }

        assertQuery(predicate: "arrayCol.@max.optDoubleCol < %@", values: [345.678], expectedCount: 0) {
            $0.arrayCol.optDoubleCol.max < 345.678
        }

        assertQuery(predicate: "arrayCol.@max.optDoubleCol == %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.max == 345.678
        }

        assertQuery(predicate: "arrayCol.@max.optDoubleCol >= %@", values: [123.456], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.max >= 123.456
        }

        assertQuery(predicate: "arrayCol.@max.optDoubleCol >= %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.max >= 345.678
        }

        assertQuery(predicate: "arrayCol.@max.optDoubleCol <= %@", values: [234.567], expectedCount: 0) {
            $0.arrayCol.optDoubleCol.max <= 234.567
        }

        assertQuery(predicate: "arrayCol.@max.optDoubleCol <= %@", values: [345.678], expectedCount: 1) {
            $0.arrayCol.optDoubleCol.max <= 345.678
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.optDoubleCol != %@", values: [345.678], expectedCount: 3) {
            $0.arrayCol.optDoubleCol.max != 345.678
        }

        assertQuery(predicate: "arrayCol.@max.optDoubleCol != %@", values: [123.456], expectedCount: 4) {
            $0.arrayCol.optDoubleCol.max != 123.456
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDateCol": Date(timeIntervalSince1970: 1000000)])
            let modernObj1 = ModernAllTypesObject(value: ["optDateCol": Date(timeIntervalSince1970: 2000000)])
            let modernObj2 = ModernAllTypesObject(value: ["optDateCol": Date(timeIntervalSince1970: 3000000)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.optDateCol > %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayCol.optDateCol.max > Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@max.optDateCol < %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 0) {
            $0.arrayCol.optDateCol.max < Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@max.optDateCol == %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.arrayCol.optDateCol.max == Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@max.optDateCol >= %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 1) {
            $0.arrayCol.optDateCol.max >= Date(timeIntervalSince1970: 1000000)
        }

        assertQuery(predicate: "arrayCol.@max.optDateCol >= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.arrayCol.optDateCol.max >= Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@max.optDateCol <= %@", values: [Date(timeIntervalSince1970: 2000000)], expectedCount: 0) {
            $0.arrayCol.optDateCol.max <= Date(timeIntervalSince1970: 2000000)
        }

        assertQuery(predicate: "arrayCol.@max.optDateCol <= %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 1) {
            $0.arrayCol.optDateCol.max <= Date(timeIntervalSince1970: 3000000)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.optDateCol != %@", values: [Date(timeIntervalSince1970: 3000000)], expectedCount: 3) {
            $0.arrayCol.optDateCol.max != Date(timeIntervalSince1970: 3000000)
        }

        assertQuery(predicate: "arrayCol.@max.optDateCol != %@", values: [Date(timeIntervalSince1970: 1000000)], expectedCount: 4) {
            $0.arrayCol.optDateCol.max != Date(timeIntervalSince1970: 1000000)
        }

        try! realm.write {
            let modernObj = ModernAllTypesObject(value: ["optDecimalCol": Decimal128(123.456)])
            let modernObj1 = ModernAllTypesObject(value: ["optDecimalCol": Decimal128(234.567)])
            let modernObj2 = ModernAllTypesObject(value: ["optDecimalCol": Decimal128(345.678)])
            realm.delete(object.arrayCol)
            object.arrayCol.append(objectsIn: [modernObj, modernObj1, modernObj2])
        }
        assertQuery(predicate: "arrayCol.@max.optDecimalCol > %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.max > Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@max.optDecimalCol < %@", values: [Decimal128(345.678)], expectedCount: 0) {
            $0.arrayCol.optDecimalCol.max < Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@max.optDecimalCol == %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.max == Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@max.optDecimalCol >= %@", values: [Decimal128(123.456)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.max >= Decimal128(123.456)
        }

        assertQuery(predicate: "arrayCol.@max.optDecimalCol >= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.max >= Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@max.optDecimalCol <= %@", values: [Decimal128(234.567)], expectedCount: 0) {
            $0.arrayCol.optDecimalCol.max <= Decimal128(234.567)
        }

        assertQuery(predicate: "arrayCol.@max.optDecimalCol <= %@", values: [Decimal128(345.678)], expectedCount: 1) {
            $0.arrayCol.optDecimalCol.max <= Decimal128(345.678)
        }

        // This includes all ModernAllTypesObject objects beside the one we are populating
        assertQuery(predicate: "arrayCol.@max.optDecimalCol != %@", values: [Decimal128(345.678)], expectedCount: 3) {
            $0.arrayCol.optDecimalCol.max != Decimal128(345.678)
        }

        assertQuery(predicate: "arrayCol.@max.optDecimalCol != %@", values: [Decimal128(123.456)], expectedCount: 4) {
            $0.arrayCol.optDecimalCol.max != Decimal128(123.456)
        }
    }
}
