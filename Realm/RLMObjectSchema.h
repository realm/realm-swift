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
#import <Realm/RLMProperty.h>

/**---------------------------------------------------------------------------------------
 *  @name Object Schema
 * ---------------------------------------------------------------------------------------
 */
@interface RLMObjectSchema : NSObject

/**
 Array of persisted properties for an object.
 */
@property (nonatomic, readonly, copy) NSArray *properties;

/**
 The name of the class this schema describes.
 */
@property (nonatomic, readonly) NSString *className;

/**
 Lookup a property object by name.
 
 @param propertyName The properties name.
 
 @return    RLMProperty object or nil if there is no property with the given name.
 */
- (RLMProperty *)objectForKeyedSubscript:(id <NSCopying>)propertyName;

@end


/**---------------------------------------------------------------------------------------
 *  @name Object Schema Migration
 * ---------------------------------------------------------------------------------------
 */
@interface RLMObjectSchema (Migrations)

/**
 Delete an object's property during a migration. You are required to call this or
 <code>renameProperty:to:</code> when an existing property is no longer present in the 
 current ObjectSchema.
 
 @warning   It's only valid to call this method during a migration.
 
 @param propertyName The name of the property to delete from the global schema.
 */
- (void)deleteProperty:(NSString *)propertyName;

/**
 Rename an object's property during a migration. You are required to call this or
 <code>deleteProperty:</code> when an existing property is no longer present in the 
 current ObjectSchema.
 
 @warning   It's only valid to call this method during a migration.
 
 @param propertyName    The name of the property to rename.
 @param newPropertyName The new name of the property.
 */
- (void)renameProperty:(NSString *)propertyName to:(NSString *)newPropertyName;

/**
 Add a property during a migration. This is an optional method that can be used to populate
 added properties during migrations.
 
 @warning   It's only valid to call this method during a migration.
 @warning   Any added properies must match the object schema defined in the 
            corresponding object interface at the end of a migration.

 @param property    The property to add.
 */
- (void)addProperty:(RLMProperty *)property;

@end


