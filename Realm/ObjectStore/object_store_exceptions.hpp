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
            RealmVersionGreaterThanSchemaVersion,   // OldVersion, NewVersion
            RealmPropertyTypeNotIndexable,          // ObjectType, PropertyName, PropertyType
            RealmDuplicatePrimaryKeyValue,          // ObjectType, PropertyName, PropertyType
            ObjectSchemaMissingProperty,            // ObjectType, PropertyName, PropertyType
            ObjectSchemaNewProperty,                // ObjectType, PropertyName, PropertyType
            ObjectSchemaMismatchedTypes,            // ObjectType, PropertyName, PropertyType, OldPropertyType
            ObjectSchemaMismatchedObjectTypes,      // ObjectType, PropertyName, PropertyType, ObjectType, OldObjectType
            ObjectSchemaChangedPrimaryKey,          // ObjectType, PrimaryKey
            ObjectSchemaNewPrimaryKey,              // ObjectType, PrimaryKey
            ObjectSchemaChangedOptionalProperty,
            ObjectSchemaNewOptionalProperty,
            ObjectStoreValidationFailure,           // ObjectType, vector<ObjectStoreException>
        };

        typedef const std::string InfoKey;
        typedef std::map<std::string, std::string> Info;

        ObjectStoreException(Kind kind, const std::string &object_type, const Property &prop);

        // ObjectSchemaMismatchedTypes, ObjectSchemaMismatchedObjectTypes
        ObjectStoreException(Kind kind, const std::string &object_type, const Property &prop, const Property &oldProp);

        // ObjectSchemaChangedPrimaryKey, ObjectSchemaNewPrimaryKey
        ObjectStoreException(Kind kind, const std::string &object_type, const std::string primary_key);

        // RealmVersionGreaterThanSchemaVersion
        ObjectStoreException(uint64_t old_version, uint64_t new_version);

        // ObjectStoreValidationFailure
        ObjectStoreException(std::vector<ObjectStoreException> validation_errors, const std::string &object_type);

        ObjectStoreException::Kind kind() const { return m_kind; }
        const ObjectStoreException::Info &info() const { return m_info; }

        const char *what() const noexcept override  { return m_what.c_str(); }

        // implement CustomWhat to customize exception messages per platform/language
        typedef std::map<Kind, std::string> FormatStrings;
        static void set_custom_format_strings(FormatStrings custom_format_strings) { s_custom_format_strings = custom_format_strings; }

    private:
        ObjectStoreException(Kind kind, Info info = Info());

        Kind m_kind;
        Info m_info;
        std::vector<ObjectStoreException> m_validation_errors;

        std::string m_what;
        std::string generate_what() const;
        std::string validation_errors_string() const;
        std::string populate_format_string(const std::string &format_string) const;

        static const FormatStrings s_default_format_strings;
        static FormatStrings s_custom_format_strings;

    public:
        #define INFO_KEY(key) InfoKey InfoKey##key = "InfoKey" #key;
        INFO_KEY(OldVersion);
        INFO_KEY(NewVersion);
        INFO_KEY(ObjectType);
        INFO_KEY(PropertyName);
        INFO_KEY(PropertyType);
        INFO_KEY(OldPropertyType);
        INFO_KEY(PropertyObjectType);
        INFO_KEY(OldPropertyObjectType);
        INFO_KEY(PrimaryKey);
        #undef INFO_KEY
    };
}

#endif /* defined(REALM_OBJECT_STORE_EXCEPTIONS_HPP) */
