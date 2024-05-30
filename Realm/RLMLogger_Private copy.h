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

/**
 Log a message to the supplied level.

 @param logLevel The log level for the message.
 @param message The message to log.
 */
- (void)logWithLevel:(RLMLogLevel)logLevel message:(NSString *)message, ... NS_SWIFT_UNAVAILABLE("");

/**
 Log a message to the supplied level.

 @param logLevel The log level for the message.
 @param category The log category for the message.
 @param message The message to log.
 */
- (void)logWithLevel:(RLMLogLevel)logLevel category:(NSString *)category message:(NSString *)message;

/**
Gets all the categories from Core. This is to be used for testing purposes only.
 */
+ (NSArray<NSString *> *)getAllCategories;

+ (RLMLogCategory)categoryFromString:(NSString *)string;
@end

RLM_HEADER_AUDIT_END(nullability)
