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
import Realm.Dynamic
import RealmSwift
import XCTest

func XCTAssertEqual<T: Any where T: Equatable>(@autoclosure a: () -> T?, @autoclosure b: () -> T?, _ message: String? = nil, file: String = __FILE__, line: UInt = __LINE__) {
    if let _a = a() {
        if let _b = b() {
            XCTAssertEqual(_a, _b, (message != nil ? message! : ""), file: file, line: line)
        } else {
            XCTFail((message != nil ? message! : "a != nil, b == nil"), file: file, line: line)
        }
    } else if let _ = b() {
        XCTFail((message != nil ? message! : "a == nil, b != nil"), file: file, line: line)
    }
}

func inMemoryRealm(inMememoryIdentifier: String) -> Realm {
    return Realm(configuration: Realm.Configuration(inMemoryIdentifier: inMememoryIdentifier))!
}

class TestCase: XCTestCase {
    var exceptionThrown = false

    func realmWithTestPath(var _ configuration: Realm.Configuration = Realm.Configuration()) -> Realm {
        configuration.path = testRealmPath()
        return Realm(configuration: configuration)!
    }

    override class func setUp() {
        super.setUp()
#if DEBUG || arch(i386) || arch(x86_64)
        // Disable actually syncing anything to the disk to greatly speed up the
        // tests, but only when not running on device because it can't be
        // re-enabled and we need it enabled for performance tests
        RLMDisableSyncToDisk()
#endif
        // Clean up any potentially lingering Realm files from previous runs
        NSFileManager.defaultManager().removeItemAtPath(RLMRealmPathForFile(""), error: nil)
        // The directory might not actually already exist, so not an error
    }

    override func invokeTest() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(path: realmPathForFile("\(realmFilePrefix()).default.realm"))
        NSFileManager.defaultManager().createDirectoryAtPath(realmPathForFile(""), withIntermediateDirectories: true, attributes: nil, error: nil)

        exceptionThrown = false
        autoreleasepool { super.invokeTest() }

        if !exceptionThrown {
            XCTAssertFalse(RLMHasCachedRealmForPath(defaultRealmPath()))
            XCTAssertFalse(RLMHasCachedRealmForPath(testRealmPath()))
        }
        RLMRealm.resetRealmState()
        deleteRealmFiles()
    }

    func dispatchSyncNewThread(block: dispatch_block_t) {
        let queue = dispatch_queue_create("background", nil)
        dispatch_async(queue) {
            autoreleasepool {
                block()
            }
        }
        dispatch_sync(queue) {}
    }

    func assertThrows<T>(@autoclosure(escaping) block: () -> T, _ message: String? = nil, named: String? = RLMExceptionName, fileName: String = __FILE__, lineNumber: UInt = __LINE__) {
        exceptionThrown = true
        RLMAssertThrows(self, { _ = block() } as dispatch_block_t, named, message, fileName, lineNumber)
    }

    func assertNil<T>(@autoclosure block: () -> T?, _ message: String? = nil, fileName: String = __FILE__, lineNumber: UInt = __LINE__) {
        XCTAssert(block() == nil, message ?? "", file: fileName, line: lineNumber)
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

    internal func defaultRealmPath() -> String {
        return realmPathForFile("\(realmFilePrefix()).default.realm")
    }
}

private func realmPathForFile(fileName: String) -> String {
    var path = (Realm.Configuration.defaultConfiguration.path! as NSString).stringByDeletingLastPathComponent
    if path.lastPathComponent != "testRealms" {
        path = path.stringByAppendingPathComponent("testRealms")
    }
    return path.stringByAppendingPathComponent(fileName)
}
