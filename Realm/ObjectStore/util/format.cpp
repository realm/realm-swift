////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#include "util/format.hpp"

#include <sstream>

#include <realm/string_data.hpp>
#include <realm/util/assert.hpp>

namespace realm { namespace _impl {
Printable::Printable(StringData value) : m_type(Type::String), m_string(value.data()) { }

void Printable::print(std::ostream& out) const
{
    switch (m_type) {
        case Printable::Type::Bool:
            out << (m_uint ? "true" : "false");
            break;
        case Printable::Type::Uint:
            out << m_uint;
            break;
        case Printable::Type::Int:
            out << m_int;
            break;
        case Printable::Type::String:
            out << m_string;
            break;
    }
}

std::string format(const char* fmt, std::initializer_list<Printable> values)
{
    std::stringstream ss;
    while (*fmt) {
        auto next = strchr(fmt, '%');

        // emit the rest of the format string if there are no more percents
        if (!next) {
            ss << fmt;
            break;
        }

        // emit everything up to the next percent
        ss.write(fmt, next - fmt);
        ++next;
        REALM_ASSERT(*next);

        // %% produces a single escaped %
        if (*next == '%') {
            ss << '%';
            fmt = next + 1;
            continue;
        }
        REALM_ASSERT(isdigit(*next));

        // The const_cast is safe because stroul does not actually modify
        // the pointed-to string, but it lacks a const overload
        auto index = strtoul(next, const_cast<char**>(&fmt), 10) - 1;
        REALM_ASSERT(index < values.size());
        (values.begin() + index)->print(ss);
    }
    return ss.str();
}

} // namespace _impl
} // namespace realm
