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

    class ObjectStoreException : public std::exception {
    public:
        enum class Kind {
            // thrown when calling update_realm_to_schema and the realm version is greater than the given version
            RealmVersionGreaterThanSchemaVersion,   // old_version, new_version
            RealmPropertyTypeNotIndexable,          // object_type, property_name, property_type
            RealmDuplicatePrimaryKeyValue,          // object_type, property_name
        };
        typedef std::map<std::string, std::string> Dict;

        ObjectStoreException(Kind kind, Dict dict = Dict());

        ObjectStoreException::Kind kind() const { return m_kind; }
        const ObjectStoreException::Dict &dict() const { return m_dict; }

        const char *what() const noexcept override  { return m_what.c_str(); }

    private:
        Kind m_kind;
        Dict m_dict;
        std::string m_what;
    };

    class ObjectStoreValidationException : public std::exception {
    public:
        ObjectStoreValidationException(std::vector<std::string> validation_errors, std::string object_type);

        const std::vector<std::string> &validation_errors() const { return m_validation_errors; }
        std::string object_type() const { return m_object_type; }
        const char *what() const noexcept override { return m_what.c_str(); }

    private:
        std::vector<std::string> m_validation_errors;
        std::string m_object_type;
        std::string m_what;
    };
}

#endif /* defined(REALM_OBJECT_STORE_EXCEPTIONS_HPP) */
