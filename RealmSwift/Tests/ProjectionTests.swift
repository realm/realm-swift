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

import Foundation
import Realm
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmTestSupport
//import SwiftUI
#endif

/**
 Test objects definitions
 */
enum IntegerEnum: Int, PersistableEnum {
    case value1 = 1
    case value2 = 3
}

class SwiftAllTypesObject: Object {
    @Persisted(primaryKey: true) var pk: String
    @Persisted var boolCol: Bool
    @Persisted var intCol: Int
    @Persisted var int8Col: Int8
    @Persisted var int16Col: Int16
    @Persisted var int32Col: Int32
    @Persisted var int64Col: Int64
    @Persisted var intEnumCol: IntegerEnum
    @Persisted var floatCol: Float
    @Persisted var doubleCol: Double
    @Persisted var stringCol: String
    @Persisted var binaryCol: Data
    @Persisted var dateCol: Date
    @Persisted var decimalCol: Decimal128
    @Persisted var objectIdCol: ObjectId
    @Persisted var objectCol: SwiftBoolObject?
    @Persisted var uuidCol: UUID
    @Persisted var arrayCol: List<SwiftBoolObject>
    @Persisted var setCol: MutableSet<SwiftBoolObject>
    @Persisted var mapCol: Map<String, SwiftBoolObject?>
    @Persisted var relationCol: List<SwiftAllTypesObject>
    @Persisted(originProperty: "relationCol") var backlink: LinkingObjects<SwiftAllTypesObject>

    class func defaultValues() -> [String: Any] {
        return  [
            "pk": UUID().uuidString,
            "boolCol": true,
            "intCol": 123,
            "int8Col": 123 as Int8,
            "int16Col": 123 as Int16,
            "int32Col": 123 as Int32,
            "int64Col": 123 as Int64,
            "floatCol": 1.23 as Float,
            "doubleCol": 12.3,
            "stringCol": "a",
            "binaryCol": "a".data(using: String.Encoding.utf8)!,
            "dateCol": Date(timeIntervalSince1970: 1),
            "decimalCol": Decimal128("123e4"),
            "objectIdCol": ObjectId("1234567890ab1234567890ab"),
            "objectCol": [false],
            "uuidCol": UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!,
            "arrayCol": [[true]],
            "setCol": [[true]],
            "mapCol": ["true": [true]]
        ]
    }
}

struct AllTypesProjection: Projection {
    typealias Root = ModernAllTypesObject

    init() {
    }

    @Projected(\ModernAllTypesObject.pk) var pk
    @Projected(\ModernAllTypesObject.ignored) var ignored
    @Projected(\ModernAllTypesObject.boolCol) var boolCol
    @Projected(\ModernAllTypesObject.intCol) var intCol
    @Projected(\ModernAllTypesObject.int8Col) var int8Col
    @Projected(\ModernAllTypesObject.int16Col) var int16Col
    @Projected(\ModernAllTypesObject.int32Col) var int32Col
    @Projected(\ModernAllTypesObject.int64Col) var int64Col
    @Projected(\ModernAllTypesObject.floatCol) var floatCol
    @Projected(\ModernAllTypesObject.doubleCol) var doubleCol
    @Projected(\ModernAllTypesObject.stringCol) var stringCol
    @Projected(\ModernAllTypesObject.binaryCol) var binaryCol
    @Projected(\ModernAllTypesObject.dateCol) var dateCol
    @Projected(\ModernAllTypesObject.decimalCol) var decimalCol
    @Projected(\ModernAllTypesObject.objectIdCol) var objectIdCol
    @Projected(\ModernAllTypesObject.objectCol) var objectCol
    @Projected(\ModernAllTypesObject.arrayCol) var arrayCol
    @Projected(\ModernAllTypesObject.setCol) var setCol
    @Projected(\ModernAllTypesObject.anyCol) var anyCol
    @Projected(\ModernAllTypesObject.uuidCol) var uuidCol
    @Projected(\ModernAllTypesObject.intEnumCol) var intEnumCol
    @Projected(\ModernAllTypesObject.stringEnumCol) var stringEnumCol

    @Projected(\ModernAllTypesObject.optIntCol) var optIntCol
    @Projected(\ModernAllTypesObject.optInt8Col) var optInt8Col
    @Projected(\ModernAllTypesObject.optInt16Col) var optInt16Col
    @Projected(\ModernAllTypesObject.optInt32Col) var optInt32Col
    @Projected(\ModernAllTypesObject.optInt64Col) var optInt64Col
    @Projected(\ModernAllTypesObject.optFloatCol) var optFloatCol
    @Projected(\ModernAllTypesObject.optDoubleCol) var optDoubleCol
    @Projected(\ModernAllTypesObject.optBoolCol) var optBoolCol
    @Projected(\ModernAllTypesObject.optStringCol) var optStringCol
    @Projected(\ModernAllTypesObject.optBinaryCol) var optBinaryCol
    @Projected(\ModernAllTypesObject.optDateCol) var optDateCol
    @Projected(\ModernAllTypesObject.optDecimalCol) var optDecimalCol
    @Projected(\ModernAllTypesObject.optObjectIdCol) var optObjectIdCol
    @Projected(\ModernAllTypesObject.optUuidCol) var optUuidCol
    @Projected(\ModernAllTypesObject.optIntEnumCol) var optIntEnumCol
    @Projected(\ModernAllTypesObject.optStringEnumCol) var optStringEnumCol

