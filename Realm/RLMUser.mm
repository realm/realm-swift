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
#import "RLMProviderClient_Private.hpp"
#import "RLMRealmConfiguration_Private.h"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncSession_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/sync/app_user.hpp>
#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/sync/sync_session.hpp>
#import <realm/util/bson/bson.hpp>

using namespace realm;

@implementation RLMUserSubscriptionToken {
    std::shared_ptr<app::User> _user;
    std::optional<realm::Subscribable<app::User>::Token> _token;
}

- (instancetype)initWithUser:(std::shared_ptr<app::User>)user token:(realm::Subscribable<app::User>::Token&&)token {
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

- (instancetype)initWithUser:(std::shared_ptr<SyncUser>)user {
    if (self = [super init]) {
        _user = std::static_pointer_cast<app::User>(user);
        _app = [RLMApp cachedAppWithId:@(user->app_id().c_str())];
        return self;
    }
    return nil;
}

- (BOOL)isEqual:(id)object {
    if (auto user = RLMDynamicCast<RLMUser>(object)) {
        return _user == user->_user;
    }
    return NO;
}

- (NSUInteger)hash {
    return NSUInteger(_user.get());
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
    syncConfig.initialSubscriptions = [[RLMInitialSubscriptionsConfiguration alloc] initWithCallback:initialSubscriptions                                                                                              rerunOnOpen:rerunOnOpen];
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
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
    syncConfig.initialSubscriptions = [[RLMInitialSubscriptionsConfiguration alloc] initWithCallback:initialSubscriptions                                                                                              rerunOnOpen:rerunOnOpen];

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
    syncConfig.initialSubscriptions = [[RLMInitialSubscriptionsConfiguration alloc] initWithCallback:initialSubscriptions                                                                                              rerunOnOpen:rerunOnOpen];
    config.syncConfiguration = syncConfig;
    return config;
}

- (void)logOut {
    _user->log_out();
}

- (BOOL)isLoggedIn {
    return _user->is_logged_in();
}

- (std::string)pathForPartitionValue:(std::string const&)value {
    SyncConfig config(_user, value);
    auto path = _user->path_for_realm(config, value);
    if ([NSFileManager.defaultManager fileExistsAtPath:@(path.c_str())]) {
        return path;
    }

    // Previous versions converted the partition value to a path *twice*,
    // so if the file resulting from that exists open it instead
    NSString *encodedPartitionValue = [@(value.data())
                                       stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSString *overEncodedRealmName = [[NSString alloc] initWithFormat:@"%@/%@", self.identifier, encodedPartitionValue];
    auto legacyPath = _user->path_for_realm(config, std::string(overEncodedRealmName.UTF8String));
    if ([NSFileManager.defaultManager fileExistsAtPath:@(legacyPath.c_str())]) {
        return legacyPath;
    }

    return path;
}

- (std::string)pathForFlexibleSync {
    SyncConfig config(_user, SyncConfig::FLXSyncEnabled{});
    return _user->path_for_realm(config, realm::none);
}

- (nullable RLMSyncSession *)sessionForPartitionValue:(id<RLMBSON>)partitionValue {
    std::stringstream s;
    s << RLMConvertRLMBSONToBson(partitionValue);
    auto path = [self pathForPartitionValue:s.str()];
    if (auto session = _user->sync_manager()->get_existing_session(path)) {
        return [[RLMSyncSession alloc] initWithSyncSession:session];
    }
    return nil;
}

- (NSArray<RLMSyncSession *> *)allSessions {
    auto sessions = _user->sync_manager()->get_all_sessions_for(*_user);
    NSMutableArray<RLMSyncSession *> *buffer = [NSMutableArray arrayWithCapacity:sessions.size()];
    for (auto& session : sessions) {
        [buffer addObject:[[RLMSyncSession alloc] initWithSyncSession:std::move(session)]];
    }
    return [buffer copy];
}

- (NSString *)identifier {
    return @(_user->user_id().c_str());
}

- (NSArray<RLMUserIdentity *> *)identities {
    NSMutableArray<RLMUserIdentity *> *buffer = [NSMutableArray array];
    auto identities = _user->identities();
    for (auto& identity : identities) {
        [buffer addObject:[[RLMUserIdentity alloc] initUserIdentityWithProviderType:@(identity.provider_type.c_str())
                                                                         identifier:@(identity.id.c_str())]];
    }

    return [buffer copy];
}

- (RLMUserState)state {
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
    _user->app()->link_user(_user, credentials.appCredentials,
                            ^(std::shared_ptr<app::User> user, std::optional<app::AppError> error) {
        if (error) {
            return completion(nil, makeError(*error));
        }

        completion([[RLMUser alloc] initWithUser:user], nil);
    });
}

- (void)removeWithCompletion:(RLMOptionalErrorBlock)completion {
    _user->app()->remove_user(_user, ^(std::optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (void)deleteWithCompletion:(RLMUserOptionalErrorBlock)completion {
    _user->app()->delete_user(_user, ^(std::optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (void)logOutWithCompletion:(RLMOptionalErrorBlock)completion {
    _user->app()->log_out(_user, ^(std::optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (RLMAPIKeyAuth *)apiKeysAuth {
    return [[RLMAPIKeyAuth alloc] initWithApp:_user->app()];
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

    _user->app()->call_function(_user, name.UTF8String, args,
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
    if (_user->refresh_token().empty()) {
        return nil;
    }
    return @(_user->refresh_token().c_str());
}

- (NSString *)accessToken {
    if (_user->access_token().empty()) {
        return nil;
    }
    return @(_user->access_token().c_str());
}

- (NSDictionary *)customData {
    if (!_user->custom_data()) {
        return @{};
    }

    return (NSDictionary *)RLMConvertBsonToRLMBSON(*_user->custom_data());
}

- (RLMUserProfile *)profile {
    return [[RLMUserProfile alloc] initWithUserProfile:_user->user_profile()];
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
    app::UserProfile _userProfile;
}
@end

static NSString* userProfileMemberToNSString(const std::optional<std::string>& member) {
    if (member == util::none) {
        return nil;
    }
    return @(member->c_str());
}

@implementation RLMUserProfile

using UserProfileMember = std::optional<std::string> (app::UserProfile::*)() const;

- (instancetype)initWithUserProfile:(app::UserProfile)userProfile {
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
