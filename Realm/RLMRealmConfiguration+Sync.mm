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

#import "RLMBSON_Private.hpp"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/util/bson/bson.hpp>
#import <realm/sync/config.hpp>

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

    if (syncConfiguration.customFileURL) {
        self.config.path = syncConfiguration.customFileURL.path.UTF8String;
    } else if (syncConfiguration.isFlexibleSync) {
        // TODO: Review this, it is the best way to identify if the configuration is flx
        std::string str = std::string([@"default" UTF8String]);
        self.config.path = [user pathForValue:str];
    } else {
        self.config.path = [user pathForValue:self.config.sync_config->partition_value];
    }

    [self updateSchemaMode];
}

- (RLMSyncConfiguration *)syncConfiguration {
    if (!self.config.sync_config) {
        return nil;
    }
    realm::SyncConfig& sync_config = *self.config.sync_config;
    // TODO: Fix this to not be dependable on the path to be a condition to be flexible sync, 
    RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithRawConfig:sync_config];
    NSString *path = [NSString stringWithCString:self.config.path.c_str()
                              encoding:[NSString defaultCStringEncoding]];
    if ([path hasSuffix:@"default.realm"]) {
        syncConfig.isFlexibleSync = true;
    }
    return syncConfig;
}

@end
