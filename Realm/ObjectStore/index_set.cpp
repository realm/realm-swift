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

#include <realm/util/assert.hpp>

using namespace realm;

const size_t IndexSet::npos;

IndexSet::IndexSet(std::initializer_list<size_t> values)
{
    for (size_t v : values)
        add(v);
}

bool IndexSet::contains(size_t index) const
{
    auto it = const_cast<IndexSet*>(this)->find(index);
    return it != m_ranges.end() && it->first <= index;
}

IndexSet::iterator IndexSet::find(size_t index)
{
    return find(index, m_ranges.begin());
}

IndexSet::iterator IndexSet::find(size_t index, iterator it)
{
    for (auto end = m_ranges.end(); it != end; ++it) {
        if (it->second > index)
            return it;
    }
    return m_ranges.end();
}

void IndexSet::add(size_t index)
{
    do_add(find(index), index);
}

void IndexSet::add(IndexSet const& other)
{
    auto it = m_ranges.begin();
    for (size_t index : other.as_indexes()) {
        it = do_add(find(index, it), index);
    }
}

size_t IndexSet::add_shifted(size_t index)
{
    auto it = m_ranges.begin();
    for (auto end = m_ranges.end(); it != end && it->first <= index; ++it) {
        index += it->second - it->first;
    }
    do_add(it, index);
    return index;
}

void IndexSet::add_shifted_by(IndexSet const& shifted_by, IndexSet const& values)
{
    auto it = shifted_by.begin(), end = shifted_by.end();
    size_t shift = 0;
    size_t skip_until = 0;
    for (size_t index : values.as_indexes()) {
        for (; it != end && it->first <= index; ++it) {
            shift += it->second - it->first;
            skip_until = it->second;
        }
        if (index >= skip_until) {
            REALM_ASSERT(index >= shift);
            add_shifted(index - shift);
            ++shift;
        }
    }
}

void IndexSet::set(size_t len)
{
    m_ranges.clear();
    if (len) {
        m_ranges.push_back({0, len});
    }
}

void IndexSet::insert_at(size_t index, size_t count)
{
    REALM_ASSERT(count > 0);

    auto pos = find(index);
    bool in_existing = false;
    if (pos != m_ranges.end()) {
        if (pos->first <= index)
            in_existing = true;
        else
            pos->first += count;
        pos->second += count;
        for (auto it = pos + 1; it != m_ranges.end(); ++it) {
            it->first += count;
            it->second += count;
        }
    }
    if (!in_existing) {
        for (size_t i = 0; i < count; ++i)
            pos = do_add(pos, index + i) + 1;
    }
}

void IndexSet::insert_at(IndexSet const& positions)
{
    for (auto range : positions) {
        insert_at(range.first, range.second - range.first);
    }
}

void IndexSet::shift_for_insert_at(size_t index, size_t count)
{
    REALM_ASSERT(count > 0);

    auto it = find(index);
    if (it == m_ranges.end())
        return;

    if (it->first < index) {
        // split the range so that we can exclude `index`
        auto old_second = it->second;
        it->second = index;
        it = m_ranges.insert(it + 1, {index, old_second});
    }

    for (; it != m_ranges.end(); ++it) {
        it->first += count;
        it->second += count;
    }
}

void IndexSet::shift_for_insert_at(realm::IndexSet const& values)
{
    for (auto range : values)
        shift_for_insert_at(range.first, range.second - range.first);
}

void IndexSet::erase_at(size_t index)
{
    auto it = find(index);
    if (it != m_ranges.end())
        do_erase(it, index);
}

void IndexSet::erase_at(realm::IndexSet const& values)
{
    size_t shift = 0;
    for (auto index : values.as_indexes())
        erase_at(index - shift++);
}

size_t IndexSet::erase_and_unshift(size_t index)
{
    auto shifted = index;
    auto it = m_ranges.begin(), end = m_ranges.end();
    for (; it != end && it->second <= index; ++it) {
        shifted -= it->second - it->first;
    }
    if (it == end)
        return shifted;

    if (it->first <= index)
        shifted = npos;

    do_erase(it, index);

    return shifted;
}

void IndexSet::do_erase(iterator it, size_t index)
{
    if (it->first <= index) {
        --it->second;
        if (it->first == it->second) {
            it = m_ranges.erase(it);
        }
        else {
            ++it;
        }
    }
    else if (it != m_ranges.begin() && (it - 1)->second + 1 == it->first) {
        (it - 1)->second = it->second - 1;
        it = m_ranges.erase(it);
    }

    for (; it != m_ranges.end(); ++it) {
        --it->first;
        --it->second;
    }
}

IndexSet::iterator IndexSet::do_remove(iterator it, size_t begin, size_t end)
{
    for (it = find(begin, it); it != m_ranges.end() && it->first < end; it = find(begin, it)) {
        // Trim off any part of the range to remove that's before the matching range
        begin = std::max(it->first, begin);

        // If the matching range extends to both sides of the range to remove,
        // split it on the range to remove
        if (it->first < begin && it->second > end) {
            it = m_ranges.insert(it + 1, {end, it->second}) - 1;
            it->second = begin;
        }

        // Range to delete now coverages (at least) one end of the matching range
        if (begin == it->first && end >= it->second)
            it = m_ranges.erase(it);
        else if (begin == it->first)
            it->first = end;
        else
            it->second = begin;
    }
    return it;
}

void IndexSet::remove(size_t index, size_t count)
{
    do_remove(find(index), index, index + count);
}

void IndexSet::remove(realm::IndexSet const& values)
{
    auto it = m_ranges.begin();
    for (auto range : values) {
        it = do_remove(it, range.first, range.second);
        if (it == m_ranges.end())
            return;
    }
}

size_t IndexSet::shift(size_t index) const
{
    for (auto range : m_ranges) {
        if (range.first > index)
            break;
        index += range.second - range.first;
    }
    return index;
}

size_t IndexSet::unshift(size_t index) const
{
    REALM_ASSERT_DEBUG(!contains(index));
    auto shifted = index;
    for (auto range : m_ranges) {
        if (range.first >= index)
            break;
        shifted -= std::min(range.second, index) - range.first;
    }
    return shifted;
}

void IndexSet::clear()
{
    m_ranges.clear();
}

IndexSet::iterator IndexSet::do_add(iterator it, size_t index)
{
    verify();
    bool more_before = it != m_ranges.begin(), valid = it != m_ranges.end();
    REALM_ASSERT(!more_before || index >= (it - 1)->second);
    if (valid && it->first <= index && it->second > index) {
        // index is already in set
        return it;
    }
    if (more_before && (it - 1)->second == index) {
        // index is immediately after an existing range
        ++(it - 1)->second;

        if (valid && (it - 1)->second == it->first) {
            // index joins two existing ranges
            (it - 1)->second = it->second;
            return m_ranges.erase(it) - 1;
        }
        return it - 1;
    }
    if (valid && it->first == index + 1) {
        // index is immediately before an existing range
        --it->first;
        return it;
    }

    // index is not next to an existing range
    return m_ranges.insert(it, {index, index + 1});
}

void IndexSet::verify() const noexcept
{
#ifdef REALM_DEBUG
    size_t prev_end = -1;
    for (auto range : m_ranges) {
        REALM_ASSERT(range.first < range.second);
        REALM_ASSERT(prev_end == size_t(-1) || range.first > prev_end);
        prev_end = range.second;
    }
#endif
}
