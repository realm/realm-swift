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

#import "RLMObject.h"
#import "RLMAccessor.h"
#import "RLMObjectSchema.h"

// RLMObject accessor and read/write realm
@interface RLMObject () <RLMAccessor>

- (instancetype)initWithRealm:(RLMRealm *)realm
                       schema:(RLMObjectSchema *)schema
                defaultValues:(BOOL)useDefaults;

@property (nonatomic, readwrite) RLMRealm *realm;
@property (nonatomic, assign) NSUInteger objectIndex;
@property (nonatomic, assign) NSUInteger backingTableIndex;
@property (nonatomic, assign) tightdb::Table *backingTable;
@property (nonatomic) RLMObjectSchema *schema;

@end

