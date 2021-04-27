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

import Foundation
import Realm.Dynamic
import Realm.Private
import XCTest

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif

class SwiftRLMDynamicTests: RLMTestCase {

    // Swift models

    func testDynamicRealmExists() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(url: RLMTestRealmURL())
            realm.beginWriteTransaction()
            _ = SwiftRLMDynamicObject.create(in: realm, withValue: ["column1", 1])
            _ = SwiftRLMDynamicObject.create(in: realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }
        let dyrealm = realm(withTestPathAndSchema: nil)
        XCTAssertNotNil(dyrealm, "realm should not be nil")

        // verify schema
        let dynSchema = dyrealm.schema[SwiftRLMDynamicObject.className()]
        XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
        XCTAssertEqual(dynSchema.properties.count, Int(2))
        XCTAssertEqual(dynSchema.properties[0].name, "stringCol")
        XCTAssertEqual(dynSchema.properties[1].type, RLMPropertyType.int)

        // verify object type
        let array = SwiftRLMDynamicObject.allObjects(in: dyrealm)
        XCTAssertEqual(array.count, UInt(2))
        XCTAssertEqual(array.objectClassName, SwiftRLMDynamicObject.className())
    }

    func testDynamicProperties() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(url: RLMTestRealmURL())
            realm.beginWriteTransaction()
            _ = SwiftRLMDynamicObject.create(in: realm, withValue: ["column1", 1])
            _ = SwiftRLMDynamicObject.create(in: realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = realm(withTestPathAndSchema: nil)
        let array = dyrealm.allObjects("SwiftRLMDynamicObject")

        XCTAssertTrue(array[0]["intCol"] as! NSNumber == 1)
        XCTAssertTrue(array[1]["stringCol"] as! String == "column2")
    }

    // Objective-C models

    func testDynamicRealmExists_objc() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(url: RLMTestRealmURL())
            realm.beginWriteTransaction()
            _ = DynamicTestObject.create(in: realm, withValue: ["column1", 1])
            _ = DynamicTestObject.create(in: realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }
        let dyrealm = realm(withTestPathAndSchema: nil)
        XCTAssertNotNil(dyrealm, "realm should not be nil")

        // verify schema
        let dynSchema = dyrealm.schema[DynamicTestObject.className()]
        XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
        XCTAssertTrue(dynSchema.properties.count == 2)
        XCTAssertTrue(dynSchema.properties[0].name == "stringCol")
        XCTAssertTrue(dynSchema.properties[1].type == RLMPropertyType.int)

        // verify object type
        let array = DynamicTestObject.allObjects(in: dyrealm)
        XCTAssertEqual(array.count, UInt(2))
        XCTAssertEqual(array.objectClassName, DynamicTestObject.className())
    }

    func testDynamicProperties_objc() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(url: RLMTestRealmURL())
            realm.beginWriteTransaction()
            _ = DynamicTestObject.create(in: realm, withValue: ["column1", 1])
            _ = DynamicTestObject.create(in: realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = realm(withTestPathAndSchema: nil)
        let array = dyrealm.allObjects("DynamicTestObject")

        XCTAssertTrue(array[0]["intCol"] as! NSNumber == 1)
        XCTAssertTrue(array[1]["stringCol"] as! String == "column2")
    }

    func testDynamicTypes_objc() {
        let obj1 = AllTypesObject.values(1, stringObject: nil, mixedObject: nil)!
        let obj2 = AllTypesObject.values(2,
                                         stringObject: StringObject(value: ["string"]),
                                         mixedObject: MixedObject(value: ["string"]))!

        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            _ = AllTypesObject.create(in: realm, withValue: obj1)
            _ = AllTypesObject.create(in: realm, withValue: obj2)
            try! realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = realm(withTestPathAndSchema: nil)
        let results = dyrealm.allObjects(AllTypesObject.className())
        XCTAssertEqual(results.count, UInt(2))
        let robj1 = results[0]
        let robj2 = results[1]

        let schema = dyrealm.schema[AllTypesObject.className()]
        let props = schema.properties.filter { $0.type != .object }
        for prop in props {
            XCTAssertTrue((obj1[prop.name] as AnyObject).isEqual(robj1[prop.name]))
            XCTAssertTrue((obj2[prop.name] as AnyObject).isEqual(robj2[prop.name]))
        }

        // check sub object type
        XCTAssertTrue(schema.properties[12].objectClassName! == "StringObject")
        XCTAssertTrue(schema.properties[13].objectClassName! == "MixedObject")

        // check object equality
        XCTAssertNil(robj1["objectCol"], "object should be nil")
        XCTAssertNil(robj1["mixedObjectCol"], "object should be nil")
        XCTAssertTrue((robj2["objectCol"] as! RLMObject)["stringCol"] as! String == "string")
        XCTAssertTrue((robj2["mixedObjectCol"] as! RLMObject)["anyCol"] as! String == "string")
    }
}
