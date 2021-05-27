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
import Realm.Private

class ModernObjectCreationTests: TestCase {
    var values: [String: Any]!
    override func setUp() {
        values = [
            "boolCol": true,
            "intCol": 10,
            "int8Col": 11 as Int8,
            "int16Col": 12 as Int16,
            "int32Col": 13 as Int32,
            "int64Col": 14 as Int64,
            "floatCol": 15 as Float,
            "doubleCol": 16 as Double,
            "stringCol": "a",
            "binaryCol": "b".data(using: .utf8)!,
            "dateCol": Date(timeIntervalSince1970: 17),
            "decimalCol": 18 as Decimal128,
            "objectIdCol": ObjectId.generate(),
            "objectCol": ModernAllTypesObject(value: ["intCol": 1]),
            "arrayCol": [
                ModernAllTypesObject(value: ["intCol": 2]),
                ModernAllTypesObject(value: ["intCol": 3])
            ],
            "setCol": [
                ModernAllTypesObject(value: ["intCol": 4]),
                ModernAllTypesObject(value: ["intCol": 5]),
                ModernAllTypesObject(value: ["intCol": 6])
            ],
            "anyCol": AnyRealmValue.int(20),
            "uuidCol": UUID(),
            "intEnumCol": ModernIntEnum.value2,
            "stringEnumCol": ModernStringEnum.value3,

            "optBoolCol": false,
            "optIntCol": 30,
            "optInt8Col": 31 as Int8,
            "optInt16Col": 32 as Int16,
            "optInt32Col": 33 as Int32,
            "optInt64Col": 34 as Int64,
            "optFloatCol": 35 as Float,
            "optDoubleCol": 36 as Double,
            "optStringCol": "c",
            "optBinaryCol": "d".data(using: .utf8)!,
            "optDateCol": Date(timeIntervalSince1970: 37),
            "optDecimalCol": 38 as Decimal128,
            "optObjectIdCol": ObjectId.generate(),
            "optUuidCol": UUID(),
            "optIntEnumCol": ModernIntEnum.value1,
            "optStringEnumCol": ModernStringEnum.value1,

            "arrayBool": [],
            "arrayInt": [],
            "arrayInt8": [],
            "arrayInt16": [],
            "arrayInt32": [],
            "arrayInt64": [],
            "arrayFloat": [],
            "arrayDouble": [],
            "arrayString": [],
            "arrayBinary": [],
            "arrayDate": [],
            "arrayDecimal": [],
            "arrayObjectId": [],
            "arrayAny": [],
            "arrayUuid": [],
            "arrayObject": [],

            "arrayOptBool": [],
            "arrayOptInt": [],
            "arrayOptInt8": [],
            "arrayOptInt16": [],
            "arrayOptInt32": [],
            "arrayOptInt64": [],
            "arrayOptFloat": [],
            "arrayOptDouble": [],
            "arrayOptString": [],
            "arrayOptBinary": [],
            "arrayOptDate": [],
            "arrayOptDecimal": [],
            "arrayOptObjectId": [],
            "arrayOptUuid": [],

            "setBool": [],
            "setInt": [],
            "setInt8": [],
            "setInt16": [],
            "setInt32": [],
            "setInt64": [],
            "setFloat": [],
            "setDouble": [],
            "setString": [],
            "setBinary": [],
            "setDate": [],
            "setDecimal": [],
            "setObjectId": [],
            "setAny": [],
            "setUuid": [],
            "setObject": [],

            "setOptBool": [],
            "setOptInt": [],
            "setOptInt8": [],
            "setOptInt16": [],
            "setOptInt32": [],
            "setOptInt64": [],
            "setOptFloat": [],
            "setOptDouble": [],
            "setOptString": [],
            "setOptBinary": [],
            "setOptDate": [],
            "setOptDecimal": [],
            "setOptObjectId": [],
            "setOptUuid": [],

            "mapBool": [:],
            "mapInt": [:],
            "mapInt8": [:],
            "mapInt16": [:],
            "mapInt32": [:],
            "mapInt64": [:],
            "mapFloat": [:],
            "mapDouble": [:],
            "mapString": [:],
            "mapBinary": [:],
            "mapDate": [:],
            "mapDecimal": [:],
            "mapObjectId": [:],
            "mapAny": [:],
            "mapUuid": [:],
            "mapObject": [:],

            "mapOptBool": [:],
            "mapOptInt": [:],
            "mapOptInt8": [:],
            "mapOptInt16": [:],
            "mapOptInt32": [:],
            "mapOptInt64": [:],
            "mapOptFloat": [:],
            "mapOptDouble": [:],
            "mapOptString": [:],
            "mapOptBinary": [:],
            "mapOptDate": [:],
            "mapOptDecimal": [:],
            "mapOptObjectId": [:],
            "mapOptUuid": [:]
        ]
        super.setUp()
    }

