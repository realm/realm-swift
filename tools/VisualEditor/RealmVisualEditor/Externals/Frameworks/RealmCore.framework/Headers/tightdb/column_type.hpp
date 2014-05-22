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

// Note: Value assignments must be kept in sync with <RealmCore/tightdb/data_type.hpp>
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
    col_type_Reserved4   = 11  // Decimal
};

// Attributes are bitmasks
enum ColumnAttr {
    col_attr_None        = 0,
    col_attr_Indexed     = 1,
    col_attr_Unique      = 2,
    col_attr_Sorted      = 4
};


} // namespace tightdb

#endif // TIGHTDB_COLUMN_TYPE_HPP
