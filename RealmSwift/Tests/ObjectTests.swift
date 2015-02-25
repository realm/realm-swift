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
