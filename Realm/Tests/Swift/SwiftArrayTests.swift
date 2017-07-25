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
import Realm
import Foundation

class SwiftArrayTests: RLMTestCase {

    // Swift models

    func testFastEnumeration() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let dateMinInput = Date()
        let dateMaxInput = dateMinInput.addingTimeInterval(1000)

        _ = SwiftAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])

        try! realm.commitWriteTransaction()

        let result = SwiftAggregateObject.objects(in: realm, where: "intCol < %d", 100)
        XCTAssertEqual(result.count, UInt(10), "10 objects added")

        var totalSum = 0

        for obj in result {
            if let ao = obj as? SwiftAggregateObject {
                totalSum += ao.intCol
            }
        }

        XCTAssertEqual(totalSum, 100, "total sum should be 100")
    }

    func testObjectAggregate() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let dateMinInput = Date()
        let dateMaxInput = dateMinInput.addingTimeInterval(1000)

        _ = SwiftAggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = SwiftAggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])

        try! realm.commitWriteTransaction()

        let noArray = SwiftAggregateObject.objects(in: realm, where: "boolCol == NO")
        let yesArray = SwiftAggregateObject.objects(in: realm, where: "boolCol == YES")

        // SUM ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int sum
        XCTAssertEqual(noArray.sum(ofProperty: "intCol").intValue, 4, "Sum should be 4")
        XCTAssertEqual(yesArray.sum(ofProperty: "intCol").intValue, 0, "Sum should be 0")

        // Test float sum
        XCTAssertEqual(noArray.sum(ofProperty: "floatCol").floatValue, Float(0), accuracy: 0.1, "Sum should be 0.0")
        XCTAssertEqual(yesArray.sum(ofProperty: "floatCol").floatValue, Float(7.2), accuracy: 0.1, "Sum should be 7.2")

        // Test double sum
        XCTAssertEqual(noArray.sum(ofProperty: "doubleCol").doubleValue, Double(10), accuracy: 0.1, "Sum should be 10.0")
        XCTAssertEqual(yesArray.sum(ofProperty: "doubleCol").doubleValue, Double(0), accuracy: 0.1, "Sum should be 0.0")

        // Average ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int average
        XCTAssertEqual(noArray.average(ofProperty: "intCol")!.doubleValue, Double(1), accuracy: 0.1, "Average should be 1.0")
        XCTAssertEqual(yesArray.average(ofProperty: "intCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")

        // Test float average
        XCTAssertEqual(noArray.average(ofProperty: "floatCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")
        XCTAssertEqual(yesArray.average(ofProperty: "floatCol")!.doubleValue, Double(1.2), accuracy: 0.1, "Average should be 1.2")

        // Test double average
        XCTAssertEqual(noArray.average(ofProperty: "doubleCol")!.doubleValue, Double(2.5), accuracy: 0.1, "Average should be 2.5")
        XCTAssertEqual(yesArray.average(ofProperty: "doubleCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")

        // MIN ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int min
        var min = noArray.min(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(min.int32Value, Int32(1), "Minimum should be 1")
        min = yesArray.min(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(min.int32Value, Int32(0), "Minimum should be 0")

        // Test float min
        min = noArray.min(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(min.floatValue, Float(0), accuracy: 0.1, "Minimum should be 0.0f")
        min = yesArray.min(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(min.floatValue, Float(1.2), accuracy: 0.1, "Minimum should be 1.2f")

        // Test double min
        min = noArray.min(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(min.doubleValue, Double(2.5), accuracy: 0.1, "Minimum should be 1.5")
        min = yesArray.min(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(min.doubleValue, Double(0), accuracy: 0.1, "Minimum should be 0.0")

        // Test date min
        var dateMinOutput = noArray.min(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMinOutput, dateMaxInput, "Minimum should be dateMaxInput")
        dateMinOutput = yesArray.min(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMinOutput, dateMinInput, "Minimum should be dateMinInput")

        // MAX ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int max
        var max = noArray.max(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(max.intValue, 1, "Maximum should be 8")
        max = yesArray.max(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(max.intValue, 0, "Maximum should be 10")

        // Test float max
        max = noArray.max(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(max.floatValue, Float(0), accuracy: 0.1, "Maximum should be 0.0f")
        max = yesArray.max(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(max.floatValue, Float(1.2), accuracy: 0.1, "Maximum should be 1.2f")

        // Test double max
        max = noArray.max(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(max.doubleValue, Double(2.5), accuracy: 0.1, "Maximum should be 3.5")
        max = yesArray.max(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(max.doubleValue, Double(0), accuracy: 0.1, "Maximum should be 0.0")

        // Test date max
        var dateMaxOutput = noArray.max(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMaxOutput, dateMaxInput, "Maximum should be dateMaxInput")
        dateMaxOutput = yesArray.max(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMaxOutput, dateMinInput, "Maximum should be dateMinInput")
    }

    func testArrayDescription() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        for _ in 0..<1012 {
            let person = SwiftEmployeeObject()
            person.name = "Mary"
            person.age = 24
            person.hired = true
            realm.add(person)
        }

        try! realm.commitWriteTransaction()

        let description = SwiftEmployeeObject.allObjects(in: realm).description

        XCTAssertTrue((description as NSString).range(of: "name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMArray")
        XCTAssertTrue((description as NSString).range(of: "Mary").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMArray")

        XCTAssertTrue((description as NSString).range(of: "age").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMArray")
        XCTAssertTrue((description as NSString).range(of: "24").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMArray")

        XCTAssertTrue((description as NSString).range(of: "12 objects skipped").location != Foundation.NSNotFound, "'12 objects skipped' should be displayed when calling \"description\" on RLMArray")
    }

    func testDeleteLinksAndObjectsInArray() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

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
        company.employees.addObjects(SwiftEmployeeObject.allObjects(in: realm))

        try! realm.commitWriteTransaction()

        let peopleInCompany = company.employees
        XCTAssertEqual(peopleInCompany.count, UInt(3), "No links should have been deleted")

        realm.beginWriteTransaction()
        peopleInCompany.removeObject(at: 1) // Should delete link to employee
        try! realm.commitWriteTransaction()

        XCTAssertEqual(peopleInCompany.count, UInt(2), "link deleted when accessing via links")

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

        realm.beginWriteTransaction()
        peopleInCompany.removeLastObject()
        XCTAssertEqual(peopleInCompany.count, UInt(1), "1 remaining link")
        peopleInCompany.replaceObject(at: 0, with: po2)
        XCTAssertEqual(peopleInCompany.count, UInt(1), "1 link replaced")
        peopleInCompany.insert(po1, at: 0)
        XCTAssertEqual(peopleInCompany.count, UInt(2), "2 links")
        peopleInCompany.removeAllObjects()
        XCTAssertEqual(peopleInCompany.count, UInt(0), "0 remaining links")
        try! realm.commitWriteTransaction()
    }

    // Objective-C models

    func testFastEnumeration_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let dateMinInput = Date()
        let dateMaxInput = dateMinInput.addingTimeInterval(1000)

        _ = AggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = AggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = AggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = AggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = AggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = AggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = AggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = AggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = AggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = AggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])

        try! realm.commitWriteTransaction()

        let result = AggregateObject.objects(in: realm, where: "intCol < %d", 100)
        XCTAssertEqual(result.count, UInt(10), "10 objects added")

        var totalSum: CInt = 0

        for obj in result {
            if let ao = obj as? AggregateObject {
                totalSum += ao.intCol
            }
        }

        XCTAssertEqual(totalSum, CInt(100), "total sum should be 100")
    }

    func testObjectAggregate_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let dateMinInput = Date()
        let dateMaxInput = dateMinInput.addingTimeInterval(1000)

        _ = AggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = AggregateObject.create(in: realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = AggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = AggregateObject.create(in: realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = AggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = AggregateObject.create(in: realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = AggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = AggregateObject.create(in: realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        _ = AggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        _ = AggregateObject.create(in: realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])

        try! realm.commitWriteTransaction()

        let noArray = AggregateObject.objects(in: realm, where: "boolCol == NO")
        let yesArray = AggregateObject.objects(in: realm, where: "boolCol == YES")

        // SUM ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int sum
        XCTAssertEqual(noArray.sum(ofProperty: "intCol").intValue, 4, "Sum should be 4")
        XCTAssertEqual(yesArray.sum(ofProperty: "intCol").intValue, 0, "Sum should be 0")

        // Test float sum
        XCTAssertEqual(noArray.sum(ofProperty: "floatCol").floatValue, Float(0), accuracy: 0.1, "Sum should be 0.0")
        XCTAssertEqual(yesArray.sum(ofProperty: "floatCol").floatValue, Float(7.2), accuracy: 0.1, "Sum should be 7.2")

        // Test double sum
        XCTAssertEqual(noArray.sum(ofProperty: "doubleCol").doubleValue, Double(10), accuracy: 0.1, "Sum should be 10.0")
        XCTAssertEqual(yesArray.sum(ofProperty: "doubleCol").doubleValue, Double(0), accuracy: 0.1, "Sum should be 0.0")

        // Average ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int average
        XCTAssertEqual(noArray.average(ofProperty: "intCol")!.doubleValue, Double(1), accuracy: 0.1, "Average should be 1.0")
        XCTAssertEqual(yesArray.average(ofProperty: "intCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")

        // Test float average
        XCTAssertEqual(noArray.average(ofProperty: "floatCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")
        XCTAssertEqual(yesArray.average(ofProperty: "floatCol")!.doubleValue, Double(1.2), accuracy: 0.1, "Average should be 1.2")

        // Test double average
        XCTAssertEqual(noArray.average(ofProperty: "doubleCol")!.doubleValue, Double(2.5), accuracy: 0.1, "Average should be 2.5")
        XCTAssertEqual(yesArray.average(ofProperty: "doubleCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")

        // MIN ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int min
        var min = noArray.min(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(min.int32Value, Int32(1), "Minimum should be 1")
        min = yesArray.min(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(min.int32Value, Int32(0), "Minimum should be 0")

        // Test float min
        min = noArray.min(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(min.floatValue, Float(0), accuracy: 0.1, "Minimum should be 0.0f")
        min = yesArray.min(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(min.floatValue, Float(1.2), accuracy: 0.1, "Minimum should be 1.2f")

        // Test double min
        min = noArray.min(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(min.doubleValue, Double(2.5), accuracy: 0.1, "Minimum should be 1.5")
        min = yesArray.min(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(min.doubleValue, Double(0), accuracy: 0.1, "Minimum should be 0.0")

        // Test date min
        var dateMinOutput = noArray.min(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMinOutput, dateMaxInput, "Minimum should be dateMaxInput")
        dateMinOutput = yesArray.min(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMinOutput, dateMinInput, "Minimum should be dateMinInput")

        // MAX ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int max
        var max = noArray.max(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(max.intValue, 1, "Maximum should be 8")
        max = yesArray.max(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(max.intValue, 0, "Maximum should be 10")

        // Test float max
        max = noArray.max(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(max.floatValue, Float(0), accuracy: 0.1, "Maximum should be 0.0f")
        max = yesArray.max(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(max.floatValue, Float(1.2), accuracy: 0.1, "Maximum should be 1.2f")

        // Test double max
        max = noArray.max(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(max.doubleValue, Double(2.5), accuracy: 0.1, "Maximum should be 3.5")
        max = yesArray.max(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(max.doubleValue, Double(0), accuracy: 0.1, "Maximum should be 0.0")

        // Test date max
        var dateMaxOutput = noArray.max(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMaxOutput, dateMaxInput, "Maximum should be dateMaxInput")
        dateMaxOutput = yesArray.max(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMaxOutput, dateMinInput, "Maximum should be dateMinInput")
    }

    func testArrayDescription_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        for _ in 0..<1012 {
            let person = EmployeeObject()
            person.name = "Mary"
            person.age = 24
            person.hired = true
            realm.add(person)
        }

        try! realm.commitWriteTransaction()

        let description = EmployeeObject.allObjects(in: realm).description
        XCTAssertTrue((description as NSString).range(of: "name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMArray")
        XCTAssertTrue((description as NSString).range(of: "Mary").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMArray")

        XCTAssertTrue((description as NSString).range(of: "age").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMArray")
        XCTAssertTrue((description as NSString).range(of: "24").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMArray")

        XCTAssertTrue((description as NSString).range(of: "912 objects skipped").location != Foundation.NSNotFound, "'912 objects skipped' should be displayed when calling \"description\" on RLMArray")
    }

    func makeEmployee(_ realm: RLMRealm, _ age: Int32, _ name: String, _ hired: Bool) -> EmployeeObject {
        let employee = EmployeeObject()
        employee.age = age
        employee.name = name
        employee.hired = hired
        realm.add(employee)
        return employee
    }

    func testDeleteLinksAndObjectsInArray_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let po1 = makeEmployee(realm, 40, "Joe", true)
        _ = makeEmployee(realm, 30, "John", false)
        let po3 = makeEmployee(realm, 25, "Jill", true)

        let company = CompanyObject()
        company.name = "name"
        realm.add(company)
        company.employees.addObjects(EmployeeObject.allObjects(in: realm))

        try! realm.commitWriteTransaction()

        let peopleInCompany: RLMArray<EmployeeObject> = company.employees!
        XCTAssertEqual(peopleInCompany.count, UInt(3), "No links should have been deleted")

        realm.beginWriteTransaction()
        peopleInCompany.removeObject(at: 1) // Should delete link to employee
        try! realm.commitWriteTransaction()

        XCTAssertEqual(peopleInCompany.count, UInt(2), "link deleted when accessing via links")

        var test = peopleInCompany[0]
        XCTAssertEqual(test.age, po1.age, "Should be equal")
        XCTAssertEqual(test.name!, po1.name!, "Should be equal")
        XCTAssertEqual(test.hired, po1.hired, "Should be equal")
        // XCTAssertEqual(test, po1, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568

        test = peopleInCompany[1]
        XCTAssertEqual(test.age, po3.age, "Should be equal")
        XCTAssertEqual(test.name!, po3.name!, "Should be equal")
        XCTAssertEqual(test.hired, po3.hired, "Should be equal")
        // XCTAssertEqual(test, po3, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568

        let allPeople = EmployeeObject.allObjects(in: realm)
        XCTAssertEqual(allPeople.count, UInt(3), "Only links should have been deleted, not the employees")
    }

    func testIndexOfObject_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let po1 = makeEmployee(realm, 40, "Joe", true)
        let po2 = makeEmployee(realm, 30, "John", false)
        let po3 = makeEmployee(realm, 25, "Jill", true)
        try! realm.commitWriteTransaction()

        let results = EmployeeObject.objects(in: realm, where: "hired = YES")
        XCTAssertEqual(UInt(2), results.count)
        XCTAssertEqual(UInt(0), results.index(of: po1));
        XCTAssertEqual(UInt(1), results.index(of: po3));
        XCTAssertEqual(NSNotFound, Int(results.index(of: po2)));
    }

    func testIndexOfObjectWhere_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        _ = makeEmployee(realm, 40, "Joe", true)
        _ = makeEmployee(realm, 30, "John", false)
        _ = makeEmployee(realm, 25, "Jill", true)
        try! realm.commitWriteTransaction()

        let results = EmployeeObject.objects(in: realm, where: "hired = YES")
        XCTAssertEqual(UInt(2), results.count)
        XCTAssertEqual(UInt(0), results.indexOfObject(where: "age = %d", 40))
        XCTAssertEqual(UInt(1), results.indexOfObject(where: "age = %d", 25))
        XCTAssertEqual(NSNotFound, Int(results.indexOfObject(where: "age = %d", 30)))
    }

    func testSortingExistingQuery_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        _ = makeEmployee(realm, 20, "A", true)
        _ = makeEmployee(realm, 30, "B", false)
        _ = makeEmployee(realm, 40, "C", true)
        try! realm.commitWriteTransaction()

        let sortedByAge = EmployeeObject.allObjects(in: realm).sortedResults(usingKeyPath: "age", ascending: true)
        let sortedByName = sortedByAge.sortedResults(usingKeyPath: "name", ascending: false)

        XCTAssertEqual(Int32(20), (sortedByAge[0] as! EmployeeObject).age)
        XCTAssertEqual(Int32(40), (sortedByName[0] as! EmployeeObject).age)
    }
}
