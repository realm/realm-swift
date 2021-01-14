//
//  SwiftUITests.swift
//  SwiftUITests
//
//  Created by Jason Flax on 13/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

import XCTest
import RealmSwift
import SwiftUI

// MARK: Dog Model
class Dog: EmbeddedObject, ObjectKeyIdentifiable {
    @objc dynamic var name = ""

    public static func ==(lhs: Dog, rhs: Dog) -> Bool {
        return lhs.isSameObject(as: rhs)
    }

    let handlers = LinkingObjects(fromType: Person.self, property: "dogs")
}

// MARK: Person Model
public class Person: Object, ObjectKeyIdentifiable {
    /// The name of the person
    @objc dynamic var name = ""
    /// The dogs this person has
    var dogs = RealmSwift.List<Dog>()
}

class SwiftUITests: XCTestCase {
    var realmPath: String?
    var realm: Realm!
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        // fetch realm path. ui tests are run separately to the actual
        // app, so we have to fetch the path in this awkward way
        self.realm = try! Realm(configuration: Realm.Configuration(fileURL: URL(string: app.staticTexts["realmPath"].label)!))
        try! realm.write { realm.deleteAll() }
    }

    override func tearDownWithError() throws {
    }

    private func deleteString(for string: String) -> String {
        String(repeating: XCUIKeyboardKey.delete.rawValue, count: string.count)
    }

    func testSampleApp() throws {
        // assert realm is empty
        XCTAssertEqual(realm.objects(Person.self).count, 0)

        // add 3 persons, and assert that they have been added to
        // the UI and Realm
        let addButton = app.buttons["Add"]
        addButton.tap()
        addButton.tap()
        addButton.tap()
        XCTAssertEqual(realm.objects(Person.self).count, 3)
        XCTAssertEqual(app.tables.firstMatch.cells.count, 3)

        // delete each person, operating from the zeroeth index
        for _ in 0..<app.tables.firstMatch.cells.count {
            let row = app.tables.firstMatch.cells.element(boundBy: 0)
            row.swipeLeft()
            row.buttons["Delete"].tap()
        }
        XCTAssertEqual(realm.objects(Person.self).count, 0)
        XCTAssertEqual(app.tables.firstMatch.cells.count, 0)

        // add another person, and tap into the PersonDetailView
        addButton.tap()
        XCTAssertEqual(app.tables.firstMatch.cells.count, 1)
        XCTAssertEqual(realm.objects(Person.self).count, 1)
        app.tables.firstMatch.cells.element(boundBy: 0).tap()

        // add 2 dogs
        app.buttons["Add Dog"].tap()
        XCTAssertEqual(app.tables.firstMatch.cells.count, 1)
        app.buttons["Add Dog"].tap()
        XCTAssertEqual(app.tables.firstMatch.cells.count, 2)
        XCTAssertEqual(realm.objects(Person.self)[0].dogs.count, 2)

        // change the name of the first dog
        let dogCell = app.tables.firstMatch.cells.element(boundBy: 0)
        let dogName = dogCell.textFields.element(boundBy: 0)
        XCTAssert(dogName.exists)
        let initialDogName = dogName.value
        dogName.tap()
        dogName.typeText(deleteString(for: dogName.value as! String))
        XCTAssertEqual(realm.objects(Person.self)[0].dogs[0].name, "")
        dogName.typeText("Test Dog")
        XCTAssertEqual(dogName.value as! String, "Test Dog")
        XCTAssertEqual(realm.objects(Person.self)[0].dogs[0].name, "Test Dog")
        XCTAssertNotEqual(dogName.value as! String, initialDogName as! String)

        // remove dog from list
        dogCell.swipeLeft()
        dogCell.buttons["Delete"].tap()
        XCTAssertEqual(realm.objects(Person.self)[0].dogs.count, 1)

        // change name of person
        let personNameTextField = app.textFields["personName"]
        personNameTextField.tap()
        personNameTextField.typeText(deleteString(for: personNameTextField.value as! String))
        XCTAssertEqual(realm.objects(Person.self)[0].name, "")
        personNameTextField.typeText("Test Person")
        XCTAssertEqual(realm.objects(Person.self)[0].name, "Test Person")
    }
}
