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


public struct PersonProjection: Projection {
    public typealias Root = Person
    @Projected(\Person.firstName) var firstName
    @Projected(\Person.lastName) var lastName
    @Projected(\Person.birthday.timeIntervalSince1970) var birthdayAsEpochtime
    @Projected(\Person.address?.city) var homeCity
    @Projected(\Person.friends.projectTo.firstName) var firstFriendsName: List<String>
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

            realm.create(SwiftAllTypesObject.self)
        }
    }

    func testProjectionPropertyWrapper() {
        let realm = realmWithTestPath()
        let jonSnow = realm.objects(Person.self).filter("lastName == 'Snow'").first!
        // this step will happen under the hood
        var pp = PersonProjection()
        pp.assign(jonSnow)
        XCTAssertEqual(pp.homeCity, "Winterfell")
        XCTAssertEqual(pp.birthdayAsEpochtime, Date(timeIntervalSince1970: 10).timeIntervalSince1970)
        XCTAssertEqual(pp.firstFriendsName.first!, "Daenerys")
    }
    }
}
