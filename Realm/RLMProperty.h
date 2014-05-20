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


#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "RLMConstants.h"

// object property definition
@interface RLMProperty : NSObject

@property (nonatomic, copy) NSString * name;
@property (nonatomic, assign) RLMPropertyType type;
@property (nonatomic, assign) NSUInteger column;
@property (nonatomic, copy) id defaultValue;

// object class used for RLMLink and RLMArray types
@property (nonatomic, assign) NSString *objectClassName;
@property (nonatomic, assign) char objcType;

// getter and setter names
@property (nonatomic, copy) NSString * getterName;
@property (nonatomic, copy) NSString * setterName;

// creates a tdb property object from a runtime property
+(instancetype)propertyForObjectProperty:(objc_property_t)prop column:(NSUInteger)column;

@end

