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

/**
 Test objects definitions
 */
class SwiftAllTypesObject: Object {
    @Persisted var boolCol = false
    @Persisted var intCol = 123
    @Persisted var int8Col: Int8 = 123
    @Persisted var int16Col: Int16 = 123
    @Persisted var int32Col: Int32 = 123
    @Persisted var int64Col: Int64 = 123
//    @Persisted var intEnumCol = IntEnum.value1
    @Persisted var floatCol = 1.23 as Float
    @Persisted var doubleCol = 12.3
    @Persisted var stringCol = "a"
    @Persisted var binaryCol = "a".data(using: String.Encoding.utf8)!
    @Persisted var dateCol = Date(timeIntervalSince1970: 1)
    @Persisted var decimalCol = Decimal128("123e4")
    @Persisted var objectIdCol = ObjectId("1234567890ab1234567890ab")
    @Persisted var objectCol: SwiftBoolObject? = SwiftBoolObject()
    @Persisted var uuidCol: UUID = UUID(uuidString: "137decc8-b300-4954-a233-f89909f4fd89")!
//    @Persisted var anyCol = RealmProperty<AnyRealmValue>()

//    @Persisted var arrayCol = List<SwiftBoolObject>()
    @Persisted var setCol = MutableSet<SwiftBoolObject>()
    @Persisted var mapCol = Map<String, SwiftBoolObject?>()

    class func defaultValues() -> [String: Any] {
        return  [
            "boolCol": false,
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
//            "arrayCol": [],
            "setCol": [],
            "mapCol": [:]
        ]
    }
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


public class PersonProjection: Projection<Person> {
//    public typealias Root = Person
    @Projected(\Person.firstName) var firstName
    @Projected(\Person.lastName) var lastName
    @Projected(\Person.birthday.timeIntervalSince1970) var birthdayAsEpochtime
    @Projected(\Person.address?.city) var homeCity
    @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: ProjectedList<String>
}

class AllTypesProjection: Projection<SwiftAllTypesObject> {
//    typealias Root = SwiftAllTypesObject
    
    @Projected(\SwiftAllTypesObject.boolCol) var boolCol
    @Projected(\SwiftAllTypesObject.intCol) var intCol
    @Projected(\SwiftAllTypesObject.int8Col) var int8Col
    @Projected(\SwiftAllTypesObject.int16Col) var int16Col
    @Projected(\SwiftAllTypesObject.int32Col) var int32Col
    @Projected(\SwiftAllTypesObject.int64Col) var int64Col
//    @Projected(\SwiftAllTypesObject.intEnumCol) var intEnumCol
    @Projected(\SwiftAllTypesObject.floatCol) var floatCol
    @Projected(\SwiftAllTypesObject.doubleCol) var doubleCol
    @Projected(\SwiftAllTypesObject.stringCol) var stringCol
    @Projected(\SwiftAllTypesObject.binaryCol) var binaryCol
    @Projected(\SwiftAllTypesObject.dateCol) var dateCol
    @Projected(\SwiftAllTypesObject.decimalCol) var decimalCol
    @Projected(\SwiftAllTypesObject.objectIdCol) var objectIdCol
    @Projected(\SwiftAllTypesObject.objectCol) var objectCol
    @Projected(\SwiftAllTypesObject.uuidCol) var uuidCol
//    @Projected(\SwiftAllTypesObject.anyCol) var anyCol

//    @Projected(\SwiftAllTypesObject.arrayCol) var arrayCol
    @Projected(\SwiftAllTypesObject.setCol) var setCol
    @Projected(\SwiftAllTypesObject.mapCol) var mapCol
}

//extension AllTypesProjection: RealmCollectionValue {
//
//    public static var _rlmType: PropertyType { .any }
//
//    static var _rlmOptional: Bool { false }
//
//    static var _rlmRequireObjc: Bool { false }
//
//    func _rlmPopulateProperty(_ prop: RLMProperty) {
//        fatalError()
//    }
//
//    static func _rlmPopulateProperty(_ prop: RLMProperty) {
//        fatalError()
//    }
//
//    static func == (lhs: AllTypesProjection, rhs: AllTypesProjection) -> Bool {
//        return lhs === rhs
//    }
//}

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

            realm.create(SwiftAllTypesObject.self)
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
}
