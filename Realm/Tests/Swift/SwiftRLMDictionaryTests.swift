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
import XCTest

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif

class SwiftRLMDictionaryTests: RLMTestCase {

    // Swift models

    func testFastEnumeration() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()

        let dObj = SwiftRLMDictionaryPropertyObject.create(in: realm, withValue: [])
        let dict = dObj.dict
        let dateMinInput = Date()
        let dateMaxInput = dateMinInput.addingTimeInterval(1000)

        dict["0"] = SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        dict["1"] = SwiftRLMAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        dict["2"] = SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        dict["3"] = SwiftRLMAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        dict["4"] = SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        dict["5"] = SwiftRLMAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        dict["6"] = SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        dict["7"] = SwiftRLMAggregateObject.create(in: realm, withValue: [10, 0 as Float, 2.5 as Double, false, dateMaxInput])
        dict["8"] = SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])
        dict["9"] = SwiftRLMAggregateObject.create(in: realm, withValue: [10, 1.2 as Float, 0 as Double, true, dateMinInput])

        try! realm.commitWriteTransaction()

        XCTAssertEqual(dict.count, UInt(10), "10 objects added")

        var totalSum = 0

        for (key, value) in dict {
            let obj = dict[key] as! SwiftRLMAggregateObject
            if let ao = value as? SwiftRLMAggregateObject {
                XCTAssertEqual(obj.doubleCol, ao.doubleCol)
                totalSum += ao.intCol
            }
        }

        XCTAssertEqual(totalSum, 100, "total sum should be 100")
    }

    func testKeyType() {
        let unmanaged = SwiftRLMDictionaryPropertyObject()
        XCTAssertEqual(unmanaged.dict.keyType, .string)
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let managed = SwiftRLMDictionaryPropertyObject.create(in: realm, withValue: [])
        try! realm.commitWriteTransaction()
        XCTAssertEqual(managed.dict.keyType, .string)
    }

    func testObjectAggregate() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let dateMinInput = Date()
        let dateMaxInput = dateMinInput.addingTimeInterval(1000)
        let dObj = SwiftRLMDictionaryPropertyObject.create(in: realm, withValue: ["dict" : [
            "0": [0, 1.2 as Float, 0 as Double, true, dateMinInput],
            "1": [1, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "2": [0, 1.2 as Float, 0 as Double, true, dateMinInput],
            "3": [1, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "4": [0, 1.2 as Float, 0 as Double, true, dateMinInput],
            "5": [1, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "6": [0, 1.2 as Float, 0 as Double, true, dateMinInput],
            "7": [1, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "8": [0, 1.2 as Float, 0 as Double, true, dateMinInput],
            "9": [0, 1.2 as Float, 0 as Double, true, dateMinInput]
        ]])
        try! realm.commitWriteTransaction()

        XCTAssertEqual(dObj.dict.count, UInt(10), "10 objects added")

        let noArray = dObj.dict.objects(where: "boolCol == NO")
        let yesArray = dObj.dict.objects(where: "boolCol == YES")

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

    func testDictionaryDescription() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let dObj = SwiftRLMDictionaryEmployeeObject.create(in: realm, withValue: [])
        let dict = dObj.dict

        for i in 0..<1012 {
            dict[String(i) as NSString] = makeRlmEmployee(realm, 24, "Mary", true)
        }

        try! realm.commitWriteTransaction()

        let description = dict.description

        XCTAssertTrue((description as NSString).range(of: "name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMDictionary")
        XCTAssertTrue((description as NSString).range(of: "Mary").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMDictionary")

        XCTAssertTrue((description as NSString).range(of: "age").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMDictionary")
        XCTAssertTrue((description as NSString).range(of: "24").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMDictionary")
    }

    func testDeleteLinksAndObjectsInDictionary() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let po1 = makeRlmEmployee(realm, 40, "Joe", true)
        let po2 = makeRlmEmployee(realm, 30, "John", false)
        let po3 = makeRlmEmployee(realm, 25, "Jill", true)

        let company = SwiftRLMCompanyObject()
        realm.add(company)

        company.employeeMap["Joe" as NSString] = po1
        company.employeeMap["John" as NSString] = po2
        company.employeeMap["Jill" as NSString] = po3

        try! realm.commitWriteTransaction()

        let peopleInCompany = company.employeeMap
        XCTAssertEqual(peopleInCompany.count, UInt(3), "No links should have been deleted")

        realm.beginWriteTransaction()
        peopleInCompany.removeObject(forKey: "John" as NSString) // Should delete link to employee
        try! realm.commitWriteTransaction()

        XCTAssertEqual(peopleInCompany.count, UInt(2), "link deleted when accessing via links")

        var test = peopleInCompany["Joe" as NSString]!
        XCTAssertEqual(test.age, po1.age, "Should be equal")
        XCTAssertEqual(test.name, po1.name, "Should be equal")
        XCTAssertEqual(test.hired, po1.hired, "Should be equal")

        test = peopleInCompany["Jill" as NSString]!
        XCTAssertEqual(test.age, po3.age, "Should be equal")
        XCTAssertEqual(test.name, po3.name, "Should be equal")
        XCTAssertEqual(test.hired, po3.hired, "Should be equal")

        realm.beginWriteTransaction()
        peopleInCompany["Jill" as NSString] = nil
        XCTAssertEqual(peopleInCompany.count, UInt(1), "1 remaining link")
        peopleInCompany["Joe" as NSString] = po2
        XCTAssertEqual(peopleInCompany.count, UInt(1), "1 link replaced")
        peopleInCompany.removeAllObjects()
        XCTAssertEqual(peopleInCompany.count, UInt(0), "0 remaining links")
        try! realm.commitWriteTransaction()

        let allPeople = SwiftRLMEmployeeObject.allObjects(in: realm)
        XCTAssertEqual(allPeople.count, UInt(3), "Only links should have been deleted, not the employees")
    }

    // Objective-C models

    func testFastEnumeration_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let dateMinInput = Date()
        let dateMaxInput = dateMinInput.addingTimeInterval(1000)
        let dObj = AggregateDictionaryObject.create(in: realm, withValue: ["dictionary" : [
            "0": [10, 1.2 as Float, 0 as Double, true, dateMinInput],
            "1": [10, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "2": [10, 1.2 as Float, 0 as Double, true, dateMinInput],
            "3": [10, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "4": [10, 1.2 as Float, 0 as Double, true, dateMinInput],
            "5": [10, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "6": [10, 1.2 as Float, 0 as Double, true, dateMinInput],
            "7": [10, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "8": [10, 1.2 as Float, 0 as Double, true, dateMinInput],
            "9": [10, 1.2 as Float, 0 as Double, true, dateMinInput]
        ]])
        try! realm.commitWriteTransaction()

        XCTAssertEqual(dObj.dictionary!.count, UInt(10), "10 objects added")

        var totalSum: CInt = 0
        for key in dObj.dictionary!.allKeys {
            if let ao = dObj.dictionary[key] {
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
        let dObj = AggregateDictionaryObject.create(in: realm, withValue: ["dictionary" : [
            "0": [0, 1.2 as Float, 0 as Double, true, dateMinInput],
            "1": [1, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "2": [0, 1.2 as Float, 0 as Double, true, dateMinInput],
            "3": [1, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "4": [0, 1.2 as Float, 0 as Double, true, dateMinInput],
            "5": [1, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "6": [0, 1.2 as Float, 0 as Double, true, dateMinInput],
            "7": [1, 0 as Float, 2.5 as Double, false, dateMaxInput],
            "8": [0, 1.2 as Float, 0 as Double, true, dateMinInput],
            "9": [0, 1.2 as Float, 0 as Double, true, dateMinInput]
        ]])
        try! realm.commitWriteTransaction()

        XCTAssertEqual(dObj.dictionary!.count, UInt(10), "10 objects added")

        let noArray = dObj.dictionary!.objects(where: "boolCol == NO")
        let yesArray = dObj.dictionary!.objects(where: "boolCol == YES")

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

    func testDictionaryDescription_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let dObj = CompanyObject.create(in: realm, withValue: [])

        for i in 0..<1012 {
            dObj.employeeDict![String(i) as NSString] = makeEmployee(realm, 24, "Mary", true)
        }

        try! realm.commitWriteTransaction()

        let description = dObj.employeeDict!.description
        XCTAssertTrue((description as NSString).range(of: "name").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMDictionary")
        XCTAssertTrue((description as NSString).range(of: "Mary").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMDictionary")

        XCTAssertTrue((description as NSString).range(of: "age").location != Foundation.NSNotFound, "property names should be displayed when calling \"description\" on RLMDictionary")
        XCTAssertTrue((description as NSString).range(of: "24").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMDictionary")
    }

    func makeRlmEmployee(_ realm: RLMRealm, _ age: Int32, _ name: String, _ hired: Bool) -> SwiftRLMEmployeeObject {
        let employee = SwiftRLMEmployeeObject.create(in: realm, withValue: ["age": age,
                                                                            "name": name,
                                                                            "hired": hired])
        return employee
    }

    func makeEmployee(_ realm: RLMRealm, _ age: Int32, _ name: String, _ hired: Bool) -> EmployeeObject {
        let employee = EmployeeObject.create(in: realm, withValue: ["age": age,
                                                                    "name": name,
                                                                    "hired": hired])
        return employee
    }

    func testDeleteLinksAndObjectsInDictionary_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let po1 = makeEmployee(realm, 40, "Joe", true)
        let po2 = makeEmployee(realm, 30, "John", false)
        let po3 = makeEmployee(realm, 25, "Jill", true)
        let company = CompanyObject.create(in: realm, withValue: ["employeeDict":
                                                                    ["Joe": po1,
                                                                     "John": po2,
                                                                     "Jill": po3]])
        try! realm.commitWriteTransaction()

        let peopleInCompany = company.employeeDict!
        XCTAssertEqual(peopleInCompany.count, UInt(3), "No links should have been deleted")

        realm.beginWriteTransaction()
        peopleInCompany["John" as NSString] = nil // Should delete link to employee
        try! realm.commitWriteTransaction()

        XCTAssertEqual(peopleInCompany.count, UInt(2), "link deleted when accessing via links")

        var test = peopleInCompany["Joe" as NSString]!
        XCTAssertEqual(test.age, po1.age, "Should be equal")
        XCTAssertEqual(test.name!, po1.name!, "Should be equal")
        XCTAssertEqual(test.hired, po1.hired, "Should be equal")

        test = peopleInCompany["Jill" as NSString]!
        XCTAssertEqual(test.age, po3.age, "Should be equal")
        XCTAssertEqual(test.name!, po3.name!, "Should be equal")
        XCTAssertEqual(test.hired, po3.hired, "Should be equal")

        let allPeople = EmployeeObject.allObjects(in: realm)
        XCTAssertEqual(allPeople.count, UInt(3), "Only links should have been deleted, not the employees")
    }

    func testIndexOfObject_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let po1 = makeEmployee(realm, 40, "Joe", true)
        let po2 = makeEmployee(realm, 30, "John", false)
        let po3 = makeEmployee(realm, 25, "Jill", true)
        let company = CompanyObject.create(in: realm, withValue: ["employeeDict":
                                                                    ["Joe": po1,
                                                                     "John": po2,
                                                                     "Jill": po3]])
        try! realm.commitWriteTransaction()

        let results = company.employeeDict.objects(where: "hired = YES").sortedResults(usingKeyPath: "name", ascending: false)
        XCTAssertEqual(UInt(2), results.count)
        XCTAssertEqual(UInt(0), results.index(of: po1));
        XCTAssertEqual(UInt(1), results.index(of: po3));
        XCTAssertEqual(NSNotFound, Int(results.index(of: po2)));
    }

    func testSortingExistingQuery_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let company = CompanyObject()
        company.employeeDict["Joe" as NSString] = makeEmployee(realm, 20, "A", true)
        company.employeeDict["John" as NSString] = makeEmployee(realm, 30, "B", false)
        company.employeeDict["Jill" as NSString] = makeEmployee(realm, 40, "C", true)
        realm.add(company)
        try! realm.commitWriteTransaction()

        let sortedByAge = company.employeeDict.sortedResults(usingKeyPath: "age", ascending: true)
        let sortedByName = sortedByAge.sortedResults(usingKeyPath: "name", ascending: false)

        XCTAssertEqual(Int32(20), sortedByAge[0].age)
        XCTAssertEqual(Int32(40), sortedByName[0].age)
    }
}
