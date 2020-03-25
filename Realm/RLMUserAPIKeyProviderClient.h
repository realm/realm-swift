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
#import "RLMProviderClient.h"
#import "RLMUserAPIKey.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLMUserAPIKeyProviderClient : RLMProviderClient

//temp
typedef id RLMObjectId;

/// A block type used to report an error
typedef void(^RLMOptionalErrorBlock)(NSError * _Nullable);

typedef void(^RLMOptionalUserAPIKeyBlock)(RLMUserAPIKey * _Nullable, NSError * _Nullable);

typedef void(^RLMUserAPIKeysBlock)(NSArray<RLMUserAPIKey *> *  _Nonnull, NSError * _Nullable);

/**
  Creates a user API key that can be used to authenticate as the current user.
 
  @param name The name of the API key to be created.
  @param completionHandler A callback to be invoked once the call is complete.
*/
- (void)createApiKey:(NSString *)name
   completionHandler:(RLMOptionalUserAPIKeyBlock)completionHandler;

/**
  Fetches a user API key associated with the current user.
 
  @param objectId The ObjectId of the API key to fetch.
  @param completionHandler A callback to be invoked once the call is complete.
 */
- (void)fetchApiKey:(RLMObjectId)objectId
  completionHandler:(RLMOptionalUserAPIKeyBlock)completionHandler;

/**
  Fetches the user API keys associated with the current user.
 
  @param completionHandler A callback to be invoked once the call is complete.
 */
- (void)fetchApiKeys:(RLMUserAPIKeysBlock)completionHandler;

/**
  Deletes a user API key associated with the current user.
 
  @param apiKey The API key to delete.
  @param completionHandler A callback to be invoked once the call is complete.
 */
- (void)deleteApiKey:(RLMUserAPIKey *)apiKey
   completionHandler:(RLMOptionalErrorBlock)completionHandler;

/**
  Enables a user API key associated with the current user.
 
  @param apiKey The API key to enable.
  @param completionHandler A callback to be invoked once the call is complete.
 */
- (void)enableApiKey:(RLMUserAPIKey *)apiKey
   completionHandler:(RLMOptionalErrorBlock)completionHandler;

/**
  Disables a user API key associated with the current user.
 
  @param apiKey The API key to disable.
  @param completionHandler A callback to be invoked once the call is complete.
 */
- (void)disableApiKey:(RLMUserAPIKey *)apiKey
    completionHandler:(RLMOptionalErrorBlock)completionHandler;

@end

NS_ASSUME_NONNULL_END
