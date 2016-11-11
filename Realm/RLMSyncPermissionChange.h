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
#import <Realm/RLMObject.h>
#import <Realm/RLMProperty.h>

@class RLMSyncUser;

typedef NS_ENUM(NSUInteger, RLMSyncManagementObjectStatus) {
    RLMSyncManagementObjectStatusNotProcessed,
    RLMSyncManagementObjectStatusSuccess,
    RLMSyncManagementObjectStatusError,
};

NS_ASSUME_NONNULL_BEGIN

@interface RLMSyncPermissionChange : RLMObject

/**
 The unique ID string of a Permission Object.
 */
@property (readonly) NSString *id;

/**
 Creation date.
 */
@property (readonly) NSDate *createdAt;

/**
 Modification date.
 */
@property (readonly) NSDate *updatedAt;

/**
 The status code of the object that was processed by Realm Object Server.
 */
@property (nullable, readonly) NSNumber<RLMInt> *statusCode;

/**
 Error message.
 */
@property (nullable, readonly) NSString *statusMessage;

/**
 Sync management object status.
 */
@property (readonly) RLMSyncManagementObjectStatus status;

/**
 the URL to the realm
 */
@property (readonly) NSString *realmUrl;

/**
 the identity of a user
 */
@property (readonly) NSString *userId;

@property (nullable, readonly) NSNumber<RLMBool> *mayRead;
@property (nullable, readonly) NSNumber<RLMBool> *mayWrite;
@property (nullable, readonly) NSNumber<RLMBool> *mayManage;

+ (instancetype)permissionChangeForRealm:(nullable RLMRealm *)realm
                                 forUser:(nullable RLMSyncUser *)user
                                    read:(nullable NSNumber<RLMBool> *)mayRead
                                   write:(nullable NSNumber<RLMBool> *)mayWrite
                                  manage:(nullable NSNumber<RLMBool> *)mayManage;

@end

NS_ASSUME_NONNULL_END
