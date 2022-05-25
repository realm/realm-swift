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

#if os(macOS)
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
import SwiftUI
#endif

class SwiftFlexibleSyncTests: SwiftSyncTestCase {
    override class var defaultTestSuite: XCTestSuite {
        // async/await is currently incompatible with thread sanitizer and will
        // produce many false positives
        // https://bugs.swift.org/browse/SR-15444
        if RLMThreadSanitizerEnabled() {
            return XCTestSuite(name: "\(type(of: self))")
        }
        return super.defaultTestSuite
    }

    func testCreateFlexibleSyncApp() throws {
        let appId = try RealmServer.shared.createAppForSyncMode(.flx(["age"]))
        let flexibleApp = app(fromAppId: appId)
        let user = try logInUser(for: basicCredentials(app: flexibleApp), app: flexibleApp)
        XCTAssertNotNil(user)
    }

    func testGetSubscriptionsWhenLocalRealm() throws {
        let realm = try Realm()
        assertThrows(realm.subscriptions)
    }

    // FIXME: Using `assertThrows` within a Server test will crash on tear down
    func skip_testGetSubscriptionsWhenPbsRealm() throws {
        let user = try logInUser(for: basicCredentials())
        let realm = try openRealm(partitionValue: #function, user: user)
        assertThrows(realm.subscriptions)
    }

    func testOpenFlexibleSyncPath() throws {
        let user = try logInUser(for: basicCredentials(app: flexibleSyncApp), app: flexibleSyncApp)
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try Realm(configuration: configuration)
        XCTAssertTrue(realm.configuration.fileURL!.path.hasSuffix("mongodb-realm/\(flexibleSyncAppId)/\(user.id)/flx_sync_default.realm"))
    }
}

// MARK: - Async Await

#if swift(>=5.6) && canImport(_Concurrency)
@available(macOS 12.0, *)
extension SwiftFlexibleSyncTests {
    @MainActor
    private func populateFlexibleSyncDataForType<T: RealmFetchable>(_ type: T.Type, app: RealmSwift.App? = nil, block: @escaping (Realm) -> Void) async throws {
        let app = app ?? flexibleSyncApp
        let user = try await app.login(credentials: basicCredentials(usernameSuffix: "", app: app))
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try await Realm(configuration: configuration)

        _ = try await realm.objects(type)
        try realm.write {
            block(realm)
        }
        waitForUploads(for: realm)
    }

    @MainActor
    func testFlexibleSyncResults() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }

        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try await Realm(configuration: configuration)
        let persons = try await realm.objects(SwiftPerson.self, where: { $0.age > 18 && $0.firstName == "\(#function)" })
        XCTAssertEqual(realm.subscriptions.count, 1)
        waitForDownloads(for: realm)
        XCTAssertEqual(persons.count, 3)

        // This will trigger a client reset, which will result in the server not responding to any instruction, this is not removing the object from the database.
//        let newPerson = SwiftPerson()
//        newPerson.age = 10
//        try realm.write {
//            realm.add(newPerson)
//        }
//        XCTAssertEqual(persons.count, 3)

        let newPerson = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(19)", age: 19)
        try realm.write {
            realm.add(newPerson)
        }
        XCTAssertEqual(persons.count, 4)

