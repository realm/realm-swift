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

const char * const c_metadataTableName = "metadata";
const char * const c_versionColumnName = "version";
const size_t c_versionColumnIndex = 0;

const char * const c_primaryKeyTableName = "pk";
const char * const c_primaryKeyObjectClassColumnName = "pk_table";
const size_t c_primaryKeyObjectClassColumnIndex =  0;
const char * const c_primaryKeyPropertyNameColumnName = "pk_property";
const size_t c_primaryKeyPropertyNameColumnIndex =  1;

const size_t c_zeroRowIndex = 0;

const std::string c_object_table_prefix = "class_";
const size_t c_object_table_prefix_length = c_object_table_prefix.length();

const uint64_t ObjectStore::NotVersioned = std::numeric_limits<uint64_t>::max();

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

std::string ObjectStore::object_type_for_table_name(const std::string &table_name) {
    if (table_name.size() >= c_object_table_prefix_length && table_name.compare(0, c_object_table_prefix_length, c_object_table_prefix) == 0) {
        return table_name.substr(c_object_table_prefix_length, table_name.length() - c_object_table_prefix_length);
    }
    return std::string();
}

std::string ObjectStore::table_name_for_object_type(const std::string &object_type) {
    return c_object_table_prefix + object_type;
}

TableRef ObjectStore::table_for_object_type(Group *group, StringData object_type) {
    return group->get_table(table_name_for_object_type(object_type));
}

TableRef ObjectStore::table_for_object_type_create_if_needed(Group *group, const StringData &object_type, bool &created) {
    return group->get_or_add_table(table_name_for_object_type(object_type), &created);
}

static inline bool property_has_changed(Property &p1, Property &p2) {
    return p1.type != p2.type || p1.name != p2.name || p1.object_type != p2.object_type || p1.is_nullable != p2.is_nullable;
}

static bool compare_by_name(ObjectSchema const& lft, ObjectSchema const& rgt) {
    return lft.name < rgt.name;
}

void ObjectStore::verify_schema(Group *group, Schema &target_schema, bool allow_missing_tables) {
    std::sort(begin(target_schema), end(target_schema), compare_by_name);

    std::vector<ObjectSchemaValidationException> errors;
    for (auto &object_schema : target_schema) {
        if (!table_for_object_type(group, object_schema.name)) {
            if (!allow_missing_tables) {
                errors.emplace_back(ObjectSchemaValidationException(object_schema.name,
                                    "Missing table for object type '" + object_schema.name + "'."));
            }
            continue;
        }

        auto more_errors = verify_object_schema(group, object_schema, target_schema);
        errors.insert(errors.end(), more_errors.begin(), more_errors.end());
    }
    if (errors.size()) {
        throw SchemaValidationException(errors);
    }
}

