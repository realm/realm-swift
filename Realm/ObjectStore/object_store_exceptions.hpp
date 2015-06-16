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

#ifndef REALM_OBJECT_STORE_EXCEPTIONS_HPP
#define REALM_OBJECT_STORE_EXCEPTIONS_HPP

#include <vector>
#include <map>
#include <string>

namespace realm {
    class Property;

    class ObjectStoreException : public std::exception {
    public:
        enum class Kind {
            // thrown when calling update_realm_to_schema and the realm version is greater than the given version
            RealmVersionGreaterThanSchemaVersion,   // OldVersion, NewVersion
            RealmPropertyTypeNotIndexable,          // ObjectType, PropertyName, PropertyType
            RealmDuplicatePrimaryKeyValue,          // ObjectType, PropertyName, PropertyType
            ObjectSchemaMissingProperty,            // ObjectType, PropertyName, PropertyType
            ObjectSchemaNewProperty,                // ObjectType, PropertyName, PropertyType
            ObjectSchemaMismatchedTypes,            // ObjectType, PropertyName, PropertyType, OldPropertyType
            ObjectSchemaMismatchedObjectTypes,      // ObjectType, PropertyName, PropertyType, ObjectType, OldObjectType
            ObjectSchemaMismatchedPrimaryKey,       // ObjectType, PrimaryKey, OldPrimaryKey
            ObjectSchemaChangedOptionalProperty,
            ObjectSchemaNewOptionalProperty,
            ObjectStoreValidationFailure,           // ObjectType, vector<ObjectStoreException>
        };

        enum class InfoKey {
            OldVersion,
            NewVersion,
            ObjectType,
            PropertyName,
            PropertyType,
            OldPropertyType,
            PropertyObjectType,
            OldPropertyObjectType,
            PrimaryKey,
            OldPrimaryKey,
        };
        typedef std::map<InfoKey, std::string> Info;

        ObjectStoreException(Kind kind, Info info = Info());
        ObjectStoreException(Kind kind, const std::string &object_type, const Property &prop);
        ObjectStoreException(Kind kind, const std::string &object_type, const Property &prop, const Property &oldProp);

        // ObjectStoreValidationFailure
        ObjectStoreException(std::vector<ObjectStoreException> validation_errors, const std::string &object_type);

        ObjectStoreException::Kind kind() const { return m_kind; }
        const ObjectStoreException::Info &info() const { return m_info; }
        const std::vector<ObjectStoreException> &validation_errors() { return m_validation_errors; }

        const char *what() const noexcept override  { return m_what.c_str(); }

        // implement CustomWhat to customize exception messages per platform/language
        typedef std::string (*CustomWhat)(ObjectStoreException &);
        static void set_custom_what(CustomWhat message_generator) { s_custom_what = message_generator; }

    private:
        Kind m_kind;
        Info m_info;
        std::vector<ObjectStoreException> m_validation_errors;

        std::string m_what;
        void set_what();

        static CustomWhat s_custom_what;
    };
}

#endif /* defined(REALM_OBJECT_STORE_EXCEPTIONS_HPP) */
