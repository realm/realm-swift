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

#include <realm/table.hpp>

using namespace realm;

ObjectSchema::ObjectSchema() = default;
ObjectSchema::~ObjectSchema() = default;

ObjectSchema::ObjectSchema(std::string name, std::string object_id, std::initializer_list<Property> properties)
: name(std::move(name))
, properties(properties)
, object_id(std::move(object_id))
{
    set_object_id_property();
}

ObjectSchema::ObjectSchema(const Group *group, const std::string &name) : name(name) {
    ConstTableRef table = ObjectStore::table_for_object_type(group, name);

    size_t count = table->get_column_count();
    properties.reserve(count);
    for (size_t col = 0; col < count; col++) {
        Property property;
        property.name = table->get_column_name(col).data();
        property.type = (PropertyType)table->get_column_type(col);
        property.is_indexed = table->has_search_index(col);
        property.is_object_id = false;
        property.is_nullable = table->is_nullable(col) || property.type == PropertyType::Object;
        property.table_column = col;
        if (property.type == PropertyType::Object || property.type == PropertyType::Array) {
            // set link type for objects and arrays
            ConstTableRef linkTable = table->get_link_target(col);
            property.object_type = ObjectStore::object_type_for_table_name(linkTable->get_name().data());
        }
        properties.push_back(std::move(property));
    }

    object_id = realm::ObjectStore::get_object_id_for_object(group, name);
    set_object_id_property();
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

void ObjectSchema::set_object_id_property()
{
    if (object_id.length()) {
        auto object_id_prop = object_id_property();
        if (!object_id_prop) {
            throw InvalidObjectIDException(name, object_id);
        }
        object_id_prop->is_object_id = true;
    }
}
