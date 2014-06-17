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

// apply a sort (column name or NSSortDescriptor) to an existing view
void RLMUpdateViewWithOrder(tightdb::TableView &view, id order, RLMObjectSchema *schema);

NSUInteger RLMValidatedColumnIndex(RLMObjectSchema *desc, NSString *columnName);

// predicate exception
NSException *RLMPredicateException(NSString *name, NSString *reason);
