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
#ifndef TIGHTDB_COLUMN_TYPE_HPP
#define TIGHTDB_COLUMN_TYPE_HPP

namespace tightdb {


// Note: Enumeration value assignments must be kept in sync with
// <tightdb/data_type.hpp>.
enum ColumnType {
    // Column types
    col_type_Int         =  0,
    col_type_Bool        =  1,
    col_type_String      =  2,
    col_type_StringEnum  =  3, // double refs
    col_type_Binary      =  4,
    col_type_Table       =  5,
    col_type_Mixed       =  6,
    col_type_DateTime    =  7,
    col_type_Reserved1   =  8, // new date
    col_type_Float       =  9,
    col_type_Double      = 10,
    col_type_Reserved4   = 11, // Decimal
    col_type_Link        = 12,
    col_type_LinkList    = 13,
    col_type_BackLink    = 14
};


// Column attributes can be combined using bitwise or.
enum ColumnAttr {
    col_attr_None = 0,
    col_attr_Indexed = 1,

    // Specifies that this column forms a unique constraint. It requires
    // `col_attr_Indexed`.
    col_attr_Unique = 2,

    // Specifies that this column forms the primary key. It implies a non-null
    // constraint on the column, and it requires `col_attr_Unique`.
    col_attr_PrimaryKey = 4
};


} // namespace tightdb

#endif // TIGHTDB_COLUMN_TYPE_HPP
