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

@class RLMObject;

/**
 Migration protocol.
 
 Methods are called as needed for each changed object class to get the
 backing store to a state compatible with the current interfaces. Some changes such as adding and
 removing properties, or changing between compatible types are handled automatically. When renaming properties,
 you can implement renamedProperties to migrate all objects without enumeration. In the case that the required
 migration methods are not implemented and a migration can not be completed, an exception will be thrown.
 */
@protocol RLMMigration <NSObject>
@optional
/**
 Implement this method to perform per-object migrations.
 
 @param oldObject   The old version of the object to migrate.
 @param oldVersion  The object class to create.
 @param oldVersion  The version of the old object to migrate.
 
 @return            A new migrated object.
 */
- (RLMObject *)migrateObject:(RLMObject *)oldObject
                 objectClass:(Class)objectClass
                 fromVersion:(NSUInteger)oldVersion;

/**
 Implement this method when renaming properties to avoid enumerating all properties.
 
 @return    A dictionary mapping old property names to new propert names.
 */
- (NSDictionary *)renamedProperties;

@end
