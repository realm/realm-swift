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

#import "RLMRealm.h"
#import "RLMSchema.h"
#import "RLMAccessor.h"

#import <tightdb/group.hpp>

// RLMRealm transaction state
typedef NS_ENUM(NSUInteger, RLMTransactionMode) {
    RLMTransactionModeNone = 0,
    RLMTransactionModeRead,
    RLMTransactionModeWrite
};

// RLMRealm private members
@interface RLMRealm ()
@property (nonatomic, readonly) RLMTransactionMode transactionMode;
@property (nonatomic, readonly) tightdb::Group *group;
@property (nonatomic) RLMSchema *schema;
@property (nonatomic) NSUInteger schemaVersion;

// private constructor
+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                      dynamic:(BOOL)dynamic
                        error:(NSError **)outError;

// call whenever creating an accessor to keep up to date accross transactions
- (void)registerAccessor:(id<RLMAccessor>)accessor;

@end
