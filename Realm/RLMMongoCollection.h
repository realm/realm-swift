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

@interface RLMMongoCollection : NSObject

typedef void(^RLMInsertBlock)(RLMObjectId * _Nullable, NSError * _Nullable);
typedef void(^RLMInsertManyBlock)(NSArray<RLMObjectId *> * _Nullable, NSError * _Nullable);
typedef void(^RLMFindBlock)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable);
typedef void(^RLMFindOneBlock)(NSDictionary * _Nullable, NSError * _Nullable);
typedef void(^RLMCountBlock)(NSNumber * _Nullable, NSError * _Nullable);
typedef void(^RLMUpdateBlock)(RLMUpdateResult * _Nullable, NSError * _Nullable);
typedef void(^RLMDeleteBlock)(NSError * _Nullable);

@property (nonatomic, readonly) NSString *name;

/// Encodes the provided value to BSON and inserts it. If the value is missing an identifier, one will be
/// generated for it.
/// @param document  A `Document` value to insert.
/// @param completion The result of attempting to perform the insert. An Id will be returned for the inserted object on sucess
- (void)insertOneDocument:(id<RLMBSON>)document
               completion:(RLMInsertBlock)completion;

/// Encodes the provided values to BSON and inserts them. If any values are missing identifiers,
/// they will be generated.
/// @param documents  The `Document` values in a bson array to insert.
/// @param completion The result of the insert, returns an array inserted document ids in order
- (void)insertManyDocuments:(NSArray<id<RLMBSON>> *)documents
                 completion:(RLMInsertManyBlock)completion;

/// Finds the documents in this collection which match the provided filter.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param options `RLMFindOptions` to use when executing the command.
/// @param completion The resulting bson array of documents or error if one occurs
- (void)find:(id<RLMBSON>)filterDocument
     options:(RLMFindOptions *)options
  completion:(RLMFindBlock)completion;

/// Finds the documents in this collection which match the provided filter.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param completion The resulting bson array as a string or error if one occurs
- (void)find:(id<RLMBSON>)filterDocument
  completion:(RLMFindBlock)completion;

/// Returns one document from a collection or view which matches the
/// provided filter. If multiple documents satisfy the query, this method
/// returns the first document according to the query's sort order or natural
/// order.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param options `RLMFindOptions` to use when executing the command.
/// @param completion The resulting bson or error if one occurs
- (void)findOneDocument:(id<RLMBSON>)filterDocument
                options:(RLMFindOptions *)options
             completion:(RLMFindOneBlock)completion;

/// Returns one document from a collection or view which matches the
/// provided filter. If multiple documents satisfy the query, this method
/// returns the first document according to the query's sort order or natural
/// order.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param completion The resulting bson or error if one occurs
- (void)findOneDocument:(id<RLMBSON>)filterDocument
             completion:(RLMFindOneBlock)completion;

/// Runs an aggregation framework pipeline against this collection.
/// @param pipeline A bson array made up of `Documents` containing the pipeline of aggregation operations to perform.
/// @param completion The resulting bson array of documents or error if one occurs
- (void)aggregate:(NSArray<id<RLMBSON>> *)pipeline
       completion:(RLMFindBlock)completion;

/// Counts the number of documents in this collection matching the provided filter.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param limit The max amount of documents to count
/// @param completion Returns the count of the documents that matched the filter.
- (void)count:(id<RLMBSON>)filterDocument
        limit:(NSNumber *)limit
   completion:(RLMCountBlock)completion;

/// Counts the number of documents in this collection matching the provided filter.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param completion Returns the count of the documents that matched the filter.
- (void)count:(id<RLMBSON>)filterDocument
   completion:(RLMCountBlock)completion;

/// Deletes a single matching document from the collection.
/// @param filterDocument A `Document` as bson that should match the query.
/// @param completion The result of performing the deletion. Returns the count of deleted objects
- (void)deleteOneDocument:(id<RLMBSON>)filterDocument
               completion:(RLMCountBlock)completion;

/// Deletes multiple documents
/// @param filterDocument Document representing the match criteria
/// @param completion The result of performing the deletion. Returns the count of the deletion
- (void)deleteManyDocuments:(id<RLMBSON>)filterDocument
                 completion:(RLMCountBlock)completion;

/// Updates a single document matching the provided filter in this collection.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param upsert When true, creates a new document if no document matches the query.
/// @param completion The result of the attempt to update a document.
- (void)updateOneDocument:(id<RLMBSON>)filterDocument
           updateDocument:(id<RLMBSON>)updateDocument
                   upsert:(BOOL)upsert
               completion:(RLMUpdateBlock)completion;

/// Updates a single document matching the provided filter in this collection.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param completion The result of the attempt to update a document.
- (void)updateOneDocument:(id<RLMBSON>)filterDocument
           updateDocument:(id<RLMBSON>)updateDocument
               completion:(RLMUpdateBlock)completion;

