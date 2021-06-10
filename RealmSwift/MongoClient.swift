////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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
import Realm.Private

/**
 * The `MongoClient` enables reading and writing on a MongoDB database via the Realm Cloud service.
 *
 * It provides access to instances of `MongoDatabase`, which in turn provide access to specific
 * `MongoCollection`s that hold your data.
 *
 * - Note:
 * Before you can read or write data, a user must log in.
 *
 * - SeeAlso:
 * `App`, `MongoDatabase`, `MongoCollection`
 */
public typealias MongoClient = RLMMongoClient

/**
 * The `MongoDatabase` represents a MongoDB database, which holds a group
 * of collections that contain your data.
 *
 * It can be retrieved from the `MongoClient`.
 *
 * Use it to get `MongoCollection`s for reading and writing data.
 *
 * - Note:
 * Before you can read or write data, a user must log in`.
 *
 * - SeeAlso:
 * `MongoClient`, `MongoCollection`
 */
public typealias MongoDatabase = RLMMongoDatabase

/// Options to use when executing a `find` command on a `MongoCollection`.
public typealias FindOptions = RLMFindOptions

extension FindOptions {
    /// Limits the fields to return for all matching documents.
    public var projection: Document? {
        get {
            return __projection.map(ObjectiveCSupport.convertBson)??.documentValue
        }
        set {
            __projection = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convertBson)
        }
    }

    /// The order in which to return matching documents.
    public var sort: Document? {
        get {
            return __sort.map(ObjectiveCSupport.convertBson)??.documentValue
        }
        set {
            __sort = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convertBson)
        }
    }

    /// Options to use when executing a `find` command on a `MongoCollection`.
    /// - Parameters:
    ///   - limit: The maximum number of documents to return. Specifying 0 will return all documents.
    ///   - projected: Limits the fields to return for all matching documents.
    ///   - sort: The order in which to return matching documents.
    public convenience init(_ limit: Int?, _ projection: Document?, _ sort: Document?) {
        self.init()
        self.limit = limit ?? 0
        self.projection = projection
        self.sort = sort
    }

    /// Options to use when executing a `find` command on a `MongoCollection`.
    /// - Parameters:
    ///   - limit: The maximum number of documents to return. Specifying 0 will return all documents.
    ///   - projected: Limits the fields to return for all matching documents.
    ///   - sort: The order in which to return matching documents.
    public convenience init(limit: Int?, projection: Document?, sort: Document?) {
        self.init(limit, projection, sort)
    }
}


/// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
/// or `findOneAndDelete` command on a `MongoCollection`.
public typealias FindOneAndModifyOptions = RLMFindOneAndModifyOptions

extension FindOneAndModifyOptions {

    /// Limits the fields to return for all matching documents.
    public var projection: Document? {
        get {
            return __projection.map(ObjectiveCSupport.convertBson)??.documentValue
        }
        set {
            __projection = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convertBson)
        }
    }

    /// The order in which to return matching documents.
    public var sort: Document? {
        get {
            return __sort.map(ObjectiveCSupport.convertBson)??.documentValue
        }
        set {
            __sort = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convertBson)
        }
    }

    /// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
    /// or `findOneAndDelete` command on a `MongoCollection`
    /// - Parameters:
    ///   - projection: Limits the fields to return for all matching documents.
    ///   - sort: The order in which to return matching documents.
    ///   - upsert: Whether or not to perform an upsert, default is false
    ///   (only available for findOneAndReplace and findOneAndUpdate)
    ///   - shouldReturnNewDocument: When true then the new document is returned,
    ///   Otherwise the old document is returned (default)
    ///   (only available for findOneAndReplace and findOneAndUpdate)
    public convenience init(_ projection: Document?,
                            _ sort: Document?,
                            _ upsert: Bool=false,
                            _ shouldReturnNewDocument: Bool=false) {
        self.init()
        self.projection = projection
        self.sort = sort
        self.upsert = upsert
        self.shouldReturnNewDocument = shouldReturnNewDocument
    }

    /// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
    /// or `findOneAndDelete` command on a `MongoCollection`
    /// - Parameters:
    ///   - projection: Limits the fields to return for all matching documents.
    ///   - sort: The order in which to return matching documents.
    ///   - upsert: Whether or not to perform an upsert, default is false
    ///   (only available for findOneAndReplace and findOneAndUpdate)
    ///   - shouldReturnNewDocument: When true then the new document is returned,
    ///   Otherwise the old document is returned (default)
    ///   (only available for findOneAndReplace and findOneAndUpdate)
    public convenience init(projection: Document?,
                            sort: Document?,
                            upsert: Bool=false,
                            shouldReturnNewDocument: Bool=false) {
        self.init(projection, sort, upsert, shouldReturnNewDocument)
    }
}

