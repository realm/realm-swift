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

import XCTest
import TestFramework

class SwiftDynamicTests: SwiftTestCase {

    // Swift models

    func testDynamicRealmExists() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm.realmWithPath(testRealmPath(), readOnly: false, error: nil)
            realm.beginWriteTransaction()
            SwiftDynamicObject.createInRealm(realm, withObject: ["column1", 1])
            SwiftDynamicObject.createInRealm(realm, withObject: ["column2", 2])
            realm.commitWriteTransaction()
        }
        let dyrealm = dynamicRealmWithTestPathAndSchema(nil)
        XCTAssertNotNil(dyrealm, "realm should not be nil")
        XCTAssertTrue(dyrealm.isKindOfClass(RLMRealm.self), "realm should be of class RLMDynamicRealm")

        // verify schema
        let dynSchema = dyrealm.schema[SwiftDynamicObject.className()]
        XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
        XCTAssertEqual(dynSchema.properties.count, 2, "SwiftDynamicObject should have 2 properties")
        XCTAssertEqual(dynSchema.properties[0].name!!, "stringCol", "Invalid property name")
        XCTAssertEqual((dynSchema.properties[1] as RLMProperty).type, RLMPropertyType.Int, "Invalid type")

        // verify object type
        let array = SwiftDynamicObject.allObjectsInRealm(dyrealm)
        XCTAssertEqual(array.count, 2, "Array should have 2 elements")
        XCTAssertEqual(array.objectClassName!, SwiftDynamicObject.className()!, "Array class should by a dynamic object class")
    }

    func testDynamicProperties() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm.realmWithPath(testRealmPath(), readOnly: false, error: nil)
            realm.beginWriteTransaction()
            SwiftDynamicObject.createInRealm(realm, withObject: ["column1", 1])
            SwiftDynamicObject.createInRealm(realm, withObject: ["column2", 2])
            realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = dynamicRealmWithTestPathAndSchema(nil)
        let array = dyrealm.allObjects("SwiftDynamicObject")

        XCTAssertEqual((array[0] as RLMObject)["intCol"] as NSNumber, 1, "First object should have column value 1")
        XCTAssertEqual((array[1] as RLMObject)["stringCol"] as String, "column2", "Second object should have column value column2")
    }

    // FIXME: Uncomment once Swift-defined models support RLMPropertyTypeAny
