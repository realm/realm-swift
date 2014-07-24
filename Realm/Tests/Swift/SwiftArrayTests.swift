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
import TestFramework

class SwiftArrayTests: SwiftTestCase {

    // Swift models
    
    func testFastEnumeration() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        
        let dateMinInput = NSDate()
        let dateMaxInput = dateMinInput.dateByAddingTimeInterval(1000)
        
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        
        realm.commitWriteTransaction()

        let results = realm.objects(SwiftAggregateObject(), "intCol < %d", 100)
        XCTAssertEqual(results.count, 10, "10 objects added")
        
        var totalSum = 0

        for ao in results {
            totalSum += ao.intCol
        }

        XCTAssertEqual(totalSum, 100, "total sum should be 100")
    }

    func testReadOnly() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        let obj = SwiftStringObject.createInRealm(realm, withObject: ["name"])
        realm.commitWriteTransaction()
        
        let array = realm.objects(SwiftStringObject())
        XCTAssertTrue(array.readOnly, "Array returned from query should be readonly")
    }

    func testObjectAggregate() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        
        let dateMinInput = NSDate()
        let dateMaxInput = dateMinInput.dateByAddingTimeInterval(1000)
        
        SwiftAggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        SwiftAggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        
        realm.commitWriteTransaction()

        let noArray = realm.objects(SwiftAggregateObject(), "boolCol == NO")
        let yesArray = realm.objects(SwiftAggregateObject(), "boolCol == YES")

        // SUM ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int sum
        XCTAssertEqual(noArray.sumOfProperty("intCol"), 4, "Sum should be 4")
        XCTAssertEqual(yesArray.sumOfProperty("intCol"), 0, "Sum should be 0")

        // Test float sum
        XCTAssertEqualWithAccuracy(noArray.sumOfProperty("floatCol"), 0, 0.1, "Sum should be 0.0")
        XCTAssertEqualWithAccuracy(yesArray.sumOfProperty("floatCol"), 7.2, 0.1, "Sum should be 7.2")

        // Test double sum
        XCTAssertEqualWithAccuracy(noArray.sumOfProperty("doubleCol"), 10, 0.1, "Sum should be 10.0")
        XCTAssertEqualWithAccuracy(yesArray.sumOfProperty("doubleCol"), 0, 0.1, "Sum should be 0.0")

        // Average ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("intCol"), 1, 0.1, "Average should be 1.0")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("intCol"), 0, 0.1, "Average should be 0.0")

        // Test float average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("floatCol"), 0, 0.1, "Average should be 0.0")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("floatCol"), 1.2, 0.1, "Average should be 1.2")

        // Test double average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("doubleCol"), 2.5, 0.1, "Average should be 2.5")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("doubleCol"), 0, 0.1, "Average should be 0.0")

        // MIN ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int min
        XCTAssertEqual(noArray.minOfProperty("intCol") as Int, 1, "Minimum should be 1")
        XCTAssertEqual(yesArray.minOfProperty("intCol") as Int, 0, "Minimum should be 0")

        // Test float min
        XCTAssertEqualWithAccuracy(noArray.minOfProperty("floatCol") as Float, 0, 0.1, "Minimum should be 0.0f")
        XCTAssertEqualWithAccuracy(yesArray.minOfProperty("floatCol") as Float, 1.2, 0.1, "Minimum should be 1.2f")

        // Test double min
        XCTAssertEqualWithAccuracy(noArray.minOfProperty("doubleCol") as Double, 2.5, 0.1, "Minimum should be 1.5")
        XCTAssertEqualWithAccuracy(yesArray.minOfProperty("doubleCol") as Double, 0, 0.1, "Minimum should be 0.0")

        // Test date min
        XCTAssertEqualWithAccuracy((noArray.minOfProperty("dateCol") as NSDate).timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, 1, "Minimum should be dateMaxInput")
        XCTAssertEqualWithAccuracy((yesArray.minOfProperty("dateCol") as NSDate).timeIntervalSince1970, dateMinInput.timeIntervalSince1970, 1, "Minimum should be dateMinInput")

        // MAX ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int max
        XCTAssertEqual(noArray.maxOfProperty("intCol") as Int, 1, "Maximum should be 1")
        XCTAssertEqual(yesArray.maxOfProperty("intCol") as Int, 0, "Maximum should be 0")

        // Test float max
        XCTAssertEqualWithAccuracy(noArray.maxOfProperty("floatCol") as Float, 0, 0.1, "Maximum should be 0.0f")
        XCTAssertEqualWithAccuracy(yesArray.maxOfProperty("floatCol") as Float, 1.2, 0.1, "Maximum should be 1.2f")

        // Test double max
        XCTAssertEqualWithAccuracy(noArray.maxOfProperty("doubleCol") as Double, 2.5, 0.1, "Maximum should be 3.5")
        XCTAssertEqualWithAccuracy(yesArray.maxOfProperty("doubleCol") as Double, 0, 0.1, "Maximum should be 0.0")

        // Test date max
        XCTAssertEqualWithAccuracy((noArray.maxOfProperty("dateCol") as NSDate).timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, 1, "Maximum should be dateMaxInput")
        XCTAssertEqualWithAccuracy((yesArray.maxOfProperty("dateCol") as NSDate).timeIntervalSince1970, dateMinInput.timeIntervalSince1970, 1, "Maximum should be dateMinInput")
    }

    func testArrayDescription() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        
        for i in 0..<1012 {
            let person = SwiftEmployeeObject()
            person.name = "Mary"
            person.age = 24
            person.hired = true
            realm.addObject(person)
        }
        
        realm.commitWriteTransaction()

        let description = realm.objects(SwiftEmployeeObject()).description as NSString
        XCTAssertTrue((description as NSString).rangeOfString("name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RealmArray")
        
        XCTAssertTrue(description.rangeOfString("name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RealmArray")
        XCTAssertTrue(description.rangeOfString("Mary").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RealmArray")
        
        XCTAssertTrue(description.rangeOfString("age").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RealmArray")
        XCTAssertTrue(description.rangeOfString("24").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RealmArray")
        
        XCTAssertTrue(description.rangeOfString("912 objects skipped").location != Foundation.NSNotFound, "'912 objects skipped' should be displayed when calling \"description\" on RealmArray")
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
        company.employees = realm.objects(SwiftEmployeeObject()).rlmArray
        
        realm.commitWriteTransaction()
        
        let peopleInCompany = RealmArray<SwiftEmployeeObject>(rlmArray: company.employees)
        XCTAssertEqual(peopleInCompany.count, 3, "No links should have been deleted")
        
        realm.beginWriteTransaction()
        peopleInCompany.removeObjectAtIndex(1) // Should delete link to employee
        realm.commitWriteTransaction()
        
        XCTAssertEqual(peopleInCompany.count, 2, "link deleted when accessing via links")
        
        var person0 = peopleInCompany[0]
        XCTAssertEqual(person0.age, po1.age, "Should be equal")
        XCTAssertEqual(person0.name, po1.name, "Should be equal")
        XCTAssertEqual(person0.hired, po1.hired, "Should be equal")
        // XCTAssertEqualObjects(person0, po1, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568
        
        let person1 = peopleInCompany[1]
        XCTAssertEqual(person1.age, po3.age, "Should be equal")
        XCTAssertEqual(person1.name, po3.name, "Should be equal")
        XCTAssertEqual(person1.hired, po3.hired, "Should be equal")
        // XCTAssertEqualObjects(person1, po3, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568

        realm.beginWriteTransaction()
        peopleInCompany.removeLastObject()
        XCTAssertEqual(peopleInCompany.count, 1, "1 remaining link")
        peopleInCompany.replaceObjectAtIndex(0, withObject: po2)
        XCTAssertEqual(peopleInCompany.count, 1, "1 link replaced")
        peopleInCompany.insertObject(po1, atIndex: 0)
        XCTAssertEqual(peopleInCompany.count, 2, "2 links")
        peopleInCompany.removeAllObjects()
        XCTAssertEqual(peopleInCompany.count, 0, "0 remaining links")
        realm.commitWriteTransaction()
    }

    // Objective-C models

    func testFastEnumeration_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let dateMinInput = NSDate()
        let dateMaxInput = dateMinInput.dateByAddingTimeInterval(1000)

        AggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withObject: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withObject: [10, 1.2 as Float, 0 as Double, true, dateMinInput])

        realm.commitWriteTransaction()

        let results = realm.objects(AggregateObject(), "intCol < %d", 100)
        XCTAssertEqual(results.count, 10, "10 objects added")

        var totalSum: CInt = 0

        for ao in results {
            totalSum += ao.intCol
        }

        XCTAssertEqual(totalSum, 100, "total sum should be 100")
    }

    func testReadOnly_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let obj = StringObject.createInRealm(realm, withObject: ["name"])
        realm.commitWriteTransaction()

        let array = realm.objects(StringObject())
        XCTAssertTrue(array.readOnly, "Array returned from query should be readonly")
    }

    func testObjectAggregate_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let dateMinInput = NSDate()
        let dateMaxInput = dateMinInput.dateByAddingTimeInterval(1000)

        AggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withObject: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withObject: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withObject: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withObject: [1, 0 as Float, 2.5 as Double, false, dateMaxInput])
        AggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])
        AggregateObject.createInRealm(realm, withObject: [0, 1.2 as Float, 0 as Double, true, dateMinInput])

        realm.commitWriteTransaction()

        let noArray = realm.objects(AggregateObject(), "boolCol == NO")
        let yesArray = realm.objects(AggregateObject(), "boolCol == YES")

        // SUM ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int sum
        XCTAssertEqual(noArray.sumOfProperty("intCol"), 4, "Sum should be 4")
        XCTAssertEqual(yesArray.sumOfProperty("intCol"), 0, "Sum should be 0")

        // Test float sum
        XCTAssertEqualWithAccuracy(noArray.sumOfProperty("floatCol"), 0, 0.1, "Sum should be 0.0")
        XCTAssertEqualWithAccuracy(yesArray.sumOfProperty("floatCol"), 7.2, 0.1, "Sum should be 7.2")

        // Test double sum
        XCTAssertEqualWithAccuracy(noArray.sumOfProperty("doubleCol"), 10, 0.1, "Sum should be 10.0")
        XCTAssertEqualWithAccuracy(yesArray.sumOfProperty("doubleCol"), 0, 0.1, "Sum should be 0.0")

        // Average ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("intCol"), 1, 0.1, "Average should be 1.0")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("intCol"), 0, 0.1, "Average should be 0.0")

        // Test float average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("floatCol"), 0, 0.1, "Average should be 0.0")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("floatCol"), 1.2, 0.1, "Average should be 1.2")

        // Test double average
        XCTAssertEqualWithAccuracy(noArray.averageOfProperty("doubleCol"), 2.5, 0.1, "Average should be 2.5")
        XCTAssertEqualWithAccuracy(yesArray.averageOfProperty("doubleCol"), 0, 0.1, "Average should be 0.0")

        // MIN ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int min
        XCTAssertEqual(noArray.minOfProperty("intCol") as Int, 1, "Minimum should be 1")
        XCTAssertEqual(yesArray.minOfProperty("intCol") as Int, 0, "Minimum should be 0")

        // Test float min
        XCTAssertEqualWithAccuracy(noArray.minOfProperty("floatCol") as Float, 0, 0.1, "Minimum should be 0.0f")
        XCTAssertEqualWithAccuracy(yesArray.minOfProperty("floatCol") as Float, 1.2, 0.1, "Minimum should be 1.2f")

        // Test double min
        XCTAssertEqualWithAccuracy(noArray.minOfProperty("doubleCol") as Double, 2.5, 0.1, "Minimum should be 1.5")
        XCTAssertEqualWithAccuracy(yesArray.minOfProperty("doubleCol") as Double, 0, 0.1, "Minimum should be 0.0")

        // Test date min
        XCTAssertEqualWithAccuracy((noArray.minOfProperty("dateCol") as NSDate).timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, 1, "Minimum should be dateMaxInput")
        XCTAssertEqualWithAccuracy((yesArray.minOfProperty("dateCol") as NSDate).timeIntervalSince1970, dateMinInput.timeIntervalSince1970, 1, "Minimum should be dateMinInput")

        // MAX ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int max
        XCTAssertEqual(noArray.maxOfProperty("intCol") as Int, 1, "Maximum should be 1")
        XCTAssertEqual(yesArray.maxOfProperty("intCol") as Int, 0, "Maximum should be 0")

        // Test float max
        XCTAssertEqualWithAccuracy(noArray.maxOfProperty("floatCol") as Float, 0, 0.1, "Maximum should be 0.0f")
        XCTAssertEqualWithAccuracy(yesArray.maxOfProperty("floatCol") as Float, 1.2, 0.1, "Maximum should be 1.2f")

        // Test double max
        XCTAssertEqualWithAccuracy(noArray.maxOfProperty("doubleCol") as Double, 2.5, 0.1, "Maximum should be 3.5")
        XCTAssertEqualWithAccuracy(yesArray.maxOfProperty("doubleCol") as Double, 0, 0.1, "Maximum should be 0.0")

        // Test date max
        XCTAssertEqualWithAccuracy((noArray.maxOfProperty("dateCol") as NSDate).timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, 1, "Maximum should be dateMaxInput")
        XCTAssertEqualWithAccuracy((yesArray.maxOfProperty("dateCol") as NSDate).timeIntervalSince1970, dateMinInput.timeIntervalSince1970, 1, "Maximum should be dateMinInput")
    }

    func testArrayDescription_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        for i in 0..<1012 {
            let person = EmployeeObject()
            person.name = "Mary"
            person.age = 24
            person.hired = true
            realm.addObject(person)
        }

        realm.commitWriteTransaction()

        let description = realm.objects(EmployeeObject()).description as NSString

        XCTAssertTrue(description.rangeOfString("name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RealmArray")
        XCTAssertTrue(description.rangeOfString("Mary").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RealmArray")

        XCTAssertTrue(description.rangeOfString("age").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RealmArray")
        XCTAssertTrue(description.rangeOfString("24").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RealmArray")

        XCTAssertTrue(description.rangeOfString("912 objects skipped").location != Foundation.NSNotFound, "'912 objects skipped' should be displayed when calling \"description\" on RealmArray")
    }

    func testDeleteLinksAndObjectsInArray_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let po1 = EmployeeObject()
        po1.age = 40
        po1.name = "Joe"
        po1.hired = true

        let po2 = EmployeeObject()
        po2.age = 30
        po2.name = "John"
        po2.hired = false

        let po3 = EmployeeObject()
        po3.age = 25
        po3.name = "Jill"
        po3.hired = true

        realm.addObject(po1)
        realm.addObject(po2)
        realm.addObject(po3)

        let company = CompanyObject()
        company.name = "name"
        realm.addObject(company)
        company.employees = realm.objects(EmployeeObject()).rlmArray

        realm.commitWriteTransaction()

        let peopleInCompany = RealmArray<EmployeeObject>(rlmArray: company.employees)
        XCTAssertEqual(peopleInCompany.count, 3, "No links should have been deleted")

        realm.beginWriteTransaction()
        peopleInCompany.removeObjectAtIndex(1) // Should delete link to employee
        realm.commitWriteTransaction()

        XCTAssertEqual(peopleInCompany.count, 2, "link deleted when accessing via links")

        let person0 = peopleInCompany[0]
        XCTAssertEqual(person0.age, po1.age, "Should be equal")
        XCTAssertEqual(person0.name!, po1.name!, "Should be equal")
        XCTAssertEqual(person0.hired, po1.hired, "Should be equal")
        // XCTAssertEqualObjects(person0, po1, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568

        let person1 = peopleInCompany[1]
        XCTAssertEqual(person1.age, po3.age, "Should be equal")
        XCTAssertEqual(person1.name!, po3.name!, "Should be equal")
        XCTAssertEqual(person1.hired, po3.hired, "Should be equal")
        // XCTAssertEqualObjects(person1, po3, "Should be equal") //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568
        
        let allPeople = realm.objects(EmployeeObject())
        XCTAssertEqual(allPeople.count, 3, "Only links should have been deleted, not the employees")
    }
}
