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
#import "RLMSchema.h"

extern NSString * const RLMPropertiesComparisonTypeMismatchException;
extern NSString * const RLMUnsupportedTypesFoundInPropertyComparisonException;

// apply the given predicate to the passed in query, returning the updated query
void RLMUpdateQueryWithPredicate(tightdb::Query *query, NSPredicate *predicate, RLMSchema *schema,
                                 RLMObjectSchema *objectSchema);

// sort an existing view by the specified property name and direction
void RLMUpdateViewWithOrder(tightdb::TableView &view, RLMObjectSchema *schema, NSArray *properties);

// return column index - throw for invalid column name
NSUInteger RLMValidatedColumnIndex(RLMObjectSchema *schema, NSString *columnName);

// populate columns and order with the values in properties and ascending, with validation
void RLMGetColumnIndices(RLMObjectSchema *schema, NSArray *properties,
                         std::vector<size_t> &columns, std::vector<bool> &order);


// This macro validates predicate format with optional arguments
#define RLM_VARARG(PREDICATE_FORMAT, ARGS) \
va_start(ARGS, PREDICATE_FORMAT);          \
va_end(ARGS);                              \
if (PREDICATE_FORMAT && ![PREDICATE_FORMAT isKindOfClass:[NSString class]]) {         \
    NSString *reason = @"predicate must be an NSString with optional format va_list"; \
    [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];       \
}
