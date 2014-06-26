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

////////////////////////////////////////////////////////////////////////////
// WARNING: PRIVATE USE ONLY. DO NOT USE.
////////////////////////////////////////////////////////////////////////////

#import "RLMArray.h"

@interface RLMArray ()

// Also defined in RLMArray_Private.hpp
- (instancetype)initWithObjectClassName:(NSString *)objectClassName;

@end

#import "RLMObjectSchema.h"

@interface RLMObjectSchema ()

@property (nonatomic, readwrite) NSArray *properties;

// Designated initializer
- (instancetype)initWithClassName:(NSString *)objectClassName properties:(NSArray *)properties;

@end

#import "RLMProperty.h"

@interface RLMProperty ()

@property (nonatomic, readwrite, assign) RLMPropertyAttributes attributes;

@property (nonatomic, readwrite, copy) NSString *objectClassName;

// Designated initializer
- (instancetype)initWithName:(NSString *)name type:(RLMPropertyType)type column:(NSUInteger)column;

@end
