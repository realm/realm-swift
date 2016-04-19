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

#include "object_schema.hpp"
#include "property.hpp"

#include <functional>

#include <realm/group.hpp>
#include <realm/link_view.hpp>

namespace realm {
    class ObjectSchemaValidationException;
    class Schema;

    class ObjectStore {
      public:
        // Schema version used for uninitialized Realms
        static const uint64_t NotVersioned;

        // get the last set schema version
        static uint64_t get_schema_version(const Group *group);

        // checks if the schema in the group is at the given version
        static bool is_schema_at_version(const Group *group, uint64_t version);

        // verify that schema from a group and a target schema are compatible
        // updates the column mapping on all ObjectSchema properties of the target schema
        // throws if the schema is invalid or does not match
        static void verify_schema(Schema const& actual_schema, Schema& target_schema, bool allow_missing_tables = false);

        // determines if a realm with the given old schema needs non-migration
        // changes to make it compatible with the given target schema
        static bool needs_update(Schema const& old_schema, Schema const& schema);

        // updates a Realm from old_schema to the given target schema, creating and updating tables as needed
        // passed in target schema is updated with the correct column mapping
        // optionally runs migration function if schema is out of date
        // NOTE: must be performed within a write transaction
        typedef std::function<void(Group *, Schema &)> MigrationFunction;
        static void update_realm_with_schema(Group *group, Schema const& old_schema, uint64_t version,
                                             Schema &schema, MigrationFunction migration);

        // get a table for an object type
        static realm::TableRef table_for_object_type(Group *group, StringData object_type);
        static realm::ConstTableRef table_for_object_type(const Group *group, StringData object_type);

        // get existing Schema from a group
        static Schema schema_from_group(const Group *group);

        // deletes the table for the given type
        static void delete_data_for_object(Group *group, StringData object_type);

        // indicates if this group contains any objects
        static bool is_empty(const Group *group);

        static std::string table_name_for_object_type(StringData class_name);
        static StringData object_type_for_table_name(StringData table_name);

    private:
        // set a new schema version
        static void set_schema_version(Group *group, uint64_t version);

        // check if the realm already has all metadata tables
        static bool has_metadata_tables(const Group *group);

        // create any metadata tables that don't already exist
        // must be in write transaction to set
        // returns true if it actually did anything
        static void create_metadata_tables(Group *group);

        // set references to tables on targetSchema and create/update any missing or out-of-date tables
        // if update existing is true, updates existing tables, otherwise only adds and initializes new tables
        static void create_tables(realm::Group *group, Schema &target_schema, bool update_existing);

        // verify a target schema against an expected schema, setting the table_column property on each schema object
        // updates the column mapping on the target_schema
        // returns array of validation errors
        static std::vector<ObjectSchemaValidationException> verify_object_schema(ObjectSchema const& expected,
                                                                                 ObjectSchema &target_schema);

        // get object ID property name for object type
        static StringData get_object_id_for_object(const Group *group, StringData object_type);

        // sets object ID property for object type
        // must be in write transaction to set
        static void set_object_id_for_object(Group *group, StringData object_type, StringData object_id);

        static TableRef table_for_object_type_create_if_needed(Group *group, StringData object_type, bool &created);

        // returns if any indexes were changed
        static bool update_indexes(Group *group, Schema &schema);

        // validates that all object ID properties have unique values
        static void validate_object_id_column_uniqueness(const Group *group, Schema const& schema);

        friend ObjectSchema;
    };

    // Base exception
    class ObjectStoreException : public std::exception {
      public:
        ObjectStoreException() = default;
        ObjectStoreException(const std::string &what) : m_what(what) {}
        const char* what() const noexcept override { return m_what.c_str(); }
      protected:
        std::string m_what;
    };

    // Migration exceptions
    class MigrationException : public ObjectStoreException {};

    class InvalidSchemaVersionException : public MigrationException {
      public:
        InvalidSchemaVersionException(uint64_t old_version, uint64_t new_version);
        uint64_t old_version() const { return m_old_version; }
        uint64_t new_version() const { return m_new_version; }
      private:
        uint64_t m_old_version, m_new_version;
    };

