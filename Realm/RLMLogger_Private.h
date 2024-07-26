////////////////////////////////////////////////////////////////////////////
//
// Copyright 2023 Realm Inc.
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

#import <Realm/RLMLogger.h>
#import <Realm/RLMConstants.h>

RLM_HEADER_AUDIT_BEGIN(nullability)

@interface RLMLogger()

#pragma mark Testing

/**
Gets all the categories from Core. This is to be used for testing purposes only.
 */
+ (NSArray<NSString *> *)allCategories;

/// Log a message via core's default logger for testing purposes
FOUNDATION_EXTERN void RLMTestLog(RLMLogCategory category, RLMLogLevel level, const char *message);

@end

#pragma mark Internal SDK logging

/// Logger function for operations within the SDK, to be used from obj-c code.
void RLMLog(RLMLogLevel level, NSString *format, ...);

// Helper for the Swift Logger.log() function
FOUNDATION_EXTERN void RLMLogRaw(RLMLogLevel level, NSString *message);

RLM_HEADER_AUDIT_END(nullability)
