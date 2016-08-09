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

#import <Foundation/Foundation.h>

#import "RLMServerUtil.h"


// TODO (az-ros): we need the singleton dictionary of logged-in users.
//   --> used for unbinding Realms on global error

@interface RLMServer : NSObject

NS_ASSUME_NONNULL_BEGIN

+ (void)setupWithAppID:(NSString *)appID
              logLevel:(NSUInteger)logLevel
          errorHandler:(nullable RLMErrorReportingBlock)errorHandler;

NS_ASSUME_NONNULL_END

@end
