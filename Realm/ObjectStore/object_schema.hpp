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

#ifndef REALM_OBJECT_SCHEMA_HPP
#define REALM_OBJECT_SCHEMA_HPP

#include <realm/string_data.hpp>

#include <string>
#include <vector>

namespace realm {
    class Group;
    struct Property;

    class ObjectSchema {
    public:
        ObjectSchema() = default;
        ObjectSchema(std::string name, std::string primary_key, std::initializer_list<Property> properties);
        ~ObjectSchema();

        // create object schema from existing table
        // if no table is provided it is looked up in the group
        ObjectSchema(const Group *group, const std::string &name);

        std::string name;
        std::vector<Property> properties;
        std::string primary_key;

        Property *property_for_name(StringData name);
        const Property *property_for_name(StringData name) const;
        Property *primary_key_property() {
            return property_for_name(primary_key);
        }
        const Property *primary_key_property() const {
            return property_for_name(primary_key);
        }

    private:
        void set_primary_key_property();
    };
}

#endif /* defined(REALM_OBJECT_SCHEMA_HPP) */
