/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2012] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#ifndef TIGHTDB_EXCEPTIONS_HPP
#define TIGHTDB_EXCEPTIONS_HPP

#include <exception>

#include <tightdb/util/features.h>

namespace tightdb {


/// Thrown by various functions to indicate that a specified table does not
/// exist.
class NoSuchTable: public std::exception {
public:
    const char* what() const TIGHTDB_NOEXCEPT_OR_NOTHROW TIGHTDB_OVERRIDE;
};


/// Thrown by various functions to indicate that a specified table name is
/// already in use.
class TableNameInUse: public std::exception {
public:
    const char* what() const TIGHTDB_NOEXCEPT_OR_NOTHROW TIGHTDB_OVERRIDE;
};


// Thrown by functions that require a table to **not** be the target of link
// columns, unless those link columns are part of the table itself.
class CrossTableLinkTarget: public std::exception {
public:
    const char* what() const TIGHTDB_NOEXCEPT_OR_NOTHROW TIGHTDB_OVERRIDE;
};


/// Thrown by various functions to indicate that the dynamic type of a table
/// does not match a particular other table type (dynamic or static).
class DescriptorMismatch: public std::exception {
public:
    const char* what() const TIGHTDB_NOEXCEPT_OR_NOTHROW TIGHTDB_OVERRIDE;
};


/// Reports errors that are a consequence of faulty logic within the program,
/// such as violating logical preconditions or class invariants, and can be
/// easily predicted.
class LogicError: public std::exception {
public:
    static const char* const table_index_out_of_range;
    static const char* const row_index_out_of_range;
    static const char* const column_index_out_of_range;

    /// Indicates that an argument has a value that is illegal in combination
    /// with another argument, or with the state of an involved object.
    static const char* const illegal_combination;

    /// Indicates a data type mismatch, such as when `Table::find_pkey_int()` is
    /// called and the type of the primary key is not `type_Int`.
    static const char* const type_mismatch;

    /// Indicates that an involved table is of the wrong kind, i.e., if it is a
    /// subtable, and the function requires a root table.
    static const char* const wrong_kind_of_table;

    /// Indicates that an involved accessor is was detached, i.e., was not
    /// attached to an underlying object.
    static const char* const detached_accessor;

    // Indicates that an involved column lacks a search index.
    static const char* const no_search_index;

    // Indicates that an involved table lacks a primary key.
    static const char* const no_primary_key;

    // Indicates that an attempt was made to add a primary key to a table that
    // already had a primary key.
    static const char* const has_primary_key;

    /// Indicates that a modification was attempted that would have produced a
    /// duplicate primary value.
    static const char* const unique_constraint_violation;

    LogicError(const char* message);

    const char* what() const TIGHTDB_NOEXCEPT_OR_NOTHROW TIGHTDB_OVERRIDE;

private:
    const char* m_message;
};





// Implementation:

inline const char* NoSuchTable::what() const TIGHTDB_NOEXCEPT_OR_NOTHROW
{
    return "No such table exists";
}

inline const char* TableNameInUse::what() const TIGHTDB_NOEXCEPT_OR_NOTHROW
{
    return "The specified table name is already in use";
}

inline const char* CrossTableLinkTarget::what() const TIGHTDB_NOEXCEPT_OR_NOTHROW
{
    return "Table is target of cross-table link columns";
}

inline const char* DescriptorMismatch::what() const TIGHTDB_NOEXCEPT_OR_NOTHROW
{
    return "Table descriptor mismatch";
}

inline LogicError::LogicError(const char* message):
    m_message(message)
{
}

inline const char* LogicError::what() const TIGHTDB_NOEXCEPT_OR_NOTHROW
{
    return m_message;
}


} // namespace tightdb

#endif // TIGHTDB_EXCEPTIONS_HPP
