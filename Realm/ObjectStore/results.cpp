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

#include <stdexcept>

using namespace realm;

#ifdef __has_cpp_attribute
#define REALM_HAS_CCP_ATTRIBUTE(attr) __has_cpp_attribute(attr)
#else
#define REALM_HAS_CCP_ATTRIBUTE(attr) 0
#endif

#if REALM_HAS_CCP_ATTRIBUTE(clang::fallthrough)
#define REALM_FALLTHROUGH [[clang::fallthrough]]
#else
#define REALM_FALLTHROUGH
#endif

Results::Results(SharedRealm r, Query q, SortOrder s)
: m_realm(std::move(r))
, m_query(std::move(q))
, m_table(m_query.get_table().get())
, m_sort(std::move(s))
, m_mode(Mode::Query)
{
}

Results::Results(SharedRealm r, Table& table)
: m_realm(std::move(r))
, m_table(&table)
, m_mode(Mode::Table)
{
}

void Results::validate_read() const
{
    if (m_realm && !m_realm->check_thread())
        throw Error::IncorrectThread;
    if (m_table && !m_table->is_attached())
        throw Error::Invalidated;
}

void Results::validate_write() const
{
    validate_read();
    if (!m_realm || !m_realm->is_in_transaction())
        throw Error::NotInWrite;
}

size_t Results::size()
{
    validate_read();
    switch (m_mode) {
        case Mode::Empty: return 0;
        case Mode::Table: return m_table->size();
        case Mode::Query: return m_query.count();
        case Mode::TableView:
            update_tableview();
            return m_table_view.size();
    }
    REALM_UNREACHABLE();
}

RowExpr Results::get(size_t row_ndx)
{
    validate_read();
    switch (m_mode) {
        case Mode::Empty: break;
        case Mode::Table:
            if (row_ndx < m_table->size())
                return m_table->get(row_ndx);
            break;
        case Mode::Query:
        case Mode::TableView:
            update_tableview();
            if (row_ndx < m_table_view.size())
                return m_table_view.get(row_ndx);
            break;
    }

    throw Error::OutOfBoundsIndex;
}

util::Optional<RowExpr> Results::first()
{
    validate_read();
    switch (m_mode) {
        case Mode::Empty:
            return none;
        case Mode::Table:
            return m_table->size() == 0 ? util::none : util::Optional<RowExpr>(m_table->front());
        case Mode::Query:
            update_tableview();
            REALM_FALLTHROUGH;
        case Mode::TableView:
            return m_table_view.size() == 0 ? util::none : util::Optional<RowExpr>(m_table_view.front());
    }
    REALM_UNREACHABLE();
}

util::Optional<RowExpr> Results::last()
{
    validate_read();
    switch (m_mode) {
        case Mode::Empty:
            return none;
        case Mode::Table:
            return m_table->size() == 0 ? util::none : util::Optional<RowExpr>(m_table->back());
        case Mode::Query:
            update_tableview();
            REALM_FALLTHROUGH;
        case Mode::TableView:
            return m_table_view.size() == 0 ? util::none : util::Optional<RowExpr>(m_table_view.back());
    }
    REALM_UNREACHABLE();
}

void Results::update_tableview()
{
    validate_read();
    switch (m_mode) {
        case Mode::Empty:
        case Mode::Table:
            return;
        case Mode::Query:
            m_table_view = m_query.find_all();
            if (m_sort) {
                m_table_view.sort(m_sort.columnIndices, m_sort.ascending);
            }
            m_mode = Mode::TableView;
            break;
        case Mode::TableView:
            m_table_view.sync_if_needed();
            break;
    }
}

size_t Results::index_of(Row const& row)
{
    validate_read();
    if (!row) {
        throw Error::DetachedAccessor;
    }
    if (m_table && row.get_table() != m_table) {
        throw Error::IncorrectTable;
    }
    return index_of(row.get_index());
}

size_t Results::index_of(size_t row_ndx)
{
    validate_read();
    switch (m_mode) {
        case Mode::Empty:
            return not_found;
        case Mode::Table:
            return row_ndx;
        case Mode::Query:
            if (!m_sort)
                return m_query.count(row_ndx, row_ndx + 1) ? m_query.count(0, row_ndx) : not_found;
            REALM_FALLTHROUGH;
        case Mode::TableView:
            update_tableview();
            return m_table_view.find_by_source_ndx(row_ndx);
    }
    REALM_UNREACHABLE();
}

