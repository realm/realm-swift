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
#import <Realm/RLMConstants.h>
#import <Realm/RLMObject.h>

// object property definition
@interface RLMProperty : NSObject

/**
 Create an RLMProperty.
 
 @param name            The property name.
 @param type            The property type.
 @param objectClassName The object class name of the type of object this property holds. This must be set for
                        RLMPropertyTypeArray and RLMPropertyTypeObject properties.
 
 @return A populated RLMProperty instance.
 */
+ (instancetype)propertyWithName:(NSString *)name type:(RLMPropertyType)type objectClassName:(NSString *)objectClassName;

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

@end
