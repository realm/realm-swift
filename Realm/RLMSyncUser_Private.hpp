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
    void register_refresh_handle(const std::string& path, RLMSyncSessionRefreshHandle *handle);
    void unregister_refresh_handle(const std::string& path);
    void invalidate_all_handles();

    RLMUserErrorReportingBlock error_handler() const;
    void set_error_handler(RLMUserErrorReportingBlock);

private:
    /**
     A map of paths to 'refresh handles'.

     A refresh handle is an object that encapsulates the concept of periodically
     refreshing the Realm's access token before it expires. Tokens are indexed by their
     paths (e.g. `/~/path/to/realm`).
     */
    std::unordered_map<std::string, RLMSyncSessionRefreshHandle *> m_refresh_handles;
    std::mutex m_mutex;

    /**
     An optional callback invoked when the authentication server reports the user as
     being in an expired state.
     */
    RLMUserErrorReportingBlock m_error_handler;
    mutable std::mutex m_error_handler_mutex;
};

@interface RLMSyncUser ()
- (instancetype)initWithSyncUser:(std::shared_ptr<SyncUser>)user;
- (NSURL *)defaultRealmURL;
- (std::shared_ptr<SyncUser>)_syncUser;
- (nullable NSString *)_refreshToken;
+ (void)_setUpBindingContextFactory;
@end

using PermissionChangeCallback = std::function<void(std::exception_ptr)>;

PermissionChangeCallback RLMWrapPermissionStatusCallback(RLMPermissionStatusBlock callback);

NS_ASSUME_NONNULL_END
