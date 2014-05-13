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
#import "RLMRealm.h"
#import "RLMArray.h"

#import <tightdb/table.hpp>
#import <tightdb/group.hpp>
#import <tightdb/table_view.hpp>

// accessor protocol implemented by all persisted objects
@protocol RLMAccessor <NSObject>
@property (nonatomic) RLMRealm *realm;
@property (nonatomic, assign) NSUInteger objectIndex;
@property (nonatomic, assign) NSUInteger backingTableIndex;
@property (nonatomic, assign) tightdb::Table *backingTable;
@property (nonatomic, assign) BOOL writable;
@end


// RLMRealm transaction state
typedef NS_ENUM(NSUInteger, RLMTransactionMode) {
    RLMTransactionModeNone = 0,
    RLMTransactionModeRead,
    RLMTransactionModeWrite
};

@interface RLMRealm ()
@property (nonatomic, readonly) RLMTransactionMode transactionMode;
@property (nonatomic, readonly) tightdb::Group *group;
@end

@interface RLMObject () <RLMAccessor>
@property (nonatomic, readwrite) RLMRealm *realm;
@end

@interface RLMArray () <RLMAccessor>
@property (nonatomic, assign) tightdb::TableView backingView;
@property (nonatomic, assign) Class objectClass;
@property (nonatomic, assign) Class accessorClass;
@end


