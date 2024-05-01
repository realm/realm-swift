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

#import <sys/utsname.h>
#if __has_include(<UIKit/UIDevice.h>)
#import <UIKit/UIDevice.h>
#define REALM_UIDEVICE_AVAILABLE
#endif

#import "RLMAnalytics.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMCredentials_Private.hpp"
#import "RLMEmailPasswordAuth.h"
#import "RLMLogger.h"
#import "RLMProviderClient_Private.hpp"
#import "RLMPushClient_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/sync/app_user.hpp>
#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/sync/config.hpp>

#if !defined(REALM_COCOA_VERSION)
#import "RLMVersion.h"
#endif

using namespace realm;

#pragma mark CocoaNetworkTransport
namespace {
    /// Internal transport struct to bridge RLMNetworkingTransporting to the GenericNetworkTransport.
    class CocoaNetworkTransport : public realm::app::GenericNetworkTransport {
    public:
        CocoaNetworkTransport(id<RLMNetworkTransport> transport) : m_transport(transport) {}

        void send_request_to_server(const app::Request& request,
                                    util::UniqueFunction<void(const app::Response&)>&& completion) override {
            // Convert the app::Request to an RLMRequest
            auto rlmRequest = [RLMRequest new];
            rlmRequest.url = @(request.url.data());
            rlmRequest.body = @(request.body.data());
            NSMutableDictionary *headers = [NSMutableDictionary new];
            for (auto&& header : request.headers) {
                headers[@(header.first.data())] = @(header.second.data());
            }
            rlmRequest.headers = headers;
            rlmRequest.method = static_cast<RLMHTTPMethod>(request.method);
            rlmRequest.timeout = request.timeout_ms / 1000.0;

            // Send the request through to the Cocoa level transport
            auto completion_ptr = completion.release();
            [m_transport sendRequestToServer:rlmRequest completion:^(RLMResponse *response) {
                util::UniqueFunction<void(const app::Response&)> completion(completion_ptr);
                std::map<std::string, std::string> bridgingHeaders;
                [response.headers enumerateKeysAndObjectsUsingBlock:[&](NSString *key, NSString *value, BOOL *) {
                    bridgingHeaders[key.UTF8String] = value.UTF8String;
                }];

                // Convert the RLMResponse to an app:Response and pass downstream to
                // the object store
                completion(app::Response{
                    .http_status_code = static_cast<int>(response.httpStatusCode),
                    .custom_status_code = static_cast<int>(response.customStatusCode),
                    .headers = bridgingHeaders,
                    .body = response.body ? response.body.UTF8String : ""
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

#pragma mark RLMAppConfiguration
@implementation RLMAppConfiguration {
    realm::app::AppConfig _config;
}

- (instancetype)init {
    if (self = [super init]) {
        self.enableSessionMultiplexing = true;
        self.encryptMetadata = !getenv("REALM_DISABLE_METADATA_ENCRYPTION") && !RLMIsRunningInPlayground();
        RLMNSStringToStdString(_config.base_file_path, RLMDefaultDirectoryForBundleIdentifier(nil));
        configureSyncConnectionParameters(_config);
    }
    return self;
}

- (instancetype)initWithBaseURL:(nullable NSString *)baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
                   localAppName:(nullable NSString *)localAppName
                localAppVersion:(nullable NSString *)localAppVersion {
    return [self initWithBaseURL:baseURL
                       transport:transport
                    localAppName:localAppName
                 localAppVersion:localAppVersion
         defaultRequestTimeoutMS:60000];
}

- (instancetype)initWithBaseURL:(nullable NSString *)baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
                   localAppName:(nullable NSString *)localAppName
                localAppVersion:(nullable NSString *)localAppVersion
        defaultRequestTimeoutMS:(NSUInteger)defaultRequestTimeoutMS {
    if (self = [self init]) {
        self.baseURL = baseURL;
        self.transport = transport;
        self.localAppName = localAppName;
        self.localAppVersion = localAppVersion;
        self.defaultRequestTimeoutMS = defaultRequestTimeoutMS;
    }
    return self;
}

- (instancetype)initWithBaseURL:(nullable NSString *)baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport {
    return [self initWithBaseURL:baseURL
                       transport:transport
         defaultRequestTimeoutMS:60000];
}

- (instancetype)initWithBaseURL:(nullable NSString *)baseURL
                      transport:(nullable id<RLMNetworkTransport>)transport
        defaultRequestTimeoutMS:(NSUInteger)defaultRequestTimeoutMS {
    if (self = [self init]) {
        self.baseURL = baseURL;
        self.transport = transport;
        self.defaultRequestTimeoutMS = defaultRequestTimeoutMS;
    }
    return self;
}

static void configureSyncConnectionParameters(realm::app::AppConfig& config) {
    // Anonymized BundleId
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSData *bundleIdData = [bundleId dataUsingEncoding:NSUTF8StringEncoding];
    RLMNSStringToStdString(config.device_info.bundle_id, RLMHashBase16Data(bundleIdData.bytes, bundleIdData.length));

    config.device_info.sdk = "Realm Swift";
    RLMNSStringToStdString(config.device_info.sdk_version, REALM_COCOA_VERSION);

    // Platform info isn't available when running via `swift test`.
    // Non-Xcode SPM builds can't build for anything but macOS, so this is
    // probably unimportant for now and we can just report "unknown"
    auto processInfo = [NSProcessInfo processInfo];
    RLMNSStringToStdString(config.device_info.platform_version,
                           [processInfo operatingSystemVersionString] ?: @"unknown");

    RLMNSStringToStdString(config.device_info.framework_version, @__clang_version__);

#ifdef REALM_UIDEVICE_AVAILABLE
    RLMNSStringToStdString(config.device_info.device_name, [UIDevice currentDevice].model);
#endif
    struct utsname systemInfo;
    uname(&systemInfo);
    config.device_info.device_version = systemInfo.machine;
}

- (const realm::app::AppConfig&)config {
    if (!_config.transport) {
        self.transport = nil;
    }
    return _config;
}

- (id)copyWithZone:(NSZone *)zone {
    RLMAppConfiguration *copy = [[RLMAppConfiguration alloc] init];
    copy->_config = _config;
    return copy;
}

- (NSString *)appId {
    return RLMStringViewToNSString(_config.app_id);
}

- (void)setAppId:(NSString *)appId {
    if ([appId length] == 0) {
        @throw RLMException(@"AppId cannot be an empty string");
    }

    RLMNSStringToStdString(_config.app_id, appId);
}

static NSString *getOptionalString(const std::optional<std::string>& str) {
    return str ? RLMStringViewToNSString(*str) : nil;
}

static void setOptionalString(std::optional<std::string>& dst, NSString *src) {
    if (src.length == 0) {
        dst.reset();
    }
    else {
        dst.emplace();
        RLMNSStringToStdString(*dst, src);
    }
}

- (NSString *)baseURL {
    return getOptionalString(_config.base_url) ?: RLMStringViewToNSString(app::App::default_base_url());
}

- (void)setBaseURL:(nullable NSString *)baseURL {
    setOptionalString(_config.base_url, baseURL);
}

- (id<RLMNetworkTransport>)transport {
    return static_cast<CocoaNetworkTransport&>(*_config.transport).transport();
}

- (void)setTransport:(id<RLMNetworkTransport>)transport {
    if (!transport) {
        transport = [RLMNetworkTransport new];
    }
    _config.transport = std::make_shared<CocoaNetworkTransport>(transport);
}

- (NSUInteger)defaultRequestTimeoutMS {
    return _config.default_request_timeout_ms.value_or(60000U);
}

- (void)setDefaultRequestTimeoutMS:(NSUInteger)defaultRequestTimeoutMS {
    _config.default_request_timeout_ms = (uint64_t)defaultRequestTimeoutMS;
}

- (BOOL)enableSessionMultiplexing {
    return _config.sync_client_config.multiplex_sessions;
}

- (void)setEnableSessionMultiplexing:(BOOL)enableSessionMultiplexing {
    _config.sync_client_config.multiplex_sessions = enableSessionMultiplexing;
}

- (BOOL)encryptMetadata {
    return _config.metadata_mode == app::AppConfig::MetadataMode::Encryption;
}

- (void)setEncryptMetadata:(BOOL)encryptMetadata {
    _config.metadata_mode = encryptMetadata ? app::AppConfig::MetadataMode::Encryption
                                            : app::AppConfig::MetadataMode::NoEncryption;
}

- (NSURL *)rootDirectory {
    return [NSURL fileURLWithPath:RLMStringViewToNSString(_config.base_file_path)];
}

- (void)setRootDirectory:(NSURL *)rootDirectory {
    RLMNSStringToStdString(_config.base_file_path, rootDirectory.path);
}

- (RLMSyncTimeoutOptions *)syncTimeouts {
    return [[RLMSyncTimeoutOptions alloc] initWithOptions:_config.sync_client_config.timeouts];
}

- (void)setSyncTimeouts:(RLMSyncTimeoutOptions *)syncTimeouts {
    _config.sync_client_config.timeouts = syncTimeouts->_options;
}

@end

#pragma mark RLMAppSubscriptionToken

@implementation RLMAppSubscriptionToken {
    std::shared_ptr<app::App> _app;
    std::optional<app::App::Token> _token;
}

- (instancetype)initWithApp:(std::shared_ptr<app::App>)app token:(app::App::Token&&)token {
    if (self = [super init]) {
        _app = std::move(app);
        _token = std::move(token);
    }
    return self;
}

- (void)unsubscribe {
    _token.reset();
    _app.reset();
}
@end

#pragma mark RLMApp
@interface RLMApp() <ASAuthorizationControllerDelegate> {
    std::shared_ptr<realm::app::App> _app;
    __weak id<RLMASLoginDelegate> _authorizationDelegate API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0));
}

@end

@implementation RLMApp : NSObject

+ (void)initialize {
    [RLMRealm class];
    // Even though there is nothing to log when the App initialises, we want to
    // be able to log anything happening after this e.g. login/register.
    [RLMLogger class];
}

- (instancetype)initWithApp:(std::shared_ptr<realm::app::App>&&)app config:(RLMAppConfiguration *)config {
    if (self = [super init]) {
        _app = std::move(app);
        _configuration = config;
        _syncManager = [[RLMSyncManager alloc] initWithSyncManager:_app->sync_manager()];
    }
    return self;
}

- (instancetype)initWithConfiguration:(RLMAppConfiguration *)configuration {
    if (self = [super init]) {
        _app = RLMTranslateError([&] {
            return app::App::get_app(app::App::CacheMode::Disabled, configuration.config);
        });
        _configuration = configuration;
        _syncManager = [[RLMSyncManager alloc] initWithSyncManager:_app->sync_manager()];
    }
    return self;
}

static RLMUnfairMutex s_appMutex;
static NSMutableDictionary *s_apps = [NSMutableDictionary new];

+ (NSArray *)allApps {
    std::lock_guard lock(s_appMutex);
    return s_apps.allValues;
}

+ (void)resetAppCache {
    std::lock_guard lock(s_appMutex);
    [s_apps removeAllObjects];
    app::App::clear_cached_apps();
}

+ (instancetype)appWithConfiguration:(RLMAppConfiguration *)configuration {
    std::lock_guard lock(s_appMutex);
    NSString *appId = configuration.appId;
    if (RLMApp *app = s_apps[appId]) {
        return app;
    }
    return s_apps[appId] = [[RLMApp alloc] initWithConfiguration:configuration.copy];
}

+ (instancetype)appWithId:(NSString *)appId configuration:(RLMAppConfiguration *)configuration {
    std::lock_guard lock(s_appMutex);
    if (RLMApp *app = s_apps[appId]) {
        return app;
    }
    configuration = configuration.copy;
    configuration.appId = appId;
    return s_apps[appId] = [[RLMApp alloc] initWithConfiguration:configuration];
}

+ (instancetype)appWithId:(NSString *)appId {
    std::lock_guard lock(s_appMutex);
    if (RLMApp *app = s_apps[appId]) {
        return app;
    }
    auto config = [[RLMAppConfiguration alloc] init];
    config.appId = appId;
    return s_apps[appId] = [[RLMApp alloc] initWithConfiguration:config];
}

+ (RLMApp *_Nullable)cachedAppWithId:(NSString *)appId {
    std::lock_guard lock(s_appMutex);
    return s_apps[appId];
}

- (NSString *)appId {
    return @(_app->config().app_id.c_str());
}

- (std::shared_ptr<realm::app::App>)_realmApp {
    return _app;
}

- (NSDictionary<NSString *, RLMUser *> *)allUsers {
    NSMutableDictionary *buffer = [NSMutableDictionary new];
    for (auto&& user : _app->all_users()) {
        NSString *user_id = @(user->user_id().c_str());
        buffer[user_id] = [[RLMUser alloc] initWithUser:std::move(user)];
    }
    return buffer;
}

- (RLMUser *)currentUser {
    if (auto user = _app->current_user()) {
        return [[RLMUser alloc] initWithUser:user];
    }
    return nil;
}

- (RLMEmailPasswordAuth *)emailPasswordAuth {
    return [[RLMEmailPasswordAuth alloc] initWithApp:_app];
}

- (NSString *)baseUrl {
    return getOptionalString(_app->get_base_url()) ?: RLMStringViewToNSString(_app->default_base_url());
}

- (void)updateBaseURL:(NSString * _Nullable)baseURL completion:(nonnull RLMOptionalErrorBlock)completionHandler {
    auto completion = ^(std::optional<app::AppError> error) {
        if (error) {
            return completionHandler(makeError(*error));
        }

        completionHandler(nil);
    };
    return RLMTranslateError([&] {
        NSString *url = (baseURL ?: @"");
        NSString *newUrl = [url stringByReplacingOccurrencesOfString:@"/" withString:@"" options:0 range:NSMakeRange(url.length-1, 1)];
        return _app->update_base_url(newUrl.UTF8String, completion);
    });
}

- (void)loginWithCredential:(RLMCredentials *)credentials
                 completion:(RLMUserCompletionBlock)completionHandler {
    auto completion = ^(std::shared_ptr<app::User> user, std::optional<app::AppError> error) {
        if (error) {
            return completionHandler(nil, makeError(*error));
        }

        completionHandler([[RLMUser alloc] initWithUser:user], nil);
    };
    return RLMTranslateError([&] {
        return _app->log_in_with_credentials(credentials.appCredentials, completion);
    });
}

- (RLMUser *)switchToUser:(RLMUser *)syncUser {
    RLMTranslateError([&] {
        _app->switch_user(syncUser.user);
    });
    return syncUser;
}

- (RLMPushClient *)pushClientWithServiceName:(NSString *)serviceName {
    return RLMTranslateError([&] {
        return [[RLMPushClient alloc] initWithPushClient:_app->push_notification_client(serviceName.UTF8String)];
    });
}

#pragma mark - Sign In With Apple Extension

- (void)setAuthorizationDelegate:(id<RLMASLoginDelegate>)authorizationDelegate API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0)) {
    _authorizationDelegate = authorizationDelegate;
}

- (id<RLMASLoginDelegate>)authorizationDelegate API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0)) {
    return _authorizationDelegate;
}

- (void)setASAuthorizationControllerDelegateForController:(ASAuthorizationController *)controller API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0)) {
    controller.delegate = self;
}

- (void)authorizationController:(__unused ASAuthorizationController *)controller
   didCompleteWithAuthorization:(ASAuthorization *)authorization API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0)) {
    NSString *jwt = [[NSString alloc] initWithData:((ASAuthorizationAppleIDCredential *)authorization.credential).identityToken
                                             encoding:NSUTF8StringEncoding];
       [self loginWithCredential:[RLMCredentials credentialsWithAppleToken:jwt]
                      completion:^(RLMUser *user, NSError *error) {
           if (user) {
               [self.authorizationDelegate authenticationDidCompleteWithUser:user];
           } else {
               [self.authorizationDelegate authenticationDidFailWithError:error];
           }
       }];
}

- (void)authorizationController:(__unused ASAuthorizationController *)controller
           didCompleteWithError:(NSError *)error API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0)) {
    [self.authorizationDelegate authenticationDidFailWithError:error];
}

- (RLMAppSubscriptionToken *)subscribe:(RLMAppNotificationBlock)block {
    return [[RLMAppSubscriptionToken alloc] initWithApp:_app token:_app->subscribe([block, self] (auto&) {
        block(self);
    })];
}

@end
