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

#import <Realm/RLMMongoDatabase.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@class RLMApp;

/// The `RLMMongoClient` enables reading and writing on a MongoDB database via the Realm Cloud service.
///
/// It provides access to instances of `RLMMongoDatabase`, which in turn provide access to specific
/// `RLMMongoCollection`s that hold your data.
///
/// - Note:
/// Before you can read or write data, a user must log in.
///
/// - SeeAlso:
/// `RLMApp`, `RLMMongoDatabase`, `RLMMongoCollection`
RLM_SWIFT_SENDABLE RLM_FINAL // immutable final class
@interface RLMMongoClient : NSObject

/// The name of the client
@property (nonatomic, readonly) NSString *name;

/// Gets a `RLMMongoDatabase` instance for the given database name.
/// @param name the name of the database to retrieve
- (RLMMongoDatabase *)databaseWithName:(NSString *)name NS_SWIFT_NAME(database(named:));

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
