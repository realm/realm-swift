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
#endif

// MARK: - SwiftMongoClientTests
class SwiftMongoClientTests: SwiftSyncTestCase {
    override func tearDown() {
        _ = setupMongoCollection()
        super.tearDown()
    }
    func testMongoClient() {
        let user = try! logInUser(for: .anonymous)
        let mongoClient = user.mongoClient("mongodb1")
        XCTAssertEqual(mongoClient.name, "mongodb1")
        let database = mongoClient.database(named: "test_data")
        XCTAssertEqual(database.name, "test_data")
        let collection = database.collection(withName: "Dog")
        XCTAssertEqual(collection.name, "Dog")
    }

    func removeAllFromCollection(_ collection: MongoCollection) {
        let deleteEx = expectation(description: "Delete all from Mongo collection")
        collection.deleteManyDocuments(filter: [:]) { result in
            if case .failure = result {
                XCTFail("Should delete")
            }
            deleteEx.fulfill()
        }
        wait(for: [deleteEx], timeout: 4.0)
    }

    func setupMongoCollection() -> MongoCollection {
        let user = try! logInUser(for: basicCredentials())
        let mongoClient = user.mongoClient("mongodb1")
        let database = mongoClient.database(named: "test_data")
        let collection = database.collection(withName: "Dog")
        removeAllFromCollection(collection)
        return collection
    }

