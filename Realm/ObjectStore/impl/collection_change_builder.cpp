////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#include "impl/collection_change_builder.hpp"

#include <realm/util/assert.hpp>

#include <algorithm>

using namespace realm;
using namespace realm::_impl;

CollectionChangeBuilder::CollectionChangeBuilder(IndexSet deletions,
                                                 IndexSet insertions,
                                                 IndexSet modifications,
                                                 std::vector<Move> moves)
: CollectionChangeSet({std::move(deletions), std::move(insertions), std::move(modifications), std::move(moves)})
{
    for (auto&& move : this->moves) {
        this->deletions.add(move.from);
        this->insertions.add(move.to);
    }
}

void CollectionChangeBuilder::merge(CollectionChangeBuilder&& c)
{
    if (c.empty())
        return;
    if (empty()) {
        *this = std::move(c);
        return;
    }

    verify();
    c.verify();

    // First update any old moves
    if (!c.moves.empty() || !c.deletions.empty() || !c.insertions.empty()) {
        auto it = std::remove_if(begin(moves), end(moves), [&](auto& old) {
            // Check if the moved row was moved again, and if so just update the destination
            auto it = find_if(begin(c.moves), end(c.moves), [&](auto const& m) {
                return old.to == m.from;
            });
            if (it != c.moves.end()) {
                if (modifications.contains(it->from))
                    c.modifications.add(it->to);
                old.to = it->to;
                *it = c.moves.back();
                c.moves.pop_back();
                ++it;
                return false;
            }

            // Check if the destination was deleted
            // Removing the insert for this move will happen later
            if (c.deletions.contains(old.to))
                return true;

            // Update the destination to adjust for any new insertions and deletions
            old.to = c.insertions.shift(c.deletions.unshift(old.to));
            return false;
        });
        moves.erase(it, end(moves));
    }

    // Ignore new moves of rows which were previously inserted (the implicit
    // delete from the move will remove the insert)
    if (!insertions.empty() && !c.moves.empty()) {
        c.moves.erase(std::remove_if(begin(c.moves), end(c.moves),
                              [&](auto const& m) { return insertions.contains(m.from); }),
                    end(c.moves));
    }

    // Ensure that any previously modified rows which were moved are still modified
    if (!modifications.empty() && !c.moves.empty()) {
        for (auto const& move : c.moves) {
            if (modifications.contains(move.from))
                c.modifications.add(move.to);
        }
    }

    // Update the source position of new moves to compensate for the changes made
    // in the old changeset
    if (!deletions.empty() || !insertions.empty()) {
        for (auto& move : c.moves)
            move.from = deletions.shift(insertions.unshift(move.from));
    }

    moves.insert(end(moves), begin(c.moves), end(c.moves));

    // New deletion indices have been shifted by the insertions, so unshift them
    // before adding
    deletions.add_shifted_by(insertions, c.deletions);

    // Drop any inserted-then-deleted rows, then merge in new insertions
    insertions.erase_at(c.deletions);
    insertions.insert_at(c.insertions);

    clean_up_stale_moves();

    modifications.erase_at(c.deletions);
    modifications.shift_for_insert_at(c.insertions);
    modifications.add(c.modifications);

    c = {};
    verify();
}

void CollectionChangeBuilder::clean_up_stale_moves()
{
    // Look for moves which are now no-ops, and remove them plus the associated
    // insert+delete. Note that this isn't just checking for from == to due to
    // that rows can also be shifted by other inserts and deletes
    moves.erase(std::remove_if(begin(moves), end(moves), [&](auto const& move) {
        if (move.from - deletions.count(0, move.from) != move.to - insertions.count(0, move.to))
            return false;
        deletions.remove(move.from);
        insertions.remove(move.to);
        return true;
    }), end(moves));
}

void CollectionChangeBuilder::parse_complete()
{
    moves.reserve(m_move_mapping.size());
    for (auto move : m_move_mapping) {
        REALM_ASSERT_DEBUG(deletions.contains(move.second));
        REALM_ASSERT_DEBUG(insertions.contains(move.first));
        moves.push_back({move.second, move.first});
    }
    m_move_mapping.clear();
    std::sort(begin(moves), end(moves),
              [](auto const& a, auto const& b) { return a.from < b.from; });
}

void CollectionChangeBuilder::modify(size_t ndx)
{
    modifications.add(ndx);
}