    @Projected(\ModernAllTypesObject.arrayBool) var arrayBool
    @Projected(\ModernAllTypesObject.arrayInt) var arrayInt
    @Projected(\ModernAllTypesObject.arrayInt8) var arrayInt8
    @Projected(\ModernAllTypesObject.arrayInt16) var arrayInt16
    @Projected(\ModernAllTypesObject.arrayInt32) var arrayInt32
    @Projected(\ModernAllTypesObject.arrayInt64) var arrayInt64
    @Projected(\ModernAllTypesObject.arrayFloat) var arrayFloat
    @Projected(\ModernAllTypesObject.arrayDouble) var arrayDouble
    @Projected(\ModernAllTypesObject.arrayString) var arrayString
    @Projected(\ModernAllTypesObject.arrayBinary) var arrayBinary
    @Projected(\ModernAllTypesObject.arrayDate) var arrayDate
    @Projected(\ModernAllTypesObject.arrayDecimal) var arrayDecimal
    @Projected(\ModernAllTypesObject.arrayObjectId) var arrayObjectId
    @Projected(\ModernAllTypesObject.arrayAny) var arrayAny
    @Projected(\ModernAllTypesObject.arrayUuid) var arrayUuid

    @Projected(\ModernAllTypesObject.arrayOptBool) var arrayOptBool
    @Projected(\ModernAllTypesObject.arrayOptInt) var arrayOptInt
    @Projected(\ModernAllTypesObject.arrayOptInt8) var arrayOptInt8
    @Projected(\ModernAllTypesObject.arrayOptInt16) var arrayOptInt16
    @Projected(\ModernAllTypesObject.arrayOptInt32) var arrayOptInt32
    @Projected(\ModernAllTypesObject.arrayOptInt64) var arrayOptInt64
    @Projected(\ModernAllTypesObject.arrayOptFloat) var arrayOptFloat
    @Projected(\ModernAllTypesObject.arrayOptDouble) var arrayOptDouble
    @Projected(\ModernAllTypesObject.arrayOptString) var arrayOptString
    @Projected(\ModernAllTypesObject.arrayOptBinary) var arrayOptBinary
    @Projected(\ModernAllTypesObject.arrayOptDate) var arrayOptDate
    @Projected(\ModernAllTypesObject.arrayOptDecimal) var arrayOptDecimal
    @Projected(\ModernAllTypesObject.arrayOptObjectId) var arrayOptObjectId
    @Projected(\ModernAllTypesObject.arrayOptUuid) var arrayOptUuid

    @Projected(\ModernAllTypesObject.setBool) var setBool
    @Projected(\ModernAllTypesObject.setInt) var setInt
    @Projected(\ModernAllTypesObject.setInt8) var setInt8
    @Projected(\ModernAllTypesObject.setInt16) var setInt16
    @Projected(\ModernAllTypesObject.setInt32) var setInt32
    @Projected(\ModernAllTypesObject.setInt64) var setInt64
    @Projected(\ModernAllTypesObject.setFloat) var setFloat
    @Projected(\ModernAllTypesObject.setDouble) var setDouble
    @Projected(\ModernAllTypesObject.setString) var setString
    @Projected(\ModernAllTypesObject.setBinary) var setBinary
    @Projected(\ModernAllTypesObject.setDate) var setDate
    @Projected(\ModernAllTypesObject.setDecimal) var setDecimal
    @Projected(\ModernAllTypesObject.setObjectId) var setObjectId
    @Projected(\ModernAllTypesObject.setAny) var setAny
    @Projected(\ModernAllTypesObject.setUuid) var setUuid

