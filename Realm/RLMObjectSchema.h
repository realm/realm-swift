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
#import "RLMProperty.h"

/**---------------------------------------------------------------------------------------
 *  @name Object Schema
 * ---------------------------------------------------------------------------------------
 */
@interface RLMObjectSchema : NSObject

/**
 Array of persisted properties for an object.
 */
@property (nonatomic, readonly, copy) NSArray *properties;

/**
 The name of the class this schema describes.
 */
@property (nonatomic, readonly) NSString *className;

/**
 Lookup a property object by name.
 
 @param key The properties name.
 
 @return    RLMProperty object or nil if there is no property with the given name.
 */
- (RLMProperty *)objectForKeyedSubscript:(id <NSCopying>)propertyName;

@end

