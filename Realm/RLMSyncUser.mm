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

#import "RLMJSONModels.h"
#import "RLMNetworkClient.h"
#import "RLMRealmConfiguration+Sync.h"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMSyncManager_Private.h"
#import "RLMSyncPermissionResults_Private.hpp"
#import "RLMSyncPermissionValue_Private.hpp"
#import "RLMSyncSession_Private.hpp"
#import "RLMSyncSessionRefreshHandle.hpp"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"

#import "sync/sync_manager.hpp"
#import "sync/sync_session.hpp"
#import "sync/sync_user.hpp"

using namespace realm;
using ConfigMaker = std::function<Realm::Config(std::shared_ptr<SyncUser>, std::string)>;

namespace {

NSError *translateExceptionPtrToError(std::exception_ptr ptr, bool get) {
    NSError *error = nil;
    try {
        std::rethrow_exception(ptr);
    } catch (PermissionChangeException const& ex) {
        error = (get
                 ? make_permission_error_get(@(ex.what()), ex.code)
                 : make_permission_error_change(@(ex.what()), ex.code));
    }
    catch (const std::exception &exp) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, exp), &error);
    }
    return error;
}

Permissions::PermissionResultsCallback RLMWrapPermissionResultsCallback(RLMPermissionResultsBlock callback) {
    return [callback](Results results, std::exception_ptr ptr) {
        if (ptr) {
            NSError *error = translateExceptionPtrToError(std::move(ptr), true);
            REALM_ASSERT(error);
            callback(nil, error);
        } else {
            // Finished successfully
            callback([[RLMSyncPermissionResults alloc] initWithResults:std::move(results)], nil);
        }
    };
}

}

void CocoaSyncUserContext::register_refresh_handle(const std::string& path, RLMSyncSessionRefreshHandle *handle)
{
    REALM_ASSERT(handle);
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = m_refresh_handles.find(path);
    if (it != m_refresh_handles.end()) {
        [it->second invalidate];
        m_refresh_handles.erase(it);
    }
    m_refresh_handles.insert({path, handle});
}

void CocoaSyncUserContext::unregister_refresh_handle(const std::string& path)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    m_refresh_handles.erase(path);
}

void CocoaSyncUserContext::invalidate_all_handles()
{
    std::lock_guard<std::mutex> lock(m_mutex);
    for (auto& it : m_refresh_handles) {
        [it.second invalidate];
    }
    m_refresh_handles.clear();
}

RLMUserErrorReportingBlock CocoaSyncUserContext::error_handler() const
{
    std::lock_guard<std::mutex> lock(m_error_handler_mutex);
    return m_error_handler;
}

void CocoaSyncUserContext::set_error_handler(RLMUserErrorReportingBlock block)
{
    std::lock_guard<std::mutex> lock(m_error_handler_mutex);
    m_error_handler = block;
}

PermissionChangeCallback RLMWrapPermissionStatusCallback(RLMPermissionStatusBlock callback) {
    return [callback](std::exception_ptr ptr) {
        if (ptr) {
            NSError *error = translateExceptionPtrToError(std::move(ptr), false);
            REALM_ASSERT(error);
            callback(error);
        } else {
            // Finished successfully
            callback(nil);
        }
    };
}

@interface RLMSyncUserInfo ()

@property (nonatomic, readwrite) RLMIdentityProvider provider;
@property (nonatomic, readwrite) NSString *providerUserIdentity;
@property (nonatomic, readwrite) NSString *identity;
@property (nonatomic, readwrite) BOOL isAdmin;

+ (instancetype)syncUserInfoWithModel:(RLMUserResponseModel *)model;

@end

@interface RLMSyncUser () {
    std::shared_ptr<SyncUser> _user;
    // FIXME: remove this when the object store ConfigMaker goes away
    std::unique_ptr<ConfigMaker> _configMaker;
}

- (instancetype)initPrivate NS_DESIGNATED_INITIALIZER;

@end

@implementation RLMSyncUser

