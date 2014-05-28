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

