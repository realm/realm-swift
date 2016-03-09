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

#ifndef REALM_INDEX_SET_HPP
#define REALM_INDEX_SET_HPP

#include <cstdlib>
#include <iterator>
#include <vector>
#include <stddef.h>

namespace realm {
class IndexSet {
public:
    static const size_t npos = -1;

    using value_type = std::pair<size_t, size_t>;
    using iterator = std::vector<value_type>::iterator;
    using const_iterator = std::vector<value_type>::const_iterator;

    const_iterator begin() const { return m_ranges.begin(); }
    const_iterator end() const { return m_ranges.end(); }
    bool empty() const { return m_ranges.empty(); }
    size_t size() const { return m_ranges.size(); }

    IndexSet() = default;
    IndexSet(std::initializer_list<size_t>);

    // Check if the index set contains the given index
    bool contains(size_t index) const;

    // Counts the number of indices in the set in the given range
    size_t count(size_t start_index, size_t end_index) const;

    // Add an index to the set, doing nothing if it's already present
    void add(size_t index);
    void add(IndexSet const& is);

    // Add an index which has had all of the ranges in the set before it removed
    // Returns the unshifted index
    size_t add_shifted(size_t index);
    // Add indexes which have had the ranges in `shifted_by` added and the ranges
    // in the current set removed
    void add_shifted_by(IndexSet const& shifted_by, IndexSet const& values);

    // Remove all indexes from the set and then add a single range starting from
    // zero with the given length
    void set(size_t len);

    // Insert an index at the given position, shifting existing indexes at or
    // after that point back by one
    void insert_at(size_t index, size_t count=1);
    void insert_at(IndexSet const&);

    // Shift indexes at or after the given point back by one
    void shift_for_insert_at(size_t index, size_t count=1);
    void shift_for_insert_at(IndexSet const&);

    // Delete an index at the given position, shifting indexes after that point
    // forward by one
    void erase_at(size_t index);
    void erase_at(IndexSet const&);

    size_t erase_and_unshift(size_t index);

    // Remove the indexes at the given index from the set, without shifting
    void remove(size_t index, size_t count=1);
    void remove(IndexSet const&);

    // Shift an index by inserting each of the indexes in this set
    size_t shift(size_t index) const;
    // Shift an index by deleting each of the indexes in this set
    size_t unshift(size_t index) const;

    // Remove all indexes from the set
    void clear();

    void verify() const noexcept;

    // An iterator over the indivual indices in the set rather than the ranges
    class IndexInterator : public std::iterator<std::forward_iterator_tag, size_t> {
    public:
        IndexInterator(IndexSet::const_iterator it) : m_iterator(it) { }
        size_t operator*() const { return m_iterator->first + m_offset; }
        bool operator!=(IndexInterator const& it) const { return m_iterator != it.m_iterator; }

        IndexInterator& operator++()
        {
            ++m_offset;
            if (m_iterator->first + m_offset == m_iterator->second) {
                ++m_iterator;
                m_offset = 0;
            }
            return *this;
        }

        IndexInterator operator++(int)
        {
            auto value = *this;
            ++*this;
            return value;
        }

    private:
        IndexSet::const_iterator m_iterator;
        size_t m_offset = 0;
    };

    class IndexIteratableAdaptor {
    public:
        using value_type = size_t;
        using iterator = IndexInterator;
        using const_iterator = iterator;

        const_iterator begin() const { return m_index_set.begin(); }
        const_iterator end() const { return m_index_set.end(); }

        IndexIteratableAdaptor(IndexSet const& is) : m_index_set(is) { }
    private:
        IndexSet const& m_index_set;
    };

    IndexIteratableAdaptor as_indexes() const { return *this; }

private:
    std::vector<value_type> m_ranges;

    // Find the range which contains the index, or the first one after it if
    // none do
    iterator find(size_t index);
    iterator find(size_t index, iterator it);
    // Insert the index before the given position, combining existing ranges as
    // applicable
    // returns inserted position
    iterator do_add(iterator pos, size_t index);
    void do_erase(iterator it, size_t index);
    iterator do_remove(iterator it, size_t index, size_t count);
};
} // namespace realm

#endif // REALM_INDEX_SET_HPP