void CollectionChangeBuilder::insert(size_t index, size_t count, bool track_moves)
{
    modifications.shift_for_insert_at(index, count);
    if (!track_moves)
        return;

    insertions.insert_at(index, count);

    for (auto& move : moves) {
        if (move.to >= index)
            ++move.to;
    }
}

void CollectionChangeBuilder::erase(size_t index)
{
    modifications.erase_at(index);
    size_t unshifted = insertions.erase_or_unshift(index);
    if (unshifted != IndexSet::npos)
        deletions.add_shifted(unshifted);

    for (size_t i = 0; i < moves.size(); ++i) {
        auto& move = moves[i];
        if (move.to == index) {
            moves.erase(moves.begin() + i);
            --i;
        }
        else if (move.to > index)
            --move.to;
    }
}

void CollectionChangeBuilder::clear(size_t old_size)
{
    if (old_size != std::numeric_limits<size_t>::max()) {
        for (auto range : deletions)
            old_size += range.second - range.first;
        for (auto range : insertions)
            old_size -= range.second - range.first;
    }

    modifications.clear();
    insertions.clear();
    moves.clear();
    m_move_mapping.clear();
    deletions.set(old_size);
}

void CollectionChangeBuilder::move(size_t from, size_t to)
{
    REALM_ASSERT(from != to);

    bool updated_existing_move = false;
    for (auto& move : moves) {
        if (move.to != from) {
            // Shift other moves if this row is moving from one side of them
            // to the other
            if (move.to >= to && move.to < from)
                ++move.to;
            else if (move.to <= to && move.to > from)
                --move.to;
            continue;
        }
        REALM_ASSERT(!updated_existing_move);

        // Collapse A -> B, B -> C into a single A -> C move
        move.to = to;
        updated_existing_move = true;

        insertions.erase_at(from);
        insertions.insert_at(to);
    }

    if (!updated_existing_move) {
        auto shifted_from = insertions.erase_or_unshift(from);
        insertions.insert_at(to);

        // Don't report deletions/moves for newly inserted rows
        if (shifted_from != IndexSet::npos) {
            shifted_from = deletions.add_shifted(shifted_from);
            moves.push_back({shifted_from, to});
        }
    }

    bool modified = modifications.contains(from);
    modifications.erase_at(from);

    if (modified)
        modifications.insert_at(to);
    else
        modifications.shift_for_insert_at(to);
}

void CollectionChangeBuilder::move_over(size_t row_ndx, size_t last_row, bool track_moves)
{
    REALM_ASSERT(row_ndx <= last_row);
    REALM_ASSERT(insertions.empty() || prev(insertions.end())->second - 1 <= last_row);
    REALM_ASSERT(modifications.empty() || prev(modifications.end())->second - 1 <= last_row);

    if (row_ndx == last_row) {
        if (track_moves) {
            auto shifted_from = insertions.erase_or_unshift(row_ndx);
            if (shifted_from != IndexSet::npos)
                deletions.add_shifted(shifted_from);
            m_move_mapping.erase(row_ndx);
        }
        modifications.remove(row_ndx);
        return;
    }

    bool modified = modifications.contains(last_row);
    if (modified) {
        modifications.remove(last_row);
        modifications.add(row_ndx);
    }
    else
        modifications.remove(row_ndx);

    if (!track_moves)
        return;

    bool row_is_insertion = insertions.contains(row_ndx);
    bool last_is_insertion = !insertions.empty() && prev(insertions.end())->second == last_row + 1;
    REALM_ASSERT_DEBUG(insertions.empty() || prev(insertions.end())->second <= last_row + 1);

    // Collapse A -> B, B -> C into a single A -> C move
    bool last_was_already_moved = false;
    if (last_is_insertion) {
        auto it = m_move_mapping.find(last_row);
        if (it != m_move_mapping.end() && it->first == last_row) {
            m_move_mapping[row_ndx] = it->second;
            m_move_mapping.erase(it);
            last_was_already_moved = true;
        }
    }

    // Remove moves to the row being deleted
    if (row_is_insertion && !last_was_already_moved) {
        auto it = m_move_mapping.find(row_ndx);
        if (it != m_move_mapping.end() && it->first == row_ndx)
            m_move_mapping.erase(it);
    }

    // Don't report deletions/moves if last_row is newly inserted
    if (last_is_insertion) {
        insertions.remove(last_row);
    }
    // If it was previously moved, the unshifted source row has already been marked as deleted
    else if (!last_was_already_moved) {
        auto shifted_last_row = insertions.unshift(last_row);
        shifted_last_row = deletions.add_shifted(shifted_last_row);
        m_move_mapping[row_ndx] = shifted_last_row;
    }

    // Don't mark the moved-over row as deleted if it was a new insertion
    if (!row_is_insertion) {
        deletions.add_shifted(insertions.unshift(row_ndx));
        insertions.add(row_ndx);
    }
    verify();
}

