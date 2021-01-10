////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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
import XCTest

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif

class SwiftRLMSetTests: RLMTestCase {

    // Swift models

    func testDeleteLinksAndObjectsInSet() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let po1 = SwiftRLMEmployeeObject()
        po1.age = 40
        po1.name = "Joe"
        po1.hired = true

        let po2 = SwiftRLMEmployeeObject()
        po2.age = 30
        po2.name = "John"
        po2.hired = false

        let po3 = SwiftRLMEmployeeObject()
        po3.age = 25
        po3.name = "Jill"
        po3.hired = true

        realm.add(po1)
        realm.add(po2)
        realm.add(po3)

        let company = SwiftRLMCompanyObject()
        realm.add(company)
        company.employeeSet.addObjects(SwiftRLMEmployeeObject.allObjects(in: realm))

        try! realm.commitWriteTransaction()

        let peopleInCompany = company.employeeSet
        XCTAssertEqual(peopleInCompany.count, UInt(3), "No links should have been deleted")

        realm.beginWriteTransaction()
        peopleInCompany.remove(po2) // Should delete link to employee
        try! realm.commitWriteTransaction()

        XCTAssertEqual(peopleInCompany.count, UInt(2), "link deleted when accessing via links")

        let test = peopleInCompany.allObjects[0]
        XCTAssertTrue(((test.age == po1.age) || (test.age == po3.age)), "Should be equal")
        XCTAssertEqual(test.name, po1.name, "Should be equal")
        XCTAssertEqual(test.hired, po1.hired, "Should be equal")

