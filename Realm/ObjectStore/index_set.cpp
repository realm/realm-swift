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

#include <algorithm>

using namespace realm;
using namespace realm::_impl;

const size_t IndexSet::npos;

template<typename T>
void MutableChunkedRangeVectorIterator<T>::set(size_t front, size_t back)
{
    this->m_outer->count -= this->m_inner->second - this->m_inner->first;
    if (this->offset() == 0) {
        this->m_outer->begin = front;
    }
    if (this->m_inner == &this->m_outer->data.back()) {
        this->m_outer->end = back;
    }
    this->m_outer->count += back - front;
    this->m_inner->first = front;
    this->m_inner->second = back;
}

template<typename T>
void MutableChunkedRangeVectorIterator<T>::adjust(ptrdiff_t front, ptrdiff_t back)
{
    if (this->offset() == 0) {
        this->m_outer->begin += front;
    }
    if (this->m_inner == &this->m_outer->data.back()) {
        this->m_outer->end += back;
    }
    this->m_outer->count += -front + back;
    this->m_inner->first += front;
    this->m_inner->second += back;
}

template<typename T>
void MutableChunkedRangeVectorIterator<T>::shift(ptrdiff_t distance)
{
    if (this->offset() == 0) {
        this->m_outer->begin += distance;
    }
    if (this->m_inner == &this->m_outer->data.back()) {
        this->m_outer->end += distance;
    }
    this->m_inner->first += distance;
    this->m_inner->second += distance;
}

void ChunkedRangeVector::push_back(value_type value)
{
    if (!empty() && m_data.back().data.size() < max_size) {
        auto& range = m_data.back();
        REALM_ASSERT(range.end <= value.first);

        range.data.push_back(value);
        range.count += value.second - value.first;
        range.end = value.second;
    }
    else {
        m_data.push_back({{std::move(value)}, value.first, value.second, value.second - value.first});
    }
    verify();
}

ChunkedRangeVector::iterator ChunkedRangeVector::insert(iterator pos, value_type value)
{
    if (pos.m_outer == m_data.end()) {
        push_back(std::move(value));
        return std::prev(end());
    }

    pos = ensure_space(pos);
    auto& chunk = *pos.m_outer;
    pos.m_inner = &*chunk.data.insert(pos.m_outer->data.begin() + pos.offset(), value);
    chunk.count += value.second - value.first;
    chunk.begin = std::min(chunk.begin, value.first);
    chunk.end = std::max(chunk.end, value.second);

    verify();
    return pos;
}

ChunkedRangeVector::iterator ChunkedRangeVector::ensure_space(iterator pos)
{
    if (pos.m_outer->data.size() + 1 <= max_size)
        return pos;

    auto offset = pos.offset();

    // Split the chunk in half to make space for the new insertion
    auto new_pos = m_data.insert(pos.m_outer + 1, Chunk{});
    auto prev = new_pos - 1;
    auto to_move = max_size / 2;
    new_pos->data.reserve(to_move);
    new_pos->data.assign(prev->data.end() - to_move, prev->data.end());
    prev->data.resize(prev->data.size() - to_move);

    size_t moved_count = 0;
    for (auto range : new_pos->data)
        moved_count += range.second - range.first;

    prev->end = prev->data.back().second;
    prev->count -= moved_count;
    new_pos->begin = new_pos->data.front().first;
    new_pos->end = new_pos->data.back().second;
    new_pos->count = moved_count;

    if (offset >= to_move) {
        pos.m_outer = new_pos;
        offset -= to_move;
    }
    else {
        pos.m_outer = prev;
    }
    pos.m_end = m_data.end();
    pos.m_inner = &pos.m_outer->data[offset];
    verify();
    return pos;
}

ChunkedRangeVector::iterator ChunkedRangeVector::erase(iterator pos)
{
    auto offset = pos.offset();
    auto& chunk = *pos.m_outer;
    chunk.count -= pos->second - pos->first;
    chunk.data.erase(chunk.data.begin() + offset);

    if (chunk.data.size() == 0) {
        pos.m_outer = m_data.erase(pos.m_outer);
        pos.m_end = m_data.end();
        pos.m_inner = pos.m_outer == m_data.end() ? nullptr : &pos.m_outer->data.front();
        verify();
        return pos;
    }

    chunk.begin = chunk.data.front().first;
    chunk.end = chunk.data.back().second;
    if (offset < chunk.data.size())
        pos.m_inner = &chunk.data[offset];
    else {
        ++pos.m_outer;
        pos.m_inner = pos.m_outer == pos.m_end ? nullptr : &pos.m_outer->data.front();
    }

    verify();
    return pos;
}

