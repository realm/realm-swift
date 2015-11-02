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

let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"

class SwiftUnicodeTests: RLMTestCase {

    // Swift models

    func testUTF8StringContents() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        SwiftStringObject.createInRealm(realm, withValue: [utf8TestString])
        try! realm.commitWriteTransaction()

        let obj1 = SwiftStringObject.allObjectsInRealm(realm).firstObject() as! SwiftStringObject
        XCTAssertEqual(obj1.stringCol, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        let obj2 = SwiftStringObject.objectsInRealm(realm, "stringCol == %@", utf8TestString).firstObject() as! SwiftStringObject
        XCTAssertTrue(obj1.isEqualToObject(obj2), "Querying a realm searching for a string with UTF8 content should work")
    }

    func testUTF8PropertyWithUTF8StringContents() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        SwiftUTF8Object.createInRealm(realm, withValue: [utf8TestString])
        try! realm.commitWriteTransaction()

        let obj1 = SwiftUTF8Object.allObjectsInRealm(realm).firstObject() as! SwiftUTF8Object
        XCTAssertEqual(obj1.柱колоéнǢкƱаم👍, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        // Test fails because of rdar://17735684
//        let obj2 = SwiftUTF8Object.objectsInRealm(realm, "柱колоéнǢкƱаم👍 == %@", utf8TestString).firstObject() as SwiftUTF8Object
//        XCTAssertEqual(obj1, obj2, "Querying a realm searching for a string with UTF8 content should work")
    }

    // Objective-C models

    func testUTF8StringContents_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        StringObject.createInRealm(realm, withValue: [utf8TestString])
        try! realm.commitWriteTransaction()

        let obj1 = StringObject.allObjectsInRealm(realm).firstObject() as! StringObject
        XCTAssertEqual(obj1.stringCol, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        let obj2 = StringObject.objectsInRealm(realm, "stringCol == %@", utf8TestString).firstObject() as! StringObject
        XCTAssertTrue(obj1.isEqualToObject(obj2), "Querying a realm searching for a string with UTF8 content should work")
    }

    func testUTF8PropertyWithUTF8StringContents_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        UTF8Object.createInRealm(realm, withValue: [utf8TestString])
        try! realm.commitWriteTransaction()

        let obj1 = UTF8Object.allObjectsInRealm(realm).firstObject() as! UTF8Object
        XCTAssertEqual(obj1.柱колоéнǢкƱаم, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        // Test fails because of rdar://17735684
//        let obj2 = UTF8Object.objectsInRealm(realm, "柱колоéнǢкƱаم == %@", utf8TestString).firstObject() as UTF8Object
//        XCTAssertEqual(obj1, obj2, "Querying a realm searching for a string with UTF8 content should work")
    }
}
