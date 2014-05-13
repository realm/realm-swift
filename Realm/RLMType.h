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

#ifndef REALM_OBJC_TYPE_H
#define REALM_OBJC_TYPE_H

// Make sure numbers match those in <tightdb/data_type.hpp>
typedef NS_ENUM(int32_t, RLMType) {
    RLMTypeNone =  -1,
    RLMTypeBool =  1,
    RLMTypeInt =  0,
    RLMTypeFloat =  9,
    RLMTypeDouble = 10,
    RLMTypeString =  2,
    RLMTypeBinary =  4,
    RLMTypeDate =  7,
    RLMTypeTable =  5,
    RLMTypeMixed =  6,
};


typedef NS_ENUM(NSInteger, RLMSortOrder) {
    RLMSortOrderAscending =  0,
    RLMSortOrderDescending =  1,
};

#endif // REALM_OBJC_TYPE_H
