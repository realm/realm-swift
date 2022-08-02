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
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))
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
        let configuration = Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self])
        let realm = try user.realm(configuration: configuration)

        _ = try await realm.subscriptions.subscribe(to: type)

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
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))
        let persons: QueryResults<SwiftPerson> = try await realm.subscriptions.subscribe(to: { $0.age > 18 && $0.firstName == "\(#function)" })
        waitForDownloads(for: realm)
        XCTAssertEqual(persons.count, 3)

        // This will trigger a client reset, which will result in the server not responding to any instruction, this is not removing the object from the database.
//        let newPerson = SwiftPerson()
//        newPerson.age = 10
//        try realm.write {
//            realm.add(newPerson)
//        }
//        XCTAssertEqual(persons.count, 3)

        let newPerson = SwiftPerson(firstName: "\(#function)", lastName: "", age: 19)
        try realm.write {
            realm.add(newPerson)
        }
        XCTAssertEqual(persons.count, 4)

        try await persons.unsubscribe()
        waitForDownloads(for: realm)
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
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let (persons, dogs) = try await realm.subscriptions.subscribe(to: QuerySubscription<SwiftPerson>(), QuerySubscription<SwiftDog>())
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
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let persons: QueryResults<SwiftPerson> = try await realm.subscriptions.subscribe(to: { $0.age > 18 && $0.firstName == "\(#function)" })
        waitForDownloads(for: realm)
        XCTAssertEqual(persons.count, 3)
        let persons2: QueryResults<SwiftPerson> = try await realm.subscriptions.subscribe(to: { $0.age > 18 && $0.firstName == "\(#function)" })
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
        waitForDownloads(for: realm)
        XCTAssertEqual(persons.count, 0)
        XCTAssertEqual(persons2.count, 0)
        XCTAssertEqual(realm.subscriptions.count, 0)
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
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let (personsAge15, personsAge10, personsAge5, personsAge0) = try await realm.subscriptions.subscribe(to: QuerySubscription<SwiftPerson> { $0.age > 15 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftPerson> { $0.age > 10 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftPerson> { $0.age > 5 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftPerson> { $0.age >= 0 && $0.firstName == "\(#function)" })
        waitForDownloads(for: realm)
        XCTAssertEqual(personsAge0.count, 21)
        XCTAssertEqual(personsAge5.count, 16)
        XCTAssertEqual(personsAge10.count, 11)
        XCTAssertEqual(personsAge15.count, 6)
        XCTAssertEqual(realm.subscriptions.count, 4)

        try await realm.subscriptions.unsubscribeAll(ofType: SwiftPerson.self)
        waitForDownloads(for: realm)
        XCTAssertEqual(personsAge0.count, 0)
        XCTAssertEqual(personsAge5.count, 0)
        XCTAssertEqual(personsAge10.count, 0)
        XCTAssertEqual(personsAge15.count, 0)
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
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let (personsAge15, personsAge10, personsAge5, personsAge0, dogs, birds) = try await realm.subscriptions.subscribe(to: QuerySubscription<SwiftPerson> { $0.age > 15 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftPerson> { $0.age > 10 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftPerson> { $0.age > 5 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftPerson> { $0.age >= 0 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftDog> { $0.breed != "labradoodle" && $0.name == "\(#function)" }, QuerySubscription<Bird> { $0.species.in(BirdSpecies.allCases) && $0.name == "\(#function)" })
        waitForDownloads(for: realm)
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
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let (persons, dogs, birds) = try await realm.subscriptions.subscribe(to: QuerySubscription<SwiftPerson> { $0.age > 12 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftDog> { $0.breed != "labradoodle" && $0.name == "\(#function)" }, QuerySubscription<Bird> { $0.species.in(BirdSpecies.allCases) && $0.name == "\(#function)" })
        waitForDownloads(for: realm)
        XCTAssertEqual(persons.count, 9)
        XCTAssertEqual(dogs.count, 15)
        XCTAssertEqual(birds.count, 10)
        XCTAssertEqual(realm.subscriptions.count, 3)
    }

    @MainActor
    func testFlexibleSyncSearchSubscription() async throws {
        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let (_, _, _) = try await realm.subscriptions.subscribe(to: QuerySubscription<SwiftPerson> { $0.age > 12 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftDog> { $0.breed != "labradoodle" && $0.name == "\(#function)" }, QuerySubscription<Bird> { $0.species.in(BirdSpecies.allCases) && $0.name == "\(#function)" })
        XCTAssertEqual(realm.subscriptions.count, 3)

        let foundedSubscription = realm.subscriptions.first(ofType: SwiftPerson.self, where: { $0.age > 12 && $0.firstName == "\(#function)" })
        XCTAssertNotNil(foundedSubscription)
        try await foundedSubscription!.unsubscribe()
        XCTAssertEqual(realm.subscriptions.count, 2)

        try await realm.subscriptions.unsubscribeAll()
        XCTAssertEqual(realm.subscriptions.count, 0)

        let notFoundedSubscription = realm.subscriptions.first(ofType: SwiftDog.self, where: { $0.breed != "labradoodle" && $0.name == "\(#function)" })
        XCTAssertNil(notFoundedSubscription)
    }

    @MainActor
    func testFlexibleSyncMaxResults() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }
        try await populateFlexibleSyncDataForType(SwiftDog.self) { realm in
            for _ in 1...21 {
                let dog = SwiftDog(name: "\(#function)", breed: ["bulldog", "poodle", "boxer", "beagle"].randomElement()!)
                realm.add(dog)
            }
        }
        try await populateFlexibleSyncDataForType(Bird.self) { realm in
            for _ in 1...21 {
                let bird = Bird(name: "\(#function)", species: [.magpie, .owl, .penguin, .duck].randomElement()!)
                realm.add(bird)
            }
        }

        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let (personsAge15, dogsBulldog, birdsMagpie, personsAge10, dogsPoodle, birdsOwl, personsAge5, dogsBoxer, birdsPenguin, personsAge0, dogsBeagle, birdsDuck) = try await realm.subscriptions.subscribe(to: QuerySubscription<SwiftPerson> { $0.age > 15 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftDog> { $0.breed == "bulldog" && $0.name == "\(#function)" }, QuerySubscription<Bird> { $0.species == .magpie && $0.name == "\(#function)" }, QuerySubscription<SwiftPerson> { $0.age > 10 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftDog> { $0.breed == "poodle" && $0.name == "\(#function)" }, QuerySubscription<Bird> { $0.species == .owl && $0.name == "\(#function)" }, QuerySubscription<SwiftPerson> { $0.age > 5 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftDog> { $0.breed == "boxer" && $0.name == "\(#function)" }, QuerySubscription<Bird> { $0.species == .penguin && $0.name == "\(#function)" }, QuerySubscription<SwiftPerson> { $0.age >= 0 && $0.firstName == "\(#function)" }, QuerySubscription<SwiftDog> { $0.breed == "beagle" && $0.name == "\(#function)" }, QuerySubscription<Bird> { $0.species == .duck && $0.name == "\(#function)" })
        waitForDownloads(for: realm)
        XCTAssertEqual(realm.subscriptions.count, 12)
        XCTAssertEqual(personsAge0.count, 21)
        XCTAssertEqual(personsAge5.count, 16)
        XCTAssertEqual(personsAge10.count, 11)
        XCTAssertEqual(personsAge15.count, 6)

        XCTAssertEqual(dogsBulldog.count + dogsPoodle.count + dogsBoxer.count + dogsBeagle.count, 21)
        XCTAssertEqual(birdsMagpie.count + birdsOwl.count + birdsPenguin.count + birdsDuck.count, 21)

        let newPerson = SwiftPerson(firstName: "\(#function)", lastName: "", age: 8)
        try realm.write {
            realm.add(newPerson)
        }

        XCTAssertEqual(personsAge0.count, 22)
        XCTAssertEqual(personsAge5.count, 17)
        XCTAssertEqual(personsAge10.count, 11)
        XCTAssertEqual(personsAge15.count, 6)

        let previousBullDogsCount = dogsBulldog.count
        let newDog = SwiftDog(name: "\(#function)", breed: "bulldog")
        try realm.write {
            realm.add(newDog)
        }

        XCTAssertEqual(previousBullDogsCount + 1, dogsBulldog.count)

        try await dogsBulldog.unsubscribe()
        waitForDownloads(for: realm)
        XCTAssertEqual(dogsBulldog.count, 0)

        try await realm.subscriptions.unsubscribeAll()
        waitForDownloads(for: realm)
        XCTAssertEqual(realm.subscriptions.count, 0)
        XCTAssertEqual(personsAge0.count, 0)
        XCTAssertEqual(personsAge5.count, 0)
        XCTAssertEqual(personsAge10.count, 0)
        XCTAssertEqual(personsAge15.count, 0)
        XCTAssertEqual(dogsBulldog.count, 0)
        XCTAssertEqual(dogsPoodle.count, 0)
        XCTAssertEqual(dogsBoxer.count, 0)
        XCTAssertEqual(dogsBeagle.count, 0)
        XCTAssertEqual(birdsMagpie.count, 0)
        XCTAssertEqual(birdsOwl.count, 0)
        XCTAssertEqual(birdsPenguin.count, 0)
        XCTAssertEqual(birdsDuck.count, 0)
    }

    @MainActor
    func testFlexibleSyncQueryThrowsError() async throws {
        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        // This throws because the property is not included as a queryable field
        do {
            let _: QueryResults<SwiftDog> = try await realm.subscriptions.subscribe(to: { $0.gender == .female })
            XCTFail("Querying on a property which is not included as a queryable field should fail")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    @MainActor
    func testFlexibleSyncSubscriptionSetIterate() async throws {
        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let numberOfSubs = 25
        for i in 1...numberOfSubs {
            let _: QueryResults<SwiftPerson> = try await realm.subscriptions.subscribe(to: { $0.age > i })
        }
        XCTAssertEqual(realm.subscriptions.count, numberOfSubs)

        var count = 0
        for (index, subscription) in realm.subscriptions.enumerated() {
            XCTAssertNotNil(subscription)
            XCTAssertEqual(subscription.query, "age > \(index + 1)")
            XCTAssertTrue((Calendar.current.date(byAdding: DateComponents(hour: -1), to: Date())!...Date()).contains(subscription.createdAt))
            count += 1
        }

        XCTAssertEqual(count, numberOfSubs)
    }

    @MainActor
    func testFlexibleSyncSubscriptionSetFirstAndLast() async throws {
        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let numberOfSubs = 10
        for i in 1...numberOfSubs {
            let _: QueryResults<SwiftPerson> = try await realm.subscriptions.subscribe(to: { $0.age > i })
        }
        XCTAssertEqual(realm.subscriptions.count, numberOfSubs)

        let firstQueryResult = realm.subscriptions.first
        XCTAssertTrue((Calendar.current.date(byAdding: DateComponents(hour: -1), to: Date())!...Date()).contains(firstQueryResult!.createdAt))
        XCTAssertEqual(firstQueryResult!.query, "age > 1")

        let lastQueryResult = realm.subscriptions.last
        XCTAssertTrue((Calendar.current.date(byAdding: DateComponents(hour: -1), to: Date())!...Date()).contains(lastQueryResult!.createdAt))
        XCTAssertEqual(lastQueryResult!.query, "age > 10")
    }

    @MainActor
    func testFlexibleSyncSubscriptionSetSubscript() async throws {
        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let numberOfSubs = 5
        for i in 1...numberOfSubs {
            let _: QueryResults<SwiftPerson> = try await realm.subscriptions.subscribe(to: { $0.age > i })
        }
        XCTAssertEqual(realm.subscriptions.count, numberOfSubs)


        let firstQueryResult = realm.subscriptions[0]
        XCTAssertTrue((Calendar.current.date(byAdding: DateComponents(hour: -1), to: Date())!...Date()).contains(firstQueryResult!.createdAt))
        XCTAssertEqual(firstQueryResult!.query, "age > 1")

        let lastQueryResult = realm.subscriptions[numberOfSubs-1]
        XCTAssertTrue((Calendar.current.date(byAdding: DateComponents(hour: -1), to: Date())!...Date()).contains(lastQueryResult!.createdAt))
        XCTAssertEqual(lastQueryResult!.query, "age > 5")
    }

    @MainActor
    func testFlexibleSyncAnyQueryResultsUnsubscribe() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }
        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let numberOfSubs = 10
        for i in 1...numberOfSubs {
            let _: QueryResults<SwiftPerson> = try await realm.subscriptions.subscribe(to: { $0.age > i })
        }
        let _: QueryResults<SwiftDog> = try await realm.subscriptions.subscribe(to: { $0.breed == "poodle" })
        XCTAssertEqual(realm.subscriptions.count, numberOfSubs+1)

        let subs = realm.subscriptions.filter { $0.query.contains("age") }
        for sub in subs {
            try await sub.unsubscribe()
        }

        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    @MainActor
    func testFlexibleSyncAnyQueryResultsCast() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...21 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }
        let user = try await self.flexibleSyncApp.login(credentials: basicCredentials(usernameSuffix: "", app: flexibleSyncApp))
        let realm = try user.realm(configuration: Realm.Configuration(objectTypes: [SwiftPerson.self, SwiftDog.self, Bird.self]))

        let originalPersons: QueryResults<SwiftPerson> = try await realm.subscriptions.subscribe(to: { $0.age > 15 && $0.firstName == "\(#function)"})
        waitForDownloads(for: realm)
        XCTAssertEqual(realm.subscriptions.count, 1)
        XCTAssertEqual(originalPersons.count, 6)

        let anyQueryResults = realm.subscriptions[0]
        XCTAssertTrue((Calendar.current.date(byAdding: DateComponents(hour: -1), to: Date())!...Date()).contains(anyQueryResults!.createdAt))
        XCTAssertEqual(anyQueryResults!.query, "age > 15 and firstName == \"\(#function)\"")

        let persons = anyQueryResults?.as(type: SwiftPerson.self)
        XCTAssertNotNil(persons)
        XCTAssertEqual(persons!.count, 6)

        let notPersons = anyQueryResults?.as(type: SwiftDog.self)
        XCTAssertNil(notPersons)

        try await anyQueryResults!.unsubscribe()
        waitForDownloads(for: realm)
        XCTAssertEqual(originalPersons.count, 0)
        XCTAssertEqual(persons!.count, 0)
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsAsync() async throws {
        try await populateFlexibleSyncDataForType(SwiftPerson.self) { realm in
            for i in 1...20 {
                let person = SwiftPerson(firstName: "\(#function)", lastName: "lastname_\(i)", age: i)
                realm.add(person)
            }
        }

        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(ofType: SwiftPerson.self,
                                 where: { $0.age > 10 && $0.firstName == "\(#function)" })
        })

        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self]
        }
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm)

        XCTAssertEqual(realm.subscriptions.count, 1)
        // Adding this sleep, because there seems to be a timing issue after this commit in baas
        // https://github.com/10gen/baas/commit/64e75b3f1fe8a6f8704d1597de60f9dda401ccce,
        // data take a little longer to be downloaded to the realm even though the
        // sync client changed the subscription state to completed.
        sleep(1)
        checkCount(expected: 10, realm, SwiftPerson.self)
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsNotRerunOnOpen() async throws {
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(ofType: SwiftPerson.self,
                                 where: { $0.age > 10 && $0.firstName == "\(#function)" })
        })

        if config.objectTypes == nil {
            config.objectTypes = [SwiftPerson.self]
        }
        let realm = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm)
        XCTAssertEqual(realm.subscriptions.count, 1)

        let realm2 = try await Realm(configuration: config, downloadBeforeOpen: .once)
        XCTAssertNotNil(realm2)
        XCTAssertEqual(realm.subscriptions.count, 1)
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsRerunOnOpen() async throws {
        try await populateFlexibleSyncDataForType(SwiftTypesSyncObject.self) { realm in
            for i in 1...30 {
                let object = SwiftTypesSyncObject()
                object.dateCol = Calendar.current.date(
                    byAdding: .hour,
                    value: -i,
                    to: Date())!
                realm.add(object)
            }
        }

        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var isFirstOpen = true
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(ofType: SwiftTypesSyncObject.self,
                                 where: {
                let date = isFirstOpen ? Calendar.current.date(
                    byAdding: .hour,
                    value: -10,
                    to: Date()) : Calendar.current.date(
                        byAdding: .hour,
                        value: -20,
                        to: Date())
                isFirstOpen = false
                return $0.dateCol < Date() && $0.dateCol > date! })
        }, rerunOnOpen: true)

        if config.objectTypes == nil {
            config.objectTypes = [SwiftTypesSyncObject.self, SwiftPerson.self]
        }
        let c = config
        _ = try await Task { @MainActor in
            let realm = try await Realm(configuration: c, downloadBeforeOpen: .always)
            XCTAssertNotNil(realm)
            XCTAssertEqual(realm.subscriptions.count, 1)
            // Adding this sleep, because there seems to be a timing issue after this commit in baas
            // https://github.com/10gen/baas/commit/64e75b3f1fe8a6f8704d1597de60f9dda401ccce,
            // data take a little longer to be downloaded to the realm even though the
            // sync client changed the subscription state to completed.
            sleep(1)
            checkCount(expected: 9, realm, SwiftTypesSyncObject.self)
        }.value

        _ = try await Task { @MainActor in
            let realm = try await Realm(configuration: c, downloadBeforeOpen: .always)
            XCTAssertNotNil(realm)
            XCTAssertEqual(realm.subscriptions.count, 2)
            checkCount(expected: 19, realm, SwiftTypesSyncObject.self)
        }.value
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsThrows() async throws {
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(ofType: SwiftTypesSyncObject.self,
                                 where: { $0.uuidCol == UUID() })
        })

        if config.objectTypes == nil {
            config.objectTypes = [SwiftTypesSyncObject.self, SwiftPerson.self]
        }
        do {
           _ = try await Realm(configuration: config, downloadBeforeOpen: .once)
        } catch {
            XCTAssertNotNil(error)
            let nsError = error as NSError
            XCTAssertEqual(nsError.code, 2)
            XCTAssertEqual(nsError.domain, "io.realm.sync.flx")
        }
    }

    @MainActor
    func testFlexibleSyncInitialSubscriptionsDefaultConfiguration() async throws {
        let user = try await logInUser(for: basicCredentials(app: self.flexibleSyncApp), app: self.flexibleSyncApp)
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subscriptions in
            subscriptions.append(ofType: SwiftTypesSyncObject.self)
        })

        if config.objectTypes == nil {
            config.objectTypes = [SwiftTypesSyncObject.self, SwiftPerson.self]
        }
        Realm.Configuration.defaultConfiguration = config

        let realm = try await Realm(downloadBeforeOpen: .once)
        XCTAssertEqual(realm.subscriptions.count, 1)
    }
}

#endif // canImport(_Concurrency)
#endif // os(macOS)
