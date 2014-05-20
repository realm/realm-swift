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

#import "RLMObjectSchema.h"

#import <tightdb/table.hpp>

// RLMObjectSchema private
@interface RLMObjectSchema ()

// returns a cached or new schema for a given object class
+(instancetype)schemaForObjectClass:(Class)objectClass;

// generate a schema from a table
+(instancetype)schemaForTable:(tightdb::Table *)table className:(NSString *)className;

@end
