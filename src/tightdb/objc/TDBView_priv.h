//
//  table_view_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>
#import "TDBTable.h"
#import "TDBView.h"

#include <tightdb/table_view.hpp>

@interface TDBView()

+(TDBView*)viewWithTable:(TDBTable*)table andNativeView:(const tightdb::TableView&)view;

@end