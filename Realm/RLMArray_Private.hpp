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

#import "RLMArray.h"
#import "RLMAccessor.h"
#import <tightdb/query.hpp>
#import <tightdb/link_view.hpp>

// RLMArray private members and accessor
@interface RLMArray () <RLMAccessor>
+ (instancetype)arrayWithObjectClassName:(NSString *)objectClassName
                                   query:(tightdb::Query *)query
                                    view:(tightdb::TableView &)view
                                   realm:(RLMRealm *)realm;
+ (instancetype)arrayWithObjectClassName:(NSString *)objectClassName
                                    view:(tightdb::LinkViewRef)view
                                   realm:(RLMRealm *)realm;;
@end


