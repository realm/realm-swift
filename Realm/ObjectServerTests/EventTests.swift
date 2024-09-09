////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

import Combine
import Foundation
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSwiftTestSupport
import RealmSyncTestSupport
import RealmTestSupport
#endif

class SwiftCustomEventRepresentation: Object, CustomEventRepresentable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var value: Int

    convenience init(value: Int) {
        self.init()
        self.value = value
    }

    func customEventRepresentation() -> String {
        if value == 0 {
            return "invalid json"
        }
        if value == 1 {
            _ = NSArray()[1]
            return ""
        }
        return "{\"int\": \(value)}"
    }
}

class AuditEvent: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var activity: String
    @Persisted var event: String?
    @Persisted var data: String?
    @Persisted var timestamp: Date
    @Persisted var userId: String?

    var parsedData: NSDictionary?
}

@available(macOS 13, *)
class SwiftEventTests: SwiftSyncTestCase {
    var user: User!
    var collection: MongoCollection!
    var start: Date!

    override func setUp() async throws {
        user = try await createUser()
        collection = user.collection(for: AuditEvent.self, app: app)
        try await _ = collection.deleteManyDocuments(filter: [:])

        // The server truncates date values to lower precision than we support,
        // so we need to set the start date to slightly in the past
        start = Date(timeIntervalSinceNow: -1.0)
    }

    override func tearDown() {
        if let user {
            while user.allSessions.count > 0 {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            }
            self.user = nil
        }
        super.tearDown()
    }

    override func configuration(user: User) -> Realm.Configuration {
        var config = user.configuration(partitionValue: name)
        config.eventConfiguration = EventConfiguration()
        return config
    }

    override var objectTypes: [ObjectBase.Type] {
        [AuditEvent.self, SwiftPerson.self, SwiftCustomEventRepresentation.self, LinkToSwiftPerson.self]
    }

    @MainActor
    func scope<T>(_ events: Events, _ name: String, body: () throws -> T) rethrows -> T {
        let scope = events.beginScope(activity: name)
        XCTAssertTrue(scope.isActive)
        let result = try body()
        scope.commit().await(self)
        XCTAssertFalse(scope.isActive)
        return result
    }

    @MainActor
    func getEvents(expectedCount: Int) -> [AuditEvent] {
        waitForCollectionCount(collection, expectedCount)

        let docs = collection.find(filter: [:]).await(self)
        XCTAssertEqual(docs.count, expectedCount)
        return docs.map { doc in
            let event = AuditEvent()
            event._id = doc["_id"]!!.objectIdValue!
            event.activity = doc["activity"]!!.stringValue!
            event.event = doc["event"]??.stringValue
            event.data = doc["data"]??.stringValue
            event.parsedData = event.data
                .flatMap { try? JSONSerialization.jsonObject(with: $0.data(using: .utf8)!) }
                .flatMap { $0 as? NSDictionary }
            event.userId = doc["userId"]??.stringValue

            XCTAssertGreaterThan(doc["timestamp"]!!.dateValue!, start)

            return event
        }
    }

    func full(_ person: SwiftPerson) -> NSDictionary {
        return [
            "_id": person._id.stringValue,
            "firstName": person.firstName,
            "lastName": person.lastName,
            "age": person.age,
            "realm_id": NSNull()
        ]
    }

    func idOnly(_ person: SwiftPerson) -> Any {
        return person._id.stringValue
    }

    func assertEvent(_ events: [AuditEvent], activity: String, event: String?,
                     _ data: NSDictionary?, line: UInt = #line) {
        let matching = events.filter { $0.activity == activity && $0.event == event }
        XCTAssertEqual(matching.count, 1, line: line)
        guard let actual = matching.first else { return }
        if let parsed = actual.parsedData {
            XCTAssertEqual(parsed, data)
        } else {
            XCTAssertNil(actual.data)
        }
    }

    func assertEvent(_ events: [AuditEvent], activity: String, userId: String?, line: UInt = #line) {
        let matching = events.filter { $0.activity == activity }
        XCTAssertEqual(matching.count, 1, line: line)
        XCTAssertEqual(matching[0].userId, userId, line: line)
    }

    func assertEvent(_ events: [AuditEvent], activity: String, event: String?,
                     data: String?, line: UInt = #line) {
        let matching = events.filter { $0.activity == activity && $0.event == event }
        XCTAssertEqual(matching.count, 1, line: line)
        XCTAssertEqual(matching[0].data, data, line: line)
    }

