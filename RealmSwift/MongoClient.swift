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

/// Options to use when executing a `find` command on a `MongoCollection`.
public typealias FindOptions = RLMFindOptions

extension FindOptions {

    /// The maximum number of documents to return.
    public var limit: uint64? {
        get {
            guard let value = __limit else {
                return nil
            }
            return value.uint64Value
        }
        set {
            if let value = newValue {
                __limit = NSNumber(value: value)
            }
        }
    }
    
    /// Limits the fields to return for all matching documents.
    public var projectedBSON: Document? {
        get {
            guard let value = ObjectiveCSupport.convert(object: __projectionBson) else {
                return nil
            }
            return value.documentValue
        }
        set {
            if let value = newValue {
                __projectionBson = ObjectiveCSupport.convert(object: AnyBSON(value))
            }
        }
    }

    /// The order in which to return matching documents.
    public var sortBSON: Document? {
        get {
            guard let value = ObjectiveCSupport.convert(object: __sortBson) else {
                return nil
            }
            return value.documentValue
        }
        set {
            if let value = newValue {
                __sortBson = ObjectiveCSupport.convert(object: AnyBSON(value))
            }
        }
    }

    public convenience init(_ limit: uint64?, _ projectedBSON: Document?, _ sortBSON: Document?) {
        self.init()
        self.limit = limit
        self.projectedBSON = projectedBSON
        self.sortBSON = sortBSON
    }
}


/// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
/// or `findOneAndDelete` command on a `MongoCollection`.
public typealias FindOneAndModifyOptions = RLMFindOneAndModifyOptions

extension FindOneAndModifyOptions {

    /// Limits the fields to return for all matching documents.
    public var projectedBSON: Document? {
        get {
            guard let value = ObjectiveCSupport.convert(object: __projectionBson) else {
                return nil
            }
            return value.documentValue
        }
        set {
            if let value = newValue {
                __projectionBson = ObjectiveCSupport.convert(object: AnyBSON(value))
            }
        }
    }

    /// The order in which to return matching documents.
    public var sortBSON: Document? {
        get {
            guard let value = ObjectiveCSupport.convert(object: __sortBson) else {
                return nil
            }
            return value.documentValue
        }
        set {
            if let value = newValue {
                __sortBson = ObjectiveCSupport.convert(object: AnyBSON(value))
            }
        }
    }

    public convenience init(_ projectedBSON: Document?,
                            _ sortBSON: Document?,
                            _ upsert: Bool=false,
                            _ returnNewDocument: Bool=false) {
        self.init()
        self.projectedBSON = projectedBSON
        self.sortBSON = sortBSON
        self.upsert = upsert
        self.returnNewDocument = returnNewDocument
    }
}

/// The result of an `updateOne` or `updateMany` operation a `MongoCollection`.
public typealias UpdateResult = RLMUpdateResult

extension UpdateResult {
    /// The number of matching documents
    public var matchedCount: UInt64 {
        return __matchedCount.uint64Value
    }
    
    /// The number of documents modified.
    public var modifiedCount: UInt64 {
        return __modifiedCount.uint64Value
    }
    /// The identifier of the inserted document if an upsert took place.
    public var objectId: ObjectId? {
        guard let objId = __objectId else {
            return nil
        }

        return try? ObjectId(string: objId.stringValue)
    }
}

public typealias InsertBlock = RLMInsertBlock
public typealias InsertManyBlock = RLMInsertManyBlock
public typealias FindBlock = RLMFindBlock
public typealias FindOneBlock = RLMFindOneBlock
public typealias CountBlock = RLMCountBlock
public typealias UpdateBlock = (UpdateResult?, Error?) -> Void
public typealias DeleteBlock = RLMDeleteBlock

extension MongoCollection {

    /// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
    /// generated for it.
    /// - Parameters:
    ///   - document: document  A `Document` value to insert.
    ///   - completion: The result of attempting to perform the insert. An Id will be returned for the inserted object on sucess
    public func insertOne(_ document: Document, _ completion: @escaping InsertBlock) {
        self.__insertOneDocument(toRLMBSON(document), completion: completion)
    }

    /// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
    /// they will be generated.
    /// - Parameters:
    ///   - documents: The `Document` values in a bson array to insert.
    ///   - completion: The result of the insert, returns an array inserted document ids in order.
    public func insertMany(_ documents: [Document], _ completion: @escaping InsertManyBlock) {
        self.__insertManyDocuments(toRLMBSONArray(documents), completion: completion)
    }

    /// Finds the documents in this collection which match the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    ///   - completion: The resulting bson array of documents or error if one occurs
    public func find(_ filter: Document, _ options: FindOptions, _ completion: @escaping FindBlock) {
        self.__find(toRLMBSON(filter), options: options, completion: completion)
    }

