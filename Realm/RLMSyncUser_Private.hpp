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

#include "sync/sync_config.hpp"
#include "sync/impl/sync_metadata.hpp"

@class RLMSyncConfiguration;

using namespace realm;

typedef void(^RLMFetchedRealmCompletionBlock)(NSError * _Nullable, RLMRealm * _Nullable, BOOL * _Nonnull);

NS_ASSUME_NONNULL_BEGIN

@interface RLMSyncUser ()

- (void)_bindSessionWithPath:(const std::string&)path
                      config:(const SyncConfig&)config
                     session:(std::shared_ptr<SyncSession>)session
                  completion:(nullable RLMSyncBasicErrorReportingBlock)completion
                isStandalone:(BOOL)standalone;

- (instancetype)initWithSyncUser:(std::shared_ptr<SyncUser>)user;
- (std::shared_ptr<SyncUser>)_syncUser;
- (nullable NSString *)_refreshToken;

- (void)_unregisterRefreshHandleForURLPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
