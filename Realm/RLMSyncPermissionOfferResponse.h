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

#import <Realm/Realm.h>
#import <Realm/RLMSyncUtil.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This model is used for responsing permissions by a received token,
 which was created by another user based on a RLMSyncPermissionOffer.
 
 It should be used in conjunction with an `SyncUser`'s management Realm.

 See https://realm.io/docs/realm-object-server/#permissions for general
 documentation.
 */
@interface RLMSyncPermissionOfferResponse : RLMObject

/// The globally unique ID string of this permission change object.
@property (readonly) NSString *id;

/// The date this object was initially created.
@property (readonly) NSDate *createdAt;

/// The date this object was last modified.
@property (readonly) NSDate *updatedAt;

/// The status code of the object that was processed by Realm Object Server.
@property (nullable, readonly) NSNumber<RLMInt> *statusCode;

/// An error or informational message, typically written to by the Realm Object Server.
@property (nullable, readonly) NSString *statusMessage;

/// Sync management object status.
@property (readonly) RLMSyncManagementObjectStatus status;

/// The received token, which was created by another user
/// based on a RLMSyncPermissionOffer.
@property (readonly) NSString *token;

/// The URL to the Realm for which the token granted permissions.
/// Is is filled by server.
@property (nullable, readonly) NSString *realmUrl;

/**
 Construct a permission offer response object used to response permissions by a received token,
 which was created by another user based on a RLMSyncPermissionOffer.

 @param token The received token.
 */
+ (instancetype)permissionOfferResponseWithToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
