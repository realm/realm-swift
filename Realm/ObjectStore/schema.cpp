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

#include "schema.hpp"

#include "object_schema.hpp"
#include "object_store.hpp"
#include "property.hpp"

using namespace realm;

static bool compare_by_name(ObjectSchema const& lft, ObjectSchema const& rgt) {
    return lft.name < rgt.name;
}

Schema::Schema(base types) : base(std::move(types)) {
    std::sort(begin(), end(), compare_by_name);
}

Schema::iterator Schema::find(std::string const& name)
{
    ObjectSchema cmp;
    cmp.name = name;
    return find(cmp);
}

Schema::const_iterator Schema::find(std::string const& name) const
{
    return const_cast<Schema *>(this)->find(name);
}

Schema::iterator Schema::find(ObjectSchema const& object) noexcept
{
    auto it = std::lower_bound(begin(), end(), object, compare_by_name);
    if (it != end() && it->name != object.name) {
        it = end();
    }
    return it;
}

Schema::const_iterator Schema::find(ObjectSchema const& object) const noexcept
{
    return const_cast<Schema *>(this)->find(object);
}

void Schema::validate() const
{
    std::vector<ObjectSchemaValidationException> exceptions;
    for (auto const& object : *this) {
        const Property *primary = nullptr;
        for (auto const& prop : object.properties) {
            // check object_type existence
            if (!prop.object_type.empty() && find(prop.object_type) == end()) {
                exceptions.emplace_back(MissingObjectTypeException(object.name, prop));
            }

            // check nullablity
            if (prop.is_nullable) {
                if (prop.type == PropertyTypeArray || prop.type == PropertyTypeAny) {
                    exceptions.emplace_back(InvalidNullabilityException(object.name, prop));
                }
            }
            else if (prop.type == PropertyTypeObject) {
                exceptions.emplace_back(InvalidNullabilityException(object.name, prop));
            }

            // check primary keys
            if (prop.is_primary) {
                if (primary) {
                    exceptions.emplace_back(DuplicatePrimaryKeysException(object.name));
                }
                primary = &prop;
            }

            // check indexable
            if (prop.is_indexed) {
                if (prop.type != PropertyTypeString && prop.type != PropertyTypeInt) {
                    exceptions.emplace_back(PropertyTypeNotIndexableException(object.name, prop));
                }
            }
        }
    }

    if (exceptions.size()) {
        throw SchemaValidationException(exceptions);
    }
}
