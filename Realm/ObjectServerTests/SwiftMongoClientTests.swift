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

import Combine
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
import RealmSwiftTestSupport
#endif

// MARK: - SwiftMongoClientTests
@available(macOS 13.0, *)
class SwiftMongoClientTests: SwiftSyncTestCase {
    override var objectTypes: [ObjectBase.Type] {
        [Dog.self]
    }

    override func tearDown() {
        _ = setupMongoCollection()
        super.tearDown()
    }

    @MainActor
    func testMongoClient() {
        let user = try! logInUser(for: .anonymous)
        let mongoClient = user.mongoClient("mongodb1")
        XCTAssertEqual(mongoClient.name, "mongodb1")
        let database = mongoClient.database(named: "test_data")
        XCTAssertEqual(database.name, "test_data")
        let collection = database.collection(withName: "Dog")
        XCTAssertEqual(collection.name, "Dog")
    }

    func setupMongoCollection() -> MongoCollection {
        let collection = createUser().collection(for: Dog.self, app: app)
        removeAllFromCollection(collection)
        return collection
    }

    func testMongoOptions() {
        let findOptions = FindOptions(1)
        let findOptions1 = FindOptions(5, ["name": 1], [["_id": 1]])
        let findOptions2 = FindOptions(5, ["names": ["fido", "bob", "rex"]], [["_id": 1]])
        let findOptions3 = FindOptions(5, ["names": ["fido", "bob", "rex"]], [["_id": 1], ["breed": 0]])

        XCTAssertEqual(findOptions.limit, 1)
        XCTAssertEqual(findOptions.projection, nil)
        XCTAssertTrue(findOptions.sorting.isEmpty)

        XCTAssertEqual(findOptions1.limit, 5)
        XCTAssertEqual(findOptions1.projection, ["name": 1])
        XCTAssertTrue(findOptions1.sorting == [["_id": 1]])

        XCTAssertEqual(findOptions2.limit, 5)
        XCTAssertEqual(findOptions2.projection, ["names": ["fido", "bob", "rex"]])
        XCTAssertTrue(findOptions2.sorting == [["_id": 1]])

        XCTAssertEqual(findOptions3.limit, 5)
        XCTAssertEqual(findOptions3.projection, ["names": ["fido", "bob", "rex"]])
        XCTAssertTrue(findOptions3.sorting == [["_id": 1], ["breed": 0]])

        let findModifyOptions = FindOneAndModifyOptions(["name": 1], [["_id": 1], ["breed": 0]], true, true)
        XCTAssertEqual(findModifyOptions.projection, ["name": 1])
        XCTAssertEqual(findModifyOptions.sorting, [["_id": 1], ["breed": 0]])
        XCTAssertTrue(findModifyOptions.upsert)
        XCTAssertTrue(findModifyOptions.shouldReturnNewDocument)
    }

    func testMongoInsertResultCompletion() {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "tibetan mastiff"]

        let insertOneEx1 = expectation(description: "Insert one document")
        collection.insertOne(document) { result in
            if case .failure = result {
                XCTFail("Should insert")
            }
            insertOneEx1.fulfill()
        }
        wait(for: [insertOneEx1], timeout: 20.0)

        let insertManyEx1 = expectation(description: "Insert many documents")
        collection.insertMany([document, document2]) { result in
            switch result {
            case .success(let objectIds):
                XCTAssertEqual(objectIds.count, 2)
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx1.fulfill()
        }
        wait(for: [insertManyEx1], timeout: 20.0)

        let findEx1 = expectation(description: "Find documents")
        collection.find(filter: [:]) { result in
            switch result {
            case .success(let documents):
                XCTAssertEqual(documents.count, 3)
                XCTAssertEqual(documents[0]["name"]??.stringValue, "fido")
                XCTAssertEqual(documents[1]["name"]??.stringValue, "fido")
                XCTAssertEqual(documents[2]["name"]??.stringValue, "rex")
            case .failure:
                XCTFail("Should find")
            }
            findEx1.fulfill()
        }
        wait(for: [findEx1], timeout: 20.0)
    }

    func testMongoFindResultCompletion() {
        let collection = setupMongoCollection()

        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "tibetan mastiff"]
        let document3: Document = ["name": "rex", "breed": "tibetan mastiff", "coat": ["fawn", "brown", "white"]]
        let findOptions = FindOptions(1, nil)

