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

#ifndef REALM_PROPERTY_HPP
#define REALM_PROPERTY_HPP

#include <string>

namespace realm {
    enum class PropertyType {
        /** Integer type: NSInteger, int, long, Int (Swift) */
        Int    = 0,
        /** Boolean type: BOOL, bool, Bool (Swift) */
        Bool   = 1,
        /** Float type: float, Float (Swift) */
        Float  = 9,
        /** Double type: double, Double (Swift) */
        Double = 10,
        /** String type: NSString, String (Swift) */
        String = 2,
        /** Data type: NSData */
        Data   = 4,
        /** Any type: id, **not supported in Swift** */
        Any    = 6,
        /** Date type: NSDate */
        Date   = 7,
        /** Object type. See [Realm Models](https://realm.io/docs/objc/latest/#models) */
        Object = 12,
        /** Array type. See [Realm Models](https://realm.io/docs/objc/latest/#models) */
        Array  = 13,
        /** Linking objects type. See [Realm Models](https://realm.io/docs/objc/latest/#models) */
        LinkingObjects = 14,
    };

    struct Property {
        std::string name;
        PropertyType type;
        std::string object_type;
        std::string link_origin_property_name;
        bool is_primary = false;
        bool is_indexed = false;
        bool is_nullable = false;

        size_t table_column = -1;
        bool requires_index() const { return is_primary || is_indexed; }
        bool is_indexable() const {
            return type == PropertyType::Int
                || type == PropertyType::Bool
                || type == PropertyType::String
                || type == PropertyType::Date;
        }
    };

    static inline const char *string_for_property_type(PropertyType type) {
        switch (type) {
            case PropertyType::String:
                return "string";
            case PropertyType::Int:
                return "int";
            case PropertyType::Bool:
                return "bool";
            case PropertyType::Date:
                return "date";
            case PropertyType::Data:
                return "data";
            case PropertyType::Double:
                return "double";
            case PropertyType::Float:
                return "float";
            case PropertyType::Any:
                return "any";
            case PropertyType::Object:
                return "object";
            case PropertyType::Array:
                return "array";
            case PropertyType::LinkingObjects:
                return "linking objects";
        }
    }
}

#endif /* REALM_PROPERTY_HPP */