//    func testDynamicTypes() {
//        let date = NSDate(timeIntervalSince1970: 100000)
//        let obj1 = [true, 1, 1.1 as Float, 1.11, "string", "a".dataUsingEncoding(NSUTF8StringEncoding), date, true, 11, 0, NSNull()]
//
//        let obj = StringObject()
//        obj.stringCol = "string"
//
//        let obj2 = [false, 2, 2.2 as Float, 2.22, "string2", "b".dataUsingEncoding(NSUTF8StringEncoding), date, false, 22, date, obj]
//
//        autoreleasepool {
//            // open realm in autoreleasepool to create tables and then dispose
//            let realm = self.realmWithTestPath()
//            realm.beginWriteTransaction()
//            SwiftAllTypesObject.createInRealm(realm, withObject: obj1)
//            SwiftAllTypesObject.createInRealm(realm, withObject: obj2)
//            realm.commitWriteTransaction()
//        }
//
//        // verify properties
//        let dyrealm = dynamicRealmWithTestPathAndSchema(nil)
//        let array = dyrealm.allObjects(SwiftAllTypesObject.className())
//        XCTAssertEqual(array.count, 2, "Should have 2 objects")
//
//        let schema = dyrealm.schema[SwiftAllTypesObject.className()]
//        for idx in 0..<10 {
//            let propName = schema.properties[idx].name
//            XCTAssertEqual(obj1[idx], (array[0] as RLMObject)[propName] as? NSObject, "Invalid property value")
//            XCTAssertEqual(obj2[idx], (array[1] as RLMObject)[propName] as? NSObject, "Invalid property value")
//        }
//
//        // check sub object type
//        XCTAssertEqual((schema.properties[10] as RLMProperty).objectClassName, "StringObject", "Sub-object type in schema should be 'StringObject'")
//
//        // check object equality
//        XCTAssertNil((array[0] as RLMObject)["objectCol"], "object should be nil")
//        XCTAssertEqual(((array[1] as RLMObject)["objectCol"] as RLMObject)["stringCol"] as? NSObject, "string", "Child object should have string value 'column'")
//    }

    // Objective-C models

    func testDynamicRealmExists_objc() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm.realmWithPath(testRealmPath(), readOnly: false, error: nil)
            realm.beginWriteTransaction()
            DynamicObject.createInRealm(realm, withObject: ["column1", 1])
            DynamicObject.createInRealm(realm, withObject: ["column2", 2])
            realm.commitWriteTransaction()
        }
        let dyrealm = dynamicRealmWithTestPathAndSchema(nil)
        XCTAssertNotNil(dyrealm, "realm should not be nil")
        XCTAssertTrue(dyrealm.isKindOfClass(RLMRealm.self), "realm should be of class RLMDynamicRealm")

        // verify schema
        let dynSchema = dyrealm.schema[DynamicObject.className()]
        XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
        XCTAssertEqual(dynSchema.properties.count, 2, "DynamicObject should have 2 properties")
        XCTAssertEqual(dynSchema.properties[0].name!!, "stringCol", "Invalid property name")
        XCTAssertEqual((dynSchema.properties[1] as RLMProperty).type, RLMPropertyType.Int, "Invalid type")

        // verify object type
        let array = DynamicObject.allObjectsInRealm(dyrealm)
        XCTAssertEqual(array.count, 2, "Array should have 2 elements")
        XCTAssertEqual(array.objectClassName!, DynamicObject.className()!, "Array class should by a dynamic object class")
    }

    func testDynamicProperties_objc() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm.realmWithPath(testRealmPath(), readOnly: false, error: nil)
            realm.beginWriteTransaction()
            DynamicObject.createInRealm(realm, withObject: ["column1", 1])
            DynamicObject.createInRealm(realm, withObject: ["column2", 2])
            realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = dynamicRealmWithTestPathAndSchema(nil)
        let array = dyrealm.allObjects("DynamicObject")

        XCTAssertEqual((array[0] as RLMObject)["intCol"] as NSNumber, 1, "First object should have column value 1")
        XCTAssertEqual((array[1] as RLMObject)["stringCol"] as String, "column2", "Second object should have column value column2")
    }

    func testDynamicTypes_objc() {
        let date = NSDate(timeIntervalSince1970: 100000)
        let obj1 = [true, 1, 1.1 as Float, 1.11, "string", "a".dataUsingEncoding(NSUTF8StringEncoding), date, true, 11, 0, NSNull()] as NSArray

        let obj = StringObject()
        obj.stringCol = "string"

        let obj2 = [false, 2, 2.2 as Float, 2.22, "string2", "b".dataUsingEncoding(NSUTF8StringEncoding), date, false, 22, date, obj] as NSArray

        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            AllTypesObject.createInRealm(realm, withObject: obj1)
            AllTypesObject.createInRealm(realm, withObject: obj2)
            realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = dynamicRealmWithTestPathAndSchema(nil)
        let array = dyrealm.allObjects(AllTypesObject.className())
        XCTAssertEqual(array.count, 2, "Should have 2 objects")

        let schema = dyrealm.schema[AllTypesObject.className()]
        for idx in 0..<10 {
            let propName = schema.properties[idx].name
            XCTAssertTrue(obj1[idx].isEqual((array[0] as RLMObject)[propName]), "Invalid property value")
            XCTAssertTrue(obj2[idx].isEqual((array[1] as RLMObject)[propName]), "Invalid property value")
        }

        // check sub object type
        XCTAssertEqual((schema.properties[10] as RLMProperty).objectClassName!, "StringObject", "Sub-object type in schema should be 'StringObject'")

        // check object equality
        XCTAssertNil((array[0] as RLMObject)["objectCol"], "object should be nil")
        XCTAssertEqual(((array[1] as RLMObject)["objectCol"] as RLMObject)["stringCol"] as String, "string", "Child object should have string value 'column'")
    }
}
