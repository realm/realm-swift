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
 * `RealmApp`, `MongoDatabase`, `MongoCollection`
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
    public var projected: Document? {
        get {
            guard let value = ObjectiveCSupport.convert(object: __projection) else {
                return nil
            }
            return value.documentValue
        }
        set {
            if let value = newValue {
                __projection = ObjectiveCSupport.convert(object: AnyBSON(value))
            }
        }
    }

    /// The order in which to return matching documents.
    public var sort: Document? {
        get {
            guard let value = ObjectiveCSupport.convert(object: __sort) else {
                return nil
            }
            return value.documentValue
        }
        set {
            if let value = newValue {
                __sort = ObjectiveCSupport.convert(object: AnyBSON(value))
            }
        }
    }

    /// Options to use when executing a `find` command on a `RLMMongoCollection`.
    /// - Parameters:
    ///   - limit: The maximum number of documents to return. Specifying 0 will return all documents.
    ///   - projected: Limits the fields to return for all matching documents.
    ///   - sort: The order in which to return matching documents.
    public convenience init(_ limit: Int?, _ projected: Document?, _ sort: Document?) {
        self.init()
        self.limit = limit ?? 0
        self.projected = projected
        self.sort = sort
    }
}


/// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
/// or `findOneAndDelete` command on a `MongoCollection`.
public typealias FindOneAndModifyOptions = RLMFindOneAndModifyOptions

extension FindOneAndModifyOptions {

    /// Limits the fields to return for all matching documents.
    public var projection: Document? {
        get {
            guard let value = ObjectiveCSupport.convert(object: __projection) else {
                return nil
            }
            return value.documentValue
        }
        set {
            if let value = newValue {
                __projection = ObjectiveCSupport.convert(object: AnyBSON(value))
            }
        }
    }

    /// The order in which to return matching documents.
    public var sort: Document? {
        get {
            guard let value = ObjectiveCSupport.convert(object: __sort) else {
                return nil
            }
            return value.documentValue
        }
        set {
            if let value = newValue {
                __sort = ObjectiveCSupport.convert(object: AnyBSON(value))
            }
        }
    }

    /// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
    /// or `findOneAndDelete` command on a `RLMMongoCollection`
    /// - Parameters:
    ///   - projection: Limits the fields to return for all matching documents.
    ///   - sort: The order in which to return matching documents.
    ///   - upsert: Whether or not to perform an upsert, default is false
    ///   (only available for find_one_and_replace and find_one_and_update)
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
}

/// The result of an `updateOne` or `updateMany` operation a `MongoCollection`.
public typealias UpdateResult = RLMUpdateResult

/// Block which returns an RLMObjectId on a successful insert, or an error should one occur.
public typealias MongoInsertBlock = RLMMongoInsertBlock
/// Block which returns an array of RLMObjectId's on a successful insertMany, or an error should one occur.
public typealias MongoInsertManyBlock = RLMMongoInsertManyBlock
/// Block which returns an array of Documents on a successful find operation, or an error should one occur.
public typealias MongoFindBlock = RLMMongoFindBlock
/// Block which returns a Document on a successful findOne operation, or an error should one occur.
public typealias MongoFindOneBlock = RLMMongoFindOneBlock
/// Block which returns the number of Documents in a collection on a successful count operation, or an error should one occur.
public typealias MongoCountBlock = RLMMongoCountBlock
/// Block which returns an RLMUpdateResult on a successful update operation, or an error should one occur.
public typealias MongoUpdateBlock = (UpdateResult?, Error?) -> Void
/// Block which returns the deleted Document on a successful delete operation, or an error should one occur.
public typealias MongoDeleteBlock = RLMMongoDeleteBlock

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

extension MongoCollection {

    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// - Parameters:
    ///   - document: document  A `Document` value to insert.
    ///   - completion: The result of attempting to perform the insert. An Id will be returned for the inserted object on sucess
    public func insertOne(_ document: Document, _ completion: @escaping MongoInsertBlock) {
        guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(document)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__insertOneDocument(rlmBSON, completion: completion)
    }

    /// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
    /// they will be generated.
    /// - Parameters:
    ///   - documents: The `Document` values in a bson array to insert.
    ///   - completion: The result of the insert, returns an array inserted document ids in order.
    public func insertMany(_ documents: [Document], _ completion: @escaping MongoInsertManyBlock) {
        do {
            let convertedDocuments = try documents.map { (document: Document) -> [String: RLMBSON] in
                guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(document)) as? [String: RLMBSON] else {
                    throw BSONError.swiftToObjCConversion
                }
                return rlmBSON
            }
            self.__insertManyDocuments(convertedDocuments, completion: completion)
        } catch let error {
            return completion(nil, error)
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
        guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__findWhere(rlmBSON, options: options, completion: completion)
    }

    /// Finds the documents in this collection which match the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: The resulting bson array of documents or error if one occurs
    public func find(filter: Document,
                     _ completion: @escaping MongoFindBlock) {
        guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__findWhere(rlmBSON, completion: completion)
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
        guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__findOneDocumentWhere(rlmBSON, options: options, completion: completion)
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
        guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__findOneDocumentWhere(rlmBSON, completion: completion)
    }

