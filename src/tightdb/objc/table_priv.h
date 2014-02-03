//
//  table_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>


@interface TightdbBinary()

-(tightdb::BinaryData)getBinary;

@end


@interface TightdbTable()

@property (nonatomic) tightdb::TableRef table;

-(tightdb::Table&)getTable;

-(void)setParent:(id)parent; // Workaround for ARC release problem.

-(void)setReadOnly:(BOOL)read_only;

/// Also returns NO if memory allocation fails.
-(BOOL)_checkType;

/// Returns NO if memory allocation fails.
-(BOOL)_addColumns;

@end
