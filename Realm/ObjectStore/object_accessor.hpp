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

#ifndef REALM_OBJECT_ACCESSOR
#define REALM_OBJECT_ACCESSOR

#include <realm/link_view.hpp>
#include <realm/row.hpp>

#include <map>

#include "shared_realm.hpp"

namespace realm {
    class Object;
    class Array;

    class AccessorException : public std::exception
    {
    public:
        enum class Kind
        {
            InvalidatedObject,
            MutationWithoutWriteTransaction,
            DuplicatePrimaryKeyValue,
            MismatchedObjectType,
        };
        AccessorException(Kind kind, std::string message) : m_kind(kind), m_what(message) {}

        virtual const char *what() noexcept { return m_what.c_str(); }
        Kind kind() const { return m_kind; }

    private:
        Kind m_kind;
        std::string m_what;
    };

    template<typename StringType = StringData, typename DateType = DateTime, typename DataType = BinaryData, typename ObjectType = Row, typename ArrayType = TableView>
    class NativeAccessors {
    public:

        //
        // native <=> core conversions
        //
        static StringData to_string_data(StringType value);
        static StringType to_string_type(StringData string_data);
        static DateTime to_date_time(DateType value);
        static DateType to_date_type(DateTime date_time);
        static BinaryData to_binary_data(DataType value);
        static DataType to_data_type(BinaryData binary_data);

        static ObjectType to_object(Realm *realm, Row &row, const Property &prop);
        static Row object_row(ObjectType object);
        static Realm *object_realm(ObjectType object);
        static ObjectType null_object();
        static bool is_null(ObjectType object);

        static ArrayType to_array(Realm *realm, LinkViewRef link_view, const Property &prop);

        //
        // validation
        //

        // verify attached
        static void VerifyAttached(const Row &row, Realm *realm)
        {
            if (!row.is_attached()) {
                throw AccessorException(AccessorException::Kind::InvalidatedObject,
                                        "Object has been deleted or invalidated.");
            }
            realm->verify_thread();
        }

        // verify writable
        static void VerifyInWriteTransaction(Realm *realm)
        {
            if (!realm->is_in_transaction()) {
                throw AccessorException(AccessorException::Kind::MutationWithoutWriteTransaction,
                                        "Attempting to modify object outside of a write transaction.");
            }
        }

        // verify unique
        static bool VerifyMatchingOrUnique(size_t found_index, const Row &row)
        {
            if (found_index == row.get_index()) {
                return true;
            }
            if (found_index != realm::not_found) {
                throw AccessorException(AccessorException::Kind::DuplicatePrimaryKeyValue, "Duplicate value for primary key");
            }
            return false;
        }

        static void VerifyMatchingObjectTypes(ObjectType object, const Row &row, __unused Property &prop)
        {
            if (row.get_table() != object_row(object).get_table()) {
                throw AccessorException(AccessorException::Kind::MismatchedObjectType, "Object type does not match property");
            }
        }

        //
        // object property accessors
        //

        // long getter/setter
        static long long get_long(Realm *realm, const Row &row, size_t column_index)
        {
            VerifyAttached(row, realm);
            return row.get_int(column_index);
        }

        static void set_long(Realm *realm, Row &row, size_t column_index, long long value, bool verify_unique)
        {
            VerifyInWriteTransaction(realm);
            VerifyAttached(row, realm);
            if (verify_unique) {
                if (VerifyMatchingOrUnique(row.get_table()->find_first_int(column_index, value), row)) {
                    return;
                }
            }
            row.set_int(column_index, value);
        }

        // float getter/setter
        static float get_float(Realm *realm, const Row &row, size_t column_index)
        {
            VerifyAttached(row, realm);
            return row.get_float(column_index);
        }

        static void set_float(Realm *realm, Row &row, size_t column_index, float value)
        {
            VerifyInWriteTransaction(realm);
            VerifyAttached(row, realm);
            row.set_float(column_index, value);
        }

        // double getter/setter
        static double get_double(Realm *realm, const Row &row, size_t column_index)
        {
            VerifyAttached(row, realm);
            return row.get_double(column_index);
        }
        static void set_double(Realm *realm, Row &row, size_t column_index, double value)
        {
            VerifyInWriteTransaction(realm);
            VerifyAttached(row, realm);
            row.set_double(column_index, value);
        }
        