    /// Runs an aggregation framework pipeline against this collection.
    /// - Parameters:
    ///   - pipeline: A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
    ///   - completion: The resulting bson array of documents or error if one occurs
    public func aggregate(pipeline: [Document],
                          _ completion: @escaping MongoFindBlock) {
        do {
            let convertedDocuments = try pipeline.map { (document: Document) -> [String: RLMBSON] in
                guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(document)) as? [String: RLMBSON] else {
                    throw BSONError.swiftToObjCConversion
                }
                return rlmBSON
            }
            self.__aggregate(withPipeline: convertedDocuments, completion: completion)
        } catch let error {
            completion(nil, error)
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
        guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(0, BSONError.swiftToObjCConversion)
        }
        self.__countWhere(rlmBSON, limit: limit, completion: completion)
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: Returns the count of the documents that matched the filter.
    public func count(filter: Document,
                      _ completion: @escaping MongoCountBlock) {
        guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(0, BSONError.swiftToObjCConversion)
        }
        self.__countWhere(rlmBSON, completion: completion)
    }

    /// Deletes a single matching document from the collection.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: The result of performing the deletion. Returns the count of deleted objects
    public func deleteOneDocument(filter: Document,
                                  _ completion: @escaping MongoCountBlock) {
        guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(0, BSONError.swiftToObjCConversion)
        }
        self.__deleteOneDocumentWhere(rlmBSON, completion: completion)
    }

    /// Deletes multiple documents
    /// - Parameters:
    ///   - filter: Document representing the match criteria
    ///   - completion: The result of performing the deletion. Returns the count of the deletion
    public func deleteManyDocuments(filter: Document,
                                    _ completion: @escaping MongoCountBlock) {
        guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(0, BSONError.swiftToObjCConversion)
        }
        self.__deleteManyDocumentsWhere(rlmBSON, completion: completion)
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
        guard let filterBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }

        guard let updateBSON = ObjectiveCSupport.convert(object: AnyBSON(update)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__updateOneDocumentWhere(filterBSON,
                                      updateDocument: updateBSON,
                                      upsert: upsert,
                                      completion: completion)
    }

    /// Updates a single document matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - completion: The result of the attempt to update a document.
    public func updateOneDocument(filter: Document,
                                  update: Document,
                                  _ completion: @escaping MongoUpdateBlock) {
        guard let filterBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }

        guard let updateBSON = ObjectiveCSupport.convert(object: AnyBSON(update)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__updateOneDocumentWhere(filterBSON,
                                      updateDocument: updateBSON,
                                      completion: completion)
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
        guard let filterBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }

        guard let updateBSON = ObjectiveCSupport.convert(object: AnyBSON(update)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__updateManyDocumentsWhere(filterBSON,
                                        updateDocument: updateBSON,
                                        upsert: upsert,
                                        completion: completion)
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - completion: The result of the attempt to update a document.
    public func updateManyDocuments(filter: Document,
                                    update: Document,
                                    _ completion: @escaping MongoUpdateBlock) {
        guard let filterBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }

        guard let updateBSON = ObjectiveCSupport.convert(object: AnyBSON(update)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__updateManyDocumentsWhere(filterBSON,
                                        updateDocument: updateBSON,
                                        completion: completion)
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
        guard let filterBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }

        guard let updateBSON = ObjectiveCSupport.convert(object: AnyBSON(update)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__findOneAndUpdateWhere(filterBSON,
                                     updateDocument: updateBSON,
                                     options: options,
                                     completion: completion)
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
        guard let filterBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }

        guard let updateBSON = ObjectiveCSupport.convert(object: AnyBSON(update)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__findOneAndUpdateWhere(filterBSON,
                                     updateDocument: updateBSON,
                                     completion: completion)
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
        guard let filterBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }

        guard let replacementBSON = ObjectiveCSupport.convert(object: AnyBSON(replacement)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__findOneAndReplaceWhere(filterBSON,
                                      replacementDocument: replacementBSON,
                                      options: options,
                                      completion: completion)
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
        guard let filterBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }

        guard let replacementBSON = ObjectiveCSupport.convert(object: AnyBSON(replacement)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__findOneAndReplaceWhere(filterBSON,
                                      replacementDocument: replacementBSON,
                                      completion: completion)
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
                                 _ completion: @escaping MongoDeleteBlock) {
        guard let filterBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__findOneAndDeleteWhere(filterBSON,
                                     options: options,
                                     completion: completion)
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
                                 _ completion: @escaping MongoDeleteBlock) {
        guard let filterBSON = ObjectiveCSupport.convert(object: AnyBSON(filter)) as? [String: RLMBSON] else {
            return completion(nil, BSONError.swiftToObjCConversion)
        }
        self.__findOneAndDeleteWhere(filterBSON,
                                     completion: completion)
    }
}
