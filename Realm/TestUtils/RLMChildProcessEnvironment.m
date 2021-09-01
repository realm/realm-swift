//
//  RLMChildProcessEnvironment.m
//  RLMChildProcessEnvironment
//
//  Created by Jason Flax on 01/09/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
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
    NSString *shouldCleanUpOnTermination = [[NSProcessInfo processInfo].environment objectForKey:@"RLMChildShouldCleanUpOnTermination"] ?: @"YES";
    NSString *identifier = [[NSProcessInfo processInfo].environment objectForKey:@"RLMChildIdentifier"] ?: @"0";
    NSString *appIds = [NSProcessInfo processInfo].environment[@"RLMParentAppIds"] ?: @"";

    return [[RLMChildProcessEnvironment new] initWithAppIds: [appIds componentsSeparatedByString:@","] email:[NSProcessInfo processInfo].environment[@"RLMChildEmail"] password:[NSProcessInfo processInfo].environment[@"RLMChildPassword"] identifer:[identifier intValue] shouldCleanUpOnTermination:[shouldCleanUpOnTermination boolValue]];
}

@end
