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

#if REALM_XCODE_VERSION_0730
    typealias TestLocationString = StaticString
#else
    typealias TestLocationString = String
#endif

func inMemoryRealm(inMememoryIdentifier: String) -> Realm {
    return try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: inMememoryIdentifier))
}

class TestCase: XCTestCase {
    var exceptionThrown = false
    var testDir: String! = nil

    func realmWithTestPath(configuration: Realm.Configuration = Realm.Configuration()) -> Realm {
        var configuration = configuration
        configuration.path = testRealmPath()
        return try! Realm(configuration: configuration)
    }

    override class func setUp() {
        super.setUp()
#if DEBUG || arch(i386) || arch(x86_64)
        // Disable actually syncing anything to the disk to greatly speed up the
        // tests, but only when not running on device because it can't be
        // re-enabled and we need it enabled for performance tests
        RLMDisableSyncToDisk()
#endif
        do {
            // Clean up any potentially lingering Realm files from previous runs
            try NSFileManager.defaultManager().removeItemAtPath(RLMRealmPathForFile(""))
        } catch {
            // The directory might not actually already exist, so not an error
        }
    }

    override class func tearDown() {
        RLMRealm.resetRealmState()
        super.tearDown()
    }

    override func invokeTest() {
        testDir = RLMRealmPathForFile(realmFilePrefix())

        do {
            try NSFileManager.defaultManager().removeItemAtPath(testDir)
        } catch {
            // The directory shouldn't actually already exist, so not an error
        }
        try! NSFileManager.defaultManager().createDirectoryAtPath(testDir, withIntermediateDirectories: true,
            attributes: nil)

        Realm.Configuration.defaultConfiguration = Realm.Configuration(path: defaultRealmPath())

        exceptionThrown = false
        autoreleasepool { super.invokeTest() }

        if !exceptionThrown {
            XCTAssertFalse(RLMHasCachedRealmForPath(defaultRealmPath()))
            XCTAssertFalse(RLMHasCachedRealmForPath(testRealmPath()))
        }

        resetRealmState()

        do {
            try NSFileManager.defaultManager().removeItemAtPath(testDir)
        } catch {
            XCTFail("Unable to delete realm files")
        }

        // Verify that there are no remaining realm files after the test
        let parentDir = (testDir as NSString).stringByDeletingLastPathComponent
        for url in NSFileManager().enumeratorAtPath(parentDir)! {
            XCTAssertNotEqual(url.pathExtension, "realm", "Lingering realm file at \(parentDir)/\(url)")
            assert(url.pathExtension != "realm")
        }
    }

    func resetRealmState() {
        RLMRealm.resetRealmState()
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

    func assertThrows<T>(@autoclosure(escaping) block: () -> T, _ message: String? = nil,
                         named: String? = RLMExceptionName, fileName: String = __FILE__, lineNumber: UInt = __LINE__) {
        exceptionThrown = true
        RLMAssertThrows(self, { _ = block() } as dispatch_block_t, named, message, fileName, lineNumber)
    }

    func assertSucceeds(message: String? = nil, fileName: TestLocationString = __FILE__,
                        lineNumber: UInt = __LINE__, @noescape block: () throws -> ()) {
        do {
            try block()
        } catch {
            XCTFail("Expected no error, but instead caught <\(error)>.",
                file: fileName, line: lineNumber)
        }
    }

    func assertFails<T>(expectedError: Error, _ message: String? = nil,
                        fileName: TestLocationString = __FILE__, lineNumber: UInt = __LINE__,
                        @noescape block: () throws -> T) {
        do {
            try block()
            XCTFail("Expected to catch <\(expectedError)>, but no error was thrown.",
                file: fileName, line: lineNumber)
        } catch expectedError {
            // Success!
        } catch {
            XCTFail("Expected to catch <\(expectedError)>, but instead caught <\(error)>.",
                file: fileName, line: lineNumber)
        }
    }

    func assertNil<T>(@autoclosure block: () -> T?, _ message: String? = nil,
                      fileName: TestLocationString = __FILE__, lineNumber: UInt = __LINE__) {
        XCTAssert(block() == nil, message ?? "", file: fileName, line: lineNumber)
    }

    private func realmFilePrefix() -> String {
        let remove = NSCharacterSet(charactersInString: "-[]")
#if REALM_XCODE_VERSION_0730
        return self.name!.stringByTrimmingCharactersInSet(remove)
#else
        return self.name.stringByTrimmingCharactersInSet(remove)
#endif
    }

    internal func testRealmPath() -> String {
        return realmPathForFile("test.realm")
    }

    internal func defaultRealmPath() -> String {
        return realmPathForFile("default.realm")
    }

    private func realmPathForFile(fileName: String) -> String {
        return (testDir as NSString).stringByAppendingPathComponent(fileName)
    }
}
