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

#include "object_schema.hpp"
#include "schema.hpp"
#include "util/format.hpp"

#include <realm/group.hpp>
#include <realm/table.hpp>
#include <realm/table_view.hpp>
#include <realm/util/assert.hpp>

#include <string.h>

using namespace realm;

namespace {
const char * const c_metadataTableName = "metadata";
const char * const c_versionColumnName = "version";
const size_t c_versionColumnIndex = 0;

const char * const c_primaryKeyTableName = "pk";
const char * const c_primaryKeyObjectClassColumnName = "pk_table";
const size_t c_primaryKeyObjectClassColumnIndex =  0;
const char * const c_primaryKeyPropertyNameColumnName = "pk_property";
const size_t c_primaryKeyPropertyNameColumnIndex =  1;

const size_t c_zeroRowIndex = 0;

const char c_object_table_prefix[] = "class_";
}

const uint64_t ObjectStore::NotVersioned = std::numeric_limits<uint64_t>::max();

bool ObjectStore::has_metadata_tables(const Group *group) {
    return group->get_table(c_primaryKeyTableName) && group->get_table(c_metadataTableName);
}

void ObjectStore::create_metadata_tables(Group *group) {
    TableRef table = group->get_or_add_table(c_primaryKeyTableName);
    if (table->get_column_count() == 0) {
        table->add_column(type_String, c_primaryKeyObjectClassColumnName);
        table->add_column(type_String, c_primaryKeyPropertyNameColumnName);
    }

    table = group->get_or_add_table(c_metadataTableName);
    if (table->get_column_count() == 0) {
        table->add_column(type_Int, c_versionColumnName);

        // set initial version
        table->add_empty_row();
        table->set_int(c_versionColumnIndex, c_zeroRowIndex, ObjectStore::NotVersioned);
    }
}

uint64_t ObjectStore::get_schema_version(const Group *group) {
    ConstTableRef table = group->get_table(c_metadataTableName);
    if (!table || table->get_column_count() == 0) {
        return ObjectStore::NotVersioned;
    }
    return table->get_int(c_versionColumnIndex, c_zeroRowIndex);
}

void ObjectStore::set_schema_version(Group *group, uint64_t version) {
    TableRef table = group->get_or_add_table(c_metadataTableName);
    table->set_int(c_versionColumnIndex, c_zeroRowIndex, version);
}

