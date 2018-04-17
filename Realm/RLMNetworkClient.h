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

NS_ASSUME_NONNULL_BEGIN

/// An abstract class representing a server endpoint.
@interface RLMSyncServerEndpoint : NSObject RLM_SYNC_UNINITIALIZABLE
@end

/// The authentication endpoint.
@interface RLMSyncAuthEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
+ (instancetype)endpoint;
@end

/// The password change endpoint.
@interface RLMSyncChangePasswordEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
+ (instancetype)endpoint;
@end

/// The get user info endpoint.
@interface RLMSyncGetUserInfoEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
+ (instancetype)endpoint;
@end

@interface RLMNetworkRequestOptions : NSObject

@property (nonatomic, copy, nullable) NSString *authorizationHeaderName;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *customHeaders;

@end

/**
 A simple Realm Object Server network client that wraps `NSURLSession`.
 */
@interface RLMNetworkClient : NSObject

+ (void)sendRequestToEndpoint:(RLMSyncServerEndpoint *)endpoint
                       server:(NSURL *)serverURL
                         JSON:(NSDictionary *)jsonDictionary
                      timeout:(NSTimeInterval)timeout
                      options:(nullable RLMNetworkRequestOptions *)options
                   completion:(RLMSyncCompletionBlock)completionBlock;

NS_ASSUME_NONNULL_END

@end
