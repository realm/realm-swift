//
//  RLMMigration.h
//  Realm
//
//  Created by Ari Lazier on 5/8/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

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