        try await persons.unsubscribe()
        XCTAssertEqual(realm.subscriptions.count, 0)
        waitForDownloads(for: realm)
        waitForUploads(for: realm)
        XCTAssertEqual(persons.count, 0)
    }

    @MainActor
    func testFlexibleSyncResultsForAllCollection() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            realm.deleteAll() // Remove all objects from that type
            for i in 1...9 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }
        try await populateFlexibleSyncDataForType(SwiftDog.self) { realm in
            realm.deleteAll() // Remove all objects from that type
            for _ in 1...8 {
                let dog = SwiftDog(name: "\(#function)", breed: ["bulldog", "poodle", "boxer", "beagle"].randomElement()!)
                realm.add(dog)
            }
        }

        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: self.flexibleSyncApp))
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try await Realm(configuration: configuration)

        let persons = try await realm.objects(SwiftPerson.self)
        let dogs = try await realm.objects(SwiftDog.self)
        waitForDownloads(for: realm)
        XCTAssertEqual(persons.count, 9)
        XCTAssertEqual(dogs.count, 8)
        XCTAssertEqual(realm.subscriptions.count, 2)

        try await persons.unsubscribe()
        try await dogs.unsubscribe()
    }

    @MainActor
    func testFlexibleSyncResultsWithDuplicateQuery() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }

        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try await Realm(configuration: configuration)

        let persons = try await realm.objects(SwiftPerson.self, where: { $0.age > 18 && $0.firstName == "\(#function)" })

        waitForDownloads(for: realm)
        XCTAssertEqual(persons.count, 3)
        let persons2 = try await realm.objects(SwiftPerson.self, where: { $0.age > 18 && $0.firstName == "\(#function)" })
        waitForDownloads(for: realm)
        XCTAssertEqual(persons2.count, 3)

        // The results are pointing to the same subscription, which means the data on both will be the same
        XCTAssertEqual(realm.subscriptions.count, 1)
        XCTAssertEqual(persons.count, persons2.count)

        let newPerson = SwiftPerson(firstName: "\(#function)", lastName: "", age: 19)
        try realm.write {
            realm.add(newPerson)
        }
        XCTAssertEqual(persons.count, 4)
        XCTAssertEqual(persons2.count, 4)
        XCTAssertEqual(persons.count, persons2.count)
        XCTAssertEqual(realm.subscriptions.count, 1)

        try await persons.unsubscribe()
        XCTAssertEqual(realm.subscriptions.count, 0)

        waitForDownloads(for: realm)
        XCTAssertEqual(persons.count, 0)
        XCTAssertEqual(persons2.count, 0)

    }

    @MainActor
    func testFlexibleSyncWithSameType() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }

        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try await Realm(configuration: configuration)

        let personsAge15 = try await realm.objects(SwiftPerson.self, where: { $0.age > 15 && $0.firstName == "\(#function)" })
        let personsAge10 = try await realm.objects(SwiftPerson.self, where: { $0.age > 10 && $0.firstName == "\(#function)" })
        let personsAge5 = try await realm.objects(SwiftPerson.self, where: { $0.age > 5 && $0.firstName == "\(#function)" })
        let personsAge0 = try await realm.objects(SwiftPerson.self, where: { $0.age > 0 && $0.firstName == "\(#function)" })
        waitForDownloads(for: realm)
        XCTAssertEqual(personsAge0.count, 21)
        XCTAssertEqual(personsAge5.count, 16)
        XCTAssertEqual(personsAge10.count, 11)
        XCTAssertEqual(personsAge15.count, 6)
        XCTAssertEqual(realm.subscriptions.count, 4)
    }

    @MainActor
    func testFlexibleSyncSearchSubscription() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }
        try await populateFlexibleSyncDataForType(SwiftDog.self) { realm in
            for _ in 1...15 {
                let dog = SwiftDog(name: "\(#function)", breed: ["bulldog", "poodle", "boxer", "beagle"].randomElement()!)
                realm.add(dog)
            }
        }
        try await populateFlexibleSyncDataForType(Bird.self) { realm in
            for _ in 1...10 {
                let bird = Bird(name: "\(#function)", species: [.magpie, .owl, .penguin, .duck].randomElement()!)
                realm.add(bird)
            }
        }

        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try await Realm(configuration: configuration)

        let persons = try await realm.objects(SwiftPerson.self, where: { $0.age > 12 && $0.firstName == "\(#function)" })
        let dogs = try await realm.objects(SwiftDog.self, where: { $0.breed != "labradoodle" && $0.name == "\(#function)" })
        let birds = try await realm.objects(Bird.self, where: { $0.species.in(BirdSpecies.allCases) && $0.name == "\(#function)" })
        waitForDownloads(for: realm)
        XCTAssertEqual(persons.count, 9)
        XCTAssertEqual(dogs.count, 15)
        XCTAssertEqual(birds.count, 10)
        XCTAssertEqual(realm.subscriptions.count, 3)

        try await realm.subscriptions.unsubscribeAll()
        XCTAssertEqual(persons.count, 0)
        XCTAssertEqual(dogs.count, 0)
        XCTAssertEqual(birds.count, 0)
        XCTAssertEqual(realm.subscriptions.count, 0)
    }

    @MainActor
    func testFlexibleSyncUnsubscribeByType() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }
        try await populateFlexibleSyncDataForType(SwiftDog.self) { realm in
            for _ in 1...15 {
                let dog = SwiftDog(name: "\(#function)", breed: ["bulldog", "poodle", "boxer", "beagle"].randomElement()!)
                realm.add(dog)
            }
        }
        try await populateFlexibleSyncDataForType(Bird.self) { realm in
            for _ in 1...10 {
                let bird = Bird(name: "\(#function)", species: [.magpie, .owl, .penguin, .duck].randomElement()!)
                realm.add(bird)
            }
        }

        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try await Realm(configuration: configuration)

        let personsAge15 = try await realm.objects(SwiftPerson.self, where: { $0.age > 15 && $0.firstName == "\(#function)" })
        let personsAge10 = try await realm.objects(SwiftPerson.self, where: { $0.age > 10 && $0.firstName == "\(#function)" })
        let personsAge5 = try await realm.objects(SwiftPerson.self, where: { $0.age > 5 && $0.firstName == "\(#function)" })
        let personsAge0 = try await realm.objects(SwiftPerson.self, where: { $0.age > 0 && $0.firstName == "\(#function)" })
        let dogs = try await realm.objects(SwiftDog.self, where: { $0.breed != "labradoodle" && $0.name == "\(#function)" })
        let birds = try await realm.objects(Bird.self, where: { $0.species.in(BirdSpecies.allCases) && $0.name == "\(#function)" })
        XCTAssertEqual(personsAge0.count, 21)
        XCTAssertEqual(personsAge5.count, 16)
        XCTAssertEqual(personsAge10.count, 11)
        XCTAssertEqual(personsAge15.count, 6)
        XCTAssertEqual(dogs.count, 15)
        XCTAssertEqual(birds.count, 10)
        XCTAssertEqual(realm.subscriptions.count, 6)

        try await realm.subscriptions.unsubscribeAll(ofType: SwiftPerson.self)
        waitForDownloads(for: realm)
        XCTAssertEqual(personsAge0.count, 0)
        XCTAssertEqual(personsAge5.count, 0)
        XCTAssertEqual(personsAge10.count, 0)
        XCTAssertEqual(personsAge15.count, 0)
        XCTAssertEqual(dogs.count, 15)
        XCTAssertEqual(birds.count, 10)
        XCTAssertEqual(realm.subscriptions.count, 2)
    }

    @MainActor
    func testFlexibleSyncWithDifferentTypes() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }
        try await populateFlexibleSyncDataForType(SwiftDog.self) { realm in
            for _ in 1...15 {
                let dog = SwiftDog(name: "\(#function)", breed: ["bulldog", "poodle", "boxer", "beagle"].randomElement()!)
                realm.add(dog)
            }
        }
        try await populateFlexibleSyncDataForType(Bird.self) { realm in
            for _ in 1...10 {
                let bird = Bird(name: "\(#function)", species: [.magpie, .owl, .penguin, .duck].randomElement()!)
                realm.add(bird)
            }
        }

        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try await Realm(configuration: configuration)

        let persons = try await realm.objects(SwiftPerson.self, where: { $0.age > 12 && $0.firstName == "\(#function)" })
        let dogs = try await realm.objects(SwiftDog.self, where: { $0.breed != "labradoodle" && $0.name == "\(#function)" })
        let birds = try await realm.objects(Bird.self, where: { $0.species.in(BirdSpecies.allCases) && $0.name == "\(#function)" })
        waitForDownloads(for: realm)
        XCTAssertEqual(persons.count, 9)
        XCTAssertEqual(dogs.count, 15)
        XCTAssertEqual(birds.count, 10)
        XCTAssertEqual(realm.subscriptions.count, 3)
    }

    @MainActor
    func testFlexibleSyncUpdateFilter() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }

        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try await Realm(configuration: configuration)

        let personsAge15 = try await realm.objects(SwiftPerson.self, where: { $0.age > 0 && $0.firstName == "\(#function)" })
        waitForDownloads(for: realm)
        XCTAssertEqual(personsAge15.count, 21)
        XCTAssertEqual(realm.subscriptions.count, 1)

        let personsAge10 = try await personsAge15.where { $0.age > 10 && $0.firstName == "\(#function)" }
        waitForDownloads(for: realm)
        XCTAssertEqual(personsAge10.count, 11)
        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    @MainActor
    func testFlexibleSyncQueryThrowsError() async throws {
        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        var configuration = user.flexibleSyncConfiguration()
        configuration.objectTypes = [SwiftPerson.self, SwiftDog.self, Bird.self]
        let realm = try await Realm(configuration: configuration)

        // This throws because the property is not included as a queryable field
        do {
            let _: Results<SwiftDog> = try await realm.objects(SwiftDog.self, where: { $0.gender == .female })
            XCTFail("Querying on a property which is not included as a queryable field should fail")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

#endif // canImport(_Concurrency)
#endif // os(macOS)
