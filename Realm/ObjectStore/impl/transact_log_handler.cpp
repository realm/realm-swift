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

#include "impl/transact_log_handler.hpp"

#include "binding_context.hpp"
#include "impl/collection_notifier.hpp"
#include "index_set.hpp"

#include <realm/group_shared.hpp>
#include <realm/lang_bind_helper.hpp>
#include <algorithm>

using namespace realm;

namespace {
template<typename Derived>
struct MarkDirtyMixin  {
    bool mark_dirty(size_t row, size_t col) { static_cast<Derived *>(this)->mark_dirty(row, col); return true; }

    bool set_int(size_t col, size_t row, int_fast64_t) { return mark_dirty(row, col); }
    bool set_bool(size_t col, size_t row, bool) { return mark_dirty(row, col); }
    bool set_float(size_t col, size_t row, float) { return mark_dirty(row, col); }
    bool set_double(size_t col, size_t row, double) { return mark_dirty(row, col); }
    bool set_string(size_t col, size_t row, StringData) { return mark_dirty(row, col); }
    bool set_binary(size_t col, size_t row, BinaryData) { return mark_dirty(row, col); }
    bool set_olddatetime(size_t col, size_t row, OldDateTime) { return mark_dirty(row, col); }
    bool set_timestamp(size_t col, size_t row, Timestamp) { return mark_dirty(row, col); }
    bool set_table(size_t col, size_t row) { return mark_dirty(row, col); }
    bool set_mixed(size_t col, size_t row, const Mixed&) { return mark_dirty(row, col); }
    bool set_link(size_t col, size_t row, size_t, size_t) { return mark_dirty(row, col); }
    bool set_null(size_t col, size_t row) { return mark_dirty(row, col); }
    bool nullify_link(size_t col, size_t row, size_t) { return mark_dirty(row, col); }
    bool set_int_unique(size_t col, size_t row, size_t, int_fast64_t) { return mark_dirty(row, col); }
    bool set_string_unique(size_t col, size_t row, size_t, StringData) { return mark_dirty(row, col); }
    bool insert_substring(size_t col, size_t row, size_t, StringData) { return mark_dirty(row, col); }
    bool erase_substring(size_t col, size_t row, size_t, size_t) { return mark_dirty(row, col); }
};

class TransactLogValidationMixin {
    // Index of currently selected table
    size_t m_current_table = 0;

    // Tables which were created during the transaction being processed, which
    // can have columns inserted without a schema version bump
    std::vector<size_t> m_new_tables;

    REALM_NORETURN
    REALM_NOINLINE
    void schema_error()
    {
        throw std::runtime_error("Schema mismatch detected: another process has modified the Realm file's schema in an incompatible way");
    }

    // Throw an exception if the currently modified table already existed before
    // the current set of modifications
    bool schema_error_unless_new_table()
    {
        if (std::find(begin(m_new_tables), end(m_new_tables), m_current_table) == end(m_new_tables)) {
            schema_error();
        }
        return true;
    }

protected:
    size_t current_table() const noexcept { return m_current_table; }

public:
    // Schema changes which don't involve a change in the schema version are
    // allowed
    bool add_search_index(size_t) { return true; }
    bool remove_search_index(size_t) { return true; }

    // Creating entirely new tables without a schema version bump is allowed, so
    // we need to track if new columns are being added to a new table or an
    // existing one
    bool insert_group_level_table(size_t table_ndx, size_t, StringData)
    {
        // Shift any previously added tables after the new one
        for (auto& table : m_new_tables) {
            if (table >= table_ndx)
                ++table;
        }
        m_new_tables.push_back(table_ndx);
        return true;
    }
    bool insert_column(size_t, DataType, StringData, bool) { return schema_error_unless_new_table(); }
    bool insert_link_column(size_t, DataType, StringData, size_t, size_t) { return schema_error_unless_new_table(); }
    bool set_link_type(size_t, LinkType) { return schema_error_unless_new_table(); }

    // Removing or renaming things while a Realm is open is never supported
    bool erase_group_level_table(size_t, size_t) { schema_error(); }
    bool rename_group_level_table(size_t, StringData) { schema_error(); }
    bool erase_column(size_t) { schema_error(); }
    bool erase_link_column(size_t, size_t, size_t) { schema_error(); }
    bool rename_column(size_t, StringData) { schema_error(); }
    bool move_column(size_t, size_t) { schema_error(); }
    bool move_group_level_table(size_t, size_t) { schema_error(); }

    bool select_descriptor(int levels, const size_t*)
    {
        // subtables not supported
        return levels == 0;
    }

    bool select_table(size_t group_level_ndx, int, const size_t*) noexcept
    {
        m_current_table = group_level_ndx;
        return true;
    }

    bool select_link_list(size_t, size_t, size_t) { return true; }

