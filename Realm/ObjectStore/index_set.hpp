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

#include <cstddef>
#include <cstdlib>
#include <initializer_list>
#include <iterator>
#include <type_traits>
#include <utility>
#include <vector>

namespace realm {
namespace _impl {
template<typename OuterIterator>
class MutableChunkedRangeVectorIterator;

// An iterator for ChunkedRangeVector, templated on the vector iterator/const_iterator
template<typename OuterIterator>
class ChunkedRangeVectorIterator {
public:
    using iterator_category = std::bidirectional_iterator_tag;
    using value_type = typename std::remove_reference<decltype(*OuterIterator()->data.begin())>::type;
    using difference_type = ptrdiff_t;
    using pointer = const value_type*;
    using reference = const value_type&;

    ChunkedRangeVectorIterator(OuterIterator outer, OuterIterator end, value_type* inner)
    : m_outer(outer), m_end(end), m_inner(inner) { }

    reference operator*() const { return *m_inner; }
    pointer operator->() const { return m_inner; }

    template<typename Other> bool operator==(Other const& it) const;
    template<typename Other> bool operator!=(Other const& it) const;

    ChunkedRangeVectorIterator& operator++();
    ChunkedRangeVectorIterator operator++(int);

    ChunkedRangeVectorIterator& operator--();
    ChunkedRangeVectorIterator operator--(int);

    // Advance directly to the next outer block
    void next_chunk();

    OuterIterator outer() const { return m_outer; }
    size_t offset() const { return m_inner - &m_outer->data[0]; }

private:
    OuterIterator m_outer;
    OuterIterator m_end;
    value_type* m_inner;
    friend struct ChunkedRangeVector;
    friend class MutableChunkedRangeVectorIterator<OuterIterator>;
};

// A mutable iterator that adds some invariant-preserving mutation methods
template<typename OuterIterator>
class MutableChunkedRangeVectorIterator : public ChunkedRangeVectorIterator<OuterIterator> {
public:
    using ChunkedRangeVectorIterator<OuterIterator>::ChunkedRangeVectorIterator;

    // Set this iterator to the given range and update the parent if needed
    void set(size_t begin, size_t end);
    // Adjust the begin and end of this iterator by the given amounts and
    // update the parent if needed
    void adjust(ptrdiff_t front, ptrdiff_t back);
    // Shift this iterator by the given amount and update the parent if needed
    void shift(ptrdiff_t distance);
};

// A vector which stores ranges in chunks with a maximum size
struct ChunkedRangeVector {
    struct Chunk {
        std::vector<std::pair<size_t, size_t>> data;
        size_t begin;
        size_t end;
        size_t count;
    };
    std::vector<Chunk> m_data;

    using value_type = std::pair<size_t, size_t>;
    using iterator = MutableChunkedRangeVectorIterator<typename decltype(m_data)::iterator>;
    using const_iterator = ChunkedRangeVectorIterator<typename decltype(m_data)::const_iterator>;

#ifdef REALM_DEBUG
    static const size_t max_size = 4;
#else
    static const size_t max_size = 4096 / sizeof(std::pair<size_t, size_t>);
#endif

    iterator begin() { return empty() ? end() : iterator(m_data.begin(), m_data.end(), &m_data[0].data[0]); }
    iterator end() { return iterator(m_data.end(), m_data.end(), nullptr); }
    const_iterator begin() const { return cbegin(); }
    const_iterator end() const { return cend(); }
    const_iterator cbegin() const { return empty() ? cend() : const_iterator(m_data.cbegin(), m_data.end(), &m_data[0].data[0]); }
    const_iterator cend() const { return const_iterator(m_data.end(), m_data.end(), nullptr); }

    bool empty() const noexcept { return m_data.empty(); }

    iterator insert(iterator pos, value_type value);
    iterator erase(iterator pos);
    void push_back(value_type value);
    iterator ensure_space(iterator pos);

    void verify() const noexcept;
};
} // namespace _impl

class IndexSet : private _impl::ChunkedRangeVector {
public:
    static const size_t npos = -1;

