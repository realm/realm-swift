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

#import "RLMRealm.h"

#import "RLMSyncUtil.h"

@class RLMSyncUser;

NS_ASSUME_NONNULL_BEGIN

@interface RLMRealm (Sync)

/**
 Open a Realm on behalf of a Realm Sync user.
 
 @param user A `RLMSyncUser` object encapsulating information about the user and their credentials.
 @param completionBlock A block run once the login is complete, containing either an error or a session object.
 */
- (void)openForSyncUser:(RLMSyncUser *)user
           onCompletion:(RLMSyncLoginCompletionBlock)completionBlock;

/**
 Open a Realm on behalf of a Realm Sync user account, using username and password credentials.

 @param username The account's username, as a string.
 @param password The account's password, as a string.
 @param completionBlock A block run once the login is complete, containing either an error or a session object.
 */
- (void)openForUsername:(NSString *)username
               password:(NSString *)password
           onCompletion:(RLMSyncLoginCompletionBlock)completionBlock;

/**
 Open a Realm directly using a Realm Sync token.

 @param token A Realm Sync token; this is usually a token shipped with the application.
 */
- (void)openWithSyncToken:(RLMSyncToken)token;

@end

NS_ASSUME_NONNULL_END
