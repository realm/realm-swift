////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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

// sort an existing view by the specified property name and direction
void RLMUpdateViewWithOrder(tightdb::TableView &view, RLMObjectSchema *schema, NSString *property, BOOL ascending);

NSUInteger RLMValidatedColumnIndex(RLMObjectSchema *desc, NSString *columnName);


// predicate exception
NSException *RLMPredicateException(NSString *name, NSString *reason);

// This macro generates an NSPredicate from an NSString with optional format va_list
#define RLM_PREDICATE(IN_PREDICATE_FORMAT, OUT_PREDICATE)   \
if ([IN_PREDICATE_FORMAT isKindOfClass:[NSString class]]) { \
    va_list args;                                           \
    va_start(args, IN_PREDICATE_FORMAT);                    \
    OUT_PREDICATE = [NSPredicate predicateWithFormat:IN_PREDICATE_FORMAT arguments:args]; \
    va_end(args);                                           \
} else if (IN_PREDICATE_FORMAT) {                           \
    NSString *reason = @"predicate must be an NSString with optional format va_list"; \
    [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];       \
}
