////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

@class RLMTokenDataModel, RLMSyncUserAccountInfo;

#pragma mark - RLMTokenModel

@interface RLMTokenModel : NSObject RLM_SYNC_UNINITIALIZABLE

@property (nonatomic, readonly) NSString *token;
@property (nonatomic, nullable, readonly) NSString *path;
@property (nonatomic, readonly) RLMTokenDataModel *tokenData;

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary;

@end

#pragma mark - RLMTokenDataModel

@interface RLMTokenDataModel : NSObject RLM_SYNC_UNINITIALIZABLE

@property (nonatomic, readonly) NSString *identity;
@property (nonatomic, nullable, readonly) NSString *appID;
@property (nonatomic, nullable, readonly) NSString *path;
@property (nonatomic, readonly) NSTimeInterval expires;
@property (nonatomic, readonly) BOOL isAdmin;
//@property (nonatomic, readonly) NSArray *access;

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary;

@end

#pragma mark - RLMAuthResponseModel

/**
 An internal class representing a valid JSON response to an auth request.

 ```
 {
 "access_token": { ... } // (optional),
 "refresh_token": { ... } // (optional)
 }
 ```
 */
@interface RLMAuthResponseModel : NSObject RLM_SYNC_UNINITIALIZABLE

@property (nonatomic, readonly, nullable) RLMTokenModel *accessToken;
@property (nonatomic, readonly, nullable) RLMTokenModel *refreshToken;

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary
                requireAccessToken:(BOOL)requireAccessToken
               requireRefreshToken:(BOOL)requireRefreshToken;

@end

#pragma mark - RLMUserInfoResponseModel

@interface RLMUserResponseModel : NSObject RLM_SYNC_UNINITIALIZABLE

@property (nonatomic, readonly) NSString *identity;
@property (nonatomic, readonly) NSArray<RLMSyncUserAccountInfo *> *accounts;
@property (nonatomic, readonly) NSDictionary *metadata;
@property (nonatomic, readonly) BOOL isAdmin;

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary;

@end

#pragma mark - RLMSyncErrorResponseModel

@interface RLMSyncErrorResponseModel : NSObject RLM_SYNC_UNINITIALIZABLE

@property (nonatomic, readonly) NSInteger status;
@property (nonatomic, readonly) NSInteger code;
@property (nullable, nonatomic, readonly, copy) NSString *title;
@property (nullable, nonatomic, readonly, copy) NSString *hint;

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary;

@end

NS_ASSUME_NONNULL_END
