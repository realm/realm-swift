////////////////////////////////////////////////////////////////////////////
//
// Copyright 2019 Realm Inc.
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

class TreeObject: Object {
    @objc dynamic var value: Int = 0
    @objc dynamic var parent: TreeObject?
    let children = LinkingObjects(fromType: TreeObject.self, property: "parent")
}

class SwiftPartialSyncTests: SwiftSyncTestCase {
    func populateTestRealm(_ username: String) {
        autoreleasepool {
            let credentials = SyncCredentials.usernamePassword(username: username, password: "a", register: true)
            let user = try! synchronouslyLogInUser(for: credentials, server: authURL)
            let realm = try! synchronouslyOpenRealm(configuration: user.configuration())

            try! realm.write {
                realm.add(SwiftPartialSyncObjectA(number: 0, string: "realm"))
                realm.add(SwiftPartialSyncObjectA(number: 1, string: ""))
                realm.add(SwiftPartialSyncObjectA(number: 2, string: ""))
                realm.add(SwiftPartialSyncObjectA(number: 3, string: ""))
                realm.add(SwiftPartialSyncObjectA(number: 4, string: "realm"))
                realm.add(SwiftPartialSyncObjectA(number: 5, string: "sync"))
                realm.add(SwiftPartialSyncObjectA(number: 6, string: "partial"))
                realm.add(SwiftPartialSyncObjectA(number: 7, string: "partial"))
                realm.add(SwiftPartialSyncObjectA(number: 8, string: "partial"))
                realm.add(SwiftPartialSyncObjectA(number: 9, string: "partial"))
                realm.add(SwiftPartialSyncObjectB(number: 0, firstString: "", secondString: ""))
                realm.add(SwiftPartialSyncObjectB(number: 1, firstString: "", secondString: ""))
                realm.add(SwiftPartialSyncObjectB(number: 2, firstString: "", secondString: ""))
                realm.add(SwiftPartialSyncObjectB(number: 3, firstString: "", secondString: ""))
                realm.add(SwiftPartialSyncObjectB(number: 4, firstString: "", secondString: ""))
                realm.add(SwiftPartialSyncObjectB(number: 5, firstString: "", secondString: ""))
                realm.add(SwiftPartialSyncObjectB(number: 6, firstString: "", secondString: ""))
                realm.add(SwiftPartialSyncObjectB(number: 7, firstString: "", secondString: ""))
                realm.add(SwiftPartialSyncObjectB(number: 8, firstString: "", secondString: ""))
                realm.add(SwiftPartialSyncObjectB(number: 9, firstString: "", secondString: ""))
            }
            waitForUploads(for: realm)
        }
    }

