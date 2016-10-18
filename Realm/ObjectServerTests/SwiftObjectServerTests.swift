////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#if swift(>=3.0)
class SwiftObjectServerTests: SwiftSyncTestCase {
    /// It should be possible to successfully open a Realm configured for sync.
    func testBasicSwiftSync() {
        let url = URL(string: "realm://localhost:9080/~/testBasicSync")!
        do {
            let user = try synchronouslyLogInUser(for: basicCredential(create: true), server: authURL)
            let realm = try synchronouslyOpenRealm(url: url, user: user)
            XCTAssert(realm.isEmpty, "Freshly synced Realm was not empty...")
        } catch {
            XCTFail("Got an error: \(error)")
        }
    }

    /// If client B adds objects to a Realm, client A should see those new objects.
    func testSwiftAddObjects() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredential(create: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            if isParent {
                user.waitForDownload(toFinish: realmURL)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
                executeChild()
                user.waitForDownload(toFinish: realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
            } else {
                // Add objects
                try realm.write {
                    realm.add(SwiftSyncObject(value: ["child-1"]))
                    realm.add(SwiftSyncObject(value: ["child-2"]))
                    realm.add(SwiftSyncObject(value: ["child-3"]))
                }
                user.waitForUpload(toFinish: realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    /// If client B removes objects from a Realm, client A should see those changes.
    func testSwiftDeleteObjects() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredential(create: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            if isParent {
                try realm.write {
                    realm.add(SwiftSyncObject(value: ["child-1"]))
                    realm.add(SwiftSyncObject(value: ["child-2"]))
                    realm.add(SwiftSyncObject(value: ["child-3"]))
                }
                user.waitForUpload(toFinish: realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
                executeChild()
                user.waitForDownload(toFinish: realmURL)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
            } else {
                try realm.write {
                    realm.deleteAll()
                }
                user.waitForUpload(toFinish: realmURL)
                checkCount(expected:0, realm, SwiftSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }
}
#else
class SwiftObjectServerTests: SwiftSyncTestCase {
    /// It should be possible to successfully open a Realm configured for sync.
    func testBasicSwiftSync() {
        let url = NSURL(string: "realm://localhost:9080/~/testBasicSync")!
        do {
            let user = try synchronouslyLogInUser(for: basicCredential(create: true), server: authURL)
            let realm = try synchronouslyOpenRealm(url: url, user: user)
            XCTAssert(realm.isEmpty, "Freshly synced Realm was not empty...")
        } catch {
            XCTFail("Got an error: \(error)")
        }
    }

    /// If client B adds objects to a Realm, client A should see those new objects.
    func testSwiftAddObjects() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredential(create: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            if isParent {
                user.waitForDownloadToFinish(realmURL)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
                executeChild()
                user.waitForDownloadToFinish(realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
            } else {
                // Add objects
                try realm.write {
                    realm.add(SwiftSyncObject(value: ["child-1"]))
                    realm.add(SwiftSyncObject(value: ["child-2"]))
                    realm.add(SwiftSyncObject(value: ["child-3"]))
                }
                user.waitForUploadToFinish(realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    /// If client B removes objects from a Realm, client A should see those changes.
    func testSwiftDeleteObjects() {
        do {
            let user = try synchronouslyLogInUser(for: basicCredential(create: isParent), server: authURL)
            let realm = try synchronouslyOpenRealm(url: realmURL, user: user)
            if isParent {
                try realm.write {
                    realm.add(SwiftSyncObject(value: ["child-1"]))
                    realm.add(SwiftSyncObject(value: ["child-2"]))
                    realm.add(SwiftSyncObject(value: ["child-3"]))
                }
                user.waitForUploadToFinish(realmURL)
                checkCount(expected: 3, realm, SwiftSyncObject.self)
                executeChild()
                user.waitForDownloadToFinish(realmURL)
                checkCount(expected: 0, realm, SwiftSyncObject.self)
            } else {
                try realm.write {
                    realm.deleteAll()
                }
                user.waitForUploadToFinish(realmURL)
                checkCount(expected:0, realm, SwiftSyncObject.self)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }
}
#endif
