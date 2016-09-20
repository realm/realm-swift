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

@class RLMSyncSession, RLMSyncConfiguration;

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

@interface RLMSyncManager : NSObject RLM_SYNC_UNINITIALIZABLE

@property (nullable, nonatomic, copy) RLMSyncErrorReportingBlock errorHandler;

@property (nonatomic) NSString *appID;

/// Whether SSL certificate validation should be disabled. SSL certificate validation is ON by default. Setting this
/// property after at least one synced Realm or standalone Session has been opened is a no-op.
@property (nonatomic) BOOL disableSSLValidation;

/**
 The logging threshold which newly opened synced Realms will use. Defaults to `RLMSyncLogLevelInfo`. Set this before
 any synced Realms are opened.
 */
@property (nonatomic) RLMSyncLogLevel logLevel;

+ (instancetype)sharedManager;

/**
 Given a sync configuration, open and return a standalone session.
 
 If a standalone session was previously opened but encountered a fatal error, attempting to open an equivalent session
 (by using the same configuration) will return `nil`.
 */
- (nullable RLMSyncSession *)sessionForSyncConfiguration:(RLMSyncConfiguration *)config;

NS_ASSUME_NONNULL_END

@end
