////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#include "results.hpp"
#import <stdexcept>

using namespace realm;

Results::Results(SharedRealm &r, ObjectSchema &o, Query q, SortOrder s) :
    realm(r), object_schema(o), backing_query(q), table_view(backing_query.find_all())
{
    setSort(std::move(s));
}

size_t Results::size()
{
    verify_attached();
    return table_view.size();
}

void Results::setSort(SortOrder s)
{
    sort_order = std::make_unique<SortOrder>(std::move(s));
    table_view.sort(sort_order->columnIndices, sort_order->ascending);
}

Row Results::get(std::size_t row_ndx)
{
    verify_attached();
    if (row_ndx >= table_view.size()) {
        throw std::out_of_range(std::string("Index ") + std::to_string(row_ndx) + " is outside of range 0..." +
                               std::to_string(table_view.size()) + ".");
    }
    return table_view.get(row_ndx);
}

void Results::verify_attached()
{
    if (!table_view.is_attached()) {
        throw std::runtime_error("Tableview is not attached");
    }
    table_view.sync_if_needed();
}