#pragma mark - static API

+ (NSDictionary *)allUsers {
    NSArray *allUsers = [[RLMSyncManager sharedManager] _allUsers];
    return [NSDictionary dictionaryWithObjects:allUsers
                                       forKeys:[allUsers valueForKey:@"identity"]];
}

+ (RLMSyncUser *)currentUser {
    NSArray *allUsers = [[RLMSyncManager sharedManager] _allUsers];
    if (allUsers.count > 1) {
        @throw RLMException(@"+currentUser cannot be called if more that one valid, logged-in user exists.");
    }
    return allUsers.firstObject;
}

#pragma mark - API

- (instancetype)initPrivate {
    if (self = [super init]) {
        _configMaker = std::make_unique<ConfigMaker>([](std::shared_ptr<SyncUser> user, std::string url) {
            RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
            NSURL *objCUrl = [NSURL URLWithString:@(url.c_str())];
            RLMSyncUser *objCUser = [[RLMSyncUser alloc] initWithSyncUser:std::move(user)];
            config.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:objCUser realmURL:objCUrl];
            return [config config];
        });
        return self;
    }
    return nil;
}

- (instancetype)initWithSyncUser:(std::shared_ptr<SyncUser>)user {
    if (self = [self initPrivate]) {
        _user = user;
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

+ (void)logInWithCredentials:(RLMSyncCredentials *)credential
               authServerURL:(NSURL *)authServerURL
                onCompletion:(RLMUserCompletionBlock)completion {
    [self logInWithCredentials:credential
                 authServerURL:authServerURL
                       timeout:30
                  onCompletion:completion];
}

+ (void)logInWithCredentials:(RLMSyncCredentials *)credential
               authServerURL:(NSURL *)authServerURL
                     timeout:(NSTimeInterval)timeout
                onCompletion:(RLMUserCompletionBlock)completion {
    RLMSyncUser *user = [[RLMSyncUser alloc] initPrivate];
    [RLMSyncUser _performLogInForUser:user
                          credentials:credential
                        authServerURL:authServerURL
                              timeout:timeout
                      completionBlock:completion];
}

- (void)logOut {
    if (!_user) {
        return;
    }
    _user->log_out();
    context_for(_user).invalidate_all_handles();
}

- (RLMUserErrorReportingBlock)errorHandler {
    if (!_user) {
        return nil;
    }
    return context_for(_user).error_handler();
}

- (void)setErrorHandler:(RLMUserErrorReportingBlock)errorHandler {
    if (!_user) {
        return;
    }
    context_for(_user).set_error_handler([errorHandler copy]);
}

- (nullable RLMSyncSession *)sessionForURL:(NSURL *)url {
    if (!_user) {
        return nil;
    }
    auto path = SyncManager::shared().path_for_realm(*_user, [url.absoluteString UTF8String]);
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

- (RLMSyncUserState)state {
    if (!_user) {
        return RLMSyncUserStateError;
    }
    switch (_user->state()) {
        case SyncUser::State::Active:
            return RLMSyncUserStateActive;
        case SyncUser::State::LoggedOut:
            return RLMSyncUserStateLoggedOut;
        case SyncUser::State::Error:
            return RLMSyncUserStateError;
    }
}

- (RLMRealm *)managementRealmWithError:(NSError **)error {
    return [RLMRealm realmWithConfiguration:[RLMRealmConfiguration managementConfigurationForUser:self] error:error];
}

- (RLMRealm *)permissionRealmWithError:(NSError **)error {
    return [RLMRealm realmWithConfiguration:[RLMRealmConfiguration permissionConfigurationForUser:self] error:error];
}

- (NSURL *)authenticationServer {
    if (!_user || _user->token_type() == SyncUser::TokenType::Admin) {
        return nil;
    }
    return [NSURL URLWithString:@(_user->server_url().c_str())];
}

- (BOOL)isAdmin {
    if (!_user) {
        return NO;
    }
    return _user->is_admin();
}

#pragma mark - Passwords

- (void)changePassword:(NSString *)newPassword completion:(RLMPasswordChangeStatusBlock)completion {
    [self changePassword:newPassword forUserID:self.identity completion:completion];
}

- (void)changePassword:(NSString *)newPassword forUserID:(NSString *)userID completion:(RLMPasswordChangeStatusBlock)completion {
    if (self.state != RLMSyncUserStateActive) {
        completion([NSError errorWithDomain:RLMSyncErrorDomain
                                       code:RLMSyncErrorClientSessionError
                                   userInfo:nil]);
        return;
    }
    [RLMNetworkClient sendRequestToEndpoint:[RLMSyncChangePasswordEndpoint endpoint]
                                     server:self.authenticationServer
                                       JSON:@{kRLMSyncTokenKey: self._refreshToken,
                                              @"user_id": userID,
                                              @"password": newPassword}
                                    timeout:60
                                 completion:^(NSError *error, __unused NSDictionary *json) {
        completion(error);
    }];
}

#pragma mark - Administrator API

- (void)retrieveInfoForUser:(NSString *)providerUserIdentity
           identityProvider:(RLMIdentityProvider)provider
                 completion:(RLMRetrieveUserBlock)completion {
    [RLMNetworkClient sendRequestToEndpoint:[RLMSyncGetUserInfoEndpoint endpoint]
                                     server:self.authenticationServer
                                       JSON:@{
                                              kRLMSyncProviderKey: provider,
                                              kRLMSyncProviderIDKey: providerUserIdentity,
                                              kRLMSyncTokenKey: self._refreshToken
                                              }
                                 completion:^(NSError *error, NSDictionary *json) {
                                     if (error) {
                                         completion(nil, error);
                                         return;
                                     }
                                     RLMUserResponseModel *model = [[RLMUserResponseModel alloc] initWithDictionary:json];
                                     if (!model) {
                                         completion(nil, make_auth_error_bad_response(json));
                                         return;
                                     }
                                     completion([RLMSyncUserInfo syncUserInfoWithModel:model], nil);
                                 }];
}

#pragma mark - Permissions API

- (void)retrievePermissionsWithCallback:(RLMPermissionResultsBlock)callback {
    if (!_user || _user->state() == SyncUser::State::Error) {
        callback(nullptr, make_permission_error_get(@"Permissions cannot be retrieved using an invalid user."));
        return;
    }
    Permissions::get_permissions(_user, RLMWrapPermissionResultsCallback(callback), *_configMaker);
}

- (void)applyPermission:(RLMSyncPermissionValue *)permission callback:(RLMPermissionStatusBlock)callback {
    if (!_user || _user->state() == SyncUser::State::Error) {
        callback(make_permission_error_change(@"Permissions cannot be applied using an invalid user."));
        return;
    }
    Permissions::set_permission(_user,
                                [permission rawPermission],
                                RLMWrapPermissionStatusCallback(callback),
                                *_configMaker);
}

- (void)revokePermission:(RLMSyncPermissionValue *)permission callback:(RLMPermissionStatusBlock)callback {
    if (!_user || _user->state() == SyncUser::State::Error) {
        callback(make_permission_error_change(@"Permissions cannot be revoked using an invalid user."));
        return;
    }
    Permissions::delete_permission(_user,
                                   [permission rawPermission],
                                   RLMWrapPermissionStatusCallback(callback),
                                   *_configMaker);
}

#pragma mark - Private API

+ (void)_setUpBindingContextFactory {
    SyncUser::set_binding_context_factory([] {
        return std::make_shared<CocoaSyncUserContext>();
    });
}

- (NSString *)_refreshToken {
    if (!_user) {
        return nil;
    }
    return @(_user->refresh_token().c_str());
}

- (std::shared_ptr<SyncUser>)_syncUser {
    return _user;
}

+ (void)_performLogInForUser:(RLMSyncUser *)user
                 credentials:(RLMSyncCredentials *)credentials
               authServerURL:(NSURL *)authServerURL
                     timeout:(NSTimeInterval)timeout
             completionBlock:(RLMUserCompletionBlock)completion {
    // Special credential login should be treated differently.
    if (credentials.provider == RLMIdentityProviderAccessToken) {
        [self _performLoginForDirectAccessTokenCredentials:credentials
                                                      user:user
                                             authServerURL:authServerURL
                                           completionBlock:completion];
        return;
    }
    if (!authServerURL) {
        @throw RLMException(@"A user cannot be logged in without specifying an authentication server URL.");
    }

    // Prepare login network request
    NSMutableDictionary *json = [@{
                                   kRLMSyncProviderKey: credentials.provider,
                                   kRLMSyncDataKey: credentials.token,
                                   kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                                   } mutableCopy];
    NSMutableDictionary *info = [(credentials.userInfo ?: @{}) mutableCopy];

    if ([info count] > 0) {
        // Munge user info into the JSON request.
        json[@"user_info"] = info;
    }

    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (json && !error) {
            RLMAuthResponseModel *model = [[RLMAuthResponseModel alloc] initWithDictionary:json
                                                                        requireAccessToken:NO
                                                                       requireRefreshToken:YES];
            if (!model) {
                // Malformed JSON
                completion(nil, make_auth_error_bad_response(json));
                return;
            } else {
                std::string server_url = authServerURL.absoluteString.UTF8String;
                SyncUserIdentifier identity{[model.refreshToken.tokenData.identity UTF8String], std::move(server_url)};
                auto sync_user = SyncManager::shared().get_user(identity , [model.refreshToken.token UTF8String]);
                if (!sync_user) {
                    completion(nil, make_auth_error_client_issue());
                    return;
                }
                sync_user->set_is_admin(model.refreshToken.tokenData.isAdmin);
                user->_user = sync_user;
                completion(user, nil);
            }
        } else {
            // Something else went wrong
            completion(nil, error);
        }
    };
    [RLMNetworkClient sendRequestToEndpoint:[RLMSyncAuthEndpoint endpoint]
                                     server:authServerURL
                                       JSON:json
                                    timeout:timeout
                                 completion:handler];
}

+ (void)_performLoginForDirectAccessTokenCredentials:(RLMSyncCredentials *)credentials
                                                user:(RLMSyncUser *)user
                                       authServerURL:(NSURL *)serverURL
                                     completionBlock:(nonnull RLMUserCompletionBlock)completion {
    NSString *identity = credentials.userInfo[kRLMSyncIdentityKey];
    std::shared_ptr<SyncUser> sync_user;
    if (serverURL) {
        // Retrieve the user based on the auth server URL.
        util::Optional<std::string> identity_string;
        if (identity) {
            identity_string = std::string(identity.UTF8String);
        }
        sync_user = SyncManager::shared().get_admin_token_user([serverURL absoluteString].UTF8String,
                                                               credentials.token.UTF8String,
                                                               std::move(identity_string));
    } else {
        // Retrieve the user based on the identity.
        if (!identity) {
            @throw RLMException(@"A direct access credential must specify either an identity, a server URL, or both.");
        }
        sync_user = SyncManager::shared().get_admin_token_user_from_identity(identity.UTF8String,
                                                                             none,
                                                                             credentials.token.UTF8String);
    }
    if (!sync_user) {
        completion(nil, make_auth_error_client_issue());
        return;
    }
    user->_user = sync_user;
    completion(user, nil);
}

@end

#pragma mark - RLMSyncUserInfo

@implementation RLMSyncUserInfo

- (instancetype)initPrivate {
    return [super init];
}

+ (instancetype)syncUserInfoWithModel:(RLMUserResponseModel *)model {
    RLMSyncUserInfo *info = [[RLMSyncUserInfo alloc] initPrivate];
    info.provider = model.provider;
    info.providerUserIdentity = model.username;
    info.isAdmin = model.isAdmin;
    info.identity = model.identity;
    return info;
}

@end
