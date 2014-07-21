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

/*
 Store archived objects in a data column with a sentinal sequence of bytes and
 inside a top level NSDictionary that keeps track of the stored object class.
 This allows for native columns with data in the table to have the correct
 object class available for migrations etc.
 
 
 //TODO: RH: One possible, alternative aproach would be to have an internal
 realm object that we could use to hold onto the metadata via a link table entry.
 ie:
 
 @interface _RLMNativeObjectWrapper
 @property (nonatomic, copy) NSData *archivedObject;
 @property (nonatomic, copy) NSString *className;
 @property (nonatomic) BOOL archivedObjectIsNil;
 @property (nonatomic, strong) id _inMemoryCachedObject; // realm ignored property
 @end
 
 We would need to be careful to make sure that we didn't leak the internal object
 externally, and would also need to make sure that we handled NSArrays of native
 objects correctly..
 
 */

#import <Foundation/Foundation.h>


extern BOOL RLMNativeObjectSupportsArchiving(id nativeObject);
extern BOOL RLMDataContainsNativeObject(NSData *data);

extern NSData * RLMDataFromNativeObject(id <NSObject, NSCoding> nativeObject, NSString *className);
extern id<NSCoding> RLMNativeObjectFromData(NSData *data);
extern NSString * RLMNativeObjectClassNameFromData(NSData *data);
