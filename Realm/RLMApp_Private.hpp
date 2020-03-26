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
#import "sync/app.hpp"

static NSMutableDictionary<NSString *, RLMApp *> *apps= [NSMutableDictionary new];

@interface RLMApp ()

- (realm::app::App)_realmApp;

/**
Convert an object store AppError to an NSError.
*/
- (NSError*)AppErrorToNSError:(const realm::app::AppError&)appError;

- (void)handleResponse:(Optional<realm::app::AppError>)error
            completion:(RLMOptionalErrorBlock)completion;

@end
