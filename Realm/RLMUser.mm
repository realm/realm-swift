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

#import "RLMUser_Private.hpp"

#import "RLMAPIKeyAuth.h"
#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMCredentials_Private.hpp"
#import "RLMMongoClient_Private.hpp"
#import "RLMRealmConfiguration_Private.h"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncSession_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/sync/sync_session.hpp>
#import <realm/object-store/sync/sync_user.hpp>
#import <realm/util/bson/bson.hpp>

using namespace realm;

@interface RLMUser () {
    std::shared_ptr<SyncUser> _user;
}
@end

@implementation RLMUserSubscriptionToken {
    std::shared_ptr<SyncUser> _user;
    std::optional<realm::Subscribable<SyncUser>::Token> _token;
}

- (instancetype)initWithUser:(std::shared_ptr<SyncUser>)user token:(realm::Subscribable<SyncUser>::Token&&)token {
    if (self = [super init]) {
        _user = std::move(user);
        _token = std::move(token);
    }
    return self;
}

- (void)unsubscribe {
    _token.reset();
    _user.reset();
}
@end

@implementation RLMUser

#pragma mark - API

- (instancetype)initWithUser:(std::shared_ptr<SyncUser>)user
                         app:(RLMApp *)app {
    if (self = [super init]) {
        _user = user;
        _app = app;
        return self;
    }
    return nil;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[RLMUser class]]) {
        return NO;
    }
    return _user == ((RLMUser *)object)->_user;
}

- (RLMRealmConfiguration *)configurationWithPartitionValue:(nullable id<RLMBSON>)partitionValue {
    return [self configurationWithPartitionValue:partitionValue clientResetMode:RLMClientResetModeRecoverUnsyncedChanges];
}

- (RLMRealmConfiguration *)configurationWithPartitionValue:(nullable id<RLMBSON>)partitionValue
                                           clientResetMode:(RLMClientResetMode)clientResetMode {
    auto syncConfig = [[RLMSyncConfiguration alloc] initWithUser:self
                                                  partitionValue:partitionValue];
    syncConfig.clientResetMode = clientResetMode;
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    config.syncConfiguration = syncConfig;
    return config;
}

- (RLMRealmConfiguration *)configurationWithPartitionValue:(nullable id<RLMBSON>)partitionValue
                                           clientResetMode:(RLMClientResetMode)clientResetMode
                                         notifyBeforeReset:(nullable RLMClientResetBeforeBlock)beforeResetBlock
                                          notifyAfterReset:(nullable RLMClientResetAfterBlock)afterResetBlock {
    auto syncConfig = [[RLMSyncConfiguration alloc] initWithUser:self
                                                  partitionValue:partitionValue];
    syncConfig.clientResetMode = clientResetMode;
    syncConfig.beforeClientReset = beforeResetBlock;
    syncConfig.afterClientReset = afterResetBlock;
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    config.syncConfiguration = syncConfig;
    return config;
}

- (RLMRealmConfiguration *)configurationWithPartitionValue:(nullable id<RLMBSON>)partitionValue
                                           clientResetMode:(RLMClientResetMode)clientResetMode
                                  manualClientResetHandler:(nullable RLMSyncErrorReportingBlock)manualClientResetHandler {
    auto syncConfig = [[RLMSyncConfiguration alloc] initWithUser:self
                                                  partitionValue:partitionValue];
    syncConfig.clientResetMode = clientResetMode;
    syncConfig.manualClientResetHandler = manualClientResetHandler;
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    config.syncConfiguration = syncConfig;
    return config;
}

- (RLMRealmConfiguration *)flexibleSyncConfiguration {
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    config.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:self];
    return config;
}

- (RLMRealmConfiguration *)flexibleSyncConfigurationWithClientResetMode:(RLMClientResetMode)clientResetMode
                                                      notifyBeforeReset:(nullable RLMClientResetBeforeBlock)beforeResetBlock
                                                       notifyAfterReset:(nullable RLMClientResetAfterBlock)afterResetBlock {
    auto syncConfig = [[RLMSyncConfiguration alloc] initWithUser:self];
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    syncConfig.clientResetMode = clientResetMode;
    syncConfig.beforeClientReset = beforeResetBlock;
    syncConfig.afterClientReset = afterResetBlock;
    config.syncConfiguration = syncConfig;
    return config;
}

- (RLMRealmConfiguration *)flexibleSyncConfigurationWithClientResetMode:(RLMClientResetMode)clientResetMode
                                               manualClientResetHandler:(nullable RLMSyncErrorReportingBlock)manualClientResetHandler {
    auto syncConfig = [[RLMSyncConfiguration alloc] initWithUser:self];
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    syncConfig.clientResetMode = clientResetMode;
    syncConfig.manualClientResetHandler = manualClientResetHandler;
    config.syncConfiguration = syncConfig;
    return config;
}

- (RLMRealmConfiguration *)flexibleSyncConfigurationWithInitialSubscriptions:(RLMFlexibleSyncInitialSubscriptionsBlock)initialSubscriptions
                                                                 rerunOnOpen:(BOOL)rerunOnOpen {
    auto syncConfig = [[RLMSyncConfiguration alloc] initWithUser:self];
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    config.initialSubscriptions = initialSubscriptions;
    config.rerunOnOpen = rerunOnOpen;
    config.syncConfiguration = syncConfig;
    return config;
}

