////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import "RLMApp_Private.hpp"

#import "RLMAppCredentials_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMSyncUser_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMUsernamePasswordProviderClient.h"
#import "RLMUserAPIKeyProviderClient.h"
#import "RLMUtil.hpp"
#import "RLMMongoClient_Private.hpp"

#if !defined(REALM_COCOA_VERSION)
#import "RLMVersion.h"
#endif

using namespace realm;

namespace {
    /// Internal transport struct to bridge RLMNetworkingTransporting to the GenericNetworkTransport.
    class CocoaNetworkTransport : public realm::app::GenericNetworkTransport {
    public:
        CocoaNetworkTransport(id<RLMNetworkTransport> transport) : m_transport(transport) {};

        void send_request_to_server(const app::Request request,
                                    std::function<void(const app::Response)> completion) override {
            // Convert the app::Request to an RLMRequest
            auto rlmRequest = [RLMRequest new];
            rlmRequest.url = @(request.url.data());
            rlmRequest.body = @(request.body.data());
            NSMutableDictionary *headers = [NSMutableDictionary new];
            for (auto header : request.headers) {
                headers[@(header.first.data())] = @(header.second.data());
            }
            rlmRequest.headers = headers;
            rlmRequest.method = static_cast<RLMHTTPMethod>(request.method);
            rlmRequest.timeout = request.timeout_ms / 1000;

            // Send the request through to the Cocoa level transport
            [m_transport sendRequestToServer:rlmRequest completion:^(RLMResponse * response) {
                __block std::map<std::string, std::string> bridgingHeaders;
                [response.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *) {
                    bridgingHeaders[key.UTF8String] = value.UTF8String;
                }];

                // Convert the RLMResponse to an app:Response and pass downstream to
                // the object store
                completion({
                    .body = response.body.UTF8String,
                    .headers = bridgingHeaders,
                    .http_status_code = static_cast<int>(response.httpStatusCode),
                    .custom_status_code = static_cast<int>(response.customStatusCode)
                });
            }];
        }
        
        id<RLMNetworkTransport> transport() const {
            return m_transport;
        }
    private:
        id<RLMNetworkTransport> m_transport;
    };
}

@implementation RLMAppConfiguration {
    realm::app::App::Config _config;
}

- (instancetype)initWithBaseURL:(nullable NSString *)baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
                   localAppName:(nullable NSString *)localAppName
                localAppVersion:(nullable NSString *)localAppVersion {
    return [self initWithBaseURL:baseURL
                       transport:transport
                    localAppName:localAppName
                 localAppVersion:localAppVersion
         defaultRequestTimeoutMS:6000];
}

- (instancetype)initWithBaseURL:(nullable NSString *)baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
                   localAppName:(NSString *)localAppName
                localAppVersion:(nullable NSString *)localAppVersion
        defaultRequestTimeoutMS:(NSUInteger)defaultRequestTimeoutMS {
    if (self = [super init]) {
        self.baseURL = baseURL;
        self.transport = transport;
        self.localAppName = localAppName;
        self.localAppVersion = localAppVersion;
        self.defaultRequestTimeoutMS = defaultRequestTimeoutMS;
        
        _config.platform = "Realm Cocoa";

        RLMNSStringToStdString(_config.platform_version, [[NSProcessInfo processInfo] operatingSystemVersionString]);
        RLMNSStringToStdString(_config.sdk_version, REALM_COCOA_VERSION);
        return self;
    }
    return nil;
}

- (realm::app::App::Config&)config {
    return _config;
}

- (void)setAppId:(NSString *)appId {
    RLMNSStringToStdString(_config.app_id, appId);
}

- (NSString *)baseURL {
    if (_config.base_url) {
        return @(_config.base_url->c_str());
    }

    return nil;
}

- (void)setBaseURL:(nullable NSString *)baseURL {
    std::string base_url;
    RLMNSStringToStdString(base_url, baseURL);
    _config.base_url = base_url.empty() ? util::none : util::Optional(base_url);
    return;
}

