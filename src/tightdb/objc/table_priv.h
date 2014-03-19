//
//  table_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>

#include <tightdb/table.hpp>

@interface TDBTable()

-(tightdb::Table&)getNativeTable;

-(void)setNativeTable:(tightdb::Table*)table;

-(void)setParent:(id)parent; // Workaround for ARC release problem.

-(void)setReadOnly:(BOOL)read_only;

/// Also returns NO if memory allocation fails.
-(BOOL)_checkType;

/// Returns NO if memory allocation fails.
-(BOOL)_addColumns;

@end
