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
import Realm

class SwiftUISyncTestCases: XCTestCase {
    // Create App only once
    static var appId: String?
    static var flexibleSyncAppId: String?

    // App Runner Directory
    var clientDataRoot: URL {
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return applicationSupportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier!)
    }
    // App Directory
    var appClientDataRoot: URL {
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return applicationSupportDirectory.appendingPathComponent("io.realm.TestHost")
    }

    // App Info
    fileprivate var appId: String? {
        SwiftUISyncTestHostUITests.appId
    }
    fileprivate var app: App?

    // Flexible Sync
    fileprivate var flexibleSyncAppId: String? {
        SwiftUISyncTestHostUITests.flexibleSyncAppId
    }
    fileprivate var flexibleSyncApp: App?

    // User Info
    fileprivate var username1 = ""
    fileprivate var username2 = ""
    fileprivate let password = "password"

    // Application
    fileprivate let application = XCUIApplication()

    // MARK: - Test Lifecycle
    override class func setUp() {
        super.setUp()
        if RealmServer.haveServer() {
            _ = RealmServer.shared
        }
    }

    override func tearDown() {
        logoutAllUsers()
        application.terminate()
        resetSyncManager()
        super.tearDown()
    }

    override class func tearDown() {
        do {
            try FileManager.default.removeItem(at: SwiftUISyncTestHostUITests().clientDataRoot)
            try FileManager.default.removeItem(at: SwiftUISyncTestHostUITests().appClientDataRoot)
        } catch {
            XCTFail("Error reseting application data")
        }
        super.tearDown()
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

            // Sessions are removed from the user asynchronously after a logout.
            // We need to wait for this to happen before calling resetForTesting as
            // that expects all sessions to be cleaned up first.
            if user.allSessions.count > 0 {
                exArray.append(expectation(for: NSPredicate(format: "allSessions.@count == 0"), evaluatedWith: user, handler: nil))
            }
        }

        if exArray.count > 0 {
            wait(for: exArray, timeout: 60.0)
        }
    }
}

// MARK: -
extension SwiftUISyncTestCases {
    fileprivate func registerAndLoginUser(email: String, password: String, for app: App) throws -> User {
        try registerUser(email: email, password: password, for: app)
        return try loginUser(email: email, password: password, for: app)
    }

    fileprivate func registerUser(email: String, password: String, for app: App) throws {
        let ex = expectation(description: "Should register in the user properly")
        app.emailPasswordAuth.registerUser(email: email, password: password, completion: { error in
            XCTAssertNil(error)
            ex.fulfill()
        })
        waitForExpectations(timeout: 4, handler: nil)
    }

    fileprivate func loginUser(email: String, password: String, for app: App) throws -> User {
        var syncUser: User!
        let ex = expectation(description: "Should log in the user properly")
        let credentials = Credentials.emailPassword(email: email, password: password)
        app.login(credentials: credentials) { result in
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

    fileprivate func openRealm(configuration: Realm.Configuration, for user: User) throws -> Realm {
        var configuration = configuration
        if configuration.objectTypes == nil {
            configuration.objectTypes = [SwiftPerson.self]
        }
        let realm = try Realm(configuration: configuration)
        user.waitForDownload(toFinish: user.id)
        return realm
    }

    // Login for given email and password
    fileprivate enum UserType: Int {
        case first = 1
        case second = 2
    }
    fileprivate func loginUser(_ type: UserType) {
        let loginButton = application.buttons["login_button_\(type.rawValue)"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 2))
        loginButton.tap()

        let loggingView = application.staticTexts["logged_view"]
        XCTAssertTrue(loggingView.waitForExistence(timeout: 2))
    }

    fileprivate func asyncOpen() {
        loginUser(.first)

        // Query for button to start syncing
        let syncButtonView = application.buttons["sync_button"]
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()
    }

    fileprivate func logoutAllUsers() {
        let loginButton = application.buttons["logout_users_button"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 2))
        loginButton.tap()
    }

    fileprivate func randomString(_ length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}

class SwiftUISyncTestHostUITests: SwiftUISyncTestCases {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        try? FileManager.default.createDirectory(at: clientDataRoot, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: appClientDataRoot, withIntermediateDirectories: true)

        // Create App once for this Test Suite
        if SwiftUISyncTestHostUITests.appId == nil {
            do {
                let appId = try RealmServer.shared.createApp()
                SwiftUISyncTestHostUITests.appId = appId
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

    private func getApp() throws -> App {
        // Setup App for Testing
        let appConfiguration = RLMAppConfiguration(baseURL: "http://localhost:9090",
                                                   transport: nil,
                                                   localAppName: nil,
                                                   localAppVersion: nil,
                                                   defaultRequestTimeoutMS: 60)
        // Create app in current process
        return App(id: appId!, configuration: appConfiguration, rootDirectory: clientDataRoot)
    }

    private func createUsers(email: String, password: String, n: Int) throws -> User {
        let user = try registerAndLoginUser(email: email, password: password, for: app!)
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
}

// MARK: - AsyncOpen
extension SwiftUISyncTestHostUITests {
    func testDownloadRealmAsyncOpenApp() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let user = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "async_open"
        application.launchEnvironment["app_id"] = appId
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
        XCTAssertEqual(table.cells.count, 2)
    }

    func testDownloadRealmAsyncOpenAppWithEnvironmentPartitionValue() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)
    }

