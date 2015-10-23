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

#include "index_set.hpp"

using namespace realm;

IndexSet::iterator IndexSet::find(size_t index)
{
    for (auto it = m_ranges.begin(), end = m_ranges.end(); it != end; ++it) {
        if (it->second > index)
            return it;
    }
    return m_ranges.end();
}

void IndexSet::add(size_t index)
{
    do_add(find(index), index);
}

void IndexSet::do_add(iterator it, size_t index)
{
    bool more_before = it != m_ranges.begin(), valid = it != m_ranges.end();
    if (valid && it->first <= index && it->second > index) {
        // index is already in set
    }
    else if (more_before && (it - 1)->second == index) {
        // index is immediately after an existing range
        ++(it - 1)->second;
    }
    else if (more_before && valid && (it - 1)->second == it->first) {
        // index joins two existing ranges
        (it - 1)->second = it->second;
        m_ranges.erase(it);
    }
    else if (valid && it->first == index + 1) {
        // index is immediately before an existing range
        --it->first;
    }
    else {
        // index is not next to an existing range
        m_ranges.insert(it, {index, index + 1});
    }
}

void IndexSet::set(size_t len)
{
    m_ranges.clear();
    if (len) {
        m_ranges.push_back({0, len});
    }
}

void IndexSet::insert_at(size_t index)
{
    auto pos = find(index);
    if (pos != m_ranges.end()) {
        if (pos->first >= index)
            ++pos->first;
        ++pos->second;
        for (auto it = pos + 1; it != m_ranges.end(); ++it) {
            ++it->first;
            ++it->second;
        }
    }
    do_add(pos, index);
}

void IndexSet::add_shifted(size_t index)
{
    auto it = m_ranges.begin();
    for (auto end = m_ranges.end(); it != end && it->first <= index; ++it) {
        index += it->second - it->first;
    }
    do_add(it, index);
}
