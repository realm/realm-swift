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
using namespace std;

const char * const c_metadataTableName = "metadata";
const char * const c_versionColumnName = "version";
const size_t c_versionColumnIndex = 0;

const char * const c_primaryKeyTableName = "pk";
const char * const c_primaryKeyObjectClassColumnName = "pk_table";
const size_t c_primaryKeyObjectClassColumnIndex =  0;
const char * const c_primaryKeyPropertyNameColumnName = "pk_property";
const size_t c_primaryKeyPropertyNameColumnIndex =  1;

const string c_object_table_name_prefix = "class_";

const uint64_t ObjectStore::NotVersioned = numeric_limits<uint64_t>::max();

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

StringData ObjectStore::get_primary_key_for_object(realm::Group *group, StringData object_type) {
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

void ObjectStore::set_primary_key_for_object(realm::Group *group, StringData object_type, StringData primary_key) {
    realm::TableRef table = group->get_table(c_primaryKeyTableName);

    // get row or create if new object and populate
    size_t row = table->find_first_string(c_primaryKeyObjectClassColumnIndex, object_type);
    if (row == realm::not_found && primary_key.size()) {
        row = table->add_empty_row();
        table->set_string(c_primaryKeyObjectClassColumnIndex, row, object_type);
    }

    // set if changing, or remove if setting to nil
    if (primary_key.size() == 0 && row != realm::not_found) {
        table->remove(row);
    }
    else {
        table->set_string(c_primaryKeyPropertyNameColumnIndex, row, primary_key);
    }
}

string ObjectStore::object_type_for_table_name(string table_name) {
    if (table_name.compare(0, 6, c_object_table_name_prefix) == 0) {
        return table_name.substr(6, table_name.length()-6);
    }
    return string();
}

string ObjectStore::table_name_for_object_type(string object_type) {
    return c_object_table_name_prefix + object_type;
}

realm::TableRef ObjectStore::table_for_object_type(realm::Group *group, StringData object_type) {
    return group->get_table(table_name_for_object_type(object_type));
}

realm::TableRef ObjectStore::table_for_object_type_create_if_needed(realm::Group *group, StringData object_type, bool &created) {
    return group->get_or_add_table(table_name_for_object_type(object_type), &created);
}

std::vector<std::string> ObjectStore::validate_schema_and_update_column_mapping(realm::Group *group, ObjectSchema &target_schema) {
    vector<string> validation_errors;
    ObjectSchema table_schema(group, target_schema.name);

    // check to see if properties are the same
    for (auto current_prop = table_schema.properties.begin(); current_prop != table_schema.properties.end(); current_prop++) {
        auto target_prop = target_schema.property_for_name(current_prop->name);

        if (target_prop == target_schema.properties.end()) {
            validation_errors.push_back("Property '" + current_prop->name + "' is missing from latest object model.");
            continue;
        }

        if (current_prop->type != target_prop->type) {
            validation_errors.push_back("Property types for '" + target_prop->name + "' property do not match. " +
                                        "Old type '" + string_for_property_type(current_prop->type) +
                                        "', new type '" + string_for_property_type(target_prop->type) + "'");
            continue;
        }
        if (current_prop->type == PropertyTypeObject || target_prop->type == PropertyTypeArray) {
            if (current_prop->object_type != target_prop->object_type) {
                validation_errors.push_back("Target object type for property '" + current_prop->name + "' does not match. " +
                                            "Old type '" + current_prop->object_type +
                                            "', new type '" + target_prop->object_type + "'.");
            }
        }
        if (current_prop->is_primary != target_prop->is_primary) {
            if (current_prop->is_primary) {
                validation_errors.push_back("Property '" + current_prop->name + "' is no longer a primary key.");
            }
            else {
                validation_errors.push_back("Property '" + current_prop->name + "' has been made a primary key.");
            }
        }

        // create new property with aligned column
        target_prop->table_column = current_prop->table_column;
    }

    // check for new missing properties
    for (auto target_iter = target_schema.properties.begin(); target_iter != target_schema.properties.end(); target_iter++) {
        if (table_schema.property_for_name(target_iter->name) == table_schema.properties.end()) {
            validation_errors.push_back("Property '" + target_iter->name + "' has been added to latest object model.");
        }
    }

    return validation_errors;
}

static inline bool property_has_changed(Property &p1, Property &p2) {
    return p1.type != p2.type || p1.name != p2.name || p1.object_type != p2.object_type;
}

// set references to tables on targetSchema and create/update any missing or out-of-date tables
// if update existing is true, updates existing tables, otherwise validates existing tables
// NOTE: must be called from within write transaction
bool ObjectStore::create_tables(realm::Group *group, ObjectStore::Schema target_schema, bool update_existing) {
    bool changed = false;

    // first pass to create missing tables
    vector<ObjectSchema *> to_update;
    for (size_t i = 0; i < target_schema.size(); i++) {
        ObjectSchema *object_schema = target_schema[i].get();
        bool created = false;
        ObjectStore::table_for_object_type_create_if_needed(group, object_schema->name, created);

        // we will modify tables for any new objectSchema (table was created) or for all if update_existing is true
        if (update_existing || created) {
            to_update.push_back(object_schema);
            changed = true;
        }
    }

    // second pass adds/removes columns for out of date tables
    for (size_t i = 0; i < to_update.size(); i++) {
        ObjectSchema *target_schema = to_update[i];
        TableRef table = ObjectStore::table_for_object_type(group, target_schema->name);

        ObjectSchema current_schema(group, target_schema->name);
        vector<Property> &target_props = target_schema->properties;

        // add missing columns
        for (auto target_prop = target_props.begin(); target_prop < target_props.end(); target_prop++) {
            auto current_prop = current_schema.property_for_name(target_prop->name);

            // add any new properties (new name or different type)
            if (current_prop == current_schema.properties.end() || property_has_changed(*current_prop, *target_prop)) {
                switch (target_prop->type) {
                        // for objects and arrays, we have to specify target table
                    case PropertyTypeObject:
                    case PropertyTypeArray: {
                        realm::TableRef link_table = ObjectStore::table_for_object_type(group, target_prop->object_type);
                        target_prop->table_column = table->add_column_link(realm::DataType(target_prop->type), target_prop->name, *link_table);
                        break;
                    }
                    default:
                        target_prop->table_column = table->add_column(realm::DataType(target_prop->type), target_prop->name);
                        break;
                }
                changed = true;
            }
        }

        // remove extra columns
        vector<Property> reverse_props = current_schema.properties;
        std::sort(reverse_props.begin(), reverse_props.end(), [](Property &i, Property &j){ return (j.table_column < i.table_column); });
        for (auto iter = reverse_props.begin(); iter != reverse_props.end(); iter++) {
            auto target_prop_iter = target_schema->property_for_name(iter->name);
            if (target_prop_iter == target_props.end() || property_has_changed(*iter, *target_prop_iter)) {
                table->remove_column(iter->table_column);
                changed = true;
            }
        }

        // update table metadata
        if (target_schema->primary_key.length()) {
            // if there is a primary key set, check if it is the same as the old key
            if (!current_schema.primary_key.length() || current_schema.primary_key != target_schema->primary_key) {
                realm::ObjectStore::set_primary_key_for_object(group, target_schema->name, target_schema->primary_key);
                changed = true;
            }
        }
        else if (current_schema.primary_key.length()) {
            // there is no primary key, so if there was one nil out
            realm::ObjectStore::set_primary_key_for_object(group, target_schema->name, "");
            changed = true;
        }
    }

    return changed;
}

bool ObjectStore::is_migration_required(realm::Group *group, uint64_t new_version) {
    uint64_t old_version = get_schema_version(group);
    if (old_version > new_version && old_version != realm::ObjectStore::NotVersioned) {
        throw ObjectStoreException(ObjectStoreException::RealmVersionGreaterThanSchemaVersion);
    }
    return old_version != new_version;
}


bool ObjectStore::update_realm_with_schema(realm::Group *group,
                                           uint64_t version,
                                           Schema schema,
                                           MigrationFunction migration) {
    // Recheck the schema version after beginning the write transaction as
    // another process may have done the migration after we opened the read
    // transaction
    bool migrating = is_migration_required(group, version);

    // create tables
    bool changed = create_metadata_tables(group) | create_tables(group, schema, migrating);
    for (size_t i = 0; i < schema.size(); i++) {
        ObjectSchema *target_schema = schema[i].get();
        TableRef table = table_for_object_type(group, target_schema->name);

        // read-only realms may be missing tables entirely
        if (table) {
            auto errors = validate_schema_and_update_column_mapping(group, *target_schema);
            if (errors.size()) {
                throw ObjectStoreValidationException(errors, target_schema->name);
            }
        }
    }

    if (!migrating) {
        return changed;
    }

    // apply the migration block if provided and there's any old data
    // to be migrated
    if (get_schema_version(group) != realm::ObjectStore::NotVersioned) {
        migration();
    }

    set_schema_version(group, version);
    return true;
}

ObjectStore::Schema ObjectStore::schema_from_group(Group *group) {
    ObjectStore::Schema schema;
    for (unsigned long i = 0; i < group->size(); i++) {
        string object_type = object_type_for_table_name(group->get_table_name(i));
        if (object_type.length()) {
            schema.push_back(ObjectSchemaRef(new ObjectSchema(group, object_type)));
        }
    }
    return schema;
}