/// The result of an `updateOne` or `updateMany` operation a `MongoCollection`.
public typealias UpdateResult = RLMUpdateResult

/// Block which returns Result.success(DocumentId) on a successful insert or Result.failure(error)
public typealias MongoInsertBlock = (Result<AnyBSON, Error>) -> Void
/// Block which returns Result.success([ObjectId]) on a successful insertMany or Result.failure(error)
public typealias MongoInsertManyBlock = (Result<[AnyBSON], Error>) -> Void
/// Block which returns Result.success([Document]) on a successful find operation or Result.failure(error)
public typealias MongoFindBlock = (Result<[Document], Error>) -> Void
/// Block which returns Result.success(Document?) on a successful findOne operation or Result.failure(error)
public typealias MongoFindOneBlock = (Result<Document?, Error>) -> Void
/// Block which returns Result.success(Int) on a successful count operation or Result.failure(error)
public typealias MongoCountBlock = (Result<Int, Error>) -> Void
/// Block which returns Result.success(UpdateResult) on a successful update operation or Result.failure(error)
public typealias MongoUpdateBlock = (Result<UpdateResult, Error>) -> Void

/**
 * The `MongoCollection` represents a MongoDB collection.
 *
 * You can get an instance from a `MongoDatabase`.
 *
 * Create, read, update, and delete methods are available.
 *
 * Operations against the Realm Cloud server are performed asynchronously.
 *
 * - Note:
 * Before you can read or write data, a user must log in.
 *
 * - SeeAlso:
 * `MongoClient`, `MongoDatabase`
 */
public typealias MongoCollection = RLMMongoCollection

/// Acts as a middleman and processes events with WatchStream
public typealias ChangeStream = RLMChangeStream

/// Delegate which is used for subscribing to changes on a `MongoCollection.watch()` stream.
public protocol ChangeEventDelegate: AnyObject {
    /// The stream was opened.
    /// - Parameter changeStream: The `ChangeStream` subscribing to the stream changes.
    func changeStreamDidOpen(_ changeStream: ChangeStream )
    /// The stream has been closed.
    /// - Parameter error: If an error occurred when closing the stream, an error will be passed.
    func changeStreamDidClose(with error: Error?)
    /// A error has occurred while streaming.
    /// - Parameter error: The streaming error.
    func changeStreamDidReceive(error: Error)
    /// Invoked when a change event has been received.
    /// - Parameter changeEvent:The change event in BSON format.
    func changeStreamDidReceive(changeEvent: AnyBSON?)
}

extension MongoCollection {
    /// Opens a MongoDB change stream against the collection to watch for changes. The resulting stream will be notified
    /// of all events on this collection that the active user is authorized to see based on the configured MongoDB
    /// rules.
    /// - Parameters:
    ///   - delegate: The delegate that will react to events and errors from the resulting change stream.
    ///   - queue: Dispatches streaming events to an optional queue, if no queue is provided the main queue is used
    /// - Returns: A ChangeStream which will manage the streaming events.
    public func watch(delegate: ChangeEventDelegate, queue: DispatchQueue = .main) -> ChangeStream {
        return self.__watch(with: ChangeEventDelegateProxy(delegate),
                            delegateQueue: queue)
    }

    /// Opens a MongoDB change stream against the collection to watch for changes. The provided BSON document will be
    /// used as a match expression filter on the change events coming from the stream.
    ///
    /// See https://docs.mongodb.com/manual/reference/operator/aggregation/match/ for documentation around how to define
    /// a match filter.
    ///
    /// Defining the match expression to filter ChangeEvents is similar to defining the match expression for triggers:
    /// https://docs.mongodb.com/realm/triggers/database-triggers/
    /// - Parameters:
    ///   - matchFilter: The $match filter to apply to incoming change events
    ///   - delegate: The delegate that will react to events and errors from the resulting change stream.
    ///   - queue: Dispatches streaming events to an optional queue, if no queue is provided the main queue is used
    /// - Returns: A ChangeStream which will manage the streaming events.
    public func watch(matchFilter: Document, delegate: ChangeEventDelegate, queue: DispatchQueue = .main) -> ChangeStream {
        let filterBSON = ObjectiveCSupport.convert(object: .document(matchFilter)) as! [String: RLMBSON]
        return self.__watch(withMatchFilter: filterBSON,
                            delegate: ChangeEventDelegateProxy(delegate),
                            delegateQueue: queue)
    }

