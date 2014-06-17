////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
