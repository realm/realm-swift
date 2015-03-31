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

import Foundation
import Realm
import Realm.Private
import RealmSwift
import XCTest

class TestCase: RLMAutoreleasePoolTestCase {
    var exceptionThrown = false

    func realmWithTestPath() -> Realm {
        return Realm(path: testRealmPath())
    }

    override func invokeTest() {
        Realm.defaultPath = realmPathForFile("\(realmFilePrefix()).default.realm")
        NSFileManager.defaultManager().createDirectoryAtPath(realmPathForFile(""), withIntermediateDirectories: true, attributes: nil, error: nil)

        exceptionThrown = false
        super.invokeTest()

        if exceptionThrown {
            RLMDeallocateRealm(Realm.defaultPath)
            RLMDeallocateRealm(testRealmPath())
        }
        else {
            XCTAssertNil(RLMGetThreadLocalCachedRealmForPath(Realm.defaultPath))
            XCTAssertNil(RLMGetThreadLocalCachedRealmForPath(testRealmPath()))
        }
        deleteRealmFiles()
        RLMRealm.resetRealmState()
    }

    func assertThrows<T>(block: @autoclosure () -> T, _ message: String? = nil, fileName: String = __FILE__, lineNumber: UInt = __LINE__) {
        exceptionThrown = true
        RLMAssertThrows(self, { _ = block() }, message, fileName, lineNumber);
    }

    private func realmFilePrefix() -> String {
        let remove = NSCharacterSet(charactersInString: "-[]")
        return self.name.stringByTrimmingCharactersInSet(remove)
    }

    private func deleteRealmFiles() {
        let succeeded = NSFileManager.defaultManager().removeItemAtPath(realmPathForFile(""), error: nil)
        assert(succeeded, "Unable to delete realm files")
    }

    internal func testRealmPath() -> String {
        return realmPathForFile("\(realmFilePrefix()).realm")
    }
}

private func realmPathForFile(fileName: String) -> String {
    var path = Realm.defaultPath.stringByDeletingLastPathComponent
    if path.lastPathComponent != "testRealms" {
        path = path.stringByAppendingPathComponent("testRealms")
    }
    return path.stringByAppendingPathComponent(fileName)
}