    /// Opens a MongoDB change stream against the collection to watch for changes
    /// made to specific documents. The documents to watch must be explicitly
    /// specified by their _id.
    /// - Parameters:
    ///   - filterIds: The list of _ids in the collection to watch.
    ///   - delegate: The delegate that will react to events and errors from the resulting change stream.
    ///   - queue: Dispatches streaming events to an optional queue, if no queue is provided the main queue is used
    /// - Returns: A ChangeStream which will manage the streaming events.
    public func watch(filterIds: [ObjectId], delegate: ChangeEventDelegate, queue: DispatchQueue = .main) -> ChangeStream {
        let filterBSON = ObjectiveCSupport.convert(object: .array(filterIds.map {AnyBSON($0)})) as! [RLMObjectId]
        return self.__watch(withFilterIds: filterBSON,
                            delegate: ChangeEventDelegateProxy(delegate),
                            delegateQueue: queue)
    }
}

// MongoCollection methods with result type completions
extension MongoCollection {
    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// - Parameters:
    ///   - document: document  A `Document` value to insert.
    ///   - completion: The result of attempting to perform the insert. An Id will be returned for the inserted object on sucess
    public func insertOne(_ document: Document, _ completion: @escaping MongoInsertBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(document))
        self.__insertOneDocument(bson as! [String: RLMBSON]) { objectId, error in
            if let o = objectId.map(ObjectiveCSupport.convert), let objectId = o {
                completion(.success(objectId))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
    /// they will be generated.
    /// - Parameters:
    ///   - documents: The `Document` values in a bson array to insert.
    ///   - completion: The result of the insert, returns an array inserted document ids in order.
    public func insertMany(_ documents: [Document], _ completion: @escaping MongoInsertManyBlock) {
        let bson = ObjectiveCSupport.convert(object: .array(documents.map {.document($0)}))
        self.__insertManyDocuments(bson as! [[String: RLMBSON]]) { objectIds, error in
            if let objectIds = objectIds?.compactMap(ObjectiveCSupport.convert) {
                completion(.success(objectIds))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Finds the documents in this collection which match the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    ///   - completion: The resulting bson array of documents or error if one occurs
    public func find(filter: Document,
                     options: FindOptions,
                     _ completion: @escaping MongoFindBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        self.__findWhere(bson as! [String: RLMBSON], options: options) { documents, error in
            let bson: [Document]? = documents?.map { $0.mapValues { ObjectiveCSupport.convert(object: $0) } }
            if let bson = bson {
                completion(.success(bson))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Finds the documents in this collection which match the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: The resulting bson array of documents or error if one occurs
    public func find(filter: Document,
                     _ completion: @escaping MongoFindBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        self.__findWhere(bson as! [String: RLMBSON]) { documents, error in
            let bson: [Document]? = documents?.map { $0.mapValues { ObjectiveCSupport.convert(object: $0) } }
            if let bson = bson {
                completion(.success(bson))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    ///   - completion: The resulting bson or error if one occurs
    public func findOneDocument(filter: Document,
                                options: FindOptions,
                                _ completion: @escaping MongoFindOneBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        self.__findOneDocumentWhere(bson as! [String: RLMBSON], options: options) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let bson: Document? = document?.mapValues { ObjectiveCSupport.convert(object: $0) }
                completion(.success(bson))
            }
        }
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: The resulting bson or error if one occurs
    public func findOneDocument(filter: Document,
                                _ completion: @escaping MongoFindOneBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        self.__findOneDocumentWhere(bson as! [String: RLMBSON]) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let bson: Document? = document?.mapValues { ObjectiveCSupport.convert(object: $0) }
                completion(.success(bson))
            }
        }
    }

    /// Runs an aggregation framework pipeline against this collection.
    /// - Parameters:
    ///   - pipeline: A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
    ///   - completion: The resulting bson array of documents or error if one occurs
    public func aggregate(pipeline: [Document],
                          _ completion: @escaping MongoFindBlock) {
        let bson = ObjectiveCSupport.convert(object: .array(pipeline.map {.document($0)}))
        self.__aggregate(withPipeline: bson as! [[String: RLMBSON]]) { documents, error in
            let bson: [Document]? = documents?.map { $0.mapValues { ObjectiveCSupport.convert(object: $0) } }
            if let bson = bson {
                completion(.success(bson))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - limit: The max amount of documents to count
    ///   - completion: Returns the count of the documents that matched the filter.
    public func count(filter: Document,
                      limit: Int,
                      _ completion: @escaping MongoCountBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        self.__countWhere(bson as! [String: RLMBSON], limit: limit) { count, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(count))
            }
        }
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: Returns the count of the documents that matched the filter.
    public func count(filter: Document,
                      _ completion: @escaping MongoCountBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        self.__countWhere(bson as! [String: RLMBSON]) { count, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(count))
            }
        }
    }

    /// Deletes a single matching document from the collection.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: The result of performing the deletion. Returns the count of deleted objects
    public func deleteOneDocument(filter: Document,
                                  _ completion: @escaping MongoCountBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        self.__deleteOneDocumentWhere(bson as! [String: RLMBSON]) { count, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(count))
            }
        }
    }

    /// Deletes multiple documents
    /// - Parameters:
    ///   - filter: Document representing the match criteria
    ///   - completion: The result of performing the deletion. Returns the count of the deletion
    public func deleteManyDocuments(filter: Document,
                                    _ completion: @escaping MongoCountBlock) {
        let bson = ObjectiveCSupport.convert(object: .document(filter))
        self.__deleteManyDocumentsWhere(bson as! [String: RLMBSON]) { count, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(count))
            }
        }
    }

    /// Updates a single document matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - upsert: When true, creates a new document if no document matches the query.
    ///   - completion: The result of the attempt to update a document.
    public func updateOneDocument(filter: Document,
                                  update: Document,
                                  upsert: Bool,
                                  _ completion: @escaping MongoUpdateBlock) {
        let filterBSON = ObjectiveCSupport.convert(object: .document(filter))
        let updateBSON = ObjectiveCSupport.convert(object: .document(update))
        self.__updateOneDocumentWhere(filterBSON as! [String: RLMBSON],
                                      updateDocument: updateBSON as! [String: RLMBSON],
                                      upsert: upsert) { updateResult, error in
            if let updateResult = updateResult {
                completion(.success(updateResult))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Updates a single document matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - completion: The result of the attempt to update a document.
    public func updateOneDocument(filter: Document,
                                  update: Document,
                                  _ completion: @escaping MongoUpdateBlock) {
        let filterBSON = ObjectiveCSupport.convert(object: .document(filter))
        let updateBSON = ObjectiveCSupport.convert(object: .document(update))
        self.__updateOneDocumentWhere(filterBSON as! [String: RLMBSON],
                                      updateDocument: updateBSON as! [String: RLMBSON]) { updateResult, error in
            if let updateResult = updateResult {
                completion(.success(updateResult))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - upsert: When true, creates a new document if no document matches the query.
    ///   - completion: The result of the attempt to update a document.
    public func updateManyDocuments(filter: Document,
                                    update: Document,
                                    upsert: Bool,
                                    _ completion: @escaping MongoUpdateBlock) {
        let filterBSON = ObjectiveCSupport.convert(object: .document(filter))
        let updateBSON = ObjectiveCSupport.convert(object: .document(update))
        self.__updateManyDocumentsWhere(filterBSON as! [String: RLMBSON],
                                        updateDocument: updateBSON as! [String: RLMBSON],
                                        upsert: upsert) { updateResult, error in
            if let updateResult = updateResult {
                completion(.success(updateResult))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - completion: The result of the attempt to update a document.
    public func updateManyDocuments(filter: Document,
                                    update: Document,
                                    _ completion: @escaping MongoUpdateBlock) {
        let filterBSON = ObjectiveCSupport.convert(object: .document(filter))
        let updateBSON = ObjectiveCSupport.convert(object: .document(update))
        self.__updateManyDocumentsWhere(filterBSON as! [String: RLMBSON],
                                        updateDocument: updateBSON as! [String: RLMBSON]) { updateResult, error in
            if let updateResult = updateResult {
                completion(.success(updateResult))
            } else {
                completion(.failure(error ?? Realm.Error.callFailed))
            }
        }
    }

    /// Updates a single document in a collection based on a query filter and
    /// returns the document in either its pre-update or post-update form. Unlike
    /// `updateOneDocument`, this action allows you to atomically find, update, and
    /// return a document with the same command. This avoids the risk of other
    /// update operations changing the document between separate find and update
    /// operations.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - options: `RemoteFindOneAndModifyOptions` to use when executing the command.
    ///   - completion: The result of the attempt to update a document.
    public func findOneAndUpdate(filter: Document,
                                 update: Document,
                                 options: FindOneAndModifyOptions,
                                 _ completion: @escaping MongoFindOneBlock) {
        let filterBSON = ObjectiveCSupport.convert(object: .document(filter))
        let updateBSON = ObjectiveCSupport.convert(object: .document(update))
        self.__findOneAndUpdateWhere(filterBSON as! [String: RLMBSON],
                                     updateDocument: updateBSON as! [String: RLMBSON],
                                     options: options) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let bson: Document? = document?.mapValues { ObjectiveCSupport.convert(object: $0) }
                completion(.success(bson))
            }
        }
    }

    /// Updates a single document in a collection based on a query filter and
    /// returns the document in either its pre-update or post-update form. Unlike
    /// `updateOneDocument`, this action allows you to atomically find, update, and
    /// return a document with the same command. This avoids the risk of other
    /// update operations changing the document between separate find and update
    /// operations.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - completion: The result of the attempt to update a document.
    public func findOneAndUpdate(filter: Document,
                                 update: Document,
                                 _ completion: @escaping MongoFindOneBlock) {
        let filterBSON = ObjectiveCSupport.convert(object: .document(filter))
        let updateBSON = ObjectiveCSupport.convert(object: .document(update))
        self.__findOneAndUpdateWhere(filterBSON as! [String: RLMBSON],
                                     updateDocument: updateBSON as! [String: RLMBSON]) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let bson: Document? = document?.mapValues { ObjectiveCSupport.convert(object: $0) }
                completion(.success(bson))
            }
        }
    }

    /// Overwrites a single document in a collection based on a query filter and
    /// returns the document in either its pre-replacement or post-replacement
    /// form. Unlike `updateOneDocument`, this action allows you to atomically find,
    /// replace, and return a document with the same command. This avoids the
    /// risk of other update operations changing the document between separate
    /// find and update operations.
    /// - Parameters:
    ///   - filter: A `Document` that should match the query.
    ///   - replacement: A `Document` describing the replacement.
    ///   - options: `FindOneAndModifyOptions` to use when executing the command.
    ///   - completion: The result of the attempt to replace a document.
    public func findOneAndReplace(filter: Document,
                                  replacement: Document,
                                  options: FindOneAndModifyOptions,
                                  _ completion: @escaping MongoFindOneBlock) {
        let filterBSON = ObjectiveCSupport.convert(object: .document(filter))
        let replacementBSON = ObjectiveCSupport.convert(object: .document(replacement))
        self.__findOneAndReplaceWhere(filterBSON as! [String: RLMBSON],
                                      replacementDocument: replacementBSON as! [String: RLMBSON],
                                      options: options) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let bson: Document? = document?.mapValues { ObjectiveCSupport.convert(object: $0) }
                completion(.success(bson))
            }
        }
    }

    /// Overwrites a single document in a collection based on a query filter and
    /// returns the document in either its pre-replacement or post-replacement
    /// form. Unlike `updateOneDocument`, this action allows you to atomically find,
    /// replace, and return a document with the same command. This avoids the
    /// risk of other update operations changing the document between separate
    /// find and update operations.
    /// - Parameters:
    ///   - filter: A `Document` that should match the query.
    ///   - replacement: A `Document` describing the replacement.
    ///   - options: `RLMFindOneAndModifyOptions` to use when executing the command.
    ///   - completion: The result of the attempt to replace a document.
    public func findOneAndReplace(filter: Document,
                                  replacement: Document,
                                  _ completion: @escaping MongoFindOneBlock) {
        let filterBSON = ObjectiveCSupport.convert(object: .document(filter))
        let replacementBSON = ObjectiveCSupport.convert(object: .document(replacement))
        self.__findOneAndReplaceWhere(filterBSON as! [String: RLMBSON],
                                      replacementDocument: replacementBSON as! [String: RLMBSON]) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let bson: Document? = document?.mapValues { ObjectiveCSupport.convert(object: $0) }
                completion(.success(bson))
            }
        }
    }

    /// Removes a single document from a collection based on a query filter and
    /// returns a document with the same form as the document immediately before
    /// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
    /// find and delete a document with the same command. This avoids the risk of
    /// other update operations changing the document between separate find and
    /// delete operations.
    /// - Parameters:
    ///   - filter: A `Document` that should match the query.
    ///   - options: `FindOneAndModifyOptions` to use when executing the command.
    ///   - completion: The result of the attempt to delete a document.
    public func findOneAndDelete(filter: Document,
                                 options: FindOneAndModifyOptions,
                                 _ completion: @escaping MongoFindOneBlock) {
        let filterBSON = ObjectiveCSupport.convert(object: .document(filter))
        self.__findOneAndDeleteWhere(filterBSON as! [String: RLMBSON],
                                     options: options) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let bson: Document? = document?.mapValues { ObjectiveCSupport.convert(object: $0) }
                completion(.success(bson))
            }
        }
    }

    /// Removes a single document from a collection based on a query filter and
    /// returns a document with the same form as the document immediately before
    /// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
    /// find and delete a document with the same command. This avoids the risk of
    /// other update operations changing the document between separate find and
    /// delete operations.
    /// - Parameters:
    ///   - filter: A `Document` that should match the query.
    ///   - completion: The result of the attempt to delete a document.
    public func findOneAndDelete(filter: Document,
                                 _ completion: @escaping MongoFindOneBlock) {
        let filterBSON = ObjectiveCSupport.convert(object: .document(filter))
        self.__findOneAndDeleteWhere(filterBSON as! [String: RLMBSON]) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let bson: Document? = document?.mapValues { ObjectiveCSupport.convert(object: $0) }
                completion(.success(bson))
            }
        }
    }
}

private class ChangeEventDelegateProxy: RLMChangeEventDelegate {

