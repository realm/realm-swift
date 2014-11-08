////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import "RLMRealm_Private.hpp"
#import "RLMObject.h"
#import "RLMObjectSchema.h"
#import <tightdb/row.hpp>

// RLMObject accessor and read/write realm
@interface RLMObject () {
  @public
    tightdb::Row _row;
    RLMRealm *_realm;
}

- (instancetype)initWithRealm:(RLMRealm *)realm
                       schema:(RLMObjectSchema *)schema
                defaultValues:(BOOL)useDefaults;

// namespace properties to prevent collision with user properties
@property (nonatomic, readwrite) RLMRealm *realm;
@property (nonatomic, readwrite) RLMObjectSchema *objectSchema;

// shared schema for this class
+ (RLMObjectSchema *)sharedSchema;

@end

