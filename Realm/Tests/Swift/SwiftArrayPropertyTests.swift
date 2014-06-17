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

class SwiftArrayPropertyTests: RLMTestCase {
    
    func testPopulateEmptyArray() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        let array = ArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", []]);
        XCTAssertNotNil(array.array, "Should be able to get an empty array")
        XCTAssertEqual(array.array.count, 0, "Should start with no array elements")
        
        let obj = RLMTestObject()
        obj.column = "a"
        array.array.addObject(obj)
        array.array.addObject(RLMTestObject.createInRealm(realm, withObject: ["b"]))
        array.array.addObject(obj)
        realm.commitWriteTransaction()
        
        XCTAssertEqual(array.array.count, 3, "Should have three elements in array")
        XCTAssertEqualObjects((array.array[0] as RLMTestObject).column, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects((array.array[1] as RLMTestObject).column, "b", "Second element should have property value 'b'")
        XCTAssertEqualObjects((array.array[2] as RLMTestObject).column, "a", "Third element should have property value 'a'")
        
        // Index-based enumeration
        for idx in 0..array.array.count {
            let obj = array.array[idx] as RLMTestObject
            XCTAssertFalse(obj.description.isEmpty, "Object should have description")
        }
        
        // FIXME: Can't enumerate
//        // make sure we can fast enumerate
//        for obj in array.array {
//            XCTAssertTrue(obj.description.length > 0, "Object should have description")
//        }
//        for (index, obj) in enumerate(array.array) {
//            XCTAssertTrue(obj.description.length > 0, "Object should have description")
//        }
    }
    
    func testModifyDetatchedArray() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let arObj = ArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", []])
        XCTAssertNotNil(arObj.array, "Should be able to get an empty array")
        XCTAssertEqual(arObj.array.count, 0, "Should start with no array elements")
        
        let obj = RLMTestObject()
        obj.column = "a"
        let array = arObj.array
        array.addObject(obj)
        array.addObject(RLMTestObject.createInRealm(realm, withObject: ["b"]))
        realm.commitWriteTransaction()
        
        XCTAssertEqual(array.count, 2, "Should have two elements in array")
        XCTAssertEqualObjects((array[0] as RLMTestObject).column, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects((array[1] as RLMTestObject).column, "b", "Second element should have property value 'b'")
    }
    
    func testInsertMultiple() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        
        let obj = ArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", []])
        let child1 = RLMTestObject.createInRealm(realm, withObject: ["a"])
        let child2 = RLMTestObject()
        child2.column = "b"
        obj.array.addObjectsFromArray([child2, child1])
        realm.commitWriteTransaction()
        
        let children = realm.allObjects(RLMTestObject.className())
        XCTAssertEqualObjects((children[0] as RLMTestObject).column, "a", "First child should be 'a'")
        XCTAssertEqualObjects((children[1] as RLMTestObject).column, "b", "Second child should be 'b'")
    }
    
    func testStandalone() {
        let realm = realmWithTestPath()
        
        let array = ArrayPropertyObject()
        array.name = "name"
        XCTAssertNotNil(array.array, "RLMArray property should get created on access")
        
        let obj = RLMTestObject()
        obj.column = "a"
        array.array.addObject(obj)
        array.array.addObject(obj)
        
        realm.beginWriteTransaction()
        realm.addObject(array)
        realm.commitWriteTransaction()
        
        XCTAssertEqual(array.array.count, 2, "Should have two elements in array")
        XCTAssertEqualObjects((array.array[0] as RLMTestObject).column, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects((array.array[1] as RLMTestObject).column, "a", "Second element should have property value 'a'")
    }
}
