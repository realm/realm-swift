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

using namespace realm;
using namespace std;

ObjectStoreException::ObjectStoreException(Kind kind, Dict dict) : m_kind(kind), m_dict(dict) {
    switch (m_kind) {
        case Kind::RealmVersionGreaterThanSchemaVersion:
            m_what = "Provided schema version " + m_dict.at("old_version") + " is less than last set version " + m_dict.at("new_version") + ".";
            break;
        case Kind::RealmPropertyTypeNotIndexable:
            m_what = "Can't index property '" + m_dict.at("object_type") + "." + m_dict.at("property_name") + "': " +
                     "indexing properties of type '" + m_dict.at("property_type") + "' is currently not supported";
            break;
        case Kind::RealmDuplicatePrimaryKeyValue:
            m_what = "Primary key property '" + m_dict["property_name"] + "' has duplicate values after migration.";
            break;
    }
}

ObjectStoreValidationException::ObjectStoreValidationException(std::vector<std::string> validation_errors, std::string object_type) :
    m_validation_errors(validation_errors), m_object_type(object_type) {
    m_what = "Migration is required for object type '" + m_object_type + "' due to the following errors:";
    for (auto error : m_validation_errors) {
        m_what += "\n- " + error;
    }
}
