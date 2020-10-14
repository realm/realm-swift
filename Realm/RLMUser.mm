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

#import "RLMCredentials_Private.hpp"
#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
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
#import "RLMAPIKeyAuth.h"
#import "RLMMongoClient_Private.hpp"

#import "util/bson/bson.hpp"
#import "sync/sync_manager.hpp"
#import "sync/sync_session.hpp"
#import "sync/sync_user.hpp"

using namespace realm;

@interface RLMUser () {
    std::shared_ptr<SyncUser> _user;
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

- (BOOL)isLoggedIn {
    return _user->is_logged_in();
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
    return [[NSString alloc] initWithFormat:@"%@/%@", [self identifier], encodedPartitionValue];
}

- (nullable RLMSyncSession *)sessionForPartitionValue:(id<RLMBSON>)partitionValue {
    if (!_user) {
        return nil;
    }

    auto path = _user->sync_manager()->path_for_realm(*_user, [[self pathForPartitionValue:partitionValue] UTF8String]);
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
    _user->refresh_custom_data([completion, self](util::Optional<app::AppError> error) {
        if (!error) {
            return completion([self customData], nil);
        }

        completion(nil, RLMAppErrorToNSError(*error));
    });
}

- (void)linkUserWithCredentials:(RLMCredentials *)credentials
                     completion:(RLMOptionalUserBlock)completion {
    _app._realmApp->link_user(_user, credentials.appCredentials,
                   ^(std::shared_ptr<SyncUser> user, util::Optional<app::AppError> error) {
        if (error && error->error_code) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }

        completion([[RLMUser alloc] initWithUser:user app:_app], nil);
    });
}

- (void)removeWithCompletion:(RLMOptionalErrorBlock)completion {
    _app._realmApp->remove_user(_user, ^(realm::util::Optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (void)logOutWithCompletion:(RLMOptionalErrorBlock)completion {
    _app._realmApp->log_out(_user, ^(realm::util::Optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (RLMAPIKeyAuth *)apiKeysAuth {
    return [[RLMAPIKeyAuth alloc] initWithApp: _app];
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

    _app._realmApp->call_function(_user,
                        std::string(name.UTF8String),
                        args, [completionBlock](util::Optional<app::AppError> error,
                                                util::Optional<bson::Bson> response) {
        if (error) {
            return completionBlock(nil, RLMAppErrorToNSError(*error));
        }

        completionBlock(RLMConvertBsonToRLMBSON(*response), nil);
    });
}

- (void)handleResponse:(realm::util::Optional<realm::app::AppError>)error
            completion:(RLMOptionalErrorBlock)completion {
    if (error && error->error_code) {
        return completion(RLMAppErrorToNSError(*error));
    }
    completion(nil);
}

#pragma mark - Private API

+ (void)_setUpBindingContextFactory {
    SyncUser::set_binding_context_factory([] {
        return std::make_shared<CocoaSyncUserContext>();
    });
}

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

- (std::shared_ptr<SyncUser>)_syncUser {
    return _user;
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
