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

NS_ASSUME_NONNULL_BEGIN


@interface RLMMongoDBFindOptions


@end

@interface RLMMongoDBCountOptions


@end

@interface RLMMongoDBInsertOneResult

@end

@interface RLMMongoDBInsertManyResult

@end

@interface RLMMongoDBDeleteResult

@end

@interface RLMMongoDBUpdateResult

@end

/// A class to represent a MongoDB write concern.
@interface RLMMongoDBWriteConcern

@property(nonatomic, readonly) bool journal;
@property(nonatomic, readonly) NSInteger wtimeoutMS;
@property(nonatomic, readonly) bool isAcknowledged;
@property(nonatomic, readonly) bool isDefault;
@property(nonatomic, readonly) bool isValid;

@end

/// Options to use when executing an `update` command on an `RLMMongoDBCollection`.
@interface RLMMongoDBUpdateOptions

/// A set of filters specifying to which array elements an update should apply.
@property(nonatomic, readonly, nullable) NSArray<NSDictionary *> *arrayFilters;
/// If true, allows the write to opt-out of document level validation.
@property(nonatomic, readonly) bool bypassDocumentValidation;

/// Specifies a collation.
@property(nonatomic, readonly, nullable) NSDictionary *collation;

/// When true, creates a new document if no document matches the query.
@property(nonatomic, readonly) bool upsert;

/// An optional WriteConcern to use for the command.
//@property(nonatomic, readonly, nullable) WriteConcern? writeConcern;

@end

@interface RLMMongoDBCollection<ObjectType> : NSObject

/**
 Finds a document in this collection that matches the provided filter.

 - parameters:
   - filter: A `Document` that should match the query.
   - options: Optional `RemoteFindOptions` to use when executing the command.

 - returns: A the resulting `Document` or nil if no such document exists
*/
-(void)findOne:(NSDictionary *)filter
       options:(RLMMongoDBFindOptions *)options
  onCompletion:(void(^)(ObjectType, NSError *))completion;

/**
 Counts the number of documents in this collection matching the provided filter.

 - parameters:
   - filter: a `Document`, the filter that documents must match in order to be counted.
   - options: Optional `RemoteCountOptions` to use when executing the command.
   - completionHandler: The completion handler to call when the count is completed or if the operation fails.
                        This handler is executed on a non-main global `DispatchQueue`. If the operation is
                        successful, the result will contain the count of the documents that matched the filter.
*/
-(void)count:(NSDictionary *)filter
     options:(RLMMongoDBCountOptions *)options
onCompletion:(void(^)(NSInteger, NSError *))completion;

/**
 Encodes the provided value as BSON and inserts it. If the value is missing an identifier, one will be
 generated for it.

 - important: If the insert failed due to a request timeout, it does not necessarily indicate that the insert
              failed on the database. Application code should handle timeout errors with the assumption that the
              document may or may not have been inserted.

 - parameters:
   - value: A `CollectionType` value to encode and insert.
   - completionHandler: The completion handler to call when the insert is completed or if the operation fails.
                        This handler is executed on a non-main global `DispatchQueue`. If the operation is
                        successful, the result will contain the result of attempting to perform the insert, as
                        a `RemoteInsertOneResult`.
*/
-(void)insertOne:(ObjectType)value
    onCompletion:(void(^)(RLMMongoDBInsertOneResult *, NSError*))completion;

/**
 Encodes the provided values as BSON and inserts them. If any values are missing identifiers,
 they will be generated.

 - important: If the insert failed due to a request timeout, it does not necessarily indicate that the insert
              failed on the database. Application code should handle timeout errors with the assumption that
              documents may or may not have been inserted.

 - parameters:
   - documents: The `CollectionType` values to insert.
   - completionHandler: The completion handler to call when the insert is completed or if the operation fails.
                        This handler is executed on a non-main global `DispatchQueue`.
   - result: The result of attempting to perform the insert, or `nil` if the insert failed. If the operation is
                        successful, the result will contain the result of attempting to perform the insert, as
                        a `RemoteInsertManyResult`.
*/
-(void)insertMany:(NSArray<ObjectType>*)values
     onCompletion:(void(^)(RLMMongoDBInsertManyResult *, NSError*))completion;

