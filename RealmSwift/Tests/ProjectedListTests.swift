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
    
    func testCount() {
        XCTAssertEqual(collection.count, 1)
    }
    
    func testAccess() {
        XCTAssertEqual(collection[0], "Daenerys")
        XCTAssertEqual(collection.first, "Daenerys")
        XCTAssertEqual(collection.last, "Daenerys")
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
        
        XCTAssertFalse(projectedList.isFrozen)
        XCTAssertFalse(johnSnow.isFrozen)
        
        let frosenJohn = johnSnow.freeze()
        let frozenProjectedList = frosenJohn.firstFriendsName
        
        XCTAssertTrue(frosenJohn.isFrozen)
        XCTAssertFalse(projectedList.isFrozen)
        XCTAssertTrue(frozenProjectedList.isFrozen)

//        let thawedJohnProjectionA = frozenJohnProjection.thaw()!
//        let thawedJohnProjectionB = johnProjectionFromFrozen.thaw()!
//        XCTAssertFalse(thawedJohnProjectionA.isFrozen)
//        XCTAssertFalse(thawedJohnProjectionB.isFrozen)
//        XCTAssertEqual(thawedJohnProjectionA, thawedJohnProjectionB)
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
        let matching = NSPredicate(format: "value = 'Daenerys'")
        let notMatching = NSPredicate(format: "value = 'Not There'")
        XCTAssertEqual(0, collection.index(matching: matching)!)
        XCTAssertNil(collection.index(matching: notMatching))
    }

    func testFilterFormat() {
        XCTAssertNotNil(collection.filter { $0 == "Daenerys" }.first!)
        XCTAssertNil(collection.filter { $0 == "Not There" }.first!)
    }

    func testSortWithProperty() {
        XCTAssertEqual("A", collection.sorted { $0 > $1 }.first!)
        XCTAssertEqual("B", collection.sorted { $0 > $1 }.last!)
    }

    func testFastEnumeration() {
        var str = ""
        for element in collection {
            str += element
        }

        XCTAssertEqual(str, "longstring")
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

//    func testObserve() {
//        let ex = expectation(description: "initial notification")
//        let token = collection.observe(on: nil) { (changes: RealmCollectionChange) in
//            switch changes {
//            case .initial(let collection):
//                XCTAssertEqual(collection.count, 2)
//            case .update:
//                XCTFail("Shouldn't happen")
//            case .error:
//                XCTFail("Shouldn't happen")
//            }
//
//            ex.fulfill()
//        }
//        waitForExpectations(timeout: 1, handler: nil)
//
//        // add a second notification and wait for it
//        var ex2 = expectation(description: "second initial notification")
//        let token2 = collection.observe(on: nil) { _ in
//            ex2.fulfill()
//        }
//        waitForExpectations(timeout: 1, handler: nil)
//
//        // make a write and implicitly verify that only the unskipped
//        // notification is called (the first would error on .update)
//        ex2 = expectation(description: "change notification")
//        let realm = realmWithTestPath()
//        realm.beginWrite()
//        realm.delete(collection)
//        try! realm.commitWrite(withoutNotifying: [token])
//        waitForExpectations(timeout: 1, handler: nil)
//
//        token.invalidate()
//        token2.invalidate()
//    }
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
//
//    func testInvalidate() {
//        XCTAssertFalse(collection.isInvalidated)
//        realmWithTestPath().invalidate()
//        XCTAssertTrue(collection.realm == nil || collection.isInvalidated)
//    }
//
//    func testIsFrozen() {
//        XCTAssertFalse(collection.isFrozen)
//        XCTAssertTrue(collection.freeze().isFrozen)
//    }
//
//    func testThaw() {
//        let frozen = collection.freeze()
//        XCTAssertTrue(frozen.isFrozen)
//
//        let frozenRealm = frozen.realm!
//        assertThrows(try! frozenRealm.write {}, reason: "Can't perform transactions on a frozen Realm")
//
//        let live = frozen.thaw()
//        XCTAssertFalse(live!.isFrozen)
//
//        let liveRealm = live!.realm!
//        try! liveRealm.write { liveRealm.delete(live!) }
//        XCTAssertTrue(live!.isEmpty)
//        XCTAssertFalse(frozen.isEmpty)
//    }
//
//    func testThawFromDifferentThread() {
//        let frozen = collection.freeze()
//        XCTAssertTrue(frozen.isFrozen)
//
//        dispatchSyncNewThread {
//            let live = frozen.thaw()
//            XCTAssertFalse(live!.isFrozen)
//
//            let liveRealm = live!.realm!
//            try! liveRealm.write { liveRealm.delete(live!) }
//            XCTAssertTrue(live!.isEmpty)
//            XCTAssertFalse(frozen.isEmpty)
//        }
//    }
//
//    func testThawPreviousVersion() {
//        let frozen = collection.freeze()
//        XCTAssertTrue(frozen.isFrozen)
//        XCTAssertEqual(collection.count, frozen.count)
//
//        let realm = collection.realm!
//        try! realm.write { realm.delete(collection) }
//        XCTAssertNotEqual(frozen.count, collection.count, "Frozen collections should not change")
//
//        let live = frozen.thaw()
//        XCTAssertTrue(live!.isEmpty, "Thawed collection should reflect transactions since the original reference was frozen")
//        XCTAssertFalse(frozen.isEmpty)
//        XCTAssertEqual(live!.count, self.collection.count)
//    }
//
//    func testThawUpdatedOnDifferentThread() {
//        let tsr = ThreadSafeReference(to: collection)
//        var frozen: AnyRealmCollection<CTTNullableStringObjectWithLink>?
//        var frozenQuery: Results<CTTNullableStringObjectWithLink>?
//
//        XCTAssertEqual(collection.count, 2) // stringCol "1" and "2"
//        XCTAssertEqual(collection.filter("stringCol == %@", "3").count, 0)
//
//        dispatchSyncNewThread {
//            let realm = try! Realm(configuration: self.collection.realm!.configuration)
//            let collection = realm.resolve(tsr)!
//            try! realm.write { collection.first!.stringCol = "3" }
//            try! realm.write { realm.delete(collection.last!) }
//
//            let query = collection.filter("stringCol == %@", "1")
//            frozen = collection.freeze() // Results::Mode::TableView
//            frozenQuery = query.freeze() // Results::Mode::Query
//
//        }
//
//        let thawed = frozen!.thaw()
//        XCTAssertEqual(frozen!.count, 1)
//        XCTAssertEqual(frozen!.first?.stringCol, "3")
//        XCTAssertEqual(frozen!.filter("stringCol == %@", "1").count, 0)
//        XCTAssertEqual(frozen!.filter("stringCol == %@", "2").count, 0)
//        XCTAssertEqual(frozen!.filter("stringCol == %@", "3").count, 1)
//
//        XCTAssertEqual(thawed!.count, 2)
//        XCTAssertEqual(thawed!.first?.stringCol, "1")
//        XCTAssertEqual(thawed!.filter("stringCol == %@", "1").count, 1)
//        XCTAssertEqual(thawed!.filter("stringCol == %@", "2").count, 1)
//        XCTAssertEqual(thawed!.filter("stringCol == %@", "3").count, 0)
//
//        XCTAssertEqual(collection.count, 2)
//        XCTAssertEqual(collection.first?.stringCol, "1")
//        XCTAssertEqual(collection.filter("stringCol == %@", "1").count, 1)
//        XCTAssertEqual(collection.filter("stringCol == %@", "2").count, 1)
//        XCTAssertEqual(collection.filter("stringCol == %@", "3").count, 0)
//
//        let thawedQuery = frozenQuery!.thaw()
//        XCTAssertEqual(frozenQuery!.count, 0)
//        XCTAssertEqual(frozenQuery!.first?.stringCol, nil)
//        XCTAssertEqual(frozenQuery!.filter("stringCol == %@", "1").count, 0)
//        XCTAssertEqual(frozenQuery!.filter("stringCol == %@", "2").count, 0)
//        XCTAssertEqual(frozenQuery!.filter("stringCol == %@", "3").count, 0)
//
//        XCTAssertEqual(thawedQuery!.count, 1)
//        XCTAssertEqual(thawedQuery!.first?.stringCol, "1")
//        XCTAssertEqual(thawedQuery!.filter("stringCol == %@", "1").count, 1)
//        XCTAssertEqual(thawedQuery!.filter("stringCol == %@", "2").count, 0)
//        XCTAssertEqual(thawedQuery!.filter("stringCol == %@", "3").count, 0)
//
//        collection.realm!.refresh()
//
//        XCTAssertEqual(thawed!.count, 1)
//        XCTAssertEqual(thawed!.first?.stringCol, "3")
//        XCTAssertEqual(thawed!.filter("stringCol == %@", "1").count, 0)
//        XCTAssertEqual(thawed!.filter("stringCol == %@", "2").count, 0)
//        XCTAssertEqual(thawed!.filter("stringCol == %@", "3").count, 1)
//
//        XCTAssertEqual(thawedQuery!.count, 0)
//        XCTAssertEqual(thawedQuery!.first?.stringCol, nil)
//        XCTAssertEqual(thawedQuery!.filter("stringCol == %@", "1").count, 0)
//        XCTAssertEqual(thawedQuery!.filter("stringCol == %@", "2").count, 0)
//        XCTAssertEqual(thawedQuery!.filter("stringCol == %@", "3").count, 0)
//
//        XCTAssertEqual(collection.count, 1)
//        XCTAssertEqual(collection.first?.stringCol, "3")
//        XCTAssertEqual(collection.filter("stringCol == %@", "1").count, 0)
//        XCTAssertEqual(collection.filter("stringCol == %@", "2").count, 0)
//        XCTAssertEqual(collection.filter("stringCol == %@", "3").count, 1)
//    }
//
//    func testThawDeletedParent() {
//        let frozenElement = collection.first!.freeze()
//        XCTAssertTrue(frozenElement.isFrozen)
//
//        let realm = collection.realm!
//        try! realm.write { realm.delete(collection) }
//        XCTAssertNil(collection.first)
//        XCTAssertNotNil(frozenElement)
//
//        let thawed = frozenElement.thaw()
//        XCTAssertNil(thawed)
//    }
//
//    func testFreezeFromWrongThread() {
//        dispatchSyncNewThread {
//            self.assertThrows(self.collection.freeze(), reason: "Realm accessed from incorrect thread")
//        }
//    }
//
//    func testAccessFrozenCollectionFromDifferentThread() {
//        let frozen = collection.freeze()
//        dispatchSyncNewThread {
//            XCTAssertEqual(frozen[0], "Dany")
//            XCTAssertEqual(frozen[1], "Tiri")
//        }
//    }
//
//    func testObserveFrozenCollection() {
//        let frozen = collection.freeze()
//        assertThrows(frozen.observe(on: nil, { _ in }),
//                     reason: "Frozen Realms do not change and do not have change notifications.")
//    }
//
//    func testFilterFrozenCollection() {
//        let frozen = collection.freeze()
//        XCTAssertEqual(frozen.filter({ $0 == "Dany" }).count, 1)
//        XCTAssertNil(frozen.filter({ $0 == "Nothing" }).first)
//    }
}
