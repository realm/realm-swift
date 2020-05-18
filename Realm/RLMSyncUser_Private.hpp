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

#import "sync/sync_config.hpp"
#import "sync/sync_user.hpp"
#import "sync/impl/sync_metadata.hpp"

@class RLMSyncConfiguration, RLMSyncSessionRefreshHandle;

using namespace realm;

typedef void(^RLMFetchedRealmCompletionBlock)(NSError * _Nullable, RLMRealm * _Nullable, BOOL * _Nonnull);

NS_ASSUME_NONNULL_BEGIN

class CocoaSyncUserContext : public SyncUserContext {
public:

private:
    /**
     A map of paths to 'refresh handles'.

     A refresh handle is an object that encapsulates the concept of periodically
     refreshing the Realm's access token before it expires. Tokens are indexed by their
     paths (e.g. `/~/path/to/realm`).
     */
    std::unordered_map<std::string, RLMSyncSessionRefreshHandle *> m_refresh_handles;
    std::mutex m_mutex;
};

@interface RLMSyncUser ()
- (instancetype)initWithSyncUser:(std::shared_ptr<SyncUser>)user app:(RLMApp *)app;
- (NSString *)pathForPartitionValue:(id<RLMBSON>)partitionValue;
- (std::shared_ptr<SyncUser>)_syncUser;
+ (void)_setUpBindingContextFactory;
@property (weak, readonly) RLMApp* app;

@end

NS_ASSUME_NONNULL_END
