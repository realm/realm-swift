////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
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


