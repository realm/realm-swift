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

#import "RLMSyncUtil_Private.h"

/**
 An enum describing all possible endpoints on the Realm Object Server.
 */
typedef NS_ENUM(NSUInteger, RLMServerEndpoint) {
    RLMServerEndpointAuth,
    RLMServerEndpointLogout,
    RLMServerEndpointAddCredential,
    RLMServerEndpointRemoveCredential,
};

/**
 A simple Realm Object Server network client that wraps `NSURLSession`.
 */
@interface RLMNetworkClient : NSObject

NS_ASSUME_NONNULL_BEGIN

+ (void)postRequestToEndpoint:(RLMServerEndpoint)endpoint
                       server:(NSURL *)serverURL
                         JSON:(NSDictionary *)jsonDictionary
                   completion:(RLMSyncCompletionBlock)completionBlock;

/**
 Post some JSON data to the authentication server, and asynchronously call a completion block with a JSON response
 and/or error.
 */
+ (void)postRequestToEndpoint:(RLMServerEndpoint)endpoint
                       server:(NSURL *)serverURL
                         JSON:(NSDictionary *)jsonDictionary
                      timeout:(NSTimeInterval)timeout
                   completion:(RLMSyncCompletionBlock)completionBlock;

NS_ASSUME_NONNULL_END

@end
