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

class ListTests: SwiftTestCase {
    func doTest(array: SwiftArrayPropertyObject) {
        let realm = array.array.realm

        let str1 = SwiftStringObject()
        str1.stringCol = "1"
        let str2 = SwiftStringObject()
        str2.stringCol = "2"

        if let realm = realm {
            realm.write {
                realm.add(str1)
                realm.add(str2)

            }

            realm.beginWrite()
        }

        XCTAssertEqual(UInt(0), array.array.count)
        XCTAssertNil(array.array.first())
        XCTAssertNil(array.array.last())
        XCTAssertFalse(array.array.description.isEmpty)

        array.array.append(str1)
        XCTAssertEqual(UInt(1), array.array.count)
        XCTAssertEqual("1", array.array[0].stringCol)
        XCTAssertEqual("1", array.array.first()!.stringCol)
        XCTAssertEqual("1", array.array.last()!.stringCol)

        array.array.insert(str2, atIndex: 0)
        XCTAssertEqual(UInt(2), array.array.count)
        XCTAssertEqual("2", array.array[0].stringCol)
        XCTAssertEqual("2", array.array.first()!.stringCol)
        XCTAssertEqual("1", array.array.last()!.stringCol)

        array.array.removeLast()
        XCTAssertEqual(UInt(1), array.array.count)
        XCTAssertEqual("2", array.array[0].stringCol)
        XCTAssertEqual("2", array.array.first()!.stringCol)
        XCTAssertEqual("2", array.array.last()!.stringCol)

        array.array.removeAll()
        XCTAssertEqual(UInt(0), array.array.count)

        array.array.append([str1, str2])
        XCTAssertEqual(UInt(2), array.array.count)
        XCTAssertEqual("1", array.array[0].stringCol)
        XCTAssertEqual("1", array.array.first()!.stringCol)
        XCTAssertEqual("2", array.array.last()!.stringCol)

        var i = 0
        for obj in array.array {
            if i == 0 {
                XCTAssertEqual(obj, str1)
            }
            else {
                XCTAssertEqual(obj, str2)
            }
            i += 1
        }

        XCTAssertEqual(UInt(0), array.array.indexOf(str1)!)
        XCTAssertEqual(UInt(1), array.array.indexOf(str2)!)

        // not implemented for standalone
        if realm != nil {
            let sortedAsc = array.array.sorted("stringCol", ascending: true)
            let sortedDesc = array.array.sorted("stringCol", ascending: false)
            XCTAssertEqual("1", sortedAsc[0].stringCol)
            XCTAssertEqual("2", sortedAsc[1].stringCol)
            XCTAssertEqual("2", sortedDesc[0].stringCol)
            XCTAssertEqual("1", sortedDesc[1].stringCol)
        }

        // FIXME: test filter()+indexOf() once it's implemented
//        if realm != nil {
//            XCTAssertEqual(0, array.array.indexOf("stringCol == 1")!)
//            XCTAssertEqual(1, array.array.indexOf("stringCol == 2")!)
//            XCTAssertNil(array.array.indexOf("stringCol == 3"))
//        }

        array.array.remove(str1)
        XCTAssertEqual(UInt(1), array.array.count)
        XCTAssertEqual("2", array.array[0].stringCol)
        XCTAssertEqual("2", array.array.first()!.stringCol)
        XCTAssertEqual("2", array.array.last()!.stringCol)
        XCTAssertNil(array.array.indexOf(str1))

        array.array.replace(0, object: str1)
        XCTAssertEqual(UInt(1), array.array.count)
        XCTAssertEqual("1", array.array[0].stringCol)
        XCTAssertEqual("1", array.array.first()!.stringCol)
        XCTAssertEqual("1", array.array.last()!.stringCol)

        array.array[0] = str2
        XCTAssertEqual(UInt(1), array.array.count)
        XCTAssertEqual("2", array.array[0].stringCol)
        XCTAssertEqual("2", array.array.first()!.stringCol)
        XCTAssertEqual("2", array.array.last()!.stringCol)

        realm?.commitWrite()

        // verify all the stuff we just did was actually persisted
        if let realm = realm {
            let fetchedArray = realm.objects(SwiftArrayPropertyObject).first()!
            XCTAssertEqual(UInt(1), fetchedArray.array.count)
        }
    }

    func testStandalone() {
        let array = SwiftArrayPropertyObject()
        XCTAssertNil(array.array.realm)
        doTest(array)
    }

    func testNewlyAdded() {
        let array = SwiftArrayPropertyObject()
        array.name = "name"

        let realm = self.realmWithTestPath()
        realm.write { realm.add(array) }

        XCTAssertNotNil(array.array.realm)
        doTest(array)
    }

    func testNewlyCreated() {
        let realm = self.realmWithTestPath()
        realm.beginWrite()
        let array = SwiftArrayPropertyObject.createInRealm(realm, withObject: ["name", [], []])
        realm.commitWrite()

        XCTAssertNotNil(array.array.realm)
        doTest(array)
    }

    func testRetrieved() {
        let realm = self.realmWithTestPath()
        realm.beginWrite()
        SwiftArrayPropertyObject.createInRealm(realm, withObject: ["name", [], []])
        realm.commitWrite()
        let array = realm.objects(SwiftArrayPropertyObject).first()!

        XCTAssertNotNil(array.array.realm)
        doTest(array)
    }
}
