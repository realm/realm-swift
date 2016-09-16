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

#import "RLMSyncConfiguration.h"
#import "RLMSyncUtil_Private.h"

#include "sync_config.hpp"
#include "sync_metadata.hpp"

@class RLMSyncConfiguration;

@interface RLMSyncUser ()

NS_ASSUME_NONNULL_BEGIN

@property (nullable, nonatomic) RLMServerToken refreshToken;

/// Create a user based on a `SyncUserMetadata` object. This method does NOT register the user to the sync manager's
/// user store.
- (instancetype)initWithMetadata:(realm::SyncUserMetadata)metadata;

/**
 Register a Realm to a user.
 
 @param fileURL     The location of the file on disk where the local copy of the Realm will be saved.
 @param completion  An optional completion block.
 */
- (RLMSyncSession *)_registerSessionForBindingWithFileURL:(NSURL *)fileURL
                                               syncConfig:(RLMSyncConfiguration *)syncConfig
                                        standaloneSession:(BOOL)isStandalone
                                             onCompletion:(nullable RLMSyncBasicErrorReportingBlock)completion;

- (void)_invalidate;
- (void)_deregisterSessionWithRealmURL:(NSURL *)realmURL;

NS_ASSUME_NONNULL_END

@end
