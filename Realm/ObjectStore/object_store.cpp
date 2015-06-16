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

#include "object_store.hpp"

#include <realm/group.hpp>
#include <realm/table.hpp>
#include <realm/link_view.hpp>
#include <realm/table_view.hpp>
#include <realm/util/assert.hpp>

#include <string.h>

using namespace realm;
using namespace std;

const char * const c_metadataTableName = "metadata";
const char * const c_versionColumnName = "version";
const size_t c_versionColumnIndex = 0;

const char * const c_primaryKeyTableName = "pk";
const char * const c_primaryKeyObjectClassColumnName = "pk_table";
const size_t c_primaryKeyObjectClassColumnIndex =  0;
const char * const c_primaryKeyPropertyNameColumnName = "pk_property";
const size_t c_primaryKeyPropertyNameColumnIndex =  1;

const size_t c_zeroRowIndex = 0;

const string c_object_table_prefix = "class_";
const size_t c_object_table_prefix_length = c_object_table_prefix.length();

const uint64_t ObjectStore::NotVersioned = numeric_limits<uint64_t>::max();

bool ObjectStore::create_metadata_tables(Group *group) {
    bool changed = false;
    TableRef table = group->get_or_add_table(c_primaryKeyTableName);
    if (table->get_column_count() == 0) {
        table->add_column(type_String, c_primaryKeyObjectClassColumnName);
        table->add_column(type_String, c_primaryKeyPropertyNameColumnName);
        changed = true;
    }

    table = group->get_or_add_table(c_metadataTableName);
    if (table->get_column_count() == 0) {
        table->add_column(type_Int, c_versionColumnName);

        // set initial version
        table->add_empty_row();
        table->set_int(c_versionColumnIndex, c_zeroRowIndex, ObjectStore::NotVersioned);
        changed = true;
    }

    return changed;
}

uint64_t ObjectStore::get_schema_version(Group *group) {
    TableRef table = group->get_table(c_metadataTableName);
    if (!table || table->get_column_count() == 0) {
        return ObjectStore::NotVersioned;
    }
    return table->get_int(c_versionColumnIndex, c_zeroRowIndex);
}

void ObjectStore::set_schema_version(Group *group, uint64_t version) {
    TableRef table = group->get_or_add_table(c_metadataTableName);
    table->set_int(c_versionColumnIndex, c_zeroRowIndex, version);
}

StringData ObjectStore::get_primary_key_for_object(Group *group, StringData object_type) {
    TableRef table = group->get_table(c_primaryKeyTableName);
    if (!table) {
        return "";
    }
    size_t row = table->find_first_string(c_primaryKeyObjectClassColumnIndex, object_type);
    if (row == not_found) {
        return "";
    }
    return table->get_string(c_primaryKeyPropertyNameColumnIndex, row);
}

void ObjectStore::set_primary_key_for_object(Group *group, StringData object_type, StringData primary_key) {
    TableRef table = group->get_table(c_primaryKeyTableName);

    // get row or create if new object and populate
    size_t row = table->find_first_string(c_primaryKeyObjectClassColumnIndex, object_type);
    if (row == not_found && primary_key.size()) {
        row = table->add_empty_row();
        table->set_string(c_primaryKeyObjectClassColumnIndex, row, object_type);
    }

    // set if changing, or remove if setting to nil
    if (primary_key.size() == 0) {
        if (row != not_found) {
            table->remove(row);
        }
    }
    else {
        table->set_string(c_primaryKeyPropertyNameColumnIndex, row, primary_key);
    }
}

string ObjectStore::object_type_for_table_name(const string &table_name) {
    if (table_name.size() >= c_object_table_prefix_length && table_name.compare(0, c_object_table_prefix_length, c_object_table_prefix) == 0) {
        return table_name.substr(c_object_table_prefix_length, table_name.length() - c_object_table_prefix_length);
    }
    return string();
}

string ObjectStore::table_name_for_object_type(const string &object_type) {
    return c_object_table_prefix + object_type;
}

TableRef ObjectStore::table_for_object_type(Group *group, StringData object_type) {
    return group->get_table(table_name_for_object_type(object_type));
}

