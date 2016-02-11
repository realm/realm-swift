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
#import <vector>

namespace realm {
    class Query;
    struct SortOrder;
    class Table;
    class TableView;
}

@class RLMObjectSchema;
@class RLMProperty;
@class RLMSchema;

extern NSString * const RLMPropertiesComparisonTypeMismatchException;
extern NSString * const RLMUnsupportedTypesFoundInPropertyComparisonException;

// apply the given predicate to the passed in query, returning the updated query
void RLMUpdateQueryWithPredicate(realm::Query *query, NSPredicate *predicate, RLMSchema *schema,
                                 RLMObjectSchema *objectSchema);

// return property - throw for invalid column name
RLMProperty *RLMValidatedProperty(RLMObjectSchema *objectSchema, NSString *columnName);

// validate the array of RLMSortDescriptors and convert it to a realm::SortOrder
realm::SortOrder RLMSortOrderFromDescriptors(RLMObjectSchema *objectSchema, NSArray *descriptors);
