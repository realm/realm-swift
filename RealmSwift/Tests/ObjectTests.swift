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

    // init() Tests are in ObjectCreationTests.swift

    // init(value:) tests are in ObjectCreationTests.swift
    
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

        let queue = dispatch_queue_create("background", DISPATCH_QUEUE_SERIAL)
        dispatch_async(queue) {
            XCTAssertNotEqual(Realm(), persisted.realm!)
        }
        dispatch_sync(queue, {})
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
        XCTAssertEqual(SwiftIndexedPropertiesObject.indexedProperties().count, 1)
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["stringCol"]!.indexed)
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

    func testValueForKey() {
        let test: (SwiftObject) -> () = { object in
            XCTAssertEqual(object.valueForKey("boolCol") as Bool!, false)
            XCTAssertEqual(object.valueForKey("intCol") as Int!, 123)
            XCTAssertEqual(object.valueForKey("floatCol") as Float!, 1.23 as Float)
            XCTAssertEqual(object.valueForKey("doubleCol") as Double!, 12.3)
            XCTAssertEqual(object.valueForKey("stringCol") as String!, "a")
            XCTAssertEqual(object.valueForKey("binaryCol") as NSData, "a".dataUsingEncoding(NSUTF8StringEncoding)! as NSData)
            XCTAssertEqual(object.valueForKey("dateCol") as NSDate!, NSDate(timeIntervalSince1970: 1))
            XCTAssertEqual((object.valueForKey("objectCol")! as SwiftBoolObject).boolCol, false)
            XCTAssert(object.valueForKey("arrayCol")! is List<SwiftBoolObject>)
        }

        test(SwiftObject())
        Realm().write {
            let persistedObject = Realm().create(SwiftObject.self, value: [:])
            test(persistedObject)
        }
    }

    func testSetValueForKey() {
        let test: (SwiftObject) -> () = { object in
            object.setValue(true, forKey: "boolCol")
            XCTAssertEqual(object.valueForKey("boolCol") as Bool!, true)

            object.setValue(321, forKey: "intCol")
            XCTAssertEqual(object.valueForKey("intCol") as Int!, 321)

            object.setValue(32.1 as Float, forKey: "floatCol")
            XCTAssertEqual(object.valueForKey("floatCol") as Float!, 32.1 as Float)

            object.setValue(3.21, forKey: "doubleCol")
            XCTAssertEqual(object.valueForKey("doubleCol") as Double!, 3.21)

            object.setValue("z", forKey: "stringCol")
            XCTAssertEqual(object.valueForKey("stringCol") as String!, "z")

            object.setValue("z".dataUsingEncoding(NSUTF8StringEncoding), forKey: "binaryCol")
            XCTAssertEqual(object.valueForKey("binaryCol") as NSData, "z".dataUsingEncoding(NSUTF8StringEncoding)! as NSData)

            object.setValue(NSDate(timeIntervalSince1970: 333), forKey: "dateCol")
            XCTAssertEqual(object.valueForKey("dateCol") as NSDate!, NSDate(timeIntervalSince1970: 333))

            let boolObject = SwiftBoolObject(object: [true])
            object.setValue(boolObject, forKey: "objectCol")
            XCTAssertEqual(object.valueForKey("objectCol") as SwiftBoolObject, boolObject)
            XCTAssertEqual((object.valueForKey("objectCol")! as SwiftBoolObject).boolCol, true)

            let list = List<SwiftBoolObject>()
            list.append(boolObject)
            object.setValue(list, forKey: "arrayCol")
            XCTAssertEqual((object.valueForKey("arrayCol") as List<SwiftBoolObject>).count, 1)
            XCTAssertEqual((object.valueForKey("arrayCol") as List<SwiftBoolObject>).first!, boolObject)
        }

        test(SwiftObject())
        Realm().write {
            let persistedObject = Realm().create(SwiftObject.self, value: [:])
            test(persistedObject)
        }
    }
}