TableRef ObjectStore::table_for_object_type_create_if_needed(Group *group, const StringData &object_type, bool &created) {
    return group->get_or_add_table(table_name_for_object_type(object_type), &created);
}

std::vector<ObjectStoreException> ObjectStore::validate_schema(Group *group, ObjectSchema &target_schema) {
    vector<ObjectStoreException> exceptions;
    ObjectSchema table_schema(group, target_schema.name);

    // check to see if properties are the same
    for (auto& current_prop : table_schema.properties) {
        auto target_prop = target_schema.property_for_name(current_prop.name);

        if (!target_prop) {
            exceptions.emplace_back(ObjectStoreException(ObjectStoreException::Kind::ObjectSchemaMissingProperty,
                                                         table_schema.name, current_prop));
            continue;
        }

        if (current_prop.type != target_prop->type) {
            exceptions.emplace_back(ObjectStoreException(ObjectStoreException::Kind::ObjectSchemaMismatchedTypes,
                                                         table_schema.name, current_prop, *target_prop));
            continue;
        }
        if (current_prop.type == PropertyTypeObject || target_prop->type == PropertyTypeArray) {
            if (current_prop.object_type != target_prop->object_type) {
                exceptions.emplace_back(ObjectStoreException(ObjectStoreException::Kind::ObjectSchemaMismatchedObjectTypes,
                                                             table_schema.name, current_prop, *target_prop));
            }
        }
        if (current_prop.is_nullable != target_prop->is_nullable) {
            if (current_prop.is_nullable) {
                exceptions.emplace_back(ObjectStoreException::Kind::ObjectSchemaChangedOptionalProperty, table_schema.name, current_prop, *target_prop);
            }
            else {
                exceptions.emplace_back(ObjectStoreException::Kind::ObjectSchemaNewOptionalProperty, table_schema.name, current_prop, *target_prop);
            }
        }

        // create new property with aligned column
        target_prop->table_column = current_prop.table_column;
    }

    // check for change to primary key
    if (table_schema.primary_key != target_schema.primary_key) {
        if (table_schema.primary_key.length()) {
            exceptions.emplace_back(ObjectStoreException(ObjectStoreException::Kind::ObjectSchemaChangedPrimaryKey,
                                                         table_schema.name, table_schema.primary_key));
        }
        else {
            exceptions.emplace_back(ObjectStoreException(ObjectStoreException::Kind::ObjectSchemaNewPrimaryKey,
                                                         target_schema.name, target_schema.primary_key));
        }
    }

    // check for new missing properties
    for (auto& target_prop : target_schema.properties) {
        if (!table_schema.property_for_name(target_prop.name)) {
            exceptions.emplace_back(ObjectStoreException(ObjectStoreException::Kind::ObjectSchemaNewProperty,
                                                         table_schema.name, target_prop));
        }
    }

    return exceptions;
}

void ObjectStore::update_column_mapping(Group *group, ObjectSchema &target_schema) {
    ObjectSchema table_schema(group, target_schema.name);
    for (auto& target_prop : target_schema.properties) {
        auto table_prop = table_schema.property_for_name(target_prop.name);
        if (table_prop) {
            // Update target property column to match what's in the realm if it exists
            target_prop.table_column = table_prop->table_column;
        }
    }
}

static inline bool property_has_changed(Property &p1, Property &p2) {
    return p1.type != p2.type || p1.name != p2.name || p1.object_type != p2.object_type || p1.is_nullable != p2.is_nullable;
}

static bool property_can_be_migrated_to_nullable(Property &old_property, Property &new_property) {
    return old_property.type == new_property.type &&
        !old_property.is_nullable && new_property.is_nullable &&
        new_property.name == old_property.name;
}

template <typename T>
static void copy_property_values(Property const& old_property, Property const& new_property, Table& table,
                                 T (Table::*getter)(std::size_t, std::size_t) const noexcept,
                                 void (Table::*setter)(std::size_t, std::size_t, T)) {
    size_t old_column = old_property.table_column, new_column = new_property.table_column;
    size_t count = table.size();
    for (size_t i = 0; i < count; i++) {
        (table.*setter)(new_column, i, (table.*getter)(old_column, i));
    }
}

