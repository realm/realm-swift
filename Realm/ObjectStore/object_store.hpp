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

#include <vector>
#include <functional>
#include <realm/link_view.hpp>
#include <realm/group.hpp>

#include "object_schema.hpp"
#include "property.hpp"

namespace realm {
    class ObjectSchemaValidationException;
    using Schema = std::vector<ObjectSchema>;

    class ObjectStore {
      public:
        // Schema version used for uninitialized Realms
        static const uint64_t NotVersioned;

        // get the last set schema version
        static uint64_t get_schema_version(Group *group);

        // checks if the schema in the group is at the given version
        static bool is_schema_at_version(realm::Group *group, uint64_t version);

        // verify a target schema against tables in the given group
        // updates the column mapping on all ObjectSchema properties
        // throws if the schema is invalid or does not match tables in the given group
        static void verify_schema(Group *group, Schema &target_schema, bool allow_missing_tables = false);

        // updates the target_column member for all properties based on the column indexes in the passed in group
        static void update_column_mapping(Group *group, ObjectSchema &target_schema);

        // determines if you must call update_realm_with_schema for a given realm.
        // returns true if there is a schema version mismatch, if there tables which still need to be created,
        // or if file format or other changes/updates need to be made
        static bool realm_requires_update(Group *group, uint64_t version, Schema const& schema);
        
        // updates a Realm to a given target schema/version creating tables and updating indexes as necessary
        // returns if any changes were made
        // passed in schema ar updated with the correct column mapping
        // optionally runs migration function/lambda if schema is out of date
        // NOTE: must be performed within a write transaction
        typedef std::function<void(Group *, Schema &)> MigrationFunction;
        static bool update_realm_with_schema(Group *group, uint64_t version, Schema &schema, MigrationFunction migration);

        // get a table for an object type
        static realm::TableRef table_for_object_type(Group *group, StringData object_type);

        // get existing Schema from a group
        static Schema schema_from_group(Group *group);

        // deletes the table for the given type
        static void delete_data_for_object(Group *group, const StringData &object_type);

        // indicates if this group contains any objects
        static bool is_empty(const Group *group);

    private:
        // set a new schema version
        static void set_schema_version(Group *group, uint64_t version);

        // create any metadata tables that don't already exist
        // must be in write transaction to set
        // returns true if it actually did anything
        static bool create_metadata_tables(Group *group);

        // set references to tables on targetSchema and create/update any missing or out-of-date tables
        // if update existing is true, updates existing tables, otherwise only adds and initializes new tables
        static bool create_tables(realm::Group *group, Schema &target_schema, bool update_existing);

        // verify a target schema against its table, setting the table_column property on each schema object
        // updates the column mapping on the target_schema
        // returns array of validation errors
        static std::vector<ObjectSchemaValidationException> verify_object_schema(Group *group, ObjectSchema &target_schema, Schema &schema);

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

    // Base exception
    class ObjectStoreException : public std::exception {
      public:
        ObjectStoreException() = default;
        ObjectStoreException(const std::string &what) : m_what(what) {}
        virtual const char* what() const noexcept { return m_what.c_str(); }
      protected:
        std::string m_what;
    };

    // Migration exceptions
    class MigrationException : public ObjectStoreException {};

    class InvalidSchemaVersionException : public MigrationException {
      public:
        InvalidSchemaVersionException(uint64_t old_version, uint64_t new_version);
        uint64_t old_version() { return m_old_version; }
        uint64_t new_version() { return m_new_version; }
      private:
        uint64_t m_old_version, m_new_version;
    };

    class DuplicatePrimaryKeyValueException : public MigrationException {
      public:
        DuplicatePrimaryKeyValueException(std::string object_type, Property &property);
        std::string object_type() { return m_object_type; }
        Property &property() { return m_property; }
      private:
        std::string m_object_type;
        Property m_property;
    };

    // Schema validation exceptions
    class SchemaValidationException : public ObjectStoreException {
      public:
        SchemaValidationException(std::vector<ObjectSchemaValidationException> errors);
        std::vector<ObjectSchemaValidationException> &validation_errors() { return m_validation_errors; }
      private:
        std::vector<ObjectSchemaValidationException> m_validation_errors;
    };

    class ObjectSchemaValidationException : public ObjectStoreException {
      public:
        ObjectSchemaValidationException(std::string object_type) : m_object_type(object_type) {}
        ObjectSchemaValidationException(std::string object_type, std::string message) :
            m_object_type(object_type) { m_what = message; }
        std::string object_type() { return m_object_type; }
      protected:
        std::string m_object_type;
    };

    class ObjectSchemaPropertyException : public ObjectSchemaValidationException {
      public:
        ObjectSchemaPropertyException(std::string object_type, Property &property) :
            ObjectSchemaValidationException(object_type), m_property(property) {}
        Property &property() { return m_property; }
      private:
        Property m_property;
    };

    class PropertyTypeNotIndexableException : public ObjectSchemaPropertyException {
      public:
        PropertyTypeNotIndexableException(std::string object_type, Property &property);
    };

    class ExtraPropertyException : public ObjectSchemaPropertyException {
      public:
        ExtraPropertyException(std::string object_type, Property &property);
    };

    class MissingPropertyException : public ObjectSchemaPropertyException {
      public:
        MissingPropertyException(std::string object_type, Property &property);
    };

    class InvalidNullabilityException : public ObjectSchemaPropertyException {
      public:
        InvalidNullabilityException(std::string object_type, Property &property);
    };

    class MissingObjectTypeException : public ObjectSchemaPropertyException {
    public:
        MissingObjectTypeException(std::string object_type, Property &property);
    };

    class DuplicatePrimaryKeysException : public ObjectSchemaValidationException {
    public:
        DuplicatePrimaryKeysException(std::string object_type);
    };

    class MismatchedPropertiesException : public ObjectSchemaValidationException {
      public:
        MismatchedPropertiesException(std::string object_type, Property &old_property, Property &new_property);
        Property &old_property() { return m_old_property; }
        Property &new_property() { return m_new_property; }
      private:
        Property m_old_property, m_new_property;
    };

    class ChangedPrimaryKeyException : public ObjectSchemaValidationException {
      public:
        ChangedPrimaryKeyException(std::string object_type, std::string old_primary, std::string new_primary);
        std::string old_primary() { return m_old_primary; }
        std::string new_primary() { return m_new_primary; }
      private:
        std::string m_old_primary, m_new_primary;
    };

    class InvalidPrimaryKeyException : public ObjectSchemaValidationException {
      public:
        InvalidPrimaryKeyException(std::string object_type, std::string primary_key);
        std::string primary_key() { return m_primary_key; }
      private:
        std::string m_primary_key;
    };
}

#endif /* defined(REALM_OBJECT_STORE_HPP) */