    @MainActor
    func testBasicEvents() throws {
        let realm = try openRealm()
        let events = realm.events!

        let personJson: NSDictionary = try scope(events, "create object") {
            try realm.write {
                let person = SwiftPerson(firstName: "Fred", lastName: "Q", age: 30)
                realm.add(person)
                return full(person)
            }
        }

        let person = scope(events, "read object") {
            realm.objects(SwiftPerson.self).first!
        }

        try scope(events, "mutate object") {
            try realm.write {
                person.age = 31
            }
        }

        try scope(events, "delete object") {
            try realm.write {
                realm.delete(person)
            }
        }

        let mutatedPersonJson = personJson.mutableCopy() as! NSMutableDictionary
        mutatedPersonJson["age"] = 31

        let result = getEvents(expectedCount: 4)
        assertEvent(result, activity: "create object", event: "write",
                    ["SwiftPerson": ["insertions": [personJson]]])
        assertEvent(result, activity: "read object", event: "read",
                    ["type": "SwiftPerson", "value": [personJson]])
        assertEvent(result, activity: "mutate object", event: "write",
                    ["SwiftPerson": ["modifications": [
                        ["oldValue": personJson, "newValue": ["age": 31]]]]])
        assertEvent(result, activity: "delete object", event: "write",
                    ["SwiftPerson": ["deletions": [mutatedPersonJson]]])
    }

    @MainActor
    func testBasicWithAsyncOpen() throws {
        let realm = Realm.asyncOpen(configuration: try configuration()).await(self)
        let events = try XCTUnwrap(realm.events)

        let personJson: NSDictionary = try scope(events, "create object") {
            try realm.write {
                let person = SwiftPerson(firstName: "Fred", lastName: "Q", age: 30)
                realm.add(person)
                return full(person)
            }
        }

        let result = getEvents(expectedCount: 1)
        assertEvent(result, activity: "create object", event: "write",
                    ["SwiftPerson": ["insertions": [personJson]]])
    }

    @MainActor
    func testCustomEventRepresentation() throws {
        let realm = try openRealm()
        let events = realm.events!
        let scope1 = events.beginScope(activity: "bad json")
        try realm.write {
            realm.add(SwiftCustomEventRepresentation(value: 0))
        }
        scope1.commit().awaitFailure(self) { error in
            XCTAssert(error.localizedDescription.contains("json.exception.parse_error"))
        }

        let scope2 = events.beginScope(activity: "exception thrown")
        try realm.write {
            realm.add(SwiftCustomEventRepresentation(value: 1))
        }
        scope2.commit().awaitFailure(self) { error in
            XCTAssertEqual((error as NSError).userInfo["ExceptionName"] as! String?,
                           NSExceptionName.rangeException.rawValue)
        }

        try scope(events, "valid representation") {
            try realm.write {
                realm.add(SwiftCustomEventRepresentation(value: 2))
            }
        }

        let result = getEvents(expectedCount: 1)
        assertEvent(result, activity: "valid representation", event: "write",
                    ["SwiftCustomEventRepresentation": ["insertions": [["int": 2]]]])
    }

    @MainActor
    func testReadEvents() throws {
        let realm = try openRealm()
        let events = realm.events!

        let a = SwiftPerson(firstName: "A", lastName: "B")
        let b = SwiftPerson(firstName: "B", lastName: "C")
        let c = SwiftPerson(firstName: "C", lastName: "D")
        try realm.write {
            realm.add([a, b, c])
            realm.create(LinkToSwiftPerson.self, value: [
                "person": a,
                "people": [b, c],
                "peopleByName": [b.firstName: b, c.firstName: c]
            ] as [String: Any])
        }

        let objects = realm.objects(SwiftPerson.self)
        let first = realm.objects(LinkToSwiftPerson.self).first!
        scope(events, "link") {
            _ = first.person
        }
        scope(events, "results") {
            _ = objects.first
        }
        scope(events, "query") {
            _ = objects.filter("firstName != 'B'").first
        }
        scope(events, "list") {
            _ = first.people.first
        }
        scope(events, "dynamic list") {
            _ = first.dynamicList("people").first
        }
        scope(events, "collection kvc") {
            _ = first.people.value(forKey: "firstName") as [AnyObject]
        }
        scope(events, "dictionary") {
            _ = first.peopleByName["B"]
        }
        scope(events, "dynamic dictionary") {
            _ = first.dynamicMap("peopleByName")["B"]
        }
        scope(events, "lookup by primary key") {
            _ = realm.object(ofType: SwiftPerson.self, forPrimaryKey: a._id)
        }

        let result = getEvents(expectedCount: 10)
        func assertEvent(_ activity: String, _ value: [NSDictionary]..., line: UInt = #line) {
            let filtered = Array(result.filter { $0.activity == activity }.sorted { $0._id < $1._id })
            XCTAssertEqual(filtered.count, value.count, line: line)
            for (expected, actual) in zip(value, filtered.map { $0.parsedData }) {
                XCTAssertNotNil(actual, line: line)
                guard let actual = actual else { continue }
                XCTAssertEqual(actual["type"] as? String, "SwiftPerson", line: line)
                XCTAssertEqual(actual["value"]! as! [NSDictionary],
                               expected, line: line)
            }
        }

        assertEvent("link", [full(a)])
        assertEvent("results", [full(a)])
        assertEvent("query", [full(a), full(c)])
        assertEvent("list", [full(b)])
        assertEvent("dynamic list", [full(b)])
        assertEvent("collection kvc", [full(b)], [full(c)])
        assertEvent("dictionary", [full(b)])
        assertEvent("dynamic dictionary", [full(b)])
        assertEvent("lookup by primary key", [full(a)])
    }