- (id<RLMNetworkTransport>)transport {
    return static_cast<CocoaNetworkTransport*>(_config.transport_generator().get())->transport();
}

- (void)setTransport:(id<RLMNetworkTransport>)transport {
    if (transport) {
        _config.transport_generator = [transport]{
            return std::make_unique<CocoaNetworkTransport>(transport);
        };
    } else {
        _config.transport_generator = []{
            return std::make_unique<CocoaNetworkTransport>([RLMNetworkTransport new]);
        };
    }
}

- (NSString *)localAppName {
    if (_config.local_app_name) {
        return @((_config.base_url)->c_str());
    }

    return nil;
}

- (void)setLocalAppName:(nullable NSString *)localAppName {
    std::string local_app_name;
    RLMNSStringToStdString(local_app_name, localAppName);
    _config.local_app_name = local_app_name.empty() ? util::none : util::Optional(local_app_name);
    return;
}

- (NSString *)localAppVersion {
    if (_config.local_app_version) {
        return @((_config.base_url)->c_str());
    }

    return nil;
}

- (void)setLocalAppVersion:(nullable NSString *)localAppVersion {
    std::string local_app_version;
    RLMNSStringToStdString(local_app_version, localAppVersion);
    _config.local_app_version = local_app_version.empty() ? util::none : util::Optional(local_app_version);
    return;
}

- (NSUInteger)defaultRequestTimeoutMS {
    return _config.default_request_timeout_ms.value_or(6000);
}

- (void)setDefaultRequestTimeoutMS:(NSUInteger)defaultRequestTimeoutMS {
    _config.default_request_timeout_ms = (uint64_t)defaultRequestTimeoutMS;
}

@end

NSError *RLMAppErrorToNSError(realm::app::AppError const& appError) {
    return [[NSError alloc] initWithDomain:@(appError.error_code.category().name())
                                      code:appError.error_code.value()
                                  userInfo:@{
                                      @(appError.error_code.category().name()) : @(appError.error_code.message().data()),
                                      NSLocalizedDescriptionKey : @(appError.message.c_str())
                                  }];
}

@interface RLMApp() {
    std::shared_ptr<realm::app::App> _app;
}

@end

@implementation RLMApp : NSObject

- (instancetype)initWithId:(NSString *)appId
             configuration:(RLMAppConfiguration *)configuration
             rootDirectory:(NSURL *)rootDirectory {
    if (self = [super init]) {
        if (!configuration) {
            configuration = [[RLMAppConfiguration alloc] initWithBaseURL:nil
                                                               transport:nil
                                                            localAppName:nil
                                                         localAppVersion:nil];
        }
        _configuration = configuration;
        [_configuration setAppId:appId];

        _syncManager = [[RLMSyncManager alloc] initWithAppConfiguration:configuration
                                                          rootDirectory:rootDirectory];
        _app = [_syncManager app];

        return self;
    }
    return nil;
}

+ (instancetype)appWithId:(NSString *)appId
            configuration:(RLMAppConfiguration *)configuration
            rootDirectory:(NSURL *)rootDirectory {
    static NSMutableDictionary *s_apps = [NSMutableDictionary new];
    // protects the app cache
    static std::mutex& initLock = *new std::mutex();
    std::lock_guard<std::mutex> lock(initLock);

    if (RLMApp *app = s_apps[appId]) {
        return app;
    }

    RLMApp *app = [[RLMApp alloc] initWithId:appId configuration:configuration rootDirectory:rootDirectory];
    s_apps[appId] = app;
    return app;
}

+ (instancetype)appWithId:(NSString *)appId configuration:(RLMAppConfiguration *)configuration {
    return [self appWithId:appId configuration:configuration rootDirectory:nil];
}

+ (instancetype)appWithId:(NSString *)appId {
    return [self appWithId:appId configuration:nil];
}

