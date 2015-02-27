////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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
import Foundation

class ObjectCreationTests: TestCase {

    // MARK: Init tests
    func testInitWithDefaults() {
        // test all properties are defaults
        let object = SwiftObject()
        XCTAssertNil(object.realm)

        // test defaults values
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: SwiftObject.defaultValues(), boolObjectValue: false, boolObjectListValues: [])

        // test realm properties are nil for standalone
        XCTAssertNil(object.realm)
        XCTAssertNil(object.objectCol.realm)
        XCTAssertNil(object.arrayCol.realm)
    }

    func testInitWithDictionaryLiteral() {
        // dictionary with all values specified
        let valueCreator =  {
           ["boolCol": true as NSNumber,
            "intCol": 1 as NSNumber,
            "floatCol": 1.1 as NSNumber,
            "doubleCol": 11.1 as NSNumber,
            "stringCol": "b" as NSString,
            "binaryCol": "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
            "dateCol": NSDate(timeIntervalSince1970: 2) as NSDate,
            "objectCol": SwiftBoolObject(object: [true]) as AnyObject,
            "arrayCol": [SwiftBoolObject(), SwiftBoolObject()]  as AnyObject
           ]
        }
        let value = valueCreator()
        let object = SwiftObject(object: value)
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: value, boolObjectValue: true, boolObjectListValues: [false, false])

        // TODO - test all valid value types for each property type (list and object)

        // test with invalid dictionary literals
        let invalidValues = ["invalid", "invalid", "invalid", "invalid", 0x17A71D, "invalid", "invalid", "invalid", "invalid"]
        let props = object.objectSchema.properties
        for propNum in 0..<props.count {
            var invalidValue = valueCreator()
            invalidValue[props[propNum].name] = invalidValues[propNum]
            assertThrows(SwiftObject(object: invalidValue), "Invalid property value")
        }
    }

    func testInitWithDefaultsAndDictionaryLiteral() {
        // test with dictionary with mix of default and one specified value
        let object = SwiftObject(object: ["intCol": 200])
        var valueDict = defaultSwiftObjectValuesWithReplacements(["intCol": 200])
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
    }

    func testInitWithArrayLiteral() {
        // test with array literal
        let date = NSDate(timeIntervalSince1970: 2)
        let data = "b".dataUsingEncoding(NSUTF8StringEncoding)!
        let valueCreator = { [true, 1, 1.1, 11.1, "b", data, date, ["boolCol": true], [[true], [false]]] }
        let value = valueCreator()
        let arrayObject = SwiftObject(object: value)
        verifySwiftObjectWithArrayLiteral(arrayObject, array: value, boolObjectValue: true, boolObjectListValues: [true, false])

        // TODO - test all valid value types for each property type (list and object)

        // test with invalid array literals
        assertThrows(SwiftObject(object: [true, 1, 1.1, 11.1, "b", data, date, ["boolCol": true]]), "Missing properties")

        let invalidValues = ["invalid", "invalid", "invalid", "invalid", 0x17A71D, "invalid", "invalid", "invalid", "invalid"]
        let props = arrayObject.objectSchema.properties
        for propNum in 0..<props.count {
            var invalidValue = valueCreator()
            invalidValue[propNum] = invalidValues[propNum]
            assertThrows(SwiftObject(object: invalidValue), "Invalid property value")
        }
    }

    func testInitWithKVCObject() {
        // test with kvc object
        let objectWithInt = SwiftObject(object: ["intCol": 200])
        let objectWithKVCObject = SwiftObject(object: objectWithInt)
        var valueDict = defaultSwiftObjectValuesWithReplacements(["intCol": 200])
        verifySwiftObjectWithDictionaryLiteral(objectWithKVCObject, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
    }

    // MARK: Creation tests

    func testCreateWithDefaults() {
        let realm = Realm()
        assertThrows(realm.create(SwiftObject.self), "Must be in write transaction")

        var object: SwiftObject!
        let objects = realm.objects(SwiftObject)
        XCTAssertEqual(0, objects.count)
        realm.write {
            // test create with all defaults
            object = realm.create(SwiftObject.self)
            return
        }
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: SwiftObject.defaultValues(), boolObjectValue: false, boolObjectListValues: [])

        // test realm properties are populated correctly
        XCTAssertEqual(object.realm!, realm)
        XCTAssertEqual(object.objectCol.realm!, realm)
        XCTAssertEqual(object.arrayCol.realm!, realm)
    }

    func testCreateWithDictionaryLiteral() {
        // test create with partial dictionary literal
        let date = NSDate(timeIntervalSince1970: 2)
        let data = "b".dataUsingEncoding(NSUTF8StringEncoding)!
        let boolObj = SwiftBoolObject(object: [true])
        let dict = ["boolCol": true,
            "intCol": 1,
            "floatCol": 1.1 as Float,
            "doubleCol": 11.1,
            "stringCol": "b",
            "binaryCol": data,
            "dateCol": date,
            "objectCol": SwiftBoolObject(object: [true]),
            "arrayCol": [SwiftBoolObject(), SwiftBoolObject()]]

        let realm = Realm()
        realm.beginWrite()
        let object = realm.create(SwiftObject.self, value: dict)
        realm.commitWrite()

        verifySwiftObjectWithDictionaryLiteral(object, dictionary: dict, boolObjectValue: true, boolObjectListValues: [false, false])
    }

    func testCreateWithDefaultsAndDictionaryLiteral() {
        // test with dictionary with mix of default and one specified value
        let realm = Realm()
        realm.beginWrite()
        let objectWithInt = realm.create(SwiftObject.self, value: ["intCol": 200])
        realm.commitWrite()

        var valueDict = defaultSwiftObjectValuesWithReplacements(["intCol": 200])
        verifySwiftObjectWithDictionaryLiteral(objectWithInt, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
    }

    func testCreateWithArrayLiteral() {
    }

    func testCreateWithKVCObject() {
    }

    func testCreateWithNestedObjects() {
    }

    func testUpdateWithNestedObjects() {
    }

    func testCreateWithObjectsFromAnotherRealm() {
    }

    func testUpdateWithObjectsFromAnotherRealm() {
    }

    // test NSNull for object
    // test NSNull for list
    // test null object
    // test null list
    // test literals with standalone objects
    // test literals with existing objects
    // test literals with existing lists

    // MARK: Add tests
    func testAddWithExisingNestedObjects() {
    }

    func testAddAndUpdateWithExisingNestedObjects() {
    }

    // MARK: Private utilities
    private func verifySwiftObjectWithArrayLiteral(object: SwiftObject, array: [AnyObject], boolObjectValue: Bool, boolObjectListValues: [Bool]) {
        XCTAssertEqual(object.boolCol, array[0] as Bool)
        XCTAssertEqual(object.intCol, array[1] as Int)
        XCTAssertEqual(object.floatCol, array[2] as Float)
        XCTAssertEqual(object.doubleCol, array[3] as Double)
        XCTAssertEqual(object.stringCol, array[4] as String)
        XCTAssertEqual(object.binaryCol, array[5] as NSData)
        XCTAssertEqual(object.dateCol, array[6] as NSDate)
        XCTAssertEqual(object.objectCol.boolCol, boolObjectValue)
        XCTAssertEqual(object.arrayCol.count, boolObjectListValues.count)
        for i in 0..<boolObjectListValues.count {
            XCTAssertEqual(object.arrayCol[i].boolCol, boolObjectListValues[i])
        }
    }

    private func verifySwiftObjectWithDictionaryLiteral(object: SwiftObject, dictionary: [String:AnyObject], boolObjectValue: Bool, boolObjectListValues: [Bool]) {
        XCTAssertEqual(object.boolCol, dictionary["boolCol"] as Bool)
        XCTAssertEqual(object.intCol, dictionary["intCol"] as Int)
        XCTAssertEqual(object.floatCol, dictionary["floatCol"] as Float)
        XCTAssertEqual(object.doubleCol, dictionary["doubleCol"] as Double)
        XCTAssertEqual(object.stringCol, dictionary["stringCol"] as String)
        XCTAssertEqual(object.binaryCol, dictionary["binaryCol"] as NSData)
        XCTAssertEqual(object.dateCol, dictionary["dateCol"] as NSDate)
        XCTAssertEqual(object.objectCol.boolCol, boolObjectValue)
        XCTAssertEqual(object.arrayCol.count, boolObjectListValues.count)
        for i in 0..<boolObjectListValues.count {
            XCTAssertEqual(object.arrayCol[i].boolCol, boolObjectListValues[i])
        }
    }

    private func defaultSwiftObjectValuesWithReplacements(replace: [String: AnyObject]) -> [String: AnyObject] {
        var valueDict = SwiftObject.defaultValues()
        for (key, value) in replace {
            valueDict[key] = value
        }
        return valueDict
    }
}