// set references to tables on targetSchema and create/update any missing or out-of-date tables
// if update existing is true, updates existing tables, otherwise validates existing tables
// NOTE: must be called from within write transaction
bool ObjectStore::create_tables(Group *group, ObjectStore::Schema &target_schema, bool update_existing) {
    bool changed = false;

    // first pass to create missing tables
    vector<ObjectSchema *> to_update;
    for (auto& object_schema : target_schema) {
        bool created = false;
        ObjectStore::table_for_object_type_create_if_needed(group, object_schema.name, created);

        // we will modify tables for any new objectSchema (table was created) or for all if update_existing is true
        if (update_existing || created) {
            to_update.push_back(&object_schema);
            changed = true;
        }
    }

    // second pass adds/removes columns for out of date tables
    for (auto& target_object_schema : to_update) {
        TableRef table = table_for_object_type(group, target_object_schema->name);
        ObjectSchema current_schema(group, target_object_schema->name);
        vector<Property> &target_props = target_object_schema->properties;

        // add missing columns
        for (auto& target_prop : target_props) {
            auto current_prop = current_schema.property_for_name(target_prop.name);

            // add any new properties (new name or different type)
            if (!current_prop || property_has_changed(*current_prop, target_prop)) {
                switch (target_prop.type) {
                        // for objects and arrays, we have to specify target table
                    case PropertyTypeObject:
                    case PropertyTypeArray: {
                        TableRef link_table = ObjectStore::table_for_object_type(group, target_prop.object_type);
                        target_prop.table_column = table->add_column_link(DataType(target_prop.type), target_prop.name, *link_table);
                        break;
                    }
                    default:
                        target_prop.table_column = table->add_column(DataType(target_prop.type), target_prop.name, target_prop.is_nullable);
                        break;
                }

                if (current_prop && property_can_be_migrated_to_nullable(*current_prop, target_prop)) {
                    switch (target_prop.type) {
                        case PropertyTypeString:
                            copy_property_values(*current_prop, target_prop, *table, &Table::get_string, &Table::set_string);
                            break;
                        case PropertyTypeData:
                            copy_property_values(*current_prop, target_prop, *table, &Table::get_binary, &Table::set_binary);
                            break;
                        case PropertyTypeBool:
                            copy_property_values(*current_prop, target_prop, *table, &Table::get_bool, &Table::set_bool);
                            break;
                        case PropertyTypeInt:
                            copy_property_values(*current_prop, target_prop, *table, &Table::get_int, &Table::set_int);
                            break;
                        case PropertyTypeFloat:
                            copy_property_values(*current_prop, target_prop, *table, &Table::get_float, &Table::set_float);
                            break;
                        case PropertyTypeDouble:
                            copy_property_values(*current_prop, target_prop, *table, &Table::get_double, &Table::set_double);
                            break;
                        case PropertyTypeDate:
                            copy_property_values(*current_prop, target_prop, *table, &Table::get_datetime, &Table::set_datetime);
                            break;
                        default:
                            break;
                    }
                }

                changed = true;
            }
        }

        // remove extra columns
        sort(begin(current_schema.properties), end(current_schema.properties), [](Property &i, Property &j) {
            return j.table_column < i.table_column;
        });
        for (auto& current_prop : current_schema.properties) {
            auto target_prop = target_object_schema->property_for_name(current_prop.name);
            if (!target_prop || property_has_changed(current_prop, *target_prop)) {
                table->remove_column(current_prop.table_column);
                changed = true;
            }
        }

        // update table metadata
        if (target_object_schema->primary_key.length()) {
            // if there is a primary key set, check if it is the same as the old key
            if (current_schema.primary_key != target_object_schema->primary_key) {
                set_primary_key_for_object(group, target_object_schema->name, target_object_schema->primary_key);
                changed = true;
            }
        }
        else if (current_schema.primary_key.length()) {
            // there is no primary key, so if there was one nil out
            set_primary_key_for_object(group, target_object_schema->name, "");
            changed = true;
        }
    }
    return changed;
}

