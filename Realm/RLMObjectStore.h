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

#import "RLMRealm.h"

//
// Object Store Initialization
//

// initialize global object store
// call once before using other methods
void RLMInitializeObjectStore();


//
// Table modifications
//

// verifies and/or creates tables needed in a realm to store all object types
// throws if current state of realm is not compatible with current objects
void RLMVerifyAndCreateTables(RLMRealm *realm);

// verify that columns match - update objectSchema column indexes to match table
void RLMVerifyAndAlignTableColumns(tightdb::Table *table, RLMObjectSchema *targetSchema);

// create tables described in targetSchema missing from the given realm
// returns if tables were added
// NOTE: must be called from within write transaction
bool RLMCreateMissingTables(RLMRealm *realm, RLMSchema *targetSchema, BOOL verifyExisting);

// FIXME - implement this and make use it to remove deleted object classes
// removes tables in realm not described in targetSchema
// returns if tables were removed
// NOTE: must be called from within write transaction
// bool RLMRemoveOldTables(RLMRealm *realm, RLMSchema *targetSchema);

// add missing columns to objects described in targetSchema
// returns if columns were added
// NOTE: must be called from within write transaction
bool RLMAddNewColumnsToSchema(RLMRealm *realm, RLMSchema *targetSchema, BOOL verifyMatching);

// remove old columns in the realm not in targetSchema
// returns if columns were removed
// NOTE: must be called from within write transaction
bool RLMRemoveOldColumnsFromSchema(RLMRealm *realm, RLMSchema *targetSchema);


//
// Adding, Removing, Getting Objects
//

// add an object to the given realm
void RLMAddObjectToRealm(RLMObject *object, RLMRealm *realm);

// add an object to the given realm
void RLMDeleteObjectFromRealm(RLMObject *object);

// get objects of a given class
RLMArray *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate, NSString *order);

//
// Accessor Creation
//

// Create accessors
RLMObject *RLMCreateObjectAccessor(RLMRealm *realm, NSString *objectClassName, NSUInteger index);