template<typename Int, typename Float, typename Double, typename DateTime>
util::Optional<Mixed> Results::aggregate(size_t column, bool return_none_for_empty,
                                         Int agg_int, Float agg_float,
                                         Double agg_double, DateTime agg_datetime)
{
    validate_read();
    if (!m_table)
        return none;
    if (column > m_table->get_column_count())
        throw Error::OutOfBoundsIndex;

    auto do_agg = [&](auto const& getter) -> util::Optional<Mixed> {
        switch (m_mode) {
            case Mode::Empty:
                return none;
            case Mode::Table:
                if (return_none_for_empty && m_table->size() == 0)
                    return none;
                return util::Optional<Mixed>(getter(*m_table));
            case Mode::Query:
            case Mode::TableView:
                this->update_tableview();
                if (return_none_for_empty && m_table_view.size() == 0)
                    return none;
                return util::Optional<Mixed>(getter(m_table_view));
        }
        REALM_UNREACHABLE();
    };

    switch (m_table->get_column_type(column))
    {
        case type_DateTime: return do_agg(agg_datetime);
        case type_Double: return do_agg(agg_double);
        case type_Float: return do_agg(agg_float);
        case type_Int: return do_agg(agg_int);
        default:
            throw Error::UnsupportedColumnType;
    }
}

util::Optional<Mixed> Results::max(size_t column)
{
    return aggregate(column, true,
                     [=](auto const& table) { return table.maximum_int(column); },
                     [=](auto const& table) { return table.maximum_float(column); },
                     [=](auto const& table) { return table.maximum_double(column); },
                     [=](auto const& table) { return table.maximum_datetime(column); });
}

util::Optional<Mixed> Results::min(size_t column)
{
    return aggregate(column, true,
                     [=](auto const& table) { return table.minimum_int(column); },
                     [=](auto const& table) { return table.minimum_float(column); },
                     [=](auto const& table) { return table.minimum_double(column); },
                     [=](auto const& table) { return table.minimum_datetime(column); });
}

util::Optional<Mixed> Results::sum(size_t column)
{
    return aggregate(column, false,
                     [=](auto const& table) { return table.sum_int(column); },
                     [=](auto const& table) { return table.sum_float(column); },
                     [=](auto const& table) { return table.sum_double(column); },
                     [=](auto const&) -> util::None { throw Error::UnsupportedColumnType; });
}

util::Optional<Mixed> Results::average(size_t column)
{
    return aggregate(column, true,
                     [=](auto const& table) { return table.average_int(column); },
                     [=](auto const& table) { return table.average_float(column); },
                     [=](auto const& table) { return table.average_double(column); },
                     [=](auto const&) -> util::None { throw Error::UnsupportedColumnType; });
}

void Results::clear()
{
    switch (m_mode) {
        case Mode::Empty:
            return;
        case Mode::Table:
            validate_write();
            m_table->clear();
            break;
        case Mode::Query:
            // Not using Query:remove() because bulding the tableview and
            // clearing it is actually significantly faster
        case Mode::TableView:
            validate_write();
            update_tableview();
            m_table_view.clear();
            break;
    }
}

Query Results::get_query() const
{
    validate_read();
    switch (m_mode) {
        case Mode::Empty:
        case Mode::Query:
        case Mode::TableView:
            return m_query;
        case Mode::Table:
            return m_table->where();
    }
    REALM_UNREACHABLE();
}

TableView Results::get_tableview()
{
    validate_read();
    switch (m_mode) {
        case Mode::Empty:
            return {};
        case Mode::Query:
        case Mode::TableView:
            update_tableview();
            return m_table_view;
        case Mode::Table:
            return m_table->where().find_all();
    }
    REALM_UNREACHABLE();
}

Results Results::sort(realm::SortOrder&& sort) const
{
    return Results(m_realm, get_query(), std::move(sort));
}

Results Results::filter(Query&& q) const
{
    return Results(m_realm, get_query().and_query(q), get_sort());
}