    @Projected(\ModernAllTypesObject.setOptBool) var setOptBool
    @Projected(\ModernAllTypesObject.setOptInt) var setOptInt
    @Projected(\ModernAllTypesObject.setOptInt8) var setOptInt8
    @Projected(\ModernAllTypesObject.setOptInt16) var setOptInt16
    @Projected(\ModernAllTypesObject.setOptInt32) var setOptInt32
    @Projected(\ModernAllTypesObject.setOptInt64) var setOptInt64
    @Projected(\ModernAllTypesObject.setOptFloat) var setOptFloat
    @Projected(\ModernAllTypesObject.setOptDouble) var setOptDouble
    @Projected(\ModernAllTypesObject.setOptString) var setOptString
    @Projected(\ModernAllTypesObject.setOptBinary) var setOptBinary
    @Projected(\ModernAllTypesObject.setOptDate) var setOptDate
    @Projected(\ModernAllTypesObject.setOptDecimal) var setOptDecimal
    @Projected(\ModernAllTypesObject.setOptObjectId) var setOptObjectId
    @Projected(\ModernAllTypesObject.setOptUuid) var setOptUuid

    @Projected(\ModernAllTypesObject.mapBool) var mapBool
    @Projected(\ModernAllTypesObject.mapInt) var mapInt
    @Projected(\ModernAllTypesObject.mapInt8) var mapInt8
    @Projected(\ModernAllTypesObject.mapInt16) var mapInt16
    @Projected(\ModernAllTypesObject.mapInt32) var mapInt32
    @Projected(\ModernAllTypesObject.mapInt64) var mapInt64
    @Projected(\ModernAllTypesObject.mapFloat) var mapFloat
    @Projected(\ModernAllTypesObject.mapDouble) var mapDouble
    @Projected(\ModernAllTypesObject.mapString) var mapString
    @Projected(\ModernAllTypesObject.mapBinary) var mapBinary
    @Projected(\ModernAllTypesObject.mapDate) var mapDate
    @Projected(\ModernAllTypesObject.mapDecimal) var mapDecimal
    @Projected(\ModernAllTypesObject.mapObjectId) var mapObjectId
    @Projected(\ModernAllTypesObject.mapAny) var mapAny
    @Projected(\ModernAllTypesObject.mapUuid) var mapUuid

    @Projected(\ModernAllTypesObject.mapOptBool) var mapOptBool
    @Projected(\ModernAllTypesObject.mapOptInt) var mapOptInt
    @Projected(\ModernAllTypesObject.mapOptInt8) var mapOptInt8
    @Projected(\ModernAllTypesObject.mapOptInt16) var mapOptInt16
    @Projected(\ModernAllTypesObject.mapOptInt32) var mapOptInt32
    @Projected(\ModernAllTypesObject.mapOptInt64) var mapOptInt64
    @Projected(\ModernAllTypesObject.mapOptFloat) var mapOptFloat
    @Projected(\ModernAllTypesObject.mapOptDouble) var mapOptDouble
    @Projected(\ModernAllTypesObject.mapOptString) var mapOptString
    @Projected(\ModernAllTypesObject.mapOptBinary) var mapOptBinary
    @Projected(\ModernAllTypesObject.mapOptDate) var mapOptDate
    @Projected(\ModernAllTypesObject.mapOptDecimal) var mapOptDecimal
    @Projected(\ModernAllTypesObject.mapOptObjectId) var mapOptObjectId
    @Projected(\ModernAllTypesObject.mapOptUuid) var mapOptUuid

    @Projected(\ModernAllTypesObject.linkingObjects) var linkingObjects
}
public class Address: EmbeddedObject {
    @Persisted var city: String = ""
    @Persisted var country = ""
}

public class Person: Object {
    @Persisted var firstName: String
    @Persisted var lastName = ""
    @Persisted var birthday: Date
    @Persisted var address: Address? = nil
    @Persisted public var friends = List<Person>()
    @Persisted var reviews = List<String>()
    @Persisted var money: Decimal128
}

public struct PersonProjection: Projection {
    public typealias Root = Person

    public init() {
    }

    @Projected(\Person.firstName) var firstName
    @Projected(\Person.lastName) var lastName
    @Projected(\Person.birthday.timeIntervalSince1970) var birthdayAsEpochtime
    @Projected(\Person.address?.city) var homeCity
    @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: ProjectedList<String>
}

class ProjectionTests: TestCase {