    private weak var proxyDelegate: ChangeEventDelegate?

    init(_ proxyDelegate: ChangeEventDelegate) {
        self.proxyDelegate = proxyDelegate
    }

    func changeStreamDidOpen(_ changeStream: RLMChangeStream) {
        proxyDelegate?.changeStreamDidOpen(changeStream)
    }

    func changeStreamDidCloseWithError(_ error: Error?) {
        proxyDelegate?.changeStreamDidClose(with: error)
    }

    func changeStreamDidReceiveError(_ error: Error) {
        proxyDelegate?.changeStreamDidReceive(error: error)
    }

    func changeStreamDidReceiveChangeEvent(_ changeEvent: RLMBSON) {
        let bson = ObjectiveCSupport.convert(object: changeEvent)
        proxyDelegate?.changeStreamDidReceive(changeEvent: bson)
    }
}

#if canImport(Combine)
import Combine

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension Publishers {
    class WatchSubscription<S: Subscriber>: ChangeEventDelegate, Subscription where S.Input == AnyBSON, S.Failure == Error {
        private let collection: MongoCollection
        private var changeStream: ChangeStream?
        private var subscriber: S?
        private var onOpen: (() -> Void)?

        init(collection: MongoCollection,
             subscriber: S,
             queue: DispatchQueue = .main,
             filterIds: [ObjectId]? = nil,
             matchFilter: Document? = nil,
             onOpen: (() -> Void)? = nil) {
            self.collection = collection
            self.subscriber = subscriber
            self.onOpen = onOpen

            if let matchFilter = matchFilter {
                changeStream = collection.watch(matchFilter: matchFilter,
                                                delegate: self,
                                                queue: queue)
            } else if let filterIds = filterIds {
                changeStream = collection.watch(filterIds: filterIds,
                                                delegate: self,
                                                queue: queue)
            } else {
                changeStream = collection.watch(delegate: self,
                                                queue: queue)
            }
        }

        func request(_ demand: Subscribers.Demand) { }

        func cancel() {
            changeStream?.close()
        }

        func changeStreamDidOpen(_ changeStream: RLMChangeStream) {
            onOpen?()
        }

        func changeStreamDidClose(with error: Error?) {
            guard let error = error else {
                subscriber?.receive(completion: .finished)
                return
            }
            subscriber?.receive(completion: .failure(error))
        }

        func changeStreamDidReceive(error: Error) {
            subscriber?.receive(completion: .failure(error))
        }

        func changeStreamDidReceive(changeEvent: AnyBSON?) {
            guard let changeEvent = changeEvent else {
                return
            }
            _ = subscriber?.receive(changeEvent)
        }
    }

    /// A publisher that emits a change event each time the remote MongoDB collection changes.
    public struct WatchPublisher: Publisher {
        public typealias Output = AnyBSON
        public typealias Failure = Error

        private let collection: MongoCollection
        private let queue: DispatchQueue
        private let filterIds: [ObjectId]?
        private let matchFilter: Document?
        private let openEvent: (() -> Void)?

        init(collection: MongoCollection,
             queue: DispatchQueue,
             filterIds: [ObjectId]? = nil,
             matchFilter: Document? = nil,
             onOpen: (() -> Void)? = nil) {
            self.collection = collection
            self.queue = queue
            self.filterIds = filterIds
            self.matchFilter = matchFilter
            self.openEvent = onOpen
        }

        /// Triggers an event when the watch change stream is opened.
        ///
        /// Use this function when you require a change stream to be open before you perform any work.
        /// This should be called directly after invoking the publisher.
        ///
        /// - Parameter event: Callback which will be invoked once the change stream is open.
        /// - Returns: A publisher that emits a change event each time the remote MongoDB collection changes.
        public func onOpen(_ event: @escaping (() -> Void)) -> Self {
            Self(collection: collection,
                 queue: queue,
                 filterIds: filterIds,
                 matchFilter: matchFilter,
                 onOpen: event)
        }

        /// :nodoc:
        public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            let subscription = WatchSubscription(collection: collection,
                                                 subscriber: subscriber,
                                                 queue: queue,
                                                 filterIds: filterIds,
                                                 matchFilter: matchFilter,
                                                 onOpen: openEvent)
            subscriber.receive(subscription: subscription)
        }

        /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
        ///
        /// - parameter scheduler: The dispatch queue to perform the subscription on.
        /// - returns: A publisher which subscribes on the given scheduler.
        public func subscribe<S: Scheduler>(on scheduler: S) -> WatchPublisher {
            guard let queue = scheduler as? DispatchQueue else {
                fatalError("Cannot subscribe on scheduler \(scheduler): only dispatch queues are currently implemented.")
            }
            return Self(collection: collection,
                        queue: queue,
                        filterIds: filterIds,
                        matchFilter: matchFilter,
                        onOpen: openEvent)
        }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension MongoCollection {
    /// Creates a publisher that emits a AnyBSON change event each time the MongoDB collection changes.
    ///
    /// - returns: A publisher that emits the AnyBSON change event each time the collection changes.
    public func watch() -> Publishers.WatchPublisher {
        return Publishers.WatchPublisher(collection: self, queue: .main)
    }
    /// Creates a publisher that emits a AnyBSON change event each time the MongoDB collection changes.
    ///
    /// - Parameter filterIds: The list of _ids in the collection to watch.
    /// - Returns: A publisher that emits the AnyBSON change event each time the collection changes.
    public func watch(filterIds: [ObjectId]) -> Publishers.WatchPublisher {
        return Publishers.WatchPublisher(collection: self, queue: .main, filterIds: filterIds)
    }
    /// Creates a publisher that emits a AnyBSON change event each time the MongoDB collection changes.
    ///
    /// - Parameter matchFilter: The $match filter to apply to incoming change events.
    /// - Returns: A publisher that emits the AnyBSON change event each time the collection changes.
    public func watch(matchFilter: Document) -> Publishers.WatchPublisher {
        return Publishers.WatchPublisher(collection: self, queue: .main, matchFilter: matchFilter)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public extension MongoCollection {
    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// @param document:  A `Document` value to insert.
    /// @returns A publisher that eventually return the object id of the inserted document or `Error`.
    func insertOne(_ document: Document) -> Future<AnyBSON, Error> {
        return Future { self.insertOne(document, $0) }
    }

    /// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
    /// they will be generated.
    /// @param documents: The `Document` values in a bson array to insert.
    /// @returns A publisher that eventually return the object ids of inserted documents or `Error`.
    func insertMany(_ documents: [Document]) -> Future<[AnyBSON], Error> {
        return Future { self.insertMany(documents, $0) }
    }

    /// Finds the documents in this collection which match the provided filter.
    /// @param filter: A `Document` as bson that should match the query.
    /// @param options: `FindOptions` to use when executing the command.
    /// @returns A publisher that eventually return `[ObjectId]` of documents or `Error`.
    func find(filter: Document, options: FindOptions) -> Future<[Document], Error> {
        return Future { self.find(filter: filter, options: options, $0) }
    }

    /// Finds the documents in this collection which match the provided filter.
    /// @param filter: A `Document` as bson that should match the query.
    /// @returns A publisher that eventually return `[ObjectId]` of documents or `Error`.
    func find(filter: Document) -> Future<[Document], Error> {
        return Future { self.find(filter: filter, $0) }
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// @param filter: A `Document` as bson that should match the query.
    /// @param options: `FindOptions` to use when executing the command.
    /// @returns A publisher that eventually return `Document` or `Error`.
    func findOneDocument(filter: Document, options: FindOptions) -> Future<Document?, Error> {
        return Future { self.findOneDocument(filter: filter, $0) }
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// @param filter: A `Document` as bson that should match the query.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneDocument(filter: Document) -> Future<Document?, Error> {
        return Future { self.findOneDocument(filter: filter, $0) }
    }

    /// Runs an aggregation framework pipeline against this collection.
    /// @param pipeline: A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
    /// @returns A publisher that eventually return `Document` or `Error`.
    func aggregate(pipeline: [Document]) -> Future<[Document], Error> {
        return Future { self.aggregate(pipeline: pipeline, $0) }
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// @param filter: A `Document` as bson that should match the query.
    /// @param limit: The max amount of documents to count
    /// @returns A publisher that eventually return `Int` count of documents or `Error`.
    func count(filter: Document, limit: Int) -> Future<Int, Error> {
        return Future { self.count(filter: filter, limit: limit, $0) }
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// @param filter: A `Document` as bson that should match the query.
    /// @returns A publisher that eventually return `Int` count of documents or `Error`.
    func count(filter: Document) -> Future<Int, Error> {
        return Future { self.count(filter: filter, $0) }
    }

    /// Deletes a single matching document from the collection.
    /// @param filter: A `Document` as bson that should match the query.
    /// @returns A publisher that eventually return `Int` count of deleted documents or `Error`.
    func deleteOneDocument(filter: Document) -> Future<Int, Error> {
        return Future { self.deleteOneDocument(filter: filter, $0) }
    }

    /// Deletes multiple documents
    /// @param filter: Document representing the match criteria
    /// @returns A publisher that eventually return `Int` count of deleted documents or `Error`.
    func deleteManyDocuments(filter: Document) -> Future<Int, Error> {
        return Future { self.deleteManyDocuments(filter: filter, $0) }
    }

    /// Updates a single document matching the provided filter in this collection.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @param upsert: When true, creates a new document if no document matches the query.
    /// @returns A publisher that eventually return `UpdateResult` or `Error`.
    func updateOneDocument(filter: Document, update: Document, upsert: Bool) -> Future<UpdateResult, Error> {
        return Future { self.updateOneDocument(filter: filter, update: update, upsert: upsert, $0) }
    }

    /// Updates a single document matching the provided filter in this collection.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @returns A publisher that eventually return `UpdateResult` or `Error`.
    func updateOneDocument(filter: Document, update: Document) -> Future<UpdateResult, Error> {
        return Future { self.updateOneDocument(filter: filter, update: update, $0) }
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @param upsert: When true, creates a new document if no document matches the query.
    /// @returns A publisher that eventually return `UpdateResult` or `Error`.
    func updateManyDocuments(filter: Document, update: Document, upsert: Bool) -> Future<UpdateResult, Error> {
        return Future { self.updateManyDocuments(filter: filter, update: update, upsert: upsert, $0) }
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @returns A publisher that eventually return `UpdateResult` or `Error`.
    func updateManyDocuments(filter: Document, update: Document) -> Future<UpdateResult, Error> {
        return Future { self.updateManyDocuments(filter: filter, update: update, $0) }
    }

    /// Updates a single document in a collection based on a query filter and
    /// returns the document in either its pre-update or post-update form. Unlike
    /// `updateOneDocument`, this action allows you to atomically find, update, and
    /// return a document with the same command. This avoids the risk of other
    /// update operations changing the document between separate find and update
    /// operations.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @param options: `RemoteFindOneAndModifyOptions` to use when executing the command.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndUpdate(filter: Document, update: Document, options: FindOneAndModifyOptions) -> Future<Document?, Error> {
        return Future { self.findOneAndUpdate(filter: filter, update: update, options: options, $0) }
    }

    /// Updates a single document in a collection based on a query filter and
    /// returns the document in either its pre-update or post-update form. Unlike
    /// `updateOneDocument`, this action allows you to atomically find, update, and
    /// return a document with the same command. This avoids the risk of other
    /// update operations changing the document between separate find and update
    /// operations.
    /// @param filter: A bson `Document` representing the match criteria.
    /// @param update: A bson `Document` representing the update to be applied to a matching document.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndUpdate(filter: Document, update: Document) -> Future<Document?, Error> {
        return Future { self.findOneAndUpdate(filter: filter, update: update, $0) }
    }

    /// Overwrites a single document in a collection based on a query filter and
    /// returns the document in either its pre-replacement or post-replacement
    /// form. Unlike `updateOneDocument`, this action allows you to atomically find,
    /// replace, and return a document with the same command. This avoids the
    /// risk of other update operations changing the document between separate
    /// find and update operations.
    /// @param filter: A `Document` that should match the query.
    /// @param replacement: A `Document` describing the replacement.
    /// @param options: `FindOneAndModifyOptions` to use when executing the command.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndReplace(filter: Document, replacement: Document, options: FindOneAndModifyOptions) -> Future<Document?, Error> {
        return Future { self.findOneAndReplace(filter: filter, replacement: replacement, options: options, $0) }
    }

    /// Overwrites a single document in a collection based on a query filter and
    /// returns the document in either its pre-replacement or post-replacement
    /// form. Unlike `updateOneDocument`, this action allows you to atomically find,
    /// replace, and return a document with the same command. This avoids the
    /// risk of other update operations changing the document between separate
    /// find and update operations.
    /// @param filter: A `Document` that should match the query.
    /// @param replacement: A `Document` describing the replacement.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndReplace(filter: Document, replacement: Document) -> Future<Document?, Error> {
        return Future { self.findOneAndReplace(filter: filter, replacement: replacement, $0) }
    }

    /// Removes a single document from a collection based on a query filter and
    /// returns a document with the same form as the document immediately before
    /// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
    /// find and delete a document with the same command. This avoids the risk of
    /// other update operations changing the document between separate find and
    /// delete operations.
    /// @param filter: A `Document` that should match the query.
    /// @param options: `FindOneAndModifyOptions` to use when executing the command.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndDelete(filter: Document, options: FindOneAndModifyOptions) -> Future<Document?, Error> {
        return Future { self.findOneAndDelete(filter: filter, options: options, $0) }
    }

    /// Removes a single document from a collection based on a query filter and
    /// returns a document with the same form as the document immediately before
    /// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
    /// find and delete a document with the same command. This avoids the risk of
    /// other update operations changing the document between separate find and
    /// delete operations.
    /// @param filter: A `Document` that should match the query.
    /// @returns A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndDelete(filter: Document) -> Future<Document?, Error> {
        return Future { self.findOneAndDelete(filter: filter, $0) }
    }
}

#endif // canImport(Combine)
