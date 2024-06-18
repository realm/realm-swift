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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
class SwiftUITests: XCTestCase {
    var realm: Realm!
    @MainActor
    let app = XCUIApplication()

    @MainActor
    override func setUpWithError() throws {
        continueAfterFailure = false

        // the realm must be created before app launch otherwise we will not have
        // write permissions
        let realmPath = URL(string: "\(FileManager.default.temporaryDirectory)\(UUID())")!
        let configuration = Realm.Configuration(fileURL: realmPath)
        _ = try Realm.deleteFiles(for: configuration)
        self.realm = try! Realm(configuration: configuration)

        app.launchEnvironment = [
            "REALM_PATH": realmPath.absoluteString
        ]
    }

    @MainActor
    override func tearDownWithError() throws {
        app.terminate()
        self.realm.invalidate()
        let config = realm.configuration
        self.realm = nil
        XCTAssertTrue(try Realm.deleteFiles(for: config))
    }

    private func deleteString(for string: String) -> String {
        String(repeating: XCUIKeyboardKey.delete.rawValue, count: string.count)
    }

    @MainActor
    private var tables: XCUIElementQuery {
        if #available(iOS 16.0, *) {
            return app.collectionViews
        } else {
            return app.tables
        }
    }

    @MainActor
    func testSampleApp() throws {
        app.launch()
        // assert realm is empty
        XCTAssertEqual(realm.objects(ReminderList.self).count, 0)

        // add 3 lists, and assert that they have been added to
        // the UI and Realm
        let addButton = app.buttons["addList"]
        addButton.tap()
        addButton.tap()
        addButton.tap()
        XCTAssertEqual(realm.objects(ReminderList.self).count, 3)
        XCTAssertEqual(tables.firstMatch.cells.count, 3)

        // delete each person, operating from the zeroeth index
        for _ in 0..<tables.firstMatch.cells.count {
            let row = tables.firstMatch.cells.element(boundBy: 0)
            row.swipeLeft()
            app.buttons["Delete"].tap()
        }

        XCTAssertEqual(realm.objects(ReminderList.self).count, 0)
        XCTAssertEqual(tables.firstMatch.cells.count, 0)

        // add another list, and tap into the ReminderView
        addButton.tap()
        app.buttons["New List"].tap()
        XCTAssertTrue(app.navigationBars.staticTexts["New List"].waitForExistence(timeout: 1.0))
        app.buttons["addReminder"].tap()
        if #available(iOS 18, *) {
            // Work around what appears to be a bug in SwiftUI in iOS 18 beta 1
            // where tapping the list entry doesn't navigate to ReminderView
            // if there's only one list entry
            app.buttons["addReminder"].tap()
        }
        // type in a name
        if #available(iOS 16, *) {
            app.cells.element(boundBy: 0).tap()
        } else {
            app.textFields["title"].tap()
        }
        app.textFields["title"].tap()
        app.textFields["title"].typeText("My Reminder")
        // check to see if it is reflected live in the title view
        XCTAssertTrue(app.navigationBars.staticTexts["My Reminder"].waitForExistence(timeout: 1.0))
        let myReminder = realm.objects(ReminderList.self).first!.reminders.first!
        XCTAssertEqual(myReminder.priority, .low)
        if #available(iOS 16, *) {
            app.buttons["priority_picker"].tap()
            app.buttons["medium"].tap()
            XCTAssertEqual(myReminder.priority, .medium)
        } else {
            app.buttons["priority_picker"].tap()
            tables.switches["medium"].tap()
            XCTAssertEqual(myReminder.priority, .medium)
        }

        app.navigationBars.buttons.element(boundBy: 0).tap()

        // MARK: Test Move
        app.buttons["addReminder"].tap()
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.first!.title, "My Reminder")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[1].title, "")

        app.buttons["Edit"].tap()
        app.buttons.matching(identifier: "Reorder").firstMatch.press(forDuration: 1, thenDragTo: tables.cells.element(boundBy: 1))

        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.first!.title, "")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[1].title, "My Reminder")

        // MARK: Test Delete
        // potentially brittle, but these are the hooks swiftUI gives us. when editing a list,
        // a cancel button appears on the left and a drag icon appears on the right. the label
        // for the cancel button is "Delete ", which when tapped, reveals the actual delete button
        // labeled "Delete"
        func delete() {
            if #available(iOS 16.0, *) {
                let collectionViewsQuery = app.collectionViews
                collectionViewsQuery.cells.otherElements.containing(.image, identifier: "remove").element.firstMatch.tap()
                collectionViewsQuery.buttons["Delete"].firstMatch.tap()
            } else {
                app.buttons.matching(identifier: "Delete ").firstMatch.tap()
                app.buttons.matching(identifier: "Delete").firstMatch.tap()
            }
        }
        if #available(iOS 18, *) {
            XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.count, 3)
            delete()
        }
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.count, 2)
        delete()
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.count, 1)
        delete()
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.count, 0)

        app.navigationBars.buttons.firstMatch.tap()

        tables.cells.firstMatch.swipeLeft()
        app.buttons.matching(identifier: "Delete").firstMatch.tap()
        XCTAssertEqual(realm.objects(ReminderList.self).count, 0)
    }

    @MainActor
    func testNSPredicateObservedResults() throws {
        app.launch()
        try observedResultsQueryTest()
    }

    @MainActor
    func testSwiftQueryObservedResults() throws {
        app.launchEnvironment["query_type"] = "type_safe_query"
        app.launch()
        try observedResultsQueryTest()
    }

    @MainActor
    private func observedResultsQueryTest() throws {
        let addButton = app.buttons["addList"]
        (1...5).forEach { _ in
            addButton.tap()
        }

        // Name every reminders list for search
        try realm.write {
            for (index, obj) in (realm.objects(ReminderList.self)).enumerated() {
                obj.name = "reminder list \((index % 2) == 0 ? "even" : "odd")"
            }
        }

        let searchBar = app.textFields["searchField"]
        let table = tables.firstMatch

        searchBar.tap()

        searchBar.typeText("even")
        searchBar.typeText("\n") // \n to dismiss keyboard
        XCTAssertEqual(table.cells.count, 3)
    }

    @MainActor
    func testMultipleEnvironmentRealms() {
        app.launchEnvironment["test_type"] = "multi_realm_test"
        app.launch()

        app.buttons["Realm A"].tap()
        XCTAssertEqual(app.staticTexts["test_text_view"].label, "realm_a")
        app.buttons["Back"].tap()

        app.buttons["Realm B"].tap()
        XCTAssertEqual(app.staticTexts["test_text_view"].label, "realm_b")
        app.buttons["Back"].tap()

        app.buttons["Realm C"].tap()
        XCTAssertEqual(app.staticTexts["test_text_view"].label, "realm_c")
    }

    @MainActor
    func testUnmanagedObjectState() {
        app.launchEnvironment["test_type"] = "unmanaged_object_test"
        app.launch()

        app.textFields["name"].tap()
        app.textFields["name"].typeText(deleteString(for: "New List"))
        app.textFields["name"].typeText("test name")
        app.navigationBars.firstMatch.tap()
        app.buttons["addReminder"].tap()
        XCTAssertEqual(realm.objects(ReminderList.self).first!.name, "test name")

        app.buttons["Next"].tap()
        app.buttons["Delete"].tap()

        XCTAssertEqual(app.textFields["name"].value as? String, "test name")
    }

    @MainActor
    func testKeyPathResults() {
        app.launchEnvironment["test_type"] = "observed_results_key_path"
        app.launch()

        let addButton = app.buttons["addList"]
        addButton.tap()
        addButton.tap()

        // Populate reminders to reminder list.
        try! realm.write {
            for obj in realm.objects(ReminderList.self) {
                obj.reminders.append(Reminder())
            }
        }
        // Change the name of two ReminderList objects.
        // This is a separate write block because it's testing a change outside
        // the keypath input.
        try! realm.write {
            for obj in realm.objects(ReminderList.self) {
                obj.name = "changed"
            }
        }

        // Expect the ui to still show two cells labelled New List.
        // The view should've not updated because the name change was
        // outside keypath input.
        let cell0 = tables.firstMatch.cells.element(boundBy: 0)
        let cell1 = tables.firstMatch.cells.element(boundBy: 1)
        XCTAssert(cell0.staticTexts["New List"].exists)
        XCTAssert(cell1.staticTexts["New List"].exists)
        XCTAssertEqual(realm.objects(ReminderList.self).count, 2)
        XCTAssertEqual(tables.firstMatch.cells.count, 2)

        // Change isFlagged status of a linked reminder.
        try! realm.write {
            let first = realm.objects(ReminderList.self).first!
            first.reminders[0].isFlagged = true
        }

        // Expect ui to refresh because the "reminders.isFlagged" keypath
        // has been changed.
        // Expect 2 cells now displaying "changed".
        XCTAssert(cell0.staticTexts["changed"].exists)
        XCTAssert(cell1.staticTexts["changed"].exists)
        XCTAssertEqual(realm.objects(ReminderList.self).count, 2)
        XCTAssertEqual(tables.firstMatch.cells.count, 2)
    }

    @MainActor
    func testUpdateResultsWithSearchable() {
        app.launchEnvironment["test_type"] = "observed_results_searchable"
        app.launch()
        let addButton = app.buttons["addList"]
        // iOS 16 lazily-loads only the required number of cells. 13 happens to
        // fit on-screen.
        (1...7).forEach { _ in
            addButton.tap()
        }

        // Name every reminders list for search
        try! realm.write {
            for (index, obj) in (realm.objects(ReminderList.self)).enumerated() {
                obj.name = "reminder list \(index)"
            }
        }

        (1...5).forEach { _ in
            addButton.tap()
        }

        func clearSearchBar() {
            let searchBar = app.searchFields.firstMatch
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: (searchBar.value as? String)!.count)
            searchBar.typeText(deleteString)
        }

        let table = tables.firstMatch

        // Observed Results filter, should filter reminders without name.
        XCTAssertEqual(table.cells.count, 7)

        let searchBar = app.searchFields.firstMatch
        searchBar.tap()

        searchBar.typeText("reminder")
        XCTAssertEqual(table.cells.count, 7)

        searchBar.typeText(" list 1")
        XCTAssertEqual(table.cells.count, 1)

        searchBar.typeText("2")
        XCTAssertEqual(table.cells.count, 0)

        clearSearchBar()
        app.navigationBars["Reminders"].buttons["Cancel"].tap()
        XCTAssertEqual(table.cells.count, 7)

        searchBar.tap()
        searchBar.typeText("2")
        XCTAssertEqual(table.cells.count, 1)

        clearSearchBar()
        searchBar.typeText("11")
        XCTAssertEqual(table.cells.count, 0)
    }

    @MainActor
    func testObservedResultsConfiguration() {
        app.launchEnvironment["test_type"] = "observed_results_configuration"
        app.launch()

        // Check that both @ObservedResults contain the correct configuration.
        // `remindersA` will get it's config from .environment, while `remindersA`
        // will get it's Realm config passed in the @ObservedResults initializer.
        XCTAssertEqual(app.staticTexts["realm_a_label"].label, "realm_a")
        XCTAssertEqual(app.staticTexts["realm_b_label"].label, "realm_b")

        let addButtonA = app.buttons["addListA"]
        let addButtonB = app.buttons["addListB"]
        (1...5).forEach { _ in
            addButtonA.tap()
            addButtonB.tap()
        }

        let tableA = tables["ListA"]
        XCTAssertEqual(tableA.cells.count, 5)

        let tableB = tables["ListB"]
        XCTAssertEqual(tableB.cells.count, 5)
    }

    @MainActor
    func testKeyPathObservedSectionedResults() {
        app.launchEnvironment["test_type"] = "observed_sectioned_results_key_path"
        app.launch()

        let addButton = app.buttons["addList"]
        addButton.tap()
        addButton.tap()

        // Populate reminders to reminder list.
        try! realm.write {
            for obj in realm.objects(ReminderList.self) {
                obj.reminders.append(Reminder())
            }
        }
        // Change the name of two ReminderList objects.
        // This is a separate write block because it's testing a change outside
        // the keypath input.
        try! realm.write {
            for obj in realm.objects(ReminderList.self) {
                obj.name = "changed"
            }
        }
        // Expect the ui to still show two cells labelled New List.
        // The view should've not updated because the name change was
        // outside keypath input.
        if #available(iOS 16, *) {
            let sectionHeader = app.collectionViews.children(matching: .cell).element(boundBy: 0)
            XCTAssert(sectionHeader.staticTexts["N"].exists)
            let cell0 = app.collectionViews.children(matching: .cell).element(boundBy: 1)
            let cell1 = app.collectionViews.children(matching: .cell).element(boundBy: 2)
            XCTAssert(cell0.staticTexts["New List"].exists)
            XCTAssert(cell1.staticTexts["New List"].exists)
        } else {
            XCTAssert(app.tables.firstMatch.otherElements.staticTexts["N"].exists)
            let cell0 = app.tables.firstMatch.cells.element(boundBy: 0)
            let cell1 = app.tables.firstMatch.cells.element(boundBy: 1)
            XCTAssert(cell0.staticTexts["New List"].exists)
            XCTAssert(cell1.staticTexts["New List"].exists)
            XCTAssertEqual(app.tables.firstMatch.cells.count, 2)
        }
        XCTAssertEqual(realm.objects(ReminderList.self).count, 2)

        // Change isFlagged status of a linked reminder.
        try! realm.write {
            let first = realm.objects(ReminderList.self).first!
            first.reminders[0].isFlagged = true
            let list = ReminderList()
            list.name = "Another List"
            realm.add(list)
        }

        // Expect ui to refresh because the "reminders.isFlagged" keypath
        // has been changed.
        // Expect 2 cells now displaying "changed".
        // Expect two sections as another `ReminderList` has
        // been inserted into the Realm.
        if #available(iOS 16, *) {
            let sectionHeader1 = app.collectionViews.children(matching: .cell).element(boundBy: 0)
            XCTAssert(sectionHeader1.staticTexts["A"].waitForExistence(timeout: 1.0))
            let cell0 = app.collectionViews.children(matching: .cell).element(boundBy: 1)
            XCTAssert(cell0.staticTexts["Another List"].exists)
            let sectionHeader2 = app.collectionViews.children(matching: .cell).element(boundBy: 2)
            XCTAssert(sectionHeader2.staticTexts["c"].exists)
            let cell1 = app.collectionViews.children(matching: .cell).element(boundBy: 3)
            let cell2 = app.collectionViews.children(matching: .cell).element(boundBy: 4)
            XCTAssert(cell1.staticTexts["changed"].exists)
            XCTAssert(cell2.staticTexts["changed"].exists)
        } else {
            XCTAssert(app.tables.otherElements.staticTexts["A"].exists)
            XCTAssert(app.tables.otherElements.staticTexts["c"].exists)
            let cell0 = app.tables.firstMatch.cells.element(boundBy: 0)
            XCTAssert(cell0.staticTexts["Another List"].exists)
            let cell2 = app.tables.cells.element(boundBy: 1)
            let cell3 = app.tables.cells.element(boundBy: 2)
            XCTAssert(cell2.staticTexts["changed"].exists)
            XCTAssert(cell3.staticTexts["changed"].exists)
            XCTAssertEqual(app.tables.firstMatch.cells.count, 3)
        }
        XCTAssertEqual(realm.objects(ReminderList.self).count, 3)

        let collectionViewsQuery = XCUIApplication().collectionViews
        collectionViewsQuery.children(matching: .other).element(boundBy: 1).tap()
        collectionViewsQuery.children(matching: .cell).element(boundBy: 1).children(matching: .other).element(boundBy: 1).children(matching: .other).element.swipeLeft()
        collectionViewsQuery.buttons["Delete"].tap()
        XCTAssertEqual(realm.objects(ReminderList.self).count, 2)

        collectionViewsQuery.children(matching: .other).element(boundBy: 2).tap()
        collectionViewsQuery.children(matching: .cell).element(boundBy: 2).children(matching: .other).element(boundBy: 1).children(matching: .other).element.swipeLeft()
        collectionViewsQuery.buttons["Delete"].tap()
        XCTAssertEqual(realm.objects(ReminderList.self).count, 1)

        collectionViewsQuery.children(matching: .other).element(boundBy: 1).tap()
        collectionViewsQuery.children(matching: .cell).element(boundBy: 1).children(matching: .other).element(boundBy: 1).children(matching: .other).element.swipeLeft()
        collectionViewsQuery.buttons["Delete"].tap()
        XCTAssertEqual(realm.objects(ReminderList.self).count, 0)
    }

    @MainActor
    func testKeyPathObservedSectionedResults2() {
        // Tests ObservedSectionedResults ctor that uses the `sectionBlock` param.
        app.launchEnvironment["test_type"] = "observed_sectioned_results_sort_descriptors"
        app.launch()

        let addButton = app.buttons["addList"]
        addButton.tap()
        addButton.tap()

        // Populate reminders to reminder list.
        try! realm.write {
            for obj in realm.objects(ReminderList.self) {
                obj.reminders.append(Reminder())
            }
        }
        // Change the name of two ReminderList objects.
        // This is a separate write block because it's testing a change outside
        // the keypath input.
        try! realm.write {
            for obj in realm.objects(ReminderList.self) {
                obj.name = "changed"
            }
        }

        // Expect the ui to still show two cells labelled New List.
        // The view should've not updated because the name change was
        // outside keypath input.
        if #available(iOS 16, *) {
            let sectionHeader = app.collectionViews.children(matching: .cell).element(boundBy: 0)
            XCTAssert(sectionHeader.staticTexts["N"].exists)
            let cell0 = app.collectionViews.children(matching: .cell).element(boundBy: 1)
            let cell1 = app.collectionViews.children(matching: .cell).element(boundBy: 2)
            XCTAssert(cell0.staticTexts["New List"].exists)
            XCTAssert(cell1.staticTexts["New List"].exists)
            XCTAssertEqual(realm.objects(ReminderList.self).count, 2)
        } else {
            XCTAssert(app.tables.firstMatch.otherElements.staticTexts["N"].exists)
            let cell0 = app.tables.firstMatch.cells.element(boundBy: 0)
            let cell1 = app.tables.firstMatch.cells.element(boundBy: 1)
            XCTAssert(cell0.staticTexts["New List"].exists)
            XCTAssert(cell1.staticTexts["New List"].exists)
            XCTAssertEqual(realm.objects(ReminderList.self).count, 2)
            XCTAssertEqual(app.tables.firstMatch.cells.count, 2)
        }

        // Change isFlagged status of a linked reminder.
        try! realm.write {
            let first = realm.objects(ReminderList.self).first!
            first.reminders[0].isFlagged = true
            let list = ReminderList()
            list.name = "Another List"
            realm.add(list)
        }

        // Expect ui to refresh because the "reminders.isFlagged" keypath
        // has been changed.
        // Expect 2 cells now displaying "changed".
        // Expect two sections as another `ReminderList` has
        // been inserted into the Realm.
        if #available(iOS 16, *) {
            let sectionHeader1 = app.collectionViews.children(matching: .cell).element(boundBy: 0)
            XCTAssert(sectionHeader1.staticTexts["A"].waitForExistence(timeout: 1.0))
            let cell0 = app.collectionViews.children(matching: .cell).element(boundBy: 1)
            XCTAssert(cell0.staticTexts["Another List"].exists)
            let sectionHeader2 = app.collectionViews.children(matching: .cell).element(boundBy: 2)
            XCTAssert(sectionHeader2.staticTexts["c"].exists)
            let cell1 = app.collectionViews.children(matching: .cell).element(boundBy: 3)
            let cell2 = app.collectionViews.children(matching: .cell).element(boundBy: 4)
            XCTAssert(cell1.staticTexts["changed"].exists)
            XCTAssert(cell2.staticTexts["changed"].exists)
        } else {
            XCTAssert(app.tables.otherElements.staticTexts["A"].exists)
            XCTAssert(app.tables.otherElements.staticTexts["c"].exists)
            let cell0 = app.tables.firstMatch.cells.element(boundBy: 0)
            XCTAssert(cell0.staticTexts["Another List"].exists)
            let cell2 = app.tables.cells.element(boundBy: 1)
            let cell3 = app.tables.cells.element(boundBy: 2)
            XCTAssert(cell2.staticTexts["changed"].exists)
            XCTAssert(cell3.staticTexts["changed"].exists)
            XCTAssertEqual(app.tables.firstMatch.cells.count, 3)
        }
        XCTAssertEqual(realm.objects(ReminderList.self).count, 3)
    }

    @MainActor
    func testUpdateObservedSectionedResultsWithSearchable() {
        app.launchEnvironment["test_type"] = "observed_sectioned_results_searchable"
        app.launch()

        let addButton = app.buttons["addList"]
        (1...7).forEach { _ in
            addButton.tap()
        }

        // Name every reminders list for search
        try! realm.write {
            for (index, obj) in (realm.objects(ReminderList.self)).enumerated() {
                obj.name = "reminder list \(index)"
            }
        }

        (1...5).forEach { _ in
            addButton.tap()
        }

        func clearSearchBar() {
            let searchBar = app.searchFields.firstMatch
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: (searchBar.value as? String)!.count)
            searchBar.typeText(deleteString)
        }

        if #available(iOS 16, *) {
            let table = app.collectionViews.firstMatch

            // iOS 16 will only report the visible cells.
            let searchBar = app.searchFields.firstMatch
            searchBar.tap()
            XCTAssertEqual(table.cells.count, 8)

            searchBar.typeText("5")
            XCTAssertEqual(table.cells.count, 2) // includes section header
            XCTAssert(table.staticTexts["r"].exists)
        } else {
            let table = app.tables.firstMatch

            // Observed Results filter, should filter reminders without name.
            XCTAssertEqual(table.cells.count, 7)

            let searchBar = app.searchFields.firstMatch
            searchBar.tap()

            searchBar.typeText("reminder")
            XCTAssertEqual(table.cells.count, 7)
            XCTAssert(app.tables.otherElements.staticTexts["r"].exists)

            searchBar.typeText(" list 1")
            XCTAssertEqual(table.cells.count, 1)

            searchBar.typeText("2")
            XCTAssertEqual(table.cells.count, 0)

            clearSearchBar()
            XCTAssertEqual(table.cells.count, 7)

            searchBar.typeText("5")
            XCTAssertEqual(table.cells.count, 1)

            clearSearchBar()
            searchBar.typeText("12")
            XCTAssertEqual(table.cells.count, 0)
        }
    }

    @MainActor
    func testObservedSectionedResultsConfiguration() {
        app.launchEnvironment["test_type"] = "observed_sectioned_results_configuration"
        app.launch()

        // Check that both @ObservedResults contain the correct configuration.
        // `remindersA` will get it's config from .environment, while `remindersA`
        // will get it's Realm config passed in the @ObservedResults initializer.
        XCTAssertEqual(app.staticTexts["realm_a_label"].label, "realm_a")
        XCTAssertEqual(app.staticTexts["realm_b_label"].label, "realm_b")

        let addButtonA = app.buttons["addListA"]
        let addButtonB = app.buttons["addListB"]
        (1...5).forEach { _ in
            addButtonA.tap()
            addButtonB.tap()
        }

        if #available(iOS 16, *) {
            let tableA = app.collectionViews.element(boundBy: 0)
            XCTAssert(tableA.otherElements.staticTexts["N"].exists)
            XCTAssertEqual(tableA.cells.count, 6) // includes section header

            let tableB = app.collectionViews.element(boundBy: 1)
            XCTAssert(tableB.otherElements.staticTexts["N"].exists)
            XCTAssertEqual(tableB.cells.count, 6)
        } else {
            let tableA = app.tables["ListA"]
            XCTAssert(tableA.otherElements.staticTexts["N"].exists)
            XCTAssertEqual(tableA.cells.count, 5)

            let tableB = app.tables["ListB"]
            XCTAssert(tableB.otherElements.staticTexts["N"].exists)
            XCTAssertEqual(tableB.cells.count, 5)
        }
    }
}
