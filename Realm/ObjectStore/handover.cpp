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

#include "handover.hpp"

using namespace realm;

AnyThreadConfined::AnyThreadConfined(const AnyThreadConfined& thread_confined)
{
    switch (thread_confined.m_type) {
        case Type::Row:
            new (&m_row) Row(thread_confined.m_row);
            break;

        case Type::Query:
            new (&m_query) Query(thread_confined.m_query);
            break;

        case Type::TableRef:
            new (&m_table_ref) TableRef(thread_confined.m_table_ref);
            break;

        case Type::TableView:
            new (&m_table_view) TableView(thread_confined.m_table_view);
            break;

        case Type::LinkViewRef:
            new (&m_link_view_ref) LinkViewRef(thread_confined.m_link_view_ref);
            break;
    }
    new (&m_type) Type(thread_confined.m_type);
}

AnyThreadConfined::AnyThreadConfined(AnyThreadConfined&& thread_confined)
{
    switch (thread_confined.m_type) {
        case Type::Row:
            new (&m_row) Row(std::move(thread_confined.m_row));
            break;

        case Type::Query:
            new (&m_query) Query(std::move(thread_confined.m_query));
            break;

        case Type::TableRef:
            new (&m_table_ref) TableRef(std::move(thread_confined.m_table_ref));
            break;

        case Type::TableView:
            new (&m_table_view) TableView(std::move(thread_confined.m_table_view));
            break;

        case Type::LinkViewRef:
            new (&m_link_view_ref) LinkViewRef(std::move(thread_confined.m_link_view_ref));
            break;
    }
    new (&m_type) Type(std::move(thread_confined.m_type));
}

AnyThreadConfined::~AnyThreadConfined()
{
    switch (m_type) {
        case Type::Row:
            m_row.~Row();
            break;

        case Type::Query:
            m_query.~Query();
            break;

        case Type::TableRef:
            m_table_ref.~TableRef();
            break;

        case Type::TableView:
            m_table_view.~TableView();
            break;

        case Type::LinkViewRef:
            m_link_view_ref.~LinkViewRef();
            break;
    }
}

AnyHandover AnyThreadConfined::export_for_handover(SharedGroup &shared_group) const
{
    switch (m_type) {
        case AnyThreadConfined::Type::Row:
            return AnyHandover(shared_group.export_for_handover(m_row));

        case AnyThreadConfined::Type::Query:
            return AnyHandover(shared_group.export_for_handover(m_query, ConstSourcePayload::Copy));

        case AnyThreadConfined::Type::TableRef:
            return AnyHandover(shared_group.export_table_for_handover(m_table_ref));

        case AnyThreadConfined::Type::TableView:
            return AnyHandover(shared_group.export_for_handover(m_table_view, ConstSourcePayload::Copy));

        case AnyThreadConfined::Type::LinkViewRef:
            return AnyHandover(shared_group.export_linkview_for_handover(m_link_view_ref));
    }
}

AnyHandover::AnyHandover(AnyHandover&& handover)
{
    switch (handover.m_type) {
        case Type::Row:
            new (&m_row) RowHandover(std::move(handover.m_row));
            break;

        case Type::Query:
            new (&m_query) QueryHandover(std::move(handover.m_query));
            break;

        case Type::Table:
            new (&m_table) TableHandover(std::move(handover.m_table));
            break;

        case Type::TableView:
            new (&m_table_view) TableViewHandover(std::move(handover.m_table_view));
            break;

        case Type::LinkView:
            new (&m_link_view) LinkViewHandover(std::move(handover.m_link_view));
            break;
    }
    new (&m_type) Type(handover.m_type);
}

AnyHandover::~AnyHandover()
{
    switch (m_type) {
        case Type::Row:
            m_row.~unique_ptr();
            break;

        case Type::Query:
            m_query.~unique_ptr();
            break;

        case Type::Table:
            m_table.~unique_ptr();
            break;

        case Type::TableView:
            m_table_view.~unique_ptr();
            break;

        case Type::LinkView:
            m_link_view.~unique_ptr();
            break;
    }
}

AnyThreadConfined AnyHandover::import_from_handover(SharedGroup &shared_group) &&
{
    switch (m_type) {
        case Type::Row:
            return AnyThreadConfined(*shared_group.import_from_handover(std::move(m_row)));

        case Type::Query:
            return AnyThreadConfined(*shared_group.import_from_handover(std::move(m_query)));

        case Type::Table:
            return AnyThreadConfined(shared_group.import_table_from_handover(std::move(m_table)));

        case Type::TableView:
            return AnyThreadConfined(*shared_group.import_from_handover(std::move(m_table_view)));
            
        case Type::LinkView:
            return AnyThreadConfined(shared_group.import_linkview_from_handover(std::move(m_link_view)));
    }
}
