//
//  handover.cpp
//  Realm
//
//  Created by Realm on 7/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

// This is lets our internals access AnyHandover's private constructors.
#define private public
#include "handover.hpp"
#undef private

using namespace realm;

#pragma mark AnyHandoverable

AnyHandoverable::AnyHandoverable(const AnyHandoverable& handover) {
    switch (handover.m_type) {
        case Type::Row:
            new (&m_row) Row(handover.m_row);
            break;

        case Type::Query:
            new (&m_query) Query(handover.m_query);
            break;

        case Type::TableRef:
            new (&m_table_ref) TableRef(handover.m_table_ref);
            break;

        case Type::TableView:
            new (&m_table_view) TableView(handover.m_table_view);
            break;

        case Type::LinkViewRef:
            new (&m_link_view_ref) LinkViewRef(handover.m_link_view_ref);
            break;
    }
    new (&m_type) Type(handover.m_type);
}

AnyHandoverable::AnyHandoverable(AnyHandoverable&& handover) {
    switch (handover.m_type) {
        case Type::Row:
            new (&m_row) Row(std::move(handover.m_row));
            break;

        case Type::Query:
            new (&m_query) Query(std::move(handover.m_query));
            break;

        case Type::TableRef:
            new (&m_table_ref) TableRef(std::move(handover.m_table_ref));
            break;

        case Type::TableView:
            new (&m_table_view) TableView(std::move(handover.m_table_view));
            break;

        case Type::LinkViewRef:
            new (&m_link_view_ref) LinkViewRef(std::move(handover.m_link_view_ref));
            break;
    }
    new (&m_type) Type(std::move(handover.m_type));
}

AnyHandoverable::~AnyHandoverable() {
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

AnyHandover AnyHandoverable::export_for_handover(SharedGroup &shared_group) const {
    switch (m_type) {
        case AnyHandoverable::Type::Row:
            return AnyHandover (shared_group.export_for_handover(m_row));

        case AnyHandoverable::Type::Query:
            return AnyHandover (shared_group.export_for_handover(m_query, ConstSourcePayload::Copy));

        case AnyHandoverable::Type::TableRef:
            return AnyHandover (shared_group.export_table_for_handover(m_table_ref));

        case AnyHandoverable::Type::TableView:
            return AnyHandover (shared_group.export_for_handover(m_table_view, ConstSourcePayload::Copy));

        case AnyHandoverable::Type::LinkViewRef:
            return AnyHandover (shared_group.export_linkview_for_handover(m_link_view_ref));
    }
}

#pragma mark AnyHandover

AnyHandover::AnyHandover(AnyHandover&& handover) {
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

AnyHandover::~AnyHandover() {
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

AnyHandoverable AnyHandover::import_from_handover(SharedGroup &shared_group) &&{
    switch (m_type) {
        case Type::Row:
            return AnyHandoverable (*shared_group.import_from_handover(std::move(m_row)));

        case Type::Query:
            return AnyHandoverable (*shared_group.import_from_handover(std::move(m_query)));

        case Type::Table:
            return AnyHandoverable (shared_group.import_table_from_handover(std::move(m_table)));

        case Type::TableView:
            return AnyHandoverable (*shared_group.import_from_handover(std::move(m_table_view)));
            
        case Type::LinkView:
            return AnyHandoverable (shared_group.import_linkview_from_handover(std::move(m_link_view)));
    }
}