    // Non-schema changes are all allowed
    void parse_complete() { }
    bool insert_empty_rows(size_t, size_t, size_t, bool) { return true; }
    bool erase_rows(size_t, size_t, size_t, bool) { return true; }
    bool swap_rows(size_t, size_t) { return true; }
    bool clear_table() noexcept { return true; }
    bool link_list_set(size_t, size_t) { return true; }
    bool link_list_insert(size_t, size_t) { return true; }
    bool link_list_erase(size_t) { return true; }
    bool link_list_nullify(size_t) { return true; }
    bool link_list_clear(size_t) { return true; }
    bool link_list_move(size_t, size_t) { return true; }
    bool link_list_swap(size_t, size_t) { return true; }
    bool change_link_targets(size_t, size_t) { return true; }
    bool optimize_table() { return true; }
};


// A transaction log handler that just validates that all operations made are
// ones supported by the object store
struct TransactLogValidator : public TransactLogValidationMixin, public MarkDirtyMixin<TransactLogValidator> {
    void mark_dirty(size_t, size_t) { }
};

// Extends TransactLogValidator to also track changes and report it to the
// binding context if any properties are being observed
class TransactLogObserver : public TransactLogValidationMixin, public MarkDirtyMixin<TransactLogObserver> {
    using ColumnInfo = BindingContext::ColumnInfo;
    using ObserverState = BindingContext::ObserverState;

    // Observed table rows which need change information
    std::vector<ObserverState> m_observers;
    // Userdata pointers for rows which have been deleted
    std::vector<void *> invalidated;
    // Delegate to send change information to
    BindingContext* m_context;

    // Change information for the currently selected LinkList, if any
    ColumnInfo* m_active_linklist = nullptr;

    // Tables which were created during the transaction being processed, which
    // can have columns inserted without a schema version bump
    std::vector<size_t> m_new_tables;

    // Get the change info for the given column, creating it if needed
    static ColumnInfo& get_change(ObserverState& state, size_t i)
    {
        if (state.changes.size() <= i) {
            state.changes.resize(std::max(state.changes.size() * 2, i + 1));
        }
        return state.changes[i];
    }

    // Loop over the columns which were changed in an observer state
    template<typename Func>
    static void for_each(ObserverState& state, Func&& f)
    {
        for (size_t i = 0; i < state.changes.size(); ++i) {
            auto const& change = state.changes[i];
            if (change.changed) {
                f(i, change);
            }
        }
    }

    // Remove the given observer from the list of observed objects and add it
    // to the listed of invalidated objects
    void invalidate(ObserverState *o)
    {
        invalidated.push_back(o->info);
        m_observers.erase(m_observers.begin() + (o - &m_observers[0]));
    }

public:
    template<typename Func>
    TransactLogObserver(BindingContext* context, SharedGroup& sg, Func&& func, bool validate_schema_changes)
    : m_context(context)
    {
        if (!context) {
            if (validate_schema_changes) {
                func(TransactLogValidator());
            }
            else {
                func();
            }
            return;
        }

        m_observers = context->get_observed_rows();
        if (m_observers.empty()) {
            auto old_version = sg.get_version_of_current_transaction();
            if (validate_schema_changes) {
                func(TransactLogValidator());
            }
            else {
                func();
            }
            if (old_version != sg.get_version_of_current_transaction()) {
                context->did_change({}, {});
            }
            return;
        }

        func(*this);
        context->did_change(m_observers, invalidated);
    }

    // Mark the given row/col as needing notifications sent
    void mark_dirty(size_t row_ndx, size_t col_ndx)
    {
        auto it = lower_bound(begin(m_observers), end(m_observers), ObserverState{current_table(), row_ndx, nullptr});
        if (it != end(m_observers) && it->table_ndx == current_table() && it->row_ndx == row_ndx) {
            get_change(*it, col_ndx).changed = true;
        }
    }

    // Called at the end of the transaction log immediately before the version
    // is advanced
    void parse_complete()
    {
        m_context->will_change(m_observers, invalidated);
    }

    bool insert_group_level_table(size_t table_ndx, size_t prior_size, StringData name)
    {
        for (auto& observer : m_observers) {
            if (observer.table_ndx >= table_ndx)
                ++observer.table_ndx;
        }
        TransactLogValidationMixin::insert_group_level_table(table_ndx, prior_size, name);
        return true;
    }

    bool insert_empty_rows(size_t, size_t, size_t, bool)
    {
        // rows are only inserted at the end, so no need to do anything
        return true;
    }

