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

@class RLMTokenDataModel;

@interface RLMTokenModel : NSObject RLM_SYNC_UNINITIALIZABLE

@property (nonatomic, readonly) NSString *token;
@property (nonatomic, nullable, readonly) NSString *path;
@property (nonatomic, readonly) RLMTokenDataModel *tokenData;

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary;

@end

@interface RLMTokenDataModel : NSObject RLM_SYNC_UNINITIALIZABLE

@property (nonatomic, readonly) NSString *identity;
@property (nonatomic, nullable, readonly) NSString *appID;
@property (nonatomic, nullable, readonly) NSString *path;
@property (nonatomic, readonly) NSTimeInterval expires;
@property (nonatomic, readonly) BOOL isAdmin;
//@property (nonatomic, readonly) NSArray *access;

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary;

@end

NS_ASSUME_NONNULL_END