    using ChunkedRangeVector::value_type;
    using ChunkedRangeVector::iterator;
    using ChunkedRangeVector::const_iterator;
    using ChunkedRangeVector::begin;
    using ChunkedRangeVector::end;
    using ChunkedRangeVector::empty;
    using ChunkedRangeVector::verify;

    IndexSet() = default;
    IndexSet(std::initializer_list<size_t>);

    // Check if the index set contains the given index
    bool contains(size_t index) const;

    // Counts the number of indices in the set in the given range
    size_t count(size_t start_index=0, size_t end_index=-1) const;

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

    // If the given index is in the set remove it and return npos; otherwise unshift() it
    size_t erase_or_unshift(size_t index);

    // Remove the indexes at the given index from the set, without shifting
    void remove(size_t index, size_t count=1);
    void remove(IndexSet const&);

    // Shift an index by inserting each of the indexes in this set
    size_t shift(size_t index) const;
    // Shift an index by deleting each of the indexes in this set
    size_t unshift(size_t index) const;

    // Remove all indexes from the set
    void clear();

    // An iterator over the individual indices in the set rather than the ranges
    class IndexIterator : public std::iterator<std::forward_iterator_tag, size_t> {
    public:
        IndexIterator(IndexSet::const_iterator it) : m_iterator(it) { }
        size_t operator*() const { return m_iterator->first + m_offset; }
        bool operator==(IndexIterator const& it) const { return m_iterator == it.m_iterator; }
        bool operator!=(IndexIterator const& it) const { return m_iterator != it.m_iterator; }

        IndexIterator& operator++()
        {
            ++m_offset;
            if (m_iterator->first + m_offset == m_iterator->second) {
                ++m_iterator;
                m_offset = 0;
            }
            return *this;
        }

        IndexIterator operator++(int)
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
        using iterator = IndexIterator;
        using const_iterator = iterator;

        const_iterator begin() const { return m_index_set.begin(); }
        const_iterator end() const { return m_index_set.end(); }

        IndexIteratableAdaptor(IndexSet const& is) : m_index_set(is) { }
    private:
        IndexSet const& m_index_set;
    };

    IndexIteratableAdaptor as_indexes() const { return *this; }

private:
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

    void shift_until_end_by(iterator begin, ptrdiff_t shift);
};

namespace util {
// This was added in C++14 but is missing from libstdc++ 4.9
template<typename Iterator>
std::reverse_iterator<Iterator> make_reverse_iterator(Iterator it)
{
    return std::reverse_iterator<Iterator>(it);
}
} // namespace util


namespace _impl {
template<typename T>
template<typename OtherIterator>
inline bool ChunkedRangeVectorIterator<T>::operator==(OtherIterator const& it) const
{
    return m_outer == it.outer() && m_inner == it.operator->();
}

template<typename T>
template<typename OtherIterator>
inline bool ChunkedRangeVectorIterator<T>::operator!=(OtherIterator const& it) const
{
    return !(*this == it);
}

template<typename T>
inline ChunkedRangeVectorIterator<T>& ChunkedRangeVectorIterator<T>::operator++()
{
    ++m_inner;
    if (offset() == m_outer->data.size())
        next_chunk();
    return *this;
}

template<typename T>
inline ChunkedRangeVectorIterator<T> ChunkedRangeVectorIterator<T>::operator++(int)
{
    auto value = *this;
    ++*this;
    return value;
}

template<typename T>
inline ChunkedRangeVectorIterator<T>& ChunkedRangeVectorIterator<T>::operator--()
{
    if (!m_inner || m_inner == &m_outer->data.front()) {
        --m_outer;
        m_inner = &m_outer->data.back();
    }
    else {
        --m_inner;
    }
    return *this;
}

template<typename T>
inline ChunkedRangeVectorIterator<T> ChunkedRangeVectorIterator<T>::operator--(int)
{
    auto value = *this;
    --*this;
    return value;
}

template<typename T>
inline void ChunkedRangeVectorIterator<T>::next_chunk()
{
    ++m_outer;
    m_inner = m_outer != m_end ? &m_outer->data[0] : nullptr;
}
} // namespace _impl

} // namespace realm

#endif // REALM_INDEX_SET_HPP