    bool erase_rows(size_t row_ndx, size_t, size_t last_row_ndx, bool unordered)
    {
        for (size_t i = 0; i < m_observers.size(); ++i) {
            auto& o = m_observers[i];
            if (o.table_ndx == current_table()) {
                if (o.row_ndx == row_ndx) {
                    invalidate(&o);
                    --i;
                }
                else if (unordered && o.row_ndx == last_row_ndx) {
                    o.row_ndx = row_ndx;
                }
                else if (!unordered && o.row_ndx > row_ndx) {
                    o.row_ndx -= 1;
                }
            }
        }
        return true;
    }

    bool clear_table()
    {
        for (size_t i = 0; i < m_observers.size(); ) {
            auto& o = m_observers[i];
            if (o.table_ndx == current_table()) {
                invalidate(&o);
            }
            else {
                ++i;
            }
        }
        return true;
    }

    bool select_link_list(size_t col, size_t row, size_t)
    {
        m_active_linklist = nullptr;
        for (auto& o : m_observers) {
            if (o.table_ndx == current_table() && o.row_ndx == row) {
                m_active_linklist = &get_change(o, col);
                break;
            }
        }
        return true;
    }

    void append_link_list_change(ColumnInfo::Kind kind, size_t index) {
        ColumnInfo *o = m_active_linklist;
        if (!o || o->kind == ColumnInfo::Kind::SetAll) {
            // Active LinkList isn't observed or already has multiple kinds of changes
            return;
        }

        if (o->kind == ColumnInfo::Kind::None) {
            o->kind = kind;
            o->changed = true;
            o->indices.add(index);
        }
        else if (o->kind == kind) {
            if (kind == ColumnInfo::Kind::Remove) {
                o->indices.add_shifted(index);
            }
            else if (kind == ColumnInfo::Kind::Insert) {
                o->indices.insert_at(index);
            }
            else {
                o->indices.add(index);
            }
        }
        else {
            // Array KVO can only send a single kind of change at a time, so
            // if there are multiple just give up and send "Set"
            o->indices.set(0);
            o->kind = ColumnInfo::Kind::SetAll;
        }
    }

    bool link_list_set(size_t index, size_t)
    {
        append_link_list_change(ColumnInfo::Kind::Set, index);
        return true;
    }

    bool link_list_insert(size_t index, size_t)
    {
        append_link_list_change(ColumnInfo::Kind::Insert, index);
        return true;
    }

    bool link_list_erase(size_t index)
    {
        append_link_list_change(ColumnInfo::Kind::Remove, index);
        return true;
    }

    bool link_list_nullify(size_t index)
    {
        append_link_list_change(ColumnInfo::Kind::Remove, index);
        return true;
    }

    bool link_list_swap(size_t index1, size_t index2)
    {
        append_link_list_change(ColumnInfo::Kind::Set, index1);
        append_link_list_change(ColumnInfo::Kind::Set, index2);
        return true;
    }

    bool link_list_clear(size_t old_size)
    {
        ColumnInfo *o = m_active_linklist;
        if (!o || o->kind == ColumnInfo::Kind::SetAll) {
            return true;
        }

        if (o->kind == ColumnInfo::Kind::Remove)
            old_size += o->indices.count();
        else if (o->kind == ColumnInfo::Kind::Insert)
            old_size -= o->indices.count();

        o->indices.set(old_size);

        o->kind = ColumnInfo::Kind::Remove;
        o->changed = true;
        return true;
    }

    bool link_list_move(size_t from, size_t to)
    {
        ColumnInfo *o = m_active_linklist;
        if (!o || o->kind == ColumnInfo::Kind::SetAll) {
            return true;
        }
        if (from > to) {
            std::swap(from, to);
        }

        if (o->kind == ColumnInfo::Kind::None) {
            o->kind = ColumnInfo::Kind::Set;
            o->changed = true;
        }
        if (o->kind == ColumnInfo::Kind::Set) {
            for (size_t i = from; i <= to; ++i)
                o->indices.add(i);
        }
        else {
            o->indices.set(0);
            o->kind = ColumnInfo::Kind::SetAll;
        }
        return true;
    }
};

// Extends TransactLogValidator to track changes made to LinkViews
class LinkViewObserver : public TransactLogValidationMixin, public MarkDirtyMixin<LinkViewObserver> {
    _impl::TransactionChangeInfo& m_info;
    _impl::CollectionChangeBuilder* m_active = nullptr;

    _impl::CollectionChangeBuilder* get_change()
    {
        auto tbl_ndx = current_table();
        if (tbl_ndx >= m_info.table_modifications_needed.size() || !m_info.table_modifications_needed[tbl_ndx])
            return nullptr;
        if (m_info.tables.size() <= tbl_ndx) {
            m_info.tables.resize(std::max(m_info.tables.size() * 2, tbl_ndx + 1));
        }
        return &m_info.tables[tbl_ndx];
    }

