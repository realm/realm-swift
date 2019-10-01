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

@interface RLMNetworkRequestOptions : NSObject
@property (nonatomic, copy, nullable) NSString *authorizationHeaderName;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *customHeaders;
@property (nullable, nonatomic, copy) NSDictionary<NSString *, NSURL *> *pinnedCertificatePaths;
@end

/// An abstract class representing a server endpoint.
@interface RLMSyncServerEndpoint : NSObject RLM_SYNC_UNINITIALIZABLE
+ (void)sendRequestToServer:(NSURL *)serverURL
                       JSON:(NSDictionary *)jsonDictionary
                 completion:(void (^)(NSError *))completionBlock;

+ (void)sendRequestToServer:(NSURL *)serverURL
                       JSON:(NSDictionary *)jsonDictionary
                    timeout:(NSTimeInterval)timeout
                 completion:(void (^)(NSError *, NSDictionary *))completionBlock;
@end

@interface RLMSyncAuthEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
@end
@interface RLMSyncChangePasswordEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
@end
@interface RLMSyncUpdateAccountEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
@end
@interface RLMSyncGetUserInfoEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
@end

@interface RLMSyncGetPermissionsEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
@end
@interface RLMSyncGetPermissionOffersEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
@end
@interface RLMSyncApplyPermissionsEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
@end
@interface RLMSyncOfferPermissionsEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
@end
@interface RLMSyncAcceptPermissionOfferEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
@end
@interface RLMSyncInvalidatePermissionOfferEndpoint : RLMSyncServerEndpoint RLM_SYNC_UNINITIALIZABLE
@end

NS_ASSUME_NONNULL_END