bool ObjectStore::is_schema_at_version(Group *group, uint64_t version) {
    uint64_t old_version = get_schema_version(group);
    if (old_version > version && old_version != NotVersioned) {
        throw ObjectStoreException(old_version, version);
    }
    return old_version != version;
}


bool ObjectStore::update_realm_with_schema(Group *group,
                                           uint64_t version,
                                           Schema &schema,
                                           MigrationFunction migration) {
    // Recheck the schema version after beginning the write transaction as
    // another process may have done the migration after we opened the read
    // transaction
    bool migrating = is_schema_at_version(group, version);

    // create tables
    bool changed = create_metadata_tables(group);
    changed = create_tables(group, schema, migrating) || changed;

    for (auto& target_schema : schema) {
        // read-only realms may be missing tables entirely
        TableRef table = table_for_object_type(group, target_schema.name);
        if (table) {
            auto errors = validate_schema(group, target_schema);
            if (errors.size()) {
                throw ObjectStoreException(errors, target_schema.name);
            }
        }
    }

    changed = update_indexes(group, schema) || changed;

    if (!migrating) {
        return changed;
    }

    // apply the migration block if provided and there's any old data
    if (get_schema_version(group) != ObjectStore::NotVersioned) {
        migration(group, schema);
    }

    validate_primary_column_uniqueness(group, schema);

    set_schema_version(group, version);
    return true;
}

ObjectStore::Schema ObjectStore::schema_from_group(Group *group) {
    ObjectStore::Schema schema;
    for (size_t i = 0; i < group->size(); i++) {
        string object_type = object_type_for_table_name(group->get_table_name(i));
        if (object_type.length()) {
            schema.emplace_back(group, move(object_type));
        }
    }
    return schema;
}

bool ObjectStore::indexes_are_up_to_date(Group *group, Schema &schema) {
    for (auto &object_schema : schema) {
        TableRef table = table_for_object_type(group, object_schema.name);
        if (!table) {
            continue;
        }

        update_column_mapping(group, object_schema);
        for (auto& property : object_schema.properties) {
            if (property.requires_index() != table->has_search_index(property.table_column)) {
                return false;
            }
        }
    }
    return true;
}

bool ObjectStore::update_indexes(Group *group, Schema &schema) {
    bool changed = false;
    for (auto& object_schema : schema) {
        TableRef table = table_for_object_type(group, object_schema.name);
        if (!table) {
            continue;
        }

        for (auto& property : object_schema.properties) {
            if (property.requires_index() == table->has_search_index(property.table_column)) {
                continue;
            }

            changed = true;
            if (property.requires_index()) {
                try {
                    table->add_search_index(property.table_column);
                }
                catch (LogicError const&) {
                    throw ObjectStoreException(ObjectStoreException::Kind::RealmPropertyTypeNotIndexable, object_schema.name, property);
                }
            }
            else {
                table->remove_search_index(property.table_column);
            }
        }
    }
    return changed;
}

void ObjectStore::validate_primary_column_uniqueness(Group *group, Schema &schema) {
    for (auto& object_schema : schema) {
        auto primary_prop = object_schema.primary_key_property();
        if (!primary_prop) {
            continue;
        }

        TableRef table = table_for_object_type(group, object_schema.name);
        if (table->get_distinct_view(primary_prop->table_column).size() != table->size()) {
            throw ObjectStoreException(ObjectStoreException::Kind::RealmDuplicatePrimaryKeyValue, object_schema.name, *primary_prop);
        }
    }
}

void ObjectStore::delete_data_for_object(Group *group, const StringData &object_type) {
    TableRef table = table_for_object_type(group, object_type);
    if (table) {
        group->remove_table(table->get_index_in_group());
        set_primary_key_for_object(group, object_type, "");
    }
}

bool ObjectStore::is_empty(const Group *group) {
    for (size_t i = 0; i < group->size(); i++) {
        ConstTableRef table = group->get_table(i);
        string object_type = object_type_for_table_name(table->get_name());
        if (!object_type.length()) {
            continue;
        }
        if (!table->is_empty()) {
            return false;
        }
    }
    return true;
}