    override func setUp() {
        super.setUp()
        let realm = realmWithTestPath()
        try! realm.write {
            let js = realm.create(Person.self, value: ["firstName": "John",
                                                       "lastName": "Snow",
                                                       "birthday": Date(timeIntervalSince1970: 10),
                                                       "address": ["Winterfell", "Kingdom in the North"],
                                                       "money": Decimal128("2.22")])
            let dt = realm.create(Person.self, value: ["firstName": "Daenerys",
                                                       "lastName": "Targaryen",
                                                       "birthday": Date(timeIntervalSince1970: 0),
                                                       "address": ["King's Landing", "Westeros"],
                                                       "money": Decimal128("2.22")])
            js.friends.append(dt)
            dt.friends.append(js)
            
            let a = realm.create(SwiftAllTypesObject.self, value: SwiftAllTypesObject.defaultValues())
            let b = realm.create(SwiftAllTypesObject.self, value: SwiftAllTypesObject.defaultValues())
            a.relationCol.append(b)
            b.relationCol.append(a)
            
            let all = realm.create(ModernAllTypesObject.self)
            
//            func setAndTestAllPropertiesViaNormalAccess(_ object: ModernAllTypesObject) {
//                func test<T: Equatable>(_ keyPath: ReferenceWritableKeyPath<ModernAllTypesObject, T>, _ values: T...) {
//                    for value in values {
//                        object[keyPath: keyPath] = value
//                        XCTAssertEqual(object[keyPath: keyPath], value)
//                    }
//                }

    //            test(\.boolCol, true, false)
    //            test(\.intCol, -1, 0, 1)
    //            test(\.int8Col, -1, 0, 1)
    //            test(\.int16Col, -1, 0, 1)
    //            test(\.int32Col, -1, 0, 1)
    //            test(\.int64Col, -1, 0, 1)
    //            test(\.floatCol, -Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, 20, 20.2)
    //            test(\.doubleCol, -Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, 20, 20.2, 16777217)
    //            test(\.stringCol, "", utf8TestString)
    //            test(\.binaryCol, data)
    //            test(\.dateCol, date)
    //            test(\.decimalCol, "inf", 1, 0, "0", -1, "-inf")
    //            test(\.objectIdCol, oid1, oid2)
    //            test(\.uuidCol, uuid)
    //            test(\.objectCol, ModernAllTypesObject(), nil)
    //            test(\.intEnumCol, .value1, .value2)
    //            test(\.stringEnumCol, .value1, .value2)

//                test(\.optBoolCol, true, false, nil)
//                test(\.optIntCol, Int.min, 0, Int.max, nil)
//                test(\.optInt8Col, Int8.min, 0, Int8.max, nil)
//                test(\.optInt16Col, Int16.min, 0, Int16.max, nil)
//                test(\.optInt32Col, Int32.min, 0, Int32.max, nil)
//                test(\.optInt64Col, Int64.min, 0, Int64.max, nil)
//                test(\.optFloatCol, -Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, 20, 20.2, nil)
//                test(\.optDoubleCol, -Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude, 20, 20.2, 16777217, nil)
//                test(\.optStringCol, "", utf8TestString, nil)
//                test(\.optBinaryCol, data, nil)
//                test(\.optDateCol, date, nil)
//                test(\.optDecimalCol, "inf", 1, 0, "0", -1, "-inf", nil)
//                test(\.optObjectIdCol, oid1, oid2, nil)
//                test(\.optUuidCol, uuid, nil)
//                test(\.optIntEnumCol, .value1, .value2, nil)
//                test(\.optStringEnumCol, .value1, .value2, nil)

//                test(\.anyCol, .none, .int(1), .bool(false), .float(2.2),
//                                   .double(3.3), .string("str"), .data(data), .date(date),
//                                   .object(ModernAllTypesObject()), .objectId(oid1),
//                                   .decimal128(5), .uuid(UUID()))
//
//                object.decimalCol = "nan"
//                XCTAssertTrue(object.decimalCol.isNaN)
//                object.optDecimalCol = "nan"
//                XCTAssertTrue(object.optDecimalCol!.isNaN)
//
//                object["optIntEnumCol"] = 10
//                XCTAssertNil(object.optIntEnumCol)
//
//                object.objectCol = ModernAllTypesObject()
//                if object.realm == nil {
//                    XCTAssertEqual(object.objectCol!.linkingObjects.count, 0)
//                } else {
//                    XCTAssertEqual(object.objectCol!.linkingObjects.count, 1)
//                    XCTAssertEqual(object.objectCol!.linkingObjects[0], object)
//                }
//            }
            all.arrayBool.append(objectsIn: [false, true])
            all.arrayInt.append(objectsIn: [Int.min, 0, Int.max])
            all.arrayInt8.append(objectsIn: [Int8.min, 0, Int8.max])
            all.arrayInt16.append(objectsIn: [Int16.min, 0, Int16.max])
            all.arrayInt32.append(objectsIn: [Int32.min, 0, Int32.max])
            all.arrayInt64.append(objectsIn: [Int64.min, 0, Int64.max])
            all.arrayFloat.append(objectsIn: [-Float.greatestFiniteMagnitude, 0, Float.greatestFiniteMagnitude])
            all.arrayDouble.append(objectsIn: [-Double.greatestFiniteMagnitude, 0, Double.greatestFiniteMagnitude])
            all.arrayString.append(objectsIn: ["a", "b", "c"])
            all.arrayBinary.append(objectsIn: ["a".data(using: String.Encoding.utf8)!])
            all.arrayDate.append(objectsIn: [Date(timeIntervalSince1970: 1)])
            all.arrayDecimal.append(objectsIn: [Decimal128(1), Decimal128(2)])
            all.arrayObjectId.append(objectsIn: [ObjectId("1234567890ab1234567890ab")])
            all.arrayUuid.append(objectsIn: [UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!])

            all.arrayOptBool.append(objectsIn: [false, true, nil])
            all.arrayOptInt.append(objectsIn: [Int.min, 0, Int.max, nil])
            all.arrayOptInt8.append(objectsIn: [Int8.min, 0, Int8.max, nil])
            all.arrayOptInt16.append(objectsIn: [Int16.min, 0, Int16.max, nil])
            all.arrayOptInt32.append(objectsIn: [Int32.min, 0, Int32.max, nil])
            all.arrayOptInt64.append(objectsIn: [Int64.min, 0, Int64.max, nil])
            all.arrayOptFloat.append(objectsIn: [-Float.greatestFiniteMagnitude, 0, Float.greatestFiniteMagnitude, nil])
            all.arrayOptDouble.append(objectsIn: [-Double.greatestFiniteMagnitude, 0, Double.greatestFiniteMagnitude, nil])
            all.arrayOptString.append(objectsIn: ["a", "b", "c", nil])
            all.arrayOptBinary.append(objectsIn: ["a".data(using: String.Encoding.utf8)!, nil])
            all.arrayOptDate.append(objectsIn: [Date(timeIntervalSince1970: 1), nil])
            all.arrayOptDecimal.append(objectsIn: [Decimal128(1), Decimal128(2), nil])
            all.arrayOptObjectId.append(objectsIn: [ObjectId("1234567890ab1234567890ab"), nil])
            all.arrayOptUuid.append(objectsIn: [UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!, nil])

            all.arrayAny.append(objectsIn: [.none, .int(1), .bool(false), .float(2.2), .double(3.3),
                                            .string("str"), .data("a".data(using: String.Encoding.utf8)!), .date(Date(timeIntervalSince1970: 1)), .object(ModernAllTypesObject()), .objectId(ObjectId("1234567890ab1234567890ab")),
                                            .decimal128(5), .uuid(UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)])

            all.setBool.insert(true)
            all.setInt.insert(1)
            all.setInt8.insert(1)
            all.setInt16.insert(1)
            all.setInt32.insert(1)
            all.setInt64.insert(1)
            all.setFloat.insert(1)
            all.setDouble.insert(1)
            all.setString.insert("1")
            all.setBinary.insert("1".data(using: String.Encoding.utf8)!)
            all.setDate.insert(Date(timeIntervalSince1970: 1))
            all.setDecimal.insert(1)
            all.setObjectId.insert(ObjectId("1234567890ab1234567890ab"))
            all.setAny.insert(objectsIn: [.none, .int(1), .bool(false), .float(2.2), .double(3.3),
                                          .string("str"), .data("a".data(using: String.Encoding.utf8)!), .date(Date(timeIntervalSince1970: 1)), .object(ModernAllTypesObject()), .objectId(ObjectId("1234567890ab1234567890ab")),
                                          .decimal128(5), .uuid(UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)])
            all.setUuid.insert(UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)

            all.setOptBool.insert(true)
            all.setOptInt.insert(1)
            all.setOptInt8.insert(1)
            all.setOptInt16.insert(1)
            all.setOptInt32.insert(1)
            all.setOptInt64.insert(1)
            all.setOptFloat.insert(1)
            all.setOptDouble.insert(1)
            all.setOptString.insert("1")
            all.setOptBinary.insert("1".data(using: String.Encoding.utf8)!)
            all.setOptDate.insert(Date(timeIntervalSince1970: 1))
            all.setOptDecimal.insert(1)
            all.setOptObjectId.insert(ObjectId("1234567890ab1234567890ab"))
            all.setOptUuid.insert(UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)
            
            all.mapBool["1"] = true
            all.mapInt["1"] = 1
            all.mapInt8["1"] = 1
            all.mapInt16["1"] = 1
            all.mapInt32["1"] = 1
            all.mapInt64["1"] = 1
            all.mapFloat["1"] = 1
            all.mapDouble["1"] = 1
            all.mapString["1"] = "1"
            all.mapBinary["1"] = "1".data(using: String.Encoding.utf8)!
            all.mapDate["1"] = Date(timeIntervalSince1970: 1)
            all.mapDecimal["1"] = 1
            all.mapObjectId["1"] = ObjectId("1234567890ab1234567890ab")
            ["1": AnyRealmValue.none, "2": .int(1), "3": .bool(false), "4": .float(2.2), "5": .double(3.3),
                          "6": .string("str"), "7": .data("a".data(using: String.Encoding.utf8)!), "8": .date(Date(timeIntervalSince1970: 1)), "9": .object(ModernAllTypesObject()), "10": .objectId(ObjectId("1234567890ab1234567890ab")),
             "11": .decimal128(5), "12": .uuid(UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)].forEach { all.mapAny[$0] = $1 }

            all.mapUuid["1"] = UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!

            all.mapOptBool["1"] = true
            all.mapOptInt["1"] = 1
            all.mapOptInt8["1"] = 1
            all.mapOptInt16["1"] = 1
            all.mapOptInt32["1"] = 1
            all.mapOptInt64["1"] = 1
            all.mapOptFloat["1"] = 1
            all.mapOptDouble["1"] = 1
            all.mapOptString["1"] = "1"
            all.mapOptBinary["1"] = "1".data(using: String.Encoding.utf8)!
            all.mapOptDate["1"] = Date(timeIntervalSince1970: 1)
            all.mapOptDecimal["1"] = 1
            all.mapOptObjectId["1"] = ObjectId("1234567890ab1234567890ab")
            all.mapOptUuid["1"] = UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!

        }
    }