        let insertManyEx1 = expectation(description: "Insert many documents")
        collection.insertMany([document, document2, document3]) { result in
            switch result {
            case .success(let objectIds):
                XCTAssertEqual(objectIds.count, 3)
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx1.fulfill()
        }
        wait(for: [insertManyEx1], timeout: 20.0)

        let findEx1 = expectation(description: "Find documents")
        collection.find(filter: [:]) { result in
                switch result {
                case .success(let documents):
                    XCTAssertEqual(documents.count, 3)
                    XCTAssertEqual(documents[0]["name"]??.stringValue, "fido")
                    XCTAssertEqual(documents[1]["name"]??.stringValue, "rex")
                    XCTAssertEqual(documents[2]["name"]??.stringValue, "rex")
                case .failure:
                    XCTFail("Should find")
                }
            findEx1.fulfill()
        }
        wait(for: [findEx1], timeout: 20.0)

        let findEx2 = expectation(description: "Find documents")
        collection.find(filter: [:], options: findOptions) { result in
            switch result {
            case .success(let document):
                XCTAssertEqual(document.count, 1)
                XCTAssertEqual(document[0]["name"]??.stringValue, "fido")
            case .failure:
                XCTFail("Should find")
            }
            findEx2.fulfill()
        }
        wait(for: [findEx2], timeout: 20.0)

        let findEx3 = expectation(description: "Find documents")
        collection.find(filter: document3, options: findOptions) { result in
            switch result {
            case .success(let documents):
                XCTAssertEqual(documents.count, 1)
            case .failure:
                XCTFail("Should find")
            }
            findEx3.fulfill()
        }
        wait(for: [findEx3], timeout: 20.0)

        let findOneEx1 = expectation(description: "Find one document")
        collection.findOneDocument(filter: document) { result in
            switch result {
            case .success(let document):
                XCTAssertNotNil(document)
            case .failure:
                XCTFail("Should find")
            }
            findOneEx1.fulfill()
        }
        wait(for: [findOneEx1], timeout: 20.0)

        let findOneEx2 = expectation(description: "Find one document")
        collection.findOneDocument(filter: document, options: findOptions) { result in
            switch result {
            case .success(let document):
                XCTAssertNotNil(document)
            case .failure:
                XCTFail("Should find")
            }
            findOneEx2.fulfill()
        }
        wait(for: [findOneEx2], timeout: 20.0)
    }

    func testMongoFindAndReplaceResultCompletion() {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]

        let findOneReplaceEx1 = expectation(description: "Find one document and replace")
        collection.findOneAndReplace(filter: document, replacement: document2) { result in
            switch result {
            case .success(let document):
                // no doc found, both should be nil
                XCTAssertNil(document)
            case .failure:
                XCTFail("Should find")
            }
            findOneReplaceEx1.fulfill()
        }
        wait(for: [findOneReplaceEx1], timeout: 20.0)

