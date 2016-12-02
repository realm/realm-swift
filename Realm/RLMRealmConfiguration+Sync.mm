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

#import "RLMRealmConfiguration+Sync.h"

#import "RLMRealmConfiguration_Private.hpp"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncUser_Private.hpp"
#import "RLMSyncManager_Private.h"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"

#import "sync/sync_config.hpp"
#import "sync/sync_manager.hpp"

@implementation RLMRealmConfiguration (Sync)

#pragma mark - API

- (void)setSyncConfiguration:(RLMSyncConfiguration *)syncConfiguration {
    RLMSyncUser *user = syncConfiguration.user;
    if (user.state == RLMSyncUserStateError) {
        @throw RLMException(@"Cannot set a sync configuration which has an errored-out user.");
    }
    self.config.in_memory = false;
    self.config.set_sync_config(std::make_shared<realm::SyncConfig>([syncConfiguration rawConfiguration]));
    self.config.schema_mode = realm::SchemaMode::Additive;
}

- (RLMSyncConfiguration *)syncConfiguration {
    if (!self.config.sync_config()) {
        return nil;
    }
    realm::SyncConfig& sync_config = *self.config.sync_config();
    return [[RLMSyncConfiguration alloc] initWithRawConfig:sync_config];
}

@end
