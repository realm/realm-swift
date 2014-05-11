/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import "RLMObject.h"


/**---------------------------------------------------------------------------------------
 *  @name Querying the Default Realm
 *  ---------------------------------------------------------------------------------------
 */
/*
 These methods allow you to easily query a custom subclass for instances of this class in the
 default Realm. To search across Realms other than the defaut or across multiple object classes
 use the interface on an RLMRealm instance.
 */

@interface RLMObject (DefaultRealm)

/**
 Get all objects of this type from the default Realm.
 
 @return    An RLMArray of all objects of this type in the default Realm.
 */
+ (RLMArray *)allObjects;

/**
 Get objects matching the given predicate for this type from the default Realm.
 
 @param predicate   The argument can be an NSPredicate, a predicte string, or predicate format string
 which can accept variable arguments.
 
 @return    An RLMArray of objects of the subclass type in the default Realm that match the given predicate
 */
+ (RLMArray *)objectsWhere:(id)predicate, ...;

/**
 Get an ordered RLMArray of objects matching the given predicate for this type from the default Realm.
 
 @param predicate   The argument can be an NSPredicate, a predicte string, or predicate format string
 which can accept variable arguments.
 @param order       This argument determines how the results are sorted. It can be an NSString containing
 the property name, or an NSSortDescriptor with the property name and order.
 
 @return    An RLMArray of objects of the subclass type in the default Realm that match the predicate
 ordered by the given order.
 */
+ (RLMArray *)objectsOrderedBy:(id)order where:(id)predicate, ...;

@end