    override func tearDown() {
        values = nil
        super.tearDown()
    }

    func verifyObject(_ obj: ModernAllTypesObject) {
        XCTAssertEqual(obj.boolCol, values["boolCol"] as! Bool)
        XCTAssertEqual(obj.intCol, values["intCol"] as! Int)
        XCTAssertEqual(obj.int8Col, values["int8Col"] as! Int8)
        XCTAssertEqual(obj.int16Col, values["int16Col"] as! Int16)
        XCTAssertEqual(obj.int32Col, values["int32Col"] as! Int32)
        XCTAssertEqual(obj.int64Col, values["int64Col"] as! Int64)
        XCTAssertEqual(obj.floatCol, values["floatCol"] as! Float)
        XCTAssertEqual(obj.doubleCol, values["doubleCol"] as! Double)
        XCTAssertEqual(obj.stringCol, values["stringCol"] as! String)
        XCTAssertEqual(obj.binaryCol, values["binaryCol"] as! Data)
        XCTAssertEqual(obj.dateCol, values["dateCol"] as! Date)
        XCTAssertEqual(obj.decimalCol, values["decimalCol"] as! Decimal128)
        XCTAssertEqual(obj.objectIdCol, values["objectIdCol"] as! ObjectId)
        XCTAssertEqual(obj.objectCol!.pk, (values["objectCol"] as! ModernAllTypesObject?)!.pk)
        XCTAssertEqual(obj.anyCol, values["anyCol"] as! AnyRealmValue)
        XCTAssertEqual(obj.uuidCol, values["uuidCol"] as! UUID)
        XCTAssertEqual(obj.intEnumCol, values["intEnumCol"] as! ModernIntEnum)
        XCTAssertEqual(obj.stringEnumCol, values["stringEnumCol"] as! ModernStringEnum)

        XCTAssertEqual(obj.optBoolCol, values["optBoolCol"] as! Bool?)
        XCTAssertEqual(obj.optIntCol, values["optIntCol"] as! Int?)
        XCTAssertEqual(obj.optInt8Col, values["optInt8Col"] as! Int8?)
        XCTAssertEqual(obj.optInt16Col, values["optInt16Col"] as! Int16?)
        XCTAssertEqual(obj.optInt32Col, values["optInt32Col"] as! Int32?)
        XCTAssertEqual(obj.optInt64Col, values["optInt64Col"] as! Int64?)
        XCTAssertEqual(obj.optFloatCol, values["optFloatCol"] as! Float?)
        XCTAssertEqual(obj.optDoubleCol, values["optDoubleCol"] as! Double?)
        XCTAssertEqual(obj.optStringCol, values["optStringCol"] as! String?)
        XCTAssertEqual(obj.optBinaryCol, values["optBinaryCol"] as! Data?)
        XCTAssertEqual(obj.optDateCol, values["optDateCol"] as! Date?)
        XCTAssertEqual(obj.optDecimalCol, values["optDecimalCol"] as! Decimal128?)
        XCTAssertEqual(obj.optObjectIdCol, values["optObjectIdCol"] as! ObjectId?)
        XCTAssertEqual(obj.optUuidCol, values["optUuidCol"] as! UUID?)
        XCTAssertEqual(obj.optIntEnumCol, values["optIntEnumCol"] as! ModernIntEnum?)
        XCTAssertEqual(obj.optStringEnumCol, values["optStringEnumCol"] as! ModernStringEnum?)

        XCTAssertEqual(Array(obj.arrayBool), values["arrayBool"] as! [Bool])
        XCTAssertEqual(Array(obj.arrayInt), values["arrayInt"] as! [Int])
        XCTAssertEqual(Array(obj.arrayInt8), values["arrayInt8"] as! [Int8])
        XCTAssertEqual(Array(obj.arrayInt16), values["arrayInt16"] as! [Int16])
        XCTAssertEqual(Array(obj.arrayInt32), values["arrayInt32"] as! [Int32])
        XCTAssertEqual(Array(obj.arrayInt64), values["arrayInt64"] as! [Int64])
        XCTAssertEqual(Array(obj.arrayFloat), values["arrayFloat"] as! [Float])
        XCTAssertEqual(Array(obj.arrayDouble), values["arrayDouble"] as! [Double])
        XCTAssertEqual(Array(obj.arrayString), values["arrayString"] as! [String])
        XCTAssertEqual(Array(obj.arrayBinary), values["arrayBinary"] as! [Data])
        XCTAssertEqual(Array(obj.arrayDate), values["arrayDate"] as! [Date])
        XCTAssertEqual(Array(obj.arrayDecimal), values["arrayDecimal"] as! [Decimal128])
        XCTAssertEqual(Array(obj.arrayObjectId), values["arrayObjectId"] as! [ObjectId])
        XCTAssertEqual(Array(obj.arrayAny), values["arrayAny"] as! [AnyRealmValue])
        XCTAssertEqual(Array(obj.arrayUuid), values["arrayUuid"] as! [UUID])

        XCTAssertEqual(Array(obj.arrayOptBool), values["arrayOptBool"] as! [Bool?])
        XCTAssertEqual(Array(obj.arrayOptInt), values["arrayOptInt"] as! [Int?])
        XCTAssertEqual(Array(obj.arrayOptInt8), values["arrayOptInt8"] as! [Int8?])
        XCTAssertEqual(Array(obj.arrayOptInt16), values["arrayOptInt16"] as! [Int16?])
        XCTAssertEqual(Array(obj.arrayOptInt32), values["arrayOptInt32"] as! [Int32?])
        XCTAssertEqual(Array(obj.arrayOptInt64), values["arrayOptInt64"] as! [Int64?])
        XCTAssertEqual(Array(obj.arrayOptFloat), values["arrayOptFloat"] as! [Float?])
        XCTAssertEqual(Array(obj.arrayOptDouble), values["arrayOptDouble"] as! [Double?])
        XCTAssertEqual(Array(obj.arrayOptString), values["arrayOptString"] as! [String?])
        XCTAssertEqual(Array(obj.arrayOptBinary), values["arrayOptBinary"] as! [Data?])
        XCTAssertEqual(Array(obj.arrayOptDate), values["arrayOptDate"] as! [Date?])
        XCTAssertEqual(Array(obj.arrayOptDecimal), values["arrayOptDecimal"] as! [Decimal128?])
        XCTAssertEqual(Array(obj.arrayOptObjectId), values["arrayOptObjectId"] as! [ObjectId?])
        XCTAssertEqual(Array(obj.arrayOptUuid), values["arrayOptUuid"] as! [UUID?])
    }