    func testProjectionManualInit() {
        let realm = realmWithTestPath()
        let johnSnow = realm.objects(Person.self).filter("lastName == 'Snow'").first!
        // this step will happen under the hood
        let pp = PersonProjection(johnSnow)
        XCTAssertEqual(pp.homeCity, "Winterfell")
        XCTAssertEqual(pp.birthdayAsEpochtime, Date(timeIntervalSince1970: 10).timeIntervalSince1970)
        XCTAssertEqual(pp.firstFriendsName.first!, "Daenerys")
    }
    
    func testProjectionFromResult() {
        let realm = realmWithTestPath()
        let johnSnow: PersonProjection = realm.objects(PersonProjection.self).first!
        XCTAssertEqual(johnSnow.homeCity, "Winterfell")
        XCTAssertEqual(johnSnow.birthdayAsEpochtime, Date(timeIntervalSince1970: 10).timeIntervalSince1970)
        XCTAssertEqual(johnSnow.firstFriendsName.first!, "Daenerys")
    }
    
    func testProjectionFromResultFiltered() {
        let realm = realmWithTestPath()
        let johnSnow: PersonProjection = realm.objects(PersonProjection.self).filter("lastName == 'Snow'").first!

        XCTAssertEqual(johnSnow.homeCity, "Winterfell")
        XCTAssertEqual(johnSnow.birthdayAsEpochtime, Date(timeIntervalSince1970: 10).timeIntervalSince1970)
        XCTAssertEqual(johnSnow.firstFriendsName.first!, "Daenerys")
    }

