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
import Realm
import TestFramework

class SwiftArrayPropertyTests: SwiftTestCase {

    // Swift models
    
    func testPopulateEmptyArray() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        let array = SwiftArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        XCTAssertNotNil(array.array, "Should be able to get an empty array")
        XCTAssertEqual(array.array.count, 0, "Should start with no array elements")
        
        let obj = SwiftStringObject()
        obj.stringCol = "a"
        array.array.addObject(obj)
        array.array.addObject(SwiftStringObject.createInRealm(realm, withObject: ["b"]))
        array.array.addObject(obj)
        realm.commitWriteTransaction()

        let subarray = RealmArray<SwiftStringObject>(rlmArray: array.array)
        
        XCTAssertEqual(array.array.count, 3, "Should have three elements in array")
        XCTAssertEqualObjects(subarray[0].stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects(subarray[1].stringCol, "b", "Second element should have property value 'b'")
        XCTAssertEqualObjects(subarray[2].stringCol, "a", "Third element should have property value 'a'")

        for obj in subarray {
            XCTAssertFalse(obj.description.isEmpty, "Object should have description")
        }
    }
    
    func testModifyDetatchedArray() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let arObj = SwiftArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        XCTAssertNotNil(arObj.array, "Should be able to get an empty array")
        XCTAssertEqual(arObj.array.count, 0, "Should start with no array elements")
        
        let obj = SwiftStringObject()
        obj.stringCol = "a"
        let array = RealmArray<SwiftStringObject>(rlmArray: arObj.array)
        array.addObject(obj)
        array.addObject(SwiftStringObject.createInRealm(realm, withObject: ["b"]))
        realm.commitWriteTransaction()
        
        XCTAssertEqual(array.count, 2, "Should have two elements in array")
        XCTAssertEqualObjects(array[0].stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects(array[1].stringCol, "b", "Second element should have property value 'b'")
    }

    func testInsertMultiple() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        
        let obj = SwiftArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        let child1 = SwiftStringObject.createInRealm(realm, withObject: ["a"])
        let child2 = SwiftStringObject()
        child2.stringCol = "b"
        obj.array.addObjectsFromArray([child2, child1])
        realm.commitWriteTransaction()
        
        let children = realm.objects(SwiftStringObject())
        XCTAssertEqualObjects(children[0].stringCol, "a", "First child should be 'a'")
        XCTAssertEqualObjects(children[1].stringCol, "b", "Second child should be 'b'")
    }

    // FIXME: Support standalone RealmArray's in Swift-defined models
//    func testStandalone() {
//        let realm = realmWithTestPath()
//        
//        let array = SwiftArrayPropertyObject()
//        array.name = "name"
//        XCTAssertNotNil(array.array, "RealmArray property should get created on access")
//        
//        let obj = SwiftStringObject()
//        obj.stringCol = "a"
//        array.array.addObject(obj)
//        array.array.addObject(obj)
//        
//        realm.beginWriteTransaction()
//        realm.addObject(array)
//        realm.commitWriteTransaction()
//        
//        XCTAssertEqual(array.array.count, 2, "Should have two elements in array")
//        XCTAssertEqualObjects((array.array[0] as SwiftStringObject).stringCol, "a", "First element should have property value 'a'")
//        XCTAssertEqualObjects((array.array[1] as SwiftStringObject).stringCol, "a", "Second element should have property value 'a'")
//    }

    // Objective-C models

    func testPopulateEmptyArray_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let array = ArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        XCTAssertNotNil(array.array, "Should be able to get an empty array")
        XCTAssertEqual(array.array.count, 0, "Should start with no array elements")

        let obj = StringObject()
        obj.stringCol = "a"
        array.array.addObject(obj)
        array.array.addObject(StringObject.createInRealm(realm, withObject: ["b"]))
        array.array.addObject(obj)
        realm.commitWriteTransaction()

        let subarray = RealmArray<StringObject>(rlmArray: array.array)

        XCTAssertEqual(array.array.count, 3, "Should have three elements in array")
        XCTAssertEqualObjects(subarray[0].stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects(subarray[1].stringCol, "b", "Second element should have property value 'b'")
        XCTAssertEqualObjects(subarray[2].stringCol, "a", "Third element should have property value 'a'")

        for obj in subarray {
            XCTAssertFalse(obj.description.isEmpty, "Object should have description")
        }
    }

    func testModifyDetatchedArray_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let arObj = ArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        XCTAssertNotNil(arObj.array, "Should be able to get an empty array")
        XCTAssertEqual(arObj.array.count, 0, "Should start with no array elements")

        let obj = StringObject()
        obj.stringCol = "a"
        let array = RealmArray<StringObject>(rlmArray: arObj.array)
        array.addObject(obj)
        array.addObject(StringObject.createInRealm(realm, withObject: ["b"]))
        realm.commitWriteTransaction()

        XCTAssertEqual(array.count, 2, "Should have two elements in array")
        XCTAssertEqualObjects(array[0].stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects(array[1].stringCol, "b", "Second element should have property value 'b'")
    }

    func testInsertMultiple_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let obj = ArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        let child1 = StringObject.createInRealm(realm, withObject: ["a"])
        let child2 = StringObject()
        child2.stringCol = "b"
        obj.array.addObjectsFromArray([child2, child1])
        realm.commitWriteTransaction()

        let children = realm.objects(StringObject())
        XCTAssertEqualObjects(children[0].stringCol, "a", "First child should be 'a'")
        XCTAssertEqualObjects(children[1].stringCol, "b", "Second child should be 'b'")
    }

    func testStandalone_objc() {
        let realm = realmWithTestPath()

        let array = ArrayPropertyObject()
        array.name = "name"
        XCTAssertNotNil(array.array, "RealmArray property should get created on access")

        let obj = StringObject()
        obj.stringCol = "a"
        array.array.addObject(obj)
        array.array.addObject(obj)

        realm.beginWriteTransaction()
        realm.addObject(array)
        realm.commitWriteTransaction()

        let subarray = RealmArray<StringObject>(rlmArray: array.array)

        XCTAssertEqual(subarray.count, 2, "Should have two elements in array")
        XCTAssertEqualObjects(subarray[0].stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqualObjects(subarray[1].stringCol, "a", "Second element should have property value 'a'")
    }
}