void ChunkedRangeVector::verify() const noexcept
{
#ifdef REALM_DEBUG
    size_t prev_end = -1;
    for (auto range : *this) {
        REALM_ASSERT(range.first < range.second);
        REALM_ASSERT(prev_end == size_t(-1) || range.first > prev_end);
        prev_end = range.second;
    }

    for (auto& chunk : m_data) {
        REALM_ASSERT(!chunk.data.empty());
        REALM_ASSERT(chunk.data.front().first == chunk.begin);
        REALM_ASSERT(chunk.data.back().second == chunk.end);
        REALM_ASSERT(chunk.count <= chunk.end - chunk.begin);
        size_t count = 0;
        for (auto range : chunk.data)
            count += range.second - range.first;
        REALM_ASSERT(count == chunk.count);
    }
#endif
}

namespace {
class ChunkedRangeVectorBuilder {
public:
    using value_type = std::pair<size_t, size_t>;

    ChunkedRangeVectorBuilder(ChunkedRangeVector const& expected);
    void push_back(size_t index);
    void push_back(std::pair<size_t, size_t> range);
    std::vector<ChunkedRangeVector::Chunk> finalize();
private:
    std::vector<ChunkedRangeVector::Chunk> m_data;
    size_t m_outer_pos = 0;
};

ChunkedRangeVectorBuilder::ChunkedRangeVectorBuilder(ChunkedRangeVector const& expected)
{
    size_t size = 0;
    for (auto const& chunk : expected.m_data)
        size += chunk.data.size();
    m_data.resize(size / ChunkedRangeVector::max_size + 1);
    for (size_t i = 0; i < m_data.size() - 1; ++i)
        m_data[i].data.reserve(ChunkedRangeVector::max_size);
}

void ChunkedRangeVectorBuilder::push_back(size_t index)
{
    push_back({index, index + 1});
}

void ChunkedRangeVectorBuilder::push_back(std::pair<size_t, size_t> range)
{
    auto& chunk = m_data[m_outer_pos];
    if (chunk.data.empty()) {
        chunk.data.push_back(range);
        chunk.count = range.second - range.first;
        chunk.begin = range.first;
    }
    else if (range.first == chunk.data.back().second) {
        chunk.data.back().second = range.second;
        chunk.count += range.second - range.first;
    }
    else if (chunk.data.size() < ChunkedRangeVector::max_size) {
        chunk.data.push_back(range);
        chunk.count += range.second - range.first;
    }
    else {
        chunk.end = chunk.data.back().second;
        ++m_outer_pos;
        if (m_outer_pos >= m_data.size())
            m_data.push_back({{range}, range.first, 0, 1});
        else {
            auto& chunk = m_data[m_outer_pos];
            chunk.data.push_back(range);
            chunk.begin = range.first;
            chunk.count = range.second - range.first;
        }
    }
}

std::vector<ChunkedRangeVector::Chunk> ChunkedRangeVectorBuilder::finalize()
{
    if (!m_data.empty()) {
        m_data.resize(m_outer_pos + 1);
        if (m_data.back().data.empty())
            m_data.pop_back();
        else
            m_data.back().end = m_data.back().data.back().second;
    }
    return std::move(m_data);
}
}

IndexSet::IndexSet(std::initializer_list<size_t> values)
{
    for (size_t v : values)
        add(v);
}

bool IndexSet::contains(size_t index) const
{
    auto it = const_cast<IndexSet*>(this)->find(index);
    return it != end() && it->first <= index;
}

size_t IndexSet::count(size_t start_index, size_t end_index) const
{
    auto it = const_cast<IndexSet*>(this)->find(start_index);
    const auto end = this->end();
    if (it == end || it->first >= end_index) {
        return 0;
    }
    if (it->second >= end_index)
        return std::min(it->second, end_index) - std::max(it->first, start_index);

    size_t ret = 0;

    if (start_index > it->first || it.offset() != 0) {
        // Start index is in the middle of a chunk, so start by counting the
        // rest of that chunk
        ret = it->second - std::max(it->first, start_index);
        for (++it; it != end && it->second < end_index && it.offset() != 0; ++it) {
            ret += it->second - it->first;
        }
        if (it != end && it->first < end_index && it.offset() != 0)
            ret += end_index - it->first;
        if (it == end || it->second >= end_index)
            return ret;
    }

    // Now count all complete chunks that fall within the range
    while (it != end && it.outer()->end <= end_index) {
        REALM_ASSERT_DEBUG(it.offset() == 0);
        ret += it.outer()->count;
        it.next_chunk();
    }

    // Cound all complete ranges within the last chunk
    while (it != end && it->second <= end_index) {
        ret += it->second - it->first;
        ++it;
    }

    // And finally add in the partial last range
    if (it != end && it->first < end_index)
        ret += end_index - it->first;
    return ret;
}

