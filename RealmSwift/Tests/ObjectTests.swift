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

class ObjectTests: TestCase {
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
        XCTAssertEqual(object.dateCol, NSDate(timeIntervalSince1970: 1))
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

        // FIXME - test with nested objects
    }

    func testRealm() {
        let standalone = SwiftStringObject()
        XCTAssertNil(standalone.realm)

        let realm = Realm()
        var persisted: SwiftStringObject!
        realm.write {
            persisted = realm.create(SwiftStringObject.self, value: [:])
            XCTAssertNotNil(persisted.realm)
            XCTAssertEqual(realm, persisted.realm!)
        }
        XCTAssertNotNil(persisted.realm)
        XCTAssertEqual(realm, persisted.realm!)

        let group = dispatch_group_create()
        let queue = dispatch_queue_create("background", DISPATCH_QUEUE_SERIAL)
        dispatch_async(queue) {
            XCTAssertNotEqual(Realm(), persisted.realm!)
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
    }

    func testObjectSchema() {
        let object = SwiftObject()
        let schema = object.objectSchema
        XCTAssert(schema as AnyObject is ObjectSchema)
        XCTAssert(schema.properties as AnyObject is [Property])
        XCTAssertEqual(schema.className, "SwiftObject")
        XCTAssertEqual(schema.properties.map { $0.name }, ["boolCol", "intCol", "floatCol", "doubleCol", "stringCol", "binaryCol", "dateCol", "objectCol", "arrayCol"])
    }

    func testInvalidated() {
        let object = SwiftObject()
        XCTAssertFalse(object.invalidated)

        let realm = Realm()
        realm.write {
            realm.add(object)
            XCTAssertFalse(object.invalidated)
        }

        realm.write {
            realm.deleteAll()
            XCTAssertTrue(object.invalidated)
        }
        XCTAssertTrue(object.invalidated)
    }

    func testPrimaryKey() {
        XCTAssertNil(Object.primaryKey(), "primary key should default to nil")
        XCTAssertNil(SwiftStringObject.primaryKey())
        XCTAssertNil(SwiftStringObject().objectSchema.primaryKeyProperty)
        XCTAssertEqual(SwiftPrimaryStringObject.primaryKey(), "stringCol")
        XCTAssertEqual(SwiftPrimaryStringObject().objectSchema.primaryKeyProperty!.name, "stringCol")
    }

    func testIgnoredProperties() {
        XCTAssertEqual(Object.ignoredProperties(), [], "ignored properties should default to []")
        XCTAssertEqual(SwiftIgnoredPropertiesObject.ignoredProperties().count, 2)
        XCTAssertNil(SwiftIgnoredPropertiesObject().objectSchema["runtimeProperty"])
    }

    func testIndexedProperties() {
        XCTAssertEqual(Object.indexedProperties(), [], "indexed properties should default to []")
        XCTAssertEqual(SwiftIndexedPropertiesObject.indexedProperties().count, 2)
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["stringCol"]!.indexed)
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["intCol"]!.indexed)
    }

    func testLinkingObjects() {
        let realm = Realm()
        let object = SwiftEmployeeObject()
        assertThrows(object.linkingObjects(SwiftCompanyObject.self, forProperty: "employees"))
        realm.write {
            realm.add(object)
            self.assertThrows(object.linkingObjects(SwiftCompanyObject.self, forProperty: "noSuchCol"))
            XCTAssertEqual(0, object.linkingObjects(SwiftCompanyObject.self, forProperty: "employees").count)
            for _ in 0..<10 {
                realm.create(SwiftCompanyObject.self, value: [[object]])
            }
            XCTAssertEqual(10, object.linkingObjects(SwiftCompanyObject.self, forProperty: "employees").count)
        }
        XCTAssertEqual(10, object.linkingObjects(SwiftCompanyObject.self, forProperty: "employees").count)
    }
}
