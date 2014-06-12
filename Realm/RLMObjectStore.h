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

#import "RLMRealm.h"

//
// Object Store Initialization
//

// initialize global object store
// call once before using other methods
void RLMInitializeObjectStore();

// verifies and/or creates tables needed in a realm to store all object types
// throws if current state of realm is not compatible with current objects
void RLMVerifyAndCreateTables(RLMRealm *realm);


//
// Adding, Removing, Getting Objects
//

// add an object to the given realm
void RLMAddObjectToRealm(RLMObject *object, RLMRealm *realm);

// add an object to the given realm
void RLMDeleteObjectFromRealm(RLMObject *object);

// get objects of a given class
RLMArray *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate, id order);


//
// Accessor Creation
//

// Create accessors
RLMObject *RLMCreateObjectAccessor(RLMRealm *realm, NSString *objectClassName, NSUInteger index);


