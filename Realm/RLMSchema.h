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
#import <Realm/RLMObjectSchema.h>

/**---------------------------------------------------------------------------------------
 *  @name Realm Schema
 * ---------------------------------------------------------------------------------------
 */
@interface RLMSchema : NSObject

/**
 An NSArray containing RLMObjectSchema for all object types in this Realm. Meant
 to be used during migrations for dynamic introspection.
 
 @see       RLMObjectSchema
 */
@property (nonatomic, readonly) NSArray *objectSchema;

/**
 Returns an RLMObjectSchema for the given class in this Realm.
 
 @param className   The object class name.
 @return            RLMObjectSchema for the given class in this Realm.
 
 @see               RLMObjectSchema
 */
- (RLMObjectSchema *)schemaForObject:(NSString *)className;

/**
 Lookup an RLMObjectSchema for the given class in this Realm.
 
 @param className   The object class name.
 @return            RLMObjectSchema for the given class in this Realm.
 
 @see               RLMObjectSchema
 */
- (RLMObjectSchema *)objectForKeyedSubscript:(id <NSCopying>)className;

@end


/**---------------------------------------------------------------------------------------
 *  @name Schema Migration Methods
 * ---------------------------------------------------------------------------------------
 */
@interface RLMSchema (Migrations)

/**
 Delete an object class during a migration.
 
 @warning   It's only valid to call this method during a migration. You are required to call 
 this or <code>renameObjectClass:to:</code> when removing an ObjectClass from a Schema.
 
 @param objectClassName The name of the object class to delete from the Schema.
 */
- (void)deleteObjectClass:(NSString *)objectClassName;

/**
 Rename an object class during a migration. You are required to call
 this or <code>deleteObjectClass:</code> when removing an ObjectClass from a Schema.
 
 @warning   It's only valid to call this method during a migration.
 
 @param objectClassName     The name of the object class to rename.
 @param newObjectClassName  The new object class name.
 */
- (void)renameObjectClass:(NSString *)objectClassName to:(NSString *)newObjectClassName;

/**
 Add an object class during a migration.
 
 @warning   It's only valid to call this method during a migration.
 
 @param objectClassName The name of the object class to rename.
 @param properties      An array of properties to add to the new object type.
 */
- (void)addObjectClass:(NSString *)objectClassName properties:(NSArray *)properties;

@end

