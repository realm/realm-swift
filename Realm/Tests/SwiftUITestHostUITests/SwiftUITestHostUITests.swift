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
    let app = XCUIApplication()

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

    private var tables: XCUIElementQuery {
        if #available(iOS 16.0, *) {
            return app.collectionViews
        } else {
            return app.tables
        }
    }

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
        func addReminder(_ title: String) {
            app.buttons["addReminder"].tap()
            app.textFields["title"].tap()
            app.textFields["title"].tap()
            app.textFields["title"].typeText(title)
            XCTAssertTrue(app.navigationBars.staticTexts[title].waitForExistence(timeout: 1.0))
        }

        addReminder("My Reminder")
        let myReminder = realm.objects(ReminderList.self).first!.reminders.first!
        XCTAssertEqual(myReminder.priority, .low)
        if #available(iOS 16, *) {
            // It doesn't seem to be possible to select an item from the dropdown?
        } else {
            app.buttons["picker"].tap()
            tables.switches["medium"].tap()
            XCTAssertEqual(myReminder.priority, .medium)
        }

        app.navigationBars.buttons.element(boundBy: 0).tap()

        // MARK: Test Move
        addReminder("My Reminder 2")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        addReminder("My Reminder 3")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        addReminder("My Reminder 4")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.first!.title, "My Reminder")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[1].title, "My Reminder 2")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[2].title, "My Reminder 3")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[3].title, "My Reminder 4")

        app.buttons["Edit"].tap()
        app.buttons.matching(identifier: "Reorder").firstMatch.press(forDuration: 0.5, thenDragTo: tables.cells.element(boundBy: 2))

        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.first!.title, "My Reminder 2")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[1].title, "My Reminder 3")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[2].title, "My Reminder")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[3].title, "My Reminder 4")

        app.buttons.matching(identifier: "Reorder").element(boundBy: 2).press(forDuration: 0.5, thenDragTo: tables.cells.element(boundBy: 0))

        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.first!.title, "My Reminder")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[1].title, "My Reminder 2")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[2].title, "My Reminder 3")
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders[3].title, "My Reminder 4")

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
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.count, 4)
        delete()
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.count, 3)
        delete()
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.count, 2)
        delete()
        XCTAssertEqual(realm.objects(ReminderList.self).first!.reminders.count, 1)

        if #available(iOS 16.0, *) {
            app.buttons["Done"].tap()
        }

        app.navigationBars.buttons.firstMatch.tap()
        tables.cells.firstMatch.swipeLeft()
        app.buttons.matching(identifier: "Delete").firstMatch.tap()
        XCTAssertEqual(realm.objects(ReminderList.self).count, 0)
    }

    func testNSPredicateObservedResults() throws {
        app.launch()
        try observedResultsQueryTest()
    }

    func testSwiftQueryObservedResults() throws {
        app.launchEnvironment["query_type"] = "type_safe_query"
        app.launch()
        try observedResultsQueryTest()
    }

    private func observedResultsQueryTest() throws {
        let addButton = app.buttons["addList"]
        (1...20).forEach { _ in
            addButton.tap()
        }

        // Name every reminders list for search
        try realm.write {
            for (index, obj) in (realm.objects(ReminderList.self)).enumerated() {
                obj.name = "reminder list \(index)"
            }
        }

        let searchBar = app.textFields["searchField"]
        let table = tables.firstMatch

        searchBar.tap()

        searchBar.typeText("reminder list 1\n") // \n to dismiss keyboard
        XCTAssertEqual(table.cells.count, 9)
    }

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

    func testUpdateResultsWithSearchable() {
        app.launchEnvironment["test_type"] = "observed_results_searchable"
        app.launch()
        let addButton = app.buttons["addList"]
        // iOS 16 lazily-loads only the required number of cells. 13 happens to
        // fit on-screen.
        (1...13).forEach { _ in
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
        XCTAssertEqual(table.cells.count, 12)

        let searchBar = app.searchFields.firstMatch
        searchBar.tap()

        searchBar.typeText("reminder")
        XCTAssertEqual(table.cells.count, 13)

        searchBar.typeText(" list 1")
        XCTAssertEqual(table.cells.count, 4)

        searchBar.typeText("2")
        XCTAssertEqual(table.cells.count, 1)

        searchBar.typeText("4")
        XCTAssertEqual(table.cells.count, 0)

        clearSearchBar()
        app.navigationBars["Reminders"].buttons["Cancel"].tap()
        XCTAssertEqual(table.cells.count, 12)

        searchBar.tap()
        searchBar.typeText("2")
        XCTAssertEqual(table.cells.count, 2)

        clearSearchBar()
        searchBar.typeText("11")
        XCTAssertEqual(table.cells.count, 1)
    }

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
        XCTAssert(app.collectionViews.firstMatch.otherElements.staticTexts["N"].exists)
        let cell0 = app.collectionViews.firstMatch.cells.element(boundBy: 1)
        let cell1 = app.collectionViews.firstMatch.cells.element(boundBy: 2)
        XCTAssert(cell0.staticTexts["New List"].exists)
        XCTAssert(cell1.staticTexts["New List"].exists)
        XCTAssertEqual(realm.objects(ReminderList.self).count, 2)
        // The section title is now a cell within the collection view
        XCTAssertEqual(app.collectionViews.firstMatch.cells.count, 3)

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
        XCTAssert(app.collectionViews.otherElements.staticTexts["A"].exists)
        XCTAssert(app.collectionViews.otherElements.staticTexts["c"].exists)
        XCTAssert(cell0.staticTexts["Another List"].exists)
        let cell2 = app.collectionViews.cells.element(boundBy: 3)
        let cell3 = app.collectionViews.cells.element(boundBy: 4)
        XCTAssert(cell2.staticTexts["changed"].exists)
        XCTAssert(cell3.staticTexts["changed"].exists)
        XCTAssertEqual(realm.objects(ReminderList.self).count, 3)
        XCTAssertEqual(app.collectionViews.firstMatch.cells.count, 5)
    }

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
        XCTAssert(app.collectionViews.firstMatch.otherElements.staticTexts["N"].exists)
        let cell0 = app.collectionViews.firstMatch.cells.element(boundBy: 1)
        let cell1 = app.collectionViews.firstMatch.cells.element(boundBy: 2)
        XCTAssert(cell0.staticTexts["New List"].exists)
        XCTAssert(cell1.staticTexts["New List"].exists)
        XCTAssertEqual(realm.objects(ReminderList.self).count, 2)
        XCTAssertEqual(app.collectionViews.firstMatch.cells.count, 3)

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
        XCTAssert(app.collectionViews.otherElements.staticTexts["A"].exists)
        XCTAssert(app.collectionViews.otherElements.staticTexts["c"].exists)
        XCTAssert(cell0.staticTexts["Another List"].exists)
        let cell2 = app.collectionViews.cells.element(boundBy: 3)
        let cell3 = app.collectionViews.cells.element(boundBy: 4)
        XCTAssert(cell2.staticTexts["changed"].exists)
        XCTAssert(cell3.staticTexts["changed"].exists)
        XCTAssertEqual(realm.objects(ReminderList.self).count, 3)
        XCTAssertEqual(app.collectionViews.firstMatch.cells.count, 5)
    }

    func testUpdateObservedSectionedResultsWithSearchable() {
        app.launchEnvironment["test_type"] = "observed_sectioned_results_searchable"
        app.launch()

        let addButton = app.buttons["addList"]
        (1...20).forEach { _ in
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

        let table = app.collectionViews.firstMatch

        // Observed Results filter, should filter reminders without name.
        XCTAssertEqual(table.cells.count, 12)

        let searchBar = app.searchFields.firstMatch
        searchBar.tap()

        searchBar.typeText("reminder")
        XCTAssertEqual(table.cells.count, 14)
        XCTAssert(app.collectionViews.otherElements.staticTexts["r"].exists)

        searchBar.typeText(" list 1")
        XCTAssertEqual(table.cells.count, 12)

        searchBar.typeText("8")
        XCTAssertEqual(table.cells.count, 2)

        searchBar.typeText("9")
        XCTAssertEqual(table.cells.count, 0)

        clearSearchBar()
        app.buttons["Cancel"].tap()
        XCTAssertEqual(table.cells.count, 12)

        searchBar.tap()
        searchBar.typeText("5")
        XCTAssertEqual(table.cells.count, 3)

        clearSearchBar()
        searchBar.typeText("12")
        XCTAssertEqual(table.cells.count, 2)
    }

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

        let tableA = app.collectionViews["ListA"]
        XCTAssert(tableA.otherElements.staticTexts["N"].exists)
        XCTAssertEqual(tableA.cells.count, 6)

        let tableB = app.collectionViews["ListB"]
        XCTAssert(tableB.otherElements.staticTexts["N"].exists)
        XCTAssertEqual(tableB.cells.count, 6)
    }
}
