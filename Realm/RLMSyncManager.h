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

#import "RLMSyncUtil.h"

@interface RLMSyncManager : NSObject

/**
 Whether or not the Realm Sync manager has been configured.
 */
@property (nonatomic, readonly) BOOL configured;

/**
 The Realm Sync application ID for the current application.
 */
@property (nonatomic, readonly) RLMSyncAppID appID;

/**
 Configure the Realm Sync manager with application-wide configuration options. Call this method before calling any other
 Realm Sync APIs. Do not call this method if `configured` is `YES`.
 */
+ (void)configureWithAppID:(RLMSyncAppID)appID;

+ (instancetype)sharedManager;

@end
