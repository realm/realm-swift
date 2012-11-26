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

#ifndef TIGHTDB_OBJC_COLUMNTYPE_H
#define TIGHTDB_OBJC_COLUMNTYPE_H

// Make sure numbers match with <tightdb/column_type.hpp>

#ifdef __cplusplus
#include <cstdlib>
enum ColumnType {
    COLUMN_TYPE_INT         =  0,
    COLUMN_TYPE_BOOL        =  1,
    COLUMN_TYPE_STRING      =  2,
    COLUMN_TYPE_STRING_ENUM =  3, // double refs
    COLUMN_TYPE_BINARY      =  4,
    COLUMN_TYPE_TABLE       =  5,
    COLUMN_TYPE_MIXED       =  6,
    COLUMN_TYPE_DATE        =  7,
        COLUMN_TYPE_RESERVED1   =  8, // DateTime
        COLUMN_TYPE_RESERVED2   =  9, // Float
        COLUMN_TYPE_RESERVED3   = 10, // Double
        COLUMN_TYPE_RESERVED4   = 11  // Decimal

    // Double refs
};
#else
#include <stdlib.h>
typedef enum  {
    COLUMN_TYPE_INT         =  0,
    COLUMN_TYPE_BOOL        =  1,
    COLUMN_TYPE_STRING      =  2,
    COLUMN_TYPE_STRING_ENUM =  3, // double refs
    COLUMN_TYPE_BINARY      =  4,
    COLUMN_TYPE_TABLE       =  5,
    COLUMN_TYPE_MIXED       =  6,
    COLUMN_TYPE_DATE        =  7,
        COLUMN_TYPE_RESERVED1   =  8, // DateTime
        COLUMN_TYPE_RESERVED2   =  9, // Float
        COLUMN_TYPE_RESERVED3   = 10, // Double
        COLUMN_TYPE_RESERVED4   = 11  // Decimal
} ColumnType;
#endif


#endif // TIGHTDB_OBJC_COLUMNTYPE_H
