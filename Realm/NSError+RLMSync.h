////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import <Realm/RLMConstants.h>

RLM_HEADER_AUDIT_BEGIN(nullability)

@class RLMSyncErrorActionToken;

/// NSError category extension providing methods to get data out of Realm's
/// "client reset" error.
@interface NSError (RLMSync)

/**
 Given an appropriate Atlas App Services error, return the token that
 can be passed into `+[RLMSyncSession immediatelyHandleError:]` to
 immediately perform error clean-up work, or nil if the error isn't of
 a type that provides a token.
 */
- (nullable RLMSyncErrorActionToken *)rlmSync_errorActionToken NS_REFINED_FOR_SWIFT;

/**
 Given an Atlas App Services client reset error, return the path where the
 backup copy of the Realm will be placed once the client reset process is
 complete.
 */
- (nullable NSString *)rlmSync_clientResetBackedUpRealmPath NS_SWIFT_UNAVAILABLE("");

@end

RLM_HEADER_AUDIT_END(nullability)
