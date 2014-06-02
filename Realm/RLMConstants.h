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


// Make sure numbers match those in <tightdb/data_type.hpp>
typedef NS_ENUM(int32_t, RLMPropertyType) {    
    // Primitive types
    RLMPropertyTypeInt      = 0,
    RLMPropertyTypeBool     = 1,
    RLMPropertyTypeFloat    = 9,
    RLMPropertyTypeDouble   = 10,
    
    // Object types
    RLMPropertyTypeString   = 2,
    RLMPropertyTypeData     = 4,
    RLMPropertyTypeAny      = 6,
    RLMPropertyTypeDate     = 7,
    
    // Array/Linked object types
    RLMPropertyTypeObject   = 12,
    RLMPropertyTypeArray    = 13,
};


typedef NS_ENUM(NSInteger, RLMSortOrder) {
    RLMSortOrderAscending =  0,
    RLMSortOrderDescending =  1,
};

// Posted by RLMRealm when it changes, that is when a table is
// added, removed, or changed in any way.

extern NSString *const RLMRealmDidChangeNotification;

typedef NS_ENUM(NSInteger, RLMError) {
    RLMErrorOk                    = 0,
    RLMErrorFail                  = 1,
    RLMErrorFailRdOnly            = 2,
    RLMErrorFileAccessError       = 3,
    RLMErrorFilePermissionDenied  = 4,
    RLMErrorFileExists            = 5,
    RLMErrorFileNotFound          = 6,
    RLMErrorRollback              = 7,
    RLMErrorInvalidDatabase       = 8,
    RLMErrorTableNotFound         = 9
};