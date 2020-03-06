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

#import <Foundation/Foundation.h>
#import "RLMApp_Private.hpp"

#import "RLMAppCredentials_Private.hpp"
#import "RLMSyncUser_Private.hpp"
#import "RLMSyncManager_Private.h"

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
    private:
        id<RLMNetworkTransport> m_transport;
    };
}

@implementation RLMAppConfiguration

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

- (instancetype)initWithBaseURL:(nullable NSString *) baseURL
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
        return self;
    }
    return nil;
}
@end

@interface RLMApp() {
    realm::app::App _app;
}
@end

@implementation RLMApp : NSObject

- (instancetype)initWithAppId:(NSString *)appId configuration:(RLMAppConfiguration *)configuration {
    if (self = [super init]) {
        app::App::Config boundConfiguration = {
            .app_id = appId.UTF8String
        };
        boundConfiguration.transport_generator = [configuration]{
            return std::make_unique<CocoaNetworkTransport>([RLMNetworkTransport new]);
        };
        if (configuration) {
            if (configuration.baseURL) {
                boundConfiguration.base_url = util::Optional<std::string>(configuration.baseURL.UTF8String);
            }
            if (configuration.transport) {
                boundConfiguration.transport_generator = [configuration]{
                    return std::make_unique<CocoaNetworkTransport>(configuration.transport);
                };
            }
            boundConfiguration.local_app_name = std::string(configuration.localAppName.UTF8String);
            boundConfiguration.local_app_version = std::string(configuration.localAppVersion.UTF8String);
            boundConfiguration.default_request_timeout_ms = (uint64_t)configuration.defaultRequestTimeoutMS;
        }
        _app = realm::app::App(boundConfiguration);
        apps[appId] = self;
        return self;
    }
    return nil;
}

+ (instancetype)app:(NSString *)appId configuration:(RLMAppConfiguration *)configuration {
    return [[RLMApp alloc] initWithAppId:appId configuration:configuration];
}

- (NSDictionary<NSString *, RLMSyncUser *> *)allUsers {
    NSArray *allUsers = [[RLMSyncManager sharedManager] _allUsers];
    return [NSDictionary dictionaryWithObjects:allUsers
                                       forKeys:[allUsers valueForKey:@"identity"]];
}

- (RLMSyncUser *)currentUser {
    return [[RLMSyncManager sharedManager] _currentUser];
}

/**
 Convert an object store AppError to an NSError.
 */
static NSError* AppErrorToNSError(const app::AppError& appError) {
    return [[NSError alloc] initWithDomain:@(appError.error_code.category().name())
                                      code:appError.error_code.value()
                                  userInfo:@{
                                      @(appError.error_code.category().name()) : @(appError.error_code.message().data())
                                  }];
}

- (void)loginWithCredential:(RLMAppCredentials *)credentials
          completionHandler:(RLMUserCompletionBlock)completionHandler {
    _app.login_with_credentials(credentials.appCredentials, ^(std::shared_ptr<SyncUser> user, util::Optional<app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(nil, AppErrorToNSError(*error));
        }

        completionHandler([[RLMSyncUser alloc] initWithSyncUser:user], nil);
    });
}

@end
