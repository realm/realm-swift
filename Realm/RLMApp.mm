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

using namespace realm;

@interface RLMApp() {
    std::shared_ptr<app::App> _app;
}
@end

@implementation RLMApp : NSObject

-(instancetype) initWithAppId:(NSString *) appId configuration:(RLMAppConfiguration *)configuration {
    if (self = [super init]) {
        Optional<app::App::Config> boundConfiguration = util::none;
        if (configuration) {
            boundConfiguration = app::App::Config();
            boundConfiguration->base_url = util::Optional<std::string>([configuration.baseURL cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        self->_app = app::App::app([appId cStringUsingEncoding: NSUTF8StringEncoding],
                                   boundConfiguration);
        return self;
    }
    return nil;
}

+(instancetype) app:(NSString *) appId configuration:(RLMAppConfiguration *)configuration {
    return [[RLMApp alloc] initWithAppId:appId configuration:configuration];
}


-(void) loginWithCredential:(RLMAppCredentials *)credentials
          completionHandler:(RLMUserCompletionBlock)completionHandler {
    self->_app->login_with_credentials(credentials.appCredentials,
                                       ^(std::shared_ptr<SyncUser> user, std::unique_ptr<app::error::AppError> error) {
        if (error->code()) {
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