    bool need_move_info() const
    {
        auto tbl_ndx = current_table();
        return tbl_ndx < m_info.table_moves_needed.size() && m_info.table_moves_needed[tbl_ndx];
    }

public:
    LinkViewObserver(_impl::TransactionChangeInfo& info)
    : m_info(info) { }

    void mark_dirty(size_t row, __unused size_t col)
    {
        if (auto change = get_change())
            change->modify(row);
    }

    void parse_complete()
    {
        for (auto& table : m_info.tables) {
            table.parse_complete();
        }
        for (auto& list : m_info.lists) {
            list.changes->clean_up_stale_moves();
        }
    }

    bool select_link_list(size_t col, size_t row, size_t)
    {
        mark_dirty(row, col);

        m_active = nullptr;
        // When there are multiple source versions there could be multiple
        // change objects for a single LinkView, in which case we need to use
        // the last one
        for (auto it = m_info.lists.rbegin(), end = m_info.lists.rend(); it != end; ++it) {
            if (it->table_ndx == current_table() && it->row_ndx == row && it->col_ndx == col) {
                m_active = it->changes;
                break;
            }
        }
        return true;
    }

    bool link_list_set(size_t index, size_t)
    {
        if (m_active)
            m_active->modify(index);
        return true;
    }

    bool link_list_insert(size_t index, size_t)
    {
        if (m_active)
            m_active->insert(index);
        return true;
    }

    bool link_list_erase(size_t index)
    {
        if (m_active)
            m_active->erase(index);
        return true;
    }

    bool link_list_nullify(size_t index)
    {
        return link_list_erase(index);
    }

    bool link_list_swap(size_t index1, size_t index2)
    {
        link_list_set(index1, 0);
        link_list_set(index2, 0);
        return true;
    }

    bool link_list_clear(size_t old_size)
    {
        if (m_active)
            m_active->clear(old_size);
        return true;
    }

    bool link_list_move(size_t from, size_t to)
    {
        if (m_active)
            m_active->move(from, to);
        return true;
    }

    bool insert_empty_rows(size_t row_ndx, size_t num_rows_to_insert, size_t, bool unordered)
    {
        REALM_ASSERT(!unordered);
        if (auto change = get_change())
            change->insert(row_ndx, num_rows_to_insert, need_move_info());

        return true;
    }

    bool erase_rows(size_t row_ndx, size_t, size_t prior_num_rows, bool unordered)
    {
        REALM_ASSERT(unordered);
        size_t last_row = prior_num_rows - 1;

        for (auto it = begin(m_info.lists); it != end(m_info.lists); ) {
            if (it->table_ndx == current_table()) {
                if (it->row_ndx == row_ndx) {
                    *it = std::move(m_info.lists.back());
                    m_info.lists.pop_back();
                    continue;
                }
                if (it->row_ndx == last_row - 1)
                    it->row_ndx = row_ndx;
            }
            ++it;
        }

        if (auto change = get_change())
            change->move_over(row_ndx, last_row, need_move_info());
        return true;
    }

    bool clear_table()
    {
        auto tbl_ndx = current_table();
        auto it = remove_if(begin(m_info.lists), end(m_info.lists),
                            [&](auto const& lv) { return lv.table_ndx == tbl_ndx; });
        m_info.lists.erase(it, end(m_info.lists));
        if (auto change = get_change())
            change->clear(std::numeric_limits<size_t>::max());
        return true;
    }
};
} // anonymous namespace

namespace realm {
namespace _impl {
namespace transaction {
void advance(SharedGroup& sg, BindingContext* context, SharedGroup::VersionID version)
{
    TransactLogObserver(context, sg, [&](auto&&... args) {
        LangBindHelper::advance_read(sg, std::move(args)..., version);
    }, true);
}

void begin(SharedGroup& sg, BindingContext* context, bool validate_schema_changes)
{
    TransactLogObserver(context, sg, [&](auto&&... args) {
        LangBindHelper::promote_to_write(sg, std::move(args)...);
    }, validate_schema_changes);
}

void commit(SharedGroup& sg, BindingContext* context)
{
    LangBindHelper::commit_and_continue_as_read(sg);

    if (context) {
        context->did_change({}, {});
    }
}

void cancel(SharedGroup& sg, BindingContext* context)
{
    TransactLogObserver(context, sg, [&](auto&&... args) {
        LangBindHelper::rollback_and_continue_as_read(sg, std::move(args)...);
    }, false);
}

void advance(SharedGroup& sg,
             TransactionChangeInfo& info,
             SharedGroup::VersionID version)
{
    if (info.table_modifications_needed.empty() && info.lists.empty()) {
        LangBindHelper::advance_read(sg, version);
    }
    else {
        LangBindHelper::advance_read(sg, LinkViewObserver(info), version);
    }

}

} // namespace transaction
} // namespace _impl
} // namespace realm
