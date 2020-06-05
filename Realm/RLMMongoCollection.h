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

#import <Foundation/Foundation.h>
#import "RLMObjectId.h"

NS_ASSUME_NONNULL_BEGIN
@protocol RLMBSON;

@class RLMApp, RLMFindOptions, RLMFindOneAndModifyOptions, RLMUpdateResult;

/// The `RLMMongoCollection` represents a MongoDB collection.
///
/// You can get an instance from a `RLMMongoDatabase`.
///
/// Create, read, update, and delete methods are available.
///
/// Operations against the Realm Cloud server are performed asynchronously.
///
/// - Note:
/// Before you can read or write data, a user must log in.
/// - Usage:
/// RLMMongoClient *client = [self.app mongoClient:@"mongodb1"];
/// RLMMongoDatabase *database = [client databaseWithName:@"test_data"];
/// RLMMongoCollection *collection = [database collectionWithName:@"Dog"];
/// [collection insertOneDocument:@{@"name": @"fido", @"breed": @"cane corso"} completion:...];
///
/// - SeeAlso:
/// `RLMMongoClient`, `RLMMongoDatabase`
@interface RLMMongoCollection : NSObject
/// Block which returns an RLMObjectId on a successful insert, or an error should one occur.
typedef void(^RLMMongoInsertBlock)(RLMObjectId * _Nullable, NSError * _Nullable);
/// Block which returns an array of RLMObjectId's on a successful insertMany, or an error should one occur.
typedef void(^RLMMongoInsertManyBlock)(NSArray<RLMObjectId *> * _Nullable, NSError * _Nullable);
/// Block which returns an array of Documents on a successful find operation, or an error should one occur.
typedef void(^RLMMongoFindBlock)(NSArray<NSDictionary<NSString *, id<RLMBSON>> *> * _Nullable, NSError * _Nullable);
/// Block which returns a Document on a successful findOne operation, or an error should one occur.
typedef void(^RLMMongoFindOneBlock)(NSDictionary<NSString *, id<RLMBSON>> * _Nullable, NSError * _Nullable);
/// Block which returns the number of Documents in a collection on a successful count operation, or an error should one occur.
typedef void(^RLMMongoCountBlock)(NSInteger, NSError * _Nullable);
/// Block which returns an RLMUpdateResult on a successful update operation, or an error should one occur.
typedef void(^RLMMongoUpdateBlock)(RLMUpdateResult * _Nullable, NSError * _Nullable);
/// Block which returns the deleted Document on a successful delete operation, or an error should one occur.
typedef void(^RLMMongoDeleteBlock)(NSDictionary<NSString *, id<RLMBSON>> * _Nullable, NSError * _Nullable);

/// The name of this mongodb collection.
@property (nonatomic, readonly) NSString *name;

/// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
/// generated for it.
/// @param document  A `Document` value to insert.
/// @param completion The result of attempting to perform the insert. An Id will be returned for the inserted object on sucess
- (void)insertOneDocument:(NSDictionary<NSString *, id<RLMBSON>> *)document
               completion:(RLMMongoInsertBlock)completion NS_REFINED_FOR_SWIFT;

/// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
/// they will be generated.
/// @param documents  The `Document` values in a bson array to insert.
/// @param completion The result of the insert, returns an array inserted document ids in order
- (void)insertManyDocuments:(NSArray<NSDictionary<NSString *, id<RLMBSON>> *> *)documents
                 completion:(RLMMongoInsertManyBlock)completion NS_REFINED_FOR_SWIFT;

/// Finds the documents in this collection which match the provided filter.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param options `RLMFindOptions` to use when executing the command.
/// @param completion The resulting bson array of documents or error if one occurs
- (void)findWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
          options:(RLMFindOptions *)options
       completion:(RLMMongoFindBlock)completion NS_REFINED_FOR_SWIFT;

/// Finds the documents in this collection which match the provided filter.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param completion The resulting bson array as a string or error if one occurs
- (void)findWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
       completion:(RLMMongoFindBlock)completion NS_REFINED_FOR_SWIFT;

/// Returns one document from a collection or view which matches the
/// provided filter. If multiple documents satisfy the query, this method
/// returns the first document according to the query's sort order or natural
/// order.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param options `RLMFindOptions` to use when executing the command.
/// @param completion The resulting bson or error if one occurs
- (void)findOneDocumentWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                     options:(RLMFindOptions *)options
                  completion:(RLMMongoFindOneBlock)completion NS_REFINED_FOR_SWIFT;

/// Returns one document from a collection or view which matches the
/// provided filter. If multiple documents satisfy the query, this method
/// returns the first document according to the query's sort order or natural
/// order.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param completion The resulting bson or error if one occurs
- (void)findOneDocumentWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                  completion:(RLMMongoFindOneBlock)completion NS_REFINED_FOR_SWIFT;

/// Runs an aggregation framework pipeline against this collection.
/// @param pipeline A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
/// @param completion The resulting bson array of documents or error if one occurs
- (void)aggregateWithPipeline:(NSArray<NSDictionary<NSString *, id<RLMBSON>> *> *)pipeline
                   completion:(RLMMongoFindBlock)completion NS_REFINED_FOR_SWIFT;

/// Counts the number of documents in this collection matching the provided filter.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param limit The max amount of documents to count
/// @param completion Returns the count of the documents that matched the filter.
- (void)countWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
             limit:(NSInteger)limit
        completion:(RLMMongoCountBlock)completion NS_REFINED_FOR_SWIFT;

