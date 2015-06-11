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

#ifndef REALM_OBJECT_STORE_HPP
#define REALM_OBJECT_STORE_HPP

#include <map>
#include <vector>
#include <functional>

#include "object_schema.hpp"
#include "object_store_exceptions.hpp"

namespace realm {
    class Group;
    class StringData;
    class Table;
    template<typename T> class BasicTableRef;
    typedef BasicTableRef<Table> TableRef;

    class ObjectStore {
    public:
        // Schema version used for uninitialized Realms
        static const uint64_t NotVersioned;

        // get the last set schema version
        static uint64_t get_schema_version(Group *group);

        // checks if the schema in the group is at the given version
        static bool is_schema_at_version(realm::Group *group, uint64_t version);

        // verify a target schema against its table, setting the table_column property on each schema object
        // updates the column mapping on the target_schema
        // if no table is provided it is fetched from the group
        // returns array of validation errors
        static std::vector<std::string> validate_schema(Group *group, ObjectSchema &target_schema);

        // updates the target_column member for all properties based on the column indexes in the passed in group
        static void update_column_mapping(Group *group, ObjectSchema &target_schema);

        // updates a Realm to a given target schema/version creating tables and updating indexes as necessary
        // returns if any changes were made
        // passed in schema ar updated with the correct column mapping
        // optionally runs migration function/lambda if schema is out of date
        // NOTE: must be performed within a write transaction
        typedef std::vector<ObjectSchema> Schema;
        typedef std::function<void(Group *, Schema &)> MigrationFunction;
        static bool update_realm_with_schema(Group *group, uint64_t version, Schema &schema, MigrationFunction migration);

        // get a table for an object type
        static realm::TableRef table_for_object_type(Group *group, StringData object_type);

        // get existing Schema from a group
        static Schema schema_from_group(Group *group);

        // check if indexes are up to date - if false you need to call update_realm_with_schema
        static bool indexes_are_up_to_date(Group *group, Schema &schema);

        // deletes the table for the given type
        static void delete_data_for_object(Group *group, const StringData &object_type);

    private:
        // set a new schema version
        static void set_schema_version(Group *group, uint64_t version);

        // check if the realm already has all metadata tables
        static bool has_metadata_tables(Group *group);

        // create any metadata tables that don't already exist
        // must be in write transaction to set
        // returns true if it actually did anything
        static bool create_metadata_tables(Group *group);

        // set references to tables on targetSchema and create/update any missing or out-of-date tables
        // if update existing is true, updates existing tables, otherwise only adds and initializes new tables
        static bool create_tables(realm::Group *group, ObjectStore::Schema &target_schema, bool update_existing);

        // get primary key property name for object type
        static StringData get_primary_key_for_object(Group *group, StringData object_type);

        // sets primary key property for object type
        // must be in write transaction to set
        static void set_primary_key_for_object(Group *group, StringData object_type, StringData primary_key);

        static TableRef table_for_object_type_create_if_needed(Group *group, const StringData &object_type, bool &created);
        static std::string table_name_for_object_type(const std::string &class_name);
        static std::string object_type_for_table_name(const std::string &table_name);

        // returns if any indexes were changed
        static bool update_indexes(Group *group, Schema &schema);

        // validates that all primary key properties have unique values
        static void validate_primary_column_uniqueness(Group *group, Schema &schema);

        friend ObjectSchema;
    };
}

#endif /* defined(REALM_OBJECT_STORE_HPP) */