- (std::shared_ptr<realm::app::App>)_realmApp {
    return _app;
}

- (NSDictionary<NSString *, RLMSyncUser *> *)allUsers {
    NSMutableDictionary *buffer = [NSMutableDictionary new];
    for (auto user : SyncManager::shared().all_users()) {
        std::string identity(user->identity());
        buffer[@(identity.c_str())] = [[RLMSyncUser alloc] initWithSyncUser:std::move(user) app:self];
    }
    return buffer;
}

- (RLMSyncUser *)currentUser {
    if (auto user = SyncManager::shared().get_current_user()) {
        return [[RLMSyncUser alloc] initWithSyncUser:user app:self];
    }
    return nil;
}

- (void)loginWithCredential:(RLMAppCredentials *)credentials
          completion:(RLMUserCompletionBlock)completionHandler {
    _app->log_in_with_credentials(credentials.appCredentials, ^(std::shared_ptr<SyncUser> user, util::Optional<app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(nil, RLMAppErrorToNSError(*error));
        }

        completionHandler([[RLMSyncUser alloc] initWithSyncUser:user app:self], nil);
    });
}

- (RLMSyncUser *)switchToUser:(RLMSyncUser *)syncUser {
    return [[RLMSyncUser alloc] initWithSyncUser:_app->switch_user(syncUser._syncUser) app:self];
}

- (void)removeUser:(RLMSyncUser *)syncUser completion:(RLMOptionalErrorBlock)completion {
    _app->remove_user(syncUser._syncUser, ^(realm::util::Optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (void)logOutWithCompletion:(RLMOptionalErrorBlock)completion {
    _app->log_out(^(realm::util::Optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (void)logOut:(RLMSyncUser *)syncUser completion:(RLMOptionalErrorBlock)completion {
    _app->log_out(syncUser._syncUser, ^(realm::util::Optional<app::AppError> error) {
        [self handleResponse:error completion:completion];
    });
}

- (void)linkUser:(RLMSyncUser *)syncUser
     credentials:(RLMAppCredentials *)credentials
      completion:(RLMUserCompletionBlock)completion {
    _app->link_user(syncUser._syncUser, credentials.appCredentials,
                   ^(std::shared_ptr<SyncUser> user, util::Optional<app::AppError> error) {
        if (error && error->error_code) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        
        completion([[RLMSyncUser alloc] initWithSyncUser:user app:self], nil);
    });
}

- (RLMUsernamePasswordProviderClient *)usernamePasswordProviderClient {
    return [[RLMUsernamePasswordProviderClient alloc] initWithApp: self];
}

- (RLMUserAPIKeyProviderClient *)userAPIKeyProviderClient {
    return [[RLMUserAPIKeyProviderClient alloc] initWithApp: self];
}

- (RLMMongoClient *)mongoClientWithServiceName:(NSString *)serviceName {
    return [[RLMMongoClient alloc] initWithApp:self serviceName:serviceName];
}

- (void)handleResponse:(realm::util::Optional<realm::app::AppError>)error
            completion:(RLMOptionalErrorBlock)completion {
    if (error && error->error_code) {
        return completion(RLMAppErrorToNSError(*error));
    }
    completion(nil);
}

- (void)callFunctionNamed:(NSString *)name
                arguments:(NSArray<id<RLMBSON>> *)arguments
          completionBlock:(RLMCallFunctionCompletionBlock)completionBlock {
    bson::BsonArray args;

    for (id<RLMBSON> argument in arguments) {
        args.push_back(RLMConvertRLMBSONToBson(argument));
    }

    _app->call_function(SyncManager::shared().get_current_user(),
                        std::string(name.UTF8String),
                        args, [completionBlock](util::Optional<app::AppError> error,
                                                util::Optional<bson::Bson> response) {
        if (error) {
            return completionBlock(nil, RLMAppErrorToNSError(*error));
        }

        completionBlock(RLMConvertBsonToRLMBSON(*response), nil);
    });
}

@end


