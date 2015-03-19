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
        let standalone = StringObject()
        XCTAssertNil(standalone.realm)

        let realm = Realm()
        var persisted: StringObject!
        realm.write {
            persisted = realm.create(StringObject.self, value: [:])
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
        let object = AllTypesObject()
        let schema = object.objectSchema
        XCTAssert(schema as AnyObject is ObjectSchema)
        XCTAssert(schema.properties as AnyObject is [Property])
        XCTAssertEqual(schema.className, "AllTypesObject")
        XCTAssertEqual(schema.properties.map { $0.name }, ["boolCol", "intCol", "floatCol", "doubleCol", "stringCol", "binaryCol", "dateCol", "objectCol", "arrayCol"])
    }

    func testInvalidated() {
        let object = AllTypesObject()
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

    func testDescription() {
        let object = AllTypesObject()
        let regex = NSRegularExpression(pattern: "RLMArray <0x[a-z0-9]+>", options: nil, error: nil)
        let rawDescription = object.description
        let description = regex!.stringByReplacingMatchesInString(rawDescription, options: nil, range: NSRange(location: 0, length: countElements(rawDescription)), withTemplate: "RLMArray <0x0>")
        XCTAssertEqual(description, "AllTypesObject {\n\tboolCol = 0;\n\tintCol = 123;\n\tfloatCol = 1.23;\n\tdoubleCol = 12.3;\n\tstringCol = a;\n\tbinaryCol = <61 — 1 total bytes>;\n\tdateCol = 1970-01-01 00:00:01 +0000;\n\tobjectCol = BoolObject {\n\t\tboolCol = 0;\n\t};\n\tarrayCol = RLMArray <0x0> (\n\t\n\t);\n}")
    }

    func testPrimaryKey() {
        XCTAssertNil(Object.primaryKey(), "primary key should default to nil")
        XCTAssertNil(StringObject.primaryKey())
        XCTAssertNil(StringObject().objectSchema.primaryKeyProperty)
        XCTAssertEqual(PrimaryStringObject.primaryKey(), "stringCol")
        XCTAssertEqual(PrimaryStringObject().objectSchema.primaryKeyProperty!.name, "stringCol")
    }

    func testIgnoredProperties() {
        XCTAssertEqual(Object.ignoredProperties(), [], "ignored properties should default to []")
        XCTAssertEqual(IgnoredPropertiesObject.ignoredProperties().count, 2)
        XCTAssertNil(IgnoredPropertiesObject().objectSchema["runtimeProperty"])
    }

    func testIndexedProperties() {
        XCTAssertEqual(Object.indexedProperties(), [], "indexed properties should default to []")
        XCTAssertEqual(IndexedPropertiesObject.indexedProperties().count, 1)
        XCTAssertTrue(IndexedPropertiesObject().objectSchema["stringCol"]!.indexed)
    }

    func testLinkingObjects() {
        let realm = Realm()
        let object = EmployeeObject()
        assertThrows(object.linkingObjects(CompanyObject.self, forProperty: "employees"))
        realm.write {
            realm.add(object)
            self.assertThrows(object.linkingObjects(CompanyObject.self, forProperty: "noSuchCol"))
            XCTAssertEqual(0, object.linkingObjects(CompanyObject.self, forProperty: "employees").count)
            for _ in 0..<10 {
                realm.create(CompanyObject.self, value: [[object]])
            }
            XCTAssertEqual(10, object.linkingObjects(CompanyObject.self, forProperty: "employees").count)
        }
        XCTAssertEqual(10, object.linkingObjects(CompanyObject.self, forProperty: "employees").count)
    }

    func testValueForKey() {
        let test: (AllTypesObject) -> () = { object in
            XCTAssertEqual(object.valueForKey("boolCol") as Bool!, false)
            XCTAssertEqual(object.valueForKey("intCol") as Int!, 123)
            XCTAssertEqual(object.valueForKey("floatCol") as Float!, 1.23 as Float)
            XCTAssertEqual(object.valueForKey("doubleCol") as Double!, 12.3)
            XCTAssertEqual(object.valueForKey("stringCol") as String!, "a")
            XCTAssertEqual(object.valueForKey("binaryCol") as NSData, "a".dataUsingEncoding(NSUTF8StringEncoding)! as NSData)
            XCTAssertEqual(object.valueForKey("dateCol") as NSDate!, NSDate(timeIntervalSince1970: 1))
            XCTAssertEqual((object.valueForKey("objectCol")! as BoolObject).boolCol, false)
            XCTAssert(object.valueForKey("arrayCol")! is List<BoolObject>)
        }

        test(AllTypesObject())
        Realm().write {
            let persistedObject = Realm().create(AllTypesObject.self, value: [:])
            test(persistedObject)
        }
    }

    func testSetValueForKey() {
        let test: (AllTypesObject) -> () = { object in
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

            let boolObject = BoolObject(value: [true])
            object.setValue(boolObject, forKey: "objectCol")
            XCTAssertEqual(object.valueForKey("objectCol") as BoolObject, boolObject)
            XCTAssertEqual((object.valueForKey("objectCol")! as BoolObject).boolCol, true)

            let list = List<BoolObject>()
            list.append(boolObject)
            object.setValue(list, forKey: "arrayCol")
            XCTAssertEqual((object.valueForKey("arrayCol") as List<BoolObject>).count, 1)
            XCTAssertEqual((object.valueForKey("arrayCol") as List<BoolObject>).first!, boolObject)
        }

        test(AllTypesObject())
        Realm().write {
            let persistedObject = Realm().create(AllTypesObject.self, value: [:])
            test(persistedObject)
        }
    }

    func testSubscript() {

    }
}
