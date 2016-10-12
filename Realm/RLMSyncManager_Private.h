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

#import "RLMSyncManager.h"

#import "RLMSyncUtil_Private.h"

typedef NS_ENUM(NSUInteger, RLMSyncSessionErrorKind) {
    RLMSyncSessionErrorKindDebug,
    RLMSyncSessionErrorKindSessionFatal,
    RLMSyncSessionErrorKindAccessDenied,
    RLMSyncSessionErrorKindUserFatal,
};

@class RLMSyncUser, RLMSyncConfiguration;

// All private API methods are threadsafe and synchronized, unless denoted otherwise. Since they are expected to be
// called very infrequently, this should pose no issues.

NS_ASSUME_NONNULL_BEGIN

@interface RLMSyncManager ()

@property (nullable, nonatomic, copy) RLMSyncBasicErrorReportingBlock sessionCompletionNotifier;

/**
 Given a sync configuration, open and return a standalone session.

 If a standalone session was previously opened but encountered a fatal error, attempting to open an equivalent session
 (by using the same configuration) will return `nil`.
 */
- (nullable RLMSyncSession *)sessionForSyncConfiguration:(RLMSyncConfiguration *)config NS_UNAVAILABLE;

- (void)_fireError:(NSError *)error;

- (void)_fireErrorWithCode:(int)errorCode
                   message:(NSString *)message
                   session:(RLMSyncSession *)session
                errorClass:(RLMSyncSessionErrorKind)errorClass;

- (NSArray<RLMSyncUser *> *)_allUsers;

NS_ASSUME_NONNULL_END

@end
