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

#import "RLMSync_Private.h"

#import "RLMSyncUtil.h"
#import "RLMUtil.hpp"

#import <shared_realm.hpp>

@interface RLMSync ()

@property (nonatomic) RLMSyncAppID appID;

@end

@implementation RLMSync

+ (instancetype)sharedManager {
    static RLMSync *s_sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedManager = [[RLMSync alloc] initPrivate];
    });
    return s_sharedManager;
}

+ (void)setupWithAppID:(RLMSyncAppID)appID
              logLevel:(NSUInteger)logLevel
          errorHandler:(nullable RLMErrorReportingBlock)errorHandler {
    [RLMSync sharedManager].appID = appID;

    // TODO: set up logger
    NSLog(@"Note that logger integration has not been finished yet, setting a log level will do nothing.");

    RLMErrorReportingBlock callback = [(errorHandler ?: ^(NSError *) { }) copy];

    auto handler = [=](int error_code, std::string message) {
        NSString *nativeMessage = @(message.c_str());
        NSError *error = [NSError errorWithDomain:@"io.realm.sync.client"
                                             code:error_code
                                         userInfo:@{@"description": nativeMessage}];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(error);
        });
    };

    realm::Realm::setup_sync_client(handler, nullptr);
}

+ (RLMSyncAppID)appID {
    RLMSyncAppID theAppID = [RLMSync sharedManager].appID;
    if (!theAppID) {
        @throw RLMException(@"RLMSync's setup method must be called before synced Realms can be opened.");
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
