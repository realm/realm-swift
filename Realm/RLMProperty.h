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


#import <Foundation/Foundation.h>
#import <Realm/RLMConstants.h>
#import <Realm/RLMObject.h>

// object property definition
@interface RLMProperty : NSObject

/**
 Property name.
 */
@property (nonatomic, readonly) NSString * name;

/**
 Property type.
 */
@property (nonatomic, readonly) RLMPropertyType type;

/**
 Property attributes.
 */
@property (nonatomic, readonly) RLMPropertyAttributes attributes;

/**
 Object class name - specify object types for RLMObject and RLMArray properties.
 */
@property (nonatomic, readonly, copy) NSString *objectClassName;

/**
 Returns YES if property objects are equal
 */
-(BOOL)isEqualToProperty:(RLMProperty *)prop;

@end