- (RLMRealmConfiguration *)flexibleSyncConfigurationWithInitialSubscriptions:(RLMFlexibleSyncInitialSubscriptionsBlock)initialSubscriptions
                                                                 rerunOnOpen:(BOOL)rerunOnOpen
                                                             clientResetMode:(RLMClientResetMode)clientResetMode
                                                           notifyBeforeReset:(nullable RLMClientResetBeforeBlock)beforeResetBlock
                                                            notifyAfterReset:(nullable RLMClientResetAfterBlock)afterResetBlock {
    auto syncConfig = [[RLMSyncConfiguration alloc] initWithUser:self];
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    syncConfig.clientResetMode = clientResetMode;
    syncConfig.beforeClientReset = beforeResetBlock;
    syncConfig.afterClientReset = afterResetBlock;
    config.initialSubscriptions = initialSubscriptions;
    config.rerunOnOpen = rerunOnOpen;
    config.syncConfiguration = syncConfig;
    return config;
}

- (RLMRealmConfiguration *)flexibleSyncConfigurationWithInitialSubscriptions:(RLMFlexibleSyncInitialSubscriptionsBlock)initialSubscriptions
                                                                 rerunOnOpen:(BOOL)rerunOnOpen
                                                             clientResetMode:(RLMClientResetMode)clientResetMode
                                                    manualClientResetHandler:(nullable RLMSyncErrorReportingBlock)manualClientResetHandler {
    auto syncConfig = [[RLMSyncConfiguration alloc] initWithUser:self];
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    syncConfig.clientResetMode = clientResetMode;
    syncConfig.manualClientResetHandler = manualClientResetHandler;
    config.initialSubscriptions = initialSubscriptions;
    config.rerunOnOpen = rerunOnOpen;
    config.syncConfiguration = syncConfig;
    return config;
}

- (void)logOut {
    if (!_user) {
        return;
    }
    _user->log_out();
}

- (BOOL)isLoggedIn {
    return _user->is_logged_in();
}

- (void)invalidate {
    if (!_user) {
        return;
    }
    _user = nullptr;
}

