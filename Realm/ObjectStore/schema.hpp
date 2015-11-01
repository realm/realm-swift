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

#ifndef REALM_SCHEMA_HPP
#define REALM_SCHEMA_HPP

#include <vector>

namespace realm {
class ObjectSchema;

class Schema : private std::vector<ObjectSchema> {
private:
    using base = std::vector<ObjectSchema>;
public:
    // Create a schema from a vector of ObjectSchema
    Schema(base types);

    // find an ObjectSchema by name
    iterator find(std::string const& name);
    const_iterator find(std::string const& name) const;

    // find an ObjectSchema with the same name as the passed in one
    iterator find(ObjectSchema const& object) noexcept;
    const_iterator find(ObjectSchema const& object) const noexcept;

    // Verify that this schema is internally consistent (i.e. all properties are
    // valid, links link to types that actually exist, etc.)
    void validate() const;

    using base::iterator;
    using base::const_iterator;
    using base::begin;
    using base::end;
    using base::empty;
    using base::size;
};
}

#endif /* defined(REALM_SCHEMA_HPP) */
