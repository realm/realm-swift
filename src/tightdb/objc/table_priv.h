//
//  table_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>

#pragma mark - Private Table interface


@interface Table()

@property (nonatomic) tightdb::TableRef table;

-(tightdb::Table &)getTable;

-(void)setParent:(id)parent; // Workaround for ARC release problem.

-(void)setReadOnly:(BOOL)readOnly;

/// Also returns NO if memory allocation fails.
-(BOOL)_checkType;

/// Returns NO if memory allocation fails.
-(BOOL)_addColumns;

@end
