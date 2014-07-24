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

let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"

class SwiftUnicodeTests: SwiftTestCase {

    // Swift models

    func testUTF8StringContents() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        SwiftStringObject.createInRealm(realm, withObject: [utf8TestString])
        realm.commitWriteTransaction()

        let obj1 = realm.objects(SwiftStringObject()).firstObject()!
        XCTAssertEqual(obj1.stringCol, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        let obj2 = realm.objects(SwiftStringObject(), "stringCol == %@", utf8TestString).firstObject()!
        XCTAssertEqual(obj1, obj2, "Querying a realm searching for a string with UTF8 content should work")
    }

    func testUTF8PropertyWithUTF8StringContents() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        SwiftUTF8Object.createInRealm(realm, withObject: [utf8TestString])
        realm.commitWriteTransaction()

        let obj1 = realm.objects(SwiftUTF8Object()).firstObject()!
        XCTAssertEqual(obj1.柱колоéнǢкƱаم👍, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        // Test fails because of rdar://17735684
//        let obj2 = realm.objects(SwiftUTF8Object(), "柱колоéнǢкƱаم👍 == %@", utf8TestString).firstObject()
//        XCTAssertEqualObjects(obj1, obj2, "Querying a realm searching for a string with UTF8 content should work")
    }

    // Objective-C models

    func testUTF8StringContents_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        StringObject.createInRealm(realm, withObject: [utf8TestString])
        realm.commitWriteTransaction()

        let obj1 = realm.objects(StringObject()).firstObject()!
        XCTAssertEqual(obj1.stringCol, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        let obj2 = realm.objects(StringObject(), "stringCol == %@", utf8TestString).firstObject()!
        XCTAssertEqual(obj1, obj2, "Querying a realm searching for a string with UTF8 content should work")
    }

    func testUTF8PropertyWithUTF8StringContents_objc() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        UTF8Object.createInRealm(realm, withObject: [utf8TestString])
        realm.commitWriteTransaction()

        let obj1 = realm.objects(UTF8Object()).firstObject()!
        XCTAssertEqual(obj1.柱колоéнǢкƱаم, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

        // Test fails because of rdar://17735684
//        let obj2 = realm.objects(UTF8Object(), "柱колоéнǢкƱаم👍 == %@", utf8TestString).firstObject()
//        XCTAssertEqualObjects(obj1, obj2, "Querying a realm searching for a string with UTF8 content should work")
    }
}
