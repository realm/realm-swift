//
//  table_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>

#pragma mark - Private Table interface

@interface Table()
@property(nonatomic) tightdb::TableRef table;
-(tightdb::Table *)getTable;
-(void)setParent:(id)parent; // Workaround for ARC release problem.
-(void)setReadOnly:(BOOL)readOnly;
-(BOOL)checkType:(BOOL)throwOnMismatch;
-(BOOL)_addColumns;
@end
