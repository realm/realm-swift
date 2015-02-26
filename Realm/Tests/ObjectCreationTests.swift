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
        XCTAssertEqual(object.boolCol, false)
        XCTAssertEqual(object.intCol, 123)
        XCTAssertEqual(object.floatCol, 1.23 as Float)
        XCTAssertEqual(object.doubleCol, 12.3)
        XCTAssertEqual(object.stringCol, "a")
        XCTAssertEqual(object.binaryCol, SwiftObject.defaultBinaryCol())
        XCTAssertEqual(object.dateCol, SwiftObject.defaultDateCol())
        XCTAssertEqual(object.objectCol.boolCol, false)
        XCTAssertEqual(object.arrayCol.count, 0)

        // test realm properties are nil for standalone
        XCTAssertNil(object.realm)
        XCTAssertNil(object.objectCol.realm)
        XCTAssertNil(object.arrayCol.realm)
    }

    func testInitWithDictionaryLiteral() {
        // dictionary with all values specified
        let date = NSDate(timeIntervalSince1970: 2)
        let data = "b".dataUsingEncoding(NSUTF8StringEncoding)!
        let boolObj = SwiftBoolObject(object: [true])
        let object = SwiftObject(object: ["boolCol": true,
            "intCol": 1,
            "floatCol": 1.1 as Float,
            "doubleCol": 11.1,
            "stringCol": "b",
            "binaryCol": data,
            "dateCol": date,
            "objectCol": SwiftBoolObject(object: [true]),
            "arrayCol": [SwiftBoolObject(), SwiftBoolObject()]
        ])
        XCTAssertEqual(object.boolCol, true)
        XCTAssertEqual(object.intCol, 1)
        XCTAssertEqual(object.floatCol, 1.1 as Float)
        XCTAssertEqual(object.doubleCol, 11.1)
        XCTAssertEqual(object.stringCol, "b")
        XCTAssertEqual(object.binaryCol, data)
        XCTAssertEqual(object.dateCol, date)
        XCTAssertEqual(object.objectCol.boolCol, true)
        XCTAssertEqual(object.arrayCol.count, 2)
    }

    func testInitWithDefaultsAndDictionaryLiteral() {
        // test with dictionary with mix of default and one specified value
        let objectWithInt = SwiftObject(object: ["intCol": 200])
        XCTAssertEqual(objectWithInt.intCol, 200)
        XCTAssertEqual(objectWithInt.stringCol, "a")
    }

    func testInitWithArrayLiteral() {
        // test with array literal
        let date = NSDate(timeIntervalSince1970: 2)
        let data = "b".dataUsingEncoding(NSUTF8StringEncoding)!
        let arrayObject = SwiftObject(object: [true, 1, 1.1, 11.1, "b", data, date, ["boolCol": true], [[true], [false]]])
        XCTAssertEqual(arrayObject.boolCol, true)
        XCTAssertEqual(arrayObject.intCol, 1)
        XCTAssertEqual(arrayObject.floatCol, 1.1 as Float)
        XCTAssertEqual(arrayObject.doubleCol, 11.1)
        XCTAssertEqual(arrayObject.stringCol, "b")
        XCTAssertEqual(arrayObject.binaryCol, data)
        XCTAssertEqual(arrayObject.dateCol, date)
        XCTAssertEqual(arrayObject.objectCol.boolCol, true)
        XCTAssertEqual(arrayObject.arrayCol.count, 2)
        XCTAssertEqual(arrayObject.arrayCol[0].boolCol, true)

        // test with invalid array literals
        assertThrows(SwiftObject(object: [true, 1, 1.1, 11.1, "b", data, date, ["boolCol": true]]), "Missing properties")
        assertThrows(SwiftObject(object: ["invalid", 1, 1.1, 11.1, "b", data, date, ["boolCol": true], [[true], [false]]]), "Invalid property types")
    }

    func testInitWithKVCObject() {
        // test with kvc object
        let objectWithInt = SwiftObject(object: ["intCol": 200])
        let objectWithKVCObject = SwiftObject(object: objectWithInt)
        XCTAssertEqual(objectWithKVCObject.intCol, 200)
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
        XCTAssertEqual(object.boolCol, false)
        XCTAssertEqual(object.intCol, 123)
        XCTAssertEqual(object.floatCol, 1.23 as Float)
        XCTAssertEqual(object.doubleCol, 12.3)
        XCTAssertEqual(object.stringCol, "a")
        XCTAssertEqual(object.binaryCol, SwiftObject.defaultBinaryCol())
        XCTAssertEqual(object.dateCol, SwiftObject.defaultDateCol())
        XCTAssertEqual(object.objectCol.boolCol, false)
        XCTAssertEqual(object.arrayCol.count, 0)

        // test realm properties
        XCTAssertEqual(object.realm!, realm)
        XCTAssertEqual(object.objectCol.realm!, realm)
        XCTAssertEqual(object.arrayCol.realm!, realm)
    }

    func testCreateWithDictionaryLiteral() {
        // test create with partial dictionary literal
        let date = NSDate(timeIntervalSince1970: 2)
        let data = "b".dataUsingEncoding(NSUTF8StringEncoding)!
        let boolObj = SwiftBoolObject(object: [true])

        let realm = Realm()
        realm.beginWrite()
        let object = realm.create(SwiftObject.self, value: ["boolCol": true,
            "intCol": 1,
            "floatCol": 1.1 as Float,
            "doubleCol": 11.1,
            "stringCol": "b",
            "binaryCol": data,
            "dateCol": date,
            "objectCol": SwiftBoolObject(object: [true]),
            "arrayCol": [SwiftBoolObject(), SwiftBoolObject()]])
        realm.commitWrite()

        XCTAssertEqual(object.boolCol, true)
        XCTAssertEqual(object.intCol, 1)
        XCTAssertEqual(object.floatCol, 1.1 as Float)
        XCTAssertEqual(object.doubleCol, 11.1)
        XCTAssertEqual(object.stringCol, "b")
        XCTAssertEqual(object.binaryCol, data)
        XCTAssertEqual(object.dateCol, date)
        XCTAssertEqual(object.objectCol.boolCol, true)
        XCTAssertEqual(object.arrayCol.count, 2)
    }

    func testCreateWithDefaultsAndDictionaryLiteral() {
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
    // test literals with existing objects
    // test literals with existing lists

    // MARK: Add tests
    func testAddWithExisingNestedObjects() {
    }

    func testAddAndUpdateWithExisingNestedObjects() {
    }
}