        realm.beginWriteTransaction()
        peopleInCompany.remove(po1)
        XCTAssertEqual(peopleInCompany.count, UInt(1), "1 remaining link")
        peopleInCompany.add(po1)
        XCTAssertEqual(peopleInCompany.count, UInt(2), "2 links")
        peopleInCompany.removeAllObjects()
        XCTAssertEqual(peopleInCompany.count, UInt(0), "0 remaining links")
        try! realm.commitWriteTransaction()
    }

    // Objective-C models

    func testFastEnumeration_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let po1 = SwiftRLMEmployeeObject()
        po1.age = 40
        po1.name = "Joe"
        po1.hired = true

        let po2 = SwiftRLMEmployeeObject()
        po2.age = 30
        po2.name = "John"
        po2.hired = false

        let po3 = SwiftRLMEmployeeObject()
        po3.age = 25
        po3.name = "Jill"
        po3.hired = true

        realm.add(po1)
        realm.add(po2)
        realm.add(po3)

        let company = SwiftRLMCompanyObject()
        realm.add(company)
        company.employeeSet.addObjects(SwiftRLMEmployeeObject.allObjects(in: realm))

        try! realm.commitWriteTransaction()
        XCTAssertEqual(company.employeeSet.count, UInt(3), "3 objects added")

        var totalSum: Int = 0

        for obj in company.employeeSet {
            if let ao = obj as? SwiftRLMEmployeeObject {
                totalSum += ao.age
            }
        }

        XCTAssertEqual(totalSum, 95, "total sum should be 95")
    }

    func testObjectAggregate_objc() {
        let dateMinInput = Date()
        let dateMaxInput = dateMinInput.addingTimeInterval(1000)

        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let aggSet = SwiftRLMAggregateSet()

        aggSet.set.add(SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput]))
        aggSet.set.add(SwiftRLMAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput]))
        aggSet.set.add(SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput]))
        aggSet.set.add(SwiftRLMAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput]))
        aggSet.set.add(SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput]))
        aggSet.set.add(SwiftRLMAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput]))
        aggSet.set.add(SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput]))
        aggSet.set.add(SwiftRLMAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput]))
        aggSet.set.add(SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput]))
        aggSet.set.add(SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput]))

        realm.add(aggSet)

        try! realm.commitWriteTransaction()

        // SUM ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int sum
        XCTAssertEqual(aggSet.set.sum(ofProperty: "intCol").intValue, 100, "Sum should be 100")

        // Test float sum
        XCTAssertEqual(aggSet.set.sum(ofProperty: "floatCol").floatValue, Float(7.20), accuracy: 0.1, "Sum should be 0.0")

        // Test double sum
        XCTAssertEqual(aggSet.set.sum(ofProperty: "doubleCol").doubleValue, Double(10), accuracy: 0.1, "Sum should be 10.0")

        // Average ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int average
        XCTAssertEqual(aggSet.set.average(ofProperty: "intCol")!.doubleValue, Double(10.0), accuracy: 0.1, "Average should be 1.0")

        // Test float average
        XCTAssertEqual(aggSet.set.average(ofProperty: "floatCol")!.doubleValue, Double(0.72), accuracy: 0.1, "Average should be 0.0")

        // Test double average
        XCTAssertEqual(aggSet.set.average(ofProperty: "doubleCol")!.doubleValue, Double(1.0), accuracy: 0.1, "Average should be 2.5")

        // MIN ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int min
        var min = aggSet.set.min(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(min.int32Value, Int32(10), "Minimum should be 10")

        // Test float min
        min = aggSet.set.min(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(min.floatValue, Float(0), accuracy: 0.1, "Minimum should be 0.0f")

        // Test double min
        min = aggSet.set.min(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(min.doubleValue, Double(0.0), accuracy: 0.1, "Minimum should be 1.5")

        // Test date min
        let dateMinOutput = aggSet.set.min(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMinOutput, dateMinInput, "Minimum should be dateMaxInput")

        // MAX ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int max
        var max = aggSet.set.max(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(max.intValue, 10, "Maximum should be 10")

        // Test float max
        max = aggSet.set.max(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(max.floatValue, Float(1.2), accuracy: 0.1, "Maximum should be 0.0f")

        // Test double max
        max = aggSet.set.max(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(max.doubleValue, Double(2.5), accuracy: 0.1, "Maximum should be 3.5")

        // Test date max
        let dateMaxOutput = aggSet.set.max(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMaxOutput, dateMaxInput, "Maximum should be dateMaxInput")
    }

    func testSetDescription_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        for _ in 0..<300 {
            let po1 = SwiftRLMEmployeeObject()
            po1.age = 40
            po1.name = "Joe"
            po1.hired = true

            let po2 = SwiftRLMEmployeeObject()
            po2.age = 30
            po2.name = "Mary"
            po2.hired = false

            let po3 = SwiftRLMEmployeeObject()
            po3.age = 24
            po3.name = "Jill"
            po3.hired = true

            realm.add(po1)
            realm.add(po2)
            realm.add(po3)
        }

        let company = SwiftRLMCompanyObject()
        realm.add(company)
        company.employeeSet.addObjects(SwiftRLMEmployeeObject.allObjects(in: realm))

        try! realm.commitWriteTransaction()

        let description = company.employeeSet.description
        XCTAssertTrue((description as NSString).range(of: "name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMSet")
        XCTAssertTrue((description as NSString).range(of: "Mary").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMSet")

        XCTAssertTrue((description as NSString).range(of: "age").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMSet")
        XCTAssertTrue((description as NSString).range(of: "24").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMSet")

        XCTAssertTrue((description as NSString).range(of: "800 objects skipped").location != Foundation.NSNotFound, "'800 objects skipped' should be displayed when calling \"description\" on RLMSet")
    }

    func makeEmployee(_ realm: RLMRealm, _ age: Int32, _ name: String, _ hired: Bool) -> EmployeeObject {
        let employee = EmployeeObject()
        employee.age = age
        employee.name = name
        employee.hired = hired
        realm.add(employee)
        return employee
    }

    func testDeleteLinksAndObjectsInSet_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let po1 = makeEmployee(realm, 40, "Joe", true)
        _ = makeEmployee(realm, 30, "John", false)
        let po3 = makeEmployee(realm, 25, "Jill", true)

        let company = CompanyObject()
        company.name = "name"
        realm.add(company)
        company.employeeSet.addObjects(EmployeeObject.allObjects(in: realm))

        try! realm.commitWriteTransaction()

        let peopleInCompany: RLMSet<EmployeeObject> = company.employeeSet!
        XCTAssertEqual(peopleInCompany.count, UInt(3), "No links should have been deleted")

        realm.beginWriteTransaction()
        peopleInCompany.remove(po3) // Should delete link to employee
        try! realm.commitWriteTransaction()

        XCTAssertEqual(peopleInCompany.count, UInt(2), "link deleted when accessing via links")

        let test = peopleInCompany.allObjects[0]
        XCTAssertEqual(test.age, po1.age, "Should be equal")
        XCTAssertEqual(test.name!, po1.name!, "Should be equal")
        XCTAssertEqual(test.hired, po1.hired, "Should be equal")

        let allPeople = EmployeeObject.allObjects(in: realm)
        XCTAssertEqual(allPeople.count, UInt(3), "Only links should have been deleted, not the employees")
    }

}