/**
 Deletes a single matching document from the collection.

 - important: If the delete failed due to a request timeout, it does not necessarily indicate that the delete
              failed on the database. Application code should handle timeout errors with the assumption that
              a document may or may not have been deleted.

 - parameters:
   - filter: A `Document` representing the match criteria.
   - completionHandler: The completion handler to call when the delete is completed or if the operation fails.
                        This handler is executed on a non-main global `DispatchQueue`. If the operation is
                        successful, the result will contain the result of performing the deletion, as
                        a `RemoteDeleteResult`.
*/
-(void)deleteOne:(NSDictionary *)filter
    onCompletion:(void(^)(RLMMongoDBDeleteResult *, NSError *))completion;

/**
 Deletes multiple documents from the collection.

 - important: If the delete failed due to a request timeout, it does not necessarily indicate that the delete
              failed on the database. Application code should handle timeout errors with the assumption that
              documents may or may not have been deleted.

 - parameters:
   - filter: A `Document` representing the match criteria.
   - completionHandler: The completion handler to call when the delete is completed or if the operation fails.
                        This handler is executed on a non-main global `DispatchQueue`. If the operation is
                        successful, the result will contain the result of performing the deletion, as
                        a `RemoteDeleteResult`.
*/
-(void)deleteMany:(NSDictionary *)filter
     onCompletion:(void(^)(RLMMongoDBDeleteResult *, NSError *))completion;

/**
 Updates a single document matching the provided filter in this collection.

 - important: If the update failed due to a request timeout, it does not necessarily indicate that the update
              failed on the database. Application code should handle timeout errors with the assumption that
              a document may or may not have been updated.

 - parameters:
   - filter: A `Document` representing the match criteria.
   - update: A `Document` representing the update to be applied to a matching document.
   - options: Optional `RemoteUpdateOptions` to use when executing the command.
   - completionHandler: The completion handler to call when the update is completed or if the operation fails.
                        This handler is executed on a non-main global `DispatchQueue`. If the operation is
                        successful, the result will contain the result of attempting to update a document, as
                        a `RemoteUpdateResult`.
*/
-(void)updateOne:(NSDictionary *)filter
          update:(NSDictionary *)update
         options:(RLMMongoDBUpdateOptions *)options
    onCompletion:(void(^)(RLMMongoDBUpdateResult *, NSError *))completion;

/**
 Updates mutiple documents matching the provided filter in this collection.

 - important: If the update failed due to a request timeout, it does not necessarily indicate that the update
              failed on the database. Application code should handle timeout errors with the assumption that
              documents may or may not have been updated.

 - parameters:
   - filter: A `Document` representing the match criteria.
   - update: A `Document` representing the update to be applied to a matching document.
   - options: Optional `RemoteUpdateOptions` to use when executing the command.
   - completionHandler: The completion handler to call when the update is completed or if the operation fails.
                        This handler is executed on a non-main global `DispatchQueue`. If the operation is
                        successful, the result will contain the result of attempting to update multiple
                        documents, as a `RemoteUpdateResult`.
*/
-(void)updateMany:(NSDictionary *)filter
           update:(NSDictionary *)update
          options:(RLMMongoDBUpdateOptions *)options
     onCompletion:(void(^)(RLMMongoDBUpdateResult *, NSError *))completion;

@end

@interface RLMMongoDBDatabase : NSObject

-(RLMMongoDBCollection *)collection:(NSString *)name;

@end

@interface RLMMongoDBService : NSObject

-(RLMMongoDBDatabase *)database:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
