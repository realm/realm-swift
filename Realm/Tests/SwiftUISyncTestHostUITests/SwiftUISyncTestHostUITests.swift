////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

class SwiftUISyncTestHostUITests: SwiftSyncTestCase {

    override func tearDown() {
        logoutAllUsers()
        application.terminate()
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        application.launchEnvironment["app_id"] = appId
    }

    // Application
    private let application = XCUIApplication()

    private func openRealm(configuration: Realm.Configuration, for user: User) throws -> Realm {
        var configuration = configuration
        if configuration.objectTypes == nil {
            configuration.objectTypes = [SwiftPerson.self]
        }
        let realm = try Realm(configuration: configuration)
        waitForDownloads(for: realm)
        return realm
    }

    @discardableResult
    private func populateForEmail(_ email: String, n: Int) throws -> User {
        let user = logInUser(for: basicCredentials(name: email, register: true))
        let config = user.configuration(partitionValue: user.id)
        let realm = try openRealm(configuration: config, for: user)
        try realm.write {
            for _ in (1...n) {
                realm.add(SwiftPerson(firstName: randomString(7), lastName: randomString(7)))
            }
        }
        waitForUploads(for: realm)
        return user
    }

    // Login for given user
    private enum UserType: Int {
        case first = 1
        case second = 2
    }
    private func loginUser(_ type: UserType) {
        let loginButton = application.buttons["login_button_\(type.rawValue)"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 2))
        loginButton.tap()

        let loggingView = application.staticTexts["logged_view"]
        XCTAssertTrue(loggingView.waitForExistence(timeout: 6))
    }

    private func asyncOpen() {
        loginUser(.first)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync_button"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()
    }

    private func logoutAllUsers() {
        let loginButton = application.buttons["logout_users_button"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 2))
        loginButton.tap()
    }
}

// MARK: - AsyncOpen
extension SwiftUISyncTestHostUITests {
    func testDownloadRealmAsyncOpenApp() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let user = try populateForEmail(email, n: 1)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["async_view_type"] = "async_open"
        application.launchEnvironment["partition_value"] = user.id
        application.launch()

        asyncOpen()

        // Test progress is greater than 0
        let progressView = application.staticTexts["progress_text_view"]
        XCTAssertTrue(progressView.waitForExistence(timeout: 2))
        let progressValue = progressView.value as! String
        XCTAssertTrue(Int64(progressValue)! > 0)

        // Query for button to navigate to next view
        let nextViewView = application.buttons["show_list_button_view"]
        nextViewView.tap()

        // Test show ListView after syncing realm environment
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 1)
    }

    func testDownloadRealmAsyncOpenAppWithEnvironmentPartitionValue() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateForEmail(email, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)
    }

    func testDownloadRealmAsyncOpenAppWithEnvironmentConfiguration() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateForEmail(email, n: 3)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["async_view_type"] = "async_open_environment_configuration"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 3)
    }

    func testObservedResults() throws {
        // This test ensures that `@ObservedResults` correctly observes both local
        // and sync changes to a collection.
        let partitionValue = "test"
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"

        let user1 = logInUser(for: basicCredentials(name: email, register: true))
        let user2 = logInUser(for: basicCredentials(name: email2, register: true))

        let config1 = user1.configuration(partitionValue: partitionValue)
        let config2 = user2.configuration(partitionValue: partitionValue)

        let realm = try Realm(configuration: config1)
        try realm.write {
            realm.add(SwiftPerson(firstName: "Joe", lastName: "Blogs"))
            realm.add(SwiftPerson(firstName: "Jane", lastName: "Doe"))
        }
        user1.waitForUpload(toFinish: partitionValue)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["email2"] = email2
        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launchEnvironment["partition_value"] = partitionValue
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)

        loginUser(.second)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync_button"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()

        // Test show ListView after logging new user
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)

        let realm2 = try Realm(configuration: config2)
        waitForDownloads(for: realm2)
        try! realm2.write {
            realm2.add(SwiftPerson(firstName: "Joe2", lastName: "Blogs"))
            realm2.add(SwiftPerson(firstName: "Jane2", lastName: "Doe"))
        }
        user2.waitForUpload(toFinish: partitionValue)
        XCTAssertEqual(table.cells.count, 4)

        loginUser(.first)
        waitForDownloads(for: realm)
        // Make sure the first user also has 4 SwiftPerson's
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 4)
    }

    func testAsyncOpenMultiUser() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateForEmail(email, n: 2)
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateForEmail(email2, n: 1)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["email2"] = email2
        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)

        loginUser(.second)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync_button"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()

        // Test show ListView after logging new user
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 1)
    }

    func testAsyncOpenAndLogout() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateForEmail(email, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)

        let logoutButtonView = application.buttons["logout_button"]
        XCTAssertTrue(logoutButtonView.waitForExistence(timeout: 2))
        logoutButtonView.tap()

        let waitingUserView = application.staticTexts["waiting_user_view"]
        XCTAssertTrue(waitingUserView.waitForExistence(timeout: 2))
    }
}

