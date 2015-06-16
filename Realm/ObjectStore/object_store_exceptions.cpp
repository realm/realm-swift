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

#include "object_store_exceptions.hpp"
#include "property.hpp"

#include <realm/util/assert.hpp>

using namespace realm;
using namespace std;

ObjectStoreException::CustomWhat ObjectStoreException::s_custom_what = nullptr;
string ObjectStoreException::s_property_string = "property";
string ObjectStoreException::s_property_string_upper = "Property";

ObjectStoreException::ObjectStoreException(Kind kind, Info info) : m_kind(kind), m_info(info) {
    set_what();
}

ObjectStoreException::ObjectStoreException(Kind kind, const std::string &object_type, const Property &prop) : m_kind(kind) {
    m_info[InfoKey::ObjectType] = object_type;
    m_info[InfoKey::PropertyName] = prop.name;
    m_info[InfoKey::PropertyType] = string_for_property_type(prop.type);
    m_info[InfoKey::PropertyObjectType] = prop.object_type;
    set_what();
}

ObjectStoreException::ObjectStoreException(Kind kind, const std::string &object_type, const Property &prop, const Property &oldProp) :
    m_kind(kind) {
    m_info[InfoKey::ObjectType] = object_type;
    m_info[InfoKey::PropertyName] = prop.name;
    m_info[InfoKey::PropertyType] = string_for_property_type(prop.type);
    m_info[InfoKey::OldPropertyType] = string_for_property_type(oldProp.type);
    m_info[InfoKey::PropertyObjectType] = prop.object_type;
    m_info[InfoKey::OldPropertyObjectType] = oldProp.object_type;
    set_what();
}

void ObjectStoreException::set_what() {
    if (s_custom_what) {
        string custom = s_custom_what(*this);
        if (custom.length()) {
            m_what = custom;
            return;
        }
    }

    switch (m_kind) {
        case Kind::RealmVersionGreaterThanSchemaVersion:
            m_what = "Provided schema version " + m_info[InfoKey::NewVersion] +
                        " is less than last set version " + m_info[InfoKey::OldVersion] + ".";
            break;
        case Kind::RealmPropertyTypeNotIndexable:
            m_what = "Can't index " + s_property_string + " '" + m_info[InfoKey::ObjectType] + "." + m_info[InfoKey::PropertyName] + "': " +
                        "indexing a " + s_property_string + " of type '" + m_info[InfoKey::PropertyType] + "' is currently not supported";
            break;
        case Kind::RealmDuplicatePrimaryKeyValue:
            m_what = "Primary key " + s_property_string + " '" + m_info[InfoKey::PropertyType] + "' has duplicate values after migration.";
            break;
        case Kind::ObjectSchemaMissingProperty:
            m_what = s_property_string_upper + " '" + m_info[InfoKey::PropertyName] + "' is missing from latest object model.";
            break;
        case Kind::ObjectSchemaNewProperty:
            m_what = s_property_string_upper + " '" + m_info[InfoKey::PropertyName] + "' has been added to latest object model.";
            break;
        case Kind::ObjectSchemaMismatchedTypes:
            m_what = s_property_string_upper + " types for '" + m_info[InfoKey::PropertyName] + "' " + s_property_string + " do not match. " +
                        "Old type '" + m_info[InfoKey::OldPropertyType] + "', new type '" + m_info[InfoKey::PropertyType] + "'";
            break;
        case Kind::ObjectSchemaMismatchedObjectTypes:
            m_what = "Target object type for " + s_property_string + " '" + m_info[InfoKey::PropertyName] + "' does not match. " +
                        "Old type '" + m_info[InfoKey::OldPropertyObjectType] + "', new type '" + m_info[InfoKey::PropertyObjectType] + "'.";
            break;
        case Kind::ObjectSchemaMismatchedPrimaryKey:
            if (!m_info[InfoKey::PrimaryKey].length()) {
                m_what = s_property_string_upper + " '" +  m_info[InfoKey::OldPrimaryKey] + "' is no longer a primary key.";
            }
            else {
                m_what = s_property_string_upper + " '" + m_info[InfoKey::PrimaryKey] + "' has been made a primary key.";
            }
            break;
        case Kind::ObjectStoreValidationFailure:
            m_what = "Migration is required for object type '" + info().at(InfoKey::ObjectType) + "' due to the following errors:";
            for (auto error : m_validation_errors) {
                m_what += string("\n- ") + error.what();
            }
            break;
    }
}

ObjectStoreException::ObjectStoreException(vector<ObjectStoreException> validation_errors, const string &object_type) :
    m_validation_errors(validation_errors), m_kind(Kind::ObjectStoreValidationFailure), m_info({{InfoKey::ObjectType, object_type}}) {
    set_what();
}

void ObjectStoreException::set_property_string(std::string property_string) {
    s_property_string = s_property_string_upper = property_string;
    s_property_string[0] = tolower(s_property_string[0]);
    s_property_string_upper[0] = toupper(s_property_string_upper[0]);

}


