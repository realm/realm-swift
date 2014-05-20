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
#import "RLMObjectSchema.h"

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


