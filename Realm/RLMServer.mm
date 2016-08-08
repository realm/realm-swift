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

#import "RLMServer_Private.h"

#import "RLMServerUtil.h"
#import "RLMUtil.hpp"

#import <shared_realm.hpp>

@interface RLMServer ()

@property (nonatomic) NSString *appID;

@end

@implementation RLMServer

+ (instancetype)sharedManager {
    static RLMServer *s_sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedManager = [[RLMServer alloc] initPrivate];
    });
    return s_sharedManager;
}

+ (void)setupWithAppID:(NSString *)appID
              logLevel:(NSUInteger)logLevel
          errorHandler:(nullable RLMErrorReportingBlock)errorHandler {
    [RLMServer sharedManager].appID = appID;

    // TODO: set up logger
    NSLog(@"Note that logger integration has not been finished yet, setting a log level will do nothing.");

    RLMErrorReportingBlock callback = [(errorHandler ?: ^(NSError *) { }) copy];

    auto handler = [=](int error_code, std::string message) {
        NSString *nativeMessage = @(message.c_str());
        NSError *error = [NSError errorWithDomain:RLMServerErrorDomain
                                             code:RLMServerInternalError
                                         userInfo:@{@"description": nativeMessage,
                                                    @"error": @(error_code)}];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(error);
        });
    };

    realm::Realm::set_up_sync_client(handler, nullptr);
}

+ (NSString *)appID {
    NSString *theAppID = [RLMServer sharedManager].appID;
    if (!theAppID) {
        @throw RLMException(@"RLMServer's setup method must be called before Realms with a server URL can be opened.");
    }
    return theAppID;
}

- (instancetype)initPrivate {
    if (self = [super init]) {
        // TODO: any additional setup goes here
        return self;
    }
    return nil;
}

@end
