//
//  RLMApp.m
//  Realm
//
//  Created by Jason Flax on 27/02/2020.
//  Copyright © 2020 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLMApp.h"

#import "sync/app.hpp"
#import "RLMAppCredentials_Private.hpp"
#import "RLMSyncUser_Private.hpp"
#import "RLMNetworkClient.h"

using namespace realm;

@implementation RLMAppConfiguration
@end

@interface RLMApp() {
    std::shared_ptr<app::App> _app;
}
@end

std::map<app::HttpMethod, RLMHTTPMethod> HttpMethod_toRLMHTTPMethod = {
    {app::HttpMethod::get, GET},
    {app::HttpMethod::post, POST},
    {app::HttpMethod::put, PUT},
    {app::HttpMethod::patch, PATCH},
    {app::HttpMethod::del, DELETE}
};

struct CocoaNetworkTransport : public realm::app::GenericNetworkTransport {
    static id <RLMNetworkTransporting> transport;

    void send_request_to_server(const app::Request request,
                                std::function<void(const app::Response)> completion) override {
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
        [transport sendRequestToServer:rlmRequest completion:^(RLMResponse * _Nonnull response) {
            std::map<std::string, std::string> bridgingHeaders;
            for (id key in response.headers) {
                bridgingHeaders[[key cStringUsingEncoding:NSUTF8StringEncoding]] = [response.headers[key] cStringUsingEncoding:NSUTF8StringEncoding];
            }
            @autoreleasepool {
            completion(app::Response {
                .body = [response.body cStringUsingEncoding:NSUTF8StringEncoding],
                .headers = bridgingHeaders,
                .http_status_code = static_cast<int>(response.httpStatusCode),
                .custom_status_code = static_cast<int>(response.customStatusCode)
            });
            }
        }];
    }
};

id <RLMNetworkTransporting> CocoaNetworkTransport::transport = [RLMNetworkTransport new];

@implementation RLMApp : NSObject

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
        }
        self->_app = std::make_shared<app::App>(boundConfiguration);
        return self;
    }
    return nil;
}

+(instancetype) app:(NSString *) appId configuration:(RLMAppConfiguration *)configuration {
    return [[RLMApp alloc] initWithAppId:appId configuration:configuration];
}

static NSError* appErrorToNSError(const app::AppError& appError) {
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
            return completionHandler(nil, appErrorToNSError(*error));
        }

        completionHandler([[RLMSyncUser alloc] initWithSyncUser:user], nil);
    });
}

@end