    func testMongoOptions() {
        let findOptions = FindOptions(1, nil, nil)
        let findOptions1 = FindOptions(5, ["name": 1], ["_id": 1])
        let findOptions2 = FindOptions(5, ["names": ["fido", "bob", "rex"]], ["_id": 1])

        XCTAssertEqual(findOptions.limit, 1)
        XCTAssertEqual(findOptions.projection, nil)
        XCTAssertEqual(findOptions.sort, nil)

        XCTAssertEqual(findOptions1.limit, 5)
        XCTAssertEqual(findOptions1.projection, ["name": 1])
        XCTAssertEqual(findOptions1.sort, ["_id": 1])
        XCTAssertEqual(findOptions2.projection, ["names": ["fido", "bob", "rex"]])

        let findModifyOptions = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, true)
        XCTAssertEqual(findModifyOptions.projection, ["name": 1])
        XCTAssertEqual(findModifyOptions.sort, ["_id": 1])
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
        wait(for: [insertOneEx1], timeout: 4.0)

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
        wait(for: [insertManyEx1], timeout: 4.0)

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
        wait(for: [findEx1], timeout: 4.0)
    }

    func testMongoFindResultCompletion() {
        let collection = setupMongoCollection()

        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "tibetan mastiff"]
        let document3: Document = ["name": "rex", "breed": "tibetan mastiff", "coat": ["fawn", "brown", "white"]]
        let findOptions = FindOptions(1, nil, nil)

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
        wait(for: [insertManyEx1], timeout: 4.0)

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
        wait(for: [findEx1], timeout: 4.0)

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
        wait(for: [findEx2], timeout: 4.0)

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
        wait(for: [findEx3], timeout: 4.0)

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
        wait(for: [findOneEx1], timeout: 4.0)

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
        wait(for: [findOneEx2], timeout: 4.0)
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
        wait(for: [findOneReplaceEx1], timeout: 4.0)

        let options1 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, true)
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
        wait(for: [findOneReplaceEx2], timeout: 4.0)

        let options2 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, false)
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
        wait(for: [findOneReplaceEx3], timeout: 4.0)
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
        wait(for: [findOneUpdateEx1], timeout: 4.0)

        let options1 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, true)
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
        wait(for: [findOneUpdateEx2], timeout: 4.0)

        let options2 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, true)
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
        wait(for: [findOneUpdateEx3], timeout: 4.0)
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
        wait(for: [insertManyEx], timeout: 4.0)

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
        wait(for: [findOneDeleteEx1], timeout: 4.0)

        let options1 = FindOneAndModifyOptions(["name": 1], ["_id": 1], false, false)
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
        wait(for: [findOneDeleteEx2], timeout: 4.0)

        let options2 = FindOneAndModifyOptions(["name": 1], ["_id": 1])
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
        wait(for: [findOneDeleteEx3], timeout: 4.0)

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
        wait(for: [findEx], timeout: 4.0)
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
        wait(for: [insertManyEx], timeout: 4.0)

        let updateEx1 = expectation(description: "Update one document")
        collection.updateOneDocument(filter: document, update: document2) { result in
            switch result {
            case .success(let updateResult):
                XCTAssertEqual(updateResult.matchedCount, 1)
                XCTAssertEqual(updateResult.modifiedCount, 1)
                XCTAssertNil(updateResult.objectId)
            case .failure:
                XCTFail("Should update")
            }
            updateEx1.fulfill()
        }
        wait(for: [updateEx1], timeout: 4.0)

        let updateEx2 = expectation(description: "Update one document")
        collection.updateOneDocument(filter: document5, update: document2, upsert: true) { result in
            switch result {
            case .success(let updateResult):
                XCTAssertEqual(updateResult.matchedCount, 0)
                XCTAssertEqual(updateResult.modifiedCount, 0)
                XCTAssertNotNil(updateResult.objectId)
            case .failure:
                XCTFail("Should update")
            }
            updateEx2.fulfill()
        }
        wait(for: [updateEx2], timeout: 4.0)
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
        wait(for: [insertManyEx], timeout: 4.0)

        let updateEx1 = expectation(description: "Update one document")
        collection.updateManyDocuments(filter: document, update: document2) { result in
            switch result {
            case .success(let updateResult):
                XCTAssertEqual(updateResult.matchedCount, 1)
                XCTAssertEqual(updateResult.modifiedCount, 1)
                XCTAssertNil(updateResult.objectId)
            case .failure:
                XCTFail("Should update")
            }
            updateEx1.fulfill()
        }
        wait(for: [updateEx1], timeout: 4.0)

        let updateEx2 = expectation(description: "Update one document")
        collection.updateManyDocuments(filter: document5, update: document2, upsert: true) { result in
            switch result {
            case .success(let updateResult):
                XCTAssertEqual(updateResult.matchedCount, 0)
                XCTAssertEqual(updateResult.modifiedCount, 0)
                XCTAssertNotNil(updateResult.objectId)
            case .failure:
                XCTFail("Should update")
            }
            updateEx2.fulfill()
        }
        wait(for: [updateEx2], timeout: 4.0)
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
        wait(for: [deleteEx1], timeout: 4.0)

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
        wait(for: [insertManyEx], timeout: 4.0)

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
        wait(for: [deleteEx2], timeout: 4.0)
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
        wait(for: [deleteEx1], timeout: 4.0)

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
        wait(for: [insertManyEx], timeout: 4.0)

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
        wait(for: [deleteEx2], timeout: 4.0)
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
        wait(for: [insertManyEx1], timeout: 4.0)

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
        wait(for: [countEx1], timeout: 4.0)

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
        wait(for: [countEx2], timeout: 4.0)
    }

    func testWatch() {
        performWatchTest(nil)
    }

    func testWatchAsync() {
        let queue = DispatchQueue.init(label: "io.realm.watchQueue", attributes: .concurrent)
        performWatchTest(queue)
    }

    func performWatchTest(_ queue: DispatchQueue?) {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]

        var watchEx = expectation(description: "Watch 3 document events")
        let watchTestUtility = WatchTestUtility(targetEventCount: 3, expectation: &watchEx)

        let changeStream: ChangeStream?
        if let queue = queue {
            changeStream = collection.watch(delegate: watchTestUtility, queue: queue)
        } else {
            changeStream = collection.watch(delegate: watchTestUtility)
        }

        DispatchQueue.global().async {
            watchTestUtility.isOpenSemaphore.wait()
            for _ in 0..<3 {
                collection.insertOne(document) { result in
                    if case .failure = result {
                        XCTFail("Should insert")
                    }
                }
                watchTestUtility.semaphore.wait()
            }
            changeStream?.close()
        }
        wait(for: [watchEx], timeout: 60.0)
    }

    func testWatchWithMatchFilter() {
        performWatchWithMatchFilterTest(nil)
    }

    func testWatchWithMatchFilterAsync() {
        let queue = DispatchQueue.init(label: "io.realm.watchQueue", attributes: .concurrent)
        performWatchWithMatchFilterTest(queue)
    }

    func performWatchWithMatchFilterTest(_ queue: DispatchQueue?) {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]
        let document4: Document = ["name": "ted", "breed": "bullmastiff"]
        var objectIds = [ObjectId]()
        let insertManyEx = expectation(description: "Insert many documents")
        collection.insertMany([document, document2, document3, document4]) { result in
            switch result {
            case .success(let objIds):
                XCTAssertEqual(objIds.count, 4)
                objectIds = objIds.map { $0.objectIdValue! }
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx.fulfill()
        }
        wait(for: [insertManyEx], timeout: 4.0)

        var watchEx = expectation(description: "Watch 3 document events")
        let watchTestUtility = WatchTestUtility(targetEventCount: 3, matchingObjectId: objectIds.first!, expectation: &watchEx)

        let changeStream: ChangeStream?
        if let queue = queue {
            changeStream = collection.watch(matchFilter: ["fullDocument._id": AnyBSON.objectId(objectIds[0])],
                                            delegate: watchTestUtility,
                                            queue: queue)
        } else {
            changeStream = collection.watch(matchFilter: ["fullDocument._id": AnyBSON.objectId(objectIds[0])],
                                            delegate: watchTestUtility)
        }

        DispatchQueue.global().async {
            watchTestUtility.isOpenSemaphore.wait()
            for i in 0..<3 {
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
                watchTestUtility.semaphore.wait()
            }
            changeStream?.close()
        }
        wait(for: [watchEx], timeout: 60.0)
    }

    func testWatchWithFilterIds() {
        performWatchWithFilterIdsTest(nil)
    }

    func testWatchWithFilterIdsAsync() {
        let queue = DispatchQueue.init(label: "io.realm.watchQueue", attributes: .concurrent)
        performWatchWithFilterIdsTest(queue)
    }

    func performWatchWithFilterIdsTest(_ queue: DispatchQueue?) {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]
        let document4: Document = ["name": "ted", "breed": "bullmastiff"]
        var objectIds = [ObjectId]()

        let insertManyEx = expectation(description: "Insert many documents")
        collection.insertMany([document, document2, document3, document4]) { result in
            switch result {
            case .success(let objIds):
                XCTAssertEqual(objIds.count, 4)
                objectIds = objIds.map { $0.objectIdValue! }
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx.fulfill()
        }
        wait(for: [insertManyEx], timeout: 4.0)

        var watchEx = expectation(description: "Watch 3 document events")
        let watchTestUtility = WatchTestUtility(targetEventCount: 3,
                                                matchingObjectId: objectIds.first!,
                                                expectation: &watchEx)
        let changeStream: ChangeStream?
        if let queue = queue {
            changeStream = collection.watch(filterIds: [objectIds[0]], delegate: watchTestUtility, queue: queue)
        } else {
            changeStream = collection.watch(filterIds: [objectIds[0]], delegate: watchTestUtility)
        }

        DispatchQueue.global().async {
            watchTestUtility.isOpenSemaphore.wait()
            for i in 0..<3 {
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
                watchTestUtility.semaphore.wait()
            }
            changeStream?.close()
        }
        wait(for: [watchEx], timeout: 60.0)
    }

    func testWatchMultipleFilterStreams() {
        performMultipleWatchStreamsTest(nil)
    }

    func testWatchMultipleFilterStreamsAsync() {
        let queue = DispatchQueue.init(label: "io.realm.watchQueue", attributes: .concurrent)
        performMultipleWatchStreamsTest(queue)
    }

    func performMultipleWatchStreamsTest(_ queue: DispatchQueue?) {
        let collection = setupMongoCollection()
        let document: Document = ["name": "fido", "breed": "cane corso"]
        let document2: Document = ["name": "rex", "breed": "cane corso"]
        let document3: Document = ["name": "john", "breed": "cane corso"]
        let document4: Document = ["name": "ted", "breed": "bullmastiff"]
        var objectIds = [ObjectId]()

        let insertManyEx = expectation(description: "Insert many documents")
        collection.insertMany([document, document2, document3, document4]) { result in
            switch result {
            case .success(let objIds):
                XCTAssertEqual(objIds.count, 4)
                objectIds = objIds.map { $0.objectIdValue! }
            case .failure:
                XCTFail("Should insert")
            }
            insertManyEx.fulfill()
        }
        wait(for: [insertManyEx], timeout: 4.0)

        var watchEx = expectation(description: "Watch 5 document events")
        watchEx.expectedFulfillmentCount = 2

        let watchTestUtility1 = WatchTestUtility(targetEventCount: 3,
                                                 matchingObjectId: objectIds[0],
                                                 expectation: &watchEx)

        let watchTestUtility2 = WatchTestUtility(targetEventCount: 3,
                                                 matchingObjectId: objectIds[1],
                                                 expectation: &watchEx)

        let changeStream1: ChangeStream?
        let changeStream2: ChangeStream?

        if let queue = queue {
            changeStream1 = collection.watch(filterIds: [objectIds[0]], delegate: watchTestUtility1, queue: queue)
            changeStream2 = collection.watch(filterIds: [objectIds[1]], delegate: watchTestUtility2, queue: queue)
        } else {
            changeStream1 = collection.watch(filterIds: [objectIds[0]], delegate: watchTestUtility1)
            changeStream2 = collection.watch(filterIds: [objectIds[1]], delegate: watchTestUtility2)
        }

        let teardownEx = expectation(description: "All changes complete")
        DispatchQueue.global().async {
            watchTestUtility1.isOpenSemaphore.wait()
            watchTestUtility2.isOpenSemaphore.wait()
            for i in 0..<3 {
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
                watchTestUtility1.semaphore.wait()
                watchTestUtility2.semaphore.wait()
            }
            changeStream1?.close()
            changeStream2?.close()
            teardownEx.fulfill()
        }
        wait(for: [watchEx, teardownEx], timeout: 60.0)
    }

    func testShouldNotDeleteOnMigrationWithSync() throws {
        let user = try logInUser(for: basicCredentials())
        var configuration = user.configuration(testName: appId)

        assertThrows(configuration.deleteRealmIfMigrationNeeded = true,
                     reason: "Cannot set 'deleteRealmIfMigrationNeeded' when sync is enabled ('syncConfig' is set).")

        var localConfiguration = Realm.Configuration.defaultConfiguration
        assertSucceeds {
            localConfiguration.deleteRealmIfMigrationNeeded = true
        }
    }
}

