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

#include "object_schema.hpp"

#include "object_store.hpp"
#include "property.hpp"

#include <realm/group_shared.hpp>
#include <realm/link_view.hpp>

using namespace realm;

ObjectSchema::~ObjectSchema() = default;

ObjectSchema::ObjectSchema(const Group *group, const std::string &name) : name(name) {
    ConstTableRef table = ObjectStore::table_for_object_type(group, name);

    size_t count = table->get_column_count();
    properties.reserve(count);
    for (size_t col = 0; col < count; col++) {
        Property property;
        property.name = table->get_column_name(col).data();
        property.type = (PropertyType)table->get_column_type(col);
        property.is_indexed = table->has_search_index(col);
        property.is_primary = false;
        property.is_nullable = table->is_nullable(col) || property.type == PropertyTypeObject;
        property.table_column = col;
        if (property.type == PropertyTypeObject || property.type == PropertyTypeArray) {
            // set link type for objects and arrays
            ConstTableRef linkTable = table->get_link_target(col);
            property.object_type = ObjectStore::object_type_for_table_name(linkTable->get_name().data());
        }
        properties.push_back(std::move(property));
    }

    primary_key = realm::ObjectStore::get_primary_key_for_object(group, name);
    if (primary_key.length()) {
        auto primary_key_prop = primary_key_property();
        if (!primary_key_prop) {
            throw InvalidPrimaryKeyException(name, primary_key);
        }
        primary_key_prop->is_primary = true;
    }
}

Property *ObjectSchema::property_for_name(StringData name) {
    for (auto& prop : properties) {
        if (StringData(prop.name) == name) {
            return &prop;
        }
    }
    return nullptr;
}

const Property *ObjectSchema::property_for_name(StringData name) const {
    return const_cast<ObjectSchema *>(this)->property_for_name(name);
}
