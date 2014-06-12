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

#import "RLMProperty.h"
#import <objc/runtime.h>

// private property interface
@interface RLMProperty ()

// initializer
-(instancetype)initWithName:(NSString *)name type:(RLMPropertyType)type column:(NSUInteger)column;

// creates an RLMProperty object from a runtime property
+(instancetype)propertyForObjectProperty:(objc_property_t)runtimeProp
                              attributes:(RLMPropertyAttributes)attributes
                                  column:(NSUInteger)column;

// private properties
@property (nonatomic) NSUInteger column;
@property (nonatomic, readonly) char objcType;

// getter and setter names
@property (nonatomic, copy) NSString *getterName;
@property (nonatomic, copy) NSString *setterName;
@property (nonatomic, copy) NSString *objectClassName;

@end