    func testProjectionFromResultSorted() {
        let realm = realmWithTestPath()
        let dany: PersonProjection = realm.objects(PersonProjection.self).sorted(byKeyPath: "firstName").first!

        XCTAssertEqual(dany.homeCity, "King's Landing")
        XCTAssertEqual(dany.birthdayAsEpochtime, Date(timeIntervalSince1970: 0).timeIntervalSince1970)
        XCTAssertEqual(dany.firstFriendsName.first!, "John")
    }
    
    func testProjectionEquality() {
        let collection = realmWithTestPath().objects(PersonProjection.self)
        let left = collection.first!
        let right = collection.last!
        let anotherLeft = collection[0]
        
        XCTAssertNotEqual(left, right)
        XCTAssertEqual(left, anotherLeft)
    }
    
    func testProjectionsRealmShouldNotBeNil() {
        XCTAssertNotNil(realmWithTestPath().objects(PersonProjection.self).first!.realm)
    }

    func testProjectionFromResultSortedBirthday() {
        let realm = realmWithTestPath()
//        let dany: PersonProjection = realm.objects(PersonProjection.self).sorted(byKeyPath: "birthdayAsEpochtime").first!
        let dany: PersonProjection = realm.objects(PersonProjection.self).sorted(byKeyPath: "birthday").first!

        XCTAssertEqual(dany.homeCity, "King's Landing")
        XCTAssertEqual(dany.birthdayAsEpochtime, Date(timeIntervalSince1970: 0).timeIntervalSince1970)
        XCTAssertEqual(dany.firstFriendsName.first!, "John")
    }

