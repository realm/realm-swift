/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/


#import <Foundation/Foundation.h>
#import "RLMType.h"
#import <objc/runtime.h>

// object property definition
@interface RLMProperty : NSObject

@property (nonatomic, copy) NSString * name;
@property (nonatomic, assign) RLMType type;
@property (nonatomic, assign) Class subtableObjectClass;
@property (nonatomic, assign) char objcType;

// creates a tdb property object from a runtime property
+(instancetype)propertyForObjectProperty:(objc_property_t)prop;

// adds getters and setters for this property/column on the given class
-(void)addToClass:(Class)cls existing:(NSSet *)existing column:(int)column;

@end

