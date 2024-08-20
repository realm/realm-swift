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

import Combine
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
    @available(*, deprecated, message: "Use `sorting`")
    public var sort: Document? {
        get {
            return __sort.map(ObjectiveCSupport.convertBson)??.documentValue
        }
        set {
            __sort = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convertBson)
        }
    }

    /// The order in which to return matching documents.
    public var sorting: [Document] {
        get {
            return __sorting.map(ObjectiveCSupport.convertBson).map({$0!.documentValue!})
        }
        set {
            __sorting = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convertBson)
        }
    }

    // NEXT-MAJOR: there's no reason for limit to be optional here
    /// Options to use when executing a `find` command on a `MongoCollection`.
    /// - Parameters:
    ///   - limit: The maximum number of documents to return. Specifying 0 will return all documents.
    ///   - projected: Limits the fields to return for all matching documents.
    ///   - sort: The order in which to return matching documents.
    @available(*, deprecated, message: "Use init(limit:projection:sorting:)")
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
    ///   - sorting: The order in which to return matching documents.
    public convenience init(_ limit: Int = 0, _ projection: Document? = nil, _ sorting: [Document] = []) {
        self.init()
        self.limit = limit
        self.projection = projection
        self.sorting = sorting
    }

    /// Options to use when executing a `find` command on a `MongoCollection`.
    /// - Parameters:
    ///   - limit: The maximum number of documents to return. Specifying 0 will return all documents.
    ///   - projected: Limits the fields to return for all matching documents.
    ///   - sort: The order in which to return matching documents.
    @available(*, deprecated, message: "Use init(limit:projection:sorting:)")
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
    @available(*, deprecated, message: "Use `sorting`")
    public var sort: Document? {
        get {
            return __sort.map(ObjectiveCSupport.convertBson)??.documentValue
        }
        set {
            __sort = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convertBson)
        }
    }

    /// The order in which to return matching documents, defined by `SortDescriptor`
    public var sorting: [Document] {
        get {
            return __sorting.map(ObjectiveCSupport.convertBson).map({$0!.documentValue!})
        }
        set {
            __sorting = newValue.map(AnyBSON.init).map(ObjectiveCSupport.convertBson)
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
    @available(*, deprecated, message: "Use init(projection:sorting:upsert:shouldReturnNewDocument:)")
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
    ///   - sorting: The order in which to return matching documents.
    ///   - upsert: Whether or not to perform an upsert, default is false
    ///   (only available for findOneAndReplace and findOneAndUpdate)
    ///   - shouldReturnNewDocument: When true then the new document is returned,
    ///   Otherwise the old document is returned (default)
    ///   (only available for findOneAndReplace and findOneAndUpdate)
    public convenience init(_ projection: Document?,
                            _ sorting: [Document] = [],
                            _ upsert: Bool=false,
                            _ shouldReturnNewDocument: Bool=false) {
        self.init()
        self.projection = projection
        self.sorting = sorting
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
    @available(*, deprecated, message: "Use init(projection:sorting:upsert:shouldReturnNewDocument:)")
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
public typealias MongoInsertBlock = @Sendable (Result<AnyBSON, Error>) -> Void
/// Block which returns Result.success([ObjectId]) on a successful insertMany or Result.failure(error)
public typealias MongoInsertManyBlock = @Sendable (Result<[AnyBSON], Error>) -> Void
/// Block which returns Result.success([Document]) on a successful find operation or Result.failure(error)
public typealias MongoFindBlock = @Sendable (Result<[Document], Error>) -> Void
/// Block which returns Result.success(Document?) on a successful findOne operation or Result.failure(error)
public typealias MongoFindOneBlock = @Sendable (Result<Document?, Error>) -> Void
/// Block which returns Result.success(Int) on a successful count operation or Result.failure(error)
public typealias MongoCountBlock = @Sendable (Result<Int, Error>) -> Void
/// Block which returns Result.success(UpdateResult) on a successful update operation or Result.failure(error)
public typealias MongoUpdateBlock = @Sendable (Result<UpdateResult, Error>) -> Void

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
    func changeStreamDidOpen(_ changeStream: ChangeStream)
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
        __watch(withMatchFilter: ObjectiveCSupport.convert(matchFilter),
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
        __watch(withFilterIds: filterIds,
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
    @preconcurrency
    public func insertOne(_ document: Document, _ completion: @escaping MongoInsertBlock) {
        let bson = ObjectiveCSupport.convert(document)
        __insertOneDocument(bson) { objectId, error in
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
    @preconcurrency
    public func insertMany(_ documents: [Document], _ completion: @escaping MongoInsertManyBlock) {
        let bson = documents.map(ObjectiveCSupport.convert)
        __insertManyDocuments(bson) { objectIds, error in
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
    @preconcurrency
    public func find(filter: Document, options: FindOptions = FindOptions(),
                     _ completion: @escaping MongoFindBlock) {
        let bson = ObjectiveCSupport.convert(filter)
        __findWhere(bson, options: options) { documents, error in
            if let bson = documents?.map(ObjectiveCSupport.convert) {
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
    @preconcurrency
    public func findOneDocument(filter: Document, options: FindOptions = FindOptions(),
                                _ completion: @escaping MongoFindOneBlock) {
        let bson = ObjectiveCSupport.convert(filter)
        __findOneDocumentWhere(bson, options: options) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(document.map(ObjectiveCSupport.convert)))
            }
        }
    }

    /// Runs an aggregation framework pipeline against this collection.
    /// - Parameters:
    ///   - pipeline: A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
    ///   - completion: The resulting bson array of documents or error if one occurs
    @preconcurrency
    public func aggregate(pipeline: [Document], _ completion: @escaping MongoFindBlock) {
        let bson = pipeline.map(ObjectiveCSupport.convert)
        __aggregate(withPipeline: bson) { documents, error in
            if let bson = documents?.map(ObjectiveCSupport.convert) {
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
    @preconcurrency
    public func count(filter: Document, limit: Int? = nil, _ completion: @escaping MongoCountBlock) {
        let bson = ObjectiveCSupport.convert(filter)
        __countWhere(bson, limit: limit ?? 0) { count, error in
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
    @preconcurrency
    public func deleteOneDocument(filter: Document, _ completion: @escaping MongoCountBlock) {
        let bson = ObjectiveCSupport.convert(filter)
        __deleteOneDocumentWhere(bson) { count, error in
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
    @preconcurrency
    public func deleteManyDocuments(filter: Document, _ completion: @escaping MongoCountBlock) {
        let bson = ObjectiveCSupport.convert(filter)
        __deleteManyDocumentsWhere(bson) { count, error in
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
    @preconcurrency
    public func updateOneDocument(filter: Document, update: Document, upsert: Bool = false,
                                  _ completion: @escaping MongoUpdateBlock) {
        let filterBSON = ObjectiveCSupport.convert(filter)
        let updateBSON = ObjectiveCSupport.convert(update)
        __updateOneDocumentWhere(filterBSON, updateDocument: updateBSON,
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
    ///   - upsert: When true, creates a new document if no document matches the query.
    ///   - completion: The result of the attempt to update a document.
    @preconcurrency
    public func updateManyDocuments(filter: Document, update: Document, upsert: Bool = false,
                                    _ completion: @escaping MongoUpdateBlock) {
        let filterBSON = ObjectiveCSupport.convert(filter)
        let updateBSON = ObjectiveCSupport.convert(update)
        __updateManyDocumentsWhere(filterBSON, updateDocument: updateBSON,
                                   upsert: upsert) { updateResult, error in
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
    @preconcurrency
    public func findOneAndUpdate(filter: Document, update: Document,
                                 options: FindOneAndModifyOptions = .init(),
                                 _ completion: @escaping MongoFindOneBlock) {
        let filterBSON = ObjectiveCSupport.convert(filter)
        let updateBSON = ObjectiveCSupport.convert(update)
        __findOneAndUpdateWhere(filterBSON, updateDocument: updateBSON,
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
    ///   - options: `FindOneAndModifyOptions` to use when executing the command.
    ///   - completion: The result of the attempt to replace a document.
    @preconcurrency
    public func findOneAndReplace(filter: Document, replacement: Document,
                                  options: FindOneAndModifyOptions = .init(),
                                  _ completion: @escaping MongoFindOneBlock) {
        let filterBSON = ObjectiveCSupport.convert(filter)
        let replacementBSON = ObjectiveCSupport.convert(replacement)
        __findOneAndReplaceWhere(filterBSON, replacementDocument: replacementBSON,
                                 options: options) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(document.map(ObjectiveCSupport.convert)))
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
    @preconcurrency
    public func findOneAndDelete(filter: Document, options: FindOneAndModifyOptions = .init(),
                                 _ completion: @escaping MongoFindOneBlock) {
        let filterBSON = ObjectiveCSupport.convert(filter)
        __findOneAndDeleteWhere(filterBSON, options: options) { document, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(document.map(ObjectiveCSupport.convert)))
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MongoCollection {
    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// - Parameters:
    ///   - document: A `Document` value to insert.
    /// - Returns: The object id of the inserted document.
    public func insertOne(_ document: Document) async throws -> AnyBSON {
        try await ObjectiveCSupport.convert(object: __insertOneDocument(ObjectiveCSupport.convert(document)))!
    }

    /// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
    /// they will be generated.
    /// - Parameters:
    ///   - documents: The `Document` values in a bson array to insert.
    /// - Returns: The object ids of inserted documents.
    public func insertMany(_ documents: [Document]) async throws -> [AnyBSON] {
        try await __insertManyDocuments(documents.map(ObjectiveCSupport.convert))
            .compactMap(ObjectiveCSupport.convertBson(object:))
    }

#if compiler(<6)
    /// Finds the documents in this collection which match the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    /// - Returns: Array of `Document` filtered.
    @_unsafeInheritExecutor
    public func find(filter: Document, options: FindOptions? = nil) async throws -> [Document] {
        try await __findWhere(ObjectiveCSupport.convert(filter),
                              options: options ?? .init())
            .map(ObjectiveCSupport.convert)
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    /// - Returns: `Document` filtered.
    @_unsafeInheritExecutor
    public func findOneDocument(filter: Document, options: FindOptions? = nil) async throws -> Document? {
        try await __findOneDocumentWhere(ObjectiveCSupport.convert(filter),
                                         options: options ?? .init())
            .map(ObjectiveCSupport.convert)
    }
#else
    /// Finds the documents in this collection which match the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    /// - Returns: Array of `Document` filtered.
    public func find(filter: Document, options: FindOptions = .init(),
                     _isolation: isolated (any Actor)? = #isolation) async throws -> [Document] {
        try await withCheckedThrowingContinuation { continuation in
            __findWhere(ObjectiveCSupport.convert(filter),
                        options: options) { bson, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: bson!.map(ObjectiveCSupport.convert))
                }
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
    /// - Returns: `Document` filtered.
    public func findOneDocument(filter: Document, options: FindOptions = .init(),
                                _isolation: isolated (any Actor)? = #isolation) async throws -> Document? {
        try await withCheckedThrowingContinuation { continuation in
            __findOneDocumentWhere(ObjectiveCSupport.convert(filter),
                                   options: options) { bson, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: bson.map(ObjectiveCSupport.convert))
                }
            }
        }
    }
#endif

    /// Runs an aggregation framework pipeline against this collection.
    /// - Parameters:
    ///   - pipeline: A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
    /// - Returns:An array of `Document` result of the aggregation operation.
    public func aggregate(pipeline: [Document]) async throws -> [Document] {
        try await __aggregate(withPipeline: pipeline.map(ObjectiveCSupport.convert))
            .map(ObjectiveCSupport.convert)
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - limit: The max amount of documents to count
    /// - Returns: Count of the documents that matched the filter.
    public func count(filter: Document, limit: Int? = nil) async throws -> Int {
        try await __countWhere(ObjectiveCSupport.convert(filter), limit: limit ?? 0)
    }

    /// Deletes a single matching document from the collection.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    /// - Returns: `Int` count of deleted documents.
    public func deleteOneDocument(filter: Document) async throws -> Int {
        try await __deleteOneDocumentWhere(ObjectiveCSupport.convert(filter))
    }

    /// Deletes multiple documents
    /// - Parameters:
    ///   - filter: Document representing the match criteria
    /// - Returns: `Int` count of deleted documents.
    public func deleteManyDocuments(filter: Document) async throws -> Int {
        try await __deleteManyDocumentsWhere(ObjectiveCSupport.convert(filter))
    }

    // NEXT-MAJOR: there's no reason for upsert to be optional
    /// Updates a single document matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - upsert: When true, creates a new document if no document matches the query.
    /// - Returns: `UpdateResult`result of the `updateOne` operation.
    public func updateOneDocument(filter: Document,
                                  update: Document,
                                  upsert: Bool? = nil) async throws -> UpdateResult {
        try await __updateOneDocumentWhere(ObjectiveCSupport.convert(filter),
                                           updateDocument: ObjectiveCSupport.convert(update),
                                           upsert: upsert ?? false)
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - upsert: When true, creates a new document if no document matches the query.
    /// - Returns:`UpdateResult`result of the `updateMany` operation.
    public func updateManyDocuments(filter: Document,
                                    update: Document,
                                    upsert: Bool? = nil) async throws -> UpdateResult {
        try await __updateManyDocumentsWhere(ObjectiveCSupport.convert(filter),
                                             updateDocument: ObjectiveCSupport.convert(update),
                                             upsert: upsert ?? false)
    }

#if compiler(<6)
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
    /// - Returns: `Document` result of the attempt to update a document  or `nil` if document wasn't found.
    @_unsafeInheritExecutor
    public func findOneAndUpdate(filter: Document, update: Document,
                                 options: FindOneAndModifyOptions? = nil) async throws -> Document? {
        try await __findOneAndUpdateWhere(ObjectiveCSupport.convert(filter),
                                          updateDocument: ObjectiveCSupport.convert(update),
                                          options: options ?? .init())
            .map(ObjectiveCSupport.convert)
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
    /// - Returns: `Document`result of the attempt to reaplce a document   or `nil` if document wasn't found.
    @_unsafeInheritExecutor
    public func findOneAndReplace(filter: Document, replacement: Document,
                                  options: FindOneAndModifyOptions? = nil) async throws -> Document? {
        try await __findOneAndReplaceWhere(ObjectiveCSupport.convert(filter),
                                           replacementDocument: ObjectiveCSupport.convert(replacement),
                                           options: options ?? .init())
            .map(ObjectiveCSupport.convert)
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
    /// - Returns: `Document` result of the attempt to delete a document  or `nil` if document wasn't found.
    @_unsafeInheritExecutor
    public func findOneAndDelete(filter: Document,
                                 options: FindOneAndModifyOptions? = nil) async throws -> Document? {
        try await __findOneAndDeleteWhere(ObjectiveCSupport.convert(filter),
                                          options: options ?? .init())
            .map(ObjectiveCSupport.convert)
    }
#else
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
    /// - Returns: `Document` result of the attempt to update a document  or `nil` if document wasn't found.
    public func findOneAndUpdate(filter: Document, update: Document,
                                 options: FindOneAndModifyOptions = .init(),
                                 _isolation: isolated (any Actor)? = #isolation) async throws -> Document? {
        try await withCheckedThrowingContinuation { continuation in
            __findOneAndUpdateWhere(ObjectiveCSupport.convert(filter),
                                    updateDocument: ObjectiveCSupport.convert(update),
                                    options: options) { bson, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: bson.map(ObjectiveCSupport.convert))
                }
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
    /// - Returns: `Document`result of the attempt to reaplce a document   or `nil` if document wasn't found.
    public func findOneAndReplace(filter: Document, replacement: Document,
                                  options: FindOneAndModifyOptions = .init(),
                                  _isolation: isolated (any Actor)? = #isolation) async throws -> Document? {
        try await withCheckedThrowingContinuation { continuation in
            __findOneAndReplaceWhere(ObjectiveCSupport.convert(filter),
                                     replacementDocument: ObjectiveCSupport.convert(replacement),
                                     options: options) { bson, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: bson.map(ObjectiveCSupport.convert))
                }
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
    /// - Returns: `Document` result of the attempt to delete a document  or `nil` if document wasn't found.
    public func findOneAndDelete(filter: Document,
                                 options: FindOneAndModifyOptions = .init(),
                                 _isolation: isolated (any Actor)? = #isolation) async throws -> Document? {
        try await withCheckedThrowingContinuation { continuation in
            __findOneAndDeleteWhere(ObjectiveCSupport.convert(filter),
                                    options: options) { bson, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: bson.map(ObjectiveCSupport.convert))
                }
            }
        }
    }
#endif
}

private class ChangeEventDelegateProxy: RLMChangeEventDelegate {
    // NEXT-MAJOR: This doesn't need to be weak and making it not weak would
    // allow removing the class requirement on ChangeEventDelegate
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

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers {
    private class WatchSubscription<S: Subscriber>: RLMChangeEventDelegate, Subscription where S.Input == AnyBSON, S.Failure == Error {
        private var changeStream: RLMChangeStream!
        private var subscriber: S
        private var onOpen: (@Sendable () -> Void)?

        init(publisher: __shared WatchPublisher, subscriber: S) {
            self.subscriber = subscriber
            self.onOpen = publisher.openEvent
            let scheduler = publisher.scheduler
            changeStream = publisher.collection.watch(
                withMatchFilter: publisher.matchFilter.map(ObjectiveCSupport.convert) as RLMBSON?,
                idFilter: publisher.filterIds as RLMBSON?,
                delegate: self as RLMChangeEventDelegate,
                scheduler: scheduler ?? DispatchQueue.main.schedule) as RLMChangeStream
        }

        func request(_ demand: Subscribers.Demand) { }

        func cancel() {
            changeStream.close()
        }

        func changeStreamDidOpen(_ changeStream: RLMChangeStream) {
            onOpen?()
        }

        func changeStreamDidCloseWithError(_ error: Error?) {
            if let error = error {
                subscriber.receive(completion: .failure(error))
            } else {
                subscriber.receive(completion: .finished)
            }
        }

        func changeStreamDidReceiveError(_ error: Error) {
            subscriber.receive(completion: .failure(error))
        }

        func changeStreamDidReceiveChangeEvent(_ changeEvent: RLMBSON) {
            if let changeEvent = ObjectiveCSupport.convert(object: changeEvent) {
                _ = subscriber.receive(changeEvent)
            }
        }
    }

    /// A publisher that emits a change event each time the remote MongoDB collection changes.
    public struct WatchPublisher: Publisher {
        public typealias Output = AnyBSON
        public typealias Failure = Error

        fileprivate let collection: MongoCollection
        fileprivate let scheduler: ((@escaping () -> Void) -> Void)?
        fileprivate let filterIds: [ObjectId]?
        fileprivate let matchFilter: Document?
        fileprivate let openEvent: (@Sendable () -> Void)?

        init(collection: MongoCollection,
             scheduler: ((@escaping () -> Void) -> Void)? = nil,
             filterIds: [ObjectId]? = nil,
             matchFilter: Document? = nil,
             onOpen: (@Sendable () -> Void)? = nil) {
            self.collection = collection
            self.scheduler = scheduler
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
        public func onOpen(_ event: @escaping @Sendable () -> Void) -> Self {
            Self(collection: collection, scheduler: scheduler,
                 filterIds: filterIds, matchFilter: matchFilter, onOpen: event)
        }

        /// :nodoc:
        public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            let subscription = WatchSubscription(publisher: self, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }

        /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
        ///
        /// - parameter scheduler: The scheduler to perform the subscription on.
        /// - returns: A publisher which subscribes on the given scheduler.
        public func subscribe<S: Scheduler>(on scheduler: S) -> WatchPublisher {
            return Self(collection: collection,
                        scheduler: { scheduler.schedule($0) },
                        filterIds: filterIds,
                        matchFilter: matchFilter,
                        onOpen: openEvent)
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MongoCollection {
    /// Creates a publisher that emits a AnyBSON change event each time the MongoDB collection changes.
    ///
    /// - returns: A publisher that emits the AnyBSON change event each time the collection changes.
    public func watch() -> Publishers.WatchPublisher {
        Publishers.WatchPublisher(collection: self)
    }

    /// Creates a publisher that emits a AnyBSON change event each time the MongoDB collection changes.
    ///
    /// - Parameter filterIds: The list of _ids in the collection to watch.
    /// - Returns: A publisher that emits the AnyBSON change event each time the collection changes.
    public func watch(filterIds: [ObjectId]) -> Publishers.WatchPublisher {
        Publishers.WatchPublisher(collection: self, filterIds: filterIds)
    }

    /// Creates a publisher that emits a AnyBSON change event each time the MongoDB collection changes.
    ///
    /// - Parameter matchFilter: The $match filter to apply to incoming change events.
    /// - Returns: A publisher that emits the AnyBSON change event each time the collection changes.
    public func watch(matchFilter: Document) -> Publishers.WatchPublisher {
        Publishers.WatchPublisher(collection: self, matchFilter: matchFilter)
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension MongoCollection {
    /// An async sequence of AnyBSON values containing information about each
    /// change to the MongoDB collection
    public var changeEvents: AsyncThrowingPublisher<Publishers.WatchPublisher> {
        Publishers.WatchPublisher(collection: self)
            .subscribe(on: ImmediateScheduler.shared).values
    }

    /// An async sequence of AnyBSON values containing information about each
    /// change to the MongoDB collection
    ///  - parameter onOpen: A callback which is invoked when the watch stream
    ///  has initialized on the server. Server-side changes triggered before
    ///  this callback is invoked may not produce change events.
    public func changeEvents(onOpen: @Sendable @escaping () -> Void)
            -> AsyncThrowingPublisher<Publishers.WatchPublisher> {
        Publishers.WatchPublisher(collection: self, onOpen: onOpen)
            .subscribe(on: ImmediateScheduler.shared).values
    }

    /// An async sequence of AnyBSON values containing information about each
    /// change to objects with ids contained in `filterIds` within the the
    /// MongoDB collection.
    ///  - parameter filterIds: Document ids which should produce change events
    ///  - parameter onOpen: An optional callback which is invoked when the
    ///  watch stream has initialized on the server. Server-side changes
    ///  triggered before this callback is invoked may not produce change
    ///  events.
    public func changeEvents(filterIds: [ObjectId], onOpen: (@Sendable () -> Void)? = nil)
            -> AsyncThrowingPublisher<Publishers.WatchPublisher> {
        Publishers.WatchPublisher(collection: self, filterIds: filterIds, onOpen: onOpen)
            .subscribe(on: ImmediateScheduler.shared).values
    }

    /// An async sequence of AnyBSON values containing information about each
    /// change to objects within the MongoDB collection matching the given
    /// $match filter.
    ///  - parameter matchFilter: $match filter to filter the documents which
    ///  produce change events.
    ///  - parameter onOpen: An optional callback which is invoked when the
    ///  watch stream has initialized on the server. Server-side changes
    ///  triggered before this callback is invoked may not produce change
    ///  events.
    public func changeEvents(matchFilter: Document, onOpen: (@Sendable () -> Void)? = nil)
            -> AsyncThrowingPublisher<Publishers.WatchPublisher> {
        Publishers.WatchPublisher(collection: self, matchFilter: matchFilter, onOpen: onOpen)
            .subscribe(on: ImmediateScheduler.shared).values
    }
}

@available(macOS 10.15, watchOS 6.0, iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
@usableFromInline
internal func future<T>(_ fn: @escaping (@escaping @Sendable (Result<T, Error>) -> Void) -> Void) -> Future<T, Error> {
    return Future<T, Error> { promise in
        // Future.Promise currently isn't marked as Sendable despite that being
        // the whole point of Future
        typealias SendablePromise = @Sendable (Result<T, Error>) -> Void
        fn(unsafeBitCast(promise, to: SendablePromise.self))
    }
}

@available(macOS 10.15, watchOS 6.0, iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
public extension MongoCollection {
    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// - parameter document:  A `Document` value to insert.
    /// - returns: A publisher that eventually return the object id of the inserted document or `Error`.
    func insertOne(_ document: Document) -> Future<AnyBSON, Error> {
        return future { self.insertOne(document, $0) }
    }

    /// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
    /// they will be generated.
    /// - parameter documents: The `Document` values in a bson array to insert.
    /// - returns: A publisher that eventually return the object ids of inserted documents or `Error`.
    func insertMany(_ documents: [Document]) -> Future<[AnyBSON], Error> {
        return future { self.insertMany(documents, $0) }
    }

    /// Finds the documents in this collection which match the provided filter.
    /// - parameter filter: A `Document` as bson that should match the query.
    /// - parameter options: `FindOptions` to use when executing the command.
    /// - returns: A publisher that eventually return `[ObjectId]` of documents or `Error`.
    func find(filter: Document, options: FindOptions) -> Future<[Document], Error> {
        return future { self.find(filter: filter, options: options, $0) }
    }

    /// Finds the documents in this collection which match the provided filter.
    /// - parameter filter: A `Document` as bson that should match the query.
    /// - returns: A publisher that eventually return `[ObjectId]` of documents or `Error`.
    func find(filter: Document) -> Future<[Document], Error> {
        return future { self.find(filter: filter, $0) }
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - parameter filter: A `Document` as bson that should match the query.
    /// - parameter options: `FindOptions` to use when executing the command.
    /// - returns: A publisher that eventually return `Document` or `Error`.
    func findOneDocument(filter: Document, options: FindOptions) -> Future<Document?, Error> {
        return future { self.findOneDocument(filter: filter, $0) }
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - parameter filter: A `Document` as bson that should match the query.
    /// - returns: A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneDocument(filter: Document) -> Future<Document?, Error> {
        return future { self.findOneDocument(filter: filter, $0) }
    }

    /// Runs an aggregation framework pipeline against this collection.
    /// - parameter pipeline: A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
    /// - returns: A publisher that eventually return `Document` or `Error`.
    func aggregate(pipeline: [Document]) -> Future<[Document], Error> {
        return future { self.aggregate(pipeline: pipeline, $0) }
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// - parameter filter: A `Document` as bson that should match the query.
    /// - parameter limit: The max amount of documents to count
    /// - returns: A publisher that eventually return `Int` count of documents or `Error`.
    func count(filter: Document, limit: Int) -> Future<Int, Error> {
        return future { self.count(filter: filter, limit: limit, $0) }
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// - parameter filter: A `Document` as bson that should match the query.
    /// - returns: A publisher that eventually return `Int` count of documents or `Error`.
    func count(filter: Document) -> Future<Int, Error> {
        return future { self.count(filter: filter, $0) }
    }

    /// Deletes a single matching document from the collection.
    /// - parameter filter: A `Document` as bson that should match the query.
    /// - returns: A publisher that eventually return `Int` count of deleted documents or `Error`.
    func deleteOneDocument(filter: Document) -> Future<Int, Error> {
        return future { self.deleteOneDocument(filter: filter, $0) }
    }

    /// Deletes multiple documents
    /// - parameter filter: Document representing the match criteria
    /// - returns: A publisher that eventually return `Int` count of deleted documents or `Error`.
    func deleteManyDocuments(filter: Document) -> Future<Int, Error> {
        return future { self.deleteManyDocuments(filter: filter, $0) }
    }

    /// Updates a single document matching the provided filter in this collection.
    /// - parameter filter: A bson `Document` representing the match criteria.
    /// - parameter update: A bson `Document` representing the update to be applied to a matching document.
    /// - parameter upsert: When true, creates a new document if no document matches the query.
    /// - returns: A publisher that eventually return `UpdateResult` or `Error`.
    func updateOneDocument(filter: Document, update: Document, upsert: Bool) -> Future<UpdateResult, Error> {
        return future { self.updateOneDocument(filter: filter, update: update, upsert: upsert, $0) }
    }

    /// Updates a single document matching the provided filter in this collection.
    /// - parameter filter: A bson `Document` representing the match criteria.
    /// - parameter update: A bson `Document` representing the update to be applied to a matching document.
    /// - returns: A publisher that eventually return `UpdateResult` or `Error`.
    func updateOneDocument(filter: Document, update: Document) -> Future<UpdateResult, Error> {
        return future { self.updateOneDocument(filter: filter, update: update, $0) }
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// - parameter filter: A bson `Document` representing the match criteria.
    /// - parameter update: A bson `Document` representing the update to be applied to a matching document.
    /// - parameter upsert: When true, creates a new document if no document matches the query.
    /// - returns: A publisher that eventually return `UpdateResult` or `Error`.
    func updateManyDocuments(filter: Document, update: Document, upsert: Bool) -> Future<UpdateResult, Error> {
        return future { self.updateManyDocuments(filter: filter, update: update, upsert: upsert, $0) }
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// - parameter filter: A bson `Document` representing the match criteria.
    /// - parameter update: A bson `Document` representing the update to be applied to a matching document.
    /// - returns: A publisher that eventually return `UpdateResult` or `Error`.
    func updateManyDocuments(filter: Document, update: Document) -> Future<UpdateResult, Error> {
        return future { self.updateManyDocuments(filter: filter, update: update, $0) }
    }

    /// Updates a single document in a collection based on a query filter and
    /// returns the document in either its pre-update or post-update form. Unlike
    /// `updateOneDocument`, this action allows you to atomically find, update, and
    /// return a document with the same command. This avoids the risk of other
    /// update operations changing the document between separate find and update
    /// operations.
    /// - parameter filter: A bson `Document` representing the match criteria.
    /// - parameter update: A bson `Document` representing the update to be applied to a matching document.
    /// - parameter options: `RemoteFindOneAndModifyOptions` to use when executing the command.
    /// - returns: A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndUpdate(filter: Document, update: Document, options: FindOneAndModifyOptions) -> Future<Document?, Error> {
        return future { self.findOneAndUpdate(filter: filter, update: update, options: options, $0) }
    }

    /// Updates a single document in a collection based on a query filter and
    /// returns the document in either its pre-update or post-update form. Unlike
    /// `updateOneDocument`, this action allows you to atomically find, update, and
    /// return a document with the same command. This avoids the risk of other
    /// update operations changing the document between separate find and update
    /// operations.
    /// - parameter filter: A bson `Document` representing the match criteria.
    /// - parameter update: A bson `Document` representing the update to be applied to a matching document.
    /// - returns: A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndUpdate(filter: Document, update: Document) -> Future<Document?, Error> {
        return future { self.findOneAndUpdate(filter: filter, update: update, $0) }
    }

    /// Overwrites a single document in a collection based on a query filter and
    /// returns the document in either its pre-replacement or post-replacement
    /// form. Unlike `updateOneDocument`, this action allows you to atomically find,
    /// replace, and return a document with the same command. This avoids the
    /// risk of other update operations changing the document between separate
    /// find and update operations.
    /// - parameter filter: A `Document` that should match the query.
    /// - parameter replacement: A `Document` describing the replacement.
    /// - parameter options: `FindOneAndModifyOptions` to use when executing the command.
    /// - returns: A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndReplace(filter: Document, replacement: Document, options: FindOneAndModifyOptions) -> Future<Document?, Error> {
        return future { self.findOneAndReplace(filter: filter, replacement: replacement, options: options, $0) }
    }

    /// Overwrites a single document in a collection based on a query filter and
    /// returns the document in either its pre-replacement or post-replacement
    /// form. Unlike `updateOneDocument`, this action allows you to atomically find,
    /// replace, and return a document with the same command. This avoids the
    /// risk of other update operations changing the document between separate
    /// find and update operations.
    /// - parameter filter: A `Document` that should match the query.
    /// - parameter replacement: A `Document` describing the replacement.
    /// - returns: A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndReplace(filter: Document, replacement: Document) -> Future<Document?, Error> {
        return future { self.findOneAndReplace(filter: filter, replacement: replacement, $0) }
    }

    /// Removes a single document from a collection based on a query filter and
    /// returns a document with the same form as the document immediately before
    /// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
    /// find and delete a document with the same command. This avoids the risk of
    /// other update operations changing the document between separate find and
    /// delete operations.
    /// - parameter filter: A `Document` that should match the query.
    /// - parameter options: `FindOneAndModifyOptions` to use when executing the command.
    /// - returns: A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndDelete(filter: Document, options: FindOneAndModifyOptions) -> Future<Document?, Error> {
        return future { self.findOneAndDelete(filter: filter, options: options, $0) }
    }

    /// Removes a single document from a collection based on a query filter and
    /// returns a document with the same form as the document immediately before
    /// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
    /// find and delete a document with the same command. This avoids the risk of
    /// other update operations changing the document between separate find and
    /// delete operations.
    ///
    /// - parameter filter: A `Document` that should match the query.
    /// - returns: A publisher that eventually return `Document` or `nil` if document wasn't found or `Error`.
    func findOneAndDelete(filter: Document) -> Future<Document?, Error> {
        return future { self.findOneAndDelete(filter: filter, $0) }
    }
}
