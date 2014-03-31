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
#import "TDBTable.h"

@interface NSObject (TDBTypeConversion)
@property (nonatomic, readonly) BOOL tdbBoolValue;
@property (nonatomic, readonly) long long tdbLongLongValue;
@property (nonatomic, readonly) float tdbFloatValue;
@property (nonatomic, readonly) double tdbDoubleValue;
@property (nonatomic, readonly) NSData   *asNSData;
@property (nonatomic, readonly) NSString *asNSString;
@property (nonatomic, readonly) NSDate   *asNSDate;
@property (nonatomic, readonly) TDBTable *asTDBTable;
@end
