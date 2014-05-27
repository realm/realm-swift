//
//  RLMMigration.h
//  Realm
//
//  Created by Ari Lazier on 5/27/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/RLMSchema.h>
#import <Realm/RLMObjectSchema.h>

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
 clases. Each RLMObjectSchema object exposed by this object providee the ability to remove/rename/add 
 individual properties to existing object types.

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


