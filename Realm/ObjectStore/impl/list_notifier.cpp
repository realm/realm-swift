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

#include "impl/list_notifier.hpp"

#include "shared_realm.hpp"

#include <realm/link_view.hpp>

using namespace realm;
using namespace realm::_impl;

ListNotifier::ListNotifier(LinkViewRef lv, std::shared_ptr<Realm> realm)
: CollectionNotifier(std::move(realm))
, m_prev_size(lv->size())
{
    // Find the lv's column, since that isn't tracked directly
    size_t row_ndx = lv->get_origin_row_index();
    m_col_ndx = not_found;
    auto& table = lv->get_origin_table();
    for (size_t i = 0, count = table.get_column_count(); i != count; ++i) {
        if (table.get_column_type(i) == type_LinkList && table.get_linklist(i, row_ndx) == lv) {
            m_col_ndx = i;
            break;
        }
    }
    REALM_ASSERT(m_col_ndx != not_found);

    set_table(lv->get_target_table());

    auto& sg = Realm::Internal::get_shared_group(*get_realm());
    m_lv_handover = sg.export_linkview_for_handover(lv);
}

void ListNotifier::release_data() noexcept
{
    m_lv.reset();
}

void ListNotifier::do_attach_to(SharedGroup& sg)
{
    REALM_ASSERT(m_lv_handover);
    REALM_ASSERT(!m_lv);
    m_lv = sg.import_linkview_from_handover(std::move(m_lv_handover));
}

void ListNotifier::do_detach_from(SharedGroup& sg)
{
    REALM_ASSERT(!m_lv_handover);
    if (m_lv) {
        m_lv_handover = sg.export_linkview_for_handover(m_lv);
        m_lv = {};
    }
}

bool ListNotifier::do_add_required_change_info(TransactionChangeInfo& info)
{
    REALM_ASSERT(!m_lv_handover);
    if (!m_lv || !m_lv->is_attached()) {
        return false; // origin row was deleted after the notification was added
    }

    size_t row_ndx = m_lv->get_origin_row_index();
    auto& table = m_lv->get_origin_table();
    info.lists.push_back({table.get_index_in_group(), row_ndx, m_col_ndx, &m_change});

    m_info = &info;
    return true;
}

void ListNotifier::run()
{
    if (!m_lv || !m_lv->is_attached()) {
        // LV was deleted, so report all of the rows being removed if this is
        // the first run after that
        if (m_prev_size) {
            m_change.deletions.set(m_prev_size);
            m_prev_size = 0;
        }
        else {
            m_change = {};
        }
        return;
    }

    auto row_did_change = get_modification_checker(*m_info, m_lv->get_target_table());
    for (size_t i = 0; i < m_lv->size(); ++i) {
        if (m_change.modifications.contains(i))
            continue;
        if (row_did_change(m_lv->get(i).get_index()))
            m_change.modifications.add(i);
    }

    for (auto const& move : m_change.moves) {
        if (m_change.modifications.contains(move.to))
            continue;
        if (row_did_change(m_lv->get(move.to).get_index()))
            m_change.modifications.add(move.to);
    }

    m_prev_size = m_lv->size();
}

void ListNotifier::do_prepare_handover(SharedGroup&)
{
    add_changes(std::move(m_change));
}