void CollectionChangeBuilder::verify()
{
#ifdef REALM_DEBUG
    for (auto&& move : moves) {
        REALM_ASSERT(deletions.contains(move.from));
        REALM_ASSERT(insertions.contains(move.to));
    }
#endif
}

namespace {
struct RowInfo {
    size_t row_index;
    size_t prev_tv_index;
    size_t tv_index;
    size_t shifted_tv_index;
};

void calculate_moves_unsorted(std::vector<RowInfo>& new_rows, IndexSet& removed, CollectionChangeSet& changeset)
{
    size_t expected = 0;
    for (auto& row : new_rows) {
        // With unsorted queries rows only move due to move_last_over(), which
        // inherently can only move a row to earlier in the table.
        REALM_ASSERT(row.shifted_tv_index >= expected);
        if (row.shifted_tv_index == expected) {
            ++expected;
            continue;
        }

        // This row isn't just the row after the previous one, but it still may
        // not be a move if there were rows deleted between the two, so next
        // calcuate what row should be here taking those in to account
        size_t calc_expected = row.tv_index - changeset.insertions.count(0, row.tv_index) + removed.count(0, row.prev_tv_index);
        if (row.shifted_tv_index == calc_expected) {
            expected = calc_expected + 1;
            continue;
        }

        // The row still isn't the expected one, so it's a move
        changeset.moves.push_back({row.prev_tv_index, row.tv_index});
        changeset.insertions.add(row.tv_index);
        removed.add(row.prev_tv_index);
    }
}

class LongestCommonSubsequenceCalculator {
public:
    // A pair of an index in the table and an index in the table view
    struct Row {
        size_t row_index;
        size_t tv_index;
    };

    struct Match {
        // The index in `a` at which this match begins
        size_t i;
        // The index in `b` at which this match begins
        size_t j;
        // The length of this match
        size_t size;
        // The number of rows in this block which were modified
        size_t modified;
    };
    std::vector<Match> m_longest_matches;

    LongestCommonSubsequenceCalculator(std::vector<Row>& a, std::vector<Row>& b,
                                       size_t start_index,
                                       IndexSet const& modifications)
    : m_modified(modifications)
    , a(a), b(b)
    {
        find_longest_matches(start_index, a.size(),
                             start_index, b.size());
        m_longest_matches.push_back({a.size(), b.size(), 0});
    }

private:
    IndexSet const& m_modified;

    // The two arrays of rows being diffed
    // a is sorted by tv_index, b is sorted by row_index
    std::vector<Row> &a, &b;

