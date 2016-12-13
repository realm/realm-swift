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

/**
 An internal class representing a valid JSON response to an auth request.
 
 ```
 {
     "access_token": { ... } // (optional),
     "refresh_token": { ... } // (optional)
 }
 ```
 */
@class RLMTokenModel;

NS_ASSUME_NONNULL_BEGIN

@interface RLMAuthResponseModel : NSObject

@property (nonatomic, readonly, nullable) RLMTokenModel *accessToken;
@property (nonatomic, readonly, nullable) RLMTokenModel *refreshToken;

- (instancetype)initWithDictionary:(NSDictionary *)jsonDictionary
                requireAccessToken:(BOOL)requireAccessToken
               requireRefreshToken:(BOOL)requireRefreshToken;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMTokenModel cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMTokenModel cannot be created directly")));

@end

NS_ASSUME_NONNULL_END
