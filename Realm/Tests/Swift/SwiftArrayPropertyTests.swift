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

class SwiftArrayPropertyTests: RLMTestCase {

    // Swift models

    func testBasicArray() {
        let string = SwiftStringObject()
        string.stringCol = "string"

        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        realm.addObject(string)
        try! realm.commitWriteTransaction()

        XCTAssertEqual(SwiftStringObject.allObjectsInRealm(realm).count, UInt(1), "There should be a single SwiftStringObject in the realm")

        let array = SwiftArrayPropertyObject()
        array.name = "arrayObject"
        array.array.addObject(string)
        XCTAssertEqual(array.array.count, UInt(1))
        XCTAssertEqual((array.array.firstObject() as! SwiftStringObject).stringCol, "string")

        realm.beginWriteTransaction()
        realm.addObject(array)
        array.array.addObject(string)
        try! realm.commitWriteTransaction()

        let arrayObjects = SwiftArrayPropertyObject.allObjectsInRealm(realm)

        XCTAssertEqual(arrayObjects.count, UInt(1), "There should be a single SwiftStringObject in the realm")
        let cmp = (arrayObjects.firstObject() as! SwiftArrayPropertyObject).array.firstObject() as! SwiftStringObject
        XCTAssertTrue(string.isEqualToObject(cmp), "First array object should be the string object we added")
    }

    func testPopulateEmptyArray() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let array = SwiftArrayPropertyObject.createInRealm(realm, withValue: ["arrayObject", [], []]);
        XCTAssertNotNil(array.array, "Should be able to get an empty array")
        XCTAssertEqual(array.array.count, UInt(0), "Should start with no array elements")

        let obj = SwiftStringObject()
        obj.stringCol = "a"
        array.array.addObject(obj)
        array.array.addObject(SwiftStringObject.createInRealm(realm, withValue: ["b"]))
        array.array.addObject(obj)
        try! realm.commitWriteTransaction()

        XCTAssertEqual(array.array.count, UInt(3), "Should have three elements in array")
        XCTAssertEqual((array.array[0] as! SwiftStringObject).stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqual((array.array[1] as! SwiftStringObject).stringCol, "b", "Second element should have property value 'b'")
        XCTAssertEqual((array.array[2] as! SwiftStringObject).stringCol, "a", "Third element should have property value 'a'")

        for obj in array.array {
            XCTAssertFalse(obj.description.isEmpty, "Object should have description")
        }
    }

    func testModifyDetatchedArray() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let arObj = SwiftArrayPropertyObject.createInRealm(realm, withValue: ["arrayObject", [], []])
        XCTAssertNotNil(arObj.array, "Should be able to get an empty array")
        XCTAssertEqual(arObj.array.count, UInt(0), "Should start with no array elements")

        let obj = SwiftStringObject()
        obj.stringCol = "a"
        let array = arObj.array
        array.addObject(obj)
        array.addObject(SwiftStringObject.createInRealm(realm, withValue: ["b"]))
        try! realm.commitWriteTransaction()

        XCTAssertEqual(array.count, UInt(2), "Should have two elements in array")
        XCTAssertEqual((array[0] as! SwiftStringObject).stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqual((array[1] as! SwiftStringObject).stringCol, "b", "Second element should have property value 'b'")
    }

    func testInsertMultiple() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let obj = SwiftArrayPropertyObject.createInRealm(realm, withValue: ["arrayObject", [], []])
        let child1 = SwiftStringObject.createInRealm(realm, withValue: ["a"])
        let child2 = SwiftStringObject()
        child2.stringCol = "b"
        obj.array.addObjects([child2, child1])
        try! realm.commitWriteTransaction()

