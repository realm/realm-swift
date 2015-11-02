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

        let dateMinInput = NSDate()
        let dateMaxInput = dateMinInput.dateByAddingTimeInterval(1000)

        SwiftAggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])

        try! realm.commitWriteTransaction()

        let result = SwiftAggregateObject.objectsInRealm(realm, "intCol < %d", 100)
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

        let dateMinInput = NSDate()
        let dateMaxInput = dateMinInput.dateByAddingTimeInterval(1000)

        SwiftAggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])

        try! realm.commitWriteTransaction()

        let noArray = SwiftAggregateObject.objectsInRealm(realm, "boolCol == NO")
        let yesArray = SwiftAggregateObject.objectsInRealm(realm, "boolCol == YES")

        // SUM ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int sum
        XCTAssertEqual(noArray.sumOfProperty("intCol").integerValue, 4, "Sum should be 4")
        XCTAssertEqual(yesArray.sumOfProperty("intCol").integerValue, 0, "Sum should be 0")

        // Test float sum
        XCTAssertEqualWithAccuracy(noArray.sumOfProperty("floatCol").floatValue, Float(0), accuracy: 0.1, "Sum should be 0.0")
        XCTAssertEqualWithAccuracy(yesArray.sumOfProperty("floatCol").floatValue, Float(7.2), accuracy: 0.1, "Sum should be 7.2")

        // Test double sum
        XCTAssertEqualWithAccuracy(noArray.sumOfProperty("doubleCol").doubleValue, Double(10), accuracy: 0.1, "Sum should be 10.0")
        XCTAssertEqualWithAccuracy(yesArray.sumOfProperty("doubleCol").doubleValue, Double(0), accuracy: 0.1, "Sum should be 0.0")

        // Average ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("intCol")!.doubleValue, Double(1), accuracy: 0.1, "Average should be 1.0")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("intCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")

        // Test float average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("floatCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("floatCol")!.doubleValue, Double(1.2), accuracy: 0.1, "Average should be 1.2")

        // Test double average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("doubleCol")!.doubleValue, Double(2.5), accuracy: 0.1, "Average should be 2.5")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("doubleCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")

        // MIN ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int min
        var min = noArray.minOfProperty("intCol") as! NSNumber
        XCTAssertEqual(min.intValue, Int32(1), "Minimum should be 1")
        min = yesArray.minOfProperty("intCol") as! NSNumber
        XCTAssertEqual(min.intValue, Int32(0), "Minimum should be 0")

        // Test float min
        min = noArray.minOfProperty("floatCol") as! NSNumber
        XCTAssertEqualWithAccuracy(min.floatValue, Float(0), accuracy: 0.1, "Minimum should be 0.0f")
        min = yesArray.minOfProperty("floatCol") as! NSNumber
        XCTAssertEqualWithAccuracy(min.floatValue, Float(1.2), accuracy: 0.1, "Minimum should be 1.2f")

        // Test double min
        min = noArray.minOfProperty("doubleCol") as! NSNumber
        XCTAssertEqualWithAccuracy(min.doubleValue, Double(2.5), accuracy: 0.1, "Minimum should be 1.5")
        min = yesArray.minOfProperty("doubleCol") as! NSNumber
        XCTAssertEqualWithAccuracy(min.doubleValue, Double(0), accuracy: 0.1, "Minimum should be 0.0")

        // Test date min
        var dateMinOutput = noArray.minOfProperty("dateCol") as! NSDate
        XCTAssertEqualWithAccuracy(dateMinOutput.timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, accuracy: 1, "Minimum should be dateMaxInput")
        dateMinOutput = yesArray.minOfProperty("dateCol") as! NSDate
        XCTAssertEqualWithAccuracy(dateMinOutput.timeIntervalSince1970, dateMinInput.timeIntervalSince1970, accuracy: 1, "Minimum should be dateMinInput")

        // MAX ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int max
        var max = noArray.maxOfProperty("intCol") as! NSNumber
        XCTAssertEqual(max.integerValue, 1, "Maximum should be 8")
        max = yesArray.maxOfProperty("intCol") as! NSNumber
        XCTAssertEqual(max.integerValue, 0, "Maximum should be 10")

        // Test float max
        max = noArray.maxOfProperty("floatCol") as! NSNumber
        XCTAssertEqualWithAccuracy(max.floatValue, Float(0), accuracy: 0.1, "Maximum should be 0.0f")
        max = yesArray.maxOfProperty("floatCol") as! NSNumber
        XCTAssertEqualWithAccuracy(max.floatValue, Float(1.2), accuracy: 0.1, "Maximum should be 1.2f")

        // Test double max
        max = noArray.maxOfProperty("doubleCol") as! NSNumber
        XCTAssertEqualWithAccuracy(max.doubleValue, Double(2.5), accuracy: 0.1, "Maximum should be 3.5")
        max = yesArray.maxOfProperty("doubleCol") as! NSNumber
        XCTAssertEqualWithAccuracy(max.doubleValue, Double(0), accuracy: 0.1, "Maximum should be 0.0")

        // Test date max
        var dateMaxOutput = noArray.maxOfProperty("dateCol") as! NSDate
        XCTAssertEqualWithAccuracy(dateMaxOutput.timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, accuracy: 1, "Maximum should be dateMaxInput")
        dateMaxOutput = yesArray.maxOfProperty("dateCol") as! NSDate
        XCTAssertEqualWithAccuracy(dateMaxOutput.timeIntervalSince1970, dateMinInput.timeIntervalSince1970, accuracy: 1, "Maximum should be dateMinInput")
    }

    func testArrayDescription() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        for _ in 0..<1012 {
            let person = SwiftEmployeeObject()
            person.name = "Mary"
            person.age = 24
            person.hired = true
            realm.addObject(person)
        }

        try! realm.commitWriteTransaction()

        let description = SwiftEmployeeObject.allObjectsInRealm(realm).description

        XCTAssertTrue((description as NSString).rangeOfString("name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMArray")
        XCTAssertTrue((description as NSString).rangeOfString("Mary").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMArray")

        XCTAssertTrue((description as NSString).rangeOfString("age").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMArray")
        XCTAssertTrue((description as NSString).rangeOfString("24").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMArray")

        XCTAssertTrue((description as NSString).rangeOfString("12 objects skipped").location != Foundation.NSNotFound, "'12 objects skipped' should be displayed when calling \"description\" on RLMArray")
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

        realm.addObject(po1)
        realm.addObject(po2)
        realm.addObject(po3)

        let company = SwiftCompanyObject()
        realm.addObject(company)
        company.employees.addObjects(SwiftEmployeeObject.allObjectsInRealm(realm))

        try! realm.commitWriteTransaction()

        let peopleInCompany = company.employees
        XCTAssertEqual(peopleInCompany.count, UInt(3), "No links should have been deleted")

        realm.beginWriteTransaction()
        peopleInCompany.removeObjectAtIndex(1) // Should delete link to employee
        try! realm.commitWriteTransaction()

        XCTAssertEqual(peopleInCompany.count, UInt(2), "link deleted when accessing via links")

        var test = peopleInCompany[0] as! SwiftEmployeeObject
        XCTAssertEqual(test.age, po1.age, "Should be equal")
        XCTAssertEqual(test.name, po1.name, "Should be equal")
        XCTAssertEqual(test.hired, po1.hired, "Should be equal")
        // XCTAssertEqual(test, po1, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568

        test = peopleInCompany[1] as! SwiftEmployeeObject
        XCTAssertEqual(test.age, po3.age, "Should be equal")
        XCTAssertEqual(test.name, po3.name, "Should be equal")
        XCTAssertEqual(test.hired, po3.hired, "Should be equal")
        // XCTAssertEqual(test, po3, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568

        realm.beginWriteTransaction()
        peopleInCompany.removeLastObject()
        XCTAssertEqual(peopleInCompany.count, UInt(1), "1 remaining link")
        peopleInCompany.replaceObjectAtIndex(0, withObject: po2)
        XCTAssertEqual(peopleInCompany.count, UInt(1), "1 link replaced")
        peopleInCompany.insertObject(po1, atIndex: 0)
        XCTAssertEqual(peopleInCompany.count, UInt(2), "2 links")
        peopleInCompany.removeAllObjects()
        XCTAssertEqual(peopleInCompany.count, UInt(0), "0 remaining links")
        try! realm.commitWriteTransaction()
    }

    // Objective-C models

    func testFastEnumeration_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let dateMinInput = NSDate()
        let dateMaxInput = dateMinInput.dateByAddingTimeInterval(1000)

        AggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])

        try! realm.commitWriteTransaction()

        let result = AggregateObject.objectsInRealm(realm, "intCol < %d", 100)
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

        let dateMinInput = NSDate()
        let dateMaxInput = dateMinInput.dateByAddingTimeInterval(1000)

        AggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withValue: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withValue: [0, 1.2 as Float, 0 as Double, true, dateMinInput])

        try! realm.commitWriteTransaction()

        let noArray = AggregateObject.objectsInRealm(realm, "boolCol == NO")
        let yesArray = AggregateObject.objectsInRealm(realm, "boolCol == YES")

        // SUM ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int sum
        XCTAssertEqual(noArray.sumOfProperty("intCol").integerValue, 4, "Sum should be 4")
        XCTAssertEqual(yesArray.sumOfProperty("intCol").integerValue, 0, "Sum should be 0")

        // Test float sum
        XCTAssertEqualWithAccuracy(noArray.sumOfProperty("floatCol").floatValue, Float(0), accuracy: 0.1, "Sum should be 0.0")
        XCTAssertEqualWithAccuracy(yesArray.sumOfProperty("floatCol").floatValue, Float(7.2), accuracy: 0.1, "Sum should be 7.2")

        // Test double sum
        XCTAssertEqualWithAccuracy(noArray.sumOfProperty("doubleCol").doubleValue, Double(10), accuracy: 0.1, "Sum should be 10.0")
        XCTAssertEqualWithAccuracy(yesArray.sumOfProperty("doubleCol").doubleValue, Double(0), accuracy: 0.1, "Sum should be 0.0")

        // Average ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("intCol")!.doubleValue, Double(1), accuracy: 0.1, "Average should be 1.0")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("intCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")

        // Test float average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("floatCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("floatCol")!.doubleValue, Double(1.2), accuracy: 0.1, "Average should be 1.2")

        // Test double average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("doubleCol")!.doubleValue, Double(2.5), accuracy: 0.1, "Average should be 2.5")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("doubleCol")!.doubleValue, Double(0), accuracy: 0.1, "Average should be 0.0")

        // MIN ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int min
        var min = noArray.minOfProperty("intCol") as! NSNumber
        XCTAssertEqual(min.intValue, Int32(1), "Minimum should be 1")
        min = yesArray.minOfProperty("intCol") as! NSNumber
        XCTAssertEqual(min.intValue, Int32(0), "Minimum should be 0")

        // Test float min
        min = noArray.minOfProperty("floatCol") as! NSNumber
        XCTAssertEqualWithAccuracy(min.floatValue, Float(0), accuracy: 0.1, "Minimum should be 0.0f")
        min = yesArray.minOfProperty("floatCol") as! NSNumber
        XCTAssertEqualWithAccuracy(min.floatValue, Float(1.2), accuracy: 0.1, "Minimum should be 1.2f")

        // Test double min
        min = noArray.minOfProperty("doubleCol") as! NSNumber
        XCTAssertEqualWithAccuracy(min.doubleValue, Double(2.5), accuracy: 0.1, "Minimum should be 1.5")
        min = yesArray.minOfProperty("doubleCol") as! NSNumber
        XCTAssertEqualWithAccuracy(min.doubleValue, Double(0), accuracy: 0.1, "Minimum should be 0.0")

        // Test date min
        var dateMinOutput = noArray.minOfProperty("dateCol") as! NSDate
        XCTAssertEqualWithAccuracy(dateMinOutput.timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, accuracy: 1, "Minimum should be dateMaxInput")
        dateMinOutput = yesArray.minOfProperty("dateCol") as! NSDate
        XCTAssertEqualWithAccuracy(dateMinOutput.timeIntervalSince1970, dateMinInput.timeIntervalSince1970, accuracy: 1, "Minimum should be dateMinInput")

        // MAX ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int max
        var max = noArray.maxOfProperty("intCol") as! NSNumber
        XCTAssertEqual(max.integerValue, 1, "Maximum should be 8")
        max = yesArray.maxOfProperty("intCol") as! NSNumber
        XCTAssertEqual(max.integerValue, 0, "Maximum should be 10")

        // Test float max
        max = noArray.maxOfProperty("floatCol") as! NSNumber
        XCTAssertEqualWithAccuracy(max.floatValue, Float(0), accuracy: 0.1, "Maximum should be 0.0f")
        max = yesArray.maxOfProperty("floatCol") as! NSNumber
        XCTAssertEqualWithAccuracy(max.floatValue, Float(1.2), accuracy: 0.1, "Maximum should be 1.2f")

        // Test double max
        max = noArray.maxOfProperty("doubleCol") as! NSNumber
        XCTAssertEqualWithAccuracy(max.doubleValue, Double(2.5), accuracy: 0.1, "Maximum should be 3.5")
        max = yesArray.maxOfProperty("doubleCol") as! NSNumber
        XCTAssertEqualWithAccuracy(max.doubleValue, Double(0), accuracy: 0.1, "Maximum should be 0.0")

        // Test date max
        var dateMaxOutput = noArray.maxOfProperty("dateCol") as! NSDate
        XCTAssertEqualWithAccuracy(dateMaxOutput.timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, accuracy: 1, "Maximum should be dateMaxInput")
        dateMaxOutput = yesArray.maxOfProperty("dateCol") as! NSDate
        XCTAssertEqualWithAccuracy(dateMaxOutput.timeIntervalSince1970, dateMinInput.timeIntervalSince1970, accuracy: 1, "Maximum should be dateMinInput")
    }

    func testArrayDescription_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        for _ in 0..<1012 {
            let person = EmployeeObject()
            person.name = "Mary"
            person.age = 24
            person.hired = true
            realm.addObject(person)
        }

        try! realm.commitWriteTransaction()

        let description = EmployeeObject.allObjectsInRealm(realm).description
        XCTAssertTrue((description as NSString).rangeOfString("name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMArray")
        XCTAssertTrue((description as NSString).rangeOfString("Mary").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMArray")

        XCTAssertTrue((description as NSString).rangeOfString("age").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMArray")
        XCTAssertTrue((description as NSString).rangeOfString("24").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMArray")

        XCTAssertTrue((description as NSString).rangeOfString("912 objects skipped").location != Foundation.NSNotFound, "'912 objects skipped' should be displayed when calling \"description\" on RLMArray")
    }

    func makeEmployee(realm: RLMRealm, _ age: Int32, _ name: String, _ hired: Bool) -> EmployeeObject {
        let employee = EmployeeObject()
        employee.age = age
        employee.name = name
        employee.hired = hired
        realm.addObject(employee)
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
        realm.addObject(company)
        company.employees.addObjects(EmployeeObject.allObjectsInRealm(realm))

        try! realm.commitWriteTransaction()

        let peopleInCompany = company.employees
        XCTAssertEqual(peopleInCompany.count, UInt(3), "No links should have been deleted")

        realm.beginWriteTransaction()
        peopleInCompany.removeObjectAtIndex(1) // Should delete link to employee
        try! realm.commitWriteTransaction()

        XCTAssertEqual(peopleInCompany.count, UInt(2), "link deleted when accessing via links")

        var test = peopleInCompany[0] as! EmployeeObject
        XCTAssertEqual(test.age, po1.age, "Should be equal")
        XCTAssertEqual(test.name!, po1.name!, "Should be equal")
        XCTAssertEqual(test.hired, po1.hired, "Should be equal")
        // XCTAssertEqual(test, po1, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568

        test = peopleInCompany[1] as! EmployeeObject
        XCTAssertEqual(test.age, po3.age, "Should be equal")
        XCTAssertEqual(test.name!, po3.name!, "Should be equal")
        XCTAssertEqual(test.hired, po3.hired, "Should be equal")
        // XCTAssertEqual(test, po3, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568

        let allPeople = EmployeeObject.allObjectsInRealm(realm)
        XCTAssertEqual(allPeople.count, UInt(3), "Only links should have been deleted, not the employees")
    }

    func testIndexOfObject_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let po1 = makeEmployee(realm, 40, "Joe", true)
        let po2 = makeEmployee(realm, 30, "John", false)
        let po3 = makeEmployee(realm, 25, "Jill", true)
        try! realm.commitWriteTransaction()

        let results = EmployeeObject.objectsInRealm(realm, "hired = YES")
        XCTAssertEqual(UInt(2), results.count)
        XCTAssertEqual(UInt(0), results.indexOfObject(po1));
        XCTAssertEqual(UInt(1), results.indexOfObject(po3));
        XCTAssertEqual(NSNotFound, Int(results.indexOfObject(po2)));
    }

    func testIndexOfObjectWhere_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        makeEmployee(realm, 40, "Joe", true)
        makeEmployee(realm, 30, "John", false)
        makeEmployee(realm, 25, "Jill", true)
        try! realm.commitWriteTransaction()

        let results = EmployeeObject.objectsInRealm(realm, "hired = YES")
        XCTAssertEqual(UInt(2), results.count)
        XCTAssertEqual(UInt(0), results.indexOfObjectWhere("age = %d", 40))
        XCTAssertEqual(UInt(1), results.indexOfObjectWhere("age = %d", 25))
        XCTAssertEqual(NSNotFound, Int(results.indexOfObjectWhere("age = %d", 30)))
    }

    func testSortingExistingQuery_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        makeEmployee(realm, 20, "A", true)
        makeEmployee(realm, 30, "B", false)
        makeEmployee(realm, 40, "C", true)
        try! realm.commitWriteTransaction()

        let sortedByAge = EmployeeObject.allObjectsInRealm(realm).sortedResultsUsingProperty("age", ascending: true)
        let sortedByName = sortedByAge.sortedResultsUsingProperty("name", ascending: false)

        XCTAssertEqual(Int32(20), (sortedByAge[0] as! EmployeeObject).age)
        XCTAssertEqual(Int32(40), (sortedByName[0] as! EmployeeObject).age)
    }
}
