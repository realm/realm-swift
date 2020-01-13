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

/// A block type used to asynchronously report results of a remote function call.
/// Data is returned raw as function results are of arbitrary shape.
typedef void(^RLMFunctionCompletionBlock)(NSData * _Nullable, NSError * _Nullable);

/// A block type used for APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

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

@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, RLMSyncUser *>* allUsers;
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

@property (class, nonatomic, readonly) NSDictionary<NSString*, RLMApp*> *allApps;

@property (nonatomic, readonly) RLMAuth *auth;
@property (nonatomic, readonly) Functions functions;

+ (instancetype)app:(NSString *)appID;

- (RLMRealmConfiguration *) configuration NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
