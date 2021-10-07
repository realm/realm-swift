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
    let application = XCUIApplication()

    private let username1 = "1234567890ab1234567890ab"
    private let username2 = "1234566754727dbkd67hdg5b"
    private let password = "password"

    override func setUp() {
        continueAfterFailure = false
        super.setUp()

        // TODO: This should be a static method
        let user = logInUser(for: basicCredentials(withName: username1, register: true))
        let config = user.configuration(testName: user.id)
        let realm = try! openRealm(configuration: config)
        try! realm.write {
            realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
            realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
        }
        waitForUploads(for: realm)

        // Register second user for multi-user tests, login and populate it
        let user2 = logInUser(for: basicCredentials(withName: username2, register: true))
        let config2 = user2.configuration(testName: user2.id)
        let realm2 = try! openRealm(configuration: config2)
        try! realm2.write {
            realm2.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
        }
        waitForUploads(for: realm2)

        application.launchEnvironment["partition_value"] = user.id
        application.launchEnvironment["app_id"] = appId
    }

    override func tearDown() {
        application.terminate()
        deleteApplicationData()
        super.tearDown()
    }

    func deleteApplicationData() {
        do {
            let fileManager = FileManager.default
            let applicationSupportDir = try fileManager.url(for: .applicationSupportDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
            let applicationsUrls = try fileManager.contentsOfDirectory(at: applicationSupportDir,
                                                                       includingPropertiesForKeys: nil)
            for applicationUrl in applicationsUrls where applicationUrl.lastPathComponent == "io.realm.TestHost" {
                try fileManager.removeItem(at: applicationUrl)
            }
        } catch {
            XCTFail("Error reseting application data")
        }
    }

    // Login for given email and password
    private func login(email: String, password: String) {
        let emailTextfield = application.textFields["email_textfield"]
        XCTAssertTrue(emailTextfield.waitForExistence(timeout: 2))
        emailTextfield.tap()
        emailTextfield.typeText(email)

        let passwordTextfield = application.textFields["password_textfield"]
        XCTAssertTrue(passwordTextfield.waitForExistence(timeout: 2))
        passwordTextfield.tap()
        passwordTextfield.typeText(password)

        let loginButton = application.buttons["login_button"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 2))
        loginButton.tap()

        let loggingView = application.staticTexts["logged-view"]
        XCTAssertTrue(loggingView.waitForExistence(timeout: 2))
    }

    private func asyncOpen() {
        login(email: username1, password: password)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync-button-view"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()
    }

    // MARK: - AsyncOpen
    func testDownloadRealmAsyncOpenApp() throws {
        application.launchEnvironment["test_type"] = "async_open"
        application.launch()

        asyncOpen()

        // Test progress is greater than 0
        let progressView = application.staticTexts["progress-text-view"]
        XCTAssertTrue(progressView.waitForExistence(timeout: 2))
        let progressValue = progressView.value as! String
        XCTAssertTrue(Int64(progressValue)! > 0)

        // Query for button to navigate to next view
        let nextViewView = application.buttons["show-list-button-view"]
        nextViewView.tap()

        // Test show ListView after syncing realm environment
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, SwiftSyncTestCase.bigObjectCount)
    }

    func testDownloadRealmAsyncOpenAppWithEnvironmentPartitionValue() throws {
        application.launchEnvironment["test_type"] = "async_open_environment_partition_value"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, SwiftSyncTestCase.bigObjectCount)
    }

    func testDownloadRealmAsyncOpenAppWithEnvironmentConfiguration() throws {
        application.launchEnvironment["test_type"] = "async_open_environment_configuration"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, SwiftSyncTestCase.bigObjectCount)
    }

    func testAsyncOpenMultiUser() throws {
        application.launchEnvironment["test_type"] = "async_open_environment_partition_value"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, SwiftSyncTestCase.bigObjectCount)

        let emailTextfield = application.textFields["email_textfield"]
        XCTAssertTrue(emailTextfield.waitForExistence(timeout: 2))
        emailTextfield.clearText()

        let passwordTextfield = application.textFields["password_textfield"]
        XCTAssertTrue(passwordTextfield.waitForExistence(timeout: 2))
        passwordTextfield.clearText()

        login(email: username2, password: password)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync-button-view"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()

        // Test show ListView after logging new user
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 1)
    }

    // MARK: - AutoOpen
    func testDownloadRealmAutoOpenApp() throws {
        application.launchEnvironment["test_type"] = "auto_open"
        application.launch()

        // Test that the user is already logged in
        asyncOpen()

        // Test progress is greater than 0
        let progressView = application.staticTexts["progress-text-view"]
        XCTAssertTrue(progressView.waitForExistence(timeout: 2))
        let progressValue = progressView.value as! String
        XCTAssertTrue(Int64(progressValue)! > 0)

        // Query for button to navigate to next view
        let nextViewView = application.buttons["show-list-button-view"]
        nextViewView.tap()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, SwiftSyncTestCase.bigObjectCount)
    }

    func testDownloadRealmAutoOpenAppWithEnvironmentPartitionValue() throws {
        application.launchEnvironment["test_type"] = "auto_open_environment_partition_value"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, SwiftSyncTestCase.bigObjectCount)
    }

    func testDownloadRealmAutoOpenAppWithEnvironmentConfiguration() throws {
        application.launchEnvironment["test_type"] = "auto_open_environment_configuration"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, SwiftSyncTestCase.bigObjectCount)
    }

    func testAutoOpenMultiUser() throws {
        application.launchEnvironment["test_type"] = "auto_open_environment_partition_value"
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, SwiftSyncTestCase.bigObjectCount)

        let emailTextfield = application.textFields["email_textfield"]
        XCTAssertTrue(emailTextfield.waitForExistence(timeout: 2))
        emailTextfield.clearText()

        let passwordTextfield = application.textFields["password_textfield"]
        XCTAssertTrue(passwordTextfield.waitForExistence(timeout: 2))
        passwordTextfield.clearText()

        login(email: username2, password: password)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync-button-view"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()

        // Test show ListView after logging new user
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 1)
    }
}

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        self.tap()
        let deleteString = stringValue.map { _ in "\u{8}" }.joined(separator: "")
        self.typeText(deleteString)
    }
}