IndexSet::iterator IndexSet::find(size_t index)
{
    return find(index, begin());
}

IndexSet::iterator IndexSet::find(size_t index, iterator begin)
{
    auto it = std::find_if(begin.outer(), m_data.end(),
                           [&](auto const& lft) { return lft.end > index; });
    if (it == m_data.end())
        return end();
    if (index < it->begin)
        return iterator(it, m_data.end(), &it->data[0]);
    auto inner_begin = it->data.begin();
    if (it == begin.outer())
        inner_begin += begin.offset();
    auto inner = std::lower_bound(inner_begin, it->data.end(), index,
                                  [&](auto const& lft, auto) { return lft.second <= index; });
    REALM_ASSERT_DEBUG(inner != it->data.end());

    return iterator(it, m_data.end(), &*inner);
}

void IndexSet::add(size_t index)
{
    do_add(find(index), index);
}

void IndexSet::add(IndexSet const& other)
{
    auto it = begin();
    for (size_t index : other.as_indexes()) {
        it = do_add(find(index, it), index);
    }
}

size_t IndexSet::add_shifted(size_t index)
{
    iterator it = begin(), end = this->end();

    // Shift for any complete chunks before the target
    for (; it != end && it.outer()->end <= index; it.next_chunk())
        index += it.outer()->count;

    // And any ranges within the last partial chunk
    for (; it != end && it->first <= index; ++it)
        index += it->second - it->first;

    do_add(it, index);
    return index;
}

void IndexSet::add_shifted_by(IndexSet const& shifted_by, IndexSet const& values)
{
    if (values.empty())
        return;

#ifdef REALM_DEBUG
    size_t expected = std::distance(as_indexes().begin(), as_indexes().end());
    for (auto index : values.as_indexes()) {
        if (!shifted_by.contains(index))
            ++expected;
    }
#endif

    ChunkedRangeVectorBuilder builder(*this);

    auto old_it = cbegin(), old_end = cend();
    auto shift_it = shifted_by.cbegin(), shift_end = shifted_by.cend();

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
                builder.push_back(i);
            old_shift += old_it->second - old_it->first;
        }

        REALM_ASSERT(index >= new_shift);
        builder.push_back(index - new_shift + old_shift);
    }

    copy(old_it, old_end, std::back_inserter(builder));
    m_data = builder.finalize();

#ifdef REALM_DEBUG
    REALM_ASSERT((size_t)std::distance(as_indexes().begin(), as_indexes().end()) == expected);
#endif
}

void IndexSet::set(size_t len)
{
    clear();
    if (len) {
        push_back({0, len});
    }
}

void IndexSet::insert_at(size_t index, size_t count)
{
    REALM_ASSERT(count > 0);

    auto pos = find(index);
    auto end = this->end();
    bool in_existing = false;
    if (pos != end) {
        if (pos->first <= index) {
            in_existing = true;
            pos.adjust(0, count);
        }
        else {
            pos.shift(count);
        }
        for (auto it = std::next(pos); it != end; ++it)
            it.shift(count);
    }
    if (!in_existing) {
        for (size_t i = 0; i < count; ++i)
            pos = std::next(do_add(pos, index + i));
    }

    verify();
}

void IndexSet::insert_at(IndexSet const& positions)
{
    if (positions.empty())
        return;
    if (empty()) {
        *this = positions;
        return;
    }

    IndexIterator begin1 = cbegin(), begin2 = positions.cbegin();
    IndexIterator end1 = cend(), end2 = positions.cend();

    ChunkedRangeVectorBuilder builder(*this);
    size_t shift = 0;
    while (begin1 != end1 && begin2 != end2) {
        if (*begin1 + shift < *begin2) {
            builder.push_back(*begin1++ + shift);
        }
        else {
            ++shift;
            builder.push_back(*begin2++);
        }
    }
    for (; begin1 != end1; ++begin1)
        builder.push_back(*begin1 + shift);
    for (; begin2 != end2; ++begin2)
        builder.push_back(*begin2);

    m_data = builder.finalize();
}

void IndexSet::shift_for_insert_at(size_t index, size_t count)
{
    REALM_ASSERT(count > 0);

    auto it = find(index);
    if (it == end())
        return;

    for (auto pos = it, end = this->end(); pos != end; ++pos)
        pos.shift(count);

    // If the range contained the insertion point, split the range and move
    // the part of it before the insertion point back
    if (it->first < index + count) {
        auto old_second = it->second;
        it.set(it->first - count, index);
        insert(std::next(it), {index + count, old_second});
    }
    verify();
}

