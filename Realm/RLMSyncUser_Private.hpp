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

#import "RLMSyncUser.h"

#import "RLMSyncUtil_Private.h"

#import "shared_realm.hpp"
#import "sync_metadata.hpp"

@interface RLMSyncUser ()

NS_ASSUME_NONNULL_BEGIN

@property (nullable, nonatomic) RLMServerToken refreshToken;

/// Create a user based on a `SyncUserMetadata` object. This method does NOT register the user to the sync manager's
/// user store.
- (instancetype)initWithMetadata:(realm::SyncUserMetadata)metadata;

/**
 Register a Realm to a user.
 
 @param fileURL     The location of the file on disk where the local copy of the Realm will be saved.
 @param realmURL    The fully qualified, unresolved URL of the remote Realm on the Realm Object Server.
 @param completion  An optional completion block.
 */
- (void)_registerRealmForBindingWithFileURL:(NSURL *)fileURL
                                   realmURL:(NSURL *)realmURL
                               onCompletion:(nullable RLMSyncBasicErrorReportingBlock)completion;

- (void)_invalidate;
- (void)_deregisterSessionWithRealmURL:(NSURL *)realmURL;

NS_ASSUME_NONNULL_END

@end
