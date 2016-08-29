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

@class RLMSyncSession;

typedef NS_ENUM(NSUInteger, RLMSyncLogLevel) {
    RLMSyncLogLevelOff,
    RLMSyncLogLevelFatal,
    RLMSyncLogLevelError,
    RLMSyncLogLevelWarn,
    RLMSyncLogLevelInfo,
    RLMSyncLogLevelDetail,
    RLMSyncLogLevelDebug,
    RLMSyncLogLevelTrace,
    RLMSyncLogLevelAll
};

NS_ASSUME_NONNULL_BEGIN

typedef void(^RLMSyncErrorReportingBlock)(NSError *, RLMSyncSession * _Nullable);

@interface RLMSyncManager : NSObject RLMSYNC_UNINITIALIZABLE

@property (nullable, nonatomic, copy) RLMSyncErrorReportingBlock errorHandler;

@property (nonatomic) NSString *appID;

/**
 The logging threshold which newly opened synced Realms will use. Defaults to `RLMSyncLogLevelInfo`. Set this before
 any synced Realms are opened.
 */
@property (nonatomic) RLMSyncLogLevel logLevel;

+ (instancetype)sharedManager;

NS_ASSUME_NONNULL_END

@end
