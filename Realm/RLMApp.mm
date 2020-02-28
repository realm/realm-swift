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
#import "RLMAppCredentials.h"
#import "RLMAppCredentials_Private.h"
#import "RLMSyncUser_Private.hpp"
#import "RLMNetworkClient.h"

using namespace realm;

@implementation RLMAppConfiguration
@end

@interface RLMApp() {
    std::shared_ptr<app::App> _app;
    NSMutableDictionary<NSNumber *, id>* _blocks;
    NSNumber *_idx;
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
        Optional<app::App::Config> boundConfiguration = util::none;
        CocoaNetworkTransport::transport = [RLMNetworkTransport new];
        if (configuration) {
            boundConfiguration = app::App::Config();
            boundConfiguration->base_url = util::Optional<std::string>([configuration.baseURL cStringUsingEncoding:NSUTF8StringEncoding]);
            if (configuration.transport) {
                CocoaNetworkTransport::transport = configuration.transport;
            }
        }
        std::unique_ptr<app::GenericNetworkTransport> (*factory)() = []{
            return std::unique_ptr<app::GenericNetworkTransport>(new CocoaNetworkTransport);
        };
        app::GenericNetworkTransport::set_network_transport_factory(factory);
        self->_app = app::App::app([appId cStringUsingEncoding: NSUTF8StringEncoding],
                                   boundConfiguration);
        return self;
    }
    return nil;
}

+(instancetype) app:(NSString *) appId configuration:(RLMAppConfiguration *)configuration {
    return [[RLMApp alloc] initWithAppId:appId configuration:configuration];
}

static std::function<void (std::shared_ptr<SyncUser>, std::unique_ptr<app::error::AppError>)> block;

-(void) loginWithCredential:(RLMAppCredentials *)credentials
          completionHandler:(RLMUserCompletionBlock)completionHandler {
    self->_app->login_with_credentials(credentials.appCredentials, ^(std::shared_ptr<SyncUser> user, std::unique_ptr<app::error::AppError> error) {
        if (error && error->code()) {
            return completionHandler(nil,
                                     [[NSError alloc] initWithDomain:RLMSyncAuthErrorDomain
                                                                code:error->code()
                                                            userInfo:
                                      @{@(error->category().data()): @(error->message().data())}]);
        }

        completionHandler([[RLMSyncUser alloc] initWithSyncUser:user], nil);
    });
}

@end
