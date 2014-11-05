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

#import "RLMAccessor.h"
#import "RLMResults.h"

//
// Table modifications
//

// sets a realm's schema to a copy of targetSchema
// caches table accessors on each objectSchema
void RLMRealmSetSchema(RLMRealm *realm, RLMSchema *targetSchema, bool verifyAndAlignColumns = true);

// sets a realm's schema to a copy of targetSchema and creates/updates tables
// if update existing is true, updates existing tables, otherwise validates existing tables
// NOTE: must be called from within write transaction
void RLMRealmCreateTables(RLMRealm *realm, RLMSchema *targetSchema, bool updateExisting = false);


//
// Adding, Removing, Getting Objects
//

// add an object to the given realm
void RLMAddObjectToRealm(RLMObject *object, RLMRealm *realm, RLMSetFlag options = 0);

// delete an object from its realm
void RLMDeleteObjectFromRealm(RLMObject *object, RLMRealm *realm);

// deletes all objects from a realm
void RLMDeleteAllObjectsFromRealm(RLMRealm *realm);

// get objects of a given class
RLMResults *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate);

// get an object with the given primary key
id RLMGetObject(RLMRealm *realm, NSString *objectClassName, id key);

// create object from array or dictionary
RLMObject *RLMCreateObjectInRealmWithValue(RLMRealm *realm, NSString *className, id value, RLMSetFlag options = 0);


//
// Accessor Creation
//

// Create accessors
RLMObject *RLMCreateObjectAccessor(RLMRealm *realm, NSString *objectClassName, NSUInteger index);
