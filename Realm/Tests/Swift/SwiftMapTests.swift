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

class SwiftMapTests: RLMTestCase {
    
    func testEnumerationInMap() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()

        let po1 = SwiftRLMEmployeeObject(value:["age": 40, "name": "Joe", "hired": true])
        let po2 = SwiftRLMEmployeeObject(value:["age": 30, "name": "John", "hired": false])
        let po3 = SwiftRLMEmployeeObject(value:["age": 25, "name": "Jill", "hired": true])
        realm.add(po1)
        realm.add(po2)
        realm.add(po3)

        let company = SwiftRLMCompanyObject()
        let employees = SwiftRLMEmployeeObject.allObjects(in: realm)
        for employee in employees {
            company.employeeMap![UUID().uuidString as NSString] = employee as? SwiftRLMEmployeeObject
        }
        try! realm.commitWriteTransaction()

        var totalSum: Int = 0

        for (key, value) in company.employeeMap!.map({ ($0.key, $0.value as! SwiftRLMEmployeeObject) }) {
            totalSum += value.age
        }

        XCTAssertEqual(totalSum, 95, "total sum should be 95")
    }

    func testObjectAggregate_objc() {
        let dateMinInput = Date()
        let dateMaxInput = dateMinInput.addingTimeInterval(1000)

        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        
        let dObj = SwiftRLMDictionaryPropertyObject()

        for i in 0..<5 {
            let object = SwiftRLMAggregateObject.create(in: realm, withValue: [i, Float(i) * 1.1, Double(i) * 1.2, i.isMultiple(of: 2), dateMinInput.addingTimeInterval(Double(i))])
            dObj.dict![NSString(string: "\(i)")] = object
        }

        realm.add(dObj)

        try! realm.commitWriteTransaction()

        // SUM ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int sum
        let i = dObj.dict!.sum(ofProperty: "intCol").intValue
        print(dObj.dict!.sum(ofProperty: "intCol").intValue)
        XCTAssertEqual(dObj.dict!.sum(ofProperty: "intCol").intValue, 100, "Sum should be 100")

        // Test float sum
        XCTAssertEqual(dObj.dict!.sum(ofProperty: "floatCol").floatValue, Float(7.20), accuracy: 0.1, "Sum should be 0.0")

        // Test double sum
        XCTAssertEqual(dObj.dict!.sum(ofProperty: "doubleCol").doubleValue, Double(10), accuracy: 0.1, "Sum should be 10.0")

        // Average ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int average
        XCTAssertEqual(dObj.dict!.average(ofProperty: "intCol")!.doubleValue, Double(10.0), accuracy: 0.1, "Average should be 1.0")

        // Test float average
        XCTAssertEqual(dObj.dict!.average(ofProperty: "floatCol")!.doubleValue, Double(0.72), accuracy: 0.1, "Average should be 0.0")

        // Test double average
        XCTAssertEqual(dObj.dict!.average(ofProperty: "doubleCol")!.doubleValue, Double(1.0), accuracy: 0.1, "Average should be 2.5")

        // MIN ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int min
        var min = dObj.dict!.min(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(min.int32Value, Int32(10), "Minimum should be 10")

        // Test float min
        min = dObj.dict!.min(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(min.floatValue, Float(0), accuracy: 0.1, "Minimum should be 0.0f")

        // Test double min
        min = dObj.dict!.min(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(min.doubleValue, Double(0.0), accuracy: 0.1, "Minimum should be 1.5")

        // Test date min
        let dateMinOutput = dObj.dict!.min(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMinOutput, dateMinInput, "Minimum should be dateMaxInput")

        // MAX ::::::::::::::::::::::::::::::::::::::::::::::
        // Test int max
        var max = dObj.dict!.max(ofProperty: "intCol") as! NSNumber
        XCTAssertEqual(max.intValue, 10, "Maximum should be 10")

        // Test float max
        max = dObj.dict!.max(ofProperty: "floatCol") as! NSNumber
        XCTAssertEqual(max.floatValue, Float(1.2), accuracy: 0.1, "Maximum should be 0.0f")

        // Test double max
        max = dObj.dict!.max(ofProperty: "doubleCol") as! NSNumber
        XCTAssertEqual(max.doubleValue, Double(2.5), accuracy: 0.1, "Maximum should be 3.5")

        // Test date max
        let dateMaxOutput = dObj.dict!.max(ofProperty: "dateCol") as! Date
        XCTAssertEqual(dateMaxOutput, dateMaxInput, "Maximum should be dateMaxInput")
    }

    func testDictionaryDescription_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        for _ in 0..<300 {
            realm.add(SwiftRLMEmployeeObject(value:["age": 900, "name": "Joe", "hired": true]))
            realm.add(SwiftRLMEmployeeObject(value:["age": 30, "name": "John", "hired": false]))
            realm.add(SwiftRLMEmployeeObject(value:["age": 25, "name": "Jill", "hired": true]))
        }

        let company = SwiftRLMCompanyObject()
        for employee in SwiftRLMEmployeeObject.allObjects(in: realm) {
            company.employeeMap![UUID().uuidString as NSString] = employee as? SwiftRLMEmployeeObject
        }
        try! realm.commitWriteTransaction()

        let description = company.employeeMap!.description
        print(description)
        XCTAssertTrue((description as NSString).range(of: "name").location != Foundation.NSNotFound, "property name should be displayed when calling \"description\" on RLMDictionary")
        XCTAssertTrue((description as NSString).range(of: "John").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMDictionary")
        XCTAssertTrue((description as NSString).range(of: "age").location != Foundation.NSNotFound, "property age should be displayed when calling \"description\" on RLMDictionary")
        XCTAssertTrue((description as NSString).range(of: "900").location != Foundation.NSNotFound, "property values should be displayed when calling \"description\" on RLMDictionary")
        XCTAssertTrue((description as NSString).range(of: "800 objects skipped").location != Foundation.NSNotFound, "'800 objects skipped' should be displayed when calling \"description\" on RLMDictionary")
    }
}
