////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

#import "RLMChildProcessEnvironment.h"

@implementation RLMChildProcessEnvironment

- (instancetype)init {
    if (self = [super init]) {
        _appIds = @[];
        _identifier = 0;
        _shouldCleanUpOnTermination = YES;
    }

    return self;
}

- (instancetype)initWithAppIds:(NSArray<NSString *> *)appIds
                         email:(NSString *)email
                      password:(NSString *)password
                     identifer:(NSInteger)identifier
    shouldCleanUpOnTermination:(BOOL)shouldCleanUpOnTermination {
    if (self = [super init]) {
        _appIds = appIds ?: @[];
        _email = email;
        _password = password;
        _identifier = identifier;
        _shouldCleanUpOnTermination = shouldCleanUpOnTermination;
    }

    return self;
}

- (NSString *)_appId {
    return self.appIds == nil ? nil : [self.appIds firstObject];
}

- (NSDictionary<NSString *,NSString *> *)dictionaryValue {
    NSMutableDictionary<NSString *, NSString *> *environment = [NSMutableDictionary new];
    if ([self.appIds count] > 0) {
        environment[@"RLMParentAppId"] = [self.appIds firstObject];
        environment[@"RLMParentAppIds"] = [self.appIds componentsJoinedByString:@","];
    }
    if (self.email != nil) {
        environment[@"RLMChildEmail"] = self.email;
    }
    if (self.password != nil) {
        environment[@"RLMChildPassword"] = self.password;
    }
    environment[@"RLMChildIdentifier"] = [@(self.identifier) stringValue];
    environment[@"RLMChildShouldCleanUpOnTermination"] = self.shouldCleanUpOnTermination ? @"YES" : @"NO";

    return environment;
}

+ (RLMChildProcessEnvironment *)current {
    NSDictionary<NSString *, NSString *> *environment = [NSProcessInfo processInfo].environment;
    NSString *shouldCleanUpOnTermination = [environment objectForKey:@"RLMChildShouldCleanUpOnTermination"] ?: @"YES";
    NSString *identifier = [environment objectForKey:@"RLMChildIdentifier"] ?: @"0";
    NSString *appIds = environment[@"RLMParentAppIds"] ?: @"";

    return [[RLMChildProcessEnvironment new] initWithAppIds:[appIds componentsSeparatedByString:@","]
                                                      email:environment[@"RLMChildEmail"]
                                                   password:environment[@"RLMChildPassword"]
                                                  identifer:[identifier intValue]
                                 shouldCleanUpOnTermination:[shouldCleanUpOnTermination boolValue]];
}

@end