    // Find the longest matching range in (a + begin1, a + end1) and (b + begin2, b + end2)
    // "Matching" is defined as "has the same row index"; the TV index is just
    // there to let us turn an index in a/b into an index which can be reported
    // in the output changeset.
    //
    // This is done with the O(N) space variant of the dynamic programming
    // algorithm for longest common subsequence, where N is the maximum number
    // of the most common row index (which for everything but linkview-derived
    // TVs will be 1).
    Match find_longest_match(size_t begin1, size_t end1, size_t begin2, size_t end2)
    {
        struct Length {
            size_t j, len;
        };
        // The length of the matching block for each `j` for the previously checked row
        std::vector<Length> prev;
        // The length of the matching block for each `j` for the row currently being checked
        std::vector<Length> cur;

        // Calculate the length of the matching block *ending* at b[j], which
        // is 1 if b[j - 1] did not match, and b[j - 1] + 1 otherwise.
        auto length = [&](size_t j) -> size_t {
            for (auto const& pair : prev) {
                if (pair.j + 1 == j)
                    return pair.len + 1;
            }
            return 1;
        };

        // Iterate over each `j` which has the same row index as a[i] and falls
        // within the range begin2 <= j < end2
        auto for_each_b_match = [&](size_t i, auto&& f) {
            size_t ai = a[i].row_index;
            // Find the TV indicies at which this row appears in the new results
            // There should always be at least one (or it would have been
            // filtered out earlier), but there can be multiple if there are dupes
            auto it = lower_bound(begin(b), end(b), ai,
                                  [](auto lft, auto rgt) { return lft.row_index < rgt; });
            REALM_ASSERT(it != end(b) && it->row_index == ai);
            for (; it != end(b) && it->row_index == ai; ++it) {
                size_t j = it->tv_index;
                if (j < begin2)
                    continue;
                if (j >= end2)
                    break; // b is sorted by tv_index so this can't transition from false to true
                f(j);
            }
        };

        Match best = {begin1, begin2, 0, 0};
        for (size_t i = begin1; i < end1; ++i) {
            // prev = std::move(cur), but avoids discarding prev's heap allocation
            cur.swap(prev);
            cur.clear();

            for_each_b_match(i, [&](size_t j) {
                size_t size = length(j);

                cur.push_back({j, size});

                // If the matching block ending at a[i] and b[j] is longer than
                // the previous one, select it as the best
                if (size > best.size)
                    best = {i - size + 1, j - size + 1, size, IndexSet::npos};
                // Given two equal-length matches, prefer the one with fewer modified rows
                else if (size == best.size) {
                    if (best.modified == IndexSet::npos)
                        best.modified = m_modified.count(best.j - size + 1, best.j + 1);
                    auto count = m_modified.count(j - size + 1, j + 1);
                    if (count < best.modified)
                        best = {i - size + 1, j - size + 1, size, count};
                }

                // The best block should always fall within the range being searched
                REALM_ASSERT(best.i >= begin1 && best.i + best.size <= end1);
                REALM_ASSERT(best.j >= begin2 && best.j + best.size <= end2);
            });
        }
        return best;
    }

    void find_longest_matches(size_t begin1, size_t end1, size_t begin2, size_t end2)
    {
        // FIXME: recursion could get too deep here
        // recursion depth worst case is currently O(N) and each recursion uses 320 bytes of stack
        // could reduce worst case to O(sqrt(N)) (and typical case to O(log N))
        // biasing equal selections towards the middle, but that's still
        // insufficient for Android's 8 KB stacks
        auto m = find_longest_match(begin1, end1, begin2, end2);
        if (!m.size)
            return;
        if (m.i > begin1 && m.j > begin2)
            find_longest_matches(begin1, m.i, begin2, m.j);
        m_longest_matches.push_back(m);
        if (m.i + m.size < end2 && m.j + m.size < end2)
            find_longest_matches(m.i + m.size, end1, m.j + m.size, end2);
    }
};

void calculate_moves_sorted(std::vector<RowInfo>& rows, CollectionChangeSet& changeset)
{
    // The RowInfo array contains information about the old and new TV indices of
    // each row, which we need to turn into two sequences of rows, which we'll
    // then find matches in
    std::vector<LongestCommonSubsequenceCalculator::Row> a, b;

    a.reserve(rows.size());
    for (auto& row : rows) {
        a.push_back({row.row_index, row.prev_tv_index});
    }
    std::sort(begin(a), end(a), [](auto lft, auto rgt) {
        return std::tie(lft.tv_index, lft.row_index) < std::tie(rgt.tv_index, rgt.row_index);
    });

    // Before constructing `b`, first find the first index in `a` which will
    // actually differ in `b`, and skip everything else if there aren't any
    size_t first_difference = IndexSet::npos;
    for (size_t i = 0; i < a.size(); ++i) {
        if (a[i].row_index != rows[i].row_index) {
            first_difference = i;
            break;
        }
    }
    if (first_difference == IndexSet::npos)
        return;

    // Note that `b` is sorted by row_index, while `a` is sorted by tv_index
    b.reserve(rows.size());
    for (size_t i = 0; i < rows.size(); ++i)
        b.push_back({rows[i].row_index, i});
    std::sort(begin(b), end(b), [](auto lft, auto rgt) {
        return std::tie(lft.row_index, lft.tv_index) < std::tie(rgt.row_index, rgt.tv_index);
    });

    // Calculate the LCS of the two sequences
    auto matches = LongestCommonSubsequenceCalculator(a, b, first_difference,
                                                      changeset.modifications).m_longest_matches;

    // And then insert and delete rows as needed to align them
    size_t i = first_difference, j = first_difference;
    for (auto match : matches) {
        for (; i < match.i; ++i)
            changeset.deletions.add(a[i].tv_index);
        for (; j < match.j; ++j)
            changeset.insertions.add(rows[j].tv_index);
        i += match.size;
        j += match.size;
    }
}

} // Anonymous namespace

