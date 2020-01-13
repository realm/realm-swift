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

#import "RLMApp.h"
#import "RLMAuth.h"
#import "RLMAuth_Private.h"
#import "RLMFunctions.h"
#import "RLMFunctions_Private.h"
#import "RLMRealmConfiguration.h"

@implementation RLMApp {
    NSString *_appID;
}

static NSString *defaultBaseURL = @"https://stitch.mongodb.com";
static NSString *baseRoute = @"/api/client/v2.0";
static NSMutableDictionary<NSString *, RLMApp *> *_allApps;

- (instancetype)initWithAppID:(NSString *)appID {
    if (!(self = [super init]))
        return nil;

    _appID = appID;

    NSString *appRoute = [[defaultBaseURL stringByAppendingString:baseRoute] stringByAppendingString:@"/app/%@"];

    _auth = [[RLMAuth alloc] initWithRoute:[[NSURL alloc] initWithString:
                                            [[NSString alloc] initWithFormat:[appRoute stringByAppendingString:@"/auth"],
                                             appID]]];

    _functions = [[RLMFunctions alloc] initWithApp: self
                                             route: [[NSURL alloc] initWithString: [[NSString alloc] initWithFormat:appRoute, appID]]];
    return self;
}

+ (NSDictionary<NSString *,RLMApp *> *)allApps {
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        _allApps = [NSMutableDictionary new];
    });

    return _allApps;
}

+ (instancetype)app:(NSString *)appID {
    if (auto app = [RLMApp.allApps valueForKey:appID]) {
        return app;
    }

    RLMApp *app = [[RLMApp alloc] initWithAppID: appID];
    [((NSMutableDictionary *)RLMApp.allApps) setObject:app forKey:appID];
    return app;
}

- (RLMRealmConfiguration *)configuration {
    NSURL *url = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    url = [url URLByAppendingPathComponent:_appID];
    auto config = [[RLMRealmConfiguration alloc] init];
    config.fileURL = url;
    return config;
}
@end
