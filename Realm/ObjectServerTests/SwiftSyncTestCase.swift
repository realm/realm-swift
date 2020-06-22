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

// MARK: Test case

class SwiftSyncTestCase: RLMSyncTestCase {

    var task: Process?

    /// For testing, make a unique Realm URL of the form "realm://127.0.0.1:9080/~/X",
    /// where X is either a custom string passed as an argument, or an UUID string.
    static func uniqueRealmURL(customName: String? = nil) -> URL {
        return URL(string: "realm://127.0.0.1:9080/~/\(customName ?? UUID().uuidString)")!
    }

    func executeChild(file: StaticString = #file, line: UInt = #line) {
        XCTAssert(0 == runChildAndWait(), "Tests in child process failed", file: file, line: line)
    }

    func randomString(_ length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map { _ in letters.randomElement()! })
    }

    func basicCredentials(usernameSuffix: String = "",
                          file: StaticString = #file,
                          line: UInt = #line) -> Credentials {
        let username = "\(randomString(10))\(usernameSuffix)"
        let password = "abcdef"
        let credentials = Credentials(username: username, password: password)
        let ex = expectation(description: "Should register in the user properly")
        app.emailPasswordAuth().registerEmail(username, password: password, completion: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })
        waitForExpectations(timeout: 4, handler: nil)
        return credentials
    }

    func synchronouslyOpenRealm(partitionValue: String,
                                user: User,
                                file: StaticString = #file,
                                line: UInt = #line) throws -> Realm {
        let config = user.configuration(partitionValue: partitionValue)
        return try synchronouslyOpenRealm(configuration: config)
    }

    func synchronouslyOpenRealm(configuration: Realm.Configuration,
                                file: StaticString = #file,
                                line: UInt = #line) throws -> Realm {
        return try Realm(configuration: configuration)
    }

    func immediatelyOpenRealm(partitionValue: String, user: User) throws -> Realm {
        return try Realm(configuration: user.configuration(partitionValue: partitionValue))
    }

    func synchronouslyLogInUser(for credentials: Credentials,
                                file: StaticString = #file,
                                line: UInt = #line) throws -> User {
        let process = isParent ? "parent" : "child"
        var theUser: User?
        var theError: Error?
        let ex = expectation(description: "Should log in the user properly")

        self.app.login(withCredential: credentials, completion: { user, error in
            theUser = user
            theError = error
            ex.fulfill()
        })

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertNotNil(theUser, file: file, line: line)
        XCTAssertEqual(theUser?.state, .loggedIn,
                       "User should have been valid, but wasn't. (process: \(process), error: "
                        + "\(theError != nil ? String(describing: theError!) : "n/a"))",
                       file: file,
                       line: line)
        return theUser!
    }

    func synchronouslyLogOutUser(_ user: User,
                                 file: StaticString = #file,
                                 line: UInt = #line) throws {
        var theError: Error?
        let ex = expectation(description: "Should log out the user properly")

        user.logOut { (error) in
            theError = error
            ex.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertEqual(user.state, .loggedOut,
                       "User should have been valid, but wasn't. (error: "
                        + "\(theError?.localizedDescription ?? "nil"))",
            file: file,
            line: line)
    }

    func waitForUploads(for realm: Realm) {
        waitForUploads(for: ObjectiveCSupport.convert(object: realm))
    }

    func waitForDownloads(for realm: Realm) {
        waitForDownloads(for: ObjectiveCSupport.convert(object: realm))
    }

    func checkCount<T: Object>(expected: Int,
                               _ realm: Realm,
                               _ type: T.Type,
                               file: StaticString = #file,
                               line: UInt = #line) {
        let actual = realm.objects(type).count
        XCTAssert(actual == expected,
                  "Error: expected \(expected) items, but got \(actual) (process: \(isParent ? "parent" : "child"))",
                  file: file,
                  line: line)
    }
}
