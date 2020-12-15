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

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif

let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"

class SwiftRLMUnicodeTests: RLMTestCase {

    // Swift models

    func testUTF8StringContents() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        _ = SwiftRLMStringObject.create(in: realm, withValue: [utf8TestString])
        try! realm.commitWriteTransaction()

        let obj1 = SwiftRLMStringObject.allObjects(in: realm).firstObject() as! SwiftRLMStringObject
        XCTAssertEqual(obj1.stringCol, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        let obj2 = SwiftRLMStringObject.objects(in: realm, where: "stringCol == %@", utf8TestString).firstObject() as! SwiftRLMStringObject
        XCTAssertTrue(obj1.isEqual(to: obj2), "Querying a realm searching for a string with UTF8 content should work")
    }

    func testUTF8PropertyWithUTF8StringContents() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        _ = SwiftRLMUTF8Object.create(in: realm, withValue: [utf8TestString])
        try! realm.commitWriteTransaction()

        let obj1 = SwiftRLMUTF8Object.allObjects(in: realm).firstObject() as! SwiftRLMUTF8Object
        XCTAssertEqual(obj1.柱колоéнǢкƱаم👍, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        // Test fails because of rdar://17735684
//        let obj2 = SwiftRLMUTF8Object.objectsInRealm(realm, "柱колоéнǢкƱаم👍 == %@", utf8TestString).firstObject() as SwiftRLMUTF8Object
//        XCTAssertEqual(obj1, obj2, "Querying a realm searching for a string with UTF8 content should work")
    }

    // Objective-C models

    func testUTF8StringContents_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        _ = StringObject.create(in: realm, withValue: [utf8TestString])
        try! realm.commitWriteTransaction()

        let obj1 = StringObject.allObjects(in: realm).firstObject() as! StringObject
        XCTAssertEqual(obj1.stringCol, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        // Temporarily commented out because variadic import seems broken
        let obj2 = StringObject.objects(in: realm, where: "stringCol == %@", utf8TestString).firstObject() as! StringObject
        XCTAssertTrue(obj1.isEqual(to: obj2), "Querying a realm searching for a string with UTF8 content should work")
    }

    func testUTF8PropertyWithUTF8StringContents_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        _ = UTF8Object.create(in: realm, withValue: [utf8TestString])
        try! realm.commitWriteTransaction()

        let obj1 = UTF8Object.allObjects(in: realm).firstObject() as! UTF8Object
        XCTAssertEqual(obj1.柱колоéнǢкƱаم, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        // Test fails because of rdar://17735684
//        let obj2 = UTF8Object.objectsInRealm(realm, "柱колоéнǢкƱаم == %@", utf8TestString).firstObject() as UTF8Object
//        XCTAssertEqual(obj1, obj2, "Querying a realm searching for a string with UTF8 content should work")
    }
}
