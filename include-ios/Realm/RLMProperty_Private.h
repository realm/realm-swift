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

- (instancetype)initWithName:(NSString *)name
                  attributes:(RLMPropertyAttributes)attributes
                    property:(objc_property_t)property;

- (instancetype)initSwiftPropertyWithName:(NSString *)name
                               attributes:(RLMPropertyAttributes)attributes
                                 property:(objc_property_t)property
                                 instance:(RLMObject *)objectInstance;

// private setters
@property (nonatomic, assign) NSUInteger column;
@property (nonatomic, readwrite, assign) RLMPropertyType type;
@property (nonatomic, readwrite) RLMPropertyAttributes attributes;

// private properties
@property (nonatomic, copy) NSString *objcRawType;
@property (nonatomic, assign) char objcType;

// getter and setter names
@property (nonatomic, copy) NSString *getterName;
@property (nonatomic, copy) NSString *setterName;
@property (nonatomic) SEL getterSel;
@property (nonatomic) SEL setterSel;
@property (nonatomic, copy) NSString *objectClassName;
@property (nonatomic, assign) BOOL isPrimary;

@end

