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

func testRealmPath() -> String {
    return realmPathForFile("test.realm")
}

func defaultRealmPath() -> String {
    return realmPathForFile("default.realm")
}

func realmPathForFile(fileName: String) -> String {
    #if os(iOS)
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        return (paths[0] as String) + fileName
    #else
        return fileName
    #endif
}

func realmLockPath(path: String) -> String {
    return path + ".lock"
}

func deleteRealmFilesAtPath(path: String) {
    var error: NSError?

    NSFileManager.defaultManager().removeItemAtPath(path, error: &error)
    assert(error == nil, "Unable to delete realm")

    NSFileManager.defaultManager().removeItemAtPath(realmLockPath(path), error: &error)
    assert(error == nil, "Unable to delete realm")
}

func realmWithTestPathAndSchema(schema: RLMSchema?) -> RLMRealm {
    return RLMRealm.realmWithPath(testRealmPath(), readOnly: false, dynamic: false, schema: schema, error: nil)
}

func dynamicRealmWithTestPathAndSchema(schema: RLMSchema?) -> RLMRealm {
    return RLMRealm.realmWithPath(testRealmPath(), readOnly: false, dynamic: true, schema: schema, error: nil)
}

class SwiftTestCase: XCTestCase {

    func realmWithTestPath() -> RLMRealm {
        return RLMRealm.realmWithPath(testRealmPath(), readOnly: false, error: nil)
    }

    override func setUp() {
        super.setUp()

        // Delete realm files
        deleteRealmFilesAtPath(defaultRealmPath())
        deleteRealmFilesAtPath(testRealmPath())
    }

    override func tearDown() {
        super.tearDown()

        // Reset Realm cache
        RLMRealm.clearRealmCache()

        // Delete realm files
        deleteRealmFilesAtPath(defaultRealmPath())
        deleteRealmFilesAtPath(testRealmPath())
    }
}