    @MainActor
    func testLinkTracking() throws {
        let realm = try openRealm()
        let events = realm.events!

        let a = SwiftPerson(firstName: "A", lastName: "B")
        let b = SwiftPerson(firstName: "B", lastName: "C")
        let c = SwiftPerson(firstName: "C", lastName: "D")
        var id: ObjectId?
        try realm.write {
            realm.add([a, b, c])
            id = realm.create(LinkToSwiftPerson.self, value: [
                "person": a,
                "people": [b, c],
                "peopleByName": [b.firstName: b, c.firstName: c]
            ] as [String: Any])._id
        }

        let objects = realm.objects(LinkToSwiftPerson.self)
        let dynamicObjects = realm.dynamicObjects("LinkToSwiftPerson")
        scope(events, "object read without link accesses") {
            _ = objects.first
        }
        scope(events, "link property") {
            _ = objects.first!.person
        }
        scope(events, "link via KVC") {
            _ = objects.first!.value(forKey: "person")
        }
        scope(events, "link via subscript") {
            _ = objects.first!["person"]
        }
        scope(events, "link via dynamic") {
            _ = dynamicObjects.first!["person"]
        }

        scope(events, "list property") {
            _ = objects.first!.people.first
        }
        scope(events, "dynamic list property") {
            _ = dynamicObjects.first!.dynamicList("people").first
        }
        scope(events, "dictionary property") {
            _ = objects.first!.peopleByName["B"]
        }
        scope(events, "dynamic dictionary property") {
            _ = dynamicObjects.first!.dynamicMap("peopleByName")["B"]
        }

        let result = getEvents(expectedCount: 17)

        func assertEvent(_ activity: String, personCount: Int, _ value: NSDictionary, line: UInt = #line) {
            XCTAssertEqual(result.filter { $0.activity == activity &&
                                           $0.parsedData!["type"] as! String == "SwiftPerson" }.count,
                           personCount, line: line)
            let event = result.filter { $0.activity == activity &&
                                        $0.parsedData!["type"] as! String == "LinkToSwiftPerson" }.first
            XCTAssertNotNil(event, line: line)
            guard let event = event else { return }
            let array = event.parsedData!["value"]! as! NSArray
            XCTAssertEqual(array.count, 1, line: line)
            XCTAssertEqual(array[0] as! NSDictionary, value, line: line)
        }

        assertEvent("object read without link accesses", personCount: 0, [
            "_id": id!.stringValue,
            "realm_id": NSNull(),
            "person": idOnly(a),
            "people": [idOnly(b), idOnly(c)],
            "peopleByName": [b.firstName: idOnly(b), c.firstName: idOnly(c)]
        ])

        let linkAccessed: NSDictionary = [
            "_id": id!.stringValue,
            "realm_id": NSNull(),
            "person": full(a),
            "people": [idOnly(b), idOnly(c)],
            "peopleByName": [b.firstName: idOnly(b), c.firstName: idOnly(c)]
        ]
        assertEvent("link property", personCount: 1, linkAccessed)
        assertEvent("link via KVC", personCount: 1, linkAccessed)
        assertEvent("link via subscript", personCount: 1, linkAccessed)
        assertEvent("link via dynamic", personCount: 1, linkAccessed)

        let listAccessed: NSDictionary = [
            "_id": id!.stringValue,
            "realm_id": NSNull(),
            "person": idOnly(a),
            "people": [full(b), full(c)],
            "peopleByName": [b.firstName: idOnly(b), c.firstName: idOnly(c)]
        ]
        assertEvent("list property", personCount: 1, listAccessed)
        assertEvent("dynamic list property", personCount: 1, listAccessed)

        let dictionaryAccessed: NSDictionary = [
            "_id": id!.stringValue,
            "realm_id": NSNull(),
            "person": idOnly(a),
            "people": [idOnly(b), idOnly(c)],
            "peopleByName": [b.firstName: full(b), c.firstName: full(c)]
        ]
        assertEvent("dictionary property", personCount: 1, dictionaryAccessed)
        assertEvent("dynamic dictionary property", personCount: 1, dictionaryAccessed)
    }

