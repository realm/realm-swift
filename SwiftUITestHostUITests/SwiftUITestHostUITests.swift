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

class Dog: EmbeddedObject, ObjectKeyIdentifiable {
    @objc dynamic var name = ""

    public static func ==(lhs: Dog, rhs: Dog) -> Bool {
        return lhs.isSameObject(as: rhs)
    }
}

class Person: Object, ObjectKeyIdentifiable {
    /// The name of the person
    @objc dynamic var name = ""
    /// The dogs this person has
    var dogs = RealmSwift.List<Dog>()
}

class SwiftUITests: XCTestCase {
    var realm: Realm!
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false

        // the realm must be created before app launch otherwise we will not have
        // write permissions
        let realmPath = URL(string: "\(FileManager.default.temporaryDirectory)\(UUID())")!
        let configuration = Realm.Configuration(fileURL: realmPath)
        self.realm = try! Realm(configuration: configuration)

        app.launchEnvironment = [
            "REALM_PATH": realmPath.absoluteString
        ]
        app.launch()

        try realm.write {
            realm.deleteAll()
        }
        realm.schema.objectSchema.forEach {
            print($0.className)
        }
    }

    override func tearDownWithError() throws {
        app.terminate()
        self.realm.invalidate()
        let config = realm.configuration
        self.realm = nil
        XCTAssert(try Realm.deleteFiles(for: config))
    }

    private func deleteString(for string: String) -> String {
        String(repeating: XCUIKeyboardKey.delete.rawValue, count: string.count)
    }

    func testSampleApp() throws {
        // assert realm is empty
        XCTAssertEqual(realm.objects(Person.self).count, 0)

        // add 3 persons, and assert that they have been added to
        // the UI and Realm
        let addButton = app.buttons["addPerson"]
        addButton.click()
        addButton.click()
        addButton.click()
        XCTAssertEqual(realm.objects(Person.self).count, 3)
        XCTAssertEqual(app.tables.firstMatch.cells.count, 3)

        // delete each person, operating from the zeroeth index
        for _ in 0..<app.tables.firstMatch.cells.count {
            let row = app.tables.firstMatch.cells.element(boundBy: 0)
            row.tap()
            app.buttons["deletePerson"].tap()
        }

        XCTAssertEqual(realm.objects(Person.self).count, 0)
        XCTAssertEqual(app.tables.firstMatch.cells.count, 0)

        // add another person, and tap into the PersonDetailView
        addButton.tap()
        XCTAssertEqual(app.tables.firstMatch.cells.count, 1)
        XCTAssertEqual(realm.objects(Person.self).count, 1)
        app.tables.firstMatch.cells.element(boundBy: 0).tap()

        // add 2 dogs
        app.buttons["addDog"].click()
        let firstDogTf = app.textFields[realm.objects(Person.self)[0].dogs[0].name]
        XCTAssertEqual(firstDogTf.value as? String, realm.objects(Person.self)[0].dogs[0].name)
        app.buttons["addDog"].click()
        let secondDogTf = app.textFields[realm.objects(Person.self)[0].dogs[1].name]

        XCTAssertEqual(secondDogTf.value as? String, realm.objects(Person.self)[0].dogs[1].name)
        XCTAssertEqual(realm.objects(Person.self)[0].dogs.count, 2)

        // test moving elements on a list
        let initialDogName = firstDogTf.value
        secondDogTf.click(forDuration: 0.5, thenDragTo: firstDogTf)
        XCTAssertEqual(initialDogName as? String, realm.objects(Person.self)[0].dogs[1].name)

        firstDogTf.click(forDuration: 0.5, thenDragTo: secondDogTf)
        XCTAssertEqual(initialDogName as? String, realm.objects(Person.self)[0].dogs[0].name)

        // change name of person
        let personNameTextField = app.textFields["personName"]
        personNameTextField.tap()
        personNameTextField.typeText(deleteString(for: personNameTextField.value as! String))
        XCTAssertEqual(realm.objects(Person.self)[0].name, "")
        personNameTextField.typeText("Test Person")
        XCTAssertEqual(realm.objects(Person.self)[0].name, "Test Person")
    }
}
