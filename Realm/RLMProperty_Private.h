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

#import "RLMProperty.h"
#import <objc/runtime.h>

// private property interface
@interface RLMProperty ()

// creates an RLMProperty object from a runtime property
+(instancetype)propertyForObjectProperty:(objc_property_t)runtimeProp
                              attributes:(RLMPropertyAttributes)attributes;

- (instancetype)initWithName:(NSString *)name
                        type:(RLMPropertyType)type
             objectClassName:(NSString *)objectClassName
                  attributes:(RLMPropertyAttributes)attributes;

// private setters
@property (nonatomic, assign) NSUInteger column;
@property (nonatomic, readwrite, assign) RLMPropertyType type;

// private properties
@property (nonatomic, assign) char objcType;

// getter and setter names
@property (nonatomic, copy) NSString *getterName;
@property (nonatomic, copy) NSString *setterName;
@property (nonatomic, copy) NSString *objectClassName;

@end

