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
#import "util_noinst.hpp"
#import <tightdb/query.hpp>

@class RLMTable;

tightdb::Query queryFromPredicate(RLMTable *table, id predicate);

NSException *RLM_predicate_exception(NSString *name, NSString *reason);
NSUInteger RLM_validated_column_index(RLMTable *table, NSString *columnName);
