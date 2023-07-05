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

#import <Realm/RLMConstants.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@class RLMMongoCollection;

/// The `RLMMongoDatabase` represents a MongoDB database, which holds a group
/// of collections that contain your data.
///
/// It can be retrieved from the `RLMMongoClient`.
///
/// Use it to get `RLMMongoCollection`s for reading and writing data.
///
/// - Note:
/// Before you can read or write data, a user must log in`.
///
/// - SeeAlso:
/// `RLMMongoClient`, `RLMMongoCollection`
RLM_SWIFT_SENDABLE RLM_FINAL // immutable final class
@interface RLMMongoDatabase : NSObject

/// The name of this database
@property (nonatomic, readonly) NSString *name;

/// Gets a collection.
/// @param name The name of the collection to return
/// @returns The collection
- (RLMMongoCollection *)collectionWithName:(NSString *)name;
// NEXT-MAJOR: NS_SWIFT_NAME(collection(named:))

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
