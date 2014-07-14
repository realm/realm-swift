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

#import <Foundation/Foundation.h>
#import "RLMObjectSchema.h"

/**---------------------------------------------------------------------------------------
 *  @name Realm Schema
 * ---------------------------------------------------------------------------------------
 */
@interface RLMSchema : NSObject<NSCopying>

/**
 An NSArray containing RLMObjectSchema for all object types in this Realm. Meant
 to be used during migrations for dynamic introspection.
 
 @see       RLMObjectSchema
 */
@property (nonatomic, readonly, copy) NSArray *objectSchema;

/**
 Returns an RLMObjectSchema for the given class in this RLMSchema.
 
 @param className   The object class name.
 @return            RLMObjectSchema for the given class in this RLMSchema.
 
 @see               RLMObjectSchema
 */
- (RLMObjectSchema *)schemaForClassName:(NSString *)className;

/**
 Lookup an RLMObjectSchema for the given class in this Realm. Throws if there
 is no object of type className in this RLMSchema instance.
 
 @param className   The object class name.
 @return            RLMObjectSchema for the given class in this Realm.
 
 @see               RLMObjectSchema
 */
- (RLMObjectSchema *)objectForKeyedSubscript:(id <NSCopying>)className;

@end