- (std::string)pathForPartitionValue:(std::string const&)value {
    if (!_user) {
        return "";
    }

    SyncConfig config(_user, value);
    auto path = _user->sync_manager()->path_for_realm(config, value);
    if ([NSFileManager.defaultManager fileExistsAtPath:@(path.c_str())]) {
        return path;
    }

    // Previous versions converted the partition value to a path *twice*,
    // so if the file resulting from that exists open it instead
    NSString *encodedPartitionValue = [@(value.data())
                                       stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSString *overEncodedRealmName = [[NSString alloc] initWithFormat:@"%@/%@", self.identifier, encodedPartitionValue];
    auto legacyPath = _user->sync_manager()->path_for_realm(config, std::string(overEncodedRealmName.UTF8String));
    if ([NSFileManager.defaultManager fileExistsAtPath:@(legacyPath.c_str())]) {
        return legacyPath;
    }

    return path;
}

- (std::string)pathForFlexibleSync {
    if (!_user) {
        @throw RLMException(@"This is an exceptional state, `RLMUser` cannot be initialised without a reference to `SyncUser`");
    }

    SyncConfig config(_user, SyncConfig::FLXSyncEnabled{});
    return _user->sync_manager()->path_for_realm(config, realm::none);
}

- (nullable RLMSyncSession *)sessionForPartitionValue:(id<RLMBSON>)partitionValue {
    if (!_user) {
        return nil;
    }

    std::stringstream s;
    s << RLMConvertRLMBSONToBson(partitionValue);
    auto path = [self pathForPartitionValue:s.str()];
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

- (NSString *)identifier {
    if (!_user) {
        return @"";
    }
    return @(_user->identity().c_str());
}

- (NSArray<RLMUserIdentity *> *)identities {
    if (!_user) {
        return @[];
    }
    NSMutableArray<RLMUserIdentity *> *buffer = [NSMutableArray array];
    auto identities = _user->identities();
    for (auto& identity : identities) {
        [buffer addObject: [[RLMUserIdentity alloc] initUserIdentityWithProviderType:@(identity.provider_type.c_str())
                                                                          identifier:@(identity.id.c_str())]];
    }

    return [buffer copy];
}

- (RLMUserState)state {
    if (!_user) {
        return RLMUserStateRemoved;
    }
    switch (_user->state()) {
        case SyncUser::State::LoggedIn:
            return RLMUserStateLoggedIn;
        case SyncUser::State::LoggedOut:
            return RLMUserStateLoggedOut;
        case SyncUser::State::Removed:
            return RLMUserStateRemoved;
    }
}

- (void)refreshCustomDataWithCompletion:(RLMUserCustomDataBlock)completion {
    _user->refresh_custom_data([completion, self](std::optional<app::AppError> error) {
        if (!error) {
            return completion([self customData], nil);
        }

        completion(nil, makeError(*error));
    });
}

- (void)linkUserWithCredentials:(RLMCredentials *)credentials
                     completion:(RLMOptionalUserBlock)completion {
    _app._realmApp->link_user(_user, credentials.appCredentials,
                   ^(std::shared_ptr<SyncUser> user, std::optional<app::AppError> error) {
        if (error) {
            return completion(nil, makeError(*error));
        }

        completion([[RLMUser alloc] initWithUser:user app:_app], nil);
    });
}

- (void)removeWithCompletion:(RLMOptionalErrorBlock)completion {
    _app._realmApp->remove_user(_user, ^(std::optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (void)deleteWithCompletion:(RLMUserOptionalErrorBlock)completion {
    _app._realmApp->delete_user(_user, ^(std::optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (void)logOutWithCompletion:(RLMOptionalErrorBlock)completion {
    _app._realmApp->log_out(_user, ^(std::optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (RLMAPIKeyAuth *)apiKeysAuth {
    return [[RLMAPIKeyAuth alloc] initWithApp:_app];
}

- (RLMMongoClient *)mongoClientWithServiceName:(NSString *)serviceName {
    return [[RLMMongoClient alloc] initWithUser:self serviceName:serviceName];
}

- (void)callFunctionNamed:(NSString *)name
                arguments:(NSArray<id<RLMBSON>> *)arguments
          completionBlock:(RLMCallFunctionCompletionBlock)completionBlock {
    bson::BsonArray args;

    for (id<RLMBSON> argument in arguments) {
        args.push_back(RLMConvertRLMBSONToBson(argument));
    }

    _app._realmApp->call_function(_user, name.UTF8String, args,
                                  [completionBlock](std::optional<bson::Bson>&& response,
                                                    std::optional<app::AppError> error) {
        if (error) {
            return completionBlock(nil, makeError(*error));
        }

        completionBlock(RLMConvertBsonToRLMBSON(*response), nil);
    });
}

- (void)handleResponse:(std::optional<realm::app::AppError>)error
            completion:(RLMOptionalErrorBlock)completion {
    if (error) {
        return completion(makeError(*error));
    }
    completion(nil);
}

#pragma mark - Private API

- (NSString *)refreshToken {
    if (!_user || _user->refresh_token().empty()) {
        return nil;
    }
    return @(_user->refresh_token().c_str());
}

- (NSString *)accessToken {
    if (!_user || _user->access_token().empty()) {
        return nil;
    }
    return @(_user->access_token().c_str());
}

- (NSDictionary *)customData {
    if (!_user || !_user->custom_data()) {
        return @{};
    }

    return (NSDictionary *)RLMConvertBsonToRLMBSON(*_user->custom_data());
}

- (RLMUserProfile *)profile {
    if (!_user) {
        return [RLMUserProfile new];
    }

    return [[RLMUserProfile alloc] initWithUserProfile:_user->user_profile()];
}
- (std::shared_ptr<SyncUser>)_syncUser {
    return _user;
}

- (RLMUserSubscriptionToken *)subscribe:(RLMUserNotificationBlock)block {
    return [[RLMUserSubscriptionToken alloc] initWithUser:_user token:_user->subscribe([block, self] (auto&) {
        block(self);
    })];
}
@end

#pragma mark - RLMUserIdentity

@implementation RLMUserIdentity

- (instancetype)initUserIdentityWithProviderType:(NSString *)providerType
                                      identifier:(NSString *)identifier {
    if (self = [super init]) {
        _providerType = providerType;
        _identifier = identifier;
    }
    return self;
}

@end

#pragma mark - RLMUserProfile

@interface RLMUserProfile () {
    SyncUserProfile _userProfile;
}
@end

static NSString* userProfileMemberToNSString(const std::optional<std::string>& member) {
    if (member == util::none) {
        return nil;
    }
    return @(member->c_str());
}

@implementation RLMUserProfile

using UserProfileMember = std::optional<std::string> (SyncUserProfile::*)() const;

- (instancetype)initWithUserProfile:(SyncUserProfile)userProfile {
    if (self = [super init]) {
        _userProfile = std::move(userProfile);
    }
    return self;
}

- (NSString *)name {
    return userProfileMemberToNSString(_userProfile.name());
}
- (NSString *)email {
    return userProfileMemberToNSString(_userProfile.email());
}
- (NSString *)pictureURL {
    return userProfileMemberToNSString(_userProfile.picture_url());
}
- (NSString *)firstName {
    return userProfileMemberToNSString(_userProfile.first_name());
}
- (NSString *)lastName {
    return userProfileMemberToNSString(_userProfile.last_name());;
}
- (NSString *)gender {
    return userProfileMemberToNSString(_userProfile.gender());
}
- (NSString *)birthday {
    return userProfileMemberToNSString(_userProfile.birthday());
}
- (NSString *)minAge {
    return userProfileMemberToNSString(_userProfile.min_age());
}
- (NSString *)maxAge {
    return userProfileMemberToNSString(_userProfile.max_age());
}
- (NSDictionary *)metadata {
    return (NSDictionary *)RLMConvertBsonToRLMBSON(_userProfile.data());
}

@end