        let options1 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, true)
        let findOneReplaceEx2 = expectation(description: "Find one document and replace")
        collection.findOneAndReplace(filter: document2, replacement: document3, options: options1) { result in
            switch result {
            case .success(let document):
                XCTAssertEqual(document!["name"]??.stringValue, "john")
            case .failure:
                XCTFail("Should find")
            }
            findOneReplaceEx2.fulfill()
        }
        wait(for: [findOneReplaceEx2], timeout: 20.0)

        let options2 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, false)
        let findOneReplaceEx3 = expectation(description: "Find one document and replace")
        collection.findOneAndReplace(filter: document, replacement: document2, options: options2) { result in
            switch result {
            case .success(let document):
                // upsert but do not return document
                XCTAssertNil(document)
            case .failure:
                XCTFail("Should find")
            }
            findOneReplaceEx3.fulfill()
        }
        wait(for: [findOneReplaceEx3], timeout: 20.0)
    }

    func testMongoFindAndUpdateResultCompletion() {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]

        let findOneUpdateEx1 = expectation(description: "Find one document and update")
        collection.findOneAndUpdate(filter: document, update: document2) { result in
            switch result {
            case .success(let document):
                // no doc found, both should be nil
                XCTAssertNil(document)
            case .failure:
                XCTFail("Should find")
            }
            findOneUpdateEx1.fulfill()
        }
        wait(for: [findOneUpdateEx1], timeout: 20.0)

        let options1 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, true)
        let findOneUpdateEx2 = expectation(description: "Find one document and update")
        collection.findOneAndUpdate(filter: document2, update: document3, options: options1) { result in
            switch result {
            case .success(let document):
                XCTAssertNotNil(document)
                XCTAssertEqual(document!["name"]??.stringValue, "john")
            case .failure:
                XCTFail("Should find")
            }
            findOneUpdateEx2.fulfill()
        }
        wait(for: [findOneUpdateEx2], timeout: 20.0)

        let options2 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, true)
        let findOneUpdateEx3 = expectation(description: "Find one document and update")
        collection.findOneAndUpdate(filter: document, update: document2, options: options2) { result in
            switch result {
            case .success(let document):
                XCTAssertNotNil(document)
                XCTAssertEqual(document!["name"]??.stringValue, "rex")
            case .failure:
                XCTFail("Should find")
            }
            findOneUpdateEx3.fulfill()
        }
        wait(for: [findOneUpdateEx3], timeout: 20.0)
    }

    func testMongoFindAndDeleteResultCompletion() {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]

        let insertManyEx = expectation(description: "Insert many documents")
        collection.insertMany([document, document]) { result in
            switch result {
            case .success(let objectIds):
                XCTAssertEqual(objectIds.count, 2)
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx.fulfill()
        }
        wait(for: [insertManyEx], timeout: 20.0)

        let findOneDeleteEx1 = expectation(description: "Find one document and delete")
        collection.findOneAndDelete(filter: document) { result in
            switch result {
            case .success(let document):
                // Document does not exist, but should not return an error because of that
                XCTAssertNotNil(document)
            case .failure:
                XCTFail("Should find")
            }
            findOneDeleteEx1.fulfill()
        }
        wait(for: [findOneDeleteEx1], timeout: 20.0)

        let options1 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], false, false)
        let findOneDeleteEx2 = expectation(description: "Find one document and delete")
        collection.findOneAndDelete(filter: document, options: options1) { result in
            switch result {
            case .success(let document):
                XCTAssertNotNil(document)
                XCTAssertEqual(document!["name"]??.stringValue, "fido")
                findOneDeleteEx2.fulfill()
            case .failure:
                XCTFail("Should find")
            }
        }
        wait(for: [findOneDeleteEx2], timeout: 20.0)

        let options2 = FindOneAndModifyOptions(["name": 1], [["_id": 1]])
        let findOneDeleteEx3 = expectation(description: "Find one document and delete")
        collection.findOneAndDelete(filter: document, options: options2) { result in
            switch result {
            case .success(let document):
                // Document does not exist, but should not return an error because of that
                XCTAssertNil(document)
                findOneDeleteEx3.fulfill()
            case .failure:
                XCTFail("Should find")
            }
        }
        wait(for: [findOneDeleteEx3], timeout: 20.0)

        let findEx = expectation(description: "Find documents")
        collection.find(filter: [:]) { result in
            switch result {
            case .success(let documents):
                XCTAssertEqual(documents.count, 0)
            case .failure:
                XCTFail("Should find")
            }
            findEx.fulfill()
        }
        wait(for: [findEx], timeout: 20.0)
    }

    func testMongoUpdateOneResultCompletion() {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]
        let document4: Document = ["name": "ted", "breed": "bullmastiff"]
        let document5: Document = ["name": "bill", "breed": "great dane"]

        let insertManyEx = expectation(description: "Insert many documents")
        collection.insertMany([document, document2, document3, document4]) { result in
            switch result {
            case .success(let objectIds):
                XCTAssertEqual(objectIds.count, 4)
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx.fulfill()
        }
        wait(for: [insertManyEx], timeout: 20.0)

        let updateEx1 = expectation(description: "Update one document")
        collection.updateOneDocument(filter: document, update: document2) { result in
            switch result {
            case .success(let updateResult):
                XCTAssertEqual(updateResult.matchedCount, 1)
                XCTAssertEqual(updateResult.modifiedCount, 1)
                XCTAssertNil(updateResult.documentId)
            case .failure:
                XCTFail("Should update")
            }
            updateEx1.fulfill()
        }
        wait(for: [updateEx1], timeout: 20.0)

        let updateEx2 = expectation(description: "Update one document")
        collection.updateOneDocument(filter: document5, update: document2, upsert: true) { result in
            switch result {
            case .success(let updateResult):
                XCTAssertEqual(updateResult.matchedCount, 0)
                XCTAssertEqual(updateResult.modifiedCount, 0)
                XCTAssertNotNil(updateResult.documentId)
            case .failure:
                XCTFail("Should update")
            }
            updateEx2.fulfill()
        }
        wait(for: [updateEx2], timeout: 20.0)
    }

    func testMongoUpdateManyResultCompletion() {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]
        let document4: Document = ["name": "ted", "breed": "bullmastiff"]
        let document5: Document = ["name": "bill", "breed": "great dane"]

        let insertManyEx = expectation(description: "Insert many documents")
        collection.insertMany([document, document2, document3, document4]) { result in
            switch result {
            case .success(let objectIds):
                XCTAssertEqual(objectIds.count, 4)
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx.fulfill()
        }
        wait(for: [insertManyEx], timeout: 20.0)

        let updateEx1 = expectation(description: "Update one document")
        collection.updateManyDocuments(filter: document, update: document2) { result in
            switch result {
            case .success(let updateResult):
                XCTAssertEqual(updateResult.matchedCount, 1)
                XCTAssertEqual(updateResult.modifiedCount, 1)
                XCTAssertNil(updateResult.documentId)
            case .failure:
                XCTFail("Should update")
            }
            updateEx1.fulfill()
        }
        wait(for: [updateEx1], timeout: 20.0)

        let updateEx2 = expectation(description: "Update one document")
        collection.updateManyDocuments(filter: document5, update: document2, upsert: true) { result in
            switch result {
            case .success(let updateResult):
                XCTAssertEqual(updateResult.matchedCount, 0)
                XCTAssertEqual(updateResult.modifiedCount, 0)
                XCTAssertNotNil(updateResult.documentId)
            case .failure:
                XCTFail("Should update")
            }
            updateEx2.fulfill()
        }
        wait(for: [updateEx2], timeout: 20.0)
    }

    func testMongoDeleteOneResultCompletion() {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]

        let deleteEx1 = expectation(description: "Delete 0 documents")
        collection.deleteOneDocument(filter: document) { result in
            switch result {
            case .success(let count):
                XCTAssertEqual(count, 0)
            case .failure:
                XCTFail("Should delete")
            }
            deleteEx1.fulfill()
        }
        wait(for: [deleteEx1], timeout: 20.0)

        let insertManyEx = expectation(description: "Insert many documents")
        collection.insertMany([document, document2]) { result in
            switch result {
            case .success(let objectIds):
                XCTAssertEqual(objectIds.count, 2)
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx.fulfill()
        }
        wait(for: [insertManyEx], timeout: 20.0)

        let deleteEx2 = expectation(description: "Delete one document")
        collection.deleteOneDocument(filter: document) { result in
            switch result {
            case .success(let count):
                XCTAssertEqual(count, 1)
            case .failure:
                XCTFail("Should delete")
            }
            deleteEx2.fulfill()
        }
        wait(for: [deleteEx2], timeout: 20.0)
    }

    func testMongoDeleteManyResultCompletion() {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]

        let deleteEx1 = expectation(description: "Delete 0 documents")
        collection.deleteManyDocuments(filter: document) { result in
            switch result {
            case .success(let count):
                XCTAssertEqual(count, 0)
            case .failure:
                XCTFail("Should delete")
            }
            deleteEx1.fulfill()
        }
        wait(for: [deleteEx1], timeout: 20.0)

        let insertManyEx = expectation(description: "Insert many documents")
        collection.insertMany([document, document2]) { result in
            switch result {
            case .success(let objectIds):
                XCTAssertEqual(objectIds.count, 2)
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx.fulfill()
        }
        wait(for: [insertManyEx], timeout: 20.0)

        let deleteEx2 = expectation(description: "Delete one document")
        collection.deleteManyDocuments(filter: ["breed": "cane corso"]) { result in
            switch result {
            case .success(let count):
                XCTAssertEqual(count, 2)
            case .failure:
                XCTFail("Should selete")
            }
            deleteEx2.fulfill()
        }
        wait(for: [deleteEx2], timeout: 20.0)
    }

    func testMongoCountAndAggregateResultCompletion() {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]

        let insertManyEx1 = expectation(description: "Insert many documents")
        collection.insertMany([document]) { result in
            switch result {
            case .success(let objectIds):
                XCTAssertEqual(objectIds.count, 1)
            case .failure(let error):
                XCTFail("Insert failed: \(error)")
            }
            insertManyEx1.fulfill()
        }
        wait(for: [insertManyEx1], timeout: 20.0)

        collection.aggregate(pipeline: [["$match": ["name": "fido"]], ["$group": ["_id": "$name"]]]) { result in
            switch result {
            case .success(let documents):
                XCTAssertNotNil(documents)
            case .failure(let error):
                XCTFail("Aggregate failed: \(error)")
            }
        }

        let countEx1 = expectation(description: "Count documents")
        collection.count(filter: document) { result in
            switch result {
            case .success(let count):
                XCTAssertNotNil(count)
            case .failure(let error):
                XCTFail("Count failed: \(error)")
            }
            countEx1.fulfill()
        }
        wait(for: [countEx1], timeout: 20.0)

        let countEx2 = expectation(description: "Count documents")
        collection.count(filter: document, limit: 1) { result in
            switch result {
            case .success(let count):
                XCTAssertEqual(count, 1)
            case .failure(let error):
                XCTFail("Count failed: \(error)")
            }
            countEx2.fulfill()
        }
        wait(for: [countEx2], timeout: 20.0)
    }

    func testWatch() throws {
        try performWatchTest(.main)
    }

    func testWatchAsync() throws {
        let queue = DispatchQueue(label: "io.realm.watchQueue", attributes: .concurrent)
        try performWatchTest(queue)
    }

    func performWatchTest(_ queue: DispatchQueue) throws {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]

        let watchTestUtility = WatchTestUtility(testCase: self)
        let changeStream = collection.watch(delegate: watchTestUtility, queue: queue)
        watchTestUtility.waitForOpen()
        for _ in 0..<3 {
            watchTestUtility.expectEvent()
            collection.insertOne(document) { result in
                if case .failure = result {
                    XCTFail("Should insert")
                }
            }
            try watchTestUtility.waitForEvent()
        }
        changeStream.close()
        watchTestUtility.waitForClose()
    }

    @MainActor
    func testWatchWithMatchFilter() throws {
        try performWatchWithMatchFilterTest(.main)
    }

    @MainActor
    func testWatchWithMatchFilterQueue() throws {
        let queue = DispatchQueue(label: "io.realm.watchQueue", attributes: .concurrent)
        try performWatchWithMatchFilterTest(queue)
    }

    @MainActor
    func insertDocuments(_ collection: MongoCollection) -> [ObjectId] {
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]
        let document4: Document = ["name": "ted", "breed": "bullmastiff"]

        let objectIds = collection.insertMany([document, document2, document3, document4])
            .map { @Sendable in $0.map(\.objectIdValue!) }
            .await(self)
        XCTAssertEqual(objectIds.count, 4)
        return objectIds
    }

    @MainActor
    func performWatchWithMatchFilterTest(_ queue: DispatchQueue?) throws {
        let collection = setupMongoCollection()
        let objectIds = insertDocuments(collection)
        let watchTestUtility = WatchTestUtility(testCase: self, matchingObjectId: objectIds.first!)

        let filter = ["fullDocument._id": AnyBSON.objectId(objectIds[0])]
        let changeStream: ChangeStream
        if let queue = queue {
            changeStream = collection.watch(matchFilter: filter, delegate: watchTestUtility, queue: queue)
        } else {
            changeStream = collection.watch(matchFilter: filter, delegate: watchTestUtility)
        }
        watchTestUtility.waitForOpen()

        for i in 0..<3 {
            watchTestUtility.expectEvent()
            let name: AnyBSON = .string("fido-\(i)")
            collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[0])],
                                         update: ["name": name, "breed": "king charles"]) { result in
                if case .failure = result {
                    XCTFail("Should update")
                }
            }
            collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[1])],
                                         update: ["name": name, "breed": "king charles"]) { result in
                if case .failure = result {
                    XCTFail("Should update")
                }
            }
            try watchTestUtility.waitForEvent()
        }
        changeStream.close()
        watchTestUtility.waitForClose()
    }

    @MainActor
    func testWatchWithFilterIds() throws {
        try performWatchWithFilterIdsTest(nil)
    }

    @MainActor
    func testWatchWithFilterIdsQueue() throws {
        let queue = DispatchQueue(label: "io.realm.watchQueue", attributes: .concurrent)
        try performWatchWithFilterIdsTest(queue)
    }

    @MainActor
    func performWatchWithFilterIdsTest(_ queue: DispatchQueue?) throws {
        let collection = setupMongoCollection()
        let objectIds = insertDocuments(collection)
        let watchTestUtility = WatchTestUtility(testCase: self, matchingObjectId: objectIds.first!)
        let changeStream: ChangeStream
        if let queue = queue {
            changeStream = collection.watch(filterIds: [objectIds[0]], delegate: watchTestUtility, queue: queue)
        } else {
            changeStream = collection.watch(filterIds: [objectIds[0]], delegate: watchTestUtility)
        }
        watchTestUtility.waitForOpen()

        for i in 0..<3 {
            watchTestUtility.expectEvent()
            let name: AnyBSON = .string("fido-\(i)")
            collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[0])],
                                         update: ["name": name, "breed": "king charles"]) { result in
                if case .failure = result {
                    XCTFail("Should update")
                }
            }
            collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[1])],
                                         update: ["name": name, "breed": "king charles"]) { result in
                if case .failure = result {
                    XCTFail("Should update")
                }
            }
            try watchTestUtility.waitForEvent()
        }
        changeStream.close()
        watchTestUtility.waitForClose()
    }

    @available(macOS 13, *)
    @MainActor
    func performAsyncWatchTest(filterIds: Bool = false, matchFilter: Bool = false) async throws {
        let collection = setupMongoCollection()
        let objectIds = insertDocuments(collection)

        let openEx = expectation(description: "open watch stream")
        @Locked var ex: XCTestExpectation!
        let task = Task {
            let changeEvents: AsyncThrowingPublisher<Publishers.WatchPublisher>
            if filterIds {
                changeEvents = collection.changeEvents(filterIds: [objectIds[0]],
                                                       onOpen: { openEx.fulfill() })
            } else if matchFilter {
                let filter = ["fullDocument._id": AnyBSON.objectId(objectIds[0])]
                changeEvents = collection.changeEvents(matchFilter: filter, onOpen: { openEx.fulfill() })
            } else {
                changeEvents = collection.changeEvents(onOpen: { openEx.fulfill() })
            }

            for try await event in changeEvents {
                let doc = event.documentValue!
                XCTAssertEqual(doc["operationType"], "replace")
                let id = try XCTUnwrap(doc["documentKey"]??.documentValue?["_id"]??.objectIdValue)
                XCTAssertEqual(id, objectIds[0])
                ex.fulfill()
            }
        }
        await fulfillment(of: [openEx], timeout: 2.0)

        for i in 0..<3 {
            ex = expectation(description: "got change event")
            let name: AnyBSON = .string("fido-\(i)")
            _ = try await collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[0])],
                                                       update: ["name": name, "breed": "king charles"])
            if filterIds || matchFilter {
                _ = try await collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[1])],
                                                           update: ["name": name, "breed": "king charles"])
            }
            await fulfillment(of: [ex], timeout: 2.0)
        }

        task.cancel()
        _ = await task.result
    }

    @available(macOS 13, *)
    func testWatchAsync() async throws {
        try await performAsyncWatchTest()
    }

    @available(macOS 13, *)
    func testWatchWithMatchFilterAsync() async throws {
        try await performAsyncWatchTest(matchFilter: true)
    }

    @available(macOS 13, *)
    func testWatchWithFilterIdsAsync() async throws {
        try await performAsyncWatchTest(filterIds: true)
    }

    @MainActor
    func testWatchMultipleFilterStreams() throws {
        try performMultipleWatchStreamsTest(nil)
    }

    @MainActor
    func testWatchMultipleFilterStreamsAsync() throws {
        let queue = DispatchQueue(label: "io.realm.watchQueue", attributes: .concurrent)
        try performMultipleWatchStreamsTest(queue)
    }

    @MainActor
    func performMultipleWatchStreamsTest(_ queue: DispatchQueue?) throws {
        let collection = setupMongoCollection()
        let objectIds = insertDocuments(collection)
        let watchTestUtility1 = WatchTestUtility(testCase: self, matchingObjectId: objectIds[0])
        let watchTestUtility2 = WatchTestUtility(testCase: self, matchingObjectId: objectIds[1])

        let changeStream1: ChangeStream
        let changeStream2: ChangeStream
        if let queue = queue {
            changeStream1 = collection.watch(filterIds: [objectIds[0]], delegate: watchTestUtility1, queue: queue)
            changeStream2 = collection.watch(filterIds: [objectIds[1]], delegate: watchTestUtility2, queue: queue)
        } else {
            changeStream1 = collection.watch(filterIds: [objectIds[0]], delegate: watchTestUtility1)
            changeStream2 = collection.watch(filterIds: [objectIds[1]], delegate: watchTestUtility2)
        }
        watchTestUtility1.waitForOpen()
        watchTestUtility2.waitForOpen()

        for i in 0..<3 {
            watchTestUtility1.expectEvent()
            watchTestUtility2.expectEvent()
            let name: AnyBSON = .string("fido-\(i)")
            collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[0])],
                                         update: ["name": name, "breed": "king charles"]) { result in
                if case .failure = result {
                    XCTFail("Should update")
                }
            }
            collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[1])],
                                         update: ["name": name, "breed": "king charles"]) { result in
                if case .failure = result {
                    XCTFail("Should update")
                }
            }
            try watchTestUtility1.waitForEvent()
            try watchTestUtility2.waitForEvent()
        }
        changeStream1.close()
        changeStream2.close()
        watchTestUtility1.waitForClose()
        watchTestUtility2.waitForClose()
    }

    @MainActor
    func testShouldNotDeleteOnMigrationWithSync() throws {
        var configuration = try configuration()
        assertThrows(configuration.deleteRealmIfMigrationNeeded = true,
                     reason: "Cannot set 'deleteRealmIfMigrationNeeded' when sync is enabled ('syncConfig' is set).")

        var localConfiguration = Realm.Configuration.defaultConfiguration
        assertSucceeds {
            localConfiguration.deleteRealmIfMigrationNeeded = true
        }
    }
}