    func waitForState<T>(_ subscription: SyncSubscription<T>, _ desiredState: SyncSubscriptionState) {
        let ex = expectation(description: "Waiting for state \(desiredState)")
        let token = subscription.observe(\.state, options: .initial) { state in
            if state == desiredState {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 20.0)
        token.invalidate()
    }

    func waitForError<T>(_ subscription: SyncSubscription<T>) {
        let ex = expectation(description: "Waiting for error state")
        let token = subscription.observe(\.state, options: .initial) { state in
            if case .error(_) = state {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 20.0)
        token.invalidate()
    }

    func testPartialSync() {
        populateTestRealm(#function)

        let credentials = SyncCredentials.usernamePassword(username: #function, password: "a")
        let user = try! synchronouslyLogInUser(for: credentials, server: authURL)
        let realm = try! synchronouslyOpenRealm(configuration: user.configuration())

        let results = realm.objects(SwiftPartialSyncObjectA.self).filter("number > 5")
        let subscription = results.subscribe(named: "query")
        XCTAssertEqual(subscription.state, .creating)
        waitForState(subscription, .complete)

        // Verify that we got what we're looking for
        XCTAssertEqual(results.count, 4)
        for object in results {
            XCTAssertGreaterThan(object.number, 5)
            XCTAssertEqual(object.string, "partial")
        }

        // And that we didn't get anything else.
        XCTAssertEqual(realm.objects(SwiftPartialSyncObjectA.self).count, results.count)
        XCTAssertTrue(realm.objects(SwiftPartialSyncObjectB.self).isEmpty)

        // Re-subscribing to an existing named query may not report the query's state immediately,
        // but it should report it eventually.
        let subscription2 = realm.objects(SwiftPartialSyncObjectA.self).filter("number > 5").subscribe(named: "query")
        waitForState(subscription2, .complete)

        // Creating a subscription with the same name but different query should raise an error.
        let subscription3 = realm.objects(SwiftPartialSyncObjectA.self).filter("number < 5").subscribe(named: "query")
        waitForError(subscription3)

        // Unsubscribing should move the subscription to the invalidated state.
        subscription.unsubscribe()
        waitForState(subscription, .invalidated)
    }

    func testPartialSyncLimit() {
        populateTestRealm(#function)

        let credentials = SyncCredentials.usernamePassword(username: #function, password: "a")
        let user = try! synchronouslyLogInUser(for: credentials, server: authURL)
        let realm = try! synchronouslyOpenRealm(configuration: user.configuration())

        let results = realm.objects(SwiftPartialSyncObjectA.self).filter("number > 5")
        waitForState(results.subscribe(named: "query", limit: 1), .complete)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(realm.objects(SwiftPartialSyncObjectA.self).count, 1)
        if let object = results.first {
            XCTAssertGreaterThan(object.number, 5)
            XCTAssertEqual(object.string, "partial")
        }

        let results2 = realm.objects(SwiftPartialSyncObjectA.self).sorted(byKeyPath: "number", ascending: false)
        waitForState(results2.subscribe(named: "query2", limit: 2), .complete)
        XCTAssertEqual(results2.count, 3)
        XCTAssertEqual(realm.objects(SwiftPartialSyncObjectA.self).count, 3)
        for object in results2 {
            XCTAssertTrue(object.number == 6 || object.number >= 8,
                          "\(object.number) == 6 || \(object.number) >= 8")
            XCTAssertEqual(object.string, "partial")
        }

        waitForState(results2.subscribe(named: "query2", limit: 1, update: true), .complete)
        XCTAssertEqual(results2.count, 2)
        XCTAssertEqual(realm.objects(SwiftPartialSyncObjectA.self).count, 2)
        for object in results2 {
            XCTAssertTrue(object.number == 6 || object.number == 9,
                          "\(object.number) == 6 || \(object.number) == 9")
            XCTAssertEqual(object.string, "partial")
        }
    }

    func testPartialSyncSubscriptions() {
        let credentials = SyncCredentials.usernamePassword(username: #function, password: "a", register: true)
        let user = try! synchronouslyLogInUser(for: credentials, server: authURL)
        let realm = try! synchronouslyOpenRealm(configuration: user.configuration())

        XCTAssertEqual(realm.subscriptions().count, 0)
        XCTAssertNil(realm.subscription(named: "query"))

        let subscription = realm.objects(SwiftPartialSyncObjectA.self).filter("number > 5").subscribe(named: "query")
        XCTAssertEqual(realm.subscriptions().count, 0)
        XCTAssertNil(realm.subscription(named: "query"))
        waitForState(subscription, .complete)

        XCTAssertEqual(realm.subscriptions().count, 1)
        let sub2 = realm.subscriptions().first!
        XCTAssertEqual(sub2.name, "query")
        XCTAssertEqual(sub2.state, .complete)
        let sub3 = realm.subscription(named: "query")!
        XCTAssertEqual(sub3.name, "query")
        XCTAssertEqual(sub3.state, .complete)
        for sub in realm.subscriptions() {
            XCTAssertEqual(sub.name, "query")
            XCTAssertEqual(sub.state, .complete)
        }

        XCTAssertNil(realm.subscription(named: "not query"))
    }

    func testSubscriptionPropertyUpdating() {
        let credentials = SyncCredentials.usernamePassword(username: #function, password: "a", register: true)
        let user = try! synchronouslyLogInUser(for: credentials, server: authURL)
        let realm = try! synchronouslyOpenRealm(configuration: user.configuration())

        // Create the initial subscription
        let objects = realm.objects(SwiftPartialSyncObjectA.self)
        let sub1 = objects.filter("number > 5").subscribe(named: "query")
        XCTAssertEqual(sub1.name, "query")
        XCTAssertNil(sub1.query)
        XCTAssertNotNil(sub1.createdAt)
        XCTAssertNotNil(sub1.updatedAt)
        XCTAssertEqual(sub1.createdAt, sub1.updatedAt)
        XCTAssertNil(sub1.expiresAt)
        XCTAssertNil(sub1.timeToLive)
        let createdAt = sub1.createdAt!

        // Verify that all of the properties are correct on both the returned
        // subscription object and the one fetched from the Realm
        waitForState(sub1, .complete)
        XCTAssertEqual(sub1.name, "query")
        XCTAssertEqual(sub1.query, "number > 5")
        XCTAssertNotNil(sub1.createdAt)
        XCTAssertNotNil(sub1.updatedAt)
        XCTAssertEqual(sub1.createdAt, sub1.updatedAt)
        XCTAssertGreaterThan(sub1.createdAt!, createdAt)
        XCTAssertNil(sub1.expiresAt)
        XCTAssertNil(sub1.timeToLive)

        let sub2 = realm.subscriptions().first!
        XCTAssertEqual(sub2.name, "query")
        XCTAssertEqual(sub2.query, "number > 5")
        XCTAssertNotNil(sub2.createdAt)
        XCTAssertNotNil(sub2.updatedAt)
        XCTAssertEqual(sub2.createdAt, sub2.updatedAt)
        XCTAssertGreaterThan(sub2.createdAt!, createdAt)
        XCTAssertNil(sub2.expiresAt)
        XCTAssertNil(sub2.timeToLive)

        // Update query and verify that propagates
        waitForState(objects.filter("number > 6").subscribe(named: "query", update: true),
                     .complete)
        XCTAssertEqual(sub1.name, "query")
        XCTAssertEqual(sub1.query, "number > 6")
        XCTAssertNotNil(sub1.createdAt)
        XCTAssertNotNil(sub1.updatedAt)
        XCTAssertGreaterThan(sub1.updatedAt!, sub1.createdAt!)
        XCTAssertNil(sub1.expiresAt)
        XCTAssertNil(sub1.timeToLive)

        XCTAssertEqual(sub2.name, "query")
        XCTAssertEqual(sub2.query, "number > 6")
        XCTAssertNotNil(sub2.createdAt)
        XCTAssertNotNil(sub2.updatedAt)
        XCTAssertGreaterThan(sub2.updatedAt!, sub2.createdAt!)
        XCTAssertNil(sub2.expiresAt)
        XCTAssertNil(sub2.timeToLive)

        // Update TTL and verify that propagates
        waitForState(objects.filter("number > 6").subscribe(named: "query", update: true, timeToLive: 10.0),
                     .complete)
        XCTAssertEqual(sub1.name, "query")
        XCTAssertEqual(sub1.query, "number > 6")
        XCTAssertNotNil(sub1.createdAt)
        XCTAssertNotNil(sub1.updatedAt)
        XCTAssertGreaterThan(sub1.updatedAt!, sub1.createdAt!)
        XCTAssertEqual(sub1.updatedAt!.addingTimeInterval(10.0), sub1.expiresAt!)
        XCTAssertEqual(sub1.timeToLive, 10.0)

        XCTAssertEqual(sub2.name, "query")
        XCTAssertEqual(sub2.query, "number > 6")
        XCTAssertNotNil(sub2.createdAt)
        XCTAssertNotNil(sub2.updatedAt)
        XCTAssertGreaterThan(sub2.updatedAt!, sub2.createdAt!)
        XCTAssertEqual(sub2.updatedAt!.addingTimeInterval(10.0), sub2.expiresAt!)
        XCTAssertEqual(sub2.timeToLive, 10.0)

        // Disable TTL and verify that propagates
        waitForState(objects.filter("number > 6").subscribe(named: "query", update: true, timeToLive: nil),
                     .complete)
        XCTAssertEqual(sub1.name, "query")
        XCTAssertEqual(sub1.query, "number > 6")
        XCTAssertNotNil(sub1.createdAt)
        XCTAssertNotNil(sub1.updatedAt)
        XCTAssertGreaterThan(sub1.updatedAt!, sub1.createdAt!)
        XCTAssertNil(sub1.expiresAt)
        XCTAssertNil(sub1.timeToLive)

        XCTAssertEqual(sub2.name, "query")
        XCTAssertEqual(sub2.query, "number > 6")
        XCTAssertNotNil(sub2.createdAt)
        XCTAssertNotNil(sub2.updatedAt)
        XCTAssertGreaterThan(sub2.updatedAt!, sub2.createdAt!)
        XCTAssertNil(sub2.expiresAt)
        XCTAssertNil(sub2.timeToLive)
    }

    func testQueryingSubscriptions() {
        let credentials = SyncCredentials.usernamePassword(username: #function, password: "a", register: true)
        let user = try! synchronouslyLogInUser(for: credentials, server: authURL)
        let realm = try! synchronouslyOpenRealm(configuration: user.configuration())

        // Verify that we can construct queries using the exposed property names
        // Validation that the queries produce the correct results is covered by
        // the obj-c tests
        _ = realm.subscriptions().filter("name = 'a'")
        _ = realm.subscriptions().filter("query = 'a'")
        _ = realm.subscriptions().filter("createdAt > %@", Date())
        _ = realm.subscriptions().filter("updatedAt > %@", Date())
        _ = realm.subscriptions().filter("expiresAt > %@", Date())
        _ = realm.subscriptions().filter("timeToLive = 5")
    }

    func testIncludeLinkingObjects() {
        let credentials = SyncCredentials.usernamePassword(username: #function, password: "a", register: true)
        let user = try! synchronouslyLogInUser(for: credentials, server: authURL)
        let realm = try! synchronouslyOpenRealm(configuration: user.configuration())

        //          0
        //    /     |      \
        //   1      5       9
        // / | \  / | \   / | \
        // 2 3 4  6 7 8  10 11 12
        try! realm.write {
            let root = realm.create(TreeObject.self, value: [0])
            for i in 0..<3 {
                let child = realm.create(TreeObject.self, value: [1 + i * 4, root])
                for j in 0..<3 {
                    _ = realm.create(TreeObject.self, value: [2 + i * 4 + j, child])
                }
            }
        }

        let objects = realm.objects(TreeObject.self)

        // root only
        waitForState(objects.filter("value = 0").subscribe(named: "query", update: true),
                     .complete)
        XCTAssertEqual(objects.count, 1)

        // root and children
        waitForState(objects.filter("value = 0").subscribe(named: "query", update: true, includingLinkingObjects: ["children"]),
                     .complete)
        XCTAssertEqual(objects.count, 4)
        XCTAssertEqual(Set(objects.value(forKey: "value")! as! [Int]), Set([0, 1, 5, 9]))

        // root, children and grandchildren
        waitForState(objects.filter("value = 0").subscribe(named: "query", update: true, includingLinkingObjects: ["children", "children.children"]),
                     .complete)
        XCTAssertEqual(objects.count, 13)
        XCTAssertEqual(Set(objects.value(forKey: "value")! as! [Int]),
                       Set([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]))

        // root and grandchildren pulls in children
        waitForState(objects.filter("value = 0").subscribe(named: "query", update: true, includingLinkingObjects: [ "children.children"]),
                     .complete)
        XCTAssertEqual(objects.count, 13)
        XCTAssertEqual(Set(objects.value(forKey: "value")! as! [Int]),
                       Set([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]))

        // one specific child and that child's children (plus root since it's a forward link)
        waitForState(objects.filter("value = 5").subscribe(named: "query", update: true, includingLinkingObjects: ["children"]),
                     .complete)
        XCTAssertEqual(objects.count, 5)
        XCTAssertEqual(Set(objects.value(forKey: "value")! as! [Int]),
                       Set([0, 5, 6, 7, 8]))

        // one specific grandchild
        waitForState(objects.filter("value = 12").subscribe(named: "query", update: true, includingLinkingObjects: ["children"]),
                     .complete)
        XCTAssertEqual(objects.count, 3)
        XCTAssertEqual(Set(objects.value(forKey: "value")! as! [Int]),
                       Set([0, 9, 12]))

        // one specific grandchild and all children via links off that grandchild
        waitForState(objects.filter("value = 12").subscribe(named: "query", update: true, includingLinkingObjects: ["parent.parent.children"]),
                     .complete)
        XCTAssertEqual(objects.count, 5)
        XCTAssertEqual(Set(objects.value(forKey: "value")! as! [Int]),
                       Set([0, 1, 5, 9, 12]))
    }
}
