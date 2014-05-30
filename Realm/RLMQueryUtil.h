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
#import <tightdb/table.hpp>
#import <tightdb/table_view.hpp>
#import <tightdb/query.hpp>

#import "RLMObjectSchema.h"

extern NSString *const RLMPropertiesComparisonTypeMismatchException;
extern NSString *const RLMUnsupportedTypesFoundInPropertyComparisonException;

// apply the given predicate to the passed in query, returning the updated query
void RLMUpdateQueryWithPredicate(tightdb::Query *query, id predicate, RLMObjectSchema *schema);

// apply a sort (column name or NSSortDescriptor) to an existing view
void RLMUpdateViewWithOrder(tightdb::TableView &view, id order, RLMObjectSchema *schema);

NSUInteger RLMValidatedColumnIndex(RLMObjectSchema *desc, NSString *columnName);


// predicate exception
NSException *RLMPredicateException(NSString *name, NSString *reason);

// This macro generates an NSPredicate from either an NSPredicate or an NSString with optional format va_list
#define RLM_PREDICATE(INPREDICATE, OUTPREDICATE)           \
if ([INPREDICATE isKindOfClass:[NSPredicate class]]) {     \
    OUTPREDICATE = INPREDICATE;                            \
} else if ([INPREDICATE isKindOfClass:[NSString class]]) { \
    va_list args;                                          \
    va_start(args, INPREDICATE);                           \
    OUTPREDICATE = [NSPredicate predicateWithFormat:INPREDICATE arguments:args]; \
    va_end(args);                                          \
} else if (INPREDICATE) {                                  \
    NSString *reason = @"predicate must be either an NSPredicate or an NSString with optional format va_list";  \
    [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];                                 \
}
