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
@class RLMObject;

typedef void (^RLMObjectMigrationBlock)(RLMObject *oldObject, RLMObject *newObject);

/**---------------------------------------------------------------------------------------
 *  @name Realm Migrations
 *  ---------------------------------------------------------------------------------------
 */
/**
 RLMMigration is the object passed into a user defined RLMMigrationBlock when updating the version
 of an RLMRealm instance.
 
 This object provides access to the RLMSchema current to this migration.
 */
@interface RLMMigration : NSObject

/**
 Get the new RLMSchema for the migration. This is the schema which describes the RLMRealm before the
 migration is applied.
 */
@property (nonatomic, readonly) RLMSchema *oldSchema;

/**
 Get the new RLMSchema for the migration. This is the schema which describes the RLMRealm after applying
 a migration.
 */
@property (nonatomic, readonly) RLMSchema *newSchema;


/**---------------------------------------------------------------------------------------
 *  @name Altering Objects during a Migration
 *  ---------------------------------------------------------------------------------------
 */
/**
 Enumerates objects of a given type in this Realm, providing both the old and new versions of each object.
 Objects properties can be accessed using keyed subscripting.
 
 @param className   The name of the RLMObject subclass to retrieve on eg. <code>MyClass.className</code>.
 
 @warning   All objects returned are of a type specific to the current migration and should not be casted
            to className. Instead you should access them as RLMObjects and use keyed subscripting to access
            properties.
 */
- (void)enumerateObjects:(NSString *)className block:(RLMObjectMigrationBlock)block;

@end


