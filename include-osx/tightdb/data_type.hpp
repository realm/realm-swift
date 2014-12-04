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
#ifndef TIGHTDB_DATA_TYPE_HPP
#define TIGHTDB_DATA_TYPE_HPP

namespace tightdb {

// Note: Value assignments must be kept in sync with <tightdb/column_type.h>
// Note: Value assignments must be kept in sync with <tightdb/c/data_type.h>
// Note: Value assignments must be kept in sync with <tightdb/objc/type.h>
// Note: Value assignments must be kept in sync with "com/tightdb/ColumnType.java"
enum DataType {
    type_Int        =  0,
    type_Bool       =  1,
    type_Float      =  9,
    type_Double     = 10,
    type_String     =  2,
    type_Binary     =  4,
    type_DateTime   =  7,
    type_Table      =  5,
    type_Mixed      =  6,
    type_Link       = 12,
    type_LinkList   = 13
};


} // namespace tightdb

#endif // TIGHTDB_DATA_TYPE_HPP