    /// Finds the documents in this collection which match the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    ///   - completion: The resulting bson array of documents or error if one occurs
    public func find(_ filter: Document, _ completion: @escaping FindBlock) {
        self.__find(toRLMBSON(filter), completion: completion)
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - options: `FindOptions` to use when executing the command.
    ///   - completion: The resulting bson or error if one occurs
    public func findOneDocument(_ filter: Document, _ options: FindOptions, _ completion: @escaping FindOneBlock) {
        self.__findOneDocument(toRLMBSON(filter), options: options, completion: completion)
    }

    /// Returns one document from a collection or view which matches the
    /// provided filter. If multiple documents satisfy the query, this method
    /// returns the first document according to the query's sort order or natural
    /// order.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: The resulting bson or error if one occurs
    public func findOneDocument(_ filter: Document, _ completion: @escaping FindOneBlock) {
        self.__findOneDocument(toRLMBSON(filter), completion: completion)
    }

    /// Runs an aggregation framework pipeline against this collection.
    /// - Parameters:
    ///   - pipeline: A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
    ///   - completion: The resulting bson array of documents or error if one occurs
    public func aggregate(_ pipeline: [Document], _ completion: @escaping FindBlock) {
        self.__aggregate(toRLMBSONArray(pipeline), completion: completion)
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - limit: The max amount of documents to count
    ///   - completion: Returns the count of the documents that matched the filter.
    public func count(_ filter: Document, _ limit: uint64, _ completion: @escaping CountBlock) {
        self.__count(toRLMBSON(filter), limit: NSNumber(value: limit), completion: completion)
    }

    /// Counts the number of documents in this collection matching the provided filter.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: Returns the count of the documents that matched the filter.
    public func count(_ filter: Document, _ completion: @escaping CountBlock) {
        self.__count(toRLMBSON(filter), completion: completion)
    }

    /// Deletes a single matching document from the collection.
    /// - Parameters:
    ///   - filter: A `Document` as bson that should match the query.
    ///   - completion: The result of performing the deletion. Returns the count of deleted objects
    public func deleteOneDocument(_ filter: Document, _ completion: @escaping CountBlock) {
        self.__deleteOneDocument(toRLMBSON(filter), completion: completion)
    }

    /// Deletes multiple documents
    /// - Parameters:
    ///   - filter: Document representing the match criteria
    ///   - completion: The result of performing the deletion. Returns the count of the deletion
    public func deleteManyDocuments(_ filter: Document, _ completion: @escaping CountBlock) {
        self.__deleteManyDocuments(toRLMBSON(filter), completion: completion)
    }

    /// Updates a single document matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - upsert: When true, creates a new document if no document matches the query.
    ///   - completion: The result of the attempt to update a document.
    public func updateOneDocument(_ filter: Document,
                                  _ update: Document,
                                  _ upsert: Bool,
                                  _ completion: @escaping UpdateBlock) {
        self.__updateOneDocument(toRLMBSON(filter),
                                 updateDocument: toRLMBSON(update),
                                 upsert: upsert,
                                 completion: completion)
    }

    /// Updates a single document matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - completion: The result of the attempt to update a document.
    public func updateOneDocument(_ filter: Document,
                                  _ update: Document,
                                  _ completion: @escaping UpdateBlock) {
        self.__updateOneDocument(toRLMBSON(filter),
                                 updateDocument: toRLMBSON(update),
                                 completion: completion)
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - upsert: When true, creates a new document if no document matches the query.
    ///   - completion: The result of the attempt to update a document.
    public func updateManyDocuments(_ filter: Document,
                                    _ update: Document,
                                    _ upsert: Bool,
                                    _ completion: @escaping UpdateBlock) {
        self.__updateManyDocuments(toRLMBSON(filter),
                                   updateDocument: toRLMBSON(update),
                                   upsert: upsert,
                                   completion: completion)
    }

    /// Updates multiple documents matching the provided filter in this collection.
    /// - Parameters:
    ///   - filter: A bson `Document` representing the match criteria.
    ///   - update: A bson `Document` representing the update to be applied to a matching document.
    ///   - completion: The result of the attempt to update a document.
    public func updateManyDocuments(_ filter: Document,
                                    _ update: Document,
                                    _ completion: @escaping UpdateBlock) {
        self.__updateManyDocuments(toRLMBSON(filter),
                                   updateDocument: toRLMBSON(update),
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
    public func findOneAndUpdate(_ filter: Document,
                                 _ update: Document,
                                 _ options: FindOneAndModifyOptions,
                                 _ completion: @escaping FindOneBlock) {
        self.__findOneAndUpdate(toRLMBSON(filter),
                                updateDocument: toRLMBSON(update),
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
    public func findOneAndUpdate(_ filter: Document,
                                 _ update: Document,
                                 _ completion: @escaping FindOneBlock) {
        self.__findOneAndUpdate(toRLMBSON(filter),
                                updateDocument: toRLMBSON(update),
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
    public func findOneAndReplace(_ filter: Document,
                                  _ replacement: Document,
                                  _ options: FindOneAndModifyOptions,
                                  _ completion: @escaping FindOneBlock) {
        self.__findOneAndReplace(toRLMBSON(filter),
                                replacementDocument: toRLMBSON(replacement),
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
    public func findOneAndReplace(_ filter: Document,
                                  _ replacement: Document,
                                  _ completion: @escaping FindOneBlock) {
        self.__findOneAndReplace(toRLMBSON(filter),
                                replacementDocument: toRLMBSON(replacement),
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
    public func findOneAndDelete(_ filter: Document,
                                 _ options: FindOneAndModifyOptions,
                                 _ completion: @escaping DeleteBlock) {
        self.__findOneAndDelete(toRLMBSON(filter),
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
    public func findOneAndDelete(_ filter: Document,
                                 _ completion: @escaping DeleteBlock) {
        self.__findOneAndDelete(toRLMBSON(filter),
                                completion: completion)
    }

    private func toRLMBSON(_ document: Document) -> RLMBSON {
        guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(document)) else {
            fatalError("Could not cast Document to RLMBSON")
        }
        return rlmBSON
    }

    private func toRLMBSONArray(_ documents: [Document]) -> [RLMBSON] {
        let convertedDocuments = documents.map { (document: Document) -> RLMBSON in
            guard let rlmBSON = ObjectiveCSupport.convert(object: AnyBSON(document)) else {
                fatalError("Could not cast Document to RLMBSON")
            }
            return rlmBSON
        }
        return convertedDocuments
    }

}