        // bool getter/setter
        static bool get_bool(Realm *realm, const Row &row, size_t column_index)
        {
            VerifyAttached(row, realm);
            return row.get_bool(column_index);
        }
        static void set_bool(Realm *realm, Row &row, size_t column_index, bool value)
        {
            VerifyInWriteTransaction(realm);
            VerifyAttached(row, realm);
            row.set_bool(column_index, value);
        }

        // string getter/setter
        static StringType get_string(Realm *realm, const Row &row, size_t column_index)
        {
            VerifyAttached(row, realm);
            return to_string_type(row.get_string(column_index));
        }
        static void set_string(Realm *realm, Row &row, size_t column_index, StringType value, bool verify_unique)
        {
            VerifyInWriteTransaction(realm);
            VerifyAttached(row, realm);
            if (verify_unique) {
                if (VerifyMatchingOrUnique(row.get_table()->find_first_string(column_index, to_string_data(value))), row) {
                    return;
                }
            }
            row.set_string(column_index, to_string_data(value));
        }

        // date getter/setter
        static DateType get_date(Realm *realm, const Row &row, size_t column_index)
        {
            VerifyAttached(row, realm);
            return to_date_type(row.get_datetime(column_index));
        }
        static void set_date(Realm *realm, Row &row, size_t column_index, DateType value)
        {
            VerifyInWriteTransaction(realm);
            VerifyAttached(row, realm);
            row.set_datetime(column_index, to_date_time(value));
        }

        // data getter/setter
        static DataType get_data(Realm *realm, const Row &row, size_t column_index)
        {
            VerifyAttached(row, realm);
            return to_data_type(row.get_binary(column_index));
        }
        static void set_data(Realm *realm, Row &row, size_t column_index, DataType value)
        {
            VerifyInWriteTransaction(realm);
            VerifyAttached(row, realm);
            row.set_binary(column_index, to_binary_data(value));
        }


        // object/array property helper
        static ObjectType VerifyObjectProperty(Realm *realm, const Row &row, const Property &prop, ObjectType object)
        {
            VerifyMatchingObjectTypes(object, row, prop);
            VerifyAttached(row, realm);

            if (object_realm(object) == realm) {
                return object;
            }
            throw;
        }

        // object getter/setter
        static ObjectType get_object(Realm *realm, const Row &row, size_t column_index, const Property &prop)
        {
            VerifyAttached(row, realm);
            if (row.is_null_link(column_index)) {
                return null_object();
            }
            return to_object(realm, row.get_table()->get_link_target(column_index)->get(row.get_link(column_index)), prop);
        }

        static void set_object(Realm *realm, Row &row, size_t column_index, const Property &prop, ObjectType object)
        {
            VerifyInWriteTransaction(realm);
            VerifyAttached(row, realm);
            if (is_null(object)) {
                row.nullify_link(column_index);
            }
            else {
                VerifyMatchingObjectTypes(object, prop);
                VerifyObjectProperty(realm, row, prop, object);
                row.set_link(column_index, object_row(object).get_index());
            }
        }

        static ArrayType get_array(Realm *realm, const Row &row, size_t column_index, const Property &prop)
        {
            VerifyAttached(row, realm);
            return to_array(realm, row.get_linklist(column_index), prop);
        }

        typedef void (*Inserter)(ObjectType &to_insert);
        typedef void (*InsertEnumerator)(Inserter insert);

        static void set_array(Realm *realm, Row &row, size_t column_index, const Property &prop, InsertEnumerator insert_objects)
        {
            VerifyInWriteTransaction(realm);
            VerifyAttached(row, realm);

            LinkViewRef link_view = row.get_linklist(column_index);
            link_view->clear();

            insert_objects([=](ObjectType &to_insert) {
                VerifyMatchingObjectTypes(to_insert, prop);
                link_view->add(object_row(to_insert));
            });
        }

/*
        // dynamic accessors
        static void set(Row &row, Property &prop, ValueType value, Realm::CreationOptions options);

        // dictionary accessors
        static ValueType value_for_property(DictType dict, const std::string &prop_name);

        // value accessors
        static long long to_long(ValueType &val);
        static std::string to_string(ValueType &val);
*/
    };
}

#endif /* defined(REALM_OBJECT_ACCESSOR) */
