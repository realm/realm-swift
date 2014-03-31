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
@property (nonatomic, readonly) BOOL TDBBoolValue;
@property (nonatomic, readonly) long long TDBLongLongValue;
@property (nonatomic, readonly) float TDBFloatValue;
@property (nonatomic, readonly) double TDBDoubleValue;
@property (nonatomic, readonly) NSData   *TDBasNSData;
@property (nonatomic, readonly) NSString *TDBasNSString;
@property (nonatomic, readonly) NSDate   *TDBasNSDate;
@property (nonatomic, readonly) TDBTable *TDBasTDBTable;
@end