        let children = SwiftStringObject.allObjectsInRealm(realm)
        XCTAssertEqual((children[0] as! SwiftStringObject).stringCol, "a", "First child should be 'a'")
        XCTAssertEqual((children[1] as! SwiftStringObject).stringCol, "b", "Second child should be 'b'")
    }

    // FIXME: Support standalone RLMArray's in Swift-defined models
    //    func testStandalone() {
    //        let realm = realmWithTestPath()
    //
    //        let array = SwiftArrayPropertyObject()
    //        array.name = "name"
    //        XCTAssertNotNil(array.array, "RLMArray property should get created on access")
    //
    //        let obj = SwiftStringObject()
    //        obj.stringCol = "a"
    //        array.array.addObject(obj)
    //        array.array.addObject(obj)
    //
    //        realm.beginWriteTransaction()
    //        realm.addObject(array)
    //        try! realm.commitWriteTransaction()
    //
    //        XCTAssertEqual(array.array.count, UInt(2), "Should have two elements in array")
    //        XCTAssertEqual((array.array[0] as SwiftStringObject).stringCol, "a", "First element should have property value 'a'")
    //        XCTAssertEqual((array.array[1] as SwiftStringObject).stringCol, "a", "Second element should have property value 'a'")
    //    }

    // Objective-C models

    func testBasicArray_objc() {
        let string = StringObject()
        string.stringCol = "string"

        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        realm.addObject(string)
        try! realm.commitWriteTransaction()

        XCTAssertEqual(StringObject.allObjectsInRealm(realm).count, UInt(1), "There should be a single StringObject in the realm")

        let array = ArrayPropertyObject()
        array.name = "arrayObject"
        array.array.addObject(string)

        realm.beginWriteTransaction()
        realm.addObject(array)
        try! realm.commitWriteTransaction()

        let arrayObjects = ArrayPropertyObject.allObjectsInRealm(realm)

        XCTAssertEqual(arrayObjects.count, UInt(1), "There should be a single StringObject in the realm")
        let cmp = (arrayObjects.firstObject() as! ArrayPropertyObject).array.firstObject() as! StringObject
        XCTAssertTrue(string.isEqualToObject(cmp), "First array object should be the string object we added")
    }

    func testPopulateEmptyArray_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let array = ArrayPropertyObject.createInRealm(realm, withValue: ["arrayObject", [], []]);
        XCTAssertNotNil(array.array, "Should be able to get an empty array")
        XCTAssertEqual(array.array.count, UInt(0), "Should start with no array elements")

        let obj = StringObject()
        obj.stringCol = "a"
        array.array.addObject(obj)
        array.array.addObject(StringObject.createInRealm(realm, withValue: ["b"]))
        array.array.addObject(obj)
        try! realm.commitWriteTransaction()

        XCTAssertEqual(array.array.count, UInt(3), "Should have three elements in array")
        XCTAssertEqual((array.array[0] as! StringObject).stringCol!, "a", "First element should have property value 'a'")
        XCTAssertEqual((array.array[1] as! StringObject).stringCol!, "b", "Second element should have property value 'b'")
        XCTAssertEqual((array.array[2] as! StringObject).stringCol!, "a", "Third element should have property value 'a'")

        for idx in 0..<array.array.count {
            if let obj = array.array[idx] as? StringObject {
                XCTAssertFalse(obj.description.isEmpty, "Object should have description")
            }
        }
    }

    func testModifyDetatchedArray_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let arObj = ArrayPropertyObject.createInRealm(realm, withValue: ["arrayObject", [], []])
        XCTAssertNotNil(arObj.array, "Should be able to get an empty array")
        XCTAssertEqual(arObj.array.count, UInt(0), "Should start with no array elements")

        let obj = StringObject()
        obj.stringCol = "a"
        let array = arObj.array
        array.addObject(obj)
        array.addObject(StringObject.createInRealm(realm, withValue: ["b"]))
        try! realm.commitWriteTransaction()

        XCTAssertEqual(array.count, UInt(2), "Should have two elements in array")
        XCTAssertEqual((array[0] as! StringObject).stringCol!, "a", "First element should have property value 'a'")
        XCTAssertEqual((array[1] as! StringObject).stringCol!, "b", "Second element should have property value 'b'")
    }

    func testInsertMultiple_objc() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()

        let obj = ArrayPropertyObject.createInRealm(realm, withValue: ["arrayObject", [], []])
        let child1 = StringObject.createInRealm(realm, withValue: ["a"])
        let child2 = StringObject()
        child2.stringCol = "b"
        obj.array.addObjects([child2, child1])
        try! realm.commitWriteTransaction()

        let children = StringObject.allObjectsInRealm(realm)
        XCTAssertEqual((children[0] as! StringObject).stringCol!, "a", "First child should be 'a'")
        XCTAssertEqual((children[1] as! StringObject).stringCol!, "b", "Second child should be 'b'")
    }

    func testStandalone_objc() {
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
        try! realm.commitWriteTransaction()

        XCTAssertEqual(array.array.count, UInt(2), "Should have two elements in array")
        XCTAssertEqual((array.array[0] as! StringObject).stringCol!, "a", "First element should have property value 'a'")
        XCTAssertEqual((array.array[1] as! StringObject).stringCol!, "a", "Second element should have property value 'a'")
    }
}
