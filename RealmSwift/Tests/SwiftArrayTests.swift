////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

class SwiftArrayTests: TestCase {

    func testFastEnumeration() {
        let realm = realmWithTestPath()

        realm.beginWrite()

        let dateMinInput = NSDate()
        let dateMaxInput = dateMinInput.dateByAddingTimeInterval(1000)

        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput, true])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput, true])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput, true])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput, true])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput, true])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput, true])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput, true])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput, true])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput, true])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput, true])

        realm.commitWrite()

        let results = objects(SwiftAggregateObject.self, inRealm: realm).filter("intCol < 100")
        XCTAssertEqual(results.count, Int(10), "10 objects added")

        var totalSum = 0
        for obj in results {
            totalSum += obj.intCol
        }
        XCTAssertEqual(totalSum, 100, "total sum should be 100")
    }

    func testArrayDescription() {
        let realm = realmWithTestPath()

        realm.beginWrite()

        for i in 0..<1012 {
            let person = SwiftEmployeeObject()
            person.name = "Mary"
            person.age = 24
            person.hired = true
            realm.add(person)
        }

        realm.commitWrite()

        let description: NSString = objects(SwiftEmployeeObject.self, inRealm: realm).description

        XCTAssertTrue(description.rangeOfString("name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMArray")
        XCTAssertTrue(description.rangeOfString("Mary").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMArray")

        XCTAssertTrue(description.rangeOfString("age").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMArray")
        XCTAssertTrue(description.rangeOfString("24").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMArray")

        XCTAssertTrue(description.rangeOfString("12 objects skipped").location != Foundation.NSNotFound, "'12 objects skipped' should be displayed when calling \"description\" on RLMArray")
    }

    func testDeleteLinksAndObjectsInArray() {
        let realm = realmWithTestPath()

        realm.beginWrite()

        let po1 = SwiftEmployeeObject()
        po1.age = 40
        po1.name = "Joe"
        po1.hired = true

        let po2 = SwiftEmployeeObject()
        po2.age = 30
        po2.name = "John"
        po2.hired = false

        let po3 = SwiftEmployeeObject()
        po3.age = 25
        po3.name = "Jill"
        po3.hired = true

        realm.add(po1)
        realm.add(po2)
        realm.add(po3)

        let company = SwiftCompanyObject()
        realm.add(company)
        company.employees.append(objects(SwiftEmployeeObject.self, inRealm: realm))

        realm.commitWrite()

        let peopleInCompany = company.employees
        XCTAssertEqual(peopleInCompany.count, Int(3), "No links should have been deleted")

        realm.beginWrite()
        peopleInCompany.remove(1) // Should delete link to employee
        realm.commitWrite()

        XCTAssertEqual(peopleInCompany.count, Int(2), "link deleted when accessing via links")

        var test = peopleInCompany[0]
        XCTAssertEqual(test.age, po1.age, "Should be equal")
        XCTAssertEqual(test.name, po1.name, "Should be equal")
        XCTAssertEqual(test.hired, po1.hired, "Should be equal")
        // XCTAssertEqual(test, po1, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568

        test = peopleInCompany[1]
        XCTAssertEqual(test.age, po3.age, "Should be equal")
        XCTAssertEqual(test.name, po3.name, "Should be equal")
        XCTAssertEqual(test.hired, po3.hired, "Should be equal")
        // XCTAssertEqual(test, po3, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568

        realm.beginWrite()
        peopleInCompany.removeLast()
        XCTAssertEqual(peopleInCompany.count, Int(1), "1 remaining link")
        peopleInCompany.replace(0, object: po2)
        XCTAssertEqual(peopleInCompany.count, Int(1), "1 link replaced")
        peopleInCompany.insert(po1, atIndex: 0)
        XCTAssertEqual(peopleInCompany.count, Int(2), "2 links")
        peopleInCompany.removeAll()
        XCTAssertEqual(peopleInCompany.count, Int(0), "0 remaining links")
        realm.commitWrite()
    }
}