/// Updates multiple documents matching the provided filter in this collection.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param upsert When true, creates a new document if no document matches the query.
/// @param completion The result of the attempt to update a document.
- (void)updateManyDocuments:(id<RLMBSON>)filterDocument
             updateDocument:(id<RLMBSON>)updateDocument
                     upsert:(BOOL)upsert
                 completion:(RLMUpdateBlock)completion;

/// Updates multiple documents matching the provided filter in this collection.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param completion The result of the attempt to update a document.
- (void)updateManyDocuments:(id<RLMBSON>)filterDocument
             updateDocument:(id<RLMBSON>)updateDocument
                 completion:(RLMUpdateBlock)completion;

/// Updates a single document in a collection based on a query filter and
/// returns the document in either its pre-update or post-update form. Unlike
/// `updateOneDocument`, this action allows you to atomically find, update, and
/// return a document with the same command. This avoids the risk of other
/// update operations changing the document between separate find and update
/// operations.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param options Optional `RemoteFindOneAndModifyOptions` to use when executing the command.
/// @param completion The result of the attempt to update a document.
- (void)findOneAndUpdate:(id<RLMBSON>)filterDocument
          updateDocument:(id<RLMBSON>)updateDocument
                 options:(RLMFindOneAndModifyOptions *)options
              completion:(RLMFindOneBlock)completion;

/// Updates a single document in a collection based on a query filter and
/// returns the document in either its pre-update or post-update form. Unlike
/// `updateOneDocument`, this action allows you to atomically find, update, and
/// return a document with the same command. This avoids the risk of other
/// update operations changing the document between separate find and update
/// operations.
/// @param filterDocument  A bson `Document` representing the match criteria.
/// @param updateDocument  A bson `Document` representing the update to be applied to a matching document.
/// @param completion The result of the attempt to update a document.
- (void)findOneAndUpdate:(id<RLMBSON>)filterDocument
          updateDocument:(id<RLMBSON>)updateDocument
              completion:(RLMFindOneBlock)completion;

/// Overwrites a single document in a collection based on a query filter and
/// returns the document in either its pre-replacement or post-replacement
/// form. Unlike `updateOneDocument`, this action allows you to atomically find,
/// replace, and return a document with the same command. This avoids the
/// risk of other update operations changing the document between separate
/// find and update operations.
/// @param filterDocument  A `Document` that should match the query.
/// @param replacementDocument  A `Document` describing the update.
/// @param options Optional `RLMFindOneAndModifyOptions` to use when executing the command.
/// @param completion The result of the attempt to replace a document.
- (void)findOneAndReplace:(id<RLMBSON>)filterDocument
      replacementDocument:(id<RLMBSON>)replacementDocument
                  options:(RLMFindOneAndModifyOptions *)options
               completion:(RLMFindOneBlock)completion;

/// Overwrites a single document in a collection based on a query filter and
/// returns the document in either its pre-replacement or post-replacement
/// form. Unlike `updateOneDocument`, this action allows you to atomically find,
/// replace, and return a document with the same command. This avoids the
/// risk of other update operations changing the document between separate
/// find and update operations.
/// @param filterDocument  A `Document` that should match the query.
/// @param replacementDocument  A `Document` describing the update.
/// @param completion The result of the attempt to replace a document.
- (void)findOneAndReplace:(id<RLMBSON>)filterDocument
      replacementDocument:(id<RLMBSON>)replacementDocument
               completion:(RLMFindOneBlock)completion;

/// Removes a single document from a collection based on a query filter and
/// returns a document with the same form as the document immediately before
/// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
/// find and delete a document with the same command. This avoids the risk of
/// other update operations changing the document between separate find and
/// delete operations.
/// @param filterDocument  A `Document` that should match the query.
/// @param options Optional `RLMFindOneAndModifyOptions` to use when executing the command.
/// @param completion The result of the attempt to delete a document.
- (void)findOneAndDelete:(id<RLMBSON>)filterDocument
                 options:(RLMFindOneAndModifyOptions *)options
              completion:(RLMDeleteBlock)completion;

/// Removes a single document from a collection based on a query filter and
/// returns a document with the same form as the document immediately before
/// it was deleted. Unlike `deleteOneDocument`, this action allows you to atomically
/// find and delete a document with the same command. This avoids the risk of
/// other update operations changing the document between separate find and
/// delete operations.
/// @param filterDocument  A `Document` that should match the query.
/// @param completion The result of the attempt to delete a document.
- (void)findOneAndDelete:(id<RLMBSON>)filterDocument
              completion:(RLMDeleteBlock)completion;

@end

NS_ASSUME_NONNULL_END
