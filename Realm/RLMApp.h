////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

@class RLMSyncCredentials, RLMSyncUser, RLMRealmConfiguration;

@interface RLMPushSendMessageRequest
@end

@interface RLMPushSendMessageResult
@end

/// A block type used to asynchronously report results of a remote function call.
/// Data is returned raw as function results are of arbitrary shape.
typedef void(^RLMFunctionCompletionBlock)(NSData * _Nullable, NSError * _Nullable);

/// A block type used for auth APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

/// A block type used for push APIs which asynchronously vend an `RLMPushSendMessageResult`.
typedef void(^RLMPushCompletionBlock)(RLMPushSendMessageResult * _Nullable, NSError * _Nullable);

#pragma mark RLMServices

@interface RLMTwilioService


@end

#pragma mark RLMMongoDBService

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

#pragma mark RLMServices

@interface RLMServices : NSObject

-(RLMTwilioService *)twilio:(NSString *)serviceName;
-(RLMMongoDBService *)mongoDB;

@end

#pragma mark RLMPush

/**
 `RLMPush` allows a user to register or deregister for push notifications,
 and send push messages to other users.
 */
@interface RLMPush: NSObject

/**
 Register this device for push notifications.

 - parameter token: the registration token to be registered for push
 */
- (void)register:(NSString *)token;

/**
 Deregister this device for push notifications.
 */
- (void)deregister;

/**
 Send a push message to a given target.
 */
- (void)sendMessage:(NSString *)target
            request:(id)request
       onCompletion:(RLMPushCompletionBlock)completion NS_REFINED_FOR_SWIFT;

@end

#pragma mark RLMFunctions

/**
 `RLMFunctions` allow a user to call any remote functions they have declared on the
 MongoDB Realm server.
 */
@interface RLMFunctions: NSObject

/**
 Calls the MongoDB Stitch function with the provided name and arguments, ignoring the result of the function.

 - parameter name: The name of the Stitch function to be called.
 - parameter arguments: The `BSONArray` of arguments to be provided to the function.
 - parameter timeout: The timeout for this request.
 - parameter callbackQueue: The dispatch queue to run the function call on.
 - parameter onCompletion: The completion handler to call when the function call is complete.
 This handler is executed on a non-main global `DispatchQueue`.
 */
- (void)callFunction:(NSString *)name
           arguments:(NSArray *)arguments
             timeout:(NSTimeInterval)timeout
       callbackQueue:(dispatch_queue_t)callbackQueue
        onCompletion:(RLMFunctionCompletionBlock)completion NS_REFINED_FOR_SWIFT;

@end

#pragma mark RLMAuth

/**
 `RLMAuth` acts as an authentication manager for a given `RLMApp`.
 */
@interface RLMAuth: NSObject

/// All logged in users for an application
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, RLMSyncUser *>* allUsers;
/// The currently active user for an application
@property (nonatomic, readonly, nullable) RLMSyncUser *currentUser;

/**
 Log in a user and asynchronously retrieve a user object.

 If the log in completes successfully, the completion block will be called, and a
 `SyncUser` representing the logged-in user will be passed to it. This user object
 can be used to open `Realm`s and retrieve `SyncSession`s. Otherwise, the
 completion block will be called with an error.

 - parameter credentials: A `SyncCredentials` object representing the user to log in.
 - parameter timeout: How long the network client should wait, in seconds, before timing out.
 - parameter callbackQueue: The dispatch queue upon which the callback should run. Defaults to the main queue.
 - parameter completion: A callback block to be invoked once the log in completes.
 */
- (void)logInWithCredentials:(RLMSyncCredentials *)credentials
                     timeout:(NSTimeInterval)timeout
               callbackQueue:(dispatch_queue_t)callbackQueue
                onCompletion:(RLMUserCompletionBlock)completion NS_REFINED_FOR_SWIFT;

- (void)switchUser:(NSString *)userId;

@end

#pragma mark RLMApp

/**
 The `RLMApp` has the fundamental set of methods for communicating with a MongoDB
 Realm application backend.

 This protocol provides access to the `RLMAuth` for login and authentication.

 Using `serviceClient`, you can retrieve services, including the `RemoteMongoClient` for reading
 and writing on the database. To create a `RemoteMongoClient`, pass `remoteMongoClientFactory`
 into `serviceClient(fromFactory:withName)`.

 You can also use it to execute [Functions](https://docs.mongodb.com/stitch/functions/).

 Finally, its `RLMPush` object can register the current user for push notifications.

 - SeeAlso:
 `RLMAuth`,
 `RemoteMongoClient`,
 `RLMPush`,
 [Functions](https://docs.mongodb.com/stitch/functions/)
 */
@interface RLMApp<Functions: RLMFunctions*> : NSObject

/// All applications registered on this device
@property (class, nonatomic, readonly) NSDictionary<NSString*, RLMApp*> *allApps;

@property (nonatomic, readonly) RLMAuth *auth;
@property (nonatomic, readonly) Functions functions;
@property (nonatomic, readonly) RLMPush *push;

+ (instancetype)app:(NSString *)appID;

- (RLMRealmConfiguration *) configuration NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