// MARK: - AsyncAwaitMongoClientTests
@available(macOS 13, *)
class AsyncAwaitMongoClientTests: SwiftSyncTestCase {
    override var objectTypes: [ObjectBase.Type] {
        [Dog.self]
    }

    override class var defaultTestSuite: XCTestSuite {
        // async/await is currently incompatible with thread sanitizer and will
        // produce many false positives
        // https://bugs.swift.org/browse/SR-15444
        if RLMThreadSanitizerEnabled() {
            return XCTestSuite(name: "\(type(of: self))")
        }
        return super.defaultTestSuite

    }

    func setupMongoCollection() async throws -> MongoCollection {
        let collection = try await createUser().collection(for: Dog.self, app: app)
        _ = try await collection.deleteManyDocuments(filter: [:])
        return collection
    }

    func testMongoFindSortOptions() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "tibetan mastiff"]
        let document3: Document = ["name": "rex", "breed": "cane corso"]
        let document4: Document = ["name": "fido", "breed": "tibetan mastiff"]

        let objectIds = try await collection.insertMany([document, document2, document3, document4])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 4)

        let findOptions = FindOptions(0, nil, [["name": 1], ["breed": 1]])
        let fetchedDocuments = try await collection.find(filter: [:], options: findOptions)
        XCTAssertEqual(fetchedDocuments.count, 4)
        XCTAssertEqual(fetchedDocuments[0]["name"]??.stringValue, "fido")
        XCTAssertEqual(fetchedDocuments[0]["breed"]??.stringValue, "cane corso")
        XCTAssertEqual(fetchedDocuments[1]["name"]??.stringValue, "fido")
        XCTAssertEqual(fetchedDocuments[1]["breed"]??.stringValue, "tibetan mastiff")
        XCTAssertEqual(fetchedDocuments[2]["name"]??.stringValue, "rex")
        XCTAssertEqual(fetchedDocuments[2]["breed"]??.stringValue, "cane corso")
        XCTAssertEqual(fetchedDocuments[3]["name"]??.stringValue, "rex")
        XCTAssertEqual(fetchedDocuments[3]["breed"]??.stringValue, "tibetan mastiff")


        for try _ in 0...10 {
            let findOptions2 = FindOptions(0, nil, [["name": 1], ["breed": 1]])
            let fetchedDocuments2 = try await collection.find(filter: [:], options: findOptions2)
            XCTAssertEqual(fetchedDocuments[0]["name"], fetchedDocuments2[0]["name"])
            XCTAssertEqual(fetchedDocuments[0]["breed"], fetchedDocuments2[0]["breed"])
            XCTAssertEqual(fetchedDocuments[1]["name"], fetchedDocuments2[1]["name"])
            XCTAssertEqual(fetchedDocuments[1]["breed"], fetchedDocuments2[1]["breed"])
            XCTAssertEqual(fetchedDocuments[2]["name"], fetchedDocuments2[2]["name"])
            XCTAssertEqual(fetchedDocuments[2]["breed"], fetchedDocuments2[2]["breed"])
            XCTAssertEqual(fetchedDocuments[3]["name"], fetchedDocuments2[3]["name"])
            XCTAssertEqual(fetchedDocuments[3]["breed"], fetchedDocuments2[3]["breed"])
        }

        let findOptions3 = FindOptions(0, nil, [["breed": 1], ["name": 1]])
        let fetchedDocuments3 = try await collection.find(filter: [:], options: findOptions3)
        XCTAssertEqual(fetchedDocuments3.count, 4)
        XCTAssertEqual(fetchedDocuments3[0]["name"]??.stringValue, "fido")
        XCTAssertEqual(fetchedDocuments3[0]["breed"]??.stringValue, "cane corso")
        XCTAssertEqual(fetchedDocuments3[3]["name"]??.stringValue, "rex")
        XCTAssertEqual(fetchedDocuments3[3]["breed"]??.stringValue, "tibetan mastiff")
    }

    func testMongoCollectionInsertOneAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let objectId = try await collection.insertOne(document)
        XCTAssertNotNil(objectId)
        let fetchedDocument = try await collection.find(filter: document)
        XCTAssertEqual(fetchedDocument[0]["name"]??.stringValue, "tomas")
    }

    func testMongoCollectionInsertManyAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document1: Document = ["name": "lucas", "breed": "german shepard"]
        let document2: Document = ["name": "fito", "breed": "goberian"]
        let objectIds = try await collection.insertMany([document1, document2])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 2)

        let fetchedDocuments = try await collection.find(filter: [:])
        XCTAssertEqual(fetchedDocuments.count, 2)
        XCTAssertEqual(fetchedDocuments[0]["name"]??.stringValue, "lucas")
    }

    func testMongoCollectionFindAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "lucas", "breed": "german shepard"]
        let document2: Document = ["name": "fito", "breed": "goberian"]
        let document3: Document = ["name": "fosca", "breed": "labradoodle"]
        let objectIds = try await collection.insertMany([document, document1, document2, document3])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 4)

        // Test filter all
        let fetchedDocuments = try await collection.find(filter: [:])
        XCTAssertEqual(fetchedDocuments.count, 4)
        XCTAssertEqual(fetchedDocuments[0]["name"]??.stringValue, "tomas")
        XCTAssertEqual(fetchedDocuments[1]["name"]??.stringValue, "lucas")
        XCTAssertEqual(fetchedDocuments[2]["breed"]??.stringValue, "goberian")
        XCTAssertEqual(fetchedDocuments[3]["breed"]??.stringValue, "labradoodle")

        // Test filter all with option limit to one
        let findOptions = FindOptions(1, nil)
        let fetchedDocuments2 = try await collection.find(filter: [:], options: findOptions)
        XCTAssertEqual(fetchedDocuments2.count, 1)
        XCTAssertEqual(fetchedDocuments2[0]["name"]??.stringValue, "tomas")

        // Test filter by document
        let fetchedDocuments3 = try await collection.find(filter: document1, options: findOptions)
        XCTAssertEqual(fetchedDocuments3.count, 1)
        XCTAssertEqual(fetchedDocuments3[0]["name"]??.stringValue, document1["name"]??.stringValue)

        // Test filter not matching
        let fetchedDocuments4 = try await collection.find(filter: ["name": "oliver"])
        XCTAssertEqual(fetchedDocuments4.count, 0)
    }

    func testMongoCollectionFindOneAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "lucas", "breed": "german shepard"]
        let document2: Document = ["name": "fito", "breed": "goberian"]
        let document3: Document = ["name": "fosca", "breed": "labradoodle"]
        let objectIds = try await collection.insertMany([document, document1, document2, document3])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 4)

        // Test findOne all
        let fetchedOneDocument = try await collection.findOneDocument(filter: document)
        XCTAssertNotNil(fetchedOneDocument)
        XCTAssertEqual(fetchedOneDocument?["name"]??.stringValue, "tomas")
        XCTAssertEqual(fetchedOneDocument?["breed"]??.stringValue, "jack rusell")

        // Test findOne all with option limit
        let findOptions = FindOptions(1, nil)
        let fetchedOneDocument2 = try await collection.findOneDocument(filter: [:], options: findOptions)
        XCTAssertNotNil(fetchedOneDocument2)

        // Test filter not matching
        let fetchedOneDocument3 = try await collection.findOneDocument(filter: ["name": "oliver"])
        XCTAssertNil(fetchedOneDocument3)
    }

    func testMongoCollectionFindAndReplaceAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "lucas", "breed": "german shepard"]
        let document2: Document = ["name": "fito", "breed": "goberian"]
        let document3: Document = ["name": "fosca", "breed": "labradoodle"]

        // Test find and replace non-existent element
        let resultDocument = try await collection.findOneAndReplace(filter: document, replacement: document3)
        XCTAssertNil(resultDocument)

        let objectId = try await collection.insertOne(document)
        XCTAssertNotNil(objectId)

        let resultReplacedDocument = try await collection.findOneAndReplace(filter: document, replacement: document3)
        XCTAssertNotNil(resultReplacedDocument)
        XCTAssertEqual(resultReplacedDocument?["name"]??.stringValue, "tomas") // shouldReturnNewDocument is false that is why returns old document

        let options1 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, true)
        let resultReplacedDocument2 = try await collection.findOneAndReplace(filter: document1, replacement: document2, options: options1)
        XCTAssertNotNil(resultReplacedDocument2)
        XCTAssertEqual(resultReplacedDocument2?["name"]??.stringValue, "fito")

        let options2 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, false)
        let resultReplacedDocument3 = try await collection.findOneAndReplace(filter: document, replacement: document1, options: options2)
        XCTAssertNil(resultReplacedDocument3)
    }

    func testMongoCollectionFindAndUpdateAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "lucas", "breed": "german shepard"]
        let document2: Document = ["name": "fito", "breed": "goberian"]
        let document3: Document = ["name": "fosca", "breed": "labradoodle"]

        // Test find and update non-existent element
        let resultDocument = try await collection.findOneAndUpdate(filter: document, update: document3)
        XCTAssertNil(resultDocument)

        let objectId = try await collection.insertOne(document)
        XCTAssertNotNil(objectId)

        let resultUpdatedDocument = try await collection.findOneAndUpdate(filter: document, update: document3)
        XCTAssertNotNil(resultUpdatedDocument)
        XCTAssertEqual(resultUpdatedDocument?["name"]??.stringValue, "tomas") // shouldReturnNewDocument is false that is why returns old document

        let options1 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, true)
        let resultUpdatedDocument2 = try await collection.findOneAndUpdate(filter: document1, update: document2, options: options1)
        XCTAssertNotNil(resultUpdatedDocument2)
        XCTAssertEqual(resultUpdatedDocument2?["name"]??.stringValue, "fito")

        let options2 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, false)
        let resultUpdatedDocument3 = try await collection.findOneAndUpdate(filter: document, update: document1, options: options2)
        XCTAssertNil(resultUpdatedDocument3)
    }

    func testMongoCollectionFindAndDeleteAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "lucas", "breed": "german shepard"]
        let document2: Document = ["name": "fito", "breed": "goberian"]
        let document3: Document = ["name": "fosca", "breed": "labradoodle"]

        let objectIds = try await collection.insertMany([document, document1, document2, document3])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 4)

        // Returning a document means that it was found and deleted
        let deletedDocument = try await collection.findOneAndDelete(filter: document)
        XCTAssertNotNil(deletedDocument)
        XCTAssertEqual(deletedDocument?["name"]??.stringValue, "tomas")

        // Document already deleted, should return nil
        let options2 = FindOneAndModifyOptions(["name": 1], [["_id": 1]])
        let deletedDocument3 = try await collection.findOneAndDelete(filter: document, options: options2)
        XCTAssertNil(deletedDocument3)

        let resultObjectIds = try await collection.find(filter: [:])
        XCTAssertEqual(resultObjectIds.count, 3)
    }

    func testMongoCollectionUpdateOneAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "lucas", "breed": "german shepard"]
        let document2: Document = ["name": "fito", "breed": "goberian"]

        let objectIds = try await collection.insertMany([document, document1])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 2)

        let updatedResult = try await collection.updateOneDocument(filter: document,
                                                                   update: document2)
        XCTAssertNil(updatedResult.documentId)
        XCTAssertEqual(updatedResult.matchedCount, 1)
        XCTAssertEqual(updatedResult.modifiedCount, 1)

        let updatedResult1 = try await collection.updateOneDocument(filter: document,
                                                                    update: document2,
                                                                    upsert: true)
        XCTAssertNotNil(updatedResult1.documentId)
        XCTAssertEqual(updatedResult1.matchedCount, 0)
        XCTAssertEqual(updatedResult1.modifiedCount, 0)
    }

    func testMongoCollectionUpdateManyAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "fito", "breed": "goberian"]
        let document2: Document = ["name": "fosca", "breed": "labradoodle"]

        let objectIds = try await collection.insertMany([document, document1])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 2)

        let updatedResult = try await collection.updateManyDocuments(filter: document,
                                                                     update: document2)
        XCTAssertNil(updatedResult.documentId)
        XCTAssertEqual(updatedResult.matchedCount, 1)
        XCTAssertEqual(updatedResult.modifiedCount, 1)

        let updatedResult2 = try await collection.updateManyDocuments(filter: document,
                                                                      update: document2,
                                                                      upsert: true)
        XCTAssertNotNil(updatedResult2.documentId)
        XCTAssertEqual(updatedResult2.matchedCount, 0)
        XCTAssertEqual(updatedResult2.modifiedCount, 0)
    }

    func testMongoCollectionDeleteOneAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "lucas", "breed": "german shepard"]
        let document2: Document = ["name": "fito", "breed": "goberian"]
        let document3: Document = ["name": "fosca", "breed": "labradoodle"]

        let deletedDocumentCount = try await collection.deleteOneDocument(filter: document)
        XCTAssertEqual(deletedDocumentCount, 0)

        let objectIds = try await collection.insertMany([document, document1, document2, document3])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 4)

        let deletedDocumentCount2 = try await collection.deleteOneDocument(filter: document)
        XCTAssertEqual(deletedDocumentCount2, 1)

        let resultObjectIds2 = try await collection.find(filter: [:])
        XCTAssertEqual(resultObjectIds2.count, 3)
    }

    func testMongoCollectionDeleteManyAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "fito", "breed": "jack rusell"]
        let document2: Document = ["name": "fosca", "breed": "labradoodle"]
        let document3: Document = ["name": "balo", "breed": "pug"]

        let deletedDocumentCount = try await collection.deleteManyDocuments(filter: document)
        XCTAssertEqual(deletedDocumentCount, 0)

        let objectIds = try await collection.insertMany([document, document1, document2, document3])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 4)

        let deletedDocumentCount2 = try await collection.deleteManyDocuments(filter: ["breed": "jack rusell"])
        XCTAssertEqual(deletedDocumentCount2, 2)

        let resultObjectIds2 = try await collection.find(filter: [:])
        XCTAssertEqual(resultObjectIds2.count, 2)
    }

    func testMongoCollectionAggregateAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "lucas", "breed": "german shepard"]

        let objectIds = try await collection.insertMany([document, document1])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 2)

        let documents = try await collection.aggregate(pipeline: [["$match": ["name": "tomas"]], ["$group": ["_id": "$name"]]])
        XCTAssertNotNil(documents)
        XCTAssertEqual(documents.count, 1)
    }

    func testMongoCollectionCountAsyncAwait() async throws {
        let collection = try await setupMongoCollection()

        let document: Document = ["name": "tomas", "breed": "jack rusell"]
        let document1: Document = ["name": "lucas", "breed": "jack rusell"]
        let document2: Document = ["name": "fito", "breed": "goberian"]
        let document3: Document = ["name": "balo", "breed": "pug"]

        let objectIds = try await collection.insertMany([document, document1, document2, document3])
        XCTAssertNotNil(objectIds)
        XCTAssertEqual(objectIds.count, 4)

        let count = try await collection.count(filter: [:])
        XCTAssertEqual(count, 4)

        let count2 = try await collection.count(filter: document)
        XCTAssertEqual(count2, 1)

        let count3 = try await collection.count(filter: ["breed": "jack rusell"])
        XCTAssertEqual(count3, 2)

        let count4 = try await collection.count(filter: [:], limit: 2)
        XCTAssertEqual(count4, 2)

        let count5 = try await collection.count(filter: ["breed": "jack rusell"], limit: 1)
        XCTAssertEqual(count5, 1)
    }
}

#endif // os(macOS)
