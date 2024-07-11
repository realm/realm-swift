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

#import "RLMSyncConfiguration_Private.hpp"

#import <Realm/RLMInitialSubscriptionsConfiguration.h>

#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMError_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration_Private.h"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealmUtil.hpp"
#import "RLMSchema_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncSession_Private.hpp"
#import "RLMSyncSubscription.h"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/impl/realm_coordinator.hpp>
#import <realm/object-store/sync/app_user.hpp>
#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/sync/sync_session.hpp>
#import <realm/object-store/thread_safe_reference.hpp>
#import <realm/sync/config.hpp>
#import <realm/sync/protocol.hpp>

using namespace realm;

namespace {
using ProtocolError = realm::sync::ProtocolError;

struct CallbackSchema {
    bool dynamic;
    RLMSchema *customSchema;
};

struct BeforeClientResetWrapper : CallbackSchema {
    RLMClientResetBeforeBlock block;
    void operator()(std::shared_ptr<Realm> local) {
        @autoreleasepool {
            if (local->schema_version() != RLMNotVersioned) {
                block([RLMRealm realmWithSharedRealm:local schema:customSchema dynamic:dynamic freeze:true]);
            }
        }
    }
};

struct AfterClientResetWrapper : CallbackSchema {
    RLMClientResetAfterBlock block;
    void operator()(std::shared_ptr<Realm> local, ThreadSafeReference remote, bool) {
        @autoreleasepool {
            if (local->schema_version() == RLMNotVersioned) {
                return;
            }

            RLMRealm *localRealm = [RLMRealm realmWithSharedRealm:local
                                                           schema:customSchema
                                                          dynamic:dynamic
                                                           freeze:true];
            RLMRealm *remoteRealm = [RLMRealm realmWithSharedRealm:Realm::get_shared_realm(std::move(remote))
                                                            schema:customSchema
                                                           dynamic:dynamic
                                                            freeze:false];
            block(localRealm, remoteRealm);
        }
    }
};

struct InitialSubscriptionsWrapper : CallbackSchema {
    RLMFlexibleSyncInitialSubscriptionsBlock block;
    void operator()(std::shared_ptr<Realm> local) {
        @autoreleasepool {
            RLMRealm *realm = [RLMRealm realmWithSharedRealm:local
                                                      schema:customSchema
                                                     dynamic:dynamic
                                                      freeze:false];

            RLMSyncSubscriptionSet* subscriptions = realm.subscriptions;
            [subscriptions update:^{
                block(subscriptions);
            }];
        }
    }
};
} // anonymous namespace

@interface RLMSyncConfiguration () {
    std::unique_ptr<realm::SyncConfig> _config;
    RLMSyncErrorReportingBlock _manualClientResetHandler;
}

@end

@implementation RLMSyncConfiguration

@dynamic stopPolicy;

- (instancetype)initWithRawConfig:(realm::SyncConfig)config path:(std::string const&)path {
    if (self = [super init]) {
        _config = std::make_unique<realm::SyncConfig>(std::move(config));
        _path = path;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[RLMSyncConfiguration class]]) {
        return NO;
    }
    RLMSyncConfiguration *that = (RLMSyncConfiguration *)object;
    return [self.partitionValue isEqual:that.partitionValue]
        && [self.user isEqual:that.user]
        && self.stopPolicy == that.stopPolicy;
}

- (realm::SyncConfig&)rawConfiguration {
    return *_config;
}

- (RLMUser *)user {
    return [[RLMUser alloc] initWithUser:_config->user];
}

- (RLMSyncStopPolicy)stopPolicy {
    return translateStopPolicy(_config->stop_policy);
}

- (void)setStopPolicy:(RLMSyncStopPolicy)stopPolicy {
    _config->stop_policy = translateStopPolicy(stopPolicy);
}

- (RLMClientResetMode)clientResetMode {
    return RLMClientResetMode(_config->client_resync_mode);
}

- (void)setClientResetMode:(RLMClientResetMode)clientResetMode {
    _config->client_resync_mode = realm::ClientResyncMode(clientResetMode);
}

- (RLMClientResetBeforeBlock)beforeClientReset {
    if (_config->notify_before_client_reset) {
        auto wrapper = _config->notify_before_client_reset.target<BeforeClientResetWrapper>();
        return wrapper->block;
    } else {
        return nil;
    }
}

- (void)setBeforeClientReset:(RLMClientResetBeforeBlock)beforeClientReset {
    if (!beforeClientReset) {
        _config->notify_before_client_reset = nullptr;
    } else if (self.clientResetMode == RLMClientResetModeManual) {
        @throw RLMException(@"RLMClientResetBeforeBlock reset notifications are not supported in Manual mode. Use RLMSyncConfiguration.manualClientResetHandler or RLMSyncManager.ErrorHandler");
    } else {
        _config->freeze_before_reset_realm = false;
        _config->notify_before_client_reset = BeforeClientResetWrapper{.block = beforeClientReset};
    }
}

- (RLMClientResetAfterBlock)afterClientReset {
    if (_config->notify_after_client_reset) {
        auto wrapper = _config->notify_after_client_reset.target<AfterClientResetWrapper>();
        return wrapper->block;
    } else {
        return nil;
    }
}

