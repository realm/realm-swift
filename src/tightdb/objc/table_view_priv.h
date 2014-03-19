//
//  table_view_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>
#import "table.h"
#import "table_view.h"

#include <tightdb/table_view.hpp>

@interface TDBView()

+(TDBView*)viewWithTable:(TDBTable*)table andNativeView:(const tightdb::TableView&)view;

@end