// MARK: - AutoOpen
extension SwiftUISyncTestHostUITests {
    func testDownloadRealmAutoOpenApp() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let user = try populateForEmail(email, n: 1)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["async_view_type"] = "auto_open"
        application.launchEnvironment["partition_value"] = user.id
        application.launch()

        // Test that the user is already logged in
        asyncOpen()

        // Test progress is greater than 0
        let progressView = application.staticTexts["progress_text_view"]
        XCTAssertTrue(progressView.waitForExistence(timeout: 2))
        let progressValue = progressView.value as! String
        XCTAssertTrue(Int64(progressValue)! > 0)

        // Query for button to navigate to next view
        let nextViewView = application.buttons["show_list_button_view"]
        nextViewView.tap()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 1)
    }

    func testDownloadRealmAutoOpenAppWithEnvironmentPartitionValue() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateForEmail(email, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["async_view_type"] = "auto_open_environment_partition"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)
    }

    func testDownloadRealmAutoOpenAppWithEnvironmentConfiguration() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateForEmail(email, n: 3)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["async_view_type"] = "auto_open_environment_configuration"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 3)
    }

    func testAutoOpenMultiUser() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateForEmail(email, n: 2)
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateForEmail(email2, n: 1)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["email2"] = email2
        application.launchEnvironment["async_view_type"] = "auto_open_environment_partition"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)

        loginUser(.second)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync_button"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()

        // Test show ListView after logging new user
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 1)
    }

    func testAutoOpenAndLogout() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateForEmail(email, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["async_view_type"] = "auto_open_environment_partition"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)

        let logoutButtonView = application.buttons["logout_button"]
        XCTAssertTrue(logoutButtonView.waitForExistence(timeout: 2))
        logoutButtonView.tap()

        let waitingUserView = application.staticTexts["waiting_user_view"]
        XCTAssertTrue(waitingUserView.waitForExistence(timeout: 2))
    }
}

// MARK: - Flexible Sync
extension SwiftUISyncTestHostUITests {
    private func populateFlexibleSyncForEmail(_ email: String, n: Int, _ block: @escaping (Realm) -> Void) throws {
        let user = logInUser(for: basicCredentials(name: email, register: true, app: flexibleSyncApp), app: flexibleSyncApp)

        let config = user.flexibleSyncConfiguration()
        let realm = try Realm(configuration: config)
        let subs = realm.subscriptions
        let ex = expectation(description: "state change complete")
        subs.write({
            subs.append(QuerySubscription<SwiftPerson>(name: "person_age", where: "TRUEPREDICATE"))
        }, onComplete: { error in
            if error == nil {
                ex.fulfill()
            } else {
                XCTFail("Subscription Set could not complete with \(error!)")
            }
        })
        waitForExpectations(timeout: 20.0, handler: nil)

        try realm.write {
            block(realm)
        }
        waitForUploads(for: realm)
    }

    func testFlexibleSyncAsyncOpenRoundTrip() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateFlexibleSyncForEmail(email, n: 10) { realm in
            for index in (1...10) {
                realm.add(SwiftPerson(firstName: "\(#function)", lastName: "Smith", age: index))
            }
        }

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["async_view_type"] = "async_open_flexible_sync"
        // Override appId for flexible app Id
        application.launchEnvironment["app_id"] = flexibleSyncAppId
        application.launchEnvironment["firstName"] = "\(#function)"
        application.launch()

        asyncOpen()

        // Query for button to navigate to next view
        let nextViewView = application.buttons["show_list_button_view"]
        XCTAssertTrue(nextViewView.waitForExistence(timeout: 10))
        nextViewView.tap()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 5)
    }

    func testFlexibleSyncAutoOpenRoundTrip() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        try populateFlexibleSyncForEmail(email, n: 10) { realm in
            for index in (1...20) {
                realm.add(SwiftPerson(firstName: "\(#function)", lastName: "Smith", age: index))
            }
        }

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["async_view_type"] = "auto_open_flexible_sync"
        // Override appId for flexible app Id
        application.launchEnvironment["app_id"] = flexibleSyncAppId
        application.launchEnvironment["firstName"] = "\(#function)"
        application.launch()

        asyncOpen()

        // Query for button to navigate to next view
        let nextViewView = application.buttons["show_list_button_view"]
        XCTAssertTrue(nextViewView.waitForExistence(timeout: 10))
        nextViewView.tap()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 18)
    }
}
