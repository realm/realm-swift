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

@class RLMSchema;
@class RLMArray;

/**---------------------------------------------------------------------------------------
 *  @name Realm Migrations
 *  ---------------------------------------------------------------------------------------
 */
/**
 RLMMigration is the object passed into a user defined RLMMigrationBlock when updating the version
 of an RLMRealm instance.
 
 This object provides access to the RLMSchema current to this migration.
 @see RLMMigrationBlock
 */
@interface RLMMigration : NSObject

/**
 Get the current RLMSchema for the migration. This object provides the ability to remove/rename object 
 classes. Each RLMObjectSchema object exposed by this object provide the ability to remove/rename/add
 properties to existing object types.

 @see       RLMObjectSchema
 */
@property (nonatomic, readonly) RLMSchema *schema;


/**---------------------------------------------------------------------------------------
 *  @name Getting Objects during a Migration
 *  ---------------------------------------------------------------------------------------
 */
/**
 Get all objects of a given type in this Realm. 
 
 @param className   The name of the RLMObject subclass to retrieve on eg. <code>MyClass.className</code>.
 
 @warning   All objects returned are of a type specific to the current migration and should not be casted
            to className. Instead you should access them as RLMObjects and use keyed subscripting to access
            properties.
 
 @return    An RLMArray of all objects in this Realm of the given type.
 */
- (RLMArray *)allObjects:(NSString *)className;

@end