CollectionChangeBuilder CollectionChangeBuilder::calculate(std::vector<size_t> const& prev_rows,
                                                           std::vector<size_t> const& next_rows,
                                                           std::function<bool (size_t)> row_did_change,
                                                           bool rows_are_in_table_order)
{
    REALM_ASSERT_DEBUG(!rows_are_in_table_order || std::is_sorted(begin(next_rows), end(next_rows)));

    CollectionChangeBuilder ret;

    size_t deleted = 0;
    std::vector<RowInfo> old_rows;
    old_rows.reserve(prev_rows.size());
    for (size_t i = 0; i < prev_rows.size(); ++i) {
        if (prev_rows[i] == IndexSet::npos) {
            ++deleted;
            ret.deletions.add(i);
        }
        else
            old_rows.push_back({prev_rows[i], IndexSet::npos, i, i - deleted});
    }
    std::sort(begin(old_rows), end(old_rows), [](auto& lft, auto& rgt) {
        return lft.row_index < rgt.row_index;
    });

    std::vector<RowInfo> new_rows;
    new_rows.reserve(next_rows.size());
    for (size_t i = 0; i < next_rows.size(); ++i) {
        new_rows.push_back({next_rows[i], IndexSet::npos, i, 0});
    }
    std::sort(begin(new_rows), end(new_rows), [](auto& lft, auto& rgt) {
        return lft.row_index < rgt.row_index;
    });

    // Don't add rows which were modified to not match the query to `deletions`
    // immediately because the unsorted move logic needs to be able to
    // distinguish them from rows which were outright deleted
    IndexSet removed;

    // Now that our old and new sets of rows are sorted by row index, we can
    // iterate over them and either record old+new TV indices for rows present
    // in both, or mark them as inserted/deleted if they appear only in one
    size_t i = 0, j = 0;
    while (i < old_rows.size() && j < new_rows.size()) {
        auto old_index = old_rows[i];
        auto new_index = new_rows[j];
        if (old_index.row_index == new_index.row_index) {
            new_rows[j].prev_tv_index = old_rows[i].tv_index;
            new_rows[j].shifted_tv_index = old_rows[i].shifted_tv_index;
            ++i;
            ++j;
        }
        else if (old_index.row_index < new_index.row_index) {
            removed.add(old_index.tv_index);
            ++i;
        }
        else {
            ret.insertions.add(new_index.tv_index);
            ++j;
        }
    }

    for (; i < old_rows.size(); ++i)
        removed.add(old_rows[i].tv_index);
    for (; j < new_rows.size(); ++j)
        ret.insertions.add(new_rows[j].tv_index);

    // Filter out the new insertions since we don't need them for any of the
    // further calculations
    new_rows.erase(std::remove_if(begin(new_rows), end(new_rows),
                                  [](auto& row) { return row.prev_tv_index == IndexSet::npos; }),
                   end(new_rows));
    std::sort(begin(new_rows), end(new_rows),
              [](auto& lft, auto& rgt) { return lft.tv_index < rgt.tv_index; });

    for (auto& row : new_rows) {
        if (row_did_change(row.row_index)) {
            ret.modifications.add(row.tv_index);
        }
    }

    if (!rows_are_in_table_order) {
        calculate_moves_sorted(new_rows, ret);
    }
    else {
        calculate_moves_unsorted(new_rows, removed, ret);
    }
    ret.deletions.add(removed);
    ret.verify();

#ifdef REALM_DEBUG
    { // Verify that applying the calculated change to prev_rows actually produces next_rows
        auto rows = prev_rows;
        auto it = util::make_reverse_iterator(ret.deletions.end());
        auto end = util::make_reverse_iterator(ret.deletions.begin());
        for (; it != end; ++it) {
            rows.erase(rows.begin() + it->first, rows.begin() + it->second);
        }

        for (auto i : ret.insertions.as_indexes()) {
            rows.insert(rows.begin() + i, next_rows[i]);
        }

        REALM_ASSERT(rows == next_rows);
    }
#endif

    return ret;
}