StringData ObjectStore::get_primary_key_for_object(const Group *group, StringData object_type) {
    ConstTableRef table = group->get_table(c_primaryKeyTableName);
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

StringData ObjectStore::object_type_for_table_name(StringData table_name) {
    if (table_name.begins_with(c_object_table_prefix)) {
        return table_name.substr(sizeof(c_object_table_prefix) - 1);
    }
    return StringData();
}

std::string ObjectStore::table_name_for_object_type(StringData object_type) {
    return std::string(c_object_table_prefix) + object_type.data();
}

TableRef ObjectStore::table_for_object_type(Group *group, StringData object_type) {
    auto name = table_name_for_object_type(object_type);
    return group->get_table(name);
}

ConstTableRef ObjectStore::table_for_object_type(const Group *group, StringData object_type) {
    auto name = table_name_for_object_type(object_type);
    return group->get_table(name);
}

TableRef ObjectStore::table_for_object_type_create_if_needed(Group *group, StringData object_type, bool &created) {
    auto name = table_name_for_object_type(object_type);
    return group->get_or_add_table(name, &created);
}

static inline bool property_has_changed(Property const& p1, Property const& p2) {
    return p1.type != p2.type
        || p1.name != p2.name
        || p1.object_type != p2.object_type
        || p1.is_nullable != p2.is_nullable;
}

static inline bool property_can_be_migrated_to_nullable(const Property& old_property, const Property& new_property) {
    return old_property.type == new_property.type
        && !old_property.is_nullable
        && new_property.is_nullable
        && new_property.name == old_property.name;
}

void ObjectStore::verify_missing_renamed_properties(Schema const& actual_schema, Schema& target_schema) {
    for (auto &object_schema : target_schema) {
        auto matching_schema = actual_schema.find(object_schema);
        for (auto& target_prop : matching_schema->persisted_properties) {
            if (!object_schema.property_for_name(target_prop.name)) {
                throw PropertyRenameMissingNewPropertyException(target_prop.name);
            }
        }
    }
}

void ObjectStore::verify_schema(Schema const& actual_schema, Schema& target_schema, bool allow_missing_tables) {
    std::vector<ObjectSchemaValidationException> errors;
    for (auto &object_schema : target_schema) {
        auto matching_schema = actual_schema.find(object_schema);
        if (matching_schema == actual_schema.end()) {
            if (!allow_missing_tables) {
                errors.emplace_back(object_schema.name,
                                    util::format("Missing table for object type '%1'.", object_schema.name));
            }
            continue;
        }

        auto more_errors = verify_object_schema(*matching_schema, object_schema);
        errors.insert(errors.end(), more_errors.begin(), more_errors.end());
    }
    if (errors.size()) {
        throw SchemaMismatchException(errors);
    }
}

std::vector<ObjectSchemaValidationException> ObjectStore::verify_object_schema(ObjectSchema const& table_schema,
                                                                               ObjectSchema& target_schema) {
    std::vector<ObjectSchemaValidationException> exceptions;

    // check to see if properties are the same
    for (auto& current_prop : table_schema.persisted_properties) {
        auto target_prop = target_schema.property_for_name(current_prop.name);

        if (!target_prop) {
            exceptions.emplace_back(MissingPropertyException(table_schema.name, current_prop));
            continue;
        }
        if (property_has_changed(current_prop, *target_prop)) {
            exceptions.emplace_back(MismatchedPropertiesException(table_schema.name, current_prop, *target_prop));
            continue;
        }

        // create new property with aligned column
        target_prop->table_column = current_prop.table_column;
    }

    // check for change to primary key
    if (table_schema.primary_key != target_schema.primary_key) {
        exceptions.emplace_back(ChangedPrimaryKeyException(table_schema.name, table_schema.primary_key, target_schema.primary_key));
    }

    // check for new missing properties
    for (auto& target_prop : target_schema.persisted_properties) {
        if (!table_schema.property_for_name(target_prop.name)) {
            exceptions.emplace_back(ExtraPropertyException(table_schema.name, target_prop));
        }
    }

    return exceptions;
}

template <typename T>
static void copy_property_values(const Property& old_property, const Property& new_property, Table& table,
                                 T (Table::*getter)(std::size_t, std::size_t) const noexcept,
                                 void (Table::*setter)(std::size_t, std::size_t, T)) {
    size_t old_column = old_property.table_column, new_column = new_property.table_column;
    size_t count = table.size();
    for (size_t i = 0; i < count; i++) {
        (table.*setter)(new_column, i, (table.*getter)(old_column, i));
    }
}

static void copy_property_values(const Property& source, const Property& destination, Table& table) {
    switch (destination.type) {
        case PropertyType::Int:
            copy_property_values(source, destination, table, &Table::get_int, &Table::set_int);
            break;
        case PropertyType::Bool:
            copy_property_values(source, destination, table, &Table::get_bool, &Table::set_bool);
            break;
        case PropertyType::Float:
            copy_property_values(source, destination, table, &Table::get_float, &Table::set_float);
            break;
        case PropertyType::Double:
            copy_property_values(source, destination, table, &Table::get_double, &Table::set_double);
            break;
        case PropertyType::String:
            copy_property_values(source, destination, table, &Table::get_string, &Table::set_string);
            break;
        case PropertyType::Data:
            copy_property_values(source, destination, table, &Table::get_binary, &Table::set_binary);
            break;
        case PropertyType::Date:
            copy_property_values(source, destination, table, &Table::get_timestamp, &Table::set_timestamp);
            break;
        default:
            break;
    }
}

// set references to tables on targetSchema and create/update any missing or out-of-date tables
// if update existing is true, updates existing tables, otherwise validates existing tables
// NOTE: must be called from within write transaction
std::vector<std::pair<std::string, Property>> ObjectStore::create_tables(Group *group, Schema &target_schema, bool update_existing) {
    // properties to delete
    std::vector<std::pair<std::string,Property>> to_delete;

    // first pass to create missing tables
    std::vector<ObjectSchema *> to_update;
    for (auto& object_schema : target_schema) {
        bool created = false;
        ObjectStore::table_for_object_type_create_if_needed(group, object_schema.name, created);

        // we will modify tables for any new objectSchema (table was created) or for all if update_existing is true
        if (update_existing || created) {
            to_update.push_back(&object_schema);
        }
    }

    // second pass adds/removes columns for out of date tables
    for (auto& target_object_schema : to_update) {
        TableRef table = table_for_object_type(group, target_object_schema->name);
        ObjectSchema current_schema(group, target_object_schema->name);
        std::vector<Property> &target_props = target_object_schema->persisted_properties;

        // handle columns changing from required to optional
        for (auto& current_prop : current_schema.persisted_properties) {
            auto target_prop = target_object_schema->property_for_name(current_prop.name);
            if (!target_prop || !property_can_be_migrated_to_nullable(current_prop, *target_prop))
                continue;

            target_prop->table_column = current_prop.table_column;
            current_prop.table_column = current_prop.table_column + 1;

            table->insert_column(target_prop->table_column, DataType(target_prop->type), target_prop->name, target_prop->is_nullable);
            copy_property_values(current_prop, *target_prop, *table);
            table->remove_column(current_prop.table_column);

            current_prop.table_column = target_prop->table_column;
        }

        bool inserted_placeholder_column = false;

        // remove extra columns
        size_t deleted = 0;
        for (auto& current_prop : current_schema.persisted_properties) {
            current_prop.table_column -= deleted;

            auto target_prop = target_object_schema->property_for_name(current_prop.name);
            // mark object name & property pairs for deletion
            if (!target_prop) {
                to_delete.push_back(std::make_pair(current_schema.name, current_prop));
            }
            else if ((property_has_changed(current_prop, *target_prop) &&
                      !property_can_be_migrated_to_nullable(current_prop, *target_prop))) {
                if (deleted == current_schema.persisted_properties.size() - 1) {
                    // We're about to remove the last column from the table. Insert a placeholder column to preserve
                    // the number of rows in the table for the addition of new columns below.
                    table->add_column(type_Bool, "placeholder");
                    inserted_placeholder_column = true;
                }

                table->remove_column(current_prop.table_column);
                ++deleted;
                current_prop.table_column = npos;
            }
        }

        // add missing columns
        for (auto& target_prop : target_props) {
            auto current_prop = current_schema.property_for_name(target_prop.name);

            // add any new properties (no old column or old column was removed due to not matching)
            if (!current_prop || current_prop->table_column == npos) {
                switch (target_prop.type) {
                        // for objects and arrays, we have to specify target table
                    case PropertyType::Object:
                    case PropertyType::Array: {
                        TableRef link_table = ObjectStore::table_for_object_type(group, target_prop.object_type);
                        REALM_ASSERT(link_table);
                        target_prop.table_column = table->add_column_link(DataType(target_prop.type), target_prop.name, *link_table);
                        break;
                    }
                    default:
                        target_prop.table_column = table->add_column(DataType(target_prop.type),
                                                                     target_prop.name,
                                                                     target_prop.is_nullable);
                        break;
                }
            }
            else {
                target_prop.table_column = current_prop->table_column;
            }
        }

        if (inserted_placeholder_column) {
            // We inserted a placeholder due to removing all columns from the table. Remove it, and update the indices
            // of any columns that we inserted after it.
            table->remove_column(0);
            for (auto& target_prop : target_props) {
                target_prop.table_column--;
            }
        }

        // update table metadata
        if (target_object_schema->primary_key.length()) {
            // if there is a primary key set, check if it is the same as the old key
            if (current_schema.primary_key != target_object_schema->primary_key) {
                set_primary_key_for_object(group, target_object_schema->name, target_object_schema->primary_key);
            }
        }
        else if (current_schema.primary_key.length()) {
            // there is no primary key, so if there was one nil out
            set_primary_key_for_object(group, target_object_schema->name, "");
        }
    }
    return to_delete;
}

void ObjectStore::remove_properties(Group *group, Schema &target_schema, std::vector<std::pair<std::string, Property>> to_delete) {
    for (auto& target_object_schema : target_schema) {
        TableRef table = table_for_object_type(group, target_object_schema.name);
        ObjectSchema current_schema(group, target_object_schema.name);
        size_t deleted = 0;
        for (auto& current_prop : current_schema.persisted_properties) {
            current_prop.table_column -= deleted;
            for (auto& single_to_delete : to_delete) {
                if (target_object_schema.name == single_to_delete.first &&
                    current_prop.name == single_to_delete.second.name &&
                    current_prop.object_type == single_to_delete.second.object_type) {
                    table->remove_column(current_prop.table_column);
                    ++deleted;
                    current_prop.table_column = npos;
                }
            }
        }
    }
}

bool ObjectStore::is_schema_at_version(const Group *group, uint64_t version) {
    uint64_t old_version = get_schema_version(group);
    if (old_version > version && old_version != NotVersioned) {
        throw InvalidSchemaVersionException(old_version, version);
    }
    return old_version == version;
}

bool ObjectStore::needs_update(Schema const& old_schema, Schema const& schema) {
    for (auto const& target_schema : schema) {
        auto matching_schema = old_schema.find(target_schema);
        if (matching_schema == end(old_schema)) {
            // Table doesn't exist
            return true;
        }

        if (matching_schema->persisted_properties.size() != target_schema.persisted_properties.size()) {
            // If the number of properties don't match then a migration is required
            return false;
        }

        // Check that all of the property indexes are up to date
        for (size_t i = 0, count = target_schema.persisted_properties.size(); i < count; ++i) {
            if (target_schema.persisted_properties[i].is_indexed != matching_schema->persisted_properties[i].is_indexed) {
                return true;
            }
        }
    }

    return false;
}

void ObjectStore::update_realm_with_schema(Group *group, Schema const& old_schema,
                                           uint64_t version, Schema &schema,
                                           MigrationFunction migration) {
    // Recheck the schema version after beginning the write transaction as
    // another process may have done the migration after we opened the read
    // transaction
    bool migrating = !is_schema_at_version(group, version);

    // create tables
    create_metadata_tables(group);
    auto to_delete = create_tables(group, schema, migrating);

    if (!migrating) {
        // If we aren't migrating, then verify that all of the tables which
        // were already present are valid (newly created ones always are)
        verify_schema(old_schema, schema, true);
    }

    update_indexes(group, schema);

    if (!migrating) {
        return;
    }

    // apply the migration block if provided and there's any old data
    if (get_schema_version(group) != ObjectStore::NotVersioned) {
        migration(group, schema);
        remove_properties(group, schema, std::move(to_delete));

        Schema group_schema = schema_from_group(group);
        verify_missing_renamed_properties(group_schema, schema);
        verify_schema(group_schema, schema);
        validate_primary_column_uniqueness(group, schema);
    }

    set_schema_version(group, version);
}

Schema ObjectStore::schema_from_group(const Group *group) {
    std::vector<ObjectSchema> schema;
    for (size_t i = 0; i < group->size(); i++) {
        std::string object_type = object_type_for_table_name(group->get_table_name(i));
        if (object_type.length()) {
            schema.emplace_back(group, object_type);
        }
    }
    return schema;
}

bool ObjectStore::update_indexes(Group *group, Schema &schema) {
    bool changed = false;
    for (auto& object_schema : schema) {
        TableRef table = table_for_object_type(group, object_schema.name);
        if (!table) {
            continue;
        }

        for (auto& property : object_schema.persisted_properties) {
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

void ObjectStore::validate_primary_column_uniqueness(const Group *group, Schema const& schema) {
    for (auto& object_schema : schema) {
        auto primary_prop = object_schema.primary_key_property();
        if (!primary_prop) {
            continue;
        }

        ConstTableRef table = table_for_object_type(group, object_schema.name);
        if (table->get_distinct_view(primary_prop->table_column).size() != table->size()) {
            throw DuplicatePrimaryKeyValueException(object_schema.name, *primary_prop);
        }
    }
}

void ObjectStore::delete_data_for_object(Group *group, StringData object_type) {
    TableRef table = table_for_object_type(group, object_type);
    if (table) {
        group->remove_table(table->get_index_in_group());
        set_primary_key_for_object(group, object_type, "");
    }
}

void ObjectStore::rename_property(Group *group, Schema& passed_schema, StringData object_type, StringData old_name, StringData new_name) {
    TableRef table = table_for_object_type(group, object_type);
    if (!table) {
        throw PropertyRenameMissingNewObjectTypeException(object_type);
    }
    ObjectSchema matching_schema(group, object_type);
    Property *old_property = matching_schema.property_for_name(old_name);
    if (old_property == nullptr) {
        throw PropertyRenameMissingOldPropertyException(old_name, new_name);
    }
    auto passed_object_schema = passed_schema.find(object_type);
    if (passed_object_schema == passed_schema.end()) {
        throw PropertyRenameMissingNewObjectTypeException(object_type);
    }
    Property *new_property = matching_schema.property_for_name(new_name);
    if (new_property == nullptr) {
        // new property not in new schema, which means we're probably renaming
        // to an intermediate property in a multi-version migration.
        // this is safe because the migration will fail schema validation unless
        // this property is renamed again.
        new_property = matching_schema.property_for_name(old_name);
        new_property->name = new_name;
        table->rename_column(old_property->table_column, new_name);
        return;
    }
    if (old_property->type != new_property->type ||
        old_property->object_type != new_property->object_type) {
        throw PropertyRenameTypeMismatchException(*old_property, *new_property);
    }
    if (passed_object_schema->property_for_name(old_name) != nullptr) {
        throw PropertyRenameOldStillExistsException(old_name, new_name);
    }
    size_t column_to_remove = new_property->table_column;
    table->rename_column(old_property->table_column, new_name);
    table->remove_column(column_to_remove);
    // update table_column for each property since it may have shifted
    for (auto& current_prop : passed_object_schema->persisted_properties) {
        auto target_prop = matching_schema.property_for_name(current_prop.name);
        current_prop.table_column = target_prop->table_column;
    }
    // update index for new column
    if (new_property->requires_index() && !old_property->requires_index()) {
        table->add_search_index(old_property->table_column);
    } else if (!new_property->requires_index() && old_property->requires_index()) {
        table->remove_search_index(old_property->table_column);
    }
    old_property->name = new_name;
    // update nullability for column
    if (property_can_be_migrated_to_nullable(*old_property, *new_property)) {
        new_property->table_column = old_property->table_column;
        old_property->table_column = old_property->table_column + 1;

        table->insert_column(new_property->table_column, DataType(new_property->type), new_property->name, new_property->is_nullable);
        copy_property_values(*old_property, *new_property, *table);
        table->remove_column(old_property->table_column);

        old_property->table_column = new_property->table_column;
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

PropertyRenameException::PropertyRenameException(std::string old_property_name, std::string new_property_name) :
    m_old_property_name(old_property_name), m_new_property_name(new_property_name)
{
    m_what = util::format("Old property '%1' cannot be renamed to property '%2'.",
                          old_property_name, new_property_name);
}

PropertyRenameMissingObjectTypeException::PropertyRenameMissingObjectTypeException(std::string object_type) :
    m_object_type(object_type)
{
    m_what = util::format("Cannot rename properties on type '%1'.", object_type);
}

PropertyRenameMissingOldObjectTypeException::PropertyRenameMissingOldObjectTypeException(std::string object_type) :
    PropertyRenameMissingObjectTypeException(object_type)
{
    m_what = util::format("Cannot rename properties on type '%1' because it is missing from the Realm file.",
                          object_type);
}

PropertyRenameMissingNewObjectTypeException::PropertyRenameMissingNewObjectTypeException(std::string object_type) :
    PropertyRenameMissingObjectTypeException(object_type)
{
    m_what = util::format("Cannot rename properties on type '%1' because it is missing from the specified schema.",
                          object_type);
}

PropertyRenameMissingOldPropertyException::PropertyRenameMissingOldPropertyException(std::string old_property_name, std::string new_property_name) :
    PropertyRenameException(old_property_name, new_property_name)
{
    m_what = util::format("Old property '%1' is missing from the Realm file so it cannot be renamed to '%2'.",
                          old_property_name, new_property_name);
}

PropertyRenameMissingNewPropertyException::PropertyRenameMissingNewPropertyException(std::string new_property_name) :
    m_new_property_name(new_property_name)
{
    m_what = util::format("Renamed property '%1' is not in the latest model.", new_property_name);
}

PropertyRenameOldStillExistsException::PropertyRenameOldStillExistsException(std::string old_property_name, std::string new_property_name) :
    PropertyRenameException(old_property_name, new_property_name)
{
    m_what = util::format("Old property '%1' cannot be renamed to '%2' because the old property is still present "
                          "in the specified schema.", old_property_name, new_property_name);
}

PropertyRenameTypeMismatchException::PropertyRenameTypeMismatchException(Property const& old_property, Property const& new_property) :
    m_old_property(old_property), m_new_property(new_property)
{
    m_what = util::format("Old property '%1' of type '%2' cannot be renamed to property '%3' of type '%4'.",
                          old_property.name, old_property.type_string(),
                          new_property.name, new_property.type_string());
}

InvalidSchemaVersionException::InvalidSchemaVersionException(uint64_t old_version, uint64_t new_version) :
    m_old_version(old_version), m_new_version(new_version)
{
    m_what = util::format("Provided schema version %1 is less than last set version %2.", new_version, old_version);
}

DuplicatePrimaryKeyValueException::DuplicatePrimaryKeyValueException(std::string const& object_type, Property const& property) :
    m_object_type(object_type), m_property(property)
{
    m_what = util::format("Primary key property '%1' has duplicate values after migration.", property.name);
}

SchemaValidationException::SchemaValidationException(std::vector<ObjectSchemaValidationException> const& errors)
: m_validation_errors(errors)
{
    m_what = "Schema validation failed due to the following errors:";
    for (auto const& error : errors) {
        m_what += std::string("\n- ") + error.what();
    }
}

SchemaMismatchException::SchemaMismatchException(std::vector<ObjectSchemaValidationException> const& errors) :
    m_validation_errors(errors)
{
    m_what = "Migration is required due to the following errors:";
    for (auto const& error : errors) {
        m_what += std::string("\n- ") + error.what();
    }
}

PropertyTypeNotIndexableException::PropertyTypeNotIndexableException(std::string const& object_type,
                                                                     Property const& property)
: ObjectSchemaPropertyException(object_type, property)
{
    m_what = util::format("Can't index property %1.%2: indexing a property of type '%3' is currently not supported.",
                          object_type, property.name, string_for_property_type(property.type));
}

ExtraPropertyException::ExtraPropertyException(std::string const& object_type, Property const& property) :
    ObjectSchemaPropertyException(object_type, property)
{
    m_what = util::format("Property '%1' has been added to latest object model.", property.name);
}

MissingPropertyException::MissingPropertyException(std::string const& object_type, Property const& property) :
    ObjectSchemaPropertyException(object_type, property)
{
    m_what = util::format("Property '%1' is missing from latest object model.", property.name);
}

InvalidNullabilityException::InvalidNullabilityException(std::string const& object_type, Property const& property) :
    ObjectSchemaPropertyException(object_type, property)
{
    switch (property.type) {
        case PropertyType::Object:
            m_what = util::format("'Object' property '%1' must be nullable.", property.name);
            break;
        case PropertyType::Any:
        case PropertyType::Array:
        case PropertyType::LinkingObjects:
            m_what = util::format("Property '%1' of type '%2' cannot be nullable.",
                                  property.name, string_for_property_type(property.type));
            break;
        case PropertyType::Int:
        case PropertyType::Bool:
        case PropertyType::Data:
        case PropertyType::Date:
        case PropertyType::Float:
        case PropertyType::Double:
        case PropertyType::String:
            REALM_ASSERT(false);
    }
}

MissingObjectTypeException::MissingObjectTypeException(std::string const& object_type, Property const& property)
: ObjectSchemaPropertyException(object_type, property)
{
    m_what = util::format("Target type '%1' doesn't exist for property '%2'.",
                          property.object_type, property.name);
}

MismatchedPropertiesException::MismatchedPropertiesException(std::string const& object_type,
                                                             Property const& old_property,
                                                             Property const& new_property) :
    ObjectSchemaValidationException(object_type), m_old_property(old_property), m_new_property(new_property)
{
    if (new_property.type != old_property.type) {
        m_what = util::format("Property types for '%1' property do not match. Old type '%2', new type '%3'.",
                              old_property.name,
                              string_for_property_type(old_property.type),
                              string_for_property_type(new_property.type));
    }
    else if (new_property.object_type != old_property.object_type) {
        m_what = util::format("Target object type for property '%1' do not match. Old type '%2', new type '%3'.",
                              old_property.name, old_property.object_type, new_property.object_type);
    }
    else if (new_property.is_nullable != old_property.is_nullable) {
        m_what = util::format("Nullability for property '%1' has been changed from %2 to %3.",
                              old_property.name,
                              old_property.is_nullable, new_property.is_nullable);
    }
}

ChangedPrimaryKeyException::ChangedPrimaryKeyException(std::string const& object_type,
                                                       std::string const& old_primary,
                                                       std::string const& new_primary)
: ObjectSchemaValidationException(object_type), m_old_primary(old_primary), m_new_primary(new_primary)
{
    if (old_primary.size()) {
        m_what = util::format("Property '%1' is no longer a primary key.", old_primary);
    }
    else {
        m_what = util::format("Property '%1' has been made a primary key.", new_primary);
    }
}

InvalidPrimaryKeyException::InvalidPrimaryKeyException(std::string const& object_type, std::string const& primary) :
    ObjectSchemaValidationException(object_type), m_primary_key(primary)
{
    m_what = util::format("Specified primary key property '%1' does not exist.", primary);
}

DuplicatePrimaryKeysException::DuplicatePrimaryKeysException(std::string const& object_type)
: ObjectSchemaValidationException(object_type)
{
    m_what = util::format("Duplicate primary keys for object '%1'.", object_type);
}

InvalidLinkingObjectsPropertyException::InvalidLinkingObjectsPropertyException(Type error_type, std::string const& object_type, Property const& property)
: ObjectSchemaPropertyException(object_type, property)
{
    switch (error_type) {
        case Type::OriginPropertyDoesNotExist:
            m_what = util::format("Property '%1.%2' declared as origin of linking objects property '%3.%4' does not exist.",
                                  property.object_type, property.link_origin_property_name,
                                  object_type, property.name);
            break;
        case Type::OriginPropertyIsNotALink:
            m_what = util::format("Property '%1.%2' declared as origin of linking objects property '%3.%4' is not a link.",
                                  property.object_type, property.link_origin_property_name,
                                  object_type, property.name);
            break;
        case Type::OriginPropertyInvalidLinkTarget:
            m_what = util::format("Property '%1.%2' declared as origin of linking objects property '%3.%4' links to a different class.",
                                  property.object_type, property.link_origin_property_name,
                                  object_type, property.name);
            break;
    }
}
