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
// Table modifications
//

// update tables in realm to the targetSchema and set schema on realm
// returns true if modifications were made
// NOTE: must be called from within write transaction if initializeSchema is true
bool RLMRealmSetSchema(RLMRealm *realm, RLMSchema *targetSchema, bool initializeSchema = false);

// initialize a realm if needed with the given schema
// for uninitialized dbs, the initial version is set and tables are created for the target schema
// existing dbs are validated against the target schema
void RLMRealmInitializeWithSchema(RLMRealm *realm, RLMSchema *targetSchema);

// initialize a read-only realm with the given schema
void RLMRealmInitializeReadOnlyWithSchema(RLMRealm *realm, RLMSchema *targetSchema);

//
// Adding, Removing, Getting Objects
//

// add an object to the given realm
// if tryUpdate is 'true', update an existing object with the same primary key value
void RLMAddObjectToRealm(RLMObject *object, RLMRealm *realm, bool tryUpdate = false);

// delete an object from its realm
void RLMDeleteObjectFromRealm(RLMObject *object);

// get objects of a given class
RLMArray *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate);

// create object from array or dictionary
// if tryUpdate is 'true', update an existing object with the same primary key value
RLMObject *RLMCreateObjectInRealmWithValue(RLMRealm *realm, NSString *className, id value, bool tryUpdate = false);


//
// Accessor Creation
//

// Create accessors
RLMObject *RLMCreateObjectAccessor(RLMRealm *realm, NSString *objectClassName, NSUInteger index);