void IndexSet::shift_for_insert_at(realm::IndexSet const& values)
{
    if (empty() || values.empty())
        return;
    if (values.m_data.front().begin >= m_data.back().end)
        return;

    IndexIterator begin1 = cbegin(), begin2 = values.cbegin();
    IndexIterator end1 = cend(), end2 = values.cend();

    ChunkedRangeVectorBuilder builder(*this);
    size_t shift = 0;
    while (begin1 != end1 && begin2 != end2) {
        if (*begin1 + shift < *begin2) {
            builder.push_back(*begin1++ + shift);
        }
        else {
            ++shift;
            begin2++;
        }
    }
    for (; begin1 != end1; ++begin1)
        builder.push_back(*begin1 + shift);

    m_data = builder.finalize();
}

void IndexSet::erase_at(size_t index)
{
    auto it = find(index);
    if (it != end())
        do_erase(it, index);
}

void IndexSet::erase_at(IndexSet const& positions)
{
    if (empty() || positions.empty())
        return;

    ChunkedRangeVectorBuilder builder(*this);

    IndexIterator begin1 = cbegin(), begin2 = positions.cbegin();
    IndexIterator end1 = cend(), end2 = positions.cend();

    size_t shift = 0;
    while (begin1 != end1 && begin2 != end2) {
        if (*begin1 < *begin2) {
            builder.push_back(*begin1++ - shift);
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
        builder.push_back(*begin1 - shift);

    m_data = builder.finalize();
}

size_t IndexSet::erase_or_unshift(size_t index)
{
    auto shifted = index;
    iterator it = begin(), end = this->end();

    // Shift for any complete chunks before the target
    for (; it != end && it.outer()->end <= index; it.next_chunk())
        shifted -= it.outer()->count;

    // And any ranges within the last partial chunk
    for (; it != end && it->second <= index; ++it)
        shifted -= it->second - it->first;

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
        if (it->first + 1 == it->second) {
            it = erase(it);
        }
        else {
            it.adjust(0, -1);
            ++it;
        }
    }
    else if (it != begin() && std::prev(it)->second + 1 == it->first) {
        std::prev(it).adjust(0, it->second - it->first);
        it = erase(it);
    }

    for (; it != end(); ++it)
        it.shift(-1);
}

IndexSet::iterator IndexSet::do_remove(iterator it, size_t begin, size_t end)
{
    for (it = find(begin, it); it != this->end() && it->first < end; it = find(begin, it)) {
        // Trim off any part of the range to remove that's before the matching range
        begin = std::max(it->first, begin);

        // If the matching range extends to both sides of the range to remove,
        // split it on the range to remove
        if (it->first < begin && it->second > end) {
            auto old_second = it->second;
            it.set(it->first, begin);
            it = std::prev(insert(std::next(it), {end, old_second}));
        }
        // Range to delete now coverages (at least) one end of the matching range
        else if (begin == it->first && end >= it->second)
            it = erase(it);
        else if (begin == it->first)
            it.set(end, it->second);
        else
            it.set(it->first, begin);
    }
    return it;
}

void IndexSet::remove(size_t index, size_t count)
{
    do_remove(find(index), index, index + count);
}

void IndexSet::remove(realm::IndexSet const& values)
{
    auto it = begin();
    for (auto range : values) {
        it = do_remove(it, range.first, range.second);
        if (it == end())
            return;
    }
}

size_t IndexSet::shift(size_t index) const
{
    // FIXME: optimize
    for (auto range : *this) {
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
    m_data.clear();
}

IndexSet::iterator IndexSet::do_add(iterator it, size_t index)
{
    verify();
    bool more_before = it != begin(), valid = it != end();
    REALM_ASSERT(!more_before || index >= std::prev(it)->second);
    if (valid && it->first <= index && it->second > index) {
        // index is already in set
        return it;
    }
    if (more_before && std::prev(it)->second == index) {
        auto prev = std::prev(it);
        // index is immediately after an existing range
        prev.adjust(0, 1);

        if (valid && prev->second == it->first) {
            // index joins two existing ranges
            prev.adjust(0, it->second - it->first);
            return std::prev(erase(it));
        }
        return prev;
    }
    if (valid && it->first == index + 1) {
        // index is immediately before an existing range
        it.adjust(-1, 0);
        return it;
    }

    // index is not next to an existing range
    return insert(it, {index, index + 1});
}
