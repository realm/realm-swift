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
#endif

// MARK: Test objects definitions

enum IntegerEnum: Int, PersistableEnum {
    case value1 = 1
    case value2 = 3
}

class AllTypesPrimitiveProjection: Projection<ModernAllTypesObject> {
    @Projected(\ModernAllTypesObject.pk) var pk
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

class AdvancedObject: Object {
    @Persisted(primaryKey: true) var pk: ObjectId
    @Persisted var commonArray: RealmSwift.List<Int>
    @Persisted var objectsArray: RealmSwift.List<SimpleObject>
    @Persisted var commonSet: MutableSet<Int>
    @Persisted var objectsSet: MutableSet<SimpleObject>
}

extension SimpleObject {
    var stringify: String {
        "\(int) - \(bool)"
    }
}

class AdvancedProjection: Projection<AdvancedObject> {
    @Projected(\AdvancedObject.commonArray.count) var arrayLen
    @Projected(\AdvancedObject.commonArray) var renamedArray
    @Projected(\AdvancedObject.objectsArray.projectTo.stringify) var projectedArray: ProjectedCollection<String>
    @Projected(\AdvancedObject.commonSet.first) var firstElement
    @Projected(\AdvancedObject.objectsSet.projectTo.bool) var projectedSet: ProjectedCollection<Bool>
}

class FailedProjection: Projection<ModernAllTypesObject> {
    @Projected(\ModernAllTypesObject.ignored) var ignored
}

public class AddressSwift: EmbeddedObject {
    @Persisted var city: String = ""
    @Persisted var country = ""
}

public class CommonPerson: Object {
    @Persisted var firstName: String
    @Persisted var lastName = ""
    @Persisted var birthday: Date
    @Persisted var address: AddressSwift?
    @Persisted public var friends: RealmSwift.List<CommonPerson>
    @Persisted var reviews: RealmSwift.List<String>
    @Persisted var money: Decimal128
}

public final class PersonProjection: Projection<CommonPerson> {
    @Projected(\CommonPerson.firstName) var firstName
    @Projected(\CommonPerson.lastName.localizedUppercase) var lastNameCaps
    @Projected(\CommonPerson.birthday.timeIntervalSince1970) var birthdayAsEpochtime
    @Projected(\CommonPerson.address?.city) var homeCity
    @Projected(\CommonPerson.friends.projectTo.firstName) var firstFriendsName: ProjectedCollection<String>
}

public class SimpleObject: Object {
    @Persisted var int: Int
    @Persisted var bool: Bool
}

public final class SimpleProjection: Projection<SimpleObject> {
    @Projected(\SimpleObject.int) var int
}

// MARK: Tests

@available(iOS 13.0, *)
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

