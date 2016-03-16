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

size_t IndexSet::count(size_t start_index, size_t end_index) const
{
    auto it = const_cast<IndexSet*>(this)->find(start_index);
    const auto end = m_ranges.end();
    if (it == end || it->first >= end_index) {
        return 0;
    }
    if (it->second >= end_index)
        return std::min(it->second, end_index) - std::max(it->first, start_index);

    // These checks are somewhat redundant, but this loop is hot so pulling instructions out of it helps
    size_t ret = it->second - std::max(it->first, start_index);
    for (++it; it != end && it->second < end_index; ++it) {
        ret += it->second - it->first;
    }
    if (it != end && it->first < end_index)
        ret += end_index - it->first;
    return ret;
}

IndexSet::iterator IndexSet::find(size_t index)
{
    return find(index, m_ranges.begin());
}

IndexSet::iterator IndexSet::find(size_t index, iterator it)
{
    return std::lower_bound(it, m_ranges.end(), std::make_pair(size_t(0), index + 1),
                            [&](auto const& a, auto const& b) { return a.second < b.second; });
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
    if (values.empty())
        return;

#ifdef REALM_DEBUG
    ptrdiff_t expected = std::distance(as_indexes().begin(), as_indexes().end());
    for (auto index : values.as_indexes()) {
        if (!shifted_by.contains(index))
            ++expected;
    }
#endif

    auto old_ranges = move(m_ranges);
    m_ranges.reserve(std::max(old_ranges.size(), values.size()));

    auto old_it = old_ranges.cbegin(), old_end = old_ranges.cend();
    auto shift_it = shifted_by.m_ranges.cbegin(), shift_end = shifted_by.m_ranges.cend();

    size_t skip_until = 0;
    size_t old_shift = 0;
    size_t new_shift = 0;
    for (size_t index : values.as_indexes()) {
        for (; shift_it != shift_end && shift_it->first <= index; ++shift_it) {
            new_shift += shift_it->second - shift_it->first;
            skip_until = shift_it->second;
        }
        if (index < skip_until)
            continue;

        for (; old_it != old_end && old_it->first <= index - new_shift + old_shift; ++old_it) {
            for (size_t i = old_it->first; i < old_it->second; ++i)
                add_back(i);
            old_shift += old_it->second - old_it->first;
        }

        REALM_ASSERT(index >= new_shift);
        add_back(index - new_shift + old_shift);
    }

    if (old_it != old_end) {
        if (!empty() && old_it->first == m_ranges.back().second) {
            m_ranges.back().second = old_it->second;
            ++old_it;
        }
        copy(old_it, old_end, back_inserter(m_ranges));
    }

    REALM_ASSERT_DEBUG(std::distance(as_indexes().begin(), as_indexes().end()) == expected);
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
    if (positions.empty())
        return;
    if (empty()) {
        m_ranges = positions.m_ranges;
        return;
    }

    auto old_ranges = move(m_ranges);
    m_ranges.reserve(std::max(m_ranges.size(), positions.m_ranges.size()));

    IndexIterator begin1 = old_ranges.cbegin(), begin2 = positions.m_ranges.cbegin();
    IndexIterator end1 = old_ranges.cend(), end2 = positions.m_ranges.cend();

    size_t shift = 0;
    while (begin1 != end1 && begin2 != end2) {
        if (*begin1 + shift < *begin2) {
            add_back(*begin1++ + shift);
        }
        else {
            ++shift;
            add_back(*begin2++);
        }
    }
    for (; begin1 != end1; ++begin1)
        add_back(*begin1 + shift);
    for (; begin2 != end2; ++begin2)
        add_back(*begin2);
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
    if (values.empty())
        return;

    size_t shift = 0;
    auto it = find(values.begin()->first);
    for (auto range : values) {
        for (; it != m_ranges.end() && it->second + shift <= range.first; ++it) {
            it->first += shift;
            it->second += shift;
        }
        if (it == m_ranges.end())
            return;

        if (it->first + shift < range.first) {
            // split the range so that we can exclude `index`
            auto old_second = it->second;
            it->first += shift;
            it->second = range.first;
            it = m_ranges.insert(it + 1, {range.first - shift, old_second});
        }

        shift += range.second - range.first;
    }

    for (; it != m_ranges.end(); ++it) {
        it->first += shift;
        it->second += shift;
    }
}

void IndexSet::erase_at(size_t index)
{
    auto it = find(index);
    if (it != m_ranges.end())
        do_erase(it, index);
}

void IndexSet::erase_at(IndexSet const& positions)
{
    if (empty() || positions.empty())
        return;

    auto old_ranges = move(m_ranges);
    m_ranges.reserve(std::max(m_ranges.size(), positions.m_ranges.size()));

    IndexIterator begin1 = old_ranges.cbegin(), begin2 = positions.m_ranges.cbegin();
    IndexIterator end1 = old_ranges.cend(), end2 = positions.m_ranges.cend();

    size_t shift = 0;
    while (begin1 != end1 && begin2 != end2) {
        if (*begin1 < *begin2) {
            add_back(*begin1++ - shift);
        }
        else if (*begin1 == *begin2) {
            ++shift;
            ++begin1;
            ++begin2;
        }
        else {
            ++shift;
            ++begin2;
        }
    }
    for (; begin1 != end1; ++begin1)
        add_back(*begin1 - shift);
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
    return index - count(0, index);
}

void IndexSet::clear()
{
    m_ranges.clear();
}

void IndexSet::add_back(size_t index)
{
    if (m_ranges.empty())
        m_ranges.push_back({index, index + 1});
    else if (m_ranges.back().second == index)
        ++m_ranges.back().second;
    else {
        REALM_ASSERT_DEBUG(m_ranges.back().second < index);
        m_ranges.push_back({index, index + 1});
    }
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
