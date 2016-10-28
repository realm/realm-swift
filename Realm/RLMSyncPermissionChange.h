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

#import "RLMSyncPermissionBaseObject.h"

@class RLMSyncUser;

NS_ASSUME_NONNULL_BEGIN

@interface PermissionChange : RLMSyncPermissionBaseObject

/**
 the URL to the realm
 */
@property NSString *realmUrl;

/**
 the identity of a user
 */
@property NSString *userId;

@property (nullable) NSNumber<RLMBool> *mayRead;
@property (nullable) NSNumber<RLMBool> *mayWrite;
@property (nullable) NSNumber<RLMBool> *mayManage;

+ (instancetype)permissionChangeForRealm:(nullable RLMRealm *)realm
                                 forUser:(nullable RLMSyncUser *)user
                                    read:(nullable NSNumber<RLMBool> *)mayRead
                                   write:(nullable NSNumber<RLMBool> *)mayWrite
                                  manage:(nullable NSNumber<RLMBool> *)mayManage;

@end

NS_ASSUME_NONNULL_END

@compatibility_alias RLMSyncPermissionChange PermissionChange;
