////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

class RealmTests: TestCase {
    override func setUp() {
        super.setUp()
        realmWithTestPath().write {
            SwiftStringObject.createInRealm(self.realmWithTestPath(), withObject: ["1"])
            SwiftStringObject.createInRealm(self.realmWithTestPath(), withObject: ["2"])
            SwiftStringObject.createInRealm(self.realmWithTestPath(), withObject: ["3"])
        }

        defaultRealm().write {
            SwiftIntObject.createInRealm(defaultRealm(), withObject: [100])
            SwiftIntObject.createInRealm(defaultRealm(), withObject: [200])
            SwiftIntObject.createInRealm(defaultRealm(), withObject: [300])
        }
    }

    func testObjects() {
        XCTAssertEqual(0, objects(SwiftStringObject).count)
        XCTAssertEqual(3, objects(SwiftIntObject).count)
        XCTAssertEqual(3, objects(SwiftIntObject.self, inRealm: defaultRealm()).count)
    }

    func testDefaultRealmPath() {
        let defaultPath =  defaultRealm().path
        XCTAssertEqual(defaultRealmPath, defaultPath)

        let newPath = defaultPath.stringByAppendingPathExtension("new")!
        defaultRealmPath = newPath
        XCTAssertEqual(defaultRealmPath, newPath)

        // we have to clean up
        defaultRealmPath = defaultPath
    }

    func testDefaultRealm() {
        XCTAssertNotNil(defaultRealm())
        XCTAssertTrue(defaultRealm() as AnyObject is Realm)
    }

    func testSetEncryptionKey() {
        setEncryptionKey(NSMutableData(length: 64), forRealmsAtPath: defaultRealmPath)
        setEncryptionKey(nil, forRealmsAtPath: defaultRealmPath)
        XCTAssert(true, "setting those keys should not throw")
    }

    func testPath() {
        let realm = Realm(path: defaultRealmPath)
        XCTAssertEqual(defaultRealmPath, realm.path)
    }

    func testReadOnly() {
        autoreleasepool {
            defaultRealm().write {
                _ = SwiftStringObject.createInRealm(defaultRealm(), withObject: ["a"])
            }
        }

        let readOnlyRealm = Realm(path: defaultRealmPath, readOnly: true, error: nil)!
        XCTAssertEqual(true, readOnlyRealm.readOnly)
        XCTAssertEqual(1, objects(SwiftStringObject.self, inRealm: readOnlyRealm).count)
    }

    func testSchema() {
        let schema = defaultRealm().schema
        XCTAssert(schema as AnyObject is Schema)
//        XCTAssertEqual(1, schema.objectSchema.map { $0.className }.filter { $0 == "SwiftStringObject" }.count)
    }

    func testAutorefresh() {
        let realm = realmWithTestPath()
        XCTAssertTrue(realm.autorefresh, "Autorefresh should default to true")
        realm.autorefresh = false
        XCTAssertFalse(realm.autorefresh)
        realm.autorefresh = true
        XCTAssertTrue(realm.autorefresh)
    }
}
