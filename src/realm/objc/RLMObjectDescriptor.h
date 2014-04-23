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

#import <Foundation/Foundation.h>
#import "RLMProperty.h"

@class RLMObjectDescriptor;

// ordered properties extracted from an object
@interface RLMObjectDescriptor : NSObject

// array of properties which define a schema
@property (nonatomic, readonly) NSArray * properties;

// property lookup by name
-(RLMProperty *)objectForKeyedSubscript:(id <NSCopying>)key;

// returns a cached or new schema for a given object class
+(instancetype)descriptorForObjectClass:(Class)objectClass;

@end


