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
import SwiftUI
#endif

class ProjectedListTests: TestCase {
    
    var collection: ProjectedList<String>! {
        // To test some of methods there should be a collection of projections instead of collection of strings
        realmWithTestPath().objects(PersonProjection.self).first!.firstFriendsName
    }
    
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
            let tl = realm.create(Person.self, value: ["firstName": "Tyrion",
                                                       "lastName": "Lannister",
                                                       "birthday": Date(timeIntervalSince1970: 20),
                                                       "address": ["Casterly Rock", "Westeros"],
                                                       "money": Decimal128("9999.95")])
            js.friends.append(dt)
            js.friends.append(tl)
            dt.friends.append(js)
        }
    }
    
    func testCount() {
        XCTAssertEqual(collection.count, 1)
    }
    
    func testAccess() {
        XCTAssertEqual(collection[0], "Daenerys")
        XCTAssertEqual(collection.first, "Daenerys")
        XCTAssertEqual(collection.last, "Daenerys")
        XCTAssertNil(collection.index(of:"Not tere"))
        XCTAssertEqual(0, collection.index(of:"Daenerys"))
    }
    
    func testSetValues() {
        let realm = realmWithTestPath()
        try! realm.write {
            collection[0] = "Overwrite"
        }
        XCTAssertEqual(collection.first, "Overwrite")
        let danyObject = realm.objects(Person.self).filter("lastName == 'Targaryen'").first!
        XCTAssertEqual(danyObject.firstName, "Overwrite")
    }
        let realm = realmWithTestPath()
        let johnSnow = realm.objects(PersonProjection.self).first!
        XCTAssertEqual(johnSnow.firstFriendsName.count, 3)
    func testRealm() {
        guard collection.realm != nil else {
            XCTAssertNotNil(collection.realm)
            return
        }
        XCTAssertEqual(collection.realm!.configuration.fileURL, realmWithTestPath().configuration.fileURL)
    }

    func testDescription() {
        assertMatches(collection.description, "ProjectedList<PersonProjection> ***properties description goes here***")
    }
    
    func testPredicate() {
        let matching = NSPredicate(format: "value = 'Daenerys'")
        let notMatching = NSPredicate(format: "value = 'Not There'")
        XCTAssertEqual(0, collection.index(matching: matching)!)
        XCTAssertNil(collection.index(matching: notMatching))
    }

    func testFilterFormat() {
        XCTAssertNotNil(collection.filter { $0 == "Daenerys" }.first!)
        XCTAssertNil(collection.filter { $0 == "Not There" }.first!)
    }

    func testSortWithProperty() {
        XCTAssertEqual("A", collection.sorted { $0 > $1 }.first!)
        XCTAssertEqual("B", collection.sorted { $0 > $1 }.last!)
    }

    func testFastEnumeration() {
        var str = ""
        for element in collection {
            str += element
        }

        XCTAssertEqual(str, "longstring")
    }
    }
}
