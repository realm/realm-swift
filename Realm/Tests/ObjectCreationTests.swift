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
    }

    func testInitWithDictionaryLiteral() {
    }

    func testInitWithDefaultsAndDictionaryLiteral() {
    }

    func testInitWithArrayLiteral() {
    }

    func testInitWithKVCObject() {
    }

    // MARK: Creation tests
    func testCreateWithDefaults() {
    }

    func testCreateWithDictionaryLiteral() {
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

    // MARK: Add tests
    func testAddWithExisingNestedObjects() {

    }

    func testAddAndUpdateWithExisingNestedObjects() {

    }

    // MARK: Old tests
    func testInitStandaloneObject() {
        let object = SwiftObject()

        XCTAssertNil(object.realm)
        XCTAssertEqual(object.stringCol, "a", "Should be initialized with default value")
        XCTAssertEqual(object.arrayCol.count, 0)
        XCTAssertNil(object.arrayCol.realm)
    }

    func testInitStandaloneObjectWithObject() {
        // test with all defaults
        let object = SwiftObject(object: [:])
        XCTAssertNil(object.realm)
        XCTAssertEqual(object.boolCol, false)
        XCTAssertEqual(object.intCol, 123)
        XCTAssertEqual(object.floatCol, 1.23 as Float)
        XCTAssertEqual(object.doubleCol, 12.3)
        XCTAssertEqual(object.stringCol, "a")

        let data = "a".dataUsingEncoding(NSUTF8StringEncoding)!
        XCTAssertEqual(object.binaryCol, data)

        let date = NSDate(timeIntervalSince1970: 1)
        XCTAssertEqual(object.dateCol, date)
        XCTAssertEqual(object.objectCol.boolCol, false)
        XCTAssertNil(object.objectCol.realm)
        XCTAssertEqual(object.arrayCol.count, 0)
        XCTAssertNil(object.arrayCol.realm)

        // test with dictionary with mix of default and one specified value
        let objectWithInt = SwiftObject(object: ["intCol": 200])
        XCTAssertEqual(objectWithInt.intCol, 200)

        let objectWithListLiteral = SwiftObject(object: ["arrayCol" : [[true]]])
        XCTAssertEqual(objectWithListLiteral.arrayCol.count, 1)
        XCTAssertEqual(objectWithListLiteral.arrayCol.first!.boolCol, true)
        XCTAssertNil(objectWithListLiteral.arrayCol.realm)

        let objectWithObjectLiteral = SwiftObject(object: ["objectCol" : ["boolCol" : true]])
        XCTAssertEqual(objectWithObjectLiteral.objectCol.boolCol, true)

        // test with kvc object
        let objectWithKVCObject = SwiftObject(object: objectWithInt)
        XCTAssertEqual(objectWithKVCObject.intCol, 200)

        // test with array literal
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
    }

    func testCreate() {
        let realm = Realm()
        assertThrows(realm.create(SwiftObject.self, value: [:]), "Must be in write transaction")

        let objects = realm.objects(SwiftObject)
        XCTAssertEqual(0, objects.count)
        realm.write {
            // test create with all defaults and dictionary literal
            realm.create(SwiftObject.self, value: [:])
            realm.create(SwiftObject.self, value: ["boolCol" : true])

            // test with array literal
            var intObject = realm.create(SwiftIntObject.self, value: [1])
            XCTAssertEqual(intObject.intCol, 1)

            // test with kvc object
            intObject = realm.create(SwiftIntObject.self, value: intObject)
            XCTAssertEqual(intObject.intCol, 1)
            XCTAssertEqual(realm.objects(SwiftIntObject).count, 2)

            // test with invalid object
            self.assertThrows(realm.create(SwiftBoolObject.self, value: NSObject()))

            // test with invalid type
            self.assertThrows(realm.create(Object.self, value: [:]))
        }
        XCTAssertEqual(2, objects.count)
        XCTAssertEqual(objects[0].boolCol, false)
        XCTAssertEqual(objects[1].boolCol, true)
    }
    
    func testCreateWithUpdate() {
        
    }

}