- (void)setAfterClientReset:(RLMClientResetAfterBlock)afterClientReset {
    if (!afterClientReset) {
        _config->notify_after_client_reset = nullptr;
    } else if (self.clientResetMode == RLMClientResetModeManual) {
        @throw RLMException(@"RLMClientResetAfterBlock reset notifications are not supported in Manual mode. Use RLMSyncConfiguration.manualClientResetHandler or RLMSyncManager.ErrorHandler");
    } else {
        _config->notify_after_client_reset = AfterClientResetWrapper{.block = afterClientReset};
    }
}

- (RLMSyncErrorReportingBlock)manualClientResetHandler {
    return _manualClientResetHandler;
}

- (void)setManualClientResetHandler:(RLMSyncErrorReportingBlock)manualClientReset {
    if (!manualClientReset) {
        _manualClientResetHandler = nil;
    } else if (self.clientResetMode != RLMClientResetModeManual) {
        @throw RLMException(@"A manual client reset handler can only be set with RLMClientResetModeManual");
    } else {
        _manualClientResetHandler = manualClientReset;
    }
    [self assignConfigErrorHandler:self.user];
}

- (RLMInitialSubscriptionsConfiguration *)initialSubscriptions {
    if (_config->subscription_initializer) {
        auto wrapper = _config->subscription_initializer.target<InitialSubscriptionsWrapper>();

        return [[RLMInitialSubscriptionsConfiguration alloc] initWithCallback:wrapper->block
                                                                  rerunOnOpen:_config->rerun_init_subscription_on_open];
    }

    return nil;
}

- (void)setInitialSubscriptions:(RLMInitialSubscriptionsConfiguration *)initialSubscriptions {
    if (initialSubscriptions) {
        _config->subscription_initializer = InitialSubscriptionsWrapper{.block = initialSubscriptions.callback};
        _config->rerun_init_subscription_on_open = initialSubscriptions.rerunOnOpen;
    } else {
        _config->subscription_initializer = nil;
    }
}

void RLMSetConfigInfoForClientResetCallbacks(realm::SyncConfig& syncConfig, RLMRealmConfiguration *config) {
    if (syncConfig.notify_before_client_reset) {
        auto before = syncConfig.notify_before_client_reset.target<BeforeClientResetWrapper>();
        before->dynamic = config.dynamic;
        before->customSchema = config.customSchema;
    }
    if (syncConfig.notify_after_client_reset) {
        auto after = syncConfig.notify_after_client_reset.target<AfterClientResetWrapper>();
        after->dynamic = config.dynamic;
        after->customSchema = config.customSchema;
    }
    if (syncConfig.subscription_initializer) {
        auto initializer = syncConfig.subscription_initializer.target<InitialSubscriptionsWrapper>();
        initializer->dynamic = config.dynamic;
        initializer->customSchema = config.customSchema;
    }
}

- (id<RLMBSON>)partitionValue {
    if (!_config->partition_value.empty()) {
        return RLMConvertBsonToRLMBSON(realm::bson::parse(_config->partition_value));
    }
    return nil;
}

- (bool)cancelAsyncOpenOnNonFatalErrors {
    return _config->cancel_waits_on_nonfatal_error;
}

- (void)setCancelAsyncOpenOnNonFatalErrors:(bool)cancelAsyncOpenOnNonFatalErrors {
    _config->cancel_waits_on_nonfatal_error = cancelAsyncOpenOnNonFatalErrors;
}

- (void)assignConfigErrorHandler:(RLMUser *)user {
    RLMSyncManager *manager = user.app.syncManager;
    __weak RLMSyncManager *weakManager = manager;
    RLMSyncErrorReportingBlock resetHandler = self.manualClientResetHandler;
    _config->error_handler = [weakManager, resetHandler](std::shared_ptr<SyncSession> errored_session, SyncError error) {
        RLMSyncErrorReportingBlock errorHandler;
        if (error.is_client_reset_requested()) {
            errorHandler = resetHandler;
        }
        if (!errorHandler) {
            @autoreleasepool {
                errorHandler = weakManager.errorHandler;
            }
        }
        if (!errorHandler) {
            return;
        }
        NSError *nsError = makeError(std::move(error),
                                     static_cast<app::User*>(errored_session->user().get())->app());
        if (!nsError) {
            return;
        }
        RLMSyncSession *session = [[RLMSyncSession alloc] initWithSyncSession:errored_session];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Keep the SyncSession alive until the callback completes as
            // RLMSyncSession only holds a weak reference
            static_cast<void>(errored_session);
            errorHandler(nsError, session);
        });
    };
};

static void setDefaults(SyncConfig& config, RLMUser *user) {
    config.client_resync_mode = ClientResyncMode::Recover;
    config.stop_policy = SyncSessionStopPolicy::AfterChangesUploaded;
    [user.app.syncManager populateConfig:config];
}

- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(nullable id<RLMBSON>)partitionValue {
    if (self = [super init]) {
        std::stringstream s;
        s << RLMConvertRLMBSONToBson(partitionValue);
        _config = std::make_unique<SyncConfig>(user.user, s.str());
        _path = [user pathForPartitionValue:_config->partition_value];
        setDefaults(*_config, user);
        [self assignConfigErrorHandler:user];
    }
    return self;
}

- (instancetype)initWithUser:(RLMUser *)user {
    if (self = [super init]) {
        _config = std::make_unique<SyncConfig>(user.user, SyncConfig::FLXSyncEnabled{});
        _path = [user pathForFlexibleSync];
        setDefaults(*_config, user);
        [self assignConfigErrorHandler:user];
    }
    return self;
}

@end