/// Counts the number of documents in this collection matching the provided filter.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param completion Returns the count of the documents that matched the filter.
- (void)countWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
        completion:(RLMMongoCountBlock)completion NS_REFINED_FOR_SWIFT;

/// Deletes a single matching document from the collection.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param completion The result of performing the deletion. Returns the count of deleted objects
- (void)deleteOneDocumentWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                    completion:(RLMMongoCountBlock)completion NS_REFINED_FOR_SWIFT;

/// Deletes multiple documents
/// @param filterDocument Document representing the match criteria
/// @param completion The result of performing the deletion. Returns the count of the deletion
- (void)deleteManyDocumentsWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                      completion:(RLMMongoCountBlock)completion NS_REFINED_FOR_SWIFT;

/// Updates a single document matching the provided filter in this collection.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param upsert When true, creates a new document if no document matches the query.
/// @param completion The result of the attempt to update a document.
- (void)updateOneDocumentWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                        upsert:(BOOL)upsert
                    completion:(RLMMongoUpdateBlock)completion NS_REFINED_FOR_SWIFT;

/// Updates a single document matching the provided filter in this collection.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param completion The result of the attempt to update a document.
- (void)updateOneDocumentWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                    completion:(RLMMongoUpdateBlock)completion NS_REFINED_FOR_SWIFT;

/// Updates multiple documents matching the provided filter in this collection.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param upsert When true, creates a new document if no document matches the query.
/// @param completion The result of the attempt to update a document.
- (void)updateManyDocumentsWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                  updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                          upsert:(BOOL)upsert
                      completion:(RLMMongoUpdateBlock)completion NS_REFINED_FOR_SWIFT;

/// Updates multiple documents matching the provided filter in this collection.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param completion The result of the attempt to update a document.
- (void)updateManyDocumentsWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                  updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                      completion:(RLMMongoUpdateBlock)completion NS_REFINED_FOR_SWIFT;

/// Updates a single document in a collection based on a query filter and
/// returns the document in either its pre-update or post-update form. Unlike
/// `updateOneDocument`, this action allows you to atomically find, update, and
/// return a document with the same command. This avoids the risk of other
/// update operations changing the document between separate find and update
/// operations.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param options  `RemoteFindOneAndModifyOptions` to use when executing the command.
/// @param completion The result of the attempt to update a document.
- (void)findOneAndUpdateWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
               updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                      options:(RLMFindOneAndModifyOptions *)options
                   completion:(RLMMongoFindOneBlock)completion NS_REFINED_FOR_SWIFT;

/// Updates a single document in a collection based on a query filter and
/// returns the document in either its pre-update or post-update form. Unlike
/// `updateOneDocument`, this action allows you to atomically find, update, and
/// return a document with the same command. This avoids the risk of other
/// update operations changing the document between separate find and update
/// operations.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param completion The result of the attempt to update a document.
- (void)findOneAndUpdateWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
               updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                   completion:(RLMMongoFindOneBlock)completion NS_REFINED_FOR_SWIFT;

/// Overwrites a single document in a collection based on a query filter and
/// returns the document in either its pre-replacement or post-replacement
/// form. Unlike `updateOneDocument`, this action allows you to atomically find,
/// replace, and return a document with the same command. This avoids the
/// risk of other update operations changing the document between separate
/// find and update operations.
/// @param filterDocument  A `Document` that should match the query.
/// @param replacementDocument  A `Document` describing the replacement.
/// @param options  `RLMFindOneAndModifyOptions` to use when executing the command.
/// @param completion The result of the attempt to replace a document.
- (void)findOneAndReplaceWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
           replacementDocument:(NSDictionary<NSString *, id<RLMBSON>> *)replacementDocument
                       options:(RLMFindOneAndModifyOptions *)options
                    completion:(RLMMongoFindOneBlock)completion NS_REFINED_FOR_SWIFT;

/// Overwrites a single document in a collection based on a query filter and
/// returns the document in either its pre-replacement or post-replacement
/// form. Unlike `updateOneDocument`, this action allows you to atomically find,
/// replace, and return a document with the same command. This avoids the
/// risk of other update operations changing the document between separate
/// find and update operations.
/// @param filterDocument  A `Document` that should match the query.
/// @param replacementDocument  A `Document` describing the update.
/// @param completion The result of the attempt to replace a document.
- (void)findOneAndReplaceWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
           replacementDocument:(NSDictionary<NSString *, id<RLMBSON>> *)replacementDocument
                    completion:(RLMMongoFindOneBlock)completion NS_REFINED_FOR_SWIFT;

/// Removes a single document from a collection based on a query filter and
/// returns a document with the same form as the document immediately before
/// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
/// find and delete a document with the same command. This avoids the risk of
/// other update operations changing the document between separate find and
/// delete operations.
/// @param filterDocument  A `Document` that should match the query.
/// @param options `RLMFindOneAndModifyOptions` to use when executing the command.
/// @param completion The result of the attempt to delete a document.
- (void)findOneAndDeleteWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                      options:(RLMFindOneAndModifyOptions *)options
                   completion:(RLMMongoDeleteBlock)completion NS_REFINED_FOR_SWIFT;

/// Removes a single document from a collection based on a query filter and
/// returns a document with the same form as the document immediately before
/// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
/// find and delete a document with the same command. This avoids the risk of
/// other update operations changing the document between separate find and
/// delete operations.
/// @param filterDocument  A `Document` that should match the query.
/// @param completion The result of the attempt to delete a document.
- (void)findOneAndDeleteWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                   completion:(RLMMongoDeleteBlock)completion NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