    class DuplicateObjectIDValueException : public MigrationException {
      public:
        DuplicateObjectIDValueException(std::string const& object_type, Property const& property);
        DuplicateObjectIDValueException(std::string const& object_type, Property const& property, const std::string message);

        std::string object_type() const { return m_object_type; }
        Property const& property() const { return m_property; }
      private:
        std::string m_object_type;
        Property m_property;
    };

    // Schema validation exceptions
    class SchemaValidationException : public ObjectStoreException {
      public:
        SchemaValidationException(std::vector<ObjectSchemaValidationException> const& errors);
        std::vector<ObjectSchemaValidationException> const& validation_errors() const { return m_validation_errors; }
      private:
        std::vector<ObjectSchemaValidationException> m_validation_errors;
    };

    class SchemaMismatchException : public ObjectStoreException {
    public:
        SchemaMismatchException(std::vector<ObjectSchemaValidationException> const& errors);
        std::vector<ObjectSchemaValidationException> const& validation_errors() const { return m_validation_errors; }
    private:
        std::vector<ObjectSchemaValidationException> m_validation_errors;
    };

    class ObjectSchemaValidationException : public ObjectStoreException {
      public:
        ObjectSchemaValidationException(std::string const& object_type) : m_object_type(object_type) {}
        ObjectSchemaValidationException(std::string const& object_type, std::string const& message) :
            m_object_type(object_type) { m_what = message; }
        std::string object_type() const { return m_object_type; }
      protected:
        std::string m_object_type;
    };

    class ObjectSchemaPropertyException : public ObjectSchemaValidationException {
      public:
        ObjectSchemaPropertyException(std::string const& object_type, Property const& property) :
            ObjectSchemaValidationException(object_type), m_property(property) {}
        Property const& property() const { return m_property; }
      private:
        Property m_property;
    };

    class PropertyTypeNotIndexableException : public ObjectSchemaPropertyException {
      public:
        PropertyTypeNotIndexableException(std::string const& object_type, Property const& property);
    };

    class ExtraPropertyException : public ObjectSchemaPropertyException {
      public:
        ExtraPropertyException(std::string const& object_type, Property const& property);
    };

    class MissingPropertyException : public ObjectSchemaPropertyException {
      public:
        MissingPropertyException(std::string const& object_type, Property const& property);
    };

    class InvalidNullabilityException : public ObjectSchemaPropertyException {
      public:
        InvalidNullabilityException(std::string const& object_type, Property const& property);
    };

    class MissingObjectTypeException : public ObjectSchemaPropertyException {
    public:
        MissingObjectTypeException(std::string const& object_type, Property const& property);
    };

    class DuplicateObjectIDsException : public ObjectSchemaValidationException {
    public:
        DuplicateObjectIDsException(std::string const& object_type);
    };

    class MismatchedPropertiesException : public ObjectSchemaValidationException {
      public:
        MismatchedPropertiesException(std::string const& object_type, Property const& old_property, Property const& new_property);
        Property const& old_property() const { return m_old_property; }
        Property const& new_property() const { return m_new_property; }
      private:
        Property m_old_property, m_new_property;
    };

    class ChangedObjectIDException : public ObjectSchemaValidationException {
      public:
        ChangedObjectIDException(std::string const& object_type, std::string const& old_object_id, std::string const& new_object_id);
        std::string old_object_id() const { return m_old_object_id; }
        std::string new_object_id() const { return m_new_object_id; }
      private:
        std::string m_old_object_id, m_new_object_id;
    };

    class InvalidObjectIDException : public ObjectSchemaValidationException {
      public:
        InvalidObjectIDException(std::string const& object_type, std::string const& object_id);
        std::string object_id() const { return m_object_id; }
      private:
        std::string m_object_id;
    };
}

#endif /* defined(REALM_OBJECT_STORE_HPP) */
