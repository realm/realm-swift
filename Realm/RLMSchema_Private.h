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

//
// Realm table namespace costants/methods
//

// NOTE: the object store uses a custom table namespace for storing data.
// There current names used are:
//  class_* - any table name beginning with class is used to store objects
//            of the typename (the rest of the name after class)
//  metadata - table used for realm metadata storage
extern NSString * const c_objectTableNamePrefix;
extern const char *c_metadataTableName;
extern const char *c_versionColumnName;
extern const size_t c_versionColumnIndex;
extern const NSUInteger RLMNotVersioned;

inline NSString *RLMClassForTableName(NSString *tableName) {
    if ([tableName hasPrefix:c_objectTableNamePrefix]) {
        return [tableName substringFromIndex:6];
    }
    return nil;
}

inline NSString *RLMTableNameForClass(NSString *className) {
    return [c_objectTableNamePrefix stringByAppendingString:className];
}


//
// Realm schema metadata
//
NSUInteger RLMRealmSchemaVersion(RLMRealm *realm);

// must be in write transaction to set
void RLMRealmSetSchemaVersion(RLMRealm *realm, NSUInteger version);

// get primary key property name for object class
NSString *RLMRealmPrimaryKeyForObjectClass(RLMRealm *realm, NSString *objectClass);

// sets primary key property for object class
// must be in write transaction to set
void RLMRealmSetPrimaryKeyForObjectClass(RLMRealm *realm, NSString *objectClass, NSString *primaryKey);


//
// RLMSchema private interface
//
@class RLMRealm;
@interface RLMSchema ()
@property (nonatomic, readwrite, copy) NSArray *objectSchema;

// schema based on runtime objects
+(instancetype)sharedSchema;

// schema based on tables in a Realm
+(instancetype)dynamicSchemaFromRealm:(RLMRealm *)realm;

// class for string
+ (Class)classForString:(NSString *)className;

@end