    @MainActor
    func testMetadata() throws {
        let realm = try openRealm()
        let events = realm.events!

        func writeEvent(_ name: String) throws {
            try scope(events, name) {
                try realm.write {
                    realm.add(SwiftPerson())
                }
            }
        }

        try writeEvent("no metadata")
        events.updateMetadata(["userId": "a"])
        try writeEvent("userId a")
        events.updateMetadata(["userId": "b"])
        try writeEvent("userId b")
        events.updateMetadata([:])
        try writeEvent("metadata removed")

        let result = getEvents(expectedCount: 4)
        assertEvent(result, activity: "no metadata", userId: nil)
        assertEvent(result, activity: "userId a", userId: "a")
        assertEvent(result, activity: "userId b", userId: "b")
        assertEvent(result, activity: "metadata removed", userId: nil)
    }

    @MainActor
    func testCustomLogger() throws {
        let ex = expectation(description: "saw message with scope name")
        ex.assertForOverFulfill = false
        var config = try configuration()
        config.eventConfiguration!.logger = { _, message in
            // Mostly just verify that the user-provided logger is wired up
            // correctly and not that the log messages are sensible
            if message.contains("a scope name") {
                ex.fulfill()
            }
        }
        let realm = try Realm(configuration: config)
        let scope = realm.events!.beginScope(activity: "a scope name")
        scope.commit().await(self)
        waitForExpectations(timeout: 2.0)
    }

    @MainActor
    func testCustomEvent() throws {
        let realm = try openRealm()
        let events = realm.events!

        events.recordEvent(activity: "no event or data")
        events.recordEvent(activity: "event", eventType: "custom event")
        events.recordEvent(activity: "json data", data: "{\"foo\": \"bar\"}")
        events.recordEvent(activity: "non-json data", data: "not valid json")
        events.recordEvent(activity: "event and data", eventType: "custom json event",
                          data: "{\"bar\": \"foo\"}").await(self)

        let result = getEvents(expectedCount: 5)
        assertEvent(result, activity: "no event or data", event: nil, nil)
        assertEvent(result, activity: "event", event: "custom event", nil)
        assertEvent(result, activity: "json data", event: nil, ["foo": "bar"])
        assertEvent(result, activity: "non-json data", event: nil, data: "not valid json")
        assertEvent(result, activity: "event and data", event: "custom json event", ["bar": "foo"])
    }

    @MainActor
    func testScopeLifetimes() throws {
        let realm = try openRealm()
        let events = realm.events!

        try autoreleasepool { () -> Future<Void, Error> in
            let scope1 = events.beginScope(activity: "scope 1")
            let scope2 = events.beginScope(activity: "scope 2")
            let scope3 = events.beginScope(activity: "scope 3")

            try realm.write {
                realm.add(SwiftPerson())
            }

            scope1.cancel()
            XCTAssertTrue(scope2.isActive) // ensure scope stays alive to here
            return scope3.commit()
        }.await(self)

        let result = getEvents(expectedCount: 1)
        XCTAssertEqual(result[0].activity, "scope 3")
    }

    @MainActor
    func testScopeCanOutliveSourceRealm() throws {
        var scope: Events.Scope?
        try autoreleasepool {
            let realm = try openRealm()
            let events = realm.events!
            scope = events.beginScope(activity: "scope")
            try realm.write {
                realm.add(SwiftPerson())
            }
        }

        scope?.commit().await(self)

        let result = getEvents(expectedCount: 1)
        XCTAssertEqual(result[0].activity, "scope")
    }

    @MainActor
    func testErrorHandler() throws {
        var config = try configuration()
        let blockCalled = Locked(false)
        let ex = expectation(description: "Error callback called")
        var eventConfiguration = config.eventConfiguration!
        eventConfiguration.errorHandler = { error in
            assertSyncError(error, .clientInternalError,
                            "Invalid schema change (UPLOAD): non-breaking schema change: adding \"String\" column at field \"invalid metadata field\" in schema \"AuditEvent\", schema changes from clients are restricted when developer mode is disabled")
            blockCalled.value = true
            ex.fulfill()
        }
        eventConfiguration.metadata = ["invalid metadata field": "value"]
        config.eventConfiguration = eventConfiguration
        let realm = try openRealm(configuration: config)
        let events = realm.events!

        // Recording the audit event should succeed, but we should get a sync
        // error when trying to actually upload it due to the user having
        // an invalid access token
        events.recordEvent(activity: "activity which should fail").await(self)
        wait(for: [ex], timeout: 4.0)
    }
}
