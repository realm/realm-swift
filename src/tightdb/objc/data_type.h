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
#ifndef TIGHTDB_OBJC_DATA_TYPE_H
#define TIGHTDB_OBJC_DATA_TYPE_H

// Make sure numbers match those in <tightdb/data_type.hpp>
typedef enum {
    tightdb_Bool   =  1,
    tightdb_Int    =  0,
    tightdb_Float  =  9,
    tightdb_Double = 10,
    tightdb_String =  2,
    tightdb_Binary =  4,
    tightdb_Date   =  7,
    tightdb_Table  =  5,
    tightdb_Mixed  =  6,
} TightdbDataType;

#endif // TIGHTDB_OBJC_DATA_TYPE_H
