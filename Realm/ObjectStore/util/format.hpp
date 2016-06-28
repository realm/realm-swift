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

#ifndef REALM_UTIL_FORMAT_HPP
#define REALM_UTIL_FORMAT_HPP

#include <cstdint>
#include <iosfwd>
#include <initializer_list>
#include <string>

namespace realm {
class StringData;

namespace _impl {
class Printable {
public:
    Printable(bool value) : m_type(Type::Bool), m_uint(value) { }
    Printable(unsigned char value) : m_type(Type::Uint), m_uint(value) { }
    Printable(unsigned int value) : m_type(Type::Uint), m_uint(value) { }
    Printable(unsigned long value) : m_type(Type::Uint), m_uint(value) { }
    Printable(unsigned long long value) : m_type(Type::Uint), m_uint(value) { }
    Printable(char value) : m_type(Type::Int), m_int(value) { }
    Printable(int value) : m_type(Type::Int), m_int(value) { }
    Printable(long value) : m_type(Type::Int), m_int(value) { }
    Printable(long long value) : m_type(Type::Int), m_int(value) { }
    Printable(const char* value) : m_type(Type::String), m_string(value) { }
    Printable(std::string const& value) : m_type(Type::String), m_string(value.c_str()) { }
    Printable(StringData value);

    void print(std::ostream& out) const;

private:
    enum class Type {
        Bool,
        Int,
        Uint,
        String
    } m_type;

    union {
        uintmax_t m_uint;
        intmax_t m_int;
        const char* m_string;
    };
};
std::string format(const char* fmt, std::initializer_list<Printable>);
} // namespace _impl

namespace util {
template<typename... Args>
std::string format(const char* fmt, Args&&... args)
{
    return _impl::format(fmt, {_impl::Printable(args)...});
}

} // namespace util
} // namespace realm

#endif // REALM_UTIL_FORMAT_HPP
