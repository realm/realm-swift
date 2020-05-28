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

#import "RLMSyncUser_Private.hpp"

#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMJSONModels.h"
#import "RLMNetworkTransport.h"
#import "RLMRealmConfiguration+Sync.h"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealmUtil.hpp"
#import "RLMResults_Private.hpp"
#import "RLMSyncConfiguration.h"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncSession_Private.hpp"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"

#import "util/bson/bson.hpp"
#import "sync/sync_manager.hpp"
#import "sync/sync_session.hpp"
#import "sync/sync_user.hpp"

using namespace realm;

@interface RLMSyncUserInfo ()

@property (nonatomic, readwrite) NSArray *accounts;
@property (nonatomic, readwrite) NSDictionary *metadata;
@property (nonatomic, readwrite) NSString *identity;
@property (nonatomic, readwrite) BOOL isAdmin;

+ (instancetype)syncUserInfoWithModel:(RLMUserResponseModel *)model;

@end

@interface RLMSyncUser () {
    std::shared_ptr<SyncUser> _user;
}
@end

@implementation RLMSyncUser

#pragma mark - API

- (instancetype)initWithSyncUser:(std::shared_ptr<SyncUser>)user
                             app:(RLMApp *)app {
    if (self = [super init]) {
        _user = user;
        _app = app;
        return self;
    }
    return nil;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[RLMSyncUser class]]) {
        return NO;
    }
    return _user == ((RLMSyncUser *)object)->_user;
}

- (RLMRealmConfiguration *)configurationWithPartitionValue:(id<RLMBSON>)partitionValue {
    auto syncConfig = [[RLMSyncConfiguration alloc] initWithUser:self
                                                  partitionValue:partitionValue
                                                   customFileURL:nil
                                                      stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    config.syncConfiguration = syncConfig;
    return config;
}

- (void)logOut {
    if (!_user) {
        return;
    }
    _user->log_out();
}

- (void)invalidate {
    if (!_user) {
        return;
    }
    _user = nullptr;
}

- (NSString *)pathForPartitionValue:(id<RLMBSON>)partitionValue {
    std::stringstream s;
    s << RLMConvertRLMBSONToBson(partitionValue);
    NSString *encodedPartitionValue = [@(s.str().c_str()) stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    return [[NSString alloc] initWithFormat:@"%@/%@", [self identity], encodedPartitionValue];
}

- (nullable RLMSyncSession *)sessionForPartitionValue:(id<RLMBSON>)partitionValue {
    if (!_user) {
        return nil;
    }

    auto path = SyncManager::shared().path_for_realm(*_user, [[self pathForPartitionValue:partitionValue] UTF8String]);
    if (auto session = _user->session_for_on_disk_path(path)) {
        return [[RLMSyncSession alloc] initWithSyncSession:session];
    }
    return nil;
}

- (NSArray<RLMSyncSession *> *)allSessions {
    if (!_user) {
        return @[];
    }
    NSMutableArray<RLMSyncSession *> *buffer = [NSMutableArray array];
    auto sessions = _user->all_sessions();
    for (auto session : sessions) {
        [buffer addObject:[[RLMSyncSession alloc] initWithSyncSession:std::move(session)]];
    }
    return [buffer copy];
}

- (NSString *)identity {
    if (!_user) {
        return nil;
    }
    return @(_user->identity().c_str());
}

- (NSArray<RLMSyncUserIdentity *> *)identities {
    if (!_user) {
        return @[];
    }
    NSMutableArray<RLMSyncUserIdentity *> *buffer = [NSMutableArray array];
    auto identities = _user->identities();
    for (auto& identity : identities) {
        [buffer addObject: [[RLMSyncUserIdentity alloc] initSyncUserIdentityWithProviderType:@(identity.provider_type.c_str())
                                                                                    identity:@(identity.id.c_str())]];
    }

    return [buffer copy];
}

- (RLMSyncUserState)state {
    if (!_user) {
        return RLMSyncUserStateRemoved;
    }
    switch (_user->state()) {
        case SyncUser::State::LoggedIn:
            return RLMSyncUserStateLoggedIn;
        case SyncUser::State::LoggedOut:
            return RLMSyncUserStateLoggedOut;
        case SyncUser::State::Removed:
            return RLMSyncUserStateRemoved;
    }
}

- (void)refreshCustomData:(RLMUserUserOptionalErrorBlock)completionBlock {
    [_app _realmApp]->refresh_custom_data(_user, [completionBlock](util::Optional<app::AppError> error){
        if (!error) {
            return completionBlock(nil);
        }
        
        completionBlock(RLMAppErrorToNSError(*error));
    });
}

#pragma mark - Private API

+ (void)_setUpBindingContextFactory {
    SyncUser::set_binding_context_factory([] {
        return std::make_shared<CocoaSyncUserContext>();
    });
}

- (NSString *)refreshToken {
    if (!_user) {
        return nil;
    }
    return @(_user->refresh_token().c_str());
}

- (NSString *)accessToken {
    if (!_user) {
        return nil;
    }
    return @(_user->access_token().c_str());
}

- (NSDictionary *)customData {
    if (!_user || !_user->custom_data()) {
        return nil;
    }

    return (NSDictionary *)RLMConvertBsonToRLMBSON(*_user->custom_data());
}

- (std::shared_ptr<SyncUser>)_syncUser {
    return _user;
}

@end

#pragma mark - RLMSyncUserInfo

@implementation RLMSyncUserInfo

- (instancetype)initPrivate {
    return [super init];
}

+ (instancetype)syncUserInfoWithModel:(RLMUserResponseModel *)model {
    RLMSyncUserInfo *info = [[RLMSyncUserInfo alloc] initPrivate];
    info.accounts = model.accounts;
    info.metadata = model.metadata;
    info.isAdmin = model.isAdmin;
    info.identity = model.identity;
    return info;
}

@end

#pragma mark - RLMSyncUserIdentity

@implementation RLMSyncUserIdentity

- (instancetype)initSyncUserIdentityWithProviderType:(NSString *)providerType
                                            identity:(NSString *)identity {
    if (self = [super init]) {
        _providerType = providerType;
        _identity = identity;
    }
    return self;
}

@end
