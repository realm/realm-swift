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

import Foundation
import RealmSwift
import XCTest

class PersistedCollections: Object {
    @Persisted public var list: List<CommonPerson>
    @Persisted public var set: MutableSet<CommonPerson>
}

class ProjectedCollections: Projection<PersistedCollections> {
    @Projected(\PersistedCollections.list.projectTo.firstName) var list: ProjectedCollection<String>
    @Projected(\PersistedCollections.set.projectTo.firstName) var set: ProjectedCollection<String>
}

class ProjectedCollectionsTestsTemplate: TestCase {
    // To test some of methods there should be a collection of projections instead of collection of strings
    // set value in subclass
    var collection: ProjectedCollection<String>!

    override func setUp() {
        super.setUp()
        let realm = realmWithTestPath()
        try! realm.write {
            let js = realm.create(CommonPerson.self, value: ["firstName": "John",
                                                             "lastName": "Snow",
                                                             "birthday": Date(timeIntervalSince1970: 10),
                                                             "address": ["Winterfell", "Kingdom in the North"],
                                                             "money": Decimal128("2.22")])
            let dt = realm.create(CommonPerson.self, value: ["firstName": "Daenerys",
                                                             "lastName": "Targaryen",
                                                             "birthday": Date(timeIntervalSince1970: 0),
                                                             "address": ["King's Landing", "Westeros"],
                                                             "money": Decimal128("2.22")])
            let tl = realm.create(CommonPerson.self, value: ["firstName": "Tyrion",
                                                             "lastName": "Lannister",
                                                             "birthday": Date(timeIntervalSince1970: 20),
                                                             "address": ["Casterly Rock", "Westeros"],
                                                             "money": Decimal128("9999.95")])
            js.friends.append(dt)
            js.friends.append(tl)
            dt.friends.append(js)

            realm.create(PersistedCollections.self, value: [[js, dt, tl], [js, dt, tl]])
        }
    }

    override func tearDown() {
        collection = nil
        super.tearDown()
    }

    override class var defaultTestSuite: XCTestSuite {
        // Don't run tests for the base class
        if isEqual(ProjectedCollectionsTestsTemplate.self) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite
    }

    func testCount() {
        XCTAssertEqual(collection.count, 3)
    }

    func testAccess() {
        XCTAssertEqual(collection[0], collection.first)
        XCTAssertEqual(collection[2], collection.last)
        XCTAssertNil(collection.firstIndex(of: "Not tere"))
        XCTAssertNotNil(collection.firstIndex(of: "Daenerys"))
    }

    func testSetValues() {
        let realm = realmWithTestPath()
        try! realm.write {
            collection[0] = "Overwrite"
        }
        XCTAssertEqual(collection.first, "Overwrite")
        let chandedObject = realm.objects(CommonPerson.self).filter("firstName == 'Overwrite'").first
        XCTAssertNotNil(chandedObject)
    }

    func testFreezeThawProjectedCollection() {
        let realm = realmWithTestPath()
        let johnSnow = realm.objects(PersonProjection.self).first!
        let projectedSet = collection.freeze()

        XCTAssertTrue(projectedSet.isFrozen)
        XCTAssertFalse(johnSnow.isFrozen)

        let frosenJohn = johnSnow.freeze()
        let frozenProjectedSet = frosenJohn.firstFriendsName

        XCTAssertTrue(frosenJohn.isFrozen)
        XCTAssertTrue(projectedSet.isFrozen)
        XCTAssertTrue(frozenProjectedSet.isFrozen)
    }

    func testRealm() {
        guard collection.realm != nil else {
            XCTAssertNotNil(collection.realm)
            return
        }
        XCTAssertEqual(collection.realm!.configuration.fileURL, realmWithTestPath().configuration.fileURL)
    }

    func testDescription() {
        XCTAssertEqual(collection.description, "ProjectedCollection<String> {\n\t[0] John\n\t[1] Daenerys\n\t[2] Tyrion\n}")
    }

    func testFilterFormat() {
        XCTAssertNotNil(collection.filter { $0 == "Daenerys" }.first!)
        XCTAssertNil(collection.filter { $0 == "Not There" }.first)
    }

    func testSortWithProperty() {
        XCTAssertEqual("Tyrion", collection.sorted { $0 > $1 }.first!)
        XCTAssertEqual("Daenerys", collection.sorted { $0 > $1 }.last!)
    }

    func testFastEnumeration() {
        XCTAssertGreaterThan(collection.count, 0)
        for element in collection {
            _ = element
        }
    }

    func testObserve() {
        let ex = expectation(description: "initial notification")
        let token = collection.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial(let collection):
                XCTAssertEqual(collection.count, 3)
            case .update:
                XCTFail("Shouldn't happen")
            case .error:
                XCTFail("Shouldn't happen")
            }

            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        // add a second notification and wait for it
        var ex2 = expectation(description: "second initial notification")
        let token2 = collection.observe { _ in
            ex2.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        // make a write and implicitly verify that only the unskipped
        // notification is called (the first would error on .update)
        ex2 = expectation(description: "change notification")
        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.delete(realm.objects(CommonPerson.self))
        try! realm.commitWrite(withoutNotifying: [token])
        waitForExpectations(timeout: 1, handler: nil)

        token.invalidate()
        token2.invalidate()
    }

