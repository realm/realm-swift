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
#import "RLMApp.h"
#import "RLMBSON_Private.hpp"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"

#import "util/bson/bson.hpp"
#import "sync/sync_config.hpp"
#import "sync/sync_manager.hpp"

@implementation RLMRealmConfiguration (Sync)

#pragma mark - API

- (void)setSyncConfiguration:(RLMSyncConfiguration *)syncConfiguration {
    if (syncConfiguration == nil) {
        self.config.sync_config = nullptr;
        return;
    }
    if (self.config.should_compact_on_launch_function) {
        @throw RLMException(@"Cannot set `syncConfiguration` when `shouldCompactOnLaunch` is set.");
    }
    RLMUser *user = syncConfiguration.user;
    if (user.state == RLMUserStateRemoved) {
        @throw RLMException(@"Cannot set a sync configuration which has an errored-out user.");
    }

    NSAssert(user.identifier, @"Cannot call this method on a user that doesn't have an identifier.");
    self.config.in_memory = false;
    self.config.sync_config = std::make_shared<realm::SyncConfig>([syncConfiguration rawConfiguration]);
    self.config.schema_mode = realm::SchemaMode::Additive;

    if (syncConfiguration.customFileURL) {
        self.config.path = syncConfiguration.customFileURL.path.UTF8String;
    } else {
        self.config.path = [user pathForPartitionValue:self.config.sync_config->partition_value];
    }

    if (!self.config.encryption_key.empty()) {
        auto& sync_encryption_key = self.config.sync_config->realm_encryption_key;
        sync_encryption_key = std::array<char, 64>();
        std::copy_n(self.config.encryption_key.begin(), 64, sync_encryption_key->begin());
    }
}

- (RLMSyncConfiguration *)syncConfiguration {
    if (!self.config.sync_config) {
        return nil;
    }
    realm::SyncConfig& sync_config = *self.config.sync_config;
    return [[RLMSyncConfiguration alloc] initWithRawConfig:sync_config];
}

@end
