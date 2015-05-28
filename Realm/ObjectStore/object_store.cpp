////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#include "object_store.hpp"

using namespace realm;

const char * const c_metadataTableName = "metadata";
const char * const c_versionColumnName = "version";
const size_t c_versionColumnIndex = 0;

const char * const c_primaryKeyTableName = "pk";
const char * const c_primaryKeyObjectClassColumnName = "pk_table";
const size_t c_primaryKeyObjectClassColumnIndex =  0;
const char * const c_primaryKeyPropertyNameColumnName = "pk_property";
const size_t c_primaryKeyPropertyNameColumnIndex =  1;

const uint64_t ObjectStore::NotVersioned = std::numeric_limits<uint64_t>::max();

bool ObjectStore::has_metadata_tables(realm::Group *group) {
    return group->get_table(c_primaryKeyTableName) && group->get_table(c_metadataTableName);
}

bool ObjectStore::create_metadata_tables(realm::Group *group) {
    bool changed = false;
    realm::TableRef table = group->get_or_add_table(c_primaryKeyTableName);
    if (table->get_column_count() == 0) {
        table->add_column(realm::type_String, c_primaryKeyObjectClassColumnName);
        table->add_column(realm::type_String, c_primaryKeyPropertyNameColumnName);
        changed = true;
    }

    table = group->get_or_add_table(c_metadataTableName);
    if (table->get_column_count() == 0) {
        table->add_column(realm::type_Int, c_versionColumnName);

        // set initial version
        table->add_empty_row();
        table->set_int(c_versionColumnIndex, 0, realm::ObjectStore::NotVersioned);
        changed = true;
    }

    return changed;
}

uint64_t ObjectStore::get_schema_version(realm::Group *group) {
    realm::TableRef table = group->get_table(c_metadataTableName);
    if (!table || table->get_column_count() == 0) {
        return realm::ObjectStore::NotVersioned;
    }
    return table->get_int(c_versionColumnIndex, 0);
}

void ObjectStore::set_schema_version(realm::Group *group, uint64_t version) {
    realm::TableRef table = group->get_or_add_table(c_metadataTableName);
    table->set_int(c_versionColumnIndex, 0, version);
}

std::string ObjectStore::get_primary_key_for_object(realm::Group *group, std::string object_type) {
    realm::TableRef table = group->get_table(c_primaryKeyTableName);
    if (!table) {
        return "";
    }
    size_t row = table->find_first_string(c_primaryKeyObjectClassColumnIndex, object_type);
    if (row == realm::not_found) {
        return "";
    }
    return table->get_string(c_primaryKeyPropertyNameColumnIndex, row);
}

void ObjectStore::set_primary_key_for_object(realm::Group *group, std::string object_type, std::string primary_key) {
    realm::TableRef table = group->get_table(c_primaryKeyTableName);

    // get row or create if new object and populate
    size_t row = table->find_first_string(c_primaryKeyObjectClassColumnIndex, object_type);
    if (row == realm::not_found && primary_key.length()) {
        row = table->add_empty_row();
        table->set_string(c_primaryKeyObjectClassColumnIndex, row, object_type);
    }

    // set if changing, or remove if setting to nil
    if (primary_key.length() == 0 && row != realm::not_found) {
        table->remove(row);
    }
    else {
        table->set_string(c_primaryKeyPropertyNameColumnIndex, row, primary_key);
    }
}

