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

class SwiftUISyncTestHostUITests: XCTestCase {
    // Create App only once
    static var appId: String?

    // App Info
    private var app: App?

    // User Info
    private var username1 = ""
    private var username2 = ""
    private let password = "password"

    // Application
    private let application = XCUIApplication()

    // MARK: - Test Lifecycle
    override class func setUp() {
        super.setUp()
        if RealmServer.haveServer() {
            _ = RealmServer.shared
        }
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Create App once for this Test Suite
        if SwiftUISyncTestHostUITests.appId == nil {
            do {
                SwiftUISyncTestHostUITests.appId = try RealmServer.shared.createApp()
            } catch {
                XCTFail("Cannot initialise test without a creating an App on the server")
            }
        }

        // Instantiate App from appId after
        do {
            app = try getApp()
        } catch {
            print("Error creating user \(error)")
        }
    }

    override func tearDown() {
        application.terminate()
        resetSyncManager()
        super.tearDown()
    }

    override class func tearDown() {
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
        super.tearDown()
    }
}

// MARK: -
extension SwiftUISyncTestHostUITests {
    private func getApp() throws -> App {
        super.setUp()
        // Setup App for Testing
        let appConfiguration = RLMAppConfiguration(baseURL: "http://localhost:9090",
                                                   transport: nil,
                                                   localAppName: nil,
                                                   localAppVersion: nil,
                                                   defaultRequestTimeoutMS: 60)
        // Create app in current process
        return App(id: appId!, configuration: appConfiguration)
    }

    private func resetSyncManager() {
        guard appId != nil, let app = app else {
            return
        }

        var exArray: [XCTestExpectation] = []
        for (_, user) in app.allUsers {
            let ex = expectation(description: "Should logout user")
            exArray.append(ex)
            user.logOut { error in
                if let error = error {
                    XCTFail("Logout should not fail \(error)")
                } else {
                    ex.fulfill()
                }
            }
        }

        wait(for: exArray, timeout: 60.0)
    }

    private func createUsers(email: String, password: String, n: Int) throws -> User {
        let user = try registerAndLoginUser(email: email, password: password)
        let config = user.configuration(partitionValue: user.id)
        let realm = try openRealm(configuration: config, for: user)
        try realm.write {
            (1...n).forEach { _ in
                realm.add(SwiftPerson(firstName: randomString(7), lastName: randomString(7)))
            }
        }
        user.waitForUpload(toFinish: user.id)
        return user
    }

    private func registerAndLoginUser(email: String, password: String) throws -> User{
        try registerUser(email: email, password: password)
        return try loginUser(email: email, password: password)
    }

    private func registerUser(email: String, password: String) throws {
        let ex = expectation(description: "Should register in the user properly")
        app!.emailPasswordAuth.registerUser(email: email, password: password, completion: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })
        waitForExpectations(timeout: 4, handler: nil)
    }

    private func loginUser(email: String, password: String) throws -> User {
        var syncUser: User!
        let ex = expectation(description: "Should log in the user properly")
        let credentials = Credentials.emailPassword(email: email, password: password)
        app!.login(credentials: credentials) { result in
            switch result {
            case .success(let user):
                syncUser = user
                XCTAssertTrue(syncUser.isLoggedIn)
            case .failure(let error):
                XCTFail("Should login user: \(error)")
            }
            ex.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
        return syncUser
    }

    private func openRealm(configuration: Realm.Configuration, for user: User) throws -> Realm {
        var configuration = configuration
        if configuration.objectTypes == nil {
            configuration.objectTypes = [SwiftPerson.self]
        }
        let realm = try Realm(configuration: configuration)
        user.waitForDownload(toFinish: user.id)
        return realm
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

        let loggingView = application.staticTexts["logged_view"]
        XCTAssertTrue(loggingView.waitForExistence(timeout: 2))
    }

    private func asyncOpen(email: String, password: String) {
        login(email: email, password: password)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync_button"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()
    }
}

// MARK: - AsyncOpen
extension SwiftUISyncTestHostUITests {
    func testDownloadRealmAsyncOpenApp() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let user = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["async_view_type"] = "async_open"
        application.launchEnvironment["app_id"] = appId
        application.launchEnvironment["partition_value"] = user.id
        application.launch()

