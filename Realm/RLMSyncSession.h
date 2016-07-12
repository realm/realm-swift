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
#import "RLMSyncUtil.h"

/**
 A `RLMSyncSession` instance is an opaque object representing a single user's Realm Sync session on the device for a
 single Realm Sync server and one (or more) synchronized Realms.
 */
@interface RLMSyncSession : NSObject

NS_ASSUME_NONNULL_BEGIN

/**
 The unique Realm Sync account identifier attached to the user this session belongs to.
 */
@property (nonatomic, readonly) RLMSyncAccountID account;

/**
 The host of the URL of the server that the remote Realm resides upon.
 */
@property (nonatomic, readonly) NSString *host;

// TODO: support multiple paths?
/**
 The local path of the Realm linked to this session.
 */
@property (nonatomic, readonly) RLMSyncRealmPath path;

@property (nonatomic, readonly) NSString *remoteURL;
@property (nonatomic, readonly) NSString *realmID;

/**
 Whether this session object is still valid.
 */
@property (nonatomic, readonly) BOOL valid;

/**
 Validate and refresh a session.
 */
- (void)refreshSessionWithError:(NSError **)error completion:(nullable RLMSyncCompletionBlock)completionBlock;

/**
 Destroy a session, logging a user out of their session for the linked Realm on this device.
 */
- (void)destroySessionWithError:(NSError **)error completion:(RLMSyncCompletionBlock)completionBlock;

/**
 Attempt to add a new set of login credentials for a given user.
 */
- (void)addLoginForProvider:(RLMSyncIdentityProvider)provider
                 credential:(RLMSyncCredential)credential
                   userInfo:(nullable NSDictionary *)userInfo
                      error:(NSError **)error
               onCompletion:(RLMSyncCompletionBlock)completionBlock;

NS_ASSUME_NONNULL_END

@end
