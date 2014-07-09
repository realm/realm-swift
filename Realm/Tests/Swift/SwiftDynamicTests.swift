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

class SwiftDynamicTests: RLMTestCase {
    
    func testDynamicRealmExists() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm.realmWithPath(RLMTestRealmPath(), readOnly: false, error: nil)
            realm.beginWriteTransaction()
            DynamicObject.createInRealm(realm, withObject: ["column1", 1])
            DynamicObject.createInRealm(realm, withObject: ["column2", 2])
            realm.commitWriteTransaction()
        }
        let dyrealm = self.dynamicRealmWithTestPathAndSchema(nil)
        XCTAssertNotNil(dyrealm, "realm should not be nil")
        XCTAssertTrue(dyrealm.isKindOfClass(RLMRealm.self), "realm should be of class RLMDynamicRealm")
        
        // verify schema
        let dynSchema = dyrealm.schema[DynamicObject.className()]
        XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
        XCTAssertEqual(dynSchema.properties.count, 2, "DynamicObject should have 2 properties")
        XCTAssertEqualObjects(dynSchema.properties[0].name, "stringCol", "Invalid property name")
        XCTAssertEqual((dynSchema.properties[1] as RLMProperty).type, RLMPropertyType.Int, "Invalid type")
        
        // verify object type
        let array = DynamicObject.allObjectsInRealm(dyrealm)
        XCTAssertEqual(array.count, 2, "Array should have 2 elements")
        XCTAssertEqualObjects(array.objectClassName, DynamicObject.className(), "Array class should by a dynamic object class")
    }
    
    func testDynamicProperties() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm.realmWithPath(RLMTestRealmPath(), readOnly: false, error: nil)
            realm.beginWriteTransaction()
            DynamicObject.createInRealm(realm, withObject: ["column1", 1])
            DynamicObject.createInRealm(realm, withObject: ["column2", 2])
            realm.commitWriteTransaction()
        }
        
        // verify properties
        let dyrealm = self.dynamicRealmWithTestPathAndSchema(nil)
        let array = DynamicObject.allObjectsInRealm(dyrealm)
        
        // FIXME: These should work
        // XCTAssertEqualObjects((array[0] as DynamicObject)["integer"] as NSNumber, 1, "First object should have column value 1")
        // XCTAssertEqualObjects(((array[1] as DynamicObject)["column"] as String), "column2", "Second object should have column value column2")
    }
    
    // FIXME: This test fails
//    func testDynamicTypes() {
//        let date = NSDate(timeIntervalSince1970: 100000)
//        let obj1 = [true, 1, 1.1, 1.11, "string", "a".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false), date, true, 11, 0, NSNull()]
//        
//        let obj = RLMTestObject()
//        obj.column = "column"
//        
//        let obj2 = [false, 2, 2.2, 2.22, "string2", "b".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false), date, false, 22, date, obj]
//        
//        autoreleasepool {
//            // open realm in autoreleasepool to create tables and then dispose
//            let realm = RLMRealm.realmWithPath(RLMTestRealmPath(), readOnly: false, error: nil)
//            realm.beginWriteTransaction()
//            AllTypesObject.createInRealm(realm, withObject: obj1)
//            AllTypesObject.createInRealm(realm, withObject: obj2)
//            realm.commitWriteTransaction()
//        }
//
//        // verify properties
//        let dyrealm = RLMRealm.realmWithPath(RLMTestRealmPath(), readOnly: false, dynamic: true, error: nil)
//        let array = dyrealm.allObjects(AllTypesObject.className())
//        XCTAssertEqual(array.count, 2, "Should have 2 objects")
//        
//        let schema = dyrealm.schema[AllTypesObject.className()]
//        for idx in 0..10 {
//            let propName = schema.properties[idx].name
//            XCTAssertEqualObjects(obj1[idx], (array[0] as AllTypesObject)[propName] as? NSObject, "Invalid property value")
//            XCTAssertEqualObjects(obj2[idx], (array[1] as AllTypesObject)[propName] as? NSObject, "Invalid property value")
//        }
//        
//        // check sub object type
//        XCTAssertEqualObjects((schema.properties[10]).objectClassName, "RLMTestObject", "Sub-object type in schema should be 'RLMTestObject'")
//        XCTAssertNil((array[0] as AllTypesObject)["objectCol"], "object should be nil")
//        XCTAssertEqualObjects(((array[1] as AllTypesObject)["objectCol"] as RLMTestObject)["column"] as? NSObject, "column", "Child object should have string value 'column'")
//    }
}
