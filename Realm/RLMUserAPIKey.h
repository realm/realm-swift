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

#import <Foundation/Foundation.h>
#import <Realm/RLMObjectId.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

/// UserAPIKey model for APIKeys recevied from the server.
RLM_SWIFT_SENDABLE RLM_FINAL // immutable final class
@interface RLMUserAPIKey : NSObject

/// Indicates if the API key is disabled or not
@property (nonatomic, readonly) BOOL disabled;

/// The name of the key.
@property (nonatomic, readonly) NSString *name;

/// The actual key. Will only be included in
/// the response when an API key is first created.
@property (nonatomic, readonly, nullable) NSString *key;

/// The ObjectId of the API key
@property (nonatomic, readonly) RLMObjectId *objectId NS_REFINED_FOR_SWIFT;

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
