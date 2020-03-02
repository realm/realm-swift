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

@implementation RLMAppConfiguration

- (instancetype)initWithBaseURL:(NSString *)baseURL
                      transport:(id<RLMNetworkTransporting>)transport
                   localAppName:(NSString *)localAppName
                localAppVersion:(NSString *)localAppVersion {
    return [self initWithBaseURL:baseURL
                       transport:transport
                    localAppName:localAppName
                 localAppVersion:localAppVersion
         defaultRequestTimeoutMS:6000];
}

-(instancetype) initWithBaseURL:(NSString * _Nullable) baseURL
                      transport:(id<RLMNetworkTransporting> _Nullable)transport
                   localAppName:(NSString * _Nullable)localAppName
                localAppVersion:(NSString * _Nullable)localAppVersion
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

/// A map of ObjectStore HTTP methods to RLMHTTPMethods
std::map<app::HttpMethod, RLMHTTPMethod> HttpMethod_toRLMHTTPMethod = {
    {app::HttpMethod::get, GET},
    {app::HttpMethod::post, POST},
    {app::HttpMethod::put, PUT},
    {app::HttpMethod::patch, PATCH},
    {app::HttpMethod::del, DELETE}
};

/// Internal transport struct to bridge RLMNetworkingTransporting to the GenericNetworkTransport.
struct CocoaNetworkTransport : public realm::app::GenericNetworkTransport {
    static id <RLMNetworkTransporting> transport;

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
        rlmRequest.method = HttpMethod_toRLMHTTPMethod[request.method];
        rlmRequest.timeoutMS = request.timeout_ms;

        // Send the request through to the Cocoa level transport
        [transport sendRequestToServer:rlmRequest completion:^(RLMResponse * _Nonnull response) {
            std::map<std::string, std::string> bridgingHeaders;
            for (id key in response.headers) {
                bridgingHeaders[[key cStringUsingEncoding:NSUTF8StringEncoding]] = [response.headers[key] cStringUsingEncoding:NSUTF8StringEncoding];
            }

            // Convert the RLMResponse to an app:Response and pass downstream to
            // the object store
            completion(app::Response {
                .body = [response.body cStringUsingEncoding:NSUTF8StringEncoding],
                .headers = bridgingHeaders,
                .http_status_code = static_cast<int>(response.httpStatusCode),
                .custom_status_code = static_cast<int>(response.customStatusCode)
            });
        }];
    }
};

id <RLMNetworkTransporting> CocoaNetworkTransport::transport = [RLMNetworkTransport new];

@implementation RLMApp : NSObject

+(NSMutableDictionary<NSString *, RLMApp*>*)apps {
    static NSMutableDictionary<NSString *, RLMApp*>* _apps = nil;
    if (!_apps) {
        _apps = [NSMutableDictionary new];
    }
    return _apps;
}

-(instancetype) initWithAppId:(NSString *) appId configuration:(RLMAppConfiguration *)configuration {
    if (self = [super init]) {
        app::App::Config boundConfiguration = {
            .app_id = [appId cStringUsingEncoding:NSUTF8StringEncoding]
        };
        boundConfiguration.transport_generator = []{
            return std::unique_ptr<app::GenericNetworkTransport>(new CocoaNetworkTransport);
        };
        if (configuration) {
            if (configuration.baseURL) {
                boundConfiguration.base_url = util::Optional<std::string>([configuration.baseURL cStringUsingEncoding:NSUTF8StringEncoding]);
            }
            if (configuration.transport) {
                CocoaNetworkTransport::transport = configuration.transport;
            }
            boundConfiguration.local_app_name = std::string([configuration.localAppName cStringUsingEncoding:NSUTF8StringEncoding]);
            boundConfiguration.local_app_version = std::string([configuration.localAppVersion cStringUsingEncoding:NSUTF8StringEncoding]);
            boundConfiguration.default_request_timeout_ms = (uint64_t)configuration.defaultRequestTimeoutMS;
        }
        self->_app = std::make_shared<app::App>(boundConfiguration);
        [[RLMApp apps] setValue:self forKey:appId];
        return self;
    }
    return nil;
}

+(instancetype) app:(NSString *) appId configuration:(RLMAppConfiguration *)configuration {
    return [[RLMApp alloc] initWithAppId:appId configuration:configuration];
}

- (NSDictionary *)allUsers {
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
static NSError* RLMAppErrorToNSError(const app::AppError& appError) {
    return [[NSError alloc] initWithDomain:@(appError.error_code.category().name())
                                      code:appError.error_code.value()
                                  userInfo:@{
        @(appError.error_code.category().name()) : @(appError.error_code.message().data())
    }];
}

-(void) loginWithCredential:(RLMAppCredentials *)credentials
          completionHandler:(RLMUserCompletionBlock)completionHandler {
    self->_app->login_with_credentials(*credentials.appCredentials, ^(std::shared_ptr<SyncUser> user, util::Optional<app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(nil, RLMAppErrorToNSError(*error));
        }

        completionHandler([[RLMSyncUser alloc] initWithSyncUser:user], nil);
    });
}

@end
