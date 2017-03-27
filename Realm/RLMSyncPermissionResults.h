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

#import "RLMSyncUser.h"
#import "RLMRealm.h"

@class RLMSyncPermissionValue;

/**
 A token returned when adding a notification block to a permission results object.

 Hold on to the token for as long as notifications are desired. Call `-stop` on
 the token to stop notifications. Also call `-stop` before deallocating the token.
 */
@interface RLMSyncPermissionResultsToken : RLMNotificationToken
@end

/**
 An object representing the results of a permissions query.

 Permissions results objects are thread-confined, and should not be shared across
 threads.
 */
@interface RLMSyncPermissionResults : NSObject

/// The number of results contained within the object.
@property (nonatomic, readonly) NSInteger count;

/**
 Retrieve the permission value at the given index. Throws an exception if the index
 is out of bounds.
 */
- (RLMSyncPermissionValue *)permissionAtIndex:(NSInteger)index;

/**
 Register a notification block upon the results object. The block will be called
 whenever the contents of the results object changes.

 This method returns a token. Hold on to the token for as long as notifications
 are desired. Call `-stop` on the token to stop notifications, and before
 deallocating the token.

 @see `RLMSyncPermissionResultsToken`
 */
- (RLMSyncPermissionResultsToken *)addNotificationBlock:(RLMPermissionStatusBlock)block;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMSyncPermissionResults cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMSyncPermissionResults cannot be created directly")));

@end
