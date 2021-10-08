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
import Realm
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmTestSupport
import SwiftUI
#endif

class ProjectedListTests: TestCase {
    
    lazy var collection: ProjectedList<String>! = {
        // To test some of methods there should be a collection of projections instead of collection of strings
        realmWithTestPath().objects(PersonProjection.self).first!.firstFriendsName
    }()
    
    override func setUp() {
        super.setUp()
        let realm = realmWithTestPath()
        try! realm.write {
            let js = realm.create(Person.self, value: ["firstName": "John",
                                                       "lastName": "Snow",
                                                       "birthday": Date(timeIntervalSince1970: 10),
                                                       "address": ["Winterfell", "Kingdom in the North"],
                                                       "money": Decimal128("2.22")])
            let dt = realm.create(Person.self, value: ["firstName": "Daenerys",
                                                       "lastName": "Targaryen",
                                                       "birthday": Date(timeIntervalSince1970: 0),
                                                       "address": ["King's Landing", "Westeros"],
                                                       "money": Decimal128("2.22")])
            let tl = realm.create(Person.self, value: ["firstName": "Tyrion",
                                                       "lastName": "Lannister",
                                                       "birthday": Date(timeIntervalSince1970: 20),
                                                       "address": ["Casterly Rock", "Westeros"],
                                                       "money": Decimal128("9999.95")])
            js.friends.append(dt)
            js.friends.append(tl)
            dt.friends.append(js)
        }
    }
    
    override func tearDown() {
        collection = nil
        super.tearDown()
    }
    
    func testCount() {
        XCTAssertEqual(collection.count, 2)
    }
    
    func testAccess() {
        XCTAssertEqual(collection[0], "Daenerys")
        XCTAssertEqual(collection.first, "Daenerys")
        XCTAssertEqual(collection.last, "Tyrion")
        XCTAssertNil(collection.index(of:"Not tere"))
        XCTAssertEqual(0, collection.index(of:"Daenerys"))
    }
    
    func testSetValues() {
        let realm = realmWithTestPath()
        try! realm.write {
            collection[0] = "Overwrite"
        }
        XCTAssertEqual(collection.first, "Overwrite")
        let danyObject = realm.objects(Person.self).filter("lastName == 'Targaryen'").first!
        XCTAssertEqual(danyObject.firstName, "Overwrite")
    }
    
    func testFreezeThawProjectedList() {
        let realm = realmWithTestPath()
        let johnSnow = realm.objects(PersonProjection.self).first!
        let projectedList = collection.freeze()
        
        XCTAssertTrue(projectedList.isFrozen)
        XCTAssertFalse(johnSnow.isFrozen)
        
        let frosenJohn = johnSnow.freeze()
        let frozenProjectedList = frosenJohn.firstFriendsName
        
        XCTAssertTrue(frosenJohn.isFrozen)
        XCTAssertTrue(projectedList.isFrozen)
        XCTAssertTrue(frozenProjectedList.isFrozen)
    }
    
//    public func index(matching predicate: NSPredicate) -> Int?
//    public func observe(on queue: DispatchQueue?, _ block: @escaping (RealmCollectionChange<ProjectedList<NewElement>>) -> Void) -> NotificationToken
//    public subscript(position: Int) -> NewElement {
//        get
//        set
//    }
//    public var startIndex: Int
//    public var endIndex: Int
//    public var realm: Realm?
//    public var isInvalidated: Bool
//    public var description: String
//    public func index(of object: Element) -> Int?
//    public var isFrozen: Bool
//    public func freeze() -> Self
//    public func thaw() -> Self?


    func testRealm() {
        guard collection.realm != nil else {
            XCTAssertNotNil(collection.realm)
            return
        }
        XCTAssertEqual(collection.realm!.configuration.fileURL, realmWithTestPath().configuration.fileURL)
    }

    func testDescription() {
        assertMatches(collection.description, "ProjectedList<PersonProjection> ***properties description goes here***")
    }
    
    func testPredicate() {
        let matching = NSPredicate(format: "firstName = 'Daenerys'")
        let notMatching = NSPredicate(format: "firstName = 'Not There'")
        XCTAssertEqual(0, collection.index(matching: matching)!)
        XCTAssertNil(collection.index(matching: notMatching))
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
        var str = ""
        for element in collection {
            str += element
        }

        XCTAssertEqual(str, "DaenerysTyrion")
    }

    func testFastEnumerationWithMutation() {
        let realm = realmWithTestPath()
        try! realm.write {
            for element in collection {
                if element == "Dany" {
                    //realm.delete(DanyObject)
                }
            }
        }
        XCTAssertEqual(2, collection.count)
    }

