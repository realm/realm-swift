////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#ifndef TIGHTDB_OBJC_TYPE_H
#define TIGHTDB_OBJC_TYPE_H

/* Make sure numbers match those in <tightdb/data_type.hpp> */
NS_ENUM(NSInteger, TDBType) {
    TDBTypeBool   = 1,
    TDBTypeInt    = 0,
    TDBTypeFloat  = 9,
    TDBTypeDouble = 10,
    TDBTypeString = 2,
    TDBTypeBinary = 4,
    TDBTypeDate   = 7,
    TDBTypeTable  = 5,
    TDBTypeMixed  = 6
};

NS_ENUM(NSInteger, TDBSortOrder) {
    TDBSortOrderAscending  = 0,
    TDBSortOrderDescending = 1
};

#endif /* TIGHTDB_OBJC_TYPE_H */
