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
import RealmSwift

class SwiftArrayPropertyTests: SwiftTestCase {

    func testBasicArray() {
        let string = SwiftStringObject()
        string.stringCol = "string"

        let realm = realmWithTestPath()
        realm.write { realm.add(string) }

        XCTAssertEqual(realm.objects(SwiftStringObject).count, 1, "There should be a single SwiftStringObject in the realm")

        let array = SwiftArrayPropertyObject()
        array.name = "arrayObject"
        array.array.addObject(string)
        XCTAssertEqual(array.array.count, 1)
        XCTAssertEqual((array.array.firstObject() as SwiftStringObject).stringCol, "string")

        realm.beginWrite()
        realm.add(array)
        array.array.addObject(string)
        realm.commitWrite()

        let arrayObjects = realm.objects(SwiftArrayPropertyObject)

        XCTAssertEqual(arrayObjects.count, 1, "There should be a single SwiftStringObject in the realm")
        var cmp = arrayObjects.first()!.array.list(SwiftStringObject).first()!
        XCTAssertEqual(string, cmp, "First array object should be the string object we added")
    }

    func testPopulateEmptyArray() {
        let realm = realmWithTestPath()

        realm.beginWrite()
        let array = SwiftArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        let subarray = array.array.list(SwiftStringObject)
        XCTAssertNotNil(subarray, "Should be able to get an empty array")
        XCTAssertEqual(subarray.count, 0, "Should start with no array elements")

        let obj = SwiftStringObject()
        obj.stringCol = "a"
        subarray.append(obj)
        subarray.append(SwiftStringObject.createInRealm(realm, withObject: ["b"]))
        subarray.append(obj)
        realm.commitWrite()

        XCTAssertEqual(subarray.count, 3, "Should have three elements in array")
        XCTAssertEqual(subarray[0]!.stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqual(subarray[1]!.stringCol, "b", "Second element should have property value 'b'")
        XCTAssertEqual(subarray[2]!.stringCol, "a", "Third element should have property value 'a'")

        for obj in subarray {
            XCTAssertFalse(obj.description.isEmpty, "Object should have description")
        }
    }

    func testModifyDetatchedArray() {
        let realm = realmWithTestPath()
        realm.beginWrite()
        let arObj = SwiftArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        let subarray = arObj.array.list(SwiftStringObject)
        XCTAssertNotNil(subarray, "Should be able to get an empty array")
        XCTAssertEqual(subarray.count, 0, "Should start with no array elements")

        let obj = SwiftStringObject()
        obj.stringCol = "a"
        subarray.append(obj)
        subarray.append(SwiftStringObject.createInRealm(realm, withObject: ["b"]))
        realm.commitWrite()

        XCTAssertEqual(subarray.count, 2, "Should have two elements in array")
        XCTAssertEqual(subarray[0]!.stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqual(subarray[1]!.stringCol, "b", "Second element should have property value 'b'")
    }

    func testInsertMultiple() {
        let realm = realmWithTestPath()

        realm.beginWrite()

        let obj = SwiftArrayPropertyObject.createInRealm(realm, withObject: ["arrayObject", [], []])
        let child1 = SwiftStringObject.createInRealm(realm, withObject: ["a"])
        let child2 = SwiftStringObject()
        child2.stringCol = "b"
        obj.array.list(SwiftStringObject).append([child2, child1])
        realm.commitWrite()

        let children = realm.objects(SwiftStringObject)
        XCTAssertEqual(children[0]!.stringCol, "a", "First child should be 'a'")
        XCTAssertEqual(children[1]!.stringCol, "b", "Second child should be 'b'")
    }

    func testStandalone() {
        let realm = realmWithTestPath()

        let array = SwiftArrayPropertyObject()
        let subarray = array.array.list(SwiftStringObject)
        array.name = "name"

        let obj = SwiftStringObject()
        obj.stringCol = "a"
        subarray.append(obj)
        subarray.append(obj)

        realm.write { realm.add(array) }

        XCTAssertEqual(subarray.count, 2, "Should have two elements in array")
        XCTAssertEqual(subarray[0]!.stringCol, "a", "First element should have property value 'a'")
        XCTAssertEqual(subarray[1]!.stringCol, "a", "Second element should have property value 'a'")
    }
}
