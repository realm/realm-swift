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

class SwiftArrayPropertyTests: RLMTestCase {
    
    func testPopulateEmptyArray() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        let array = ArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []]);
        XCTAssertNotNil(array.array, "Should be able to get an empty array")
        XCTAssertEqual(array.array.count, 0, "Should start with no array elements")
        
        let obj = StringObject()
        obj.stringCol = "a"
        array.array.addObject(obj)
        array.array.addObject(StringObject.createInRealm(realm, withObject: ["b"]))
        array.array.addObject(obj)
        realm.commitWriteTransaction()
        
        XCTAssertEqual(array.array.count, 3, "Should have three elements in array")
        XCTAssertEqualObjects((array.array[0] as StringObject).stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects((array.array[1] as StringObject).stringCol, "b", "Second element should have property value 'b'")
        XCTAssertEqualObjects((array.array[2] as StringObject).stringCol, "a", "Third element should have property value 'a'")

        for idx in 0..<array.array.count {
            if let obj = array.array[idx] as? StringObject {
                XCTAssertFalse(obj.description.isEmpty, "Object should have description")
            }
        }
    }
    
    func testModifyDetatchedArray() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let arObj = ArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        XCTAssertNotNil(arObj.array, "Should be able to get an empty array")
        XCTAssertEqual(arObj.array.count, 0, "Should start with no array elements")
        
        let obj = StringObject()
        obj.stringCol = "a"
        let array = arObj.array
        array.addObject(obj)
        array.addObject(StringObject.createInRealm(realm, withObject: ["b"]))
        realm.commitWriteTransaction()
        
        XCTAssertEqual(array.count, 2, "Should have two elements in array")
        XCTAssertEqualObjects((array[0] as StringObject).stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects((array[1] as StringObject).stringCol, "b", "Second element should have property value 'b'")
    }

    func testInsertMultiple() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        
        let obj = ArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        let child1 = StringObject.createInRealm(realm, withObject: ["a"])
        let child2 = StringObject()
        child2.stringCol = "b"
        obj.array.addObjectsFromArray([child2, child1])
        realm.commitWriteTransaction()
        
        let children = StringObject.allObjectsInRealm(realm)
        XCTAssertEqualObjects((children[0] as StringObject).stringCol, "a", "First child should be 'a'")
        XCTAssertEqualObjects((children[1] as StringObject).stringCol, "b", "Second child should be 'b'")
    }

    func testStandalone() {
        let realm = realmWithTestPath()
        
        let array = ArrayPropertyObject()
        array.name = "name"
        XCTAssertNotNil(array.array, "RLMArray property should get created on access")
        
        let obj = StringObject()
        obj.stringCol = "a"
        array.array.addObject(obj)
        array.array.addObject(obj)
        
        realm.beginWriteTransaction()
        realm.addObject(array)
        realm.commitWriteTransaction()
        
        XCTAssertEqual(array.array.count, 2, "Should have two elements in array")
        XCTAssertEqualObjects((array.array[0] as StringObject).stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects((array.array[1] as StringObject).stringCol, "a", "Second element should have property value 'a'")
    }
}