    func testObserve() {
        let ex = expectation(description: "initial notification")
        let token = collection.observe(on: nil) { (changes: RealmCollectionChange) in
            switch changes {
            case .initial(let collection):
                XCTAssertEqual(collection.count, 2)
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
        let token2 = collection.observe(on: nil) { _ in
            ex2.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        // make a write and implicitly verify that only the unskipped
        // notification is called (the first would error on .update)
        ex2 = expectation(description: "change notification")
        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.delete(realm.objects(Person.self))
        try! realm.commitWrite(withoutNotifying: [token])
        waitForExpectations(timeout: 1, handler: nil)

        token.invalidate()
        token2.invalidate()
    }
//
//    func testObserveKeyPath() {
//        var ex = expectation(description: "initial notification")
//        let token0 = collection.observe(keyPaths: ["stringCol"]) { (changes: RealmCollectionChange) in
//            switch changes {
//            case .initial(let collection):
//                XCTAssertEqual(collection.count, 2)
//            case .update(_, let deletions, let insertions, let modifications):
//                XCTAssertEqual(deletions, [])
//                XCTAssertEqual(insertions, [])
//                XCTAssertEqual(modifications, [0])
//            case .error:
//                XCTFail("error not expected")
//            }
//            ex.fulfill()
//        }
//        waitForExpectations(timeout: 0.2, handler: nil)
//
//        // Expect a change notification for the token observing `stringCol` keypath.
//        ex = self.expectation(description: "change notification")
//        dispatchSyncNewThread {
//            let realm = self.realmWithTestPath()
//            realm.beginWrite()
//            let obj = realm.objects(CTTNullableStringObjectWithLink.self).first!
//            obj.stringCol = "changed"
//            try! realm.commitWrite()
//        }
//        waitForExpectations(timeout: 0.1, handler: nil)
//        token0.invalidate()
//    }
//
//    func testObserveKeyPathNoChange() {
//        var ex = expectation(description: "initial notification")
//        let token0 = collection.observe(keyPaths: ["stringCol"]) { (changes: RealmCollectionChange) in
//            switch changes {
//            case .initial(let collection):
//                XCTAssertEqual(collection.count, 2)
//            case .update:
//                XCTFail("update not expected")
//            case .error:
//                XCTFail("error not expected")
//            }
//            ex.fulfill()
//        }
//        waitForExpectations(timeout: 0.2, handler: nil)
//
//        // Expect no notification for `stringCol` key path because only `linkCol.id` will be modified.
//        ex = self.expectation(description: "NO change notification")
//        ex.isInverted = true // Inverted expectation causes failure if fulfilled.
//        dispatchSyncNewThread {
//            let realm = self.realmWithTestPath()
//            realm.beginWrite()
//            let obj = realm.objects(CTTNullableStringObjectWithLink.self).first!
//            obj.linkCol!.id = 2
//            try! realm.commitWrite()
//        }
//        waitForExpectations(timeout: 0.1, handler: nil)
//        token0.invalidate()
//    }
//
//    func observeOnQueue<Collection: RealmCollection>(_ collection: Collection) where Collection.Element: Object {
//        let sema = DispatchSemaphore(value: 0)
//        let token = collection.observe(keyPaths: nil, on: queue) { (changes: RealmCollectionChange) in
//            switch changes {
//            case .initial(let collection):
//                XCTAssertEqual(collection.count, 2)
//            case .update(let collection, let deletions, _, _):
//                XCTAssertEqual(collection.count, 0)
//                XCTAssertEqual(deletions, [0, 1])
//            case .error:
//                XCTFail("Shouldn't happen")
//            }
//
//            sema.signal()
//        }
//        sema.wait()
//
//        let realm = realmWithTestPath()
//        try! realm.write {
//            realm.delete(collection)
//        }
//        sema.wait()
//
//        token.invalidate()
//    }
//
//    func testObserveOnQueue() {
//        observeOnQueue(collection)
//    }

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
        try! liveRealm.write { liveRealm.delete(liveRealm.objects(Person.self).filter(NSPredicate(format: "firstName != 'Daenerys'"))) }
        XCTAssertTrue(live!.isEmpty)
        XCTAssertFalse(frozen.isEmpty)
        try! liveRealm.write { liveRealm.delete(liveRealm.objects(Person.self)) }
        XCTAssertTrue(frozen.isInvalidated)
        XCTAssertTrue(live!.isInvalidated)
    }

    func testThawFromDifferentThread() {
        let frozen = collection.freeze()
        XCTAssertTrue(frozen.isFrozen)

        dispatchSyncNewThread {
            let live = frozen.thaw()
            XCTAssertFalse(live!.isFrozen)

            let liveRealm = live!.realm!
            try! liveRealm.write { liveRealm.delete(liveRealm.objects(Person.self)) }
            XCTAssertTrue(live!.isEmpty)
            XCTAssertFalse(frozen.isEmpty)
        }
    }

    func testFreezeFromWrongThread() {
        dispatchSyncNewThread {
            self.assertThrows(self.collection.freeze(), reason: "Realm accessed from incorrect thread")
        }
    }

    func testAccessFrozenCollectionFromDifferentThread() {
        let frozen = collection.freeze()
        dispatchSyncNewThread {
            XCTAssertEqual(frozen[0], "Dany")
            XCTAssertEqual(frozen[1], "Tiri")
        }
    }

    func testObserveFrozenCollection() {
        let frozen = collection.freeze()
        assertThrows(frozen.observe(on: nil, { _ in }),
                     reason: "Frozen Realms do not change and do not have change notifications.")
    }

    func testFilterFrozenCollection() {
        let frozen = collection.freeze()
        XCTAssertEqual(frozen.filter({ $0 == "Dany" }).count, 1)
        XCTAssertNil(frozen.filter({ $0 == "Nothing" }).first)
    }
}