    func testObserveKeyPathNoChange() {
        let ex = expectation(description: "initial notification")
        let token0 = collection.observe(keyPaths: ["firstName"]) { (changes: RealmCollectionChange) in
            switch changes {
            case .initial(let collection):
                XCTAssertEqual(collection.count, 3)
            case .update:
                XCTFail("update not expected")
            case .error:
                XCTFail("error not expected")
            }
            ex.fulfill()
        }

        dispatchSyncNewThread {
            let realm = self.realmWithTestPath()
            realm.beginWrite()
            let obj = realm.create(CommonPerson.self)
            obj.firstName = "Name"
            try! realm.commitWrite()
        }
        waitForExpectations(timeout: 2, handler: nil)
        token0.invalidate()
    }

    func observeOnQueue<Collection: RealmCollection>(_ collection: Collection) where Collection.Element: Object {
        let sema = DispatchSemaphore(value: 0)
        let token = collection.observe(keyPaths: nil, on: queue) { (changes: RealmCollectionChange) in
            switch changes {
            case .initial(let collection):
                XCTAssertEqual(collection.count, 2)
            case .update(let collection, let deletions, _, _):
                XCTAssertEqual(collection.count, 0)
                XCTAssertEqual(deletions, [0, 1])
            case .error:
                XCTFail("Shouldn't happen")
            }

            sema.signal()
        }
        sema.wait()

        let realm = realmWithTestPath()
        try! realm.write {
            realm.delete(collection)
        }
        sema.wait()

        token.invalidate()
    }

    func testInvalidate() {
        XCTAssertFalse(collection.isInvalidated)
        realmWithTestPath().invalidate()
        XCTAssertTrue(collection.realm == nil || collection.isInvalidated)
    }

    func testIsFrozen() {
        XCTAssertFalse(collection.isFrozen)
        XCTAssertTrue(collection.freeze().isFrozen)
    }

    func testThaw() {
        let frozen = collection.freeze()
        XCTAssertTrue(frozen.isFrozen)

        let frozenRealm = frozen.realm!
        assertThrows(try! frozenRealm.write {}, reason: "Can't perform transactions on a frozen Realm")

        let live = frozen.thaw()
        XCTAssertFalse(live!.isFrozen)

        let liveRealm = live!.realm!
        try! liveRealm.write { liveRealm.delete(liveRealm.objects(PersistedCollections.self)) }
        XCTAssertTrue(live!.isInvalidated)
        XCTAssertFalse(frozen.isEmpty)
        try! liveRealm.write { liveRealm.delete(liveRealm.objects(CommonPerson.self)) }
        XCTAssertFalse(frozen.isInvalidated)
    }

    func testThawFromDifferentThread() {
        let frozen = collection.freeze()
        XCTAssertTrue(frozen.isFrozen)

        dispatchSyncNewThread {
            let live = frozen.thaw()
            XCTAssertFalse(live!.isFrozen)

            let liveRealm = live!.realm!
            try! liveRealm.write { liveRealm.delete(liveRealm.objects(PersistedCollections.self)) }
            XCTAssertTrue(live!.isInvalidated)
            XCTAssertFalse(frozen.isEmpty)
        }
    }

    func testFreezeFromWrongThread() {
        let collection = realmWithTestPath().objects(PersonProjection.self).first!.firstFriendsName
        dispatchSyncNewThread {
            self.assertThrows(collection.freeze(), reason: "Realm accessed from incorrect thread")
        }
    }

    func testAccessFrozenCollectionFromDifferentThread() {
        let frozen = collection.freeze()
        dispatchSyncNewThread {
            XCTAssertTrue(frozen.contains(where: { $0 == "Daenerys" }))
            XCTAssertTrue(frozen.contains(where: { $0 == "Tyrion" }))
        }
    }

    func testObserveFrozenCollection() {
        let frozen = collection.freeze()
        assertThrows(frozen.observe({ _ in }),
                     reason: "Frozen Realms do not change and do not have change notifications.")
    }

    func testFilterFrozenCollection() {
        let frozen = collection.freeze()
        XCTAssertEqual(frozen.filter({ $0 == "Daenerys" }).count, 1)
        XCTAssertNil(frozen.filter({ $0 == "Nothing" }).first)
    }
}

class ProjectedListTests: ProjectedCollectionsTestsTemplate {
    override func setUp() {
        super.setUp()
        let realm = realmWithTestPath()
        try! realm.write {
            let people = realm.objects(CommonPerson.self)
            realm.create(PersistedCollections.self, value: ["list": people])
        }
        collection = realmWithTestPath().objects(ProjectedCollections.self)[0].list
    }
}

class ProjectedSetTests: ProjectedCollectionsTestsTemplate {
    override func setUp() {
        super.setUp()
        let realm = realmWithTestPath()
        try! realm.write {
            let people = realm.objects(CommonPerson.self)
            realm.create(PersistedCollections.self, value: ["set": people])
        }
        collection = realmWithTestPath().objects(ProjectedCollections.self)[0].set
    }
}
