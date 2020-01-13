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
#import "RLMFunctions.h"
#import "RLMNetworkClient.h"
#import "RLMAuth.h"
#import "RLMSyncUser.h"

@implementation RLMFunctions {
    RLMApp *_app;
    NSURL *_route;
}

- (instancetype) initWithApp:(RLMApp *)app
                       route:(NSURL *)route {
    if (!(self = [super init]))
        return nil;
    _app = app;
    _route = route;
    return self;
}

- (void)callFunction:(NSString *)name
           arguments:(NSArray *)arguments
             timeout:(NSTimeInterval)timeout
       callbackQueue:(dispatch_queue_t)callbackQueue
        onCompletion:(RLMFunctionCompletionBlock)completion {
    NSDictionary *json = @{
        @"name": name,
        @"arguments": arguments,
        @"token": [[_app auth] currentUser].accessToken,
    };

    [RLMAppFunctionEndpoint sendRequestToServer:_route
                                           JSON:json
                                        timeout:timeout
                                     completion:^(NSError *error, NSData *data) {
        dispatch_async(callbackQueue, ^{
            completion(data, error);
        });
    }];
}

@end
