//
//  RLMProviderClient.m
//  Realm
//
//  Created by Lee Maguire on 24/03/2020.
//  Copyright © 2020 Realm. All rights reserved.
//

#import "RLMProviderClient.h"

@implementation RLMProviderClient

- (instancetype)init:(RLMApp *)app {
    self = [super init];
    if (self) {
        _app = app;
    }
    return self;
}

@end
