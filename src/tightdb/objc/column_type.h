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
#ifndef TIGHTDB_OBJC_COLUMN_TYPE_H
#define TIGHTDB_OBJC_COLUMN_TYPE_H

#include <stdlib.h>

// FIXME: The namespace of all-upper-case names must be considered
// reserved for macros. Consider renaming 'TIGHTDB_COLUMN_TYPE_INT' to
// 'tightdb_type_Int', and so forth. That is, a qualifying prefix
// followed by the enumeration name in CamelCase. This is a reasonably
// common naming scheme for enumeration values. Note that I am also
// suggesting that we drop 'column' from the names, since these types
// a used much more generally than as just 'column types'.

// Make sure numbers match those in <tightdb/column_type.hpp>
typedef enum {
    TIGHTDB_COLUMN_TYPE_BOOL   =  1,
    TIGHTDB_COLUMN_TYPE_INT    =  0,
    TIGHTDB_COLUMN_TYPE_STRING =  2,
    TIGHTDB_COLUMN_TYPE_BINARY =  4,
    TIGHTDB_COLUMN_TYPE_DATE   =  7,
    TIGHTDB_COLUMN_TYPE_TABLE  =  5,
    TIGHTDB_COLUMN_TYPE_MIXED  =  6,
} TightdbColumnType;

#endif // TIGHTDB_OBJC_COLUMN_TYPE_H