    func testDownloadRealmAsyncOpenAppWithEnvironmentConfiguration() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "async_open_environment_configuration"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)
    }

    func testObservedResults() throws {
        // This test ensures that `@ObservedResults` correctly observes both local
        // and sync changes to a collection.
        let partitionValue = "test"
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"

        let user1 = try registerAndLoginUser(email: email, password: password, for: app!)
        let user2 = try registerAndLoginUser(email: email2, password: password, for: app!)

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
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launchEnvironment["partition_value"] = partitionValue
        application.launchEnvironment["app_id"] = appId
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
        user2.waitForDownload(toFinish: partitionValue)
        try! realm2.write {
            realm2.add(SwiftPerson(firstName: "Joe2", lastName: "Blogs"))
            realm2.add(SwiftPerson(firstName: "Jane2", lastName: "Doe"))
        }
        user2.waitForUpload(toFinish: partitionValue)
        XCTAssertEqual(table.cells.count, 4)

        loginUser(.first)
        user1.waitForDownload(toFinish: partitionValue)
        // Make sure the first user also has 4 SwiftPerson's
        XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
        syncButtonView.tap()
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 4)
    }

    func testAsyncOpenMultiUser() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)
        let email2 = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email2, password: password, n: 1)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["email2"] = email2
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
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
        _ = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "async_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
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
        let user = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "auto_open"
        application.launchEnvironment["app_id"] = appId
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
        XCTAssertEqual(table.cells.count, 2)
    }

    func testDownloadRealmAutoOpenAppWithEnvironmentPartitionValue() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "auto_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen()

        // Test show ListView after syncing realm
        let table = application.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 6))
        XCTAssertEqual(table.cells.count, 2)
    }

    func testDownloadRealmAutoOpenAppWithEnvironmentConfiguration() throws {
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        _ = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "auto_open_environment_configuration"
        application.launchEnvironment["app_id"] = appId
        application.launch()

        asyncOpen()

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

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["email2"] = email2
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "auto_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
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
        _ = try createUsers(email: email, password: password, n: 2)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "auto_open_environment_partition"
        application.launchEnvironment["app_id"] = appId
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

class SwiftUIFlexibleSyncTestHostUITests: SwiftUISyncTestCases {
    override func setUp() {
        continueAfterFailure = false

        try? FileManager.default.createDirectory(at: clientDataRoot, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: appClientDataRoot, withIntermediateDirectories: true)

        // Create App once for this Test Suite
        if SwiftUISyncTestHostUITests.flexibleSyncAppId == nil {
            do {
                let appId = try RealmServer.shared.createAppWithQueryableFields(["age", "firstName"])
                SwiftUISyncTestHostUITests.flexibleSyncAppId = appId
            } catch {
                XCTFail("Cannot initialise test without a creating an App on the server")
            }
        }

        // Instantiate App from appId after
        do {
            flexibleSyncApp = try getApp()
        } catch {
            print("Error creating user \(error)")
        }
    }

    private func getApp() throws -> App {
        // Setup App for Testing
        let appConfiguration = RLMAppConfiguration(baseURL: "http://localhost:9090",
                                                   transport: nil,
                                                   localAppName: nil,
                                                   localAppVersion: nil,
                                                   defaultRequestTimeoutMS: 60)
        // Create app in current process
        return App(id: flexibleSyncAppId!, configuration: appConfiguration, rootDirectory: clientDataRoot)
    }

    func testFlexibleSyncAsyncOpenRoundTrip() throws {
        // This test ensures that `@ObservedResults` correctly observes both local
        // and sync changes to a collection.
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let user = try registerAndLoginUser(email: email, password: password, for: flexibleSyncApp!)
        let config = user.flexibleSyncConfiguration()

        let realm = try Realm(configuration: config)
        let subs = realm.subscriptions
        subs.write {
            subs.append(QuerySubscription<SwiftPerson>(name: "person_age") {
                $0.age > 0 && $0.firstName == "\(#function)"
            })
        }

        try realm.write {
            (1...10).forEach { index in
                realm.add(SwiftPerson(firstName: "\(#function)", lastName: "Smith", age: index))
            }
        }
        try user.waitForUploads(in: realm)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "async_open_flexible_sync"
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
        // This test ensures that `@ObservedResults` correctly observes both local
        // and sync changes to a collection.
        let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
        let user = try registerAndLoginUser(email: email, password: password, for: flexibleSyncApp!)
        let config = user.flexibleSyncConfiguration()

        let realm = try Realm(configuration: config)
        let subs = realm.subscriptions
        subs.write {
            subs.append(QuerySubscription<SwiftPerson>(name: "person_age") {
                $0.age > 0 && $0.firstName == "\(#function)"
            })
        }

        try realm.write {
            (1...10).forEach { index in
                realm.add(SwiftPerson(firstName: "\(#function)", lastName: "Smith", age: index))
            }
        }
        try user.waitForUploads(in: realm)

        application.launchEnvironment["email1"] = email
        application.launchEnvironment["password"] = password
        application.launchEnvironment["async_view_type"] = "auto_open_flexible_sync"
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
        XCTAssertEqual(table.cells.count, 8)
    }
}

extension User {
    func waitForUploads(in realm: Realm) throws {
        try waitForUploads(for: ObjectiveCSupport.convert(object: realm))
    }

    func waitForDownloads(in realm: Realm) throws {
        try waitForDownloads(for: ObjectiveCSupport.convert(object: realm))
    }
}