    func verifyDefault(_ obj: ModernAllTypesObject) {
        XCTAssertEqual(obj.boolCol, false)
        XCTAssertEqual(obj.intCol, 0)
        XCTAssertEqual(obj.int8Col, 1)
        XCTAssertEqual(obj.int16Col, 2)
        XCTAssertEqual(obj.int32Col, 3)
        XCTAssertEqual(obj.int64Col, 4)
        XCTAssertEqual(obj.floatCol, 5)
        XCTAssertEqual(obj.doubleCol, 6)
        XCTAssertEqual(obj.stringCol, "")
        XCTAssertEqual(obj.binaryCol, Data())
        XCTAssertEqual(obj.decimalCol, 0)
        XCTAssertNotEqual(obj.objectIdCol, ObjectId()) // should have generated a random ObjectId
        XCTAssertEqual(obj.objectCol, nil)
        XCTAssertEqual(obj.arrayCol.count, 0)
        XCTAssertEqual(obj.setCol.count, 0)
        XCTAssertEqual(obj.anyCol, .none)
        XCTAssertEqual(obj.intEnumCol, .value1)
        XCTAssertEqual(obj.stringEnumCol, .value1)

        XCTAssertNil(obj.optIntCol)
        XCTAssertNil(obj.optInt8Col)
        XCTAssertNil(obj.optInt16Col)
        XCTAssertNil(obj.optInt32Col)
        XCTAssertNil(obj.optInt64Col)
        XCTAssertNil(obj.optFloatCol)
        XCTAssertNil(obj.optDoubleCol)
        XCTAssertNil(obj.optBoolCol)
        XCTAssertNil(obj.optStringCol)
        XCTAssertNil(obj.optBinaryCol)
        XCTAssertNil(obj.optDateCol)
        XCTAssertNil(obj.optDecimalCol)
        XCTAssertNil(obj.optObjectIdCol)
        XCTAssertNil(obj.optUuidCol)
        XCTAssertNil(obj.optIntEnumCol)
        XCTAssertNil(obj.optStringEnumCol)

        XCTAssertEqual(obj.arrayBool.count, 0)
        XCTAssertEqual(obj.arrayInt.count, 0)
        XCTAssertEqual(obj.arrayInt8.count, 0)
        XCTAssertEqual(obj.arrayInt16.count, 0)
        XCTAssertEqual(obj.arrayInt32.count, 0)
        XCTAssertEqual(obj.arrayInt64.count, 0)
        XCTAssertEqual(obj.arrayFloat.count, 0)
        XCTAssertEqual(obj.arrayDouble.count, 0)
        XCTAssertEqual(obj.arrayString.count, 0)
        XCTAssertEqual(obj.arrayBinary.count, 0)
        XCTAssertEqual(obj.arrayDate.count, 0)
        XCTAssertEqual(obj.arrayDecimal.count, 0)
        XCTAssertEqual(obj.arrayObjectId.count, 0)
        XCTAssertEqual(obj.arrayAny.count, 0)
        XCTAssertEqual(obj.arrayUuid.count, 0)
        XCTAssertEqual(obj.arrayObject.count, 0)

        XCTAssertEqual(obj.arrayOptBool.count, 0)
        XCTAssertEqual(obj.arrayOptInt.count, 0)
        XCTAssertEqual(obj.arrayOptInt8.count, 0)
        XCTAssertEqual(obj.arrayOptInt16.count, 0)
        XCTAssertEqual(obj.arrayOptInt32.count, 0)
        XCTAssertEqual(obj.arrayOptInt64.count, 0)
        XCTAssertEqual(obj.arrayOptFloat.count, 0)
        XCTAssertEqual(obj.arrayOptDouble.count, 0)
        XCTAssertEqual(obj.arrayOptString.count, 0)
        XCTAssertEqual(obj.arrayOptBinary.count, 0)
        XCTAssertEqual(obj.arrayOptDate.count, 0)
        XCTAssertEqual(obj.arrayOptDecimal.count, 0)
        XCTAssertEqual(obj.arrayOptObjectId.count, 0)
        XCTAssertEqual(obj.arrayOptUuid.count, 0)

        XCTAssertEqual(obj.setBool.count, 0)
        XCTAssertEqual(obj.setInt.count, 0)
        XCTAssertEqual(obj.setInt8.count, 0)
        XCTAssertEqual(obj.setInt16.count, 0)
        XCTAssertEqual(obj.setInt32.count, 0)
        XCTAssertEqual(obj.setInt64.count, 0)
        XCTAssertEqual(obj.setFloat.count, 0)
        XCTAssertEqual(obj.setDouble.count, 0)
        XCTAssertEqual(obj.setString.count, 0)
        XCTAssertEqual(obj.setBinary.count, 0)
        XCTAssertEqual(obj.setDate.count, 0)
        XCTAssertEqual(obj.setDecimal.count, 0)
        XCTAssertEqual(obj.setObjectId.count, 0)
        XCTAssertEqual(obj.setAny.count, 0)
        XCTAssertEqual(obj.setUuid.count, 0)
        XCTAssertEqual(obj.setObject.count, 0)

        XCTAssertEqual(obj.setOptBool.count, 0)
        XCTAssertEqual(obj.setOptInt.count, 0)
        XCTAssertEqual(obj.setOptInt8.count, 0)
        XCTAssertEqual(obj.setOptInt16.count, 0)
        XCTAssertEqual(obj.setOptInt32.count, 0)
        XCTAssertEqual(obj.setOptInt64.count, 0)
        XCTAssertEqual(obj.setOptFloat.count, 0)
        XCTAssertEqual(obj.setOptDouble.count, 0)
        XCTAssertEqual(obj.setOptString.count, 0)
        XCTAssertEqual(obj.setOptBinary.count, 0)
        XCTAssertEqual(obj.setOptDate.count, 0)
        XCTAssertEqual(obj.setOptDecimal.count, 0)
        XCTAssertEqual(obj.setOptObjectId.count, 0)
        XCTAssertEqual(obj.setOptUuid.count, 0)
    }

