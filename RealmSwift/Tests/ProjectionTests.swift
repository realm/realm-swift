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

    func assertSetEquals<T: RealmCollectionValue>(_ set: MutableSet<T>, _ expected: Array<T>) {
        XCTAssertEqual(set.count, Set(expected).count)
        XCTAssertEqual(Set(set), Set(expected))
    }

    func assertEquivalent(_ actual: AnyRealmCollection<ModernAllTypesObject>,
                          _ expected: Array<ModernAllTypesObject>,
                          expectedShouldBeCopy: Bool) {
        XCTAssertEqual(actual.count, expected.count)
        for obj in expected {
            if expectedShouldBeCopy {
                XCTAssertTrue(actual.contains { $0.pk == obj.pk })
            } else {
                XCTAssertTrue(actual.contains(obj))
            }
        }
    }

    func assertMapEquals<T: RealmCollectionValue>(_ actual: Map<String, T>, _ expected: Dictionary<String, T>) {
        XCTAssertEqual(actual.count, expected.count)
        for (key, value) in expected {
            XCTAssertEqual(actual[key], value)
        }
    }

    let allTypeValues = [
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

            "arrayBool": [true, false] as [Bool],
            "arrayInt": [1, 1, 2, 3] as [Int],
            "arrayInt8": [1, 2, 3, 1] as [Int8],
            "arrayInt16": [1, 2, 3, 1] as [Int16],
            "arrayInt32": [1, 2, 3, 1] as [Int32],
            "arrayInt64": [1, 2, 3, 1] as [Int64],
            "arrayFloat": [1 as Float, 2 as Float, 3 as Float, 1 as Float],
            "arrayDouble": [1 as Double, 2 as Double, 3 as Double, 1 as Double],
            "arrayString": ["a", "b", "c"] as [String],
            "arrayBinary": ["a".data(using: .utf8)!] as [Data],
            "arrayDate": [Date(), Date()] as [Date],
            "arrayDecimal": [1 as Decimal128, 2 as Decimal128],
            "arrayObjectId": [ObjectId.generate(), ObjectId.generate()],
            "arrayAny": [.none, .int(1), .string("a"), .none] as [AnyRealmValue],
            "arrayUuid": [UUID(), UUID(), UUID()],

            "arrayOptBool": [true, false, nil] as [Bool?],
            "arrayOptInt": [1, 1, 2, 3, nil] as [Int?],
            "arrayOptInt8": [1, 2, 3, 1, nil] as [Int8?],
            "arrayOptInt16": [1, 2, 3, 1, nil] as [Int16?],
            "arrayOptInt32": [1, 2, 3, 1, nil] as [Int32?],
            "arrayOptInt64": [1, 2, 3, 1, nil] as [Int64?],
            "arrayOptFloat": [1 as Float, 2 as Float, 3 as Float, 1 as Float, nil],
            "arrayOptDouble": [1 as Double, 2 as Double, 3 as Double, 1 as Double, nil],
            "arrayOptString": ["a", "b", "c", nil],
            "arrayOptBinary": ["a".data(using: .utf8)!, nil],
            "arrayOptDate": [Date(), Date(), nil],
            "arrayOptDecimal": [1 as Decimal128, 2 as Decimal128, nil],
            "arrayOptObjectId": [ObjectId.generate(), ObjectId.generate(), nil],
            "arrayOptUuid": [UUID(), UUID(), UUID(), nil],

            "setBool": [true, false] as [Bool],
            "setInt": [1, 1, 2, 3] as [Int],
            "setInt8": [1, 2, 3, 1] as [Int8],
            "setInt16": [1, 2, 3, 1] as [Int16],
            "setInt32": [1, 2, 3, 1] as [Int32],
            "setInt64": [1, 2, 3, 1] as [Int64],
            "setFloat": [1 as Float, 2 as Float, 3 as Float, 1 as Float],
            "setDouble": [1 as Double, 2 as Double, 3 as Double, 1 as Double],
            "setString": ["a", "b", "c"] as [String],
            "setBinary": ["a".data(using: .utf8)!] as [Data],
            "setDate": [Date(), Date()] as [Date],
            "setDecimal": [1 as Decimal128, 2 as Decimal128],
            "setObjectId": [ObjectId.generate(), ObjectId.generate()],
            "setAny": [.none, .int(1), .string("a"), .none] as [AnyRealmValue],
            "setUuid": [UUID(), UUID(), UUID()],

            "setOptBool": [true, false, nil] as [Bool?],
            "setOptInt": [1, 1, 2, 3, nil] as [Int?],
            "setOptInt8": [1, 2, 3, 1, nil] as [Int8?],
            "setOptInt16": [1, 2, 3, 1, nil] as [Int16?],
            "setOptInt32": [1, 2, 3, 1, nil] as [Int32?],
            "setOptInt64": [1, 2, 3, 1, nil] as [Int64?],
            "setOptFloat": [1 as Float, 2 as Float, 3 as Float, 1 as Float, nil],
            "setOptDouble": [1 as Double, 2 as Double, 3 as Double, 1 as Double, nil],
            "setOptString": ["a", "b", "c", nil],
            "setOptBinary": ["a".data(using: .utf8)!, nil],
            "setOptDate": [Date(), Date(), nil],
            "setOptDecimal": [1 as Decimal128, 2 as Decimal128, nil],
            "setOptObjectId": [ObjectId.generate(), ObjectId.generate(), nil],
            "setOptUuid": [UUID(), UUID(), UUID(), nil],

            "mapBool": ["1": true, "2": false] as [String: Bool],
            "mapInt": ["1": 1, "2": 1, "3": 2, "4": 3] as [String: Int],
            "mapInt8": ["1": 1, "2": 2, "3": 3, "4": 1] as [String: Int8],
            "mapInt16": ["1": 1, "2": 2, "3": 3, "4": 1] as [String: Int16],
            "mapInt32": ["1": 1, "2": 2, "3": 3, "4": 1] as [String: Int32],
            "mapInt64": ["1": 1, "2": 2, "3": 3, "4": 1] as [String: Int64],
            "mapFloat": ["1": 1 as Float, "2": 2 as Float, "3": 3 as Float, "4": 1 as Float],
            "mapDouble": ["1": 1 as Double, "2": 2 as Double, "3": 3 as Double, "4": 1 as Double],
            "mapString": ["1": "a", "2": "b", "3": "c"] as [String: String],
            "mapBinary": ["1": "a".data(using: .utf8)!] as [String: Data],
            "mapDate": ["1": Date(), "2": Date()] as [String: Date],
            "mapDecimal": ["1": 1 as Decimal128, "2": 2 as Decimal128],
            "mapObjectId": ["1": ObjectId.generate(), "2": ObjectId.generate()],
            "mapAny": ["1": .none, "2": .int(1), "3": .string("a"), "4": .none] as [String: AnyRealmValue],
            "mapUuid": ["1": UUID(), "2": UUID(), "3": UUID()],

            "mapOptBool": ["1": true, "2": false, "3": nil] as [String: Bool?],
            "mapOptInt": ["1": 1, "2": 1, "3": 2, "4": 3, "5": nil] as [String: Int?],
            "mapOptInt8": ["1": 1, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int8?],
            "mapOptInt16": ["1": 1, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int16?],
            "mapOptInt32": ["1": 1, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int32?],
            "mapOptInt64": ["1": 1, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int64?],
            "mapOptFloat": ["1": 1 as Float, "2": 2 as Float, "3": 3 as Float, "4": 1 as Float, "5": nil],
            "mapOptDouble": ["1": 1 as Double, "2": 2 as Double, "3": 3 as Double, "4": 1 as Double, "5": nil],
            "mapOptString": ["1": "a", "2": "b", "3": "c", "4": nil],
            "mapOptBinary": ["1": "a".data(using: .utf8)!, "2": nil],
            "mapOptDate": ["1": Date(), "2": Date(), "3": nil],
            "mapOptDecimal": ["1": 1 as Decimal128, "2": 2 as Decimal128, "3": nil],
            "mapOptObjectId": ["1": ObjectId.generate(), "2": ObjectId.generate(), "3": nil],
            "mapOptUuid": ["1": UUID(), "2": UUID(), "3": UUID(), "4": nil],
    ] as [String : Any]

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

            realm.create(ModernAllTypesObject.self, value: allTypeValues)
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

        XCTAssertEqual(allTypesModel.boolCol, allTypeValues["boolCol"] as! Bool)
        XCTAssertEqual(allTypesModel.intCol, allTypeValues["intCol"] as! Int)
        XCTAssertEqual(allTypesModel.int8Col, allTypeValues["int8Col"] as! Int8)
        XCTAssertEqual(allTypesModel.int16Col, allTypeValues["int16Col"] as! Int16)
        XCTAssertEqual(allTypesModel.int32Col, allTypeValues["int32Col"] as! Int32)
        XCTAssertEqual(allTypesModel.int64Col, allTypeValues["int64Col"] as! Int64)
        XCTAssertEqual(allTypesModel.floatCol, allTypeValues["floatCol"] as! Float)
        XCTAssertEqual(allTypesModel.doubleCol, allTypeValues["doubleCol"] as! Double)
        XCTAssertEqual(allTypesModel.stringCol, allTypeValues["stringCol"] as! String)
        XCTAssertEqual(allTypesModel.binaryCol, allTypeValues["binaryCol"] as! Data)
        XCTAssertEqual(allTypesModel.dateCol, allTypeValues["dateCol"] as! Date)
        XCTAssertEqual(allTypesModel.decimalCol, allTypeValues["decimalCol"] as! Decimal128)
        XCTAssertEqual(allTypesModel.objectIdCol, allTypeValues["objectIdCol"] as! ObjectId)
        XCTAssertEqual(allTypesModel.objectCol!.pk, (allTypeValues["objectCol"] as! ModernAllTypesObject?)!.pk)
        assertEquivalent(AnyRealmCollection(allTypesModel.arrayCol),
                         allTypeValues["arrayCol"] as! [ModernAllTypesObject],
                         expectedShouldBeCopy: true)
        assertEquivalent(AnyRealmCollection(allTypesModel.setCol),
                         allTypeValues["setCol"] as! [ModernAllTypesObject],
                         expectedShouldBeCopy: true)
        XCTAssertEqual(allTypesModel.anyCol, allTypeValues["anyCol"] as! AnyRealmValue)
        XCTAssertEqual(allTypesModel.uuidCol, allTypeValues["uuidCol"] as! UUID)
        XCTAssertEqual(allTypesModel.intEnumCol, allTypeValues["intEnumCol"] as! ModernIntEnum)
        XCTAssertEqual(allTypesModel.stringEnumCol, allTypeValues["stringEnumCol"] as! ModernStringEnum)

        XCTAssertEqual(allTypesModel.optBoolCol, allTypeValues["optBoolCol"] as! Bool?)
        XCTAssertEqual(allTypesModel.optIntCol, allTypeValues["optIntCol"] as! Int?)
        XCTAssertEqual(allTypesModel.optInt8Col, allTypeValues["optInt8Col"] as! Int8?)
        XCTAssertEqual(allTypesModel.optInt16Col, allTypeValues["optInt16Col"] as! Int16?)
        XCTAssertEqual(allTypesModel.optInt32Col, allTypeValues["optInt32Col"] as! Int32?)
        XCTAssertEqual(allTypesModel.optInt64Col, allTypeValues["optInt64Col"] as! Int64?)
        XCTAssertEqual(allTypesModel.optFloatCol, allTypeValues["optFloatCol"] as! Float?)
        XCTAssertEqual(allTypesModel.optDoubleCol, allTypeValues["optDoubleCol"] as! Double?)
        XCTAssertEqual(allTypesModel.optStringCol, allTypeValues["optStringCol"] as! String?)
        XCTAssertEqual(allTypesModel.optBinaryCol, allTypeValues["optBinaryCol"] as! Data?)
        XCTAssertEqual(allTypesModel.optDateCol, allTypeValues["optDateCol"] as! Date?)
        XCTAssertEqual(allTypesModel.optDecimalCol, allTypeValues["optDecimalCol"] as! Decimal128?)
        XCTAssertEqual(allTypesModel.optObjectIdCol, allTypeValues["optObjectIdCol"] as! ObjectId?)
        XCTAssertEqual(allTypesModel.optUuidCol, allTypeValues["optUuidCol"] as! UUID?)
        XCTAssertEqual(allTypesModel.optIntEnumCol, allTypeValues["optIntEnumCol"] as! ModernIntEnum?)
        XCTAssertEqual(allTypesModel.optStringEnumCol, allTypeValues["optStringEnumCol"] as! ModernStringEnum?)

        XCTAssertEqual(Array(allTypesModel.arrayBool), allTypeValues["arrayBool"] as! [Bool])
        XCTAssertEqual(Array(allTypesModel.arrayInt), allTypeValues["arrayInt"] as! [Int])
        XCTAssertEqual(Array(allTypesModel.arrayInt8), allTypeValues["arrayInt8"] as! [Int8])
        XCTAssertEqual(Array(allTypesModel.arrayInt16), allTypeValues["arrayInt16"] as! [Int16])
        XCTAssertEqual(Array(allTypesModel.arrayInt32), allTypeValues["arrayInt32"] as! [Int32])
        XCTAssertEqual(Array(allTypesModel.arrayInt64), allTypeValues["arrayInt64"] as! [Int64])
        XCTAssertEqual(Array(allTypesModel.arrayFloat), allTypeValues["arrayFloat"] as! [Float])
        XCTAssertEqual(Array(allTypesModel.arrayDouble), allTypeValues["arrayDouble"] as! [Double])
        XCTAssertEqual(Array(allTypesModel.arrayString), allTypeValues["arrayString"] as! [String])
        XCTAssertEqual(Array(allTypesModel.arrayBinary), allTypeValues["arrayBinary"] as! [Data])
        XCTAssertEqual(Array(allTypesModel.arrayDate), allTypeValues["arrayDate"] as! [Date])
        XCTAssertEqual(Array(allTypesModel.arrayDecimal), allTypeValues["arrayDecimal"] as! [Decimal128])
        XCTAssertEqual(Array(allTypesModel.arrayObjectId), allTypeValues["arrayObjectId"] as! [ObjectId])
        XCTAssertEqual(Array(allTypesModel.arrayAny), allTypeValues["arrayAny"] as! [AnyRealmValue])
        XCTAssertEqual(Array(allTypesModel.arrayUuid), allTypeValues["arrayUuid"] as! [UUID])

        XCTAssertEqual(Array(allTypesModel.arrayOptBool), allTypeValues["arrayOptBool"] as! [Bool?])
        XCTAssertEqual(Array(allTypesModel.arrayOptInt), allTypeValues["arrayOptInt"] as! [Int?])
        XCTAssertEqual(Array(allTypesModel.arrayOptInt8), allTypeValues["arrayOptInt8"] as! [Int8?])
        XCTAssertEqual(Array(allTypesModel.arrayOptInt16), allTypeValues["arrayOptInt16"] as! [Int16?])
        XCTAssertEqual(Array(allTypesModel.arrayOptInt32), allTypeValues["arrayOptInt32"] as! [Int32?])
        XCTAssertEqual(Array(allTypesModel.arrayOptInt64), allTypeValues["arrayOptInt64"] as! [Int64?])
        XCTAssertEqual(Array(allTypesModel.arrayOptFloat), allTypeValues["arrayOptFloat"] as! [Float?])
        XCTAssertEqual(Array(allTypesModel.arrayOptDouble), allTypeValues["arrayOptDouble"] as! [Double?])
        XCTAssertEqual(Array(allTypesModel.arrayOptString), allTypeValues["arrayOptString"] as! [String?])
        XCTAssertEqual(Array(allTypesModel.arrayOptBinary), allTypeValues["arrayOptBinary"] as! [Data?])
        XCTAssertEqual(Array(allTypesModel.arrayOptDate), allTypeValues["arrayOptDate"] as! [Date?])
        XCTAssertEqual(Array(allTypesModel.arrayOptDecimal), allTypeValues["arrayOptDecimal"] as! [Decimal128?])
        XCTAssertEqual(Array(allTypesModel.arrayOptObjectId), allTypeValues["arrayOptObjectId"] as! [ObjectId?])
        XCTAssertEqual(Array(allTypesModel.arrayOptUuid), allTypeValues["arrayOptUuid"] as! [UUID?])

        assertSetEquals(allTypesModel.setBool, allTypeValues["setBool"] as! [Bool])
        assertSetEquals(allTypesModel.setInt, allTypeValues["setInt"] as! [Int])
        assertSetEquals(allTypesModel.setInt8, allTypeValues["setInt8"] as! [Int8])
        assertSetEquals(allTypesModel.setInt16, allTypeValues["setInt16"] as! [Int16])
        assertSetEquals(allTypesModel.setInt32, allTypeValues["setInt32"] as! [Int32])
        assertSetEquals(allTypesModel.setInt64, allTypeValues["setInt64"] as! [Int64])
        assertSetEquals(allTypesModel.setFloat, allTypeValues["setFloat"] as! [Float])
        assertSetEquals(allTypesModel.setDouble, allTypeValues["setDouble"] as! [Double])
        assertSetEquals(allTypesModel.setString, allTypeValues["setString"] as! [String])
        assertSetEquals(allTypesModel.setBinary, allTypeValues["setBinary"] as! [Data])
        assertSetEquals(allTypesModel.setDate, allTypeValues["setDate"] as! [Date])
        assertSetEquals(allTypesModel.setDecimal, allTypeValues["setDecimal"] as! [Decimal128])
        assertSetEquals(allTypesModel.setObjectId, allTypeValues["setObjectId"] as! [ObjectId])
        assertSetEquals(allTypesModel.setAny, allTypeValues["setAny"] as! [AnyRealmValue])
        assertSetEquals(allTypesModel.setUuid, allTypeValues["setUuid"] as! [UUID])

        assertSetEquals(allTypesModel.setOptBool, allTypeValues["setOptBool"] as! [Bool?])
        assertSetEquals(allTypesModel.setOptInt, allTypeValues["setOptInt"] as! [Int?])
        assertSetEquals(allTypesModel.setOptInt8, allTypeValues["setOptInt8"] as! [Int8?])
        assertSetEquals(allTypesModel.setOptInt16, allTypeValues["setOptInt16"] as! [Int16?])
        assertSetEquals(allTypesModel.setOptInt32, allTypeValues["setOptInt32"] as! [Int32?])
        assertSetEquals(allTypesModel.setOptInt64, allTypeValues["setOptInt64"] as! [Int64?])
        assertSetEquals(allTypesModel.setOptFloat, allTypeValues["setOptFloat"] as! [Float?])
        assertSetEquals(allTypesModel.setOptDouble, allTypeValues["setOptDouble"] as! [Double?])
        assertSetEquals(allTypesModel.setOptString, allTypeValues["setOptString"] as! [String?])
        assertSetEquals(allTypesModel.setOptBinary, allTypeValues["setOptBinary"] as! [Data?])
        assertSetEquals(allTypesModel.setOptDate, allTypeValues["setOptDate"] as! [Date?])
        assertSetEquals(allTypesModel.setOptDecimal, allTypeValues["setOptDecimal"] as! [Decimal128?])
        assertSetEquals(allTypesModel.setOptObjectId, allTypeValues["setOptObjectId"] as! [ObjectId?])
        assertSetEquals(allTypesModel.setOptUuid, allTypeValues["setOptUuid"] as! [UUID?])

        assertMapEquals(allTypesModel.mapBool, allTypeValues["mapBool"] as! [String: Bool])
        assertMapEquals(allTypesModel.mapInt, allTypeValues["mapInt"] as! [String: Int])
        assertMapEquals(allTypesModel.mapInt8, allTypeValues["mapInt8"] as! [String: Int8])
        assertMapEquals(allTypesModel.mapInt16, allTypeValues["mapInt16"] as! [String: Int16])
        assertMapEquals(allTypesModel.mapInt32, allTypeValues["mapInt32"] as! [String: Int32])
        assertMapEquals(allTypesModel.mapInt64, allTypeValues["mapInt64"] as! [String: Int64])
        assertMapEquals(allTypesModel.mapFloat, allTypeValues["mapFloat"] as! [String: Float])
        assertMapEquals(allTypesModel.mapDouble, allTypeValues["mapDouble"] as! [String: Double])
        assertMapEquals(allTypesModel.mapString, allTypeValues["mapString"] as! [String: String])
        assertMapEquals(allTypesModel.mapBinary, allTypeValues["mapBinary"] as! [String: Data])
        assertMapEquals(allTypesModel.mapDate, allTypeValues["mapDate"] as! [String: Date])
        assertMapEquals(allTypesModel.mapDecimal, allTypeValues["mapDecimal"] as! [String: Decimal128])
        assertMapEquals(allTypesModel.mapObjectId, allTypeValues["mapObjectId"] as! [String: ObjectId])
        assertMapEquals(allTypesModel.mapAny, allTypeValues["mapAny"] as! [String: AnyRealmValue])
        assertMapEquals(allTypesModel.mapUuid, allTypeValues["mapUuid"] as! [String: UUID])

        assertMapEquals(allTypesModel.mapOptBool, allTypeValues["mapOptBool"] as! [String: Bool?])
        assertMapEquals(allTypesModel.mapOptInt, allTypeValues["mapOptInt"] as! [String: Int?])
        assertMapEquals(allTypesModel.mapOptInt8, allTypeValues["mapOptInt8"] as! [String: Int8?])
        assertMapEquals(allTypesModel.mapOptInt16, allTypeValues["mapOptInt16"] as! [String: Int16?])
        assertMapEquals(allTypesModel.mapOptInt32, allTypeValues["mapOptInt32"] as! [String: Int32?])
        assertMapEquals(allTypesModel.mapOptInt64, allTypeValues["mapOptInt64"] as! [String: Int64?])
        assertMapEquals(allTypesModel.mapOptFloat, allTypeValues["mapOptFloat"] as! [String: Float?])
        assertMapEquals(allTypesModel.mapOptDouble, allTypeValues["mapOptDouble"] as! [String: Double?])
        assertMapEquals(allTypesModel.mapOptString, allTypeValues["mapOptString"] as! [String: String?])
        assertMapEquals(allTypesModel.mapOptBinary, allTypeValues["mapOptBinary"] as! [String: Data?])
        assertMapEquals(allTypesModel.mapOptDate, allTypeValues["mapOptDate"] as! [String: Date?])
        assertMapEquals(allTypesModel.mapOptDecimal, allTypeValues["mapOptDecimal"] as! [String: Decimal128?])
        assertMapEquals(allTypesModel.mapOptObjectId, allTypeValues["mapOptObjectId"] as! [String: ObjectId?])
        assertMapEquals(allTypesModel.mapOptUuid, allTypeValues["mapOptUuid"] as! [String: UUID?])
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
    
    var changeDictionary: [NSKeyValueChangeKey: Any]?

    class CompoundListObserver: NSObject {
        let key: String
        let deletions: [Int]
        let insertions: [Int]
        public var count = 0

        init(_ key: String, _ deletions: [Int], _ insertions: [Int]) {
            self.key = key
            self.deletions = deletions
            self.insertions = insertions
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                   change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            XCTAssertEqual(keyPath, key)
            XCTAssertNotNil(object)
            XCTAssertNotNil(change)
            guard let change = change else { return }
            XCTAssertNotNil(change[.kindKey])
            guard let kind = (change[.kindKey] as? UInt).map(NSKeyValueChange.init(rawValue:)) else { return }
            if count == 0 {
                XCTAssertEqual(kind, .removal)
                XCTAssertEqual(Array(change[.indexesKey]! as! NSIndexSet), deletions)
            } else if count == 1 {
                XCTAssertEqual(kind, .insertion)
                XCTAssertEqual(Array(change[.indexesKey]! as! NSIndexSet), insertions)
            } else {
                XCTFail("too many notifications")
            }
            count += 1
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func observeChange<T: Equatable, P: Projection>(_ obj: Object, _ obs: P, _ key: String, _ old: T?, _ new: T?,
                                     fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        let kvoOptions: NSKeyValueObservingOptions = [.old, .new]
        obs.addObserver(self, forKeyPath: key, options: kvoOptions, context: nil)
        block()
        obs.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: (fileName), line: lineNumber)
        guard changeDictionary != nil else { return }

        let actualOld = changeDictionary![.oldKey] as? T
        let actualNew = changeDictionary![.newKey] as? T

        XCTAssert(old == actualOld,
                  "Old value: expected \(String(describing: old)), got \(String(describing: actualOld))",
                  file: (fileName), line: lineNumber)
        XCTAssert(new == actualNew,
                  "New value: expected \(String(describing: new)), got \(String(describing: actualNew))",
                  file: (fileName), line: lineNumber)

        changeDictionary = nil
    }

    func observeListChange<T: Projection>(_ obs: T, _ key: String, _ kind: NSKeyValueChange,
                           _ indexes: NSIndexSet = NSIndexSet(index: 0),
                           fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        obs.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
        block()
        obs.removeObserver(self, forKeyPath: key)
        XCTAssert(changeDictionary != nil, "Did not get a notification", file: (fileName), line: lineNumber)
        guard changeDictionary != nil else { return }

        let actualKind = NSKeyValueChange(rawValue: (changeDictionary![NSKeyValueChangeKey.kindKey] as! NSNumber).uintValue)!
        let actualIndexes = changeDictionary![NSKeyValueChangeKey.indexesKey]! as! NSIndexSet
        XCTAssert(actualKind == kind, "Change kind: expected \(kind), got \(actualKind)", file: (fileName),
            line: lineNumber)
        XCTAssert(actualIndexes.isEqual(indexes), "Changed indexes: expected \(indexes), got \(actualIndexes)",
                  file: (fileName), line: lineNumber)

        changeDictionary = nil
    }
    
    func observeCompoundListChange<T: Projection>(_ obj: NSObject, _ obs: T, _ key: String,
                                                  _ values: NSArray, deletions: [Int], insertions: [Int]) {
        let observer = CompoundListObserver(key, deletions, insertions)
        if deletions.count == 0 {
            observer.count = 1
        }

        obs.addObserver(observer, forKeyPath: key, options: [.old, .new], context: nil)
        obj.setValue(values, forKey: key)
        obs.removeObserver(observer, forKeyPath: key)

        if insertions.count > 0 {
            XCTAssertEqual(observer.count, 2)
        } else {
            XCTAssertEqual(observer.count, 1)
        }
    }

    func observeSetChange<T: Projection>(_ obs: T, _ key: String,
                                         fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        obs.addObserver(self, forKeyPath: key, options: [], context: nil)
        block()
        obs.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: (fileName), line: lineNumber)
        guard changeDictionary != nil else { return }
    }

    func testAllPropertyTypesCNotifications() {
//        let (obj, obs) = getObject(ModernAllTypesObject())
        let obj = realmWithTestPath().objects(ModernAllTypesObject.self).first!
        let obs = realmWithTestPath().objects(AllTypesProjection.self).first!

        let oldData = obj.binaryCol
        let data = "abc".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let oldDate = obj.dateCol
        let date = Date(timeIntervalSince1970: 1)
        let oldDecimal = obj.decimalCol
        let decimal = Decimal128(number: 2)
        let oldObjectId = obj.objectIdCol
        let objectId = ObjectId()
        let oldUUID = obj.uuidCol
        let uuid = UUID()

        realmWithTestPath().beginWrite()
        observeChange(obj, obs, "boolCol", false, true) { obj.boolCol = true }
        observeChange(obj, obs, "int8Col", 1 as Int8, 10) { obj.int8Col = 10 }
        observeChange(obj, obs, "int16Col", 2 as Int16, 10) { obj.int16Col = 10 }
        observeChange(obj, obs, "int32Col", 3 as Int32, 10) { obj.int32Col = 10 }
        observeChange(obj, obs, "int64Col", 4 as Int64, 10) { obj.int64Col = 10 }
        observeChange(obj, obs, "floatCol", 5 as Float, 10) { obj.floatCol = 10 }
        observeChange(obj, obs, "doubleCol", 6 as Double, 10) { obj.doubleCol = 10 }
        observeChange(obj, obs, "stringCol", "", "abc") { obj.stringCol = "abc" }
        observeChange(obj, obs, "objectCol", nil, obj) { obj.objectCol = obj }
        observeChange(obj, obs, "binaryCol", oldData, data) { obj.binaryCol = data }
        observeChange(obj, obs, "dateCol", oldDate, date) { obj.dateCol = date }
        observeChange(obj, obs, "decimalCol", oldDecimal, decimal) { obj.decimalCol = decimal }
        observeChange(obj, obs, "objectIdCol", oldObjectId, objectId) { obj.objectIdCol = objectId }
        observeChange(obj, obs, "uuidCol", oldUUID, uuid) { obj.uuidCol = uuid }
        observeChange(obj, obs, "anyCol", nil, 1) { obj.anyCol = .int(1) }

        observeListChange(obs, "arrayCol", .insertion) { obj.arrayCol.append(obj) }
        observeListChange(obs, "arrayCol", .removal) { obj.arrayCol.removeAll() }
        observeSetChange(obs, "setCol") { obj.setCol.insert(obj) }
        observeSetChange(obs, "setCol") { obj.setCol.remove(obj) }

        observeChange(obj, obs, "optIntCol", nil, 10) { obj.optIntCol = 10 }
        observeChange(obj, obs, "optFloatCol", nil, 10.0) { obj.optFloatCol = 10 }
        observeChange(obj, obs, "optDoubleCol", nil, 10.0) { obj.optDoubleCol = 10 }
        observeChange(obj, obs, "optBoolCol", nil, true) { obj.optBoolCol = true }
        observeChange(obj, obs, "optStringCol", nil, "abc") { obj.optStringCol = "abc" }
        observeChange(obj, obs, "optBinaryCol", nil, data) { obj.optBinaryCol = data }
        observeChange(obj, obs, "optDateCol", nil, date) { obj.optDateCol = date }
        observeChange(obj, obs, "optDecimalCol", nil, decimal) { obj.optDecimalCol = decimal }
        observeChange(obj, obs, "optObjectIdCol", nil, objectId) { obj.optObjectIdCol = objectId }
        observeChange(obj, obs, "optUuidCol", nil, uuid) { obj.optUuidCol = uuid }

        observeChange(obj, obs, "optIntCol", 10, nil) { obj.optIntCol = nil }
        observeChange(obj, obs, "optFloatCol", 10.0, nil) { obj.optFloatCol = nil }
        observeChange(obj, obs, "optDoubleCol", 10.0, nil) { obj.optDoubleCol = nil }
        observeChange(obj, obs, "optBoolCol", true, nil) { obj.optBoolCol = nil }
        observeChange(obj, obs, "optStringCol", "abc", nil) { obj.optStringCol = nil }
        observeChange(obj, obs, "optBinaryCol", data, nil) { obj.optBinaryCol = nil }
        observeChange(obj, obs, "optDateCol", date, nil) { obj.optDateCol = nil }
        observeChange(obj, obs, "optDecimalCol", decimal, nil) { obj.optDecimalCol = nil }
        observeChange(obj, obs, "optObjectIdCol", objectId, nil) { obj.optObjectIdCol = nil }
        observeChange(obj, obs, "optUuidCol", uuid, nil) { obj.optUuidCol = nil }

        observeListChange(obs, "arrayBool", .insertion) { obj.arrayBool.append(true) }
        observeListChange(obs, "arrayInt8", .insertion) { obj.arrayInt8.append(10) }
        observeListChange(obs, "arrayInt16", .insertion) { obj.arrayInt16.append(10) }
        observeListChange(obs, "arrayInt32", .insertion) { obj.arrayInt32.append(10) }
        observeListChange(obs, "arrayInt64", .insertion) { obj.arrayInt64.append(10) }
        observeListChange(obs, "arrayFloat", .insertion) { obj.arrayFloat.append(10) }
        observeListChange(obs, "arrayDouble", .insertion) { obj.arrayDouble.append(10) }
        observeListChange(obs, "arrayString", .insertion) { obj.arrayString.append("abc") }
        observeListChange(obs, "arrayDecimal", .insertion) { obj.arrayDecimal.append(decimal) }
        observeListChange(obs, "arrayObjectId", .insertion) { obj.arrayObjectId.append(objectId) }
        observeListChange(obs, "arrayUuid", .insertion) { obj.arrayUuid.append(uuid) }
        observeListChange(obs, "arrayAny", .insertion) { obj.arrayAny.append(.string("a")) }

        observeListChange(obs, "arrayOptBool", .insertion) { obj.arrayOptBool.append(true) }
        observeListChange(obs, "arrayOptInt8", .insertion) { obj.arrayOptInt8.append(10) }
        observeListChange(obs, "arrayOptInt16", .insertion) { obj.arrayOptInt16.append(10) }
        observeListChange(obs, "arrayOptInt32", .insertion) { obj.arrayOptInt32.append(10) }
        observeListChange(obs, "arrayOptInt64", .insertion) { obj.arrayOptInt64.append(10) }
        observeListChange(obs, "arrayOptFloat", .insertion) { obj.arrayOptFloat.append(10) }
        observeListChange(obs, "arrayOptDouble", .insertion) { obj.arrayOptDouble.append(10) }
        observeListChange(obs, "arrayOptString", .insertion) { obj.arrayOptString.append("abc") }
        observeListChange(obs, "arrayOptBinary", .insertion) { obj.arrayOptBinary.append(data) }
        observeListChange(obs, "arrayOptDate", .insertion) { obj.arrayOptDate.append(date) }
        observeListChange(obs, "arrayOptDecimal", .insertion) { obj.arrayOptDecimal.append(decimal) }
        observeListChange(obs, "arrayOptObjectId", .insertion) { obj.arrayOptObjectId.append(objectId) }
        observeListChange(obs, "arrayOptUuid", .insertion) { obj.arrayOptUuid.append(uuid) }

        observeListChange(obs, "arrayOptBool", .insertion) { obj.arrayOptBool.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt8", .insertion) { obj.arrayOptInt8.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt16", .insertion) { obj.arrayOptInt16.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt32", .insertion) { obj.arrayOptInt32.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt64", .insertion) { obj.arrayOptInt64.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptFloat", .insertion) { obj.arrayOptFloat.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptDouble", .insertion) { obj.arrayOptDouble.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptString", .insertion) { obj.arrayOptString.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptDate", .insertion) { obj.arrayOptDate.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptBinary", .insertion) { obj.arrayOptBinary.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptDecimal", .insertion) { obj.arrayOptDecimal.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptObjectId", .insertion) { obj.arrayOptObjectId.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptUuid", .insertion) { obj.arrayOptUuid.insert(nil, at: 0) }

        observeSetChange(obs, "setBool") { obj.setBool.insert(true) }
        observeSetChange(obs, "setInt8") { obj.setInt8.insert(10) }
        observeSetChange(obs, "setInt16") { obj.setInt16.insert(10) }
        observeSetChange(obs, "setInt32") { obj.setInt32.insert(10) }
        observeSetChange(obs, "setInt64") { obj.setInt64.insert(10) }
        observeSetChange(obs, "setFloat") { obj.setFloat.insert(10) }
        observeSetChange(obs, "setDouble") { obj.setDouble.insert(10) }
        observeSetChange(obs, "setString") { obj.setString.insert("abc") }
        observeSetChange(obs, "setDecimal") { obj.setDecimal.insert(decimal) }
        observeSetChange(obs, "setObjectId") { obj.setObjectId.insert(objectId) }
        observeSetChange(obs, "setUuid") { obj.setUuid.insert(uuid) }
        observeSetChange(obs, "setAny") { obj.setAny.insert(.none) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.insert(true) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.insert(10) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.insert(10) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.insert(10) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.insert(10) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.insert(10) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.insert(10) }
        observeSetChange(obs, "setOptString") { obj.setOptString.insert("abc") }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.insert(data) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.insert(date) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.insert(decimal) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.insert(objectId) }
        observeSetChange(obs, "setOptUuid") { obj.setOptUuid.insert(uuid) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.insert(nil) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.insert(nil) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.insert(nil) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.insert(nil) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.insert(nil) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.insert(nil) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.insert(nil) }
        observeSetChange(obs, "setOptString") { obj.setOptString.insert(nil) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.insert(nil) }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.insert(nil) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.insert(nil) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.insert(nil) }
        observeSetChange(obs, "setOptUuid") { obj.setOptUuid.insert(nil) }

        observeSetChange(obs, "mapBool") { obj.mapBool[""] = true }
        observeSetChange(obs, "mapInt8") { obj.mapInt8[""] = 10 }
        observeSetChange(obs, "mapInt16") { obj.mapInt16[""] = 10 }
        observeSetChange(obs, "mapInt32") { obj.mapInt32[""] = 10 }
        observeSetChange(obs, "mapInt64") { obj.mapInt64[""] = 10 }
        observeSetChange(obs, "mapFloat") { obj.mapFloat[""] = 10 }
        observeSetChange(obs, "mapDouble") { obj.mapDouble[""] = 10 }
        observeSetChange(obs, "mapString") { obj.mapString[""] = "abc" }
        observeSetChange(obs, "mapDecimal") { obj.mapDecimal[""] = decimal }
        observeSetChange(obs, "mapObjectId") { obj.mapObjectId[""] = objectId }
        observeSetChange(obs, "mapUuid") { obj.mapUuid[""] = uuid }
        observeSetChange(obs, "mapAny") { obj.mapAny[""] = AnyRealmValue.none }

        observeSetChange(obs, "mapOptBool") { obj.mapOptBool[""] = true }
        observeSetChange(obs, "mapOptInt8") { obj.mapOptInt8[""] = 10 }
        observeSetChange(obs, "mapOptInt16") { obj.mapOptInt16[""] = 10 }
        observeSetChange(obs, "mapOptInt32") { obj.mapOptInt32[""] = 10 }
        observeSetChange(obs, "mapOptInt64") { obj.mapOptInt64[""] = 10 }
        observeSetChange(obs, "mapOptFloat") { obj.mapOptFloat[""] = 10 }
        observeSetChange(obs, "mapOptDouble") { obj.mapOptDouble[""] = 10 }
        observeSetChange(obs, "mapOptString") { obj.mapOptString[""] = "abc" }
        observeSetChange(obs, "mapOptBinary") { obj.mapOptBinary[""] = data }
        observeSetChange(obs, "mapOptDate") { obj.mapOptDate[""] = date }
        observeSetChange(obs, "mapOptDecimal") { obj.mapOptDecimal[""] = decimal }
        observeSetChange(obs, "mapOptObjectId") { obj.mapOptObjectId[""] = objectId }
        observeSetChange(obs, "mapOptUuid") { obj.mapOptUuid[""] = uuid }

        observeSetChange(obs, "mapOptBool") { obj.mapOptBool[""] = nil }
        observeSetChange(obs, "mapOptInt8") { obj.mapOptInt8[""] = nil }
        observeSetChange(obs, "mapOptInt16") { obj.mapOptInt16[""] = nil }
        observeSetChange(obs, "mapOptInt32") { obj.mapOptInt32[""] = nil }
        observeSetChange(obs, "mapOptInt64") { obj.mapOptInt64[""] = nil }
        observeSetChange(obs, "mapOptFloat") { obj.mapOptFloat[""] = nil }
        observeSetChange(obs, "mapOptDouble") { obj.mapOptDouble[""] = nil }
        observeSetChange(obs, "mapOptString") { obj.mapOptString[""] = nil }
        observeSetChange(obs, "mapOptDate") { obj.mapOptDate[""] = nil }
        observeSetChange(obs, "mapOptBinary") { obj.mapOptBinary[""] = nil }
        observeSetChange(obs, "mapOptDecimal") { obj.mapOptDecimal[""] = nil }
        observeSetChange(obs, "mapOptObjectId") { obj.mapOptObjectId[""] = nil }
        observeSetChange(obs, "mapOptUuid") { obj.mapOptUuid[""] = nil }

        obj.arrayInt32.removeAll()
        observeCompoundListChange(obj, obs, "arrayInt32", [1],
                                  deletions: [], insertions: [0])
        observeCompoundListChange(obj, obs, "arrayInt32", [1],
                                  deletions: [0], insertions: [0])
        observeCompoundListChange(obj, obs, "arrayInt32", [1, 2, 3],
                                  deletions: [0], insertions: [0, 1, 2])
        observeCompoundListChange(obj, obs, "arrayInt32", [],
                                  deletions: [0, 1, 2], insertions: [])
        observeCompoundListChange(obj, obs, "arrayInt32", [],
                                  deletions: [], insertions: [])

        if obs.realm == nil {
            return
        }

//        observeChange(obs, "invalidated", false, true) {
//            realmWithTestPath().delete(obj)
//        }
//
//        let (obj2, obs2) = getObject(ModernAllTypesObject())
//        observeChange(obs2, "arrayCol.invalidated", false, true) {
//            realmWithTestPath().delete(obj2)
//        }
//
//        let (obj3, obs3) = getObject(ModernAllTypesObject())
//        observeChange(obs3, "setCol.invalidated", false, true) {
//            realmWithTestPath().delete(obj3)
//        }
//
//        let (obj4, obs4) = getObject(ModernAllTypesObject())
//        observeChange(obs4, "mapAny.invalidated", false, true) {
//            realmWithTestPath().delete(obj4)
//        }
        realmWithTestPath().cancelWrite()
    }

}
