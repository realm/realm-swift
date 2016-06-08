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

#include "list.hpp"

#include "impl/list_notifier.hpp"
#include "impl/realm_coordinator.hpp"
#include "results.hpp"
#include "shared_realm.hpp"
#include "util/format.hpp"

#include <realm/link_view.hpp>

using namespace realm;
using namespace realm::_impl;

List::List() noexcept = default;
List::~List() = default;

List::List(const List&) = default;
List& List::operator=(const List&) = default;
List::List(List&&) = default;
List& List::operator=(List&&) = default;

List::List(std::shared_ptr<Realm> r, LinkViewRef l) noexcept
: m_realm(std::move(r))
, m_link_view(std::move(l))
{
}

Query List::get_query() const
{
    verify_attached();
    return m_link_view->get_target_table().where(m_link_view);
}

size_t List::get_origin_row_index() const
{
    verify_attached();
    return m_link_view->get_origin_row_index();
}

void List::verify_valid_row(size_t row_ndx, bool insertion) const
{
    size_t size = m_link_view->size();
    if (row_ndx > size || (!insertion && row_ndx == size)) {
        throw OutOfBoundsIndexException{row_ndx, size + insertion};
    }
}

bool List::is_valid() const
{
    m_realm->verify_thread();
    return m_link_view && m_link_view->is_attached();
}

void List::verify_attached() const
{
    if (!is_valid()) {
        throw InvalidatedException{};
    }
}

void List::verify_in_transaction() const
{
    verify_attached();
    if (!m_realm->is_in_transaction()) {
        throw InvalidTransactionException("Must be in a write transaction");
    }
}

size_t List::size() const
{
    verify_attached();
    return m_link_view->size();
}

RowExpr List::get(size_t row_ndx) const
{
    verify_attached();
    verify_valid_row(row_ndx);
    return m_link_view->get(row_ndx);
}

size_t List::get_unchecked(size_t row_ndx) const noexcept
{
    return m_link_view->get(row_ndx).get_index();
}

size_t List::find(ConstRow const& row) const
{
    verify_attached();

    if (!row.is_attached() || row.get_table() != &m_link_view->get_target_table()) {
        return not_found;
    }

    return m_link_view->find(row.get_index());
}

void List::add(size_t target_row_ndx)
{
    verify_in_transaction();
    m_link_view->add(target_row_ndx);
}

void List::insert(size_t row_ndx, size_t target_row_ndx)
{
    verify_in_transaction();
    verify_valid_row(row_ndx, true);
    m_link_view->insert(row_ndx, target_row_ndx);
}

void List::move(size_t source_ndx, size_t dest_ndx)
{
    verify_in_transaction();
    verify_valid_row(source_ndx);
    verify_valid_row(dest_ndx); // Can't be one past end due to removing one earlier
    m_link_view->move(source_ndx, dest_ndx);
}

void List::remove(size_t row_ndx)
{
    verify_in_transaction();
    verify_valid_row(row_ndx);
    m_link_view->remove(row_ndx);
}

void List::remove_all()
{
    verify_in_transaction();
    m_link_view->clear();
}

void List::set(size_t row_ndx, size_t target_row_ndx)
{
    verify_in_transaction();
    verify_valid_row(row_ndx);
    m_link_view->set(row_ndx, target_row_ndx);
}

void List::swap(size_t ndx1, size_t ndx2)
{
    verify_in_transaction();
    verify_valid_row(ndx1);
    verify_valid_row(ndx2);
    m_link_view->swap(ndx1, ndx2);
}

void List::delete_all()
{
    verify_in_transaction();
    m_link_view->remove_all_target_rows();
}

Results List::sort(SortOrder order)
{
    verify_attached();
    return Results(m_realm, m_link_view, util::none, std::move(order));
}

Results List::filter(Query q)
{
    verify_attached();
    return Results(m_realm, m_link_view, get_query().and_query(std::move(q)));
}

// These definitions rely on that LinkViews are interned by core
bool List::operator==(List const& rgt) const noexcept
{
    return m_link_view.get() == rgt.m_link_view.get();
}

namespace std {
size_t hash<realm::List>::operator()(realm::List const& list) const
{
    return std::hash<void*>()(list.m_link_view.get());
}
}

NotificationToken List::add_notification_callback(CollectionChangeCallback cb)
{
    verify_attached();
    if (!m_notifier) {
        m_notifier = std::make_shared<ListNotifier>(m_link_view, m_realm);
        RealmCoordinator::register_notifier(m_notifier);
    }
    return {m_notifier, m_notifier->add_callback(std::move(cb))};
}

List::OutOfBoundsIndexException::OutOfBoundsIndexException(size_t r, size_t c)
: std::out_of_range(util::format("Requested index %1 greater than max %2", r, c))
, requested(r), valid_count(c) {}