    func testInitDefault() {
        verifyDefault(ModernAllTypesObject())
    }

    func testInitWithArray() {
        var arrayValues = ModernAllTypesObject.sharedSchema()!.properties.map { values[$0.name] }
        arrayValues[0] = ObjectId.generate()
        verifyObject(ModernAllTypesObject(value: arrayValues))
    }

    func testInitWithDictionary() {
        verifyObject(ModernAllTypesObject(value: values!))
    }

    func testInitWithObject() {
        let obj = ModernAllTypesObject(value: values!)
        verifyObject(ModernAllTypesObject(value: obj))
    }

    func testCreateDefault() {
        let realm = try! Realm()
        let obj = try! realm.write {
            return realm.create(ModernAllTypesObject.self)
        }
        verifyDefault(obj)
    }

    func testCreateWithArray() {
        let realm = try! Realm()
        var arrayValues = ModernAllTypesObject.sharedSchema()!.properties.map { values[$0.name] }
        arrayValues[0] = ObjectId.generate()
        let obj = try! realm.write {
            return realm.create(ModernAllTypesObject.self, value: arrayValues)
        }
        verifyObject(obj)
    }

    func testCreateWithDictionary() {
        let realm = try! Realm()
        let obj = try! realm.write {
            return realm.create(ModernAllTypesObject.self, value: values!)
        }
        verifyObject(obj)
    }

    func testCreateWithObject() {
        let realm = try! Realm()
        let obj = try! realm.write {
            return realm.create(ModernAllTypesObject.self, value: ModernAllTypesObject(value: values!))
        }
        verifyObject(obj)
    }

    func testAdd() {
        let obj = ModernAllTypesObject(value: values!)
        let realm = try! Realm()
        try! realm.write {
            realm.add(obj)
        }
        verifyObject(obj)
    }
}
