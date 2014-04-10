/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
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
#ifndef TIGHTDB_OBJC_TYPE_H
#define TIGHTDB_OBJC_TYPE_H

/* Make sure numbers match those in <tightdb/data_type.hpp> */
typedef enum {
    TDBBoolType   =  1,
    TDBIntType    =  0,
    TDBFloatType  =  9,
    TDBDoubleType = 10,
    TDBStringType =  2,
    TDBBinaryType =  4,
    TDBDateType   =  7,
    TDBTableType  =  5,
    TDBMixedType  =  6,
} TDBType;


typedef enum {
    TDBAscending   =  0,
    TDBDescending   =  1,

} TDBSortOrder;

#endif /* TIGHTDB_OBJC_TYPE_H */
