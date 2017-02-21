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

#import "RLMRealm+RLMSync.hpp"

#import "sync/sync_user.hpp"

#import "RLMSyncConfiguration_Private.hpp"

@implementation RLMRealm (RLMSync)

- (std::shared_ptr<SyncSession>)syncSession {
    if (RLMSyncConfiguration *syncConfig = self.configuration.syncConfiguration) {
        SyncConfig config = [syncConfig rawConfiguration];
        std::shared_ptr<SyncUser> user = config.user;
        if (user && user->state() != SyncUser::State::Error) {
            NSString *path = [self.configuration.fileURL absoluteString];
            REALM_ASSERT(path);
            return user->session_for_on_disk_path([path UTF8String]);
        }
    }
    return nullptr;
}

@end