    func testProjectionForAllRealmTypes() {
        let allTypesModel = realmWithTestPath().objects(AllTypesProjection.self).first!

        XCTAssertEqual(allTypesModel.pk, ObjectId("1234567890ab1234567890ab"))
        XCTAssertEqual(allTypesModel.ignored, 1)
        XCTAssertEqual(allTypesModel.boolCol, false)
        XCTAssertEqual(allTypesModel.intCol, 0)
        XCTAssertEqual(allTypesModel.int8Col, 1)
        XCTAssertEqual(allTypesModel.int16Col, 2)
        XCTAssertEqual(allTypesModel.int32Col, 3)
        XCTAssertEqual(allTypesModel.int64Col, 1)
        XCTAssertEqual(allTypesModel.floatCol, 5.0)
        XCTAssertEqual(allTypesModel.doubleCol, 6.0)
        XCTAssertEqual(allTypesModel.stringCol, "")
        XCTAssertEqual(allTypesModel.binaryCol, "1".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(allTypesModel.dateCol, Date(timeIntervalSince1970: 1))
        XCTAssertEqual(allTypesModel.decimalCol, 1)
        XCTAssertEqual(allTypesModel.objectIdCol, ObjectId("1234567890ab1234567890ab"))
        XCTAssertEqual(allTypesModel.objectCol, self)
        XCTAssertEqual(allTypesModel.arrayCol.count, 7)
        XCTAssertEqual(allTypesModel.setCol.count, 7)
        XCTAssertEqual(allTypesModel.anyCol, AnyRealmValue.int(1))
        XCTAssertEqual(allTypesModel.uuidCol, UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)
        XCTAssertEqual(allTypesModel.intEnumCol, ModernIntEnum.value1)
        XCTAssertEqual(allTypesModel.stringEnumCol, ModernStringEnum.value1)

        XCTAssertEqual(allTypesModel.optIntCol, 1)
        XCTAssertEqual(allTypesModel.optInt8Col, 1)
        XCTAssertEqual(allTypesModel.optInt16Col, 1)
        XCTAssertEqual(allTypesModel.optInt32Col, 1)
        XCTAssertEqual(allTypesModel.optInt64Col, 1)
        XCTAssertEqual(allTypesModel.optFloatCol, 1)
        XCTAssertEqual(allTypesModel.optDoubleCol, 1)
        XCTAssertEqual(allTypesModel.optBoolCol, true)
        XCTAssertEqual(allTypesModel.optStringCol, "1")
        XCTAssertEqual(allTypesModel.optBinaryCol, "1".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(allTypesModel.optDateCol, Date(timeIntervalSinceReferenceDate: 2))
        XCTAssertEqual(allTypesModel.optDecimalCol, 1)
        XCTAssertEqual(allTypesModel.optObjectIdCol, ObjectId("1234567890ab1234567890ab"))
        XCTAssertEqual(allTypesModel.optUuidCol, UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)
        XCTAssertEqual(allTypesModel.optIntEnumCol, ModernIntEnum.value1)
        XCTAssertEqual(allTypesModel.optStringEnumCol, ModernStringEnum.value1)

        XCTAssertEqual(allTypesModel.arrayBool.first!, true)
        XCTAssertEqual(allTypesModel.arrayInt.first!, 1)
        XCTAssertEqual(allTypesModel.arrayInt8.first!, 1)
        XCTAssertEqual(allTypesModel.arrayInt16.first!, 1)
        XCTAssertEqual(allTypesModel.arrayInt32.first!, 1)
        XCTAssertEqual(allTypesModel.arrayInt64.first!, 1)
        XCTAssertEqual(allTypesModel.arrayFloat.first!, 1)
        XCTAssertEqual(allTypesModel.arrayDouble.first!, 1)
        XCTAssertEqual(allTypesModel.arrayString.first!, "1")
        XCTAssertEqual(allTypesModel.arrayBinary.first!, "1".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(allTypesModel.arrayDate.first!, Date(timeIntervalSinceReferenceDate: 2))
        XCTAssertEqual(allTypesModel.arrayDecimal.first!, 1)
        XCTAssertEqual(allTypesModel.arrayObjectId.first!, ObjectId("1234567890ab1234567890ab"))
        XCTAssertEqual(allTypesModel.arrayAny.count, 7)
        XCTAssertEqual(allTypesModel.arrayUuid.first!, UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)

        XCTAssertEqual(allTypesModel.arrayOptBool.first!, true)
        XCTAssertEqual(allTypesModel.arrayOptInt.first!, 1)
        XCTAssertEqual(allTypesModel.arrayOptInt8.first!, 1)
        XCTAssertEqual(allTypesModel.arrayOptInt16.first!, 1)
        XCTAssertEqual(allTypesModel.arrayOptInt32.first!, 1)
        XCTAssertEqual(allTypesModel.arrayOptInt64.first!, 1)
        XCTAssertEqual(allTypesModel.arrayOptFloat.first!, 1)
        XCTAssertEqual(allTypesModel.arrayOptDouble.first!, 1)
        XCTAssertEqual(allTypesModel.arrayOptString.first!, "1")
        XCTAssertEqual(allTypesModel.arrayOptBinary.first!, "1".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(allTypesModel.arrayOptDate.first!, Date(timeIntervalSinceReferenceDate: 2))
        XCTAssertEqual(allTypesModel.arrayOptDecimal.first!, 1)
        XCTAssertEqual(allTypesModel.arrayOptObjectId.first!, ObjectId("1234567890ab1234567890ab"))
        XCTAssertEqual(allTypesModel.arrayOptUuid.first!, UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)

        XCTAssertEqual(allTypesModel.setBool.first!, true)
        XCTAssertEqual(allTypesModel.setInt.first!, 1)
        XCTAssertEqual(allTypesModel.setInt8.first!, 1)
        XCTAssertEqual(allTypesModel.setInt16.first!, 1)
        XCTAssertEqual(allTypesModel.setInt32.first!, 1)
        XCTAssertEqual(allTypesModel.setInt64.first!, 1)
        XCTAssertEqual(allTypesModel.setFloat.first!, 1)
        XCTAssertEqual(allTypesModel.setDouble.first!, 1)
        XCTAssertEqual(allTypesModel.setString.first!, "1")
        XCTAssertEqual(allTypesModel.setBinary.first!, "1".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(allTypesModel.setDate.first!, Date(timeIntervalSince1970: 1))
        XCTAssertEqual(allTypesModel.setDecimal.first!, 1)
        XCTAssertEqual(allTypesModel.setObjectId.first!, ObjectId("1234567890ab1234567890ab"))
        XCTAssertEqual(allTypesModel.setAny.count, 7)
        XCTAssertEqual(allTypesModel.setUuid.first!, UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)

        XCTAssertEqual(allTypesModel.setOptBool.first!, true)
        XCTAssertEqual(allTypesModel.setOptInt.first!, 1)
        XCTAssertEqual(allTypesModel.setOptInt8.first!, 1)
        XCTAssertEqual(allTypesModel.setOptInt16.first!, 1)
        XCTAssertEqual(allTypesModel.setOptInt32.first!, 1)
        XCTAssertEqual(allTypesModel.setOptInt64.first!, 1)
        XCTAssertEqual(allTypesModel.setOptFloat.first!, 1)
        XCTAssertEqual(allTypesModel.setOptDouble.first!, 1)
        XCTAssertEqual(allTypesModel.setOptString.first!, "1")
        XCTAssertEqual(allTypesModel.setOptBinary.first!, "1".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(allTypesModel.setOptDate.first!, Date(timeIntervalSince1970: 1))
        XCTAssertEqual(allTypesModel.setOptDecimal.first!, 1)
        XCTAssertEqual(allTypesModel.setOptObjectId.first!, ObjectId("1234567890ab1234567890ab"))
        XCTAssertEqual(allTypesModel.setOptUuid.first!, UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)

        XCTAssertEqual(allTypesModel.mapBool["1"]!, true)
        XCTAssertEqual(allTypesModel.mapInt["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapInt8["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapInt16["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapInt32["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapInt64["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapFloat["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapDouble["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapString["1"]!, "1")
        XCTAssertEqual(allTypesModel.mapBinary["1"]!, "1".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(allTypesModel.mapDate["1"]!, Date(timeIntervalSince1970: 1))
        XCTAssertEqual(allTypesModel.mapDecimal["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapObjectId["1"]!, ObjectId("1234567890ab1234567890ab"))
        XCTAssertEqual(allTypesModel.mapAny.count, 7)
        XCTAssertEqual(allTypesModel.mapUuid["1"]!, UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)

        XCTAssertEqual(allTypesModel.mapOptBool["1"]!, true)
        XCTAssertEqual(allTypesModel.mapOptInt["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapOptInt8["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapOptInt16["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapOptInt32["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapOptInt64["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapOptFloat["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapOptDouble["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapOptString["1"]!, "1")
        XCTAssertEqual(allTypesModel.mapOptBinary["1"]!, "1".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(allTypesModel.mapOptDate["1"]!, Date(timeIntervalSince1970: 1))
        XCTAssertEqual(allTypesModel.mapOptDecimal["1"]!, 1)
        XCTAssertEqual(allTypesModel.mapOptObjectId["1"]!, ObjectId("1234567890ab1234567890ab"))
        XCTAssertEqual(allTypesModel.mapOptUuid["1"]!, UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!)

        XCTAssertEqual(allTypesModel.linkingObjects.count, 7)
        
        
        
    }
    
    func testProjectioShouldNotChangeValue() {
        let realm = realmWithTestPath()
        let johnOriginal = realm.objects(Person.self).filter("lastName == 'Snow'").first!
        let john = realm.objects(PersonProjection.self).filter("lastName == 'Snow'").first!
        
        XCTAssertEqual(johnOriginal.lastName, john.lastName)
        
        try! realm.write {
            johnOriginal.lastName = "Targaryen"
        }
        
        XCTAssertEqual(johnOriginal.lastName, "Targaryen")
        XCTAssertEqual(john.lastName, "Snow")
    }
}