std::vector<ObjectSchemaValidationException> ObjectStore::verify_object_schema(Group *group, ObjectSchema &target_schema, Schema &schema) {
    std::vector<ObjectSchemaValidationException> exceptions;
    ObjectSchema table_schema(group, target_schema.name);

    ObjectSchema cmp;
    auto schema_contains_table = [&](std::string const& name) {
        cmp.name = name;
        return std::binary_search(begin(schema), end(schema), cmp, compare_by_name);
    };

    // check to see if properties are the same
    Property *primary = nullptr;
    for (auto& current_prop : table_schema.properties) {
        auto target_prop = target_schema.property_for_name(current_prop.name);

        if (!target_prop) {
            exceptions.emplace_back(MissingPropertyException(table_schema.name, current_prop));
            continue;
        }
        if (property_has_changed(current_prop, *target_prop)) {
            exceptions.emplace_back(MismatchedPropertiesException(table_schema.name, current_prop, *target_prop));
            continue;
        }

        // check object_type existence
        if (current_prop.object_type.length() && !schema_contains_table(current_prop.object_type)) {
            exceptions.emplace_back(MissingObjectTypeException(table_schema.name, current_prop));
        }

        // check nullablity
        if (current_prop.type == PropertyTypeObject) {
            if (!current_prop.is_nullable) {
                exceptions.emplace_back(InvalidNullabilityException(table_schema.name, current_prop));
            }
        }
        else {
            if (current_prop.is_nullable) {
                exceptions.emplace_back(InvalidNullabilityException(table_schema.name, current_prop));
            }
        }

        // check primary keys
        if (current_prop.is_primary) {
            if (primary) {
                exceptions.emplace_back(DuplicatePrimaryKeysException(table_schema.name));
            }
            primary = &current_prop;
        }

        // check indexable
        if (current_prop.is_indexed) {
            if (current_prop.type != PropertyTypeString && current_prop.type != PropertyTypeInt) {
                exceptions.emplace_back(PropertyTypeNotIndexableException(table_schema.name, current_prop));
            }
        }

        // create new property with aligned column
        target_prop->table_column = current_prop.table_column;
    }

    // check for change to primary key
    if (table_schema.primary_key != target_schema.primary_key) {
        exceptions.emplace_back(ChangedPrimaryKeyException(table_schema.name, table_schema.primary_key, target_schema.primary_key));
    }

    // check for new missing properties
    for (auto& target_prop : target_schema.properties) {
        if (!table_schema.property_for_name(target_prop.name)) {
            exceptions.emplace_back(ExtraPropertyException(table_schema.name, target_prop));
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

// set references to tables on targetSchema and create/update any missing or out-of-date tables
// if update existing is true, updates existing tables, otherwise validates existing tables
// NOTE: must be called from within write transaction
bool ObjectStore::create_tables(Group *group, Schema &target_schema, bool update_existing) {
    bool changed = false;

    // first pass to create missing tables
    std::vector<ObjectSchema *> to_update;
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
        std::vector<Property> &target_props = target_object_schema->properties;

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
        throw InvalidSchemaVersionException(old_version, version);
    }
    return old_version == version;
}

bool ObjectStore::realm_requires_update(Group *group, uint64_t version, Schema &schema) {
    if (!is_schema_at_version(group, version)) {
        return true;
    }
    for (auto& target_schema : schema) {
        TableRef table = table_for_object_type(group, target_schema.name);
        if (!table) {
            return true;
        }
    }
    if (!indexes_are_up_to_date(group, schema)) {
        return true;
    }
    return false;
}

bool ObjectStore::update_realm_with_schema(Group *group,
                                           uint64_t version,
                                           Schema &schema,
                                           MigrationFunction migration) {
    // Recheck the schema version after beginning the write transaction as
    // another process may have done the migration after we opened the read
    // transaction
    bool migrating = !is_schema_at_version(group, version);

    // create tables
    bool changed = create_metadata_tables(group);
    changed = create_tables(group, schema, migrating) || changed;

    verify_schema(group, schema);

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

Schema ObjectStore::schema_from_group(Group *group) {
    Schema schema;
    for (size_t i = 0; i < group->size(); i++) {
        std::string object_type = object_type_for_table_name(group->get_table_name(i));
        if (object_type.length()) {
            schema.emplace_back(group, object_type);
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
                    throw PropertyTypeNotIndexableException(object_schema.name, property);
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
            throw DuplicatePrimaryKeyValueException(object_schema.name, *primary_prop);
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
        std::string object_type = object_type_for_table_name(table->get_name());
        if (!object_type.length()) {
            continue;
        }
        if (!table->is_empty()) {
            return false;
        }
    }
    return true;
}

InvalidSchemaVersionException::InvalidSchemaVersionException(uint64_t old_version, uint64_t new_version) :
    m_old_version(old_version), m_new_version(new_version)
{
    m_what = "Provided schema version " + std::to_string(old_version) + " is less than last set version " + std::to_string(new_version) + ".";
}

DuplicatePrimaryKeyValueException::DuplicatePrimaryKeyValueException(std::string object_type, Property &property) :
    m_object_type(object_type), m_property(property)
{
    m_what = "Primary key property '" + property.name + "' has duplicate values after migration.";
};


SchemaValidationException::SchemaValidationException(std::vector<ObjectSchemaValidationException> errors) :
    m_validation_errors(errors)
{
    m_what ="Migration is required due to the following errors: ";
    for (auto error : errors) {
        m_what += std::string("\n- ") + error.what();
    }
}

PropertyTypeNotIndexableException::PropertyTypeNotIndexableException(std::string object_type, Property &property) :
    ObjectSchemaPropertyException(object_type, property)
{
    m_what = "Can't index property " + object_type + "." + property.name + ": indexing a property of type '" + string_for_property_type(property.type) + "' is currently not supported";
}

ExtraPropertyException::ExtraPropertyException(std::string object_type, Property &property) :
    ObjectSchemaPropertyException(object_type, property)
{
    m_what = "Property '" + property.name + "' has been added to latest object model.";
}

MissingPropertyException::MissingPropertyException(std::string object_type, Property &property) :
    ObjectSchemaPropertyException(object_type, property)
{
    m_what = "Property '" + property.name + "' is missing from latest object model.";
}

InvalidNullabilityException::InvalidNullabilityException(std::string object_type, Property &property) :
    ObjectSchemaPropertyException(object_type, property)
{
    if (property.type == PropertyTypeObject) {
        if (!property.is_nullable) {
            m_what = "'Object' property '" + property.name + "' must be nullable.";
        }
    }
    else {
        if (property.is_nullable) {
            m_what = "Only 'Object' property types are nullable";
        }
    }
}

MissingObjectTypeException::MissingObjectTypeException(std::string object_type, Property &property) :
    ObjectSchemaPropertyException(object_type, property)
{
    m_what = "Target type '" + property.object_type + "' doesn't exist for property '" + property.name + "'.";
}

MismatchedPropertiesException::MismatchedPropertiesException(std::string object_type, Property &old_property, Property &new_property) :
    ObjectSchemaValidationException(object_type), m_old_property(old_property), m_new_property(new_property)
{
    if (new_property.type != old_property.type) {
        m_what = "Property types for '" + old_property.name + "' property do not match. Old type '" + string_for_property_type(old_property.type) +
        "', new type '" + string_for_property_type(new_property.type) + "'";
    }
    else if (new_property.object_type != old_property.object_type) {
        m_what = "Target object type for property '" + old_property.name + "' do not match. Old type '" + old_property.object_type + "', new type '" + new_property.object_type + "'";
    }
    else if (new_property.is_nullable != old_property.is_nullable) {
        m_what = "Nullability for property '" + old_property.name + "' has changed from '" + std::to_string(old_property.is_nullable) + "' to  '" + std::to_string(new_property.is_nullable) + "'.";
    }
}

ChangedPrimaryKeyException::ChangedPrimaryKeyException(std::string object_type, std::string old_primary, std::string new_primary) : ObjectSchemaValidationException(object_type), m_old_primary(old_primary), m_new_primary(new_primary)
{
    if (old_primary.size()) {
        m_what = "Property '" + old_primary + "' is no longer a primary key.";
    }
    else {
        m_what = "Property '" + new_primary + "' has been made a primary key.";
    }
}

InvalidPrimaryKeyException::InvalidPrimaryKeyException(std::string object_type, std::string primary) :
    ObjectSchemaValidationException(object_type), m_primary_key(primary)
{
    m_what = "Specified primary key property '" + primary + "' does not exist.";
}

DuplicatePrimaryKeysException::DuplicatePrimaryKeysException(std::string object_type) : ObjectSchemaValidationException(object_type)
{
    m_what = "Duplicate primary keys for object '" + object_type + "'.";
}