// MARK: - AsyncAwaitMongoClientTests
#if swift(>=5.6) && canImport(_Concurrency)
@available(macOS 12.0, *)
class AsyncAwaitMongoClientTests: SwiftSyncTestCase {
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
        let user = try await self.app.login(credentials: basicCredentials())
        let mongoClient = user.mongoClient("mongodb1")
        let database = mongoClient.database(named: "test_data")
        let collection = database.collection(withName: "Dog")
        _ = try await collection.deleteManyDocuments(filter: [:])
        return collection
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
        let findOptions = FindOptions(1, nil, nil)
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
        let findOptions = FindOptions(1, nil, nil)
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

        let options1 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, true)
        let resultReplacedDocument2 = try await collection.findOneAndReplace(filter: document1, replacement: document2, options: options1)
        XCTAssertNotNil(resultReplacedDocument2)
        XCTAssertEqual(resultReplacedDocument2?["name"]??.stringValue, "fito")

        let options2 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, false)
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

        let options1 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, true)
        let resultUpdatedDocument2 = try await collection.findOneAndUpdate(filter: document1, update: document2, options: options1)
        XCTAssertNotNil(resultUpdatedDocument2)
        XCTAssertEqual(resultUpdatedDocument2?["name"]??.stringValue, "fito")

        let options2 = FindOneAndModifyOptions(["name": 1], ["_id": 1], true, false)
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
        let options2 = FindOneAndModifyOptions(["name": 1], ["_id": 1])
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
        XCTAssertNil(updatedResult.objectId)
        XCTAssertEqual(updatedResult.matchedCount, 1)
        XCTAssertEqual(updatedResult.modifiedCount, 1)

        let updatedResult1 = try await collection.updateOneDocument(filter: document,
                                                                    update: document2,
                                                                    upsert: true)
        XCTAssertNotNil(updatedResult1.objectId)
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
        XCTAssertNil(updatedResult.objectId)
        XCTAssertEqual(updatedResult.matchedCount, 1)
        XCTAssertEqual(updatedResult.modifiedCount, 1)

        let updatedResult2 = try await collection.updateManyDocuments(filter: document,
                                                                      update: document2,
                                                                      upsert: true)
        XCTAssertNotNil(updatedResult2.objectId)
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

#endif // swift(>=5.6)
#endif // os(macOS)
