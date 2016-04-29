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

#include "object_store.hpp"
#include "property.hpp"

#include <algorithm>

using namespace realm;

static bool compare_by_name(ObjectSchema const& lft, ObjectSchema const& rgt) {
    return lft.name < rgt.name;
}

Schema::Schema(std::initializer_list<ObjectSchema> types) : Schema(base(types)) { }

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

        std::vector<Property> all_properties = object.persisted_properties;
        all_properties.insert(all_properties.end(), object.computed_properties.begin(), object.computed_properties.end());

        for (auto const& prop : all_properties) {
            // check object_type existence
            if (!prop.object_type.empty()) {
                auto it = find(prop.object_type);
                if (it == end()) {
                    exceptions.emplace_back(MissingObjectTypeException(object.name, prop));
                }
                // validate linking objects property.
                else if (!prop.link_origin_property_name.empty()) {
                    using ErrorType = InvalidLinkingObjectsPropertyException::Type;
                    util::Optional<ErrorType> error;

                    const Property *origin_property = it->property_for_name(prop.link_origin_property_name);
                    if (!origin_property) {
                        error = ErrorType::OriginPropertyDoesNotExist;
                    }
                    else if (origin_property->type != PropertyType::Object && origin_property->type != PropertyType::Array) {
                        error = ErrorType::OriginPropertyIsNotALink;
                    }
                    else if (origin_property->object_type != object.name) {
                        error = ErrorType::OriginPropertyInvalidLinkTarget;
                    }

                    if (error) {
                        exceptions.emplace_back(InvalidLinkingObjectsPropertyException(*error, object.name, prop));
                    }
                }
            }

            // check nullablity
            if (prop.is_nullable) {
                if (prop.type == PropertyType::Array || prop.type == PropertyType::Any || prop.type == PropertyType::LinkingObjects) {
                    exceptions.emplace_back(InvalidNullabilityException(object.name, prop));
                }
            }
            else if (prop.type == PropertyType::Object) {
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
            if (prop.is_indexed && !prop.is_indexable()) {
                exceptions.emplace_back(PropertyTypeNotIndexableException(object.name, prop));
            }
        }
    }

    if (exceptions.size()) {
        throw SchemaValidationException(exceptions);
    }
}
