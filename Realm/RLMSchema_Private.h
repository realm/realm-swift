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

#import "RLMSchema.h"

// NOTE: the object store uses a custom table namespace for storing data.
// There current names used are:
//  class_* - any table name beginning with class is used to store objects
//            of the typename (the rest of the name after class)
//  metadata - table used for realm metadata storage
NSString *const c_objectTableNamePrefix = @"class_";
NSString *const c_metadataTableName = @"metadata";

inline NSString *RLMTableNameForClassName(NSString *className) {
    return [c_objectTableNamePrefix stringByAppendingString:className];
}

inline NSString *RLMClassForTableName(NSString *tableName) {
    if ([tableName hasPrefix:@"class_"]) {
        return [tableName substringFromIndex:6];
    }
    return nil;
}

@class RLMRealm;

// RLMSchema private interface
@interface RLMSchema ()

// mapping of className to tableName
@property (nonatomic, readonly) NSMutableDictionary *tableNamesForClass;

// schema based on runtime objects
+(instancetype)sharedSchema;

// schema based on tables in a Realm
+(instancetype)dynamicSchemaFromRealm:(RLMRealm *)realm;

// get object class to use for a given class name
-(Class)objectClassForClassName:(NSString *)className;

@end