        asyncOpen(email: email, password: password)

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
        XCTAssertEqual(table.cells.count, 2)
    }

    func testDownloadRealmAsyncOpenAppWithEnvironmentPartitionValue() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen(email: email, password: password)

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)
    }

    func testDownloadRealmAsyncOpenAppWithEnvironmentConfiguration() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["async_view_type"] = "async_open_environment_configuration"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen(email: email, password: password)

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)
    }
    
    func testAsyncOpenMultiUser() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email2, password: password, n: 1)
        
        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
        application.launch()
        
        asyncOpen(email: email, password: password)
        
        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)
        
        let emailTextfield = application.textFields["email_textfield"]
        XCTAssertTrue(emailTextfield.waitForExistence(timeout: 2))
        emailTextfield.clearText()
        
        let passwordTextfield = application.textFields["password_textfield"]
        XCTAssertTrue(passwordTextfield.waitForExistence(timeout: 2))
        passwordTextfield.clearText()
        
        login(email: email2, password: password)
        
        // Query for button to start syncing
        let syncButtonView = application.buttons["sync_button"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()
        
        // Test show ListView after logging new user
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 1)
    }
    
    func testAsyncOpenMultiUserWithLogout() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email2, password: password, n: 3)

        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen(email: email, password: password)

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)

        let logoutButtonView = application.buttons["logout_button"]
        XCTAssertTrue(logoutButtonView.waitForExistence(timeout: 2))
        logoutButtonView.tap()

        let waitingUserView = application.staticTexts["waiting_user_view"]
        XCTAssertTrue(waitingUserView.waitForExistence(timeout: 2))

        let emailTextfield = application.textFields["email_textfield"]
        XCTAssertTrue(emailTextfield.waitForExistence(timeout: 2))
        emailTextfield.clearText()

        let passwordTextfield = application.textFields["password_textfield"]
        XCTAssertTrue(passwordTextfield.waitForExistence(timeout: 2))
        passwordTextfield.clearText()


        login(email: email2, password: password)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync_button"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()

        // Test show ListView after logging new user
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 3)
    }
}

// MARK: - AutoOpen
extension SwiftUISyncTestHostUITests {
    func testDownloadRealmAutoOpenApp() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let user = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["async_view_type"] = "auto_open"
        application.launchEnvironment["app_id"] = appId
        application.launchEnvironment["partition_value"] = user.id
        application.launch()

        // Test that the user is already logged in
        asyncOpen(email: email, password: password)

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
        XCTAssertEqual(table.cells.count, 2)
    }

    func testDownloadRealmAutoOpenAppWithEnvironmentPartitionValue() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["async_view_type"] = "auto_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen(email: email, password: password)

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)
    }

    func testDownloadRealmAutoOpenAppWithEnvironmentConfiguration() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["async_view_type"] = "auto_open_environment_configuration"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen(email: email, password: password)

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)
    }

    func testAutoOpenMultiUser() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email2, password: password, n: 1)

        application.launchEnvironment["async_view_type"] = "auto_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen(email: email, password: password)

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)

        let emailTextfield = application.textFields["email_textfield"]
        XCTAssertTrue(emailTextfield.waitForExistence(timeout: 2))
        emailTextfield.clearText()

        let passwordTextfield = application.textFields["password_textfield"]
        XCTAssertTrue(passwordTextfield.waitForExistence(timeout: 2))
        passwordTextfield.clearText()

        login(email: email2, password: password)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync_button"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()

        // Test show ListView after logging new user
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 1)
    }

    func testAutoOpenMultiUserWithLogout() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email2, password: password, n: 3)

        application.launchEnvironment["async_view_type"] = "auto_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen(email: email, password: password)

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)

        let logoutButtonView = application.buttons["logout_button"]
        XCTAssertTrue(logoutButtonView.waitForExistence(timeout: 2))
        logoutButtonView.tap()

        let waitingUserView = application.staticTexts["waiting_user_view"]
        XCTAssertTrue(waitingUserView.waitForExistence(timeout: 2))

        let emailTextfield = application.textFields["email_textfield"]
        XCTAssertTrue(emailTextfield.waitForExistence(timeout: 2))
        emailTextfield.clearText()

        let passwordTextfield = application.textFields["password_textfield"]
        XCTAssertTrue(passwordTextfield.waitForExistence(timeout: 2))
        passwordTextfield.clearText()


        login(email: email2, password: password)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync_button"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()

        // Test show ListView after logging new user
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 3)
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
