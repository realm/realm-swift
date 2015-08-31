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

#include <vector>

namespace realm {
class IndexSet {
public:
    struct iterator {
        size_t operator*() const;
        iterator& operator++();
        bool operator==(iterator) const;
        bool operator!=(iterator) const;

        iterator(std::pair<size_t, size_t>* data) noexcept : m_data(data) { }

    private:
        std::pair<size_t, size_t>* m_data;
        size_t m_offset = 0;
    };

    iterator begin() { return iterator(&m_ranges[0]); }
    iterator end() { return iterator(&m_ranges[m_ranges.size()]); }

    size_t size() const;

    // Add an index to the set, doing nothing if it's already present
    void add(size_t index);
    // Set the index set to a single range starting at 0 with length `len`
    void set(size_t len);
    // Insert an index at the given position, shifting existing indexes back
    void insert_at(size_t index);

private:
    using Range = std::pair<size_t, size_t>;
    std::vector<Range> m_ranges;

    // Find the range which contains the index, or the first one after it if
    // none do
    std::vector<Range>::iterator find(size_t index);
    void do_add(std::vector<Range>::iterator pos, size_t index);
};
} // namespace realm

#endif // REALM_INDEX_SET_HPP