    var allTypeValues: [String: Any] {
        return [
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
            "objectIdCol": ObjectId("6058f12b957ba06156586a7c"),
            "objectCol": ModernAllTypesObject(value: ["intCol": 1]),
            "arrayCol": [
                ModernAllTypesObject(value: ["pk": ObjectId("6058f12682b2fbb1f334ef1d"), "intCol": 2]),
                ModernAllTypesObject(value: ["pk": ObjectId("6058f12d42e5a393e67538d0"), "intCol": 3])
            ],
            "setCol": [
                ModernAllTypesObject(value: ["pk": ObjectId("6058f12d42e5a393e67538d1"), "intCol": 4]),
                ModernAllTypesObject(value: ["pk": ObjectId("6058f12682b2fbb1f334ef1f"), "intCol": 5]),
                ModernAllTypesObject(value: ["pk": ObjectId("507f1f77bcf86cd799439011"), "intCol": 6])
            ],
            "anyCol": AnyRealmValue.int(20),
            "uuidCol": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
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
            "optObjectIdCol": ObjectId("6058f12b957ba06156586a7c"),
            "optUuidCol": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
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
            "arrayDate": [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1)] as [Date],
            "arrayDecimal": [1 as Decimal128, 2 as Decimal128],
            "arrayObjectId": [ObjectId("6058f12b957ba06156586a7c"), ObjectId("6058f12682b2fbb1f334ef1d")],
            "arrayAny": [.none, .int(1), .string("a"), .none] as [AnyRealmValue],
            "arrayUuid": [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!, UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!],
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
            "arrayOptDate": [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1), nil],
            "arrayOptDecimal": [1 as Decimal128, 2 as Decimal128, nil],
            "arrayOptObjectId": [ObjectId("6058f12b957ba06156586a7c"), ObjectId("6058f12682b2fbb1f334ef1d"), nil],
            "arrayOptUuid": [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!, UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!, nil],
            "setBool": [true] as [Bool],
            "setInt": [1, 1, 2, 3] as [Int],
            "setInt8": [1, 2, 3, 1] as [Int8],
            "setInt16": [1, 2, 3, 1] as [Int16],
            "setInt32": [1, 2, 3, 1] as [Int32],
            "setInt64": [1, 2, 3, 1] as [Int64],
            "setFloat": [1 as Float, 2 as Float, 3 as Float, 1 as Float],
            "setDouble": [1 as Double, 2 as Double, 3 as Double, 1 as Double],
            "setString": ["a", "b", "c"] as [String],
            "setBinary": ["a".data(using: .utf8)!] as [Data],
            "setDate": [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 2)] as [Date],
            "setDecimal": [1 as Decimal128, 2 as Decimal128],
            "setObjectId": [ObjectId("6058f12b957ba06156586a7c"),
                            ObjectId("6058f12682b2fbb1f334ef1d")],
            "setAny": [.none, .int(1), .string("a"), .none] as [AnyRealmValue],
            "setUuid": [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                        UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                        UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!],
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
            "setOptDate": [Date(timeIntervalSince1970: 1), Date(timeIntervalSince1970: 2), nil],
            "setOptDecimal": [1 as Decimal128, 2 as Decimal128, nil],
            "setOptObjectId": [ObjectId("6058f12b957ba06156586a7c"), ObjectId("6058f12682b2fbb1f334ef1d"), nil],
            "setOptUuid": [UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                           UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                           UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!,
                           nil],
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
            "mapDate": ["1": Date(timeIntervalSince1970: 1), "2": Date(timeIntervalSince1970: 2)] as [String: Date],
            "mapDecimal": ["1": 1 as Decimal128, "2": 2 as Decimal128],
            "mapObjectId": ["1": ObjectId("6058f12b957ba06156586a7c"),
                            "2": ObjectId("6058f12682b2fbb1f334ef1d")],
            "mapAny": ["1": .none, "2": .int(1), "3": .string("a"), "4": .none] as [String: AnyRealmValue],
            "mapUuid": ["1": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                        "2": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                        "3": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!],
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
            "mapOptDate": ["1": Date(timeIntervalSince1970: 1), "2": Date(timeIntervalSince1970: 2), "3": nil],
            "mapOptDecimal": ["1": 1 as Decimal128, "2": 2 as Decimal128, "3": nil],
            "mapOptObjectId": ["1": ObjectId("6058f12b957ba06156586a7c"),
                               "2": ObjectId("6058f12682b2fbb1f334ef1d"),
                               "3": nil],
            "mapOptUuid": ["1": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fd")!,
                           "2": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                           "3": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!,
                           "4": nil],
        ] as [String: Any]
    }

    func populatedRealm() -> Realm {
        let realm = realmWithTestPath()
        try! realm.write {
            let js = realm.create(CommonPerson.self, value: ["firstName": "John",
                                                             "lastName": "Snow",
                                                             "birthday": Date(timeIntervalSince1970: 10),
                                                             "address": ["Winterfell", "Kingdom in the North"],
                                                             "money": Decimal128("2.22")])
            let dt = realm.create(CommonPerson.self, value: ["firstName": "Daenerys",
                                                             "lastName": "Targaryen",
                                                             "birthday": Date(timeIntervalSince1970: 0),
                                                             "address": ["King's Landing", "Westeros"],
                                                             "money": Decimal128("2.22")])
            js.friends.append(dt)
            dt.friends.append(js)

            realm.create(ModernAllTypesObject.self, value: allTypeValues)
            realm.create(AdvancedObject.self, value: ["pk": ObjectId.generate(), "commonArray": [1, 2, 3], "objectsArray": [[1, true], [2, false]], "commonSet": [1, 2, 3], "objectsSet": [[1, true], [2, false]]])
        }
        return realm
    }

    func testProjectionManualInit() {
        let realm = populatedRealm()
        let johnSnow = realm.objects(CommonPerson.self).filter("lastName == 'Snow'").first!
        // this step will happen under the hood
        let pp = PersonProjection(projecting: johnSnow)
        XCTAssertEqual(pp.homeCity, "Winterfell")
        XCTAssertEqual(pp.birthdayAsEpochtime, Date(timeIntervalSince1970: 10).timeIntervalSince1970)
        XCTAssertEqual(pp.firstFriendsName.first!, "Daenerys")
    }

    func testProjectionFromResult() {
        let realm = populatedRealm()
        let johnSnow: PersonProjection = realm.objects(PersonProjection.self).first!
        XCTAssertEqual(johnSnow.homeCity, "Winterfell")
        XCTAssertEqual(johnSnow.birthdayAsEpochtime, Date(timeIntervalSince1970: 10).timeIntervalSince1970)
        XCTAssertEqual(johnSnow.firstFriendsName.first!, "Daenerys")
    }

    func testProjectionFromResultFiltered() {
        let realm = populatedRealm()
        let johnSnow: PersonProjection = realm.objects(PersonProjection.self).filter("lastName == 'Snow'").first!

        XCTAssertEqual(johnSnow.homeCity, "Winterfell")
        XCTAssertEqual(johnSnow.birthdayAsEpochtime, Date(timeIntervalSince1970: 10).timeIntervalSince1970)
        XCTAssertEqual(johnSnow.firstFriendsName.first!, "Daenerys")
    }

    func testProjectionFromResultSorted() {
        let realm = populatedRealm()
        let dany: PersonProjection = realm.objects(PersonProjection.self).sorted(byKeyPath: "firstName").first!

        XCTAssertEqual(dany.homeCity, "King's Landing")
        XCTAssertEqual(dany.birthdayAsEpochtime, Date(timeIntervalSince1970: 0).timeIntervalSince1970)
        XCTAssertEqual(dany.firstFriendsName.first!, "John")
    }

    func testProjectionEnumeration() {
        let realm = populatedRealm()
        XCTAssertGreaterThan(realm.objects(PersonProjection.self).count, 0)
        for proj in realm.objects(PersonProjection.self) {
            _ = proj
        }
    }

    func testProjectionEquality() {
        let realm = populatedRealm()
        let johnObject = realm.objects(CommonPerson.self).filter("lastName == 'Snow'").first!
        let johnDefaultInit = PersonProjection(projecting: johnObject)
        let johnMapped = realm.objects(PersonProjection.self).filter("lastName == 'Snow'").first!
        let notJohn = realm.objects(PersonProjection.self).filter("lastName != 'Snow'").first!

        XCTAssertEqual(johnMapped, johnDefaultInit)
        XCTAssertNotEqual(johnMapped, notJohn)
    }

    func testDescription() {
        let actual = populatedRealm().objects(PersonProjection.self).filter("lastName == 'Snow'").first!.description
        let expected = "PersonProjection<CommonPerson> <0x[0-9a-f]+> \\{\n\t\tfirstName\\(\\\\.firstName\\) = John;\n\tlastNameCaps\\(\\\\.lastName\\) = SNOW;\n\tbirthdayAsEpochtime\\(\\\\.birthday\\) = 10.0;\n\thomeCity\\(\\\\.address.city\\) = Optional\\(\"Winterfell\"\\);\n\tfirstFriendsName\\(\\\\.friends\\) = ProjectedCollection<String> \\{\n\t\\[0\\] Daenerys\n\\};\n\\}"
        assertMatches(actual, expected)
    }

    func testProjectionsRealmShouldNotBeNil() {
        XCTAssertNotNil(populatedRealm().objects(PersonProjection.self).first!.realm)
    }

    func testProjectionFromResultSortedBirthday() {
        let realm = populatedRealm()
        let dany: PersonProjection = realm.objects(PersonProjection.self).sorted(byKeyPath: "birthday").first!

        XCTAssertEqual(dany.homeCity, "King's Landing")
        XCTAssertEqual(dany.birthdayAsEpochtime, Date(timeIntervalSince1970: 0).timeIntervalSince1970)
        XCTAssertEqual(dany.firstFriendsName.first!, "John")
    }

    func testProjectionForAllRealmTypes() {
        let allTypesModel = populatedRealm().objects(AllTypesPrimitiveProjection.self).first!

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

    func observeKeyPathChange<Root: ObjectBase, P: Projection<Root>, E: Equatable>(_ obj: Object, _ obs: P, _ keyPath: PartialKeyPath<P>,
                                                                                   _ old: E?, _ new: E?,
                                                                                   fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        let ex = expectation(description: "observeKeyPathChange")
        let token = obs.observe(keyPaths: [keyPath]) { changes in
            ex.fulfill()
            if case .change(_, let properties) = changes {
                XCTAssertEqual(properties.count, 1)

                let actualOld = properties[0].oldValue as? E
                let actualNew = properties[0].newValue as? E

                XCTAssert(actualOld != actualNew, "Old value \(String(describing: actualOld)) should not be equal to New value \(String(describing: actualNew))",
                          file: (fileName), line: lineNumber)
                XCTAssert(new == actualNew,
                          "New value: expected \(String(describing: new)), got \(String(describing: actualNew))",
                          file: (fileName), line: lineNumber)
                if actualOld != nil {
                    XCTAssert(old == actualOld,
                              "Old value: expected \(String(describing: old)), got \(String(describing: actualOld))",
                              file: (fileName), line: lineNumber)
                }
            } else {
                XCTFail("Expected .change but got \(changes)")
            }
        }

        try! obj.realm!.write {
            block()
        }
        waitForExpectations(timeout: 2, handler: nil)
        token.invalidate()
    }

    func observeArrayKeyPathChange<Root: ObjectBase, P: Projection<Root>, E: Equatable & RealmCollectionValue>(_ obj: Object, _ obs: P, _ keyPath: PartialKeyPath<P>,
                                                                                                               _ new: [E]?,
                                                                                                               fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        let ex = expectation(description: "observeKeyPathChange")
        let token = obs.observe(keyPaths: [keyPath]) { changes in
            ex.fulfill()
            if case .change(let object, let properties) = changes {
                XCTAssertEqual(properties.count, 1)
                let observedOld = properties[0].oldValue as? [E]
                let observedNew = properties[0].newValue as? [E]
                XCTAssertNil(observedOld)
                XCTAssertNil(observedNew)

                guard let projectedNew = object[keyPath: keyPath] as? RealmSwift.List<E>,
                      let newVals = new else {
                          XCTFail("Expected new array to be [\(String(describing: E.self))] and projected array to be \(String(describing: RealmSwift.List<E>.self)), got \(String(describing: new)) and \(String(describing: obs[keyPath: keyPath]))",
                                  file: (fileName), line: lineNumber)
                          return
                      }

                if projectedNew.count != newVals.count {
                    XCTAssertEqual(projectedNew.count, newVals.count, "Expected \(projectedNew) and \(newVals) to be equal", file: (fileName), line: lineNumber)
                } else {
                    for (index, element) in projectedNew.enumerated() {
                        XCTAssertEqual(element, newVals[index], "Element \(element) at index \(index) should be equal to \(newVals[index])", file: (fileName), line: lineNumber)
                    }
                }
            } else {
                XCTFail("Expected .change but got \(changes)", file: (fileName), line: lineNumber)
            }
        }

        try! obj.realm!.write {
            block()
        }
        waitForExpectations(timeout: 2, handler: nil)
        token.invalidate()
    }

    func observeSetKeyPathChange<Root: ObjectBase, P: Projection<Root>, E: Equatable & RealmCollectionValue>(_ obj: Object, _ obs: P, _ keyPath: PartialKeyPath<P>,
                                                                                                             _ new: [E],
                                                                                                             fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        let ex = expectation(description: "observeKeyPathChange")
        let token = obs.observe(keyPaths: [keyPath]) { changes in
            ex.fulfill()
            if case .change(let object, let properties) = changes {
                XCTAssertEqual(properties.count, 1)
                let observedOld = properties[0].oldValue as? Set<E>
                let observedNew = properties[0].newValue as? Set<E>
                XCTAssertNil(observedOld)
                XCTAssertNil(observedNew)

                guard let projectedNew = object[keyPath: keyPath] as? MutableSet<E> else {
                          XCTFail("Expected new set to be \(String(describing: Set<E>.self)) and projected set to be \(String(describing: MutableSet<E>.self)), got \(String(describing: new)) and \(String(describing: obs[keyPath: keyPath]))",
                                  file: (fileName), line: lineNumber)
                          return
                      }

                self.assertSetEquals(projectedNew, new)
            } else {
                XCTFail("Expected .change but got \(changes)", file: (fileName), line: lineNumber)
            }
        }

        try! obj.realm!.write {
            block()
        }
        waitForExpectations(timeout: 2, handler: nil)
        token.invalidate()
    }

    func observeMapKeyPathChange<Root: ObjectBase, P: Projection<Root>, E: Equatable & RealmCollectionValue>(_ obj: Object, _ obs: P, _ keyPath: PartialKeyPath<P>,
                                                                                                             _ new: Dictionary<String, E>,
                                                                                                             fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        let ex = expectation(description: "observeKeyPathChange")
        let token = obs.observe(keyPaths: [keyPath]) { changes in
            ex.fulfill()
            if case .change(let object, let properties) = changes {
                XCTAssertEqual(properties.count, 1)
                let observedOld = properties[0].oldValue as? MutableSet<E>
                let observedNew = properties[0].newValue as? MutableSet<E>
                XCTAssertNil(observedOld)
                XCTAssertNil(observedNew)

                guard let projectedNew = object[keyPath: keyPath] as? Map<String, E> else {
                    XCTFail("Expected new set to be \(String(describing: Dictionary<String, E>.self)) and projected set to be \(String(describing: Map<String, E>.self)), got \(String(describing: new)) and \(String(describing: obs[keyPath: keyPath]))",
                            file: (fileName), line: lineNumber)
                    return
                }
                if projectedNew.count != new.count {
                    XCTAssertEqual(projectedNew.count, new.count, "Expected \(projectedNew) and \(new) to be equal", file: (fileName), line: lineNumber)
                } else {
                    for (key, value) in new {
                        XCTAssertEqual(projectedNew[key], value, "Projected set should contain (\(key), \(value))", file: (fileName), line: lineNumber)
                    }
                }
            } else {
                XCTFail("Expected .change but got \(changes)", file: (fileName), line: lineNumber)
            }
        }

        try! obj.realm!.write {
            block()
        }
        waitForExpectations(timeout: 2, handler: nil)
        token.invalidate()
    }

    func testAllPropertyTypesNotifications() {
        let realm = populatedRealm()
        let obj = realm.objects(ModernAllTypesObject.self).first!
        let obs = realm.objects(AllTypesPrimitiveProjection.self).first!

        let data = "b".data(using: String.Encoding.utf8)!
        let date = Date(timeIntervalSince1970: 7)
        let decimal = Decimal128(number: 3)
        let objectId = ObjectId()
        let uuid = UUID()
        let object = ModernAllTypesObject(value: ["intCol": 2])
        let anyValue = AnyRealmValue.int(22)

        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.boolCol, obj.boolCol, false, { obj.boolCol = false })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.intCol, obj.intCol, 2, { obj.intCol = 2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.int8Col, obj.int8Col, 2, { obj.int8Col = 2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.int16Col, obj.int16Col, 2, { obj.int16Col = 2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.int32Col, obj.int32Col, 2, { obj.int32Col = 2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.int64Col, obj.int64Col, 2, { obj.int64Col = 2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.floatCol, obj.floatCol, 2.0, { obj.floatCol = 2.0 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.doubleCol, obj.doubleCol, 2.0, { obj.doubleCol = 2.0 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.stringCol, obj.stringCol, "def", { obj.stringCol = "def" })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.binaryCol, obj.binaryCol, data, { obj.binaryCol = data })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.dateCol, obj.dateCol, date, { obj.dateCol = date })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.decimalCol, obj.decimalCol, decimal, { obj.decimalCol = decimal })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.objectIdCol, obj.objectIdCol, objectId, { obj.objectIdCol = objectId })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.objectCol, obj.objectCol, object, { obj.objectCol = object })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.anyCol, obj.anyCol, anyValue, { obj.anyCol = anyValue })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.uuidCol, obj.uuidCol, uuid, { obj.uuidCol = uuid })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.intEnumCol, obj.intEnumCol, .value2, { obj.intEnumCol = .value2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.stringEnumCol, obj.stringEnumCol, .value2, { obj.stringEnumCol = .value2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optIntCol, obj.optIntCol, 2, { obj.optIntCol = 2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optInt8Col, obj.optInt8Col, 2, { obj.optInt8Col = 2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optInt16Col, obj.optInt16Col, 2, { obj.optInt16Col = 2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optInt32Col, obj.optInt32Col, 2, { obj.optInt32Col = 2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optInt64Col, obj.optInt64Col, 2, { obj.optInt64Col = 2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optFloatCol, obj.optFloatCol, 2.0, { obj.optFloatCol = 2.0 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optDoubleCol, obj.optDoubleCol, 2.0, { obj.optDoubleCol = 2.0 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optBoolCol, obj.optBoolCol, false, { obj.optBoolCol = false })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optStringCol, obj.optStringCol, "def", { obj.optStringCol = "def" })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optBinaryCol, obj.optBinaryCol, data, { obj.optBinaryCol = data })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optDateCol, obj.optDateCol, date, { obj.optDateCol = date })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optDecimalCol, obj.optDecimalCol, decimal, { obj.optDecimalCol = decimal })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optObjectIdCol, obj.optObjectIdCol, objectId, { obj.optObjectIdCol = objectId })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optUuidCol, obj.optUuidCol, uuid, { obj.optUuidCol = uuid })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optIntEnumCol, obj.optIntEnumCol, .value2, { obj.optIntEnumCol = .value2 })
        observeKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.optStringEnumCol, obj.optStringEnumCol, .value2, { obj.optStringEnumCol = .value2 })

        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayBool, allTypeValues["arrayBool"] as! [Bool] + [false]) { obj.arrayBool.append(false) }
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayInt, allTypeValues["arrayInt"] as! [Int] + [4], { obj.arrayInt.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayInt8, allTypeValues["arrayInt8"] as! [Int8] + [4], { obj.arrayInt8.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayInt16, allTypeValues["arrayInt16"] as! [Int16] + [4], { obj.arrayInt16.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayInt32, allTypeValues["arrayInt32"] as! [Int32] + [4], { obj.arrayInt32.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayInt64, allTypeValues["arrayInt64"] as! [Int64] + [4], { obj.arrayInt64.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayFloat, allTypeValues["arrayFloat"] as! [Float] + [4], { obj.arrayFloat.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayDouble, allTypeValues["arrayDouble"] as! [Double] + [4], { obj.arrayDouble.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayString, allTypeValues["arrayString"] as! [String] + ["d"], { obj.arrayString.append("d") })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayBinary, allTypeValues["arrayBinary"] as! [Data] + [data], { obj.arrayBinary.append(data) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayDate, allTypeValues["arrayDate"] as! [Date] + [date], { obj.arrayDate.append(date) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayDecimal, allTypeValues["arrayDecimal"] as! [Decimal128] + [decimal], { obj.arrayDecimal.append(decimal) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayObjectId, allTypeValues["arrayObjectId"] as! [ObjectId] + [objectId], { obj.arrayObjectId.append(objectId) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayAny, allTypeValues["arrayAny"] as! [AnyRealmValue] + [anyValue], { obj.arrayAny.append(anyValue) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayUuid, allTypeValues["arrayUuid"] as! [UUID] + [uuid], { obj.arrayUuid.append(uuid) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptBool, allTypeValues["arrayOptBool"] as! [Bool?] + [true], { obj.arrayOptBool.append(true) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptInt, allTypeValues["arrayOptInt"] as! [Int?] + [4], { obj.arrayOptInt.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptInt8, allTypeValues["arrayOptInt8"] as! [Int8?] + [4], { obj.arrayOptInt8.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptInt16, allTypeValues["arrayOptInt16"] as! [Int16?] + [4], { obj.arrayOptInt16.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptInt32, allTypeValues["arrayOptInt32"] as! [Int32?] + [4], { obj.arrayOptInt32.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptInt64, allTypeValues["arrayOptInt64"] as! [Int64?] + [4], { obj.arrayOptInt64.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptFloat, allTypeValues["arrayOptFloat"] as! [Float?] + [4], { obj.arrayOptFloat.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptDouble, allTypeValues["arrayOptDouble"] as! [Double?] + [4], { obj.arrayOptDouble.append(4) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptString, allTypeValues["arrayOptString"] as! [String?] + ["d"], { obj.arrayOptString.append("d") })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptBinary, allTypeValues["arrayOptBinary"] as! [Data?] + [data], { obj.arrayOptBinary.append(data) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptDate, allTypeValues["arrayOptDate"] as! [Date?] + [date], { obj.arrayOptDate.append(date) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptDecimal, allTypeValues["arrayOptDecimal"] as! [Decimal128?] + [decimal], { obj.arrayOptDecimal.append(decimal) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptObjectId, allTypeValues["arrayOptObjectId"] as! [ObjectId?] + [objectId], { obj.arrayOptObjectId.append(objectId) })
        observeArrayKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.arrayOptUuid, allTypeValues["arrayOptUuid"] as! [UUID?] + [uuid], { obj.arrayOptUuid.append(uuid) })

        try! realmWithTestPath().write {
            obj.setBool.removeAll()
            obj.setBool.insert(objectsIn: [true])
            obj.setOptBool.removeAll()
            obj.setOptBool.insert(objectsIn: [true, nil])
        }

        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setBool, allTypeValues["setBool"] as! [Bool] + [false], { obj.setBool.insert(false) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setInt, allTypeValues["setInt"] as! [Int] + [4], { obj.setInt.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setInt8, allTypeValues["setInt8"] as! [Int8] + [4], { obj.setInt8.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setInt16, allTypeValues["setInt16"] as! [Int16] + [4], { obj.setInt16.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setInt32, allTypeValues["setInt32"] as! [Int32] + [4], { obj.setInt32.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setInt64, allTypeValues["setInt64"] as! [Int64] + [4], { obj.setInt64.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setFloat, allTypeValues["setFloat"] as! [Float] + [4], { obj.setFloat.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setDouble, allTypeValues["setDouble"] as! [Double] + [4], { obj.setDouble.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setString, allTypeValues["setString"] as! [String] + ["d"], { obj.setString.insert("d") })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setBinary, allTypeValues["setBinary"] as! [Data] + [data], { obj.setBinary.insert(data) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setDate, allTypeValues["setDate"] as! [Date] + [date], { obj.setDate.insert(date) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setDecimal, allTypeValues["setDecimal"] as! [Decimal128] + [decimal], { obj.setDecimal.insert(decimal) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setObjectId, allTypeValues["setObjectId"] as! [ObjectId] + [objectId], { obj.setObjectId.insert(objectId) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setAny, allTypeValues["setAny"] as! [AnyRealmValue] + [anyValue], { obj.setAny.insert(anyValue) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setUuid, allTypeValues["setUuid"] as! [UUID] + [uuid], { obj.setUuid.insert(uuid) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptBool, allTypeValues["setOptBool"] as! [Bool?] + [false], { obj.setOptBool.insert(false) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptInt, allTypeValues["setOptInt"] as! [Int?] + [4], { obj.setOptInt.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptInt8, allTypeValues["setOptInt8"] as! [Int8?] + [4], { obj.setOptInt8.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptInt16, allTypeValues["setOptInt16"] as! [Int16?] + [4], { obj.setOptInt16.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptInt32, allTypeValues["setOptInt32"] as! [Int32?] + [4], { obj.setOptInt32.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptInt64, allTypeValues["setOptInt64"] as! [Int64?] + [4], { obj.setOptInt64.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptFloat, allTypeValues["setOptFloat"] as! [Float?] + [4], { obj.setOptFloat.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptDouble, allTypeValues["setOptDouble"] as! [Double?] + [4], { obj.setOptDouble.insert(4) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptString, allTypeValues["setOptString"] as! [String?] + ["d"], { obj.setOptString.insert("d") })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptBinary, allTypeValues["setOptBinary"] as! [Data?] + [data], { obj.setOptBinary.insert(data) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptDate, allTypeValues["setOptDate"] as! [Date?] + [date], { obj.setOptDate.insert(date) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptDecimal, allTypeValues["setOptDecimal"] as! [Decimal128?] + [decimal], { obj.setOptDecimal.insert(decimal) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptObjectId, allTypeValues["setOptObjectId"] as! [ObjectId?] + [objectId], { obj.setOptObjectId.insert(objectId) })
        observeSetKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.setOptUuid, allTypeValues["setOptUuid"] as! [UUID?] + [uuid], { obj.setOptUuid.insert(uuid) })

        let newValues: [String: Any] = [
            "mapBool": ["1": false, "2": false] as [String: Bool],
            "mapInt": ["1": 4, "2": 1, "3": 2, "4": 3] as [String: Int],
            "mapInt8": ["1": 4, "2": 2, "3": 3, "4": 1] as [String: Int8],
            "mapInt16": ["1": 4, "2": 2, "3": 3, "4": 1] as [String: Int16],
            "mapInt32": ["1": 4, "2": 2, "3": 3, "4": 1] as [String: Int32],
            "mapInt64": ["1": 4, "2": 2, "3": 3, "4": 1] as [String: Int64],
            "mapFloat": ["1": 4 as Float, "2": 2 as Float, "3": 3 as Float, "4": 1 as Float],
            "mapDouble": ["1": 4 as Double, "2": 2 as Double, "3": 3 as Double, "4": 1 as Double],
            "mapString": ["1": "d", "2": "b", "3": "c"] as [String: String],
            "mapBinary": ["1": data] as [String: Data],
            "mapDate": ["1": date, "2": Date(timeIntervalSince1970: 2)] as [String: Date],
            "mapDecimal": ["1": decimal, "2": 2 as Decimal128],
            "mapObjectId": ["1": objectId,
                            "2": ObjectId("6058f12682b2fbb1f334ef1d")],
            "mapAny": ["1": anyValue, "2": .int(1), "3": .string("a"), "4": .none] as [String: AnyRealmValue],
            "mapUuid": ["1": uuid,
                        "2": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                        "3": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!],

            "mapOptBool": ["1": false, "2": false, "3": nil] as [String: Bool?],
            "mapOptInt": ["1": 4, "2": 1, "3": 2, "4": 3, "5": nil] as [String: Int?],
            "mapOptInt8": ["1": 4, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int8?],
            "mapOptInt16": ["1": 4, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int16?],
            "mapOptInt32": ["1": 4, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int32?],
            "mapOptInt64": ["1": 4, "2": 2, "3": 3, "4": 1, "5": nil] as [String: Int64?],
            "mapOptFloat": ["1": 4 as Float, "2": 2 as Float, "3": 3 as Float, "4": 1 as Float, "5": nil],
            "mapOptDouble": ["1": 4 as Double, "2": 2 as Double, "3": 3 as Double, "4": 1 as Double, "5": nil],
            "mapOptString": ["1": "d", "2": "b", "3": "c", "4": nil],
            "mapOptBinary": ["1": data, "2": nil],
            "mapOptDate": ["1": date, "2": Date(timeIntervalSince1970: 2), "3": nil],
            "mapOptDecimal": ["1": decimal, "2": 2 as Decimal128, "3": nil],
            "mapOptObjectId": ["1": objectId,
                               "2": ObjectId("6058f12682b2fbb1f334ef1d"),
                               "3": nil],
            "mapOptUuid": ["1": uuid,
                           "2": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90fe")!,
                           "3": UUID(uuidString: "6b28ec45-b29a-4b0a-bd6a-343c7f6d90ff")!,
                           "4": nil],
        ]

        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapBool, newValues["mapBool"] as! Dictionary<String, Bool>, { obj.mapBool["1"] = false })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapInt, newValues["mapInt"] as! Dictionary<String, Int>, { obj.mapInt["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapInt8, newValues["mapInt8"] as! Dictionary<String, Int8>, { obj.mapInt8["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapInt16, newValues["mapInt16"] as! Dictionary<String, Int16>, { obj.mapInt16["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapInt32, newValues["mapInt32"] as! Dictionary<String, Int32>, { obj.mapInt32["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapInt64, newValues["mapInt64"] as! Dictionary<String, Int64>, { obj.mapInt64["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapFloat, newValues["mapFloat"] as! Dictionary<String, Float>, { obj.mapFloat["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapDouble, newValues["mapDouble"] as! Dictionary<String, Double>, { obj.mapDouble["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapString, newValues["mapString"] as! Dictionary<String, String>, { obj.mapString["1"] = "d" })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapBinary, newValues["mapBinary"] as! Dictionary<String, Data>, { obj.mapBinary["1"] = data })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapDate, newValues["mapDate"] as! Dictionary<String, Date>, { obj.mapDate["1"] = date })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapDecimal, newValues["mapDecimal"] as! Dictionary<String, Decimal128>, { obj.mapDecimal["1"] = decimal })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapObjectId, newValues["mapObjectId"] as! Dictionary<String, ObjectId>, { obj.mapObjectId["1"] = objectId })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapAny, newValues["mapAny"] as! Dictionary<String, AnyRealmValue>, { obj.mapAny["1"] = anyValue })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapUuid, newValues["mapUuid"] as! Dictionary<String, UUID>, { obj.mapUuid["1"] = uuid })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptBool, newValues["mapOptBool"] as! Dictionary<String, Bool?>, { obj.mapOptBool["1"] = false })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptInt, newValues["mapOptInt"] as! Dictionary<String, Int?>, { obj.mapOptInt["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptInt8, newValues["mapOptInt8"] as! Dictionary<String, Int8?>, { obj.mapOptInt8["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptInt16, newValues["mapOptInt16"] as! Dictionary<String, Int16?>, { obj.mapOptInt16["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptInt32, newValues["mapOptInt32"] as! Dictionary<String, Int32?>, { obj.mapOptInt32["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptInt64, newValues["mapOptInt64"] as! Dictionary<String, Int64?>, { obj.mapOptInt64["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptFloat, newValues["mapOptFloat"] as! Dictionary<String, Float?>, { obj.mapOptFloat["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptDouble, newValues["mapOptDouble"] as! Dictionary<String, Double?>, { obj.mapOptDouble["1"] = 4 })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptString, newValues["mapOptString"] as! Dictionary<String, String?>, { obj.mapOptString["1"] = "d" })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptBinary, newValues["mapOptBinary"] as! Dictionary<String, Data?>, { obj.mapOptBinary["1"] = data })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptDate, newValues["mapOptDate"] as! Dictionary<String, Date?>, { obj.mapOptDate["1"] = date })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptDecimal, newValues["mapOptDecimal"] as! Dictionary<String, Decimal128?>, { obj.mapOptDecimal["1"] = decimal })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptObjectId, newValues["mapOptObjectId"] as! Dictionary<String, ObjectId?>, { obj.mapOptObjectId["1"] = objectId })
        observeMapKeyPathChange(obj, obs, \AllTypesPrimitiveProjection.mapOptUuid, newValues["mapOptUuid"] as! Dictionary<String, UUID?>, { obj.mapOptUuid["1"] = uuid })
    }

    func testObserveKeyPath() {
        let realm = populatedRealm()
        let johnProjection = realm.objects(PersonProjection.self).filter("lastName == 'Snow'").first!

        let ex = expectation(description: "testProjectionNotification")
        let token = johnProjection.observe(keyPaths: ["lastName"], on: nil) { _ in
            ex.fulfill()
        }
        dispatchSyncNewThread {
            let realm = self.realmWithTestPath()
            try! realm.write {
                let johnObject = realm.objects(CommonPerson.self).filter("lastName == 'Snow'").first!
                johnObject.lastName = "Targaryen"
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
        token.invalidate()
    }

    var changeDictionary: [NSKeyValueChangeKey: Any]?

    override class func observeValue(forKeyPath keyPath: String?,
                                     of object: Any?,
                                     change: [NSKeyValueChangeKey: Any]?,
                                     context: UnsafeMutableRawPointer?) {
        // noop
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        changeDictionary = change
    }

    // swiftlint:disable:next cyclomatic_complexity
    func observeChange<T: Equatable>(_ obj: AllTypesPrimitiveProjection, _ key: String, _ old: T?, _ new: T?,
                                     fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        let kvoOptions: NSKeyValueObservingOptions = [.old, .new]
        obj.addObserver(self, forKeyPath: key, options: kvoOptions, context: nil)
        try! obj.realm!.write {
            block()
        }
        obj.removeObserver(self, forKeyPath: key)

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

    func observeListChange(_ obj: AllTypesPrimitiveProjection, _ key: String, _ kind: NSKeyValueChange, _ indexes: NSIndexSet = NSIndexSet(index: 0),
                           fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        obj.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
        obj.realm?.beginWrite()
        block()
        try! obj.realm?.commitWrite()
        obj.removeObserver(self, forKeyPath: key)
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

    func newObjects(_ defaultValues: [String: Any] = [:]) -> (ModernAllTypesObject, AllTypesPrimitiveProjection) {
        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.delete(realm.objects(ModernAllTypesObject.self))
        let obj = realm.create(ModernAllTypesObject.self, value: defaultValues)
        let obs = AllTypesPrimitiveProjection(projecting: obj)
        try! realm.commitWrite()
        return (obj, obs)
    }

    func observeSetChange(_ obj: AllTypesPrimitiveProjection, _ key: String,
                          fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        obj.addObserver(self, forKeyPath: key, options: [], context: nil)
        obj.realm!.beginWrite()
        block()
        try! obj.realm!.commitWrite()
        obj.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: (fileName), line: lineNumber)
        guard changeDictionary != nil else { return }

        let actualKind = NSKeyValueChange(rawValue: (changeDictionary![NSKeyValueChangeKey.kindKey] as! NSNumber).uintValue)!
        XCTAssert(actualKind == NSKeyValueChange.setting, "Change kind: expected NSKeyValueChange.setting, got \(actualKind)", file: (fileName),
            line: lineNumber)

        changeDictionary = nil
    }

    func testAllPropertyTypes() {
        var (obj, obs) = newObjects(allTypeValues)

        let data = "b".data(using: String.Encoding.utf8)!
        let date = Date(timeIntervalSince1970: 2)
        let decimal = Decimal128(number: 3)
        let objectId = ObjectId()
        let uuid = UUID()

        observeChange(obs, "boolCol", true, false) { obj.boolCol = false }
        observeChange(obs, "int8Col", 11 as Int8, 10) { obj.int8Col = 10 }
        observeChange(obs, "int16Col", 12 as Int16, 10) { obj.int16Col = 10 }
        observeChange(obs, "int32Col", 13 as Int32, 10) { obj.int32Col = 10 }
        observeChange(obs, "int64Col", 14 as Int64, 10) { obj.int64Col = 10 }
        observeChange(obs, "floatCol", 15 as Float, 10) { obj.floatCol = 10 }
        observeChange(obs, "doubleCol", 16 as Double, 10) { obj.doubleCol = 10 }
        observeChange(obs, "stringCol", "a", "abc") { obj.stringCol = "abc" }
        observeChange(obs, "objectCol", obj.objectCol, obj) { obj.objectCol = obj }
        observeChange(obs, "binaryCol", obj.binaryCol, data) { obj.binaryCol = data }
        observeChange(obs, "dateCol", obj.dateCol, date) { obj.dateCol = date }
        observeChange(obs, "decimalCol", obj.decimalCol, decimal) { obj.decimalCol = decimal }
        observeChange(obs, "objectIdCol", obj.objectIdCol, objectId) { obj.objectIdCol = objectId }
        observeChange(obs, "uuidCol", obj.uuidCol, uuid) { obj.uuidCol = uuid }
        observeChange(obs, "anyCol", 20, 1) { obj.anyCol = .int(1) }

        (obj, obs) = newObjects()

        observeListChange(obs, "arrayCol", .insertion) { obj.arrayCol.append(obj) }
        observeListChange(obs, "arrayCol", .removal) { obj.arrayCol.removeAll() }
        observeSetChange(obs, "setCol") { obj.setCol.insert(obj) }
        observeSetChange(obs, "setCol") { obj.setCol.remove(obj) }

        observeChange(obs, "optIntCol", nil, 10) { obj.optIntCol = 10 }
        observeChange(obs, "optFloatCol", nil, 10.0) { obj.optFloatCol = 10 }
        observeChange(obs, "optDoubleCol", nil, 10.0) { obj.optDoubleCol = 10 }
        observeChange(obs, "optBoolCol", nil, true) { obj.optBoolCol = true }
        observeChange(obs, "optStringCol", nil, "abc") { obj.optStringCol = "abc" }
        observeChange(obs, "optBinaryCol", nil, data) { obj.optBinaryCol = data }
        observeChange(obs, "optDateCol", nil, date) { obj.optDateCol = date }
        observeChange(obs, "optDecimalCol", nil, decimal) { obj.optDecimalCol = decimal }
        observeChange(obs, "optObjectIdCol", nil, objectId) { obj.optObjectIdCol = objectId }
        observeChange(obs, "optUuidCol", nil, uuid) { obj.optUuidCol = uuid }

        observeChange(obs, "optIntCol", 10, nil) { obj.optIntCol = nil }
        observeChange(obs, "optFloatCol", 10.0, nil) { obj.optFloatCol = nil }
        observeChange(obs, "optDoubleCol", 10.0, nil) { obj.optDoubleCol = nil }
        observeChange(obs, "optBoolCol", true, nil) { obj.optBoolCol = nil }
        observeChange(obs, "optStringCol", "abc", nil) { obj.optStringCol = nil }
        observeChange(obs, "optBinaryCol", data, nil) { obj.optBinaryCol = nil }
        observeChange(obs, "optDateCol", date, nil) { obj.optDateCol = nil }
        observeChange(obs, "optDecimalCol", decimal, nil) { obj.optDecimalCol = nil }
        observeChange(obs, "optObjectIdCol", objectId, nil) { obj.optObjectIdCol = nil }
        observeChange(obs, "optUuidCol", uuid, nil) { obj.optUuidCol = nil }

        // .insertion append
        observeListChange(obs, "arrayBool", .insertion) { obj.arrayBool.append(true) }
        observeListChange(obs, "arrayInt", .insertion) { obj.arrayInt.append(10) }
        observeListChange(obs, "arrayInt8", .insertion) { obj.arrayInt8.append(10) }
        observeListChange(obs, "arrayInt16", .insertion) { obj.arrayInt16.append(10) }
        observeListChange(obs, "arrayInt32", .insertion) { obj.arrayInt32.append(10) }
        observeListChange(obs, "arrayInt64", .insertion) { obj.arrayInt64.append(10) }
        observeListChange(obs, "arrayFloat", .insertion) { obj.arrayFloat.append(10.0) }
        observeListChange(obs, "arrayDouble", .insertion) { obj.arrayDouble.append(10.0) }
        observeListChange(obs, "arrayString", .insertion) { obj.arrayString.append("10") }
        observeListChange(obs, "arrayBinary", .insertion) { obj.arrayBinary.append(data) }
        observeListChange(obs, "arrayDate", .insertion) { obj.arrayDate.append(date) }
        observeListChange(obs, "arrayDecimal", .insertion) { obj.arrayDecimal.append(decimal) }
        observeListChange(obs, "arrayObjectId", .insertion) { obj.arrayObjectId.append(objectId) }
        observeListChange(obs, "arrayAny", .insertion) { obj.arrayAny.append(.int(10)) }
        observeListChange(obs, "arrayUuid", .insertion) { obj.arrayUuid.append(uuid) }

        observeListChange(obs, "arrayOptBool", .insertion) { obj.arrayOptBool.append(true) }
        observeListChange(obs, "arrayOptInt", .insertion) { obj.arrayOptInt.append(10) }
        observeListChange(obs, "arrayOptInt8", .insertion) { obj.arrayOptInt8.append(10) }
        observeListChange(obs, "arrayOptInt16", .insertion) { obj.arrayOptInt16.append(10) }
        observeListChange(obs, "arrayOptInt32", .insertion) { obj.arrayOptInt32.append(10) }
        observeListChange(obs, "arrayOptInt64", .insertion) { obj.arrayOptInt64.append(10) }
        observeListChange(obs, "arrayOptFloat", .insertion) { obj.arrayOptFloat.append(10.0) }
        observeListChange(obs, "arrayOptDouble", .insertion) { obj.arrayOptDouble.append(10.0) }
        observeListChange(obs, "arrayOptString", .insertion) { obj.arrayOptString.append("10") }
        observeListChange(obs, "arrayOptBinary", .insertion) { obj.arrayOptBinary.append(data) }
        observeListChange(obs, "arrayOptDate", .insertion) { obj.arrayOptDate.append(date) }
        observeListChange(obs, "arrayOptDecimal", .insertion) { obj.arrayOptDecimal.append(decimal) }
        observeListChange(obs, "arrayOptObjectId", .insertion) { obj.arrayOptObjectId.append(objectId) }
        observeListChange(obs, "arrayOptUuid", .insertion) { obj.arrayOptUuid.append(uuid) }

        (obj, obs) = newObjects()
        observeListChange(obs, "arrayOptBool", .insertion) { obj.arrayOptBool.append(nil) }
        observeListChange(obs, "arrayOptInt", .insertion) { obj.arrayOptInt.append(nil) }
        observeListChange(obs, "arrayOptInt8", .insertion) { obj.arrayOptInt8.append(nil) }
        observeListChange(obs, "arrayOptInt16", .insertion) { obj.arrayOptInt16.append(nil) }
        observeListChange(obs, "arrayOptInt32", .insertion) { obj.arrayOptInt32.append(nil) }
        observeListChange(obs, "arrayOptInt64", .insertion) { obj.arrayOptInt64.append(nil) }
        observeListChange(obs, "arrayOptFloat", .insertion) { obj.arrayOptFloat.append(nil) }
        observeListChange(obs, "arrayOptDouble", .insertion) { obj.arrayOptDouble.append(nil) }
        observeListChange(obs, "arrayOptString", .insertion) { obj.arrayOptString.append(nil) }
        observeListChange(obs, "arrayOptBinary", .insertion) { obj.arrayOptBinary.append(nil) }
        observeListChange(obs, "arrayOptDate", .insertion) { obj.arrayOptDate.append(nil) }
        observeListChange(obs, "arrayOptDecimal", .insertion) { obj.arrayOptDecimal.append(nil) }
        observeListChange(obs, "arrayOptObjectId", .insertion) { obj.arrayOptObjectId.append(nil) }
        observeListChange(obs, "arrayOptUuid", .insertion) { obj.arrayOptUuid.append(nil) }

        // .insertion insert at
        observeListChange(obs, "arrayBool", .insertion) { obj.arrayBool.insert(true, at: 0) }
        observeListChange(obs, "arrayInt", .insertion) { obj.arrayInt.append(10) }
        observeListChange(obs, "arrayInt8", .insertion) { obj.arrayInt8.insert(10, at: 0) }
        observeListChange(obs, "arrayInt16", .insertion) { obj.arrayInt16.insert(10, at: 0) }
        observeListChange(obs, "arrayInt32", .insertion) { obj.arrayInt32.insert(10, at: 0) }
        observeListChange(obs, "arrayInt64", .insertion) { obj.arrayInt64.insert(10, at: 0) }
        observeListChange(obs, "arrayFloat", .insertion) { obj.arrayFloat.insert(10, at: 0) }
        observeListChange(obs, "arrayDouble", .insertion) { obj.arrayDouble.insert(10, at: 0) }
        observeListChange(obs, "arrayString", .insertion) { obj.arrayString.insert("abc", at: 0) }
        observeListChange(obs, "arrayBinary", .insertion) { obj.arrayBinary.append(data) }
        observeListChange(obs, "arrayDate", .insertion) { obj.arrayDate.append(date) }
        observeListChange(obs, "arrayDecimal", .insertion) { obj.arrayDecimal.insert(decimal, at: 0) }
        observeListChange(obs, "arrayObjectId", .insertion) { obj.arrayObjectId.insert(objectId, at: 0) }
        observeListChange(obs, "arrayUuid", .insertion) { obj.arrayUuid.insert(uuid, at: 0) }
        observeListChange(obs, "arrayAny", .insertion) { obj.arrayAny.insert(.string("a"), at: 0) }

        observeListChange(obs, "arrayOptBool", .insertion) { obj.arrayOptBool.insert(true, at: 0) }
        observeListChange(obs, "arrayOptInt", .insertion) { obj.arrayOptInt.insert(10, at: 0) }
        observeListChange(obs, "arrayOptInt8", .insertion) { obj.arrayOptInt8.insert(10, at: 0) }
        observeListChange(obs, "arrayOptInt16", .insertion) { obj.arrayOptInt16.insert(10, at: 0) }
        observeListChange(obs, "arrayOptInt32", .insertion) { obj.arrayOptInt32.insert(10, at: 0) }
        observeListChange(obs, "arrayOptInt64", .insertion) { obj.arrayOptInt64.insert(10, at: 0) }
        observeListChange(obs, "arrayOptFloat", .insertion) { obj.arrayOptFloat.insert(10, at: 0) }
        observeListChange(obs, "arrayOptDouble", .insertion) { obj.arrayOptDouble.insert(10, at: 0) }
        observeListChange(obs, "arrayOptString", .insertion) { obj.arrayOptString.insert("abc", at: 0) }
        observeListChange(obs, "arrayOptBinary", .insertion) { obj.arrayOptBinary.insert(data, at: 0) }
        observeListChange(obs, "arrayOptDate", .insertion) { obj.arrayOptDate.insert(date, at: 0) }
        observeListChange(obs, "arrayOptDecimal", .insertion) { obj.arrayOptDecimal.insert(decimal, at: 0) }
        observeListChange(obs, "arrayOptObjectId", .insertion) { obj.arrayOptObjectId.insert(objectId, at: 0) }
        observeListChange(obs, "arrayOptUuid", .insertion) { obj.arrayOptUuid.insert(uuid, at: 0) }

        observeListChange(obs, "arrayOptBool", .insertion) { obj.arrayOptBool.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt", .insertion) { obj.arrayOptInt.insert(nil, at: 0) }
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
        // .replacement
        observeListChange(obs, "arrayBool", .replacement) { obj.arrayBool[0] = true }
        observeListChange(obs, "arrayInt", .replacement) { obj.arrayInt[0] = 10 }
        observeListChange(obs, "arrayInt8", .replacement) { obj.arrayInt8[0] = 10 }
        observeListChange(obs, "arrayInt16", .replacement) { obj.arrayInt16[0] = 10 }
        observeListChange(obs, "arrayInt32", .replacement) { obj.arrayInt32[0] = 10 }
        observeListChange(obs, "arrayInt64", .replacement) { obj.arrayInt64[0] = 10 }
        observeListChange(obs, "arrayFloat", .replacement) { obj.arrayFloat[0] = 10 }
        observeListChange(obs, "arrayDouble", .replacement) { obj.arrayDouble[0] = 10 }
        observeListChange(obs, "arrayString", .replacement) { obj.arrayString[0] = "abc" }
        observeListChange(obs, "arrayBinary", .replacement) { obj.arrayBinary[0] = data }
        observeListChange(obs, "arrayDate", .replacement) { obj.arrayDate[0] = date }
        observeListChange(obs, "arrayDecimal", .replacement) { obj.arrayDecimal[0] = decimal }
        observeListChange(obs, "arrayObjectId", .replacement) { obj.arrayObjectId[0] = objectId }
        observeListChange(obs, "arrayUuid", .replacement) { obj.arrayUuid[0] = uuid }
        observeListChange(obs, "arrayAny", .replacement) { obj.arrayAny[0] = .string("a") }

        observeListChange(obs, "arrayOptBool", .replacement) { obj.arrayOptBool[0] = true }
        observeListChange(obs, "arrayOptInt", .replacement) { obj.arrayOptInt[0] = 10 }
        observeListChange(obs, "arrayOptInt8", .replacement) { obj.arrayOptInt8[0] = 10 }
        observeListChange(obs, "arrayOptInt16", .replacement) { obj.arrayOptInt16[0] = 10 }
        observeListChange(obs, "arrayOptInt32", .replacement) { obj.arrayOptInt32[0] = 10 }
        observeListChange(obs, "arrayOptInt64", .replacement) { obj.arrayOptInt64[0] = 10 }
        observeListChange(obs, "arrayOptFloat", .replacement) { obj.arrayOptFloat[0] = 10 }
        observeListChange(obs, "arrayOptDouble", .replacement) { obj.arrayOptDouble[0] = 10 }
        observeListChange(obs, "arrayOptString", .replacement) { obj.arrayOptString[0] = "abc" }
        observeListChange(obs, "arrayOptBinary", .replacement) { obj.arrayOptBinary[0] = data }
        observeListChange(obs, "arrayOptDate", .replacement) { obj.arrayOptDate[0] = date }
        observeListChange(obs, "arrayOptBinary", .replacement) { obj.arrayOptBinary[0] = data }
        observeListChange(obs, "arrayOptDate", .replacement) { obj.arrayOptDate[0] = date }
        observeListChange(obs, "arrayOptDecimal", .replacement) { obj.arrayOptDecimal[0] = decimal }
        observeListChange(obs, "arrayOptObjectId", .replacement) { obj.arrayOptObjectId[0] = objectId }
        observeListChange(obs, "arrayOptUuid", .replacement) { obj.arrayOptUuid[0] = uuid }

        observeListChange(obs, "arrayOptBool", .replacement) { obj.arrayOptBool[0] = nil }
        observeListChange(obs, "arrayOptInt", .replacement) { obj.arrayOptInt[0] = nil }
        observeListChange(obs, "arrayOptInt8", .replacement) { obj.arrayOptInt8[0] = nil }
        observeListChange(obs, "arrayOptInt16", .replacement) { obj.arrayOptInt16[0] = nil }
        observeListChange(obs, "arrayOptInt32", .replacement) { obj.arrayOptInt32[0] = nil }
        observeListChange(obs, "arrayOptInt64", .replacement) { obj.arrayOptInt64[0] = nil }
        observeListChange(obs, "arrayOptFloat", .replacement) { obj.arrayOptFloat[0] = nil }
        observeListChange(obs, "arrayOptDouble", .replacement) { obj.arrayOptDouble[0] = nil }
        observeListChange(obs, "arrayOptString", .replacement) { obj.arrayOptString[0] = nil }
        observeListChange(obs, "arrayOptBinary", .replacement) { obj.arrayOptBinary[0] = nil }
        observeListChange(obs, "arrayOptDate", .replacement) { obj.arrayOptDate[0] = nil }
        observeListChange(obs, "arrayOptDate", .replacement) { obj.arrayOptDate[0] = nil }
        observeListChange(obs, "arrayOptBinary", .replacement) { obj.arrayOptBinary[0] = nil }
        observeListChange(obs, "arrayOptDecimal", .replacement) { obj.arrayOptDecimal[0] = nil }
        observeListChange(obs, "arrayOptObjectId", .replacement) { obj.arrayOptObjectId[0] = nil }
        observeListChange(obs, "arrayOptUuid", .replacement) { obj.arrayOptUuid[0] = nil }

        // .removal removeAll
        observeListChange(obs, "arrayBool", .removal) { obj.arrayBool.removeAll() }
        observeListChange(obs, "arrayInt", .removal) { obj.arrayInt.removeAll() }
        observeListChange(obs, "arrayInt8", .removal) { obj.arrayInt8.removeAll() }
        observeListChange(obs, "arrayInt16", .removal) { obj.arrayInt16.removeAll() }
        observeListChange(obs, "arrayInt32", .removal) { obj.arrayInt32.removeAll() }
        observeListChange(obs, "arrayInt64", .removal) { obj.arrayInt64.removeAll() }
        observeListChange(obs, "arrayFloat", .removal) { obj.arrayFloat.removeAll() }
        observeListChange(obs, "arrayDouble", .removal) { obj.arrayDouble.removeAll() }
        observeListChange(obs, "arrayString", .removal) { obj.arrayString.removeAll() }
        observeListChange(obs, "arrayBinary", .removal) { obj.arrayBinary.removeAll() }
        observeListChange(obs, "arrayDate", .removal) { obj.arrayDate.removeAll() }
        observeListChange(obs, "arrayDecimal", .removal) { obj.arrayDecimal.removeAll() }
        observeListChange(obs, "arrayObjectId", .removal) { obj.arrayObjectId.removeAll() }
        observeListChange(obs, "arrayUuid", .removal) { obj.arrayUuid.removeAll() }
        observeListChange(obs, "arrayAny", .removal) { obj.arrayAny.removeAll() }

        let indices = NSIndexSet(indexesIn: NSRange(location: 0, length: 3))
        observeListChange(obs, "arrayOptBool", .removal, indices) { obj.arrayOptBool.removeAll() }
        observeListChange(obs, "arrayOptInt", .removal, indices) { obj.arrayOptInt.removeAll() }
        observeListChange(obs, "arrayOptInt8", .removal, indices) { obj.arrayOptInt8.removeAll() }
        observeListChange(obs, "arrayOptInt16", .removal, indices) { obj.arrayOptInt16.removeAll() }
        observeListChange(obs, "arrayOptInt32", .removal, indices) { obj.arrayOptInt32.removeAll() }
        observeListChange(obs, "arrayOptInt64", .removal, indices) { obj.arrayOptInt64.removeAll() }
        observeListChange(obs, "arrayOptFloat", .removal, indices) { obj.arrayOptFloat.removeAll() }
        observeListChange(obs, "arrayOptDouble", .removal, indices) { obj.arrayOptDouble.removeAll() }
        observeListChange(obs, "arrayOptString", .removal, indices) { obj.arrayOptString.removeAll() }
        observeListChange(obs, "arrayOptBinary", .removal, indices) { obj.arrayOptBinary.removeAll() }
        observeListChange(obs, "arrayOptDate", .removal, indices) { obj.arrayOptDate.removeAll() }
        observeListChange(obs, "arrayOptDecimal", .removal, indices) { obj.arrayOptDecimal.removeAll() }
        observeListChange(obs, "arrayOptObjectId", .removal, indices) { obj.arrayOptObjectId.removeAll() }
        observeListChange(obs, "arrayOptUuid", .removal, indices) { obj.arrayOptUuid.removeAll() }

        // .removal remove at
        (obj, obs) = newObjects(allTypeValues)
        observeListChange(obs, "arrayBool", .removal) { obj.arrayBool.remove(at: 0) }
        observeListChange(obs, "arrayInt", .removal) { obj.arrayInt.remove(at: 0) }
        observeListChange(obs, "arrayInt8", .removal) { obj.arrayInt8.remove(at: 0) }
        observeListChange(obs, "arrayInt16", .removal) { obj.arrayInt16.remove(at: 0) }
        observeListChange(obs, "arrayInt32", .removal) { obj.arrayInt32.remove(at: 0) }
        observeListChange(obs, "arrayInt64", .removal) { obj.arrayInt64.remove(at: 0) }
        observeListChange(obs, "arrayFloat", .removal) { obj.arrayFloat.remove(at: 0) }
        observeListChange(obs, "arrayDouble", .removal) { obj.arrayDouble.remove(at: 0) }
        observeListChange(obs, "arrayString", .removal) { obj.arrayString.remove(at: 0) }
        observeListChange(obs, "arrayBinary", .removal) { obj.arrayBinary.remove(at: 0) }
        observeListChange(obs, "arrayDate", .removal) { obj.arrayDate.remove(at: 0) }
        observeListChange(obs, "arrayDecimal", .removal) { obj.arrayDecimal.remove(at: 0) }
        observeListChange(obs, "arrayObjectId", .removal) { obj.arrayObjectId.remove(at: 0) }
        observeListChange(obs, "arrayUuid", .removal) { obj.arrayUuid.remove(at: 0) }
        observeListChange(obs, "arrayAny", .removal) { obj.arrayAny.remove(at: 0) }

        observeListChange(obs, "arrayOptBool", .removal) { obj.arrayOptBool.remove(at: 0) }
        observeListChange(obs, "arrayOptInt", .removal) { obj.arrayOptInt.remove(at: 0) }
        observeListChange(obs, "arrayOptInt8", .removal) { obj.arrayOptInt8.remove(at: 0) }
        observeListChange(obs, "arrayOptInt16", .removal) { obj.arrayOptInt16.remove(at: 0) }
        observeListChange(obs, "arrayOptInt32", .removal) { obj.arrayOptInt32.remove(at: 0) }
        observeListChange(obs, "arrayOptInt64", .removal) { obj.arrayOptInt64.remove(at: 0) }
        observeListChange(obs, "arrayOptFloat", .removal) { obj.arrayOptFloat.remove(at: 0) }
        observeListChange(obs, "arrayOptDouble", .removal) { obj.arrayOptDouble.remove(at: 0) }
        observeListChange(obs, "arrayOptString", .removal) { obj.arrayOptString.remove(at: 0) }
        observeListChange(obs, "arrayOptBinary", .removal) { obj.arrayOptBinary.remove(at: 0) }
        observeListChange(obs, "arrayOptDate", .removal) { obj.arrayOptDate.remove(at: 0) }
        observeListChange(obs, "arrayOptDecimal", .removal) { obj.arrayOptDecimal.remove(at: 0) }
        observeListChange(obs, "arrayOptObjectId", .removal) { obj.arrayOptObjectId.remove(at: 0) }
        observeListChange(obs, "arrayOptUuid", .removal) { obj.arrayOptUuid.remove(at: 0) }

        // insert
        observeSetChange(obs, "setBool") { obj.setBool.insert(true) }
        observeSetChange(obs, "setInt") { obj.setInt.insert(10) }
        observeSetChange(obs, "setInt8") { obj.setInt8.insert(10) }
        observeSetChange(obs, "setInt16") { obj.setInt16.insert(10) }
        observeSetChange(obs, "setInt32") { obj.setInt32.insert(10) }
        observeSetChange(obs, "setInt64") { obj.setInt64.insert(10) }
        observeSetChange(obs, "setFloat") { obj.setFloat.insert(10.0) }
        observeSetChange(obs, "setDouble") { obj.setDouble.insert(10.0) }
        observeSetChange(obs, "setString") { obj.setString.insert("10") }
        observeSetChange(obs, "setBinary") { obj.setBinary.insert(data) }
        observeSetChange(obs, "setDate") { obj.setDate.insert(date) }
        observeSetChange(obs, "setDecimal") { obj.setDecimal.insert(decimal) }
        observeSetChange(obs, "setObjectId") { obj.setObjectId.insert(objectId) }
        observeSetChange(obs, "setAny") { obj.setAny.insert(.string("a")) }
        observeSetChange(obs, "setUuid") { obj.setUuid.insert(uuid) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.insert(true) }
        observeSetChange(obs, "setOptInt") { obj.setOptInt.insert(10) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.insert(10) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.insert(10) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.insert(10) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.insert(10) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.insert(10.0) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.insert(10.0) }
        observeSetChange(obs, "setOptString") { obj.setOptString.insert("10") }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.insert(data) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.insert(date) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.insert(decimal) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.insert(objectId) }
        observeSetChange(obs, "setOptUuid") { obj.setOptUuid.insert(uuid) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.insert(nil) }
        observeSetChange(obs, "setOptInt") { obj.setOptInt.insert(nil) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.insert(nil) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.insert(nil) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.insert(nil) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.insert(nil) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.insert(nil) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.insert(nil) }
        observeSetChange(obs, "setOptString") { obj.setOptString.insert(nil) }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.insert(nil) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.insert(nil) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.insert(nil) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.insert(nil) }
        observeSetChange(obs, "setOptUuid") { obj.setOptUuid.insert(nil) }

        // insert objectsIn
        observeSetChange(obs, "setBool") { obj.setBool.insert(objectsIn: [true]) }
        observeSetChange(obs, "setInt") { obj.setInt.insert(objectsIn: [10]) }
        observeSetChange(obs, "setInt8") { obj.setInt8.insert(objectsIn: [10]) }
        observeSetChange(obs, "setInt16") { obj.setInt16.insert(objectsIn: [10]) }
        observeSetChange(obs, "setInt32") { obj.setInt32.insert(objectsIn: [10]) }
        observeSetChange(obs, "setInt64") { obj.setInt64.insert(objectsIn: [10]) }
        observeSetChange(obs, "setFloat") { obj.setFloat.insert(objectsIn: [10.0]) }
        observeSetChange(obs, "setDouble") { obj.setDouble.insert(objectsIn: [10.0]) }
        observeSetChange(obs, "setString") { obj.setString.insert(objectsIn: ["10"]) }
        observeSetChange(obs, "setBinary") { obj.setBinary.insert(objectsIn: [data]) }
        observeSetChange(obs, "setDate") { obj.setDate.insert(objectsIn: [date]) }
        observeSetChange(obs, "setDecimal") { obj.setDecimal.insert(objectsIn: [decimal]) }
        observeSetChange(obs, "setObjectId") { obj.setObjectId.insert(objectsIn: [objectId]) }
        observeSetChange(obs, "setAny") { obj.setAny.insert(objectsIn: [.string("a")]) }
        observeSetChange(obs, "setUuid") { obj.setUuid.insert(objectsIn: [uuid]) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.insert(objectsIn: [true, nil]) }
        observeSetChange(obs, "setOptInt") { obj.setOptInt.insert(objectsIn: [10, nil]) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.insert(objectsIn: [10, nil]) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.insert(objectsIn: [10, nil]) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.insert(objectsIn: [10, nil]) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.insert(objectsIn: [10, nil]) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.insert(objectsIn: [10.0, nil]) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.insert(objectsIn: [10.0, nil]) }
        observeSetChange(obs, "setOptString") { obj.setOptString.insert(objectsIn: ["10", nil]) }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.insert(objectsIn: [data, nil]) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.insert(objectsIn: [date, nil]) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.insert(objectsIn: [decimal, nil]) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.insert(objectsIn: [objectId, nil]) }
        observeSetChange(obs, "setOptUuid") { obj.setOptUuid.insert(objectsIn: [uuid, nil]) }

        // delete
        observeSetChange(obs, "setBool") { obj.setBool.remove(true) }
        observeSetChange(obs, "setInt") { obj.setInt.remove(10) }
        observeSetChange(obs, "setInt8") { obj.setInt8.remove(10) }
        observeSetChange(obs, "setInt16") { obj.setInt16.remove(10) }
        observeSetChange(obs, "setInt32") { obj.setInt32.remove(10) }
        observeSetChange(obs, "setInt64") { obj.setInt64.remove(10) }
        observeSetChange(obs, "setFloat") { obj.setFloat.remove(10.0) }
        observeSetChange(obs, "setDouble") { obj.setDouble.remove(10.0) }
        observeSetChange(obs, "setString") { obj.setString.remove("10") }
        observeSetChange(obs, "setBinary") { obj.setBinary.remove(data) }
        observeSetChange(obs, "setDate") { obj.setDate.remove(date) }
        observeSetChange(obs, "setDecimal") { obj.setDecimal.remove(decimal) }
        observeSetChange(obs, "setObjectId") { obj.setObjectId.remove(objectId) }
        observeSetChange(obs, "setAny") { obj.setAny.remove(.string("a")) }
        observeSetChange(obs, "setUuid") { obj.setUuid.remove(uuid) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.remove(true) }
        observeSetChange(obs, "setOptInt") { obj.setOptInt.remove(10) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.remove(10) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.remove(10) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.remove(10) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.remove(10) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.remove(10.0) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.remove(10.0) }
        observeSetChange(obs, "setOptString") { obj.setOptString.remove("10") }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.remove(data) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.remove(date) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.remove(decimal) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.remove(objectId) }
        observeSetChange(obs, "setOptUuid") { obj.setOptUuid.remove(uuid) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.remove(nil) }
        observeSetChange(obs, "setOptInt") { obj.setOptInt.remove(nil) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.remove(nil) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.remove(nil) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.remove(nil) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.remove(nil) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.remove(nil) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.remove(nil) }
        observeSetChange(obs, "setOptString") { obj.setOptString.remove(nil) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.remove(nil) }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.remove(nil) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.remove(nil) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.remove(nil) }
        observeSetChange(obs, "setOptUuid") { obj.setOptUuid.remove(nil) }
        // delete all
        observeSetChange(obs, "setBool") { obj.setBool.removeAll() }
        observeSetChange(obs, "setInt") { obj.setInt.removeAll() }
        observeSetChange(obs, "setInt8") { obj.setInt8.removeAll() }
        observeSetChange(obs, "setInt16") { obj.setInt16.removeAll() }
        observeSetChange(obs, "setInt32") { obj.setInt32.removeAll() }
        observeSetChange(obs, "setInt64") { obj.setInt64.removeAll() }
        observeSetChange(obs, "setFloat") { obj.setFloat.removeAll() }
        observeSetChange(obs, "setDouble") { obj.setDouble.removeAll() }
        observeSetChange(obs, "setString") { obj.setString.removeAll() }
        observeSetChange(obs, "setBinary") { obj.setBinary.removeAll() }
        observeSetChange(obs, "setDate") { obj.setDate.removeAll() }
        observeSetChange(obs, "setDecimal") { obj.setDecimal.removeAll() }
        observeSetChange(obs, "setObjectId") { obj.setObjectId.removeAll() }
        observeSetChange(obs, "setAny") { obj.setAny.removeAll() }
        observeSetChange(obs, "setUuid") { obj.setUuid.removeAll() }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.removeAll() }
        observeSetChange(obs, "setOptInt") { obj.setOptInt.removeAll() }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.removeAll() }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.removeAll() }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.removeAll() }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.removeAll() }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.removeAll() }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.removeAll() }
        observeSetChange(obs, "setOptString") { obj.setOptString.removeAll() }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.removeAll() }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.removeAll() }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.removeAll() }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.removeAll() }
        observeSetChange(obs, "setOptUuid") { obj.setOptUuid.removeAll() }

        observeSetChange(obs, "mapBool") { obj.mapBool["key"] = true }
        observeSetChange(obs, "mapInt") { obj.mapInt["key"] = 10 }
        observeSetChange(obs, "mapInt8") { obj.mapInt8["key"] = 10 }
        observeSetChange(obs, "mapInt16") { obj.mapInt16["key"] = 10 }
        observeSetChange(obs, "mapInt32") { obj.mapInt32["key"] = 10 }
        observeSetChange(obs, "mapInt64") { obj.mapInt64["key"] = 10 }
        observeSetChange(obs, "mapFloat") { obj.mapFloat["key"] = 10.0 }
        observeSetChange(obs, "mapDouble") { obj.mapDouble["key"] = 10.0 }
        observeSetChange(obs, "mapString") { obj.mapString["key"] = "10" }
        observeSetChange(obs, "mapBinary") { obj.mapBinary["key"] = data }
        observeSetChange(obs, "mapDate") { obj.mapDate["key"] = date }
        observeSetChange(obs, "mapDecimal") { obj.mapDecimal["key"] = decimal }
        observeSetChange(obs, "mapObjectId") { obj.mapObjectId["key"] = objectId }
        observeSetChange(obs, "mapAny") { obj.mapAny["key"] = .string("a") }
        observeSetChange(obs, "mapUuid") { obj.mapUuid["key"] = uuid }

        observeSetChange(obs, "mapOptBool") { obj.mapOptBool["key"] = true }
        observeSetChange(obs, "mapOptInt") { obj.mapOptInt["key"] = 10 }
        observeSetChange(obs, "mapOptInt8") { obj.mapOptInt8["key"] = 10 }
        observeSetChange(obs, "mapOptInt16") { obj.mapOptInt16["key"] = 10 }
        observeSetChange(obs, "mapOptInt32") { obj.mapOptInt32["key"] = 10 }
        observeSetChange(obs, "mapOptInt64") { obj.mapOptInt64["key"] = 10 }
        observeSetChange(obs, "mapOptFloat") { obj.mapOptFloat["key"] = 10.0 }
        observeSetChange(obs, "mapOptDouble") { obj.mapOptDouble["key"] = 10.0 }
        observeSetChange(obs, "mapOptString") { obj.mapOptString["key"] = "10" }
        observeSetChange(obs, "mapOptBinary") { obj.mapOptBinary["key"] = data }
        observeSetChange(obs, "mapOptDate") { obj.mapOptDate["key"] = date }
        observeSetChange(obs, "mapOptDecimal") { obj.mapOptDecimal["key"] = decimal }
        observeSetChange(obs, "mapOptObjectId") { obj.mapOptObjectId["key"] = objectId }
        observeSetChange(obs, "mapOptUuid") { obj.mapOptUuid["key"] = uuid }

        observeSetChange(obs, "mapBool") { obj.mapBool["key"] = nil }
        observeSetChange(obs, "mapInt") { obj.mapInt["key"] = nil }
        observeSetChange(obs, "mapInt8") { obj.mapInt8["key"] = nil }
        observeSetChange(obs, "mapInt16") { obj.mapInt16["key"] = nil }
        observeSetChange(obs, "mapInt32") { obj.mapInt32["key"] = nil }
        observeSetChange(obs, "mapInt64") { obj.mapInt64["key"] = nil }
        observeSetChange(obs, "mapFloat") { obj.mapFloat["key"] = nil }
        observeSetChange(obs, "mapDouble") { obj.mapDouble["key"] = nil }
        observeSetChange(obs, "mapString") { obj.mapString["key"] = nil }
        observeSetChange(obs, "mapBinary") { obj.mapBinary["key"] = nil }
        observeSetChange(obs, "mapDate") { obj.mapDate["key"] = nil }
        observeSetChange(obs, "mapDecimal") { obj.mapDecimal["key"] = nil }
        observeSetChange(obs, "mapObjectId") { obj.mapObjectId["key"] = nil }
        observeSetChange(obs, "mapAny") { obj.mapAny["key"] = nil }
        observeSetChange(obs, "mapUuid") { obj.mapUuid["key"] = nil }

        observeSetChange(obs, "mapOptBool") { obj.mapOptBool["key"] = nil }
        observeSetChange(obs, "mapOptInt") { obj.mapOptInt["key"] = nil }
        observeSetChange(obs, "mapOptInt8") { obj.mapOptInt8["key"] = nil }
        observeSetChange(obs, "mapOptInt16") { obj.mapOptInt16["key"] = nil }
        observeSetChange(obs, "mapOptInt32") { obj.mapOptInt32["key"] = nil }
        observeSetChange(obs, "mapOptInt64") { obj.mapOptInt64["key"] = nil }
        observeSetChange(obs, "mapOptFloat") { obj.mapOptFloat["key"] = nil }
        observeSetChange(obs, "mapOptDouble") { obj.mapOptDouble["key"] = nil }
        observeSetChange(obs, "mapOptString") { obj.mapOptString["key"] = nil }
        observeSetChange(obs, "mapOptBinary") { obj.mapOptBinary["key"] = nil }
        observeSetChange(obs, "mapOptDate") { obj.mapOptDate["key"] = nil }
        observeSetChange(obs, "mapOptDecimal") { obj.mapOptDecimal["key"] = nil }
        observeSetChange(obs, "mapOptObjectId") { obj.mapOptObjectId["key"] = nil }
        observeSetChange(obs, "mapOptUuid") { obj.mapOptUuid["key"] = nil }

        observeSetChange(obs, "mapOptBool") { obj.mapOptBool.removeObject(for: "key") }
        observeSetChange(obs, "mapOptInt") { obj.mapOptInt.removeObject(for: "key") }
        observeSetChange(obs, "mapOptInt8") { obj.mapOptInt8.removeObject(for: "key") }
        observeSetChange(obs, "mapOptInt16") { obj.mapOptInt16.removeObject(for: "key") }
        observeSetChange(obs, "mapOptInt32") { obj.mapOptInt32.removeObject(for: "key") }
        observeSetChange(obs, "mapOptInt64") { obj.mapOptInt64.removeObject(for: "key") }
        observeSetChange(obs, "mapOptFloat") { obj.mapOptFloat.removeObject(for: "key") }
        observeSetChange(obs, "mapOptDouble") { obj.mapOptDouble.removeObject(for: "key") }
        observeSetChange(obs, "mapOptString") { obj.mapOptString.removeObject(for: "key") }
        observeSetChange(obs, "mapOptBinary") { obj.mapOptBinary.removeObject(for: "key") }
        observeSetChange(obs, "mapOptDate") { obj.mapOptDate.removeObject(for: "key") }
        observeSetChange(obs, "mapOptDecimal") { obj.mapOptDecimal.removeObject(for: "key") }
        observeSetChange(obs, "mapOptObjectId") { obj.mapOptObjectId.removeObject(for: "key") }
        observeSetChange(obs, "mapOptUuid") { obj.mapOptUuid.removeObject(for: "key") }
    }

    // MARK: Frozen Objects

    func simpleProjection() -> SimpleProjection {
        let realm = realmWithTestPath()
        var obj: SimpleObject!
        try! realm.write {
            obj = realm.create(SimpleObject.self)
        }
        return SimpleProjection(projecting: obj)
    }

    func testIsFrozen() {
        let projection = simpleProjection()
        let frozen = projection.freeze()
        XCTAssertFalse(projection.isFrozen)
        XCTAssertTrue(frozen.isFrozen)
    }

    func testFreezingFrozenObjectReturnsSelf() {
        let projection = simpleProjection()
        let frozen = projection.freeze()
        XCTAssertNotEqual(projection, frozen)
        XCTAssertFalse(projection.freeze() === frozen)
        XCTAssertEqual(frozen, frozen.freeze())
    }

    func testFreezingDeletedObject() {
        let projection = simpleProjection()
        let object = projection.rootObject
        try! projection.realm!.write({
            projection.realm!.delete(object)
        })
        assertThrows(projection.freeze(), "Object has been deleted or invalidated.")
    }

    func testFreezeFromWrongThread() {
        let projection = simpleProjection()
        dispatchSyncNewThread {
            self.assertThrows(projection.freeze(), "Realm accessed from incorrect thread")
        }
    }

    func testAccessFrozenObjectFromDifferentThread() {
        let projection = simpleProjection()
        let frozen = projection.freeze()
        dispatchSyncNewThread {
            XCTAssertEqual(frozen.int, 0)
        }
    }

    func testMutateFrozenObject() {
        let projection = simpleProjection()
        let frozen = projection.freeze()
        XCTAssertTrue(frozen.isFrozen)
        assertThrows(try! frozen.realm!.write { }, "Can't perform transactions on a frozen Realm")
    }

    func testObserveFrozenObject() {
        let frozen = simpleProjection().freeze()
        assertThrows(frozen.observe(keyPaths: [String](), { _ in }), "Frozen Realms do not change and do not have change notifications.")
    }

    func testFrozenObjectEquality() {
        let projectionA = simpleProjection()
        let frozenA1 = projectionA.freeze()
        let frozenA2 = projectionA.freeze()
        XCTAssertEqual(frozenA1, frozenA2)
        let projectionB = simpleProjection()
        let frozenB = projectionB.freeze()
        XCTAssertNotEqual(frozenA1, frozenB)
    }

    func testFreezeInsideWriteTransaction() {
        let realm = realmWithTestPath()
        var object: SimpleObject!
        var projection: SimpleProjection!
        try! realm.write {
            object = realm.create(SimpleObject.self)
            projection = SimpleProjection(projecting: object)
            self.assertThrows(projection.freeze(), "Cannot freeze an object in the same write transaction as it was created in.")
        }
        try! realm.write {
            object.int = 2
            // Frozen objects have the value of the object at the start of the transaction
            XCTAssertEqual(projection.freeze().int, 0)
        }
    }

    func testThaw() {
        let frozen = simpleProjection().freeze()
        XCTAssertTrue(frozen.isFrozen)
        let live = frozen.thaw()!
        XCTAssertFalse(live.isFrozen)
        try! live.realm!.write {
            live.int = 2
        }
        XCTAssertNotEqual(live.int, frozen.int)
    }

    func testThawDeleted() {
        let projection = simpleProjection()
        let frozen = projection.freeze()
        let realm = realmWithTestPath()

        XCTAssertTrue(frozen.isFrozen)
        try! realm.write {
            realm.deleteAll()
        }
        let thawed = frozen.thaw()
        XCTAssertNil(thawed, "Thaw should return nil when object was deleted")
    }

    func testThawPreviousVersion() {
        let projection = simpleProjection()
        let frozen = projection.freeze()

        XCTAssertTrue(frozen.isFrozen)
        XCTAssertEqual(projection.int, frozen.int)
        try! projection.realm!.write {
            projection.int = 1
        }
        XCTAssertNotEqual(projection.int, frozen.int, "Frozen object shouldn't mutate")

        let thawed = frozen.thaw()!
        XCTAssertFalse(thawed.isFrozen)
        XCTAssertEqual(thawed.int, projection.int, "Thawed object should reflect transactions since the original reference was frozen.")
    }

    func testThawUpdatedOnDifferentThread() {
        let realm = realmWithTestPath()
        let projection = simpleProjection()
        let tsr = ThreadSafeReference(to: projection)
        var frozen: SimpleProjection!

        dispatchSyncNewThread {
            let realm = self.realmWithTestPath()
            let resolvedProjection: SimpleProjection = realm.resolve(tsr)!
            try! realm.write {
                resolvedProjection.int = 1
            }
            frozen = resolvedProjection.freeze()
        }

        let thawed = frozen.thaw()!
        XCTAssertEqual(thawed.int, 0, "Thaw shouldn't reflect background transactions until main thread realm is refreshed")
        realm.refresh()
        XCTAssertEqual(thawed.int, 1)
    }

    func testThawCreatedOnDifferentThread() {
        let realm = realmWithTestPath()
        XCTAssertEqual(realm.objects(SimpleProjection.self).count, 0)
        var frozen: SimpleProjection!
        dispatchSyncNewThread {
            let projection = self.simpleProjection()
            frozen = projection.freeze()
        }
        XCTAssertNil(frozen.thaw())
        XCTAssertEqual(realm.objects(SimpleProjection.self).count, 0)
        realm.refresh()
        XCTAssertEqual(realm.objects(SimpleProjection.self).count, 1)
    }

    func testObserveComputedChange() throws {
        let realm = populatedRealm()
        let johnProjection = realm.objects(PersonProjection.self).first!

        XCTAssertEqual(johnProjection.lastNameCaps, "SNOW")

        let ex = expectation(description: "values will be observed")
        let token = johnProjection.observe(keyPaths: [\PersonProjection.lastNameCaps]) { chg in
            if case let .change(_, change) = chg {
                ex.fulfill()
                guard let value = change.first else {
                    XCTFail("Change should contain PropertyChange")
                    return
                }
                XCTAssertEqual(value.name, "lastNameCaps")
                XCTAssertEqual(value.oldValue as? String, "SNOW")
                XCTAssertEqual(value.newValue as? String, "ALI")
            }
        }

        // Wait for the notifier to be registered before we do the write
        realm.refresh()

        dispatchSyncNewThread {
            let realm = self.realmWithTestPath()
            let johnObject = realm.objects(CommonPerson.self).filter("lastName == 'Snow'").first!
            try! realm.write {
                johnObject.lastName = "Ali"
            }
        }

        waitForExpectations(timeout: 2)
        token.invalidate()
    }

    func testFailedProjection() {
        let realm = populatedRealm()
        XCTAssertGreaterThan(realm.objects(FailedProjection.self).count, 0)
        assertThrows(realm.objects(FailedProjection.self).first, reason: "@Projected property")
    }

    func testAdvancedProjection() throws {
        let realm = populatedRealm()
        let proj = realm.objects(AdvancedProjection.self).first!

        XCTAssertEqual(proj.arrayLen, 3)
        XCTAssertTrue(proj.projectedArray.elementsEqual(["1 - true", "2 - false"]), "'\(proj.projectedArray)' should be equal to '[\"1 - true\", \"2 - false\"]'")
        XCTAssertTrue(proj.renamedArray.elementsEqual([1, 2, 3]))
        XCTAssertEqual(proj.firstElement, 1)
        XCTAssertTrue(proj.projectedSet.elementsEqual([true, false]), "'\(proj.projectedArray)' should be equal to '[true, false]'")
    }
}
