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
#include <regex>

using namespace realm;
using namespace std;

ObjectStoreException::ObjectStoreException(Kind kind, Info info) : m_kind(kind), m_info(info), m_what(generate_what()) {}

ObjectStoreException::ObjectStoreException(Kind kind, const std::string &object_type, const Property &prop) : m_kind(kind) {
    m_info[InfoKeyObjectType] = object_type;
    m_info[InfoKeyPropertyName] = prop.name;
    m_info[InfoKeyPropertyType] = string_for_property_type(prop.type);
    m_info[InfoKeyPropertyObjectType] = prop.object_type;
    m_what = generate_what();
}

ObjectStoreException::ObjectStoreException(Kind kind, const std::string &object_type, const Property &prop, const Property &oldProp) :
    m_kind(kind) {
    m_info[InfoKeyObjectType] = object_type;
    m_info[InfoKeyPropertyName] = prop.name;
    m_info[InfoKeyPropertyType] = string_for_property_type(prop.type);
    m_info[InfoKeyOldPropertyType] = string_for_property_type(oldProp.type);
    m_info[InfoKeyPropertyObjectType] = prop.object_type;
    m_info[InfoKeyOldPropertyObjectType] = oldProp.object_type;
    m_what = generate_what();
}

ObjectStoreException::ObjectStoreException(Kind kind, const std::string &object_type, const std::string primary_key) : m_kind(kind) {
    m_info[InfoKeyObjectType] = object_type;
    m_info[InfoKeyPrimaryKey] = primary_key;
    m_what = generate_what();
}

ObjectStoreException::ObjectStoreException(uint64_t old_version, uint64_t new_version) : m_kind(Kind::RealmVersionGreaterThanSchemaVersion) {
    m_info[InfoKeyOldVersion] = to_string(old_version);
    m_info[InfoKeyNewVersion] = to_string(new_version);
    m_what = generate_what();
}

ObjectStoreException::ObjectStoreException(vector<ObjectStoreException> validation_errors, const string &object_type) :
    m_validation_errors(validation_errors),
    m_kind(Kind::ObjectStoreValidationFailure)
{
    m_info[InfoKeyObjectType] = object_type;
    m_what = generate_what();
}

string ObjectStoreException::generate_what() const {
    auto format_string = s_custom_format_strings.find(m_kind);
    if (format_string != s_custom_format_strings.end()) {
        return populate_format_string(format_string->second);
    }
    return populate_format_string(s_default_format_strings.at(m_kind));
}

string ObjectStoreException::validation_errors_string() const {
    string errors_string;
    for (auto error : m_validation_errors) {
        errors_string += string("\n- ") + error.what();
    }
    return errors_string;
}

std::string ObjectStoreException::populate_format_string(const std::string & format_string) const {
    string out_string, current(format_string);
    smatch sm;
    regex re("\\{(\\w+)\\}");
    while(regex_search(current, sm, re)) {
        out_string += sm.prefix();
        const string &key = sm[1];
        if (key == "ValidationString") {
            out_string += validation_errors_string();
        }
        else {
            out_string += m_info.at(key);
        }
        current = sm.suffix();
    }
    out_string += current;
    return out_string;
}

ObjectStoreException::FormatStrings ObjectStoreException::s_custom_format_strings;
const ObjectStoreException::FormatStrings ObjectStoreException::s_default_format_strings = {
    {Kind::RealmVersionGreaterThanSchemaVersion,
        "Provided schema version {InfoKeyNewVersion} is less than last set version {InfoKeyOldVersion}."},
    {Kind::RealmPropertyTypeNotIndexable,
        "Can't index property {InfoKeyObjectType}.{InfoKeyPropertyName}: indexing a property of type '{InfoKeyPropertyType}' is currently not supported"},
    {Kind::RealmDuplicatePrimaryKeyValue,
        "Primary key property '{InfoKeyPropertyType}' has duplicate values after migration."},
    {Kind::ObjectSchemaMissingProperty,
        "Property '{InfoKeyPropertyName}' is missing from latest object model."},
    {Kind::ObjectSchemaNewProperty,
        "Property '{InfoKeyPropertyName}' has been added to latest object model."},
    {Kind::ObjectSchemaMismatchedTypes,
        "Property types for '{InfoKeyPropertyName}' property do not match. Old type '{InfoKeyOldPropertyType}', new type '{InfoKeyPropertyType}'"},
    {Kind::ObjectSchemaMismatchedObjectTypes,
        "Target object type for property '{InfoKeyPropertyName}' does not match. Old type '{InfoKeyOldPropertyObjectType}', new type '{InfoKeyPropertyObjectType}'."},
    {Kind::ObjectSchemaChangedPrimaryKey,
        "Property '{InfoKeyPrimaryKey}' is no longer a primary key."},
    {Kind::ObjectSchemaNewPrimaryKey,
        "Property '{InfoKeyPrimaryKey}' has been made a primary key."},
    {Kind::ObjectSchemaChangedOptionalProperty,
        "Property '{InfoKeyPrimaryKey}' is no longer optional."},
    {Kind::ObjectSchemaNewOptionalProperty,
        "Property '{InfoKeyPrimaryKey}' has been made optional."},
    {Kind::ObjectStoreValidationFailure,
        "Migration is required for object type '{InfoKeyObjectType}' due to the following errors: {ValidationErrors}"